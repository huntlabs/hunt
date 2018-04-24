module kiss.event.selector.kqueue;

import kiss.event.core;

// version (FreeBSD)
// {
//     version = Kqueue;
// }
// version (OpenBSD)
// {
//     version = Kqueue;
// }
// version (NetBSD)
// {
//     version = Kqueue;
// }
// version (OSX)
// {
//     version = Kqueue;
// }

// dfmt off
version(Kqueue):

deprecated("Using KqueueSelector instead!")
alias KqueueLoop = KqueueSelector;
// dfmt on

import kiss.event.core;

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
final class AbstractSelector : Selector
{
    this()
    {
        _kqueueFD = kqueue();
        _event = new KqueueEventWatcher();
        register(_event);
    }

    ~this()
    {
        .close(_kqueueFD);
    }

    override bool read(Watcher watcher, scope ReadCallBack read)
    {
        bool canRead;
        switch (watcher.type)
        {
        case WatcherType.Accept:
            canRead = (cast(PosixAcceptor) watcher).readAccept(read);
            break;
        case WatcherType.TCP:
            canRead = (cast(PosixStream) watcher).tryRead(read);
            break;
        case WatcherType.UDP:
            canRead = (cast(PosixDatagram) watcher).readUdp(read);
            break;

        case WatcherType.Timer:
            canRead = (cast(KqueueTimer) watcher).readTimer(read);
            break;
        case WatcherType.Event:
            canRead = (cast(KqueueEventChannel) watcher).readEvent(read);
            break;
        default:
            break;
        }
        return canRead;
    }

    override bool connect(Watcher watcher, Address addr)
    {
        if (watcher.type == WatcherType.TCP)
        {
            (cast(AbstractSocketChannel) watcher).socket.connect(addr);
            return true;
        }
        return false;
    }

    override bool write(Watcher watcher, in ubyte[] data, out size_t writed)
    {
        if (watcher.type == WatcherType.TCP)
        {
            return (cast(EpollStream) watcher).tryWrite(data, writed);
        }
        writed = 0;
        return false;
    }

    override bool close(Watcher watcher)
    {
        deregister(watcher);
        if (watcher.type == WatcherType.TCP)
        {
            // TcpStreamWatcher wt = cast(TcpStreamWatcher) watcher;
            // wt.socket.close();
            watcher.close();
        }
        else
        {
            assert(watcher.handle >= 0);
            core.sys.posix.unistd.close(watcher.handle);
        }

        // int fd = -1;
        // if (watcher.type == WatcherType.TCP)
        // {
        //     TcpStreamWatcher wt = cast(TcpStreamWatcher) watcher;
        //     Linger optLinger;
        //     optLinger.on = 1;
        //     optLinger.time = 0;
        //     wt.socket.setOption(SocketOptionLevel.SOCKET, SocketOption.LINGER, optLinger);
        // }
        // else if (watcher.type == WatcherType.Event)
        // {
        //     KqueueEventWatcher wt = cast(KqueueEventWatcher) watcher;
        //     wt._pair[0].close;
        //     wt._pair[1].close;
        // }
        // else
        // {
        //     fd = getFD(watcher);
        // }
        // if (fd < 0)
        //     return false;
        // .close(fd);
        return true;
    }

    override bool register(Watcher watcher)
    {
        if (watcher is null || watcher.active)
            return false;
        int err = -1;
        if (watcher.type == WatcherType.Timer)
        {
            kevent_t ev;
            KqueueTimerWatcher watch = cast(KqueueTimerWatcher) watcher;
            if (watch is null)
                return false;
            size_t time = watch.time < 20 ? 20 : watch.time;
            EV_SET(&ev, watch.fd(), EVFILT_TIMER, EV_ADD | EV_ENABLE | EV_CLEAR,
                    0, time, cast(void*) watcher); //单位毫秒
            err = kevent(_kqueueFD, &ev, 1, null, 0, null);
        }
        else
        {
            const int fd = getFD(watcher);
            if (fd < 0)
                return false;
            kevent_t[2] ev = void;
            short read = EV_ADD | EV_ENABLE;
            short write = EV_ADD | EV_ENABLE;
            if (watcher.flag(WatchFlag.ETMode))
            {
                read |= EV_CLEAR;
                write |= EV_CLEAR;
            }
            EV_SET(&(ev[0]), fd, EVFILT_READ, read, 0, 0, cast(void*) watcher);
            EV_SET(&(ev[1]), fd, EVFILT_WRITE, write, 0, 0, cast(void*) watcher);
            if (watcher.flag(WatchFlag.Read) && watcher.flag(WatchFlag.Write))
                err = kevent(_kqueueFD, &(ev[0]), 2, null, 0, null);
            else if (watcher.flag(WatchFlag.Read))
                err = kevent(_kqueueFD, &(ev[0]), 1, null, 0, null);
            else if (watcher.flag(WatchFlag.Write))
                err = kevent(_kqueueFD, &(ev[1]), 1, null, 0, null);
        }
        if (err < 0)
        {
            return false;
        }
        watcher.currtLoop = this;
        _event.setNext(watcher);
        return true;
    }

