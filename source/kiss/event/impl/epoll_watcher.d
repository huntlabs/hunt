module kiss.event.impl.epoll_watcher;

import kiss.event.base;
import kiss.event.watcher;
import kiss.event.struct_;
public import kiss.event.impl.posix_watcher;

import core.sys.posix.unistd;

final class EpollEventWatcher : Watcher 
{
    alias UlongObject = BaseTypeObject!ulong;
    this()
    {
        super(WatcherType.Event);
        setFlag(WatchFlag.Read,true);
         _readBuffer = new UlongObject();
         _eventFD = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
    }

    ~this(){
        close();
    }

    void call(){
        ulong value = 1;
        core.sys.posix.unistd.write(_eventFD,  &value, value.sizeof);
    }

    override void onRead(){
        readEvent(this,null);
    }

    mixin PosixOverrideErro;

    UlongObject _readBuffer;

    int _eventFD;
}

final class EpollTimerWatcher : TimerWatcher
{
    this()
    {
        super();
        setFlag(WatchFlag.Read,true);
        _readBuffer = new UintObject();
       _timerFD = timerfd_create(CLOCK_MONOTONIC, TFD_CLOEXEC | TFD_NONBLOCK);
    }

    ~this(){
        close();
    }

    mixin PosixOverrideErro;

    UintObject _readBuffer;

    int _timerFD;
}

bool readTimer(EpollTimerWatcher watch, scope ReadCallBack read)
{
    if(watch is null) return false;
    watch.clearError();
    ulong value;
    core.sys.posix.unistd.read(watch._timerFD, &value, 8);
    watch._readBuffer.data = value;
    if(read)
        read(watch._readBuffer);
    return false;
}

bool readEvent(EpollEventWatcher watch, scope ReadCallBack read)
{
    if(watch is null) return false;
        watch.clearError();
    ulong value;
    read(_fd,  &value, value.sizeof);
    watch._readBuffer.data = value;
    if(read)
        read(watch._readBuffer);
    return false;
}
