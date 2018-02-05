module kiss.event.impl.epoll;

import kiss.event.base;
import kiss.event.watcher;
version(linux):
import kiss.event.impl.epoll_watcher;

import std.socket;
import std.string;

import core.time;
import core.stdc.string;
import core.stdc.errno;
import core.sys.posix.sys.types; // for ssize_t, size_t
import core.sys.posix.netinet.tcp;
import core.sys.posix.netinet.in_;
import core.sys.posix.unistd;

final class EpollLoop : BaseLoop
{
    this(){
        _epollFD = epoll_create1(0);
        _event = new EpollEventWatcher();
        register(_event);
    }

    ~this(){
        //deregister(_event);
        .close(_epollFD);
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
            returnValue = new EpollEventWatcher();
            break;
        case Timer:
            returnValue = new EpollTimerWatcher();
            break;
        default:
            break;
        }
        return returnValue;
    }

    override bool read(Watcher watcher,scope ReadCallBack read)
    {
        bool canRead = false;
        switch(watcher.type){
            case WatcherType.Timer:
                canRead = readTimer(cast(EpollTimerWatcher)watcher,read);
            break;
            case WatcherType.ACCEPT:
                canRead = readAccept(cast(PosixAcceptWatcher)watcher, read);
            break;
            case WatcherType.Event:
                canRead = readEvent(cast(EpollEventWatcher)watcher,read);
            break;
            case WatcherType.TCP:
                canRead = readTcp(cast(PosixTCPWatcher)watcher,read);
            break;
            case WatcherType.UDP:
                canRead = readUdp(cast(PosixUDPWatcher)watcher,read);
            break;
            default:
            break;
        }
        return canRead;
    }

    override bool connect(Watcher watcher,Address addr)
    {
        if(watcher.type == WatcherType.TCP){
            return connectTCP(cast(PosixTCPWatcher)watcher,addr);
        }
        return false;
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
        }
        fd = getFD(watcher);
        
        if(fd < 0) return false;
        .close(fd);
        return true;
    }

    override bool register(Watcher watcher)
    {
        if(watcher is null || watcher.active) return false;
        int fd = -1;
        if(watcher.type == WatcherType.Timer){
            auto wt = cast(EpollTimerWatcher)watcher;
            if(wt !is null && wt.setTimer()){
                fd = wt._timerFD;
            }
        } else {
            fd = getFD(watcher);
        }
        if(fd < 0) return false;
        auto ev = buildEpollEvent(watcher);
        if ((epoll_ctl(_epollFD, EPOLL_CTL_ADD, fd,  & ev)) != 0) {
            if (errno != EEXIST)
                return false;
        }
        watcher.currtLoop = this;
        _event.setNext(watcher);
        return true;
    }

    override bool reregister(Watcher watcher)
    {
        if(watcher is null || watcher.currtLoop !is this) return false;
        const int fd = getFD(watcher);
        if(fd < 0) return false;
        auto ev = buildEpollEvent(watcher);
        if ((epoll_ctl(_epollFD, EPOLL_CTL_MOD, fd,  & ev)) != 0) {
            return false;
        }
        return true;
    }

    override bool deregister(Watcher watcher)
    {
        if(watcher is null || watcher.currtLoop !is this) return false;
        const int fd = getFD(watcher);
        if(fd < 0) return false;
        epoll_event ev;
        if ((epoll_ctl(_epollFD, EPOLL_CTL_DEL, fd,  &ev)) != 0) {
            //yuCathException(error("EPOLL_CTL_DEL erro! ", event.fd));
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
        do{
            weak();
            epoll_event[64] events;
            const auto len = epoll_wait(_epollFD, events.ptr, 64, 10);
            if(len < 1) continue;
            foreach(i;0..len){
                Watcher watch = cast(Watcher)(events[i].data.ptr);
                if (isErro(events[i].events)) {
                    watch.onClose();
                    continue;
                }
                if (isWrite(events[i].events) && watch.active ) 
                    watch.onWrite();

                if (isRead(events[i].events) && watch.active ) 
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
    pragma(inline, true) bool isErro(uint events)  nothrow {
        return (events & (EPOLLHUP | EPOLLERR | EPOLLRDHUP)) != 0;
    }
    pragma(inline, true) bool isRead(uint events)  nothrow {
        return (events & EPOLLIN) != 0;
    }
    pragma(inline, true) bool isWrite(uint events)  nothrow  {
        return (events & EPOLLOUT) != 0;
    }
    epoll_event buildEpollEvent(Watcher watch){
        epoll_event ev;
        ev.data.ptr = cast(void *)watch;
        ev.events = EPOLLRDHUP | EPOLLERR | EPOLLHUP;
        if (watch.flag(WatchFlag.Read))
            ev.events |= EPOLLIN;
        if (watch.flag(WatchFlag.Write))
            ev.events |= EPOLLOUT;
        if (watch.flag(WatchFlag.OneShot))
            ev.events |= EPOLLONESHOT;
        if (watch.flag(WatchFlag.ETMode))
            ev.events |= EPOLLET;
        return ev;
    }

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
            auto wt = cast(EpollEventWatcher)watch;
            if(wt !is null) fd = wt._eventFD;
        }
            break;
        case WatcherType.Timer:
        {
            auto wt = cast(EpollTimerWatcher)watch;
            if(wt !is null) fd = wt._timerFD;
        }
            break;
        default:
            break;
        }
        return fd;
    }
private:
    bool _runing;
    int _epollFD;
    EpollEventWatcher _event;
}



