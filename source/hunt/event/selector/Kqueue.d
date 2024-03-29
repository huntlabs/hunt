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

module hunt.event.selector.Kqueue;


// dfmt off
version(HAVE_KQUEUE):
// dfmt on
import hunt.event.selector.Selector;
import hunt.event.timer.Kqueue;
import hunt.Exceptions;
import hunt.io.channel;
import hunt.logging;
import hunt.util.CompilerHelper;

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
import hunt.util.worker;

/**
 * 
 */
class AbstractSelector : Selector {
    // kevent array size
    enum int NUM_KEVENTS = 128;
    private bool isDisposed = false;
    private Kevent[NUM_KEVENTS] events;
    private int _kqueueFD;
    private EventChannel _eventChannel;

    this(size_t number, size_t divider, Worker worker = null, size_t maxChannels = 1500) {
        super(number, divider, worker, maxChannels);
        _kqueueFD = kqueue();
        _eventChannel = new KqueueEventChannel(this);
        register(_eventChannel);
    }

    ~this() @nogc {
        // dispose();
    }

    override void dispose() {
        if (isDisposed)
            return;

        version (HUNT_IO_DEBUG)
            tracef("disposing selector[fd=%d]...", _kqueueFD);
        isDisposed = true;
        _eventChannel.close();
        int r = core.sys.posix.unistd.close(_kqueueFD);
        if(r != 0) {
            version(HUNT_DEBUG) warningf("error: %d", r);
        }

        super.dispose();
    }

    override void onStop() {
        version (HUNT_IO_DEBUG)
            infof("Selector stopping. fd=%d", _kqueueFD);  
               
        if(!_eventChannel.isClosed()) {
            _eventChannel.trigger();
            // _eventChannel.onWrite();
        }
    }

    override bool register(AbstractChannel channel) {
        super.register(channel);
        
        const int fd = channel.handle;
        version (HUNT_IO_DEBUG)
            tracef("register channel: fd=%d, type=%s", fd, channel.type);

        int err = -1;
        if (channel.type == ChannelType.Timer) {
            Kevent ev;
            AbstractTimer timerChannel = cast(AbstractTimer) channel;
            if (timerChannel is null)
                return false;
            size_t time = timerChannel.time < 20 ? 20 : timerChannel.time; // in millisecond
            EV_SET(&ev, timerChannel.handle, EVFILT_TIMER,
                    EV_ADD | EV_ENABLE | EV_CLEAR, 0, time, cast(void*) channel);
            err = kevent(_kqueueFD, &ev, 1, null, 0, null);
        }
        else {
            if (fd < 0)
                return false;
            Kevent[2] ev = void;
            short read = EV_ADD | EV_ENABLE;
            short write = EV_ADD | EV_ENABLE;
            if (channel.hasFlag(ChannelFlag.ETMode)) {
                read |= EV_CLEAR;
                write |= EV_CLEAR;
            }
            EV_SET(&(ev[0]), fd, EVFILT_READ, read, 0, 0, cast(void*) channel);
            EV_SET(&(ev[1]), fd, EVFILT_WRITE, write, 0, 0, cast(void*) channel);
            if (channel.hasFlag(ChannelFlag.Read) && channel.hasFlag(ChannelFlag.Write))
                err = kevent(_kqueueFD, &(ev[0]), 2, null, 0, null);
            else if (channel.hasFlag(ChannelFlag.Read))
                err = kevent(_kqueueFD, &(ev[0]), 1, null, 0, null);
            else if (channel.hasFlag(ChannelFlag.Write))
                err = kevent(_kqueueFD, &(ev[1]), 1, null, 0, null);
        }
        if (err < 0) {
            return false;
        }
        return true;
    }

    override bool deregister(AbstractChannel channel) {
        scope(exit) {
            super.deregister(channel);
            version (HUNT_IO_DEBUG)
                tracef("deregister, channel(fd=%d, type=%s)", channel.handle, channel.type);
        }
        
        const fd = channel.handle;
        if (fd < 0)
            return false;

        int err = -1;
        if (channel.type == ChannelType.Timer) {
            Kevent ev;
            AbstractTimer timerChannel = cast(AbstractTimer) channel;
            if (timerChannel is null)
                return false;
            EV_SET(&ev, fd, EVFILT_TIMER, EV_DELETE, 0, 0, cast(void*) channel);
            err = kevent(_kqueueFD, &ev, 1, null, 0, null);
        }
        else {
            Kevent[2] ev = void;
            EV_SET(&(ev[0]), fd, EVFILT_READ, EV_DELETE, 0, 0, cast(void*) channel);
            EV_SET(&(ev[1]), fd, EVFILT_WRITE, EV_DELETE, 0, 0, cast(void*) channel);
            if (channel.hasFlag(ChannelFlag.Read) && channel.hasFlag(ChannelFlag.Write))
                err = kevent(_kqueueFD, &(ev[0]), 2, null, 0, null);
            else if (channel.hasFlag(ChannelFlag.Read))
                err = kevent(_kqueueFD, &(ev[0]), 1, null, 0, null);
            else if (channel.hasFlag(ChannelFlag.Write))
                err = kevent(_kqueueFD, &(ev[1]), 1, null, 0, null);
        }
        if (err < 0) {
            return false;
        }
        // channel.currtLoop = null;
        channel.clear();
        return true;
    }

    protected override int doSelect(long timeout) {
        // void* [] tmp;
        // eventBuffer = tmp;
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
            const int timeoutMax = int.max;
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
        int result = kevent(_kqueueFD, null, 0, events.ptr, events.length, tsp);

        foreach (i; 0 .. result) {
            AbstractChannel channel = cast(AbstractChannel)(events[i].udata);
            ushort eventFlags = events[i].flags;
            version (HUNT_IO_DEBUG)
            infof("handling event: events=%d, fd=%d", eventFlags, channel.handle);

            if (eventFlags & EV_ERROR) {
                warningf("channel[fd=%d] has a error.", channel.handle);
                channel.close();
                continue;
            }
            if (eventFlags & EV_EOF) {
                version (HUNT_IO_DEBUG) infof("channel[fd=%d] closed", channel.handle);
                channel.close();
                continue;
            }

            short filter = events[i].filter;
            handeChannelEvent(channel, filter);
        }
        return result;
    }

    private void handeChannelEvent(AbstractChannel channel, uint filter) {
        version (HUNT_IO_DEBUG)
        infof("handling event: events=%d, fd=%d", filter, channel.handle);

        try {
            if(filter == EVFILT_TIMER) {
                channel.onRead();
            } else if (filter == EVFILT_WRITE) {
                channel.onWrite();
            } else if (filter == EVFILT_READ) {
                channel.onRead();
            } else {
                warningf("Unhandled channel fileter: %d", filter);
            }
        } catch(Exception e) {
            errorf("error while handing channel: fd=%s, message=%s",
                        channel.handle, e.msg);
        }
    }
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

extern (D) void EV_SET(Kevent* kevp, typeof(Kevent.tupleof) args) @nogc nothrow {
    *kevp = Kevent(args);
}

struct Kevent {
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
    int kevent(int kq, const Kevent* changelist, int nchanges,
            Kevent* eventlist, int nevents, const timespec* timeout) @nogc nothrow;
}

static if (CompilerHelper.isLessThan(2078)) {
    enum SO_REUSEPORT = 0x0200;
}
