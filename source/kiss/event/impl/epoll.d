module kiss.event.impl.epoll;

import kiss.event.base;
import kiss.event.watcher;
import kiss.event.impl.epoll_watcher;

import std.socket;
import std.string;

import core.time;
import core.stdc.string;
import core.stdc.errno;
import core.sys.posix.sys.types; // for ssize_t, size_t
import core.sys.posix.netinet.tcp;
import core.sys.posix.netinet.in_;
import core.sys.posix.time : itimerspec, CLOCK_MONOTONIC;
import core.sys.posix.unistd;

final class EpollLoop : BaseLoop
{
    this(){
        _epollFD = epoll_create1(0);
        _event = new EpollEventWatcher();
        register(_event);
    }

    ~this(){
        //unRegister(_event);
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
                canRead = readEvent(cast(EpollEventWatch)watcher,read);
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
        unRegister(watcher);
        int fd = getFD(watcher);
        if(fd < 0) return false;
        .close(fd);
    }

    override bool register(Watcher watcher)
    {
        if(watcher is null || watcher.active) return false;
        int fd = getFD(watcher);
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

    override bool reRegister(Watcher watcher)
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

    override bool unRegister(Watcher watcher)
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
            const auto len = epoll_wait(_epollFD, events.ptr, 64, 1000);
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
        ev.data.ptr = event;
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
            fd = getSocketFD!TcpSocketWatcher(watch);
            break;
        case WatcherType.UDP:
            fd = getSocketFD!UDPSocketWatcher(watch);
            break;
        case WatcherType.ACCEPT:
            fd = getSocketFD!AcceptorWatcher(watch);
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


extern (C) : @system : nothrow : enum {
    EFD_SEMAPHORE = 0x1,
    EFD_CLOEXEC = 0x80000,
    EFD_NONBLOCK = 0x800
};

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

align(1) struct epoll_event {
    align(1) : uint events;
    epoll_data_t data;
}

union epoll_data_t {
    void * ptr;
    int fd;
    uint u32;
    ulong u64;
}

int epoll_create(int size);
int epoll_create1(int flags);
int epoll_ctl(int epfd, int op, int fd, epoll_event * event);
int epoll_wait(int epfd, epoll_event * events, int maxevents, int timeout);

int eventfd(uint initval, int flags);

//timerfd

int timerfd_create(int clockid, int flags);
int timerfd_settime(int fd, int flags, const itimerspec * new_value, itimerspec * old_value);
int timerfd_gettime(int fd, itimerspec * curr_value);

enum TFD_TIMER_ABSTIME = 1 << 0;
enum TFD_CLOEXEC = 0x80000;
enum TFD_NONBLOCK = 0x800;
