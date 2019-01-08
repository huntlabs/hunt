/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.net
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.event.selector.epoll;

// dfmt off
version(linux):

// dfmt on

import std.exception;
import std.socket;
import std.string;
import hunt.logging;

import core.time;
import core.stdc.string;
import core.stdc.errno;
import core.sys.posix.sys.types; // for ssize_t, size_t
import core.sys.posix.netinet.tcp;
import core.sys.posix.netinet.in_;
import core.sys.posix.unistd;

import core.sys.posix.sys.resource;
import core.sys.posix.sys.time;

import hunt.exception;
import hunt.event.core;
import hunt.event.socket;
import hunt.event.timer;
import hunt.event.timer.epoll;
import hunt.system.error;

/* Max. theoretical number of file descriptors on system. */
__gshared size_t fdLimit = 0;

shared static this() {
    rlimit fileLimit;
    getrlimit(RLIMIT_NOFILE, &fileLimit);
    fdLimit = fileLimit.rlim_max;
}

/**
*/
class AbstractSelector : Selector {
    enum int NUM_KEVENTS = 512;
    private int _epollFD;
    private EventChannel _event;

    this() {
        // http://man7.org/linux/man-pages/man2/epoll_create.2.html
        /*
         * epoll_create expects a size as a hint to the kernel about how to
         * dimension internal structures. We can't predict the size in advance.
         */
        // _epollFD = epoll_create1(0);
        _epollFD = epoll_create(256);
        if(_epollFD < 0)
            throw new IOException("epoll_create failed");
        _event = new EpollEventChannel(this);
        register(_event);
    }

    ~this() {
        dispose();
    }

    override void dispose() {
        if (isDisposed)
            return;
        
        version (HUNT_DEBUG) tracef("disposing selector[fd=%d]...", _epollFD);
        isDisposed = true;
        _event.close();
        core.sys.posix.unistd.close(_epollFD);
    }

    private bool isDisposed = false;

    override void stop() {
        if(_running) {
            super.stop();
            version (HUNT_DEBUG) tracef("notice that selector[fd=%d] stopped", _epollFD);
            _event.call(); 
        }
    }

    override bool register(AbstractChannel channel) {
        assert(channel !is null);
        version (HUNT_DEBUG) tracef("register channel: fd=%d", channel.handle);

        if (channel.type == ChannelType.Timer) {
            auto wt = cast(AbstractTimer) channel;
            if (wt !is null)
                wt.setTimer();
        }

        if(epollCtl(channel, EPOLL_CTL_ADD)) {
            _event.setNext(channel);
            return true;
        } else {
            warningf("register channell failed: fd=%d", channel.handle);
            return false;
        }
    }

    override bool reregister(AbstractChannel channel) {        
        return epollCtl(channel, EPOLL_CTL_MOD);
    }

    override bool deregister(AbstractChannel channel) {
        if(epollCtl(channel, EPOLL_CTL_DEL)) {
            version (HUNT_DEBUG) tracef("deregister channel: fd=%d", channel.handle);
            return true;
        } else {
            warningf("deregister channel failed: fd=%d", channel.handle);
            return false;
        }
    }

    override protected int doSelect(long timeout) {
        epoll_event[NUM_KEVENTS] events;
        int len = 0;

        if(timeout <= 0) { /* Indefinite or no wait */
            do {
                // http://man7.org/linux/man-pages/man2/epoll_wait.2.html
                len = epoll_wait(_epollFD, events.ptr, events.length, cast(int)timeout);
            } while((len == -1) && (errno == EINTR));
        } else { /* Bounded wait; bounded restarts */
            len = iepoll(_epollFD, events.ptr, events.length, cast(int)timeout);
        }

        foreach (i; 0 .. len) {
            AbstractChannel channel = cast(AbstractChannel)(events[i].data.ptr);
            if (channel is null) {
                warningf("channel is null");
                continue;
            }

            uint currentEvents = events[i].events;
            version (HUNT_DEBUG) infof("handling event: events=%d, fd=%d", currentEvents, channel.handle);

            if (isClosed(currentEvents)) {
                version (HUNT_DEBUG)
                tracef("channel closed: fd=%d, errno=%d, message=%s", channel.handle,
                        errno, getErrorMessage(errno));
                channel.close();
            } else if (isError(currentEvents)) {
                // version (HUNT_DEBUG)
                warningf("channel error: fd=%s, errno=%d, message=%s", channel.handle,
                        errno, getErrorMessage(errno));
                channel.close();
            } else if (isReadable(currentEvents)) {
                channel.onRead();
            } else if (isWritable(currentEvents)) {
                AbstractSocketChannel wt = cast(AbstractSocketChannel) channel;
                assert(wt !is null);
                wt.onWriteDone();
                // channel.onWrite();
            } else {
                warningf("Undefined behavior: fd=%d, registered=%s", channel.handle, channel.isRegistered);
            }
        }

        return len;
    }

    private int iepoll(int epfd, epoll_event* events, int numfds, int timeout) {
        long start, now;
        int remaining = timeout;
        timeval t;
        long diff;

        gettimeofday(&t, null);
        start = t.tv_sec * 1000 + t.tv_usec / 1000;

        for (;;) {
            int res = epoll_wait(epfd, events, numfds, remaining);
            if (res < 0 && errno == EINTR) {
                if (remaining >= 0) {
                    gettimeofday(&t, null);
                    now = t.tv_sec * 1000 + t.tv_usec / 1000;
                    diff = now - start;
                    remaining -= diff;
                    if (diff < 0 || remaining <= 0) {
                        return 0;
                    }
                    start = now;
                }
            } else {
                return res;
            }
        }
    }

