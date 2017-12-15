module kiss.event.impl.kqueue;

import kiss.event.base;
import kiss.event.watcher;
import kiss.event.struct_;
version(Kqueue):

import kiss.event.impl.kqueue_watcher;
import std.socket;
import std.string;

import core.time;
import core.stdc.string;
import core.stdc.errno;
import core.sys.posix.sys.types; // for ssize_t, size_t
import core.sys.posix.netinet.tcp;
import core.sys.posix.netinet.in_;
import core.sys.posix.unistd;

final class KqueueLoop : BaseLoop
{
    this(){
        _kqueueFD = kqueue();
        _event = new KqueueEventWatcher();
        register(_event);
    }

    ~this(){
        .close(_kqueueFD);
    }

    override Watcher createWatcher(WatcherType type)
    {
        Watcher returnValue;
        switch (type) with(WatcherType)
        {
        case TCP:
            returnValue = new PosixTCPWatcher();
            break;
        case UDP:
            returnValue = new PosixUDPWatcher();
            break;
        case ACCEPT:
            returnValue = new PosixAcceptWatcher();
            break;
        case Event:
            returnValue = new KqueueEventWatcher();
            break;
        case Timer:
            returnValue = new KqueueTimerWatcher();
            break;
        default:
            break;
        }
        return returnValue;
    }

    override bool read(Watcher watcher,scope ReadCallBack read)
    {
        bool canRead ;
        switch(watcher.type){
            case WatcherType.ACCEPT:
                canRead = readAccept(cast(PosixAcceptWatcher)watcher, read);
            break;
            case WatcherType.TCP:
                canRead = readTcp(cast(PosixTCPWatcher)watcher,read);
            break;
            case WatcherType.UDP:
                canRead = readUdp(cast(PosixUDPWatcher)watcher,read);
            break;
            case WatcherType.Timer:
                canRead = readTimer(cast(KqueueTimerWatcher)watcher,read);
            break;
            default:
            break;
        }
        return canRead;
    }

    override bool write(Watcher watcher,in ubyte[] data, out size_t writed)
    {
        if(watcher.type == WatcherType.TCP){
            return writeTcp(cast(PosixTCPWatcher)watcher,data,writed);
        }
        writed = 0;
        return false;
    }

    override bool close(Watcher watcher)
    {
        deregister(watcher);
        int fd = -1;
        if(watcher.type == WatcherType.TCP){
            TcpStreamWatcher wt = cast(TcpStreamWatcher)watcher;
            Linger optLinger;
            optLinger.on = 1;
            optLinger.time = 0;
            wt.socket.setOption(SocketOptionLevel.SOCKET, SocketOption.LINGER, optLinger);
        } else if(watcher.type == WatcherType.Event){
            KqueueEventWatcher wt = cast(KqueueEventWatcher)watcher;
            wt._pair[0].close;
            wt._pair[1].close;
        }else{
            fd = getFD(watcher);
        }
        if(fd < 0) return false;
        .close(fd);
        return true;
    }

    override bool register(Watcher watcher)
    {
         if(watcher is null || watcher.active) return false;
        int err = -1;
        if (watcher.type == WatcherType.Timer) {
            kevent_t ev;
            KqueueTimerWatcher watch = cast(KqueueTimerWatcher)watcher;
            if(watch is null) return false;
            size_t time = watch.time < 20 ? 20 : watch.time;
            EV_SET(&ev, watch.fd(), EVFILT_TIMER,
                EV_ADD | EV_ENABLE | EV_CLEAR, 0, time, cast(void*)watcher); //单位毫秒
            err = kevent(_kqueueFD, &ev, 1, null, 0, null);
        } else {
            const int fd = getFD(watcher);
            if(fd < 0) return false;
            kevent_t[2] ev = void;
            short read = EV_ADD | EV_ENABLE;
            short write = EV_ADD | EV_ENABLE;
            if (watcher.flag(WatchFlag.ETMode)) {
                read |= EV_CLEAR;
                write |= EV_CLEAR;
            }
            EV_SET(&(ev[0]), fd, EVFILT_READ, read, 0, 0, cast(void*)watcher);
            EV_SET(&(ev[1]), fd, EVFILT_WRITE, write, 0, 0, cast(void*)watcher);
            if(watcher.flag(WatchFlag.Read) && watcher.flag(WatchFlag.Write))
                err = kevent(_kqueueFD, &(ev[0]), 2, null, 0, null);
            else if(watcher.flag(WatchFlag.Read))
                err = kevent(_kqueueFD, &(ev[0]), 1, null, 0, null);
            else if(watcher.flag(WatchFlag.Write))
                err = kevent(_kqueueFD, &(ev[1]), 1, null, 0, null);
        } 
        if (err < 0) {
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
         if(watcher is null || watcher.currtLoop !is this) return false;
         int err = -1;
        if (watcher.type == WatcherType.Timer) {
            kevent_t ev;
            KqueueTimerWatcher watch = cast(KqueueTimerWatcher)watcher;
            if(watch is null) return false;
            EV_SET(&ev, watch.fd(), EVFILT_TIMER,
                EV_DELETE, 0, 0, cast(void*)watcher); //单位毫秒
            err = kevent(_kqueueFD, &ev, 1, null, 0, null);
        } else {
            const int fd = getFD(watcher);
            if(fd < 0) return false;
            kevent_t[2] ev = void;
            EV_SET(&(ev[0]), fd, EVFILT_READ, EV_DELETE, 0, 0, cast(void*)watcher);
            EV_SET(&(ev[1]), fd, EVFILT_WRITE, EV_DELETE, 0, 0, cast(void*)watcher);
            if(watcher.flag(WatchFlag.Read) && watcher.flag(WatchFlag.Write))
                err = kevent(_kqueueFD, &(ev[0]), 2, null, 0, null);
            else if(watcher.flag(WatchFlag.Read))
                err = kevent(_kqueueFD, &(ev[0]), 1, null, 0, null);
            else if(watcher.flag(WatchFlag.Write))
                err = kevent(_kqueueFD, &(ev[1]), 1, null, 0, null);
        } 
        if (err < 0) {
            return false;
        }
        watcher.currtLoop = null;
        watcher.clear();
        return true;
    }

    override bool weakUp(){
        _event.call();
        return true;
    }

    // while(true)
    override void join(scope void delegate()nothrow weak)
    {
        _runing = true;
        auto tspec = timespec(1,  1000 * 1000);
        do{
            weak();
            kevent_t[64] events;
            auto len = kevent(_kqueueFD, null, 0, events.ptr, 64, &tspec);
            if(len < 1) continue;
            foreach(i;0..len){
                Watcher watch = cast(Watcher)(events[i].udata);
                if ((events[i].flags & EV_EOF) || (events[i].flags & EV_ERROR)) {
                    watch.onClose();
                    continue;
                }
                if(watch.type == WatcherType.Timer){
                    watch.onRead();
                    continue;
                }
                if ((events[i].filter & EVFILT_WRITE) && watch.active ) 
                    watch.onWrite();

                if ((events[i].filter & EVFILT_READ) && watch.active ) 
                    watch.onRead();
            }
        } while(_runing);
    }

    override void stop()
    {
        _runing = false;
        weakUp();
    }

protected : 
    int getFD(Watcher watch){
        int fd = -1;
        switch(watch.type){
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
            auto wt = cast(KqueueEventWatcher)watch;
            if(wt !is null) fd = wt.fd();
        }
            break;
        case WatcherType.Timer:
        {
            auto wt = cast(KqueueTimerWatcher)watch;
            if(wt !is null) fd = wt.fd();
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

