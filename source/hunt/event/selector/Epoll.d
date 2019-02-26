/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2018-2019 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.event.selector.Epoll;

// dfmt off
version(HAVE_EPOLL):

// dfmt on

import std.exception;
import std.socket;
import std.string;

import core.time;
import core.stdc.string;
import core.stdc.errno;
import core.sys.posix.sys.types; // for ssize_t, size_t
import core.sys.posix.netinet.tcp;
import core.sys.posix.netinet.in_;
import core.sys.posix.unistd;

import core.sys.posix.sys.resource;
import core.sys.posix.sys.time;

import hunt.Exceptions;
import hunt.io.socket;
import hunt.logging;
import hunt.event.timer;
import hunt.system.Error;
import hunt.concurrency.TaskPool;

/* Max. theoretical number of file descriptors on system. */
__gshared size_t fdLimit = 0;

shared static this() {
    rlimit fileLimit;
    getrlimit(RLIMIT_NOFILE, &fileLimit);
    fdLimit = fileLimit.rlim_max;
}


class Scope {
    int sfd;
    int efd;
    epoll_event event;
    epoll_event[] events;
    uint[] eventTypes;
}

// struct EventRecord {
//     int fd;
//     int type;
// }

Scope initEpoll(int maxEvents) {

	int efd = epoll_create1(0);
	// efd = epoll_create(256);
	if (efd < 0)
		throw new Exception("epoll_create failed");

	Scope sc = new Scope();
	sc.efd = efd;
	sc.events = new epoll_event[maxEvents];
    sc.eventTypes = new uint[maxEvents];

	return sc;	
}


int waitForEvents(Scope sc, int timeout) {
    int n, i, s, j = 0;
    epoll_event[] events = sc.events;
    int sfd = sc.sfd;
    int efd = sc.efd;
    int e;

    if(timeout >= 0)
        n = epoll_wait(efd, events.ptr, cast(int)events.length, timeout);
    else
        n = epoll_wait(efd, events.ptr, cast(int)events.length, -1);

   version (HUNT_DEBUG) tracef("get %d events on epoll %d", n, efd);
    for (i = 0; i < n; i++) {
        e = events[i].events;
        int fd = events[i].data.fd;
        version (HUNT_DEBUG) tracef("fd: %d, event: %d, epoll: %d", fd, e, efd);
        if ((e & EPOLLERR) || (e & EPOLLHUP) || (e & EPOLLRDHUP) || (!(e & EPOLLIN) && !(e & EPOLLOUT))) {
            /* An error has occured on this fd, or the socket is not
               ready for reading (why were we notified then?) */
           version (HUNT_DEBUG)  {
                warningf("connection closed for fd %d, event: %d", fd, e);
                int       error = 0;
                socklen_t errlen = error.sizeof;
                if (getsockopt(fd, SOL_SOCKET, SO_ERROR, cast(void *)&error, &errlen) == 0) {
                    version (HUNT_DEBUG) errorf("error = %s", strerror(error));
                }
           }
           sc.eventTypes[i] = 3; // close connection
//            close(fd);
        } else if (sfd == fd) {
            sc.eventTypes[i] = 0; // 0 - new connection
        } else {
           sc.eventTypes[i] = e; // 1-read; 4-write; 5-read and write
            version (HUNT_DEBUG) {
                if(events[i].events & EPOLLOUT)
                    tracef("write data on descriptor %d", cast(int)fd);
                else
                    tracef("read data on descriptor %d", fd);
            } 
        }
    }

    return n;
}

