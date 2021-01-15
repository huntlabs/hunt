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

import core.sys.posix.sys.types;
import core.sys.posix.netinet.tcp;
import core.sys.posix.netinet.in_;
import core.sys.posix.unistd;
import core.stdc.string;
import core.stdc.errno;
import core.time;
import core.thread;

import core.sys.posix.sys.resource;
import core.sys.posix.sys.time;
import core.sys.linux.epoll;

import hunt.event.selector.Selector;
import hunt.Exceptions;
import hunt.io.channel;
import hunt.logging.ConsoleLogger;
import hunt.event.timer;
import hunt.system.Error;
import hunt.util.worker;

/* Max. theoretical number of file descriptors on system. */
__gshared size_t fdLimit = 0;

shared static this() {
    rlimit fileLimit;
    getrlimit(RLIMIT_NOFILE, &fileLimit);
    fdLimit = fileLimit.rlim_max;
}


/**
 * 
 */
class AbstractSelector : Selector {
    enum int NUM_KEVENTS = 1024;
    private int _epollFD;
    private bool isDisposed = false;
    private epoll_event[NUM_KEVENTS] events;
    private EventChannel _eventChannel;

    this(size_t id, size_t divider, Worker worker = null, size_t maxChannels = 1500) {
        super(id, divider, worker, maxChannels);

        // http://man7.org/linux/man-pages/man2/epoll_create.2.html
        /*
         * Set the close-on-exec (FD_CLOEXEC) flag on the new file descriptor.
         * See the description of the O_CLOEXEC flag in open(2) for reasons why
         * this may be useful.
         */
        _epollFD = epoll_create1(EPOLL_CLOEXEC);
        if (_epollFD < 0)
            throw new IOException("epoll_create failed");

        _eventChannel = new EpollEventChannel(this);
        register(_eventChannel);
    }

    ~this() @nogc {
        // dispose();
    }

    override void dispose() {
        if (isDisposed)
            return;

        version (HUNT_IO_DEBUG)
            tracef("disposing selector[fd=%d]...", _epollFD);
        isDisposed = true;
        _eventChannel.close();
        int r = core.sys.posix.unistd.close(_epollFD);
        if(r != 0) {
            version (HUNT_IO_DEBUG) warningf("error: %d", r);
        }

        super.dispose();
    }

    override void onStop() {
        version (HUNT_IO_DEBUG)
            infof("Selector stopping. fd=%d, id: %d", _epollFD, getId());

        if(!_eventChannel.isClosed()) {
            _eventChannel.trigger();
            // _eventChannel.onWrite();
        }
    }

    override bool register(AbstractChannel channel) {
        super.register(channel);

        // epoll_event e;

        // e.data.fd = infd;
        // e.data.ptr = cast(void*) channel;
        // e.events = EPOLLIN | EPOLLET | EPOLLERR | EPOLLHUP | EPOLLRDHUP | EPOLLOUT;
        // int s = epoll_ctl(_epollFD, EPOLL_CTL_ADD, infd, &e);
        // if (s == -1) {
        //     debug warningf("failed to register channel: fd=%d", infd);
        //     return false;
        // } else {
        //     return true;
        // }
        if (epollCtl(channel, EPOLL_CTL_ADD)) {
            return true;
        } else {
            debug warningf("failed to register channel: fd=%d", channel.handle);
            return false;
        }
    }

    override bool deregister(AbstractChannel channel) {
        super.deregister(channel);

        if (epollCtl(channel, EPOLL_CTL_DEL)) {
            return true;
        } else {
            warningf("deregister channel failed: fd=%d", fd);
            return false;
        }
    }

    /**
        timeout: in millisecond
    */
    protected override int doSelect(long timeout) {
        int len = 0;

        if (timeout <= 0) { /* Indefinite or no wait */
            do {
                // http://man7.org/linux/man-pages/man2/epoll_wait.2.html
                // https://stackoverflow.com/questions/6870158/epoll-wait-fails-due-to-eintr-how-to-remedy-this/6870391#6870391
                len = epoll_wait(_epollFD, events.ptr, events.length, cast(int) timeout);
            } while ((len == -1) && (errno == EINTR));
        } else { /* Bounded wait; bounded restarts */
            len = iepoll(_epollFD, events.ptr, events.length, cast(int) timeout);
        }

        foreach (i; 0 .. len) {
            AbstractChannel channel = cast(AbstractChannel)(events[i].data.ptr);
            if (channel is null) {
                debug warningf("channel is null");
            } else {
                handeChannelEvent(channel, events[i].events);
            }
        }

        return len;
    }

    private void handeChannelEvent(AbstractChannel channel, uint event) {
        version (HUNT_IO_DEBUG) {
            warningf("thread: %s", Thread.getThis().name());

            // Thread.sleep(300.msecs);
            infof("handling event: selector=%d, channel=%d, events=%d, isReadable: %s, isWritable: %s, isClosed: %s", 
                this._epollFD, channel.handle, event, isReadable(event), isWritable(event), isClosed(event));
        }

        try {
            if (isClosed(event)) { // && errno != EINTR
                /* An error has occured on this fd, or the socket is not
                    ready for reading (why were we notified then?) */
                version (HUNT_IO_DEBUG) {
                    warningf("event=%d, isReadable: %s, isWritable: %s", 
                        event, isReadable(event), isWritable(event));

                    if (isError(event)) {
                        warningf("channel error: fd=%s, event=%d, errno=%d, message=%s",
                                channel.handle, event, errno, getErrorMessage(errno));
                    } else {
                        tracef("channel closed: fd=%d, errno=%d, message=%s",
                                    channel.handle, errno, getErrorMessage(errno));
                    }
                }
                
                // The remote connection broken abnormally, so the channel should be notified.
                if(isReadable(event)) {
                    channel.onRead();
                }

                // if(isWritable(event)) {
                //     channel.onWrite();
                // }

                channel.close();
            } else if (event == EPOLLIN) {
                version (HUNT_IO_DEBUG)
                    tracef("channel read event: fd=%d", channel.handle);
                channel.onRead();
            } else if (event == EPOLLOUT) {
                version (HUNT_IO_DEBUG)
                    tracef("channel write event: fd=%d", channel.handle);
                channel.onWrite();
            } else if (event == (EPOLLIN | EPOLLOUT)) {
                version (HUNT_IO_DEBUG)
                    tracef("channel read and write: fd=%d", channel.handle);
                channel.onWrite();
                channel.onRead();
            } else {
                debug warningf("Only read/write/close events can be handled, current event: %d", event);
            }
        } catch (Exception e) {
            debug {
                errorf("error while handing channel: fd=%s, exception=%s, message=%s",
                        channel.handle, typeid(e), e.msg);
            }
            version(HUNT_DEBUG) warning(e);
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

    private static bool isClosed(uint e) nothrow {
        return (e & EPOLLERR) != 0 || (e & EPOLLHUP) != 0 || (e & EPOLLRDHUP) != 0
                || (!(e & EPOLLIN) && !(e & EPOLLOUT)) != 0;
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
        // if (channel.hasFlag(ChannelFlag.OneShot))
        //     ev.events |= EPOLLONESHOT;
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