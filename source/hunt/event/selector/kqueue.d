/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.cn
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.event.selector.kqueue;

import hunt.lang.common;
import hunt.event.core;

// dfmt off
version(Kqueue):
// dfmt on

import hunt.event.core;
import hunt.event.socket.common;

// import hunt.event.socket.posix;
import hunt.event.timer.kqueue;

import std.exception;
import std.socket;

import std.string;

import core.time;
import core.stdc.string;
import core.stdc.errno;
import core.sys.posix.sys.types; // for ssize_t, size_t
import core.sys.posix.signal;
import core.sys.posix.netinet.tcp;
import core.sys.posix.netinet.in_;
import core.sys.posix.unistd;
import core.sys.posix.time;

/**
*/
class AbstractSelector : Selector {
    // kevent array size
    enum int NUM_KEVENTS = 128;

    this() {
        _kqueueFD = kqueue();
        _event = new KqueueEventChannel(this);
        incomingInterruptFD = _event._pair[0].handle;
        outgoingInterruptFD = _event._pair[1].handle;
        // register(_event);
        register0(_kqueueFD, incomingInterruptFD, true, false, _event);
    }

    ~this() {
        dispose();
    }

    override void dispose() {
        if (isDisposed)
            return;
        isDisposed = true;
        deregister(_event);
        core.sys.posix.unistd.close(_kqueueFD);
    }

    private bool isDisposed = false;

    private static int register0(int kq, int fd, bool read, bool write, AbstractChannel channel) {
        kevent[2] changes;
        kevent[2] errors;
        timespec dontBlock = {0, 0};

        // if (r) then { register for read } else { unregister for read }
        // if (w) then { register for write } else { unregister for write }
        // Ignore errors - they're probably complaints about deleting non-
        //   added filters - but provide an error array anyway because
        //   kqueue behaves erratically if some of its registrations fail.
        EV_SET(&changes[0], fd, EVFILT_READ,  read ? EV_ADD : EV_DELETE, 0, 0, cast(void*) channel);
        EV_SET(&changes[1], fd, EVFILT_WRITE, write ? EV_ADD : EV_DELETE, 0, 0, cast(void*) channel);
        return kevent(kq, changes, 2, errors, 2, &dontBlock);
    }

    // void initInterrupt(int fd0, int fd1) {
    //     outgoingInterruptFD = fd1;
    //     incomingInterruptFD = fd0;
    //     register0(kq, fd0, 1, 0);
    // }

    override bool register(AbstractChannel channel) {
        assert(channel !is null);
        const int fd = channel.handle;
        if (fd < 0)
            return false;

        kevent[2] errors;
        timespec dontBlock = {0, 0};

        int err = -1;
        if (channel.type == ChannelType.Timer) {
            kevent ev;
            AbstractTimer timerChannel = cast(AbstractTimer) channel;
            if (timerChannel is null)
                return false;
            size_t time = timerChannel.time < 20 ? 20 : timerChannel.time; // in millisecond
            EV_SET(&ev, fd, EVFILT_TIMER,
                    EV_ADD | EV_ENABLE | EV_CLEAR, 0, time, cast(void*) channel);
            err = kevent(_kqueueFD, &ev, 1, errors, 1, &dontBlock);
        } else {
            err = register0(_kqueueFD, fd, channel.hasFlag(ChannelFlag.Read), 
                channel.hasFlag(ChannelFlag.Write), channel);
            // kevent[2] ev = void;
            // short read = EV_ADD | EV_ENABLE;
            // short write = EV_ADD | EV_ENABLE;
            // if (channel.hasFlag(ChannelFlag.ETMode)) {
            //     read |= EV_CLEAR;
            //     write |= EV_CLEAR;
            // }
            // EV_SET(&(ev[0]), fd, EVFILT_READ, read, 0, 0, cast(void*) channel);
            // EV_SET(&(ev[1]), fd, EVFILT_WRITE, write, 0, 0, cast(void*) channel);
            // // Ignore errors - they're probably complaints about deleting non-
            // //   added filters - but provide an error array anyway because
            // //   kqueue behaves erratically if some of its registrations fail.
            // if (channel.hasFlag(ChannelFlag.Read) && channel.hasFlag(ChannelFlag.Write))
            //     err = kevent(_kqueueFD, &(ev[0]), 2, errors, 2, &dontBlock);
            // else if (channel.hasFlag(ChannelFlag.Read))
            //     err = kevent(_kqueueFD, &(ev[0]), 1, errors, 1, &dontBlock);
            // else if (channel.hasFlag(ChannelFlag.Write))
            //     err = kevent(_kqueueFD, &(ev[1]), 1, errors, 1, &dontBlock);
        }

        if (err < 0) {
            return false;
        } else {
            _event.setNext(channel);
            return true;
        }
    }