int waitForChannelEvents(Scope sc, int timeout) {
    int n, i, s, j = 0;
    epoll_event[] events = sc.events;
    int sfd = sc.sfd;
    int efd = sc.efd;
    int e;

    if(timeout >= 0)
        n = epoll_wait(efd, events.ptr, cast(int)events.length, timeout);
    else
        n = epoll_wait(efd, events.ptr, cast(int)events.length, -1);

    version (HUNT_DEBUG) tracef("get %d events on epoll %d", n, efd);
    for (i = 0; i < n; i++) {
        e = events[i].events;
        // AbstractChannel channel = cast(AbstractChannel)events[i].data.ptr;
        // int fd = cast(int)channel.handle;
        int fd = events[i].data.fd;
        version (HUNT_DEBUG) tracef("fd: %d, event: %d, epoll: %d", fd, e, efd);
        if ((e & EPOLLERR) || (e & EPOLLHUP) || (e & EPOLLRDHUP) || (!(e & EPOLLIN) && !(e & EPOLLOUT))) {
            /* An error has occured on this fd, or the socket is not
               ready for reading (why were we notified then?) */
           version (HUNT_DEBUG)  {
                infof("connection closed for fd %d, event: %d", fd, e);
                int       error = 0;
                socklen_t errlen = error.sizeof;
                if (getsockopt(fd, SOL_SOCKET, SO_ERROR, cast(void *)&error, &errlen) == 0) {
                    
                    version (HUNT_DEBUG) errorf("error = %s", getErrorMessage(error));
                    // import core.stdc.string;
                    // auto ss = strerror(error);
                    // version (HUNT_DEBUG) errorf("error xxxx= %s", ss[0 .. ss.strlen].idup);
                }
           }
           sc.eventTypes[i] = 3; // close connection
//            close(fd);
        } else if (sfd == fd) {
            sc.eventTypes[i] = 0; // 0 - new connection
        } else {
           sc.eventTypes[i] = e; // 1-read; 4-write; 5-read and write
            // version (HUNT_DEBUG) {
            //     if(events[i].events & EPOLLOUT)
            //         tracef("write data on descriptor %d", cast(int)fd);
            //     else
            //         tracef("read data on descriptor %d", fd);
            // } 
        }
    }

    return n;
}

/**
*/
class AbstractSelector : Selector {
    enum int NUM_KEVENTS = 1024;
    private int _epollFD;
    // private EventChannel _event;

	Scope sc;

    this() {
        // http://man7.org/linux/man-pages/man2/epoll_create.2.html
        /*
         * epoll_create expects a size as a hint to the kernel about how to
         * dimension internal structures. We can't predict the size in advance.
         */
        // _epollFD = epoll_create1(0);
        // // _epollFD = epoll_create(256);
        // if (_epollFD < 0)
        //     throw new IOException("epoll_create failed");
        // _event = new EpollEventChannel(this);
        // register(_event);

		sc = initEpoll(100);
    }

    ~this() {
        dispose();
    }

    override void dispose() {
        if (isDisposed)
            return;

        version (HUNT_DEBUG)
            tracef("disposing selector[fd=%d]...", sc.efd);
        isDisposed = true;
        // _event.close();
        core.sys.posix.unistd.close(sc.efd);
    }

    private bool isDisposed = false;

    override void stop() {
        if (_running) {
            super.stop();
            version (HUNT_DEBUG)
                tracef("selector[fd=%d] stopped", sc.efd);
            // _event.call();
        }
    }

    override bool register(AbstractChannel channel) {
        assert(channel !is null);
        version (HUNT_DEBUG)
            tracef("register channel: fd=%d", channel.handle);

        // if (channel.type == ChannelType.Timer) {
        //     auto wt = cast(AbstractTimer) channel;
        //     if (wt !is null)
        //         wt.setTimer();
        // }

        errno = 0;
        int infd = cast(int)channel.handle;
        channels[infd] = channel;
        epoll_event e;

        e.data.fd = infd;
        // e.data.ptr = cast(void*) channel;
        e.events = EPOLLIN | EPOLLET | EPOLLERR | EPOLLHUP | EPOLLRDHUP | EPOLLOUT;
        int s = epoll_ctl(sc.efd, EPOLL_CTL_ADD, infd, &e);
        if (s == -1) {
            error("epoll_ctl on attach");
            return false;
        }

        // tracef("fd=%d, count=%d",  infd, channels.length);

        return true;

        // if (epollCtl(channel, EPOLL_CTL_ADD)) {
        //     // _event.setNext(channel);
        //     return true;
        // } else {
        //     warningf("register channell failed: fd=%d", channel.handle);
        //     return false;
        // }
    }

    AbstractChannel[int] channels;

    override bool reregister(AbstractChannel channel) {
        return epollCtl(channel, EPOLL_CTL_MOD);
    }

    override bool deregister(AbstractChannel channel) {
        // if (epollCtl(channel, EPOLL_CTL_DEL)) {
        //     version (HUNT_DEBUG)
        //         tracef("deregister channel: fd=%d", channel.handle);
        //     return true;
        // } else {
        //     warningf("deregister channel failed: fd=%d", channel.handle);
        //     return false;
        // }
        channels.remove(cast(int)channel.handle);
        // trace(channels.length);
        return true;
    }

    epoll_event[NUM_KEVENTS] events;