    // https://blog.csdn.net/ljx0305/article/details/4065058
    private static bool isError(uint events) nothrow {
        return (events & EPOLLERR ) != 0;
    }

    private static bool isClosed(uint events) nothrow {
        return (events & (EPOLLHUP | EPOLLRDHUP)) != 0;
    }

    private static bool isReadable(uint events) nothrow {
        return (events & EPOLLIN) != 0;
    }

    private static bool isWritable(uint events) nothrow {
        return (events & EPOLLOUT) != 0;
    }

    private static buildEpollEvent(AbstractChannel channel, ref epoll_event ev) {
        ev.data.ptr = cast(void*) channel;
        // ev.data.fd = channel.handle;
        ev.events = EPOLLRDHUP | EPOLLERR | EPOLLHUP;
        if (channel.hasFlag(ChannelFlag.Read))
            ev.events |= EPOLLIN;
        if (channel.hasFlag(ChannelFlag.Write))
            ev.events |= EPOLLOUT;
        if (channel.hasFlag(ChannelFlag.OneShot))
            ev.events |= EPOLLONESHOT;
        if (channel.hasFlag(ChannelFlag.ETMode))
            ev.events |= EPOLLET;
        return ev;
    }

    private bool epollCtl(AbstractChannel channel, int opcode) {
        assert(channel !is null);
        const fd = channel.handle;
        assert(fd >= 0, "The channel.handle is not initialized!");

        epoll_event ev;
        buildEpollEvent(channel, ev);
        int res = 0;
        do {
            res = epoll_ctl(_epollFD, opcode, fd, &ev);
        } while((res == -1) && (errno == EINTR));

        /*
         * A channel may be registered with several Selectors. When each Selector
         * is polled a EPOLL_CTL_DEL op will be inserted into its pending update
         * list to remove the file descriptor from epoll. The "last" Selector will
         * close the file descriptor which automatically unregisters it from each
         * epoll descriptor. To avoid costly synchronization between Selectors we
         * allow pending updates to be processed, ignoring errors. The errors are
         * harmless as the last update for the file descriptor is guaranteed to
         * be EPOLL_CTL_DEL.
         */
        if (res < 0 && errno != EBADF && errno != ENOENT && errno != EPERM) {
            warning("epoll_ctl failed");
            return false;
        } else
            return true;        
    }
}


/**
*/
class EpollEventChannel : EventChannel {
    this(Selector loop) {
        super(loop);
        setFlag(ChannelFlag.Read, true);
        this.handle = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
        _isRegistered = true;
    }

    ~this() {
        close();
    }

    override void call() {
        version (HUNT_DEBUG) tracef("calling event [fd=%d]...%s", this.handle, eventLoop.isRuning);
        ulong value = 1;
        core.sys.posix.unistd.write(this.handle, &value, value.sizeof);
    }

    override void onRead() {
        version (HUNT_DEBUG) tracef("channel reading [fd=%d]...", this.handle);
        this.clearError();
        ulong value;
        ssize_t n = core.sys.posix.unistd.read(this.handle, &value, value.sizeof);
        version (HUNT_DEBUG) tracef("channel read done: %d bytes, fd=%d", n, this.handle);
    }

    override protected void onClose() {
        version (HUNT_DEBUG) tracef("close event channel [fd=%d]...", this.handle);
        core.sys.posix.unistd.close(this.handle);
    }
}

enum {
    EFD_SEMAPHORE = 0x1,
    EFD_CLOEXEC = 0x80000,
    EFD_NONBLOCK = 0x800
}

enum {
    EPOLL_CLOEXEC = 0x80000,
    EPOLL_NONBLOCK = 0x800
}

enum {
    EPOLLIN = 0x001,
    EPOLLPRI = 0x002,
    EPOLLOUT = 0x004,
    EPOLLRDNORM = 0x040,
    EPOLLRDBAND = 0x080,
    EPOLLWRNORM = 0x100,
    EPOLLWRBAND = 0x200,
    EPOLLMSG = 0x400,
    EPOLLERR = 0x008,
    EPOLLHUP = 0x010,
    EPOLLRDHUP = 0x2000, // since Linux 2.6.17
    EPOLLONESHOT = 1u << 30,
    EPOLLET = 1u << 31
}

/* Valid opcodes ( "op" parameter ) to issue to epoll_ctl().  */
enum {
    EPOLL_CTL_ADD = 1, // Add a file descriptor to the interface.
    EPOLL_CTL_DEL = 2, // Remove a file descriptor from the interface.
    EPOLL_CTL_MOD = 3, // Change file descriptor epoll_event structure.
}

// dfmt off
extern (C) : @system : nothrow :

align(1) struct epoll_event {
align(1):
    uint events;
    epoll_data data;
}

union epoll_data {
    void* ptr;
    int fd;
    uint u32;
    ulong u64;
}

// dfmt on

int epoll_create(int size);
int epoll_create1(int flags);
int epoll_ctl(int epfd, int op, int fd, epoll_event* event);
int epoll_wait(int epfd, epoll_event* events, int maxevents, int timeout);

socket_t eventfd(uint initval, int flags);