    override bool reregister(AbstractChannel channel) {
        throw new LoopException("The Kqueue does not support reregister!");
    }

    override bool deregister(AbstractChannel channel) {
        assert(channel !is null);
        const fd = channel.handle;
        if (fd < 0)
            return false;

        int err = -1;
        if (channel.type == ChannelType.Timer) {
            kevent ev;
            AbstractTimer timerChannel = cast(AbstractTimer) channel;
            if (timerChannel is null)
                return false;
            EV_SET(&ev, fd, EVFILT_TIMER, EV_DELETE, 0, 0, cast(void*) channel);
            err = kevent(_kqueueFD, &ev, 1, null, 0, null);
        }
        else {
            err = register0(_kqueueFD, fd, false, false, channel);
            // kevent[2] ev = void;
            // EV_SET(&(ev[0]), fd, EVFILT_READ, EV_DELETE, 0, 0, cast(void*) channel);
            // EV_SET(&(ev[1]), fd, EVFILT_WRITE, EV_DELETE, 0, 0, cast(void*) channel);
            // if (channel.hasFlag(ChannelFlag.Read) && channel.hasFlag(ChannelFlag.Write))
            //     err = kevent(_kqueueFD, &(ev[0]), 2, null, 0, null);
            // else if (channel.hasFlag(ChannelFlag.Read))
            //     err = kevent(_kqueueFD, &(ev[0]), 1, null, 0, null);
            // else if (channel.hasFlag(ChannelFlag.Write))
            //     err = kevent(_kqueueFD, &(ev[1]), 1, null, 0, null);
        }
        if (err < 0) {
            return false;
        }
        // channel.currtLoop = null;
        channel.clear();
        return true;
    }

    override protected int doSelect(long timeout) {
        timespec ts;
        timespec *tsp;
        // timeout is in milliseconds. Convert to struct timespec.
        // timeout == -1 : wait forever : timespec timeout of NULL
        // timeout == 0  : return immediately : timespec timeout of zero
        if (timeout >= 0) {
            // For some indeterminate reason kevent(2) has been found to fail with
            // an EINVAL error for timeout values greater than or equal to
            // 100000001000L. To avoid this problem, clamp the timeout arbitrarily
            // to the maximum value of a 32-bit signed integer which is
            // approximately 25 days in milliseconds.
            const int timeoutMax = int.max; // Integer.MAX_VALUE
            if (timeout > timeoutMax) {
                timeout = timeoutMax;
            }
            ts.tv_sec = timeout / 1000;
            ts.tv_nsec = (timeout % 1000) * 1000000; //nanosec = 1 million millisec
            tsp = &ts;
        } else {
            tsp = null;
        }        

        // auto tspec = timespec(1, 1000 * 10);
        kevent[NUM_KEVENTS] events;
        int result = kevent(_kqueueFD, null, 0, events.ptr, events.length, tsp);
        if(result < 0) {
            if (errno == EINTR) {
                // ignore EINTR, pretend nothing was selected
                result = 0;
            } else {
                error("kqueue failed");
                result = 0;
            }
        } else {
            foreach (i; 0 .. result) {
                AbstractChannel channel = cast(AbstractChannel)(events[i].udata);
                if ((events[i].flags & EV_EOF) || (events[i].flags & EV_ERROR)) {
                    channel.close();
                    continue;
                }
                if (channel.type == ChannelType.Timer) {
                    channel.onRead();
                    continue;
                }
                if ((events[i].filter & EVFILT_WRITE) && channel.isRegistered) {
                    // import hunt.logging;
                    // version(HUNT_DEBUG) trace("The channel socket is: ", typeid(channel));
                    AbstractSocketChannel wt = cast(AbstractSocketChannel) channel;
                    assert(wt !is null);
                    wt.onWriteDone();
                }

                if ((events[i].filter & EVFILT_READ) && channel.isRegistered)
                    channel.onRead();
            }
        }
        return result;
    }

private:
    // The kqueue fd
    int _kqueueFD;

    // The fd of the interrupt line going out
    int outgoingInterruptFD;

    // The fd of the interrupt line coming in
    int incomingInterruptFD;

    EventChannel _event;
}

/**
*/
class KqueueEventChannel : EventChannel {
    this(Selector loop) {
        super(loop);
        setFlag(ChannelFlag.Read, true);
        _pair = socketPair();
        _pair[0].blocking = false;
        _pair[1].blocking = false;
        // this.handle = _pair[1].handle;
        this.handle = _pair[0].handle;
    }

    ~this() {
        close();
    }

    override void call() {
        _pair[0].send("call");
    }