    /**
        timeout: in millisecond
    */
    override protected int doSelect(long timeout) {
        int len = 0;

        // if (timeout <= 0) { /* Indefinite or no wait */
        //     do {
        //         // http://man7.org/linux/man-pages/man2/epoll_wait.2.html
        //         len = epoll_wait(_epollFD, events.ptr, events.length, cast(int) timeout);
        //     }
        //     while ((len == -1) && (errno == EINTR));
        // } else { /* Bounded wait; bounded restarts */
        //     len = iepoll(_epollFD, events.ptr, events.length, cast(int) timeout);
        // }
        // len = waitForEvents(sc, 500);
        debug {
            len = waitForChannelEvents(sc, -1); 
        } else {
            len = waitForChannelEvents(sc, 500);
        }

        if (len <= 0)
            return 0;

        foreach (i; 0 .. len) {
            int fd = sc.events[i].data.fd;
            // AbstractChannel channel = cast(AbstractChannel)sc.events[i].data.ptr;

            auto channel = fd in channels;
            if (channel is null) {
                debug warningf("channel is null");
                continue;
            }

            uint currentEvents = sc.eventTypes[i]; // events[i].events;
            version (HUNT_DEBUG)
                infof("handling event: events=%d, fd=%d", currentEvents, channel.handle);

            // taskPool.put(task(&handeChannel, channel, currentEvents));
            // workerPool.put(cast(int)channel.handle, makeTask(&handeChannel, channel, currentEvents));
            // handeChannel(channel, currentEvents);
            handeChannelEvent(*channel, currentEvents);
        }
        return len;
    }

    private void handeChannelEvent(AbstractChannel channel, uint event) {
        try {
            if (event == 1) {
                // connection.readyToRead = true;
                channel.onRead();
            } else if (event == 4) {
                // onWrite(connection);
                AbstractSocketChannel wt = cast(AbstractSocketChannel) channel;
                assert(wt !is null);
                wt.onWriteDone();
            } else if (event == 5) {
                // onWrite(connection);
                // connection.readyToRead = true;
                // onRead(connection);
                assert(channel !is null);
                // trace(typeid(channel));
                AbstractSocketChannel wt = cast(AbstractSocketChannel) channel;
                assert(wt !is null);
                wt.onWriteDone();
                channel.onRead();
            } else if (event == 3) {
                channel.close();
            } else {
                debug warningf("this thread only for read/write/close events, event: %d" , event);
            }
        } catch (Exception e) {

                debug warningf("channel error: fd=%s, errno=%d, message=%s",
                    channel.handle, errno, getErrorMessage(errno));
                error(e.msg);
            // try {
            //     onError(connection, e);
            // } catch (IOException ignored) {
            // }
        }
    }
    

    private void handeChannel(AbstractChannel channel, uint currentEvents) {
        if (isClosed(currentEvents)) {
            version (HUNT_DEBUG)
                infof("channel closed: fd=%d, errno=%d, message=%s",
                        channel.handle, errno, getErrorMessage(errno));
            channel.close();
        } else if (isError(currentEvents)) {
            // version (HUNT_DEBUG)
            debug warningf("channel error: fd=%s, errno=%d, message=%s",
                    channel.handle, errno, getErrorMessage(errno));
            channel.close();
        } else if (isReadable(currentEvents)) {
            version (HUNT_DEBUG)
                tracef("channel reading: fd=%d", channel.handle);

            version (HUNT_IO_WORKERPOOL) {
                workerPool.put(cast(int)channel.handle, makeTask(&channel.onRead));
            } else {
                channel.onRead();
            }
        } else if (isWritable(currentEvents)) {
            AbstractSocketChannel wt = cast(AbstractSocketChannel) channel;
            assert(wt !is null);
            wt.onWriteDone();
        } else {
            warningf("Undefined behavior: fd=%d, registered=%s",
                    channel.handle, channel.isRegistered);
        }
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
        return (events & EPOLLERR) != 0;
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
        }
        while ((res == -1) && (errno == EINTR));

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
        version (HUNT_DEBUG)
            tracef("calling event [fd=%d]...%s", this.handle, eventLoop.isRuning);
        ulong value = 1;
        core.sys.posix.unistd.write(this.handle, &value, value.sizeof);
    }

    override void onRead() {
        version (HUNT_DEBUG)
            tracef("channel reading [fd=%d]...", this.handle);
        this.clearError();
        ulong value;
        ssize_t n = core.sys.posix.unistd.read(this.handle, &value, value.sizeof);
        version (HUNT_DEBUG)
            tracef("channel read done: %d bytes, fd=%d", n, this.handle);
    }

    override protected void onClose() {
        version (HUNT_DEBUG)
            tracef("close event channel [fd=%d]...", this.handle);
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
