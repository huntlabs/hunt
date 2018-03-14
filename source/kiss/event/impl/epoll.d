module kiss.event.impl.epoll;

version(linux):

import kiss.event.base;
import kiss.event.watcher;
import kiss.event.impl.epoll_watcher;

import std.socket;
import std.string;
import std.experimental.logger;

import core.time;
import core.stdc.string;
import core.stdc.errno;
import core.sys.posix.sys.types; // for ssize_t, size_t
import core.sys.posix.netinet.tcp;
import core.sys.posix.netinet.in_;
import core.sys.posix.unistd;


/**
*/
final class EpollLoop : BaseLoop
{
    this(){
        _epollFD = epoll_create1(0);
        _event = new EpollEventWatcher();
        register(_event);
    }

    void dispose(){
        deregister(_event);
        core.sys.posix.unistd.close(_epollFD);
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
        // debug infof("close, watcher(fd=%d)", watcher.fd);

        if(!deregister(watcher)) 
            return false;

        if(watcher.type == WatcherType.TCP){
            TcpStreamWatcher wt = cast(TcpStreamWatcher)watcher;
            wt.socket.close();
        }
        else
        {
            assert(watcher.fd >= 0);
            core.sys.posix.unistd.close(watcher.fd);
        }
        
        return true;
    }

    override bool register(Watcher watcher)
    {
        if(watcher is null || watcher.active) return false;
        int fd = watcher.fd;
        if(watcher.type == WatcherType.Timer){
            auto wt = cast(EpollTimerWatcher)watcher;
            if(wt !is null ){
                wt.setTimer();
            }
        }

        // debug infof("register, watcher[%d].fd=%d, actual fd=%d", watcher.number, watcher.fd, fd);
        // if(watcher.fd != fd)
        //     watcher.fd = fd;

        // debug infof("register, watcher(fd=%d)", watcher.fd);
        assert(fd>=0, "The watcher.fd is not initilized!");

        // if(fd < 0) return false;
        epoll_event ev = buildEpollEvent(watcher);
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
        // debug infof("unregister watcher(fd=%d)", watcher.fd);

        if(watcher is null || watcher.currtLoop !is this) return false;
        const int fd = watcher.fd;
        if(fd < 0) return false;

        if ((epoll_ctl(_epollFD, EPOLL_CTL_DEL, fd,  null)) != 0) {
            errorf("unregister failed, watcher.fd=%d", watcher.fd);
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

    override void join(scope void delegate()nothrow weak)
    {
        _runing = true;
        do{
            weak();
            handleEpollEvent();
        } while(_runing);
    }

    private void handleEpollEvent()
    {
        epoll_event[64] events;
        const int len = epoll_wait(_epollFD, events.ptr, events.length, 10);
        foreach(i;0..len){
            Watcher watch = cast(Watcher)(events[i].data.ptr);
            if(watch is null)
            {
                warningf("watcher(fd=%d) is null", watch.fd);
                continue;
            }

            if (isErro(events[i].events)) {
                watch.onClose();
                continue;
            }
            if (watch.active && isRead(events[i].events)) 
                watch.onRead();

            if (watch.active && isWrite(events[i].events)) 
                watch.onWrite();
        }
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
    static epoll_event buildEpollEvent(Watcher watch){
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

    static int getFD(Watcher watch){
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



