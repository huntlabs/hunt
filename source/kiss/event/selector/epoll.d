/*
 * Kiss - A refined core library for D programming language.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.cn
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
module kiss.event.selector.epoll;

// dfmt off
version(linux):

// dfmt on

import std.exception;
import std.socket;
import std.string;
import kiss.logger;

import core.time;
import core.stdc.string;
import core.stdc.errno;
import core.sys.posix.sys.types; // for ssize_t, size_t
import core.sys.posix.netinet.tcp;
import core.sys.posix.netinet.in_;
import core.sys.posix.unistd;
import core.sys.posix.time : itimerspec, CLOCK_MONOTONIC;

import kiss.event.core;
import kiss.event.socket;
import kiss.event.timer;
import kiss.event.timer.epoll;

/**
*/
class AbstractSelector : Selector
{
    this()
    {
        _epollFD = epoll_create1(0);
        _event = new EpollEventChannel(this);
        register(_event);
    }
    
    ~this()
    {
        dispose();
    }

    void dispose()
    {
        if(isDisposed)
            return;
        isDisposed = true;
        deregister(_event);
        core.sys.posix.unistd.close(_epollFD);
    }
    private bool isDisposed = false;


    override bool register(AbstractChannel watcher)
    {
        assert(watcher !is null);

        if (watcher.type == WatcherType.Timer)
        {
            auto wt = cast(AbstractTimer) watcher;
            if (wt !is null)
                wt.setTimer();
        }

        // version(KissDebugMode) infof("register, watcher(fd=%d)", watcher.handle);
        const fd = watcher.handle;
        assert(fd >= 0, "The watcher.handle is not initilized!");

        // if(fd < 0) return false;
        epoll_event ev = buildEpollEvent(watcher);
        if ((epoll_ctl(_epollFD, EPOLL_CTL_ADD, fd, &ev)) != 0)
        {
            if (errno != EEXIST)
                return false;
        }
        
        _event.setNext(watcher);
        return true;
    }

    override bool reregister(AbstractChannel watcher)
    {
        assert(watcher !is null);
        const int fd = watcher.handle; 
        if (fd < 0)
            return false;
        auto ev = buildEpollEvent(watcher);
       return epoll_ctl(_epollFD, EPOLL_CTL_MOD, fd, &ev) == 0;
    }

    override bool deregister(AbstractChannel watcher)
    {
        assert(watcher !is null);
        // version(KissDebugMode) infof("unregister watcher(fd=%d)", watcher.handle);

        const int fd = watcher.handle;
        if (fd < 0)
            return false;

        if ((epoll_ctl(_epollFD, EPOLL_CTL_DEL, fd, null)) != 0)
        {
            errorf("unregister failed, watcher.handle=%d", watcher.handle);
            return false;
        }
        // TODO: check this
        // watcher.currtLoop = null;
        // watcher.clear();
        return true;
    }

 
    void onLoop(scope void delegate() weak)
    {
        _runing = true;
        do
        {
            weak();
            handleEpollEvent();
        }
        while (_runing);
    }

    private void handleEpollEvent()
    {
        epoll_event[64] events;
        const int len = epoll_wait(_epollFD, events.ptr, events.length, 10);
        foreach (i; 0 .. len)
        {
            AbstractChannel watch = cast(AbstractChannel)(events[i].data.ptr);
            if (watch is null)
            {
                warningf("watcher(fd=%d) is null", watch.handle);
                continue;
            }

            if (isErro(events[i].events))
            {
                version(KissDebugMode) info("close event: ", watch.handle);
                watch.close();
                continue;
            }

            if (watch.isRegistered && isRead(events[i].events))
            {
                watch.onRead();
            }

            if (watch.isRegistered && isWrite(events[i].events))
            {
                AbstractSocketChannel wt = cast(AbstractSocketChannel) watch;
                    assert(wt !is null);
                    wt.onWriteDone();
                // watch.onWrite();
            }
        }
    }

    override void stop()
    {
        _runing = false;
    }

protected:
    bool isErro(uint events) nothrow
    {
        return (events & (EPOLLHUP | EPOLLERR | EPOLLRDHUP)) != 0;
    }

    bool isRead(uint events) nothrow
    {
        return (events & EPOLLIN) != 0;
    }

    bool isWrite(uint events) nothrow
    {
        return (events & EPOLLOUT) != 0;
    }

    static epoll_event buildEpollEvent(AbstractChannel watch)
    {
        epoll_event ev;
        ev.data.ptr = cast(void*) watch;
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

private:
    bool _runing;
    int _epollFD;
    EventChannel _event;
}

/**
*/
class EpollEventChannel : EventChannel
{
    alias UlongObject = BaseTypeObject!ulong;
    this(Selector loop)
    {
        super(loop);
        setFlag(WatchFlag.Read, true);
        _readBuffer = new UlongObject();
        this.handle = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
    }

    ~this()
    {
        close();
    }

    override void call()
    {
        ulong value = 1;
        core.sys.posix.unistd.write(this.handle, &value, value.sizeof);
    }

    override void onRead()
    {
        readEvent((Object obj) {  });
        super.onRead();
    }

    bool readEvent(scope ReadCallBack read)
    {
        this.clearError();
        ulong value;
        core.sys.posix.unistd.read(this.handle, &value, value.sizeof);
        this._readBuffer.data = value;
        if (read)
            read(this._readBuffer);
        return false;
    }

    UlongObject _readBuffer;
}

enum
{
    EFD_SEMAPHORE = 0x1,
    EFD_CLOEXEC = 0x80000,
    EFD_NONBLOCK = 0x800
};

enum
{
    EPOLL_CLOEXEC = 0x80000,
    EPOLL_NONBLOCK = 0x800
}

enum
{
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
enum
{
    EPOLL_CTL_ADD = 1, // Add a file descriptor to the interface.
    EPOLL_CTL_DEL = 2, // Remove a file descriptor from the interface.
    EPOLL_CTL_MOD = 3, // Change file descriptor epoll_event structure.
}



// dfmt off
extern (C) : @system : nothrow :
// dfmt on

align(1) struct epoll_event
{
align(1):
uint events;
    epoll_data_t data;
}

union epoll_data_t
{
    void* ptr;
    int fd;
    uint u32;
    ulong u64;
}

int epoll_create(int size);
int epoll_create1(int flags);
int epoll_ctl(int epfd, int op, int fd, epoll_event* event);
int epoll_wait(int epfd, epoll_event* events, int maxevents, int timeout);

socket_t eventfd(uint initval, int flags);