    override bool reregister(Watcher watcher)
    {
        throw new LoopException("The Kqueue does not support reregister!");
        //return false;
    }

    override bool deregister(Watcher watcher)
    {
        if (watcher is null || watcher.currtLoop !is this)
            return false;
        int err = -1;
        if (watcher.type == WatcherType.Timer)
        {
            kevent_t ev;
            KqueueTimerWatcher watch = cast(KqueueTimerWatcher) watcher;
            if (watch is null)
                return false;
            EV_SET(&ev, watch.fd(), EVFILT_TIMER, EV_DELETE, 0, 0, cast(void*) watcher); //单位毫秒
            err = kevent(_kqueueFD, &ev, 1, null, 0, null);
        }
        else
        {
            const int fd = getFD(watcher);
            if (fd < 0)
                return false;
            kevent_t[2] ev = void;
            EV_SET(&(ev[0]), fd, EVFILT_READ, EV_DELETE, 0, 0, cast(void*) watcher);
            EV_SET(&(ev[1]), fd, EVFILT_WRITE, EV_DELETE, 0, 0, cast(void*) watcher);
            if (watcher.flag(WatchFlag.Read) && watcher.flag(WatchFlag.Write))
                err = kevent(_kqueueFD, &(ev[0]), 2, null, 0, null);
            else if (watcher.flag(WatchFlag.Read))
                err = kevent(_kqueueFD, &(ev[0]), 1, null, 0, null);
            else if (watcher.flag(WatchFlag.Write))
                err = kevent(_kqueueFD, &(ev[1]), 1, null, 0, null);
        }
        if (err < 0)
        {
            return false;
        }
        watcher.currtLoop = null;
        watcher.clear();
        return true;
    }

    override bool weakUp()
    {
        _event.call();
        return true;
    }

    // while(true)
    override void join(scope void delegate() nothrow weak)
    {
        _runing = true;
        auto tspec = timespec(1, 1000 * 10);
        do
        {
            weak();
            kevent_t[64] events;
            auto len = kevent(_kqueueFD, null, 0, events.ptr, events.length, &tspec);
            if (len < 1)
                continue;
            foreach (i; 0 .. len)
            {
                Watcher watch = cast(Watcher)(events[i].udata);
                if ((events[i].flags & EV_EOF) || (events[i].flags & EV_ERROR))
                {
                    watch.onClose();
                    continue;
                }
                if (watch.type == WatcherType.Timer)
                {
                    watch.onRead();
                    continue;
                }
                if ((events[i].filter & EVFILT_WRITE) && watch.active)
                    watch.onWrite();

                if ((events[i].filter & EVFILT_READ) && watch.active)
                    watch.onRead();
            }
        }
        while (_runing);
    }

    override void stop()
    {
        _runing = false;
        weakUp();
    }

protected:
    int getFD(Watcher watch)
    {
        int fd = -1;
        switch (watch.type)
        {
        case WatcherType.TCP:
            fd = getSocketFD!TcpStreamWatcher(watch);
            break;
        case WatcherType.UDP:
            fd = getSocketFD!UdpStreamWatcher(watch);
            break;
        case WatcherType.ACCEPT:
            fd = getSocketFD!TcpListenerWatcher(watch);
            break;
        case WatcherType.Event:
            {
                auto wt = cast(KqueueEventWatcher) watch;
                if (wt !is null)
                    fd = wt.fd();
            }
            break;
        case WatcherType.Timer:
            {
                auto wt = cast(KqueueTimerWatcher) watch;
                if (wt !is null)
                    fd = wt.fd();
            }
            break;
        default:
            break;
        }
        return fd;
    }

private:
    bool _runing;
    int _kqueueFD;
    KqueueEventWatcher _event;
}

/**
*/
class KqueueEventChannel : EventChannel
{
    this()
    {
        setFlag(WatchFlag.Read, true);
        _pair = socketPair();
        _pair[0].blocking = false;
        _pair[1].blocking = false;
        this.handle = _pair[1].handle;
    }

    ~this()
    {
        close();
    }

    // int fd(){return _pair[1].handle;}

    override void call()
    {
        _pair[0].send("call");
    }

    override void onRead()
    {
        ubyte[128] data;
        while (true)
        {
            collectException(() {
                if (_pair[1].receive(data) <= 0)
                    return;
            }());
        }

        super.onRead();
    }

    // mixin OverrideErro;

    Socket[2] _pair;
}

enum : short
{
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

extern (D) void EV_SET(kevent_t* kevp, typeof(kevent_t.tupleof) args) @nogc nothrow
{
    *kevp = kevent_t(args);
}

struct kevent_t
{
    uintptr_t ident; /* identifier for this event */
    short filter; /* filter for event */
    ushort flags;
    uint fflags;
    intptr_t data;
    void* udata; /* opaque user data identifier */
}

enum
{
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

enum
{
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

extern (C)
{
    int kqueue() @nogc nothrow;
    int kevent(int kq, const kevent_t* changelist, int nchanges,
            kevent_t* eventlist, int nevents, const timespec* timeout) @nogc nothrow;
}

enum SO_REUSEPORT = 0x0200;