    override void onRead() {
        ubyte[128] data;
        while (true) {
            if (_pair[1].receive(data) <= 0)
                break;
        }

        super.onRead();
    }

    Socket[2] _pair;
}

enum : short {
    EVFILT_READ = -1,
    EVFILT_WRITE = -2,
    EVFILT_AIO = -3, /* attached to aio requests */
    EVFILT_VNODE = -4, /* attached to vnodes */
    EVFILT_PROC = -5, /* attached to struct proc */
    EVFILT_SIGNAL = -6, /* attached to struct proc */
    EVFILT_TIMER = -7, /* timers */
    EVFILT_MACHPORT = -8, /* Mach portsets */
    EVFILT_FS = -9, /* filesystem events */
    EVFILT_USER = -10, /* User events */
    EVFILT_VM = -12, /* virtual memory events */
    EVFILT_SYSCOUNT = 11
}

extern (D) void EV_SET(kevent* kevp, typeof(kevent.tupleof) args) @nogc nothrow {
    *kevp = kevent(args);
}

struct kevent {
    uintptr_t ident; /* identifier for this event */
    short filter; /* filter for event */
    ushort flags;
    uint fflags;
    intptr_t data;
    void* udata; /* opaque user data identifier */
}

enum {
    /* actions */
    EV_ADD = 0x0001, /* add event to kq (implies enable) */
    EV_DELETE = 0x0002, /* delete event from kq */
    EV_ENABLE = 0x0004, /* enable event */
    EV_DISABLE = 0x0008, /* disable event (not reported) */

    /* flags */
    EV_ONESHOT = 0x0010, /* only report one occurrence */
    EV_CLEAR = 0x0020, /* clear event state after reporting */
    EV_RECEIPT = 0x0040, /* force EV_ERROR on success, data=0 */
    EV_DISPATCH = 0x0080, /* disable event after reporting */

    EV_SYSFLAGS = 0xF000, /* reserved by system */
    EV_FLAG1 = 0x2000, /* filter-specific flag */

    /* returned values */
    EV_EOF = 0x8000, /* EOF detected */
    EV_ERROR = 0x4000, /* error, data contains errno */

}

enum {
    /*
    * data/hint flags/masks for EVFILT_USER, shared with userspace
    *
    * On input, the top two bits of fflags specifies how the lower twenty four
    * bits should be applied to the stored value of fflags.
    *
    * On output, the top two bits will always be set to NOTE_FFNOP and the
    * remaining twenty four bits will contain the stored fflags value.
    */
    NOTE_FFNOP = 0x00000000, /* ignore input fflags */
    NOTE_FFAND = 0x40000000, /* AND fflags */
    NOTE_FFOR = 0x80000000, /* OR fflags */
    NOTE_FFCOPY = 0xc0000000, /* copy fflags */
    NOTE_FFCTRLMASK = 0xc0000000, /* masks for operations */
    NOTE_FFLAGSMASK = 0x00ffffff,

    NOTE_TRIGGER = 0x01000000, /* Cause the event to be
                                    triggered for output. */

    /*
    * data/hint flags for EVFILT_{READ|WRITE}, shared with userspace
    */
    NOTE_LOWAT = 0x0001, /* low water mark */

    /*
    * data/hint flags for EVFILT_VNODE, shared with userspace
    */
    NOTE_DELETE = 0x0001, /* vnode was removed */
    NOTE_WRITE = 0x0002, /* data contents changed */
    NOTE_EXTEND = 0x0004, /* size increased */
    NOTE_ATTRIB = 0x0008, /* attributes changed */
    NOTE_LINK = 0x0010, /* link count changed */
    NOTE_RENAME = 0x0020, /* vnode was renamed */
    NOTE_REVOKE = 0x0040, /* vnode access was revoked */

    /*
    * data/hint flags for EVFILT_PROC, shared with userspace
    */
    NOTE_EXIT = 0x80000000, /* process exited */
    NOTE_FORK = 0x40000000, /* process forked */
    NOTE_EXEC = 0x20000000, /* process exec'd */
    NOTE_PCTRLMASK = 0xf0000000, /* mask for hint bits */
    NOTE_PDATAMASK = 0x000fffff, /* mask for pid */

    /* additional flags for EVFILT_PROC */
    NOTE_TRACK = 0x00000001, /* follow across forks */
    NOTE_TRACKERR = 0x00000002, /* could not track child */
    NOTE_CHILD = 0x00000004, /* am a child process */

}

extern (C) {
    int kqueue() @nogc nothrow;
    int kevent(int kq, const kevent* changelist, int nchanges,
            kevent* eventlist, int nevents, const timespec* timeout) @nogc nothrow;
}

enum SO_REUSEPORT = 0x0200;
