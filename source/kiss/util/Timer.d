/*
 * KISS - A refined core library for dlang
 *
 * Copyright (C) 2015-2017  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module kiss.util.Timer;

import kiss.aio.AsynchronousChannelSelector;
import kiss.aio.Event;
import kiss.util.Common;

import core.memory;
import core.sys.posix.time;
import core.thread;
import std.variant;
import std.socket;

alias timer_handler = void delegate(int timerId);

class Timer : Event {

public:
    
    static create(AsynchronousChannelSelector selector = null)
    {
        if (selector is null) {
            Thread thread = Thread.getThis();
            if (typeid(thread) == typeid(AsynchronousChannelSelector))
                return new Timer(cast(AsynchronousChannelSelector)thread);
            throw new Exception("Timer must create in io thread!!!");
        }   
        else {
            return new Timer(selector);
        }    
    }
    
    this(AsynchronousChannelSelector sel)
    {
        _selector = sel;
    }
    
    //loopTimes -1: always loop
    socket_t start(long delay, timer_handler handler, int loopTimes = 1)
    {
        _intervalTime = delay;
        _handler = handler;
        _loopTimes = loopTimes;
        _readyClose = false;
        static if (IOMode == IO_MODE.epoll) {
            import kiss.aio.Epoll;
            _timerId = cast(socket_t)timerfd_create(CLOCK_REALTIME, TFD_NONBLOCK | TFD_CLOEXEC);
            itimerspec its;
            ulong sec, nsec;
            sec = delay / 1000;
            nsec = (delay % 1000) * 1_000_000;
            its.it_value.tv_sec = cast(typeof(its.it_value.tv_sec)) sec;
            its.it_value.tv_nsec = cast(typeof(its.it_value.tv_nsec)) nsec;
            its.it_interval.tv_sec = its.it_value.tv_sec;
            its.it_interval.tv_nsec = its.it_value.tv_nsec;
            int err = timerfd_settime(_timerId, 0, &its, null);
            if (err == -1)
            {
                import core.sys.posix.unistd;
                close(cast(int)_timerId);
                _timerId = cast(socket_t)(-1);
                return cast(socket_t)(-1);
            }
            _selector.addEvent(this,  _timerId,  EventType.TIMER);
        }
        else if (IOMode == IO_MODE.kqueue) {
            import core.atomic;
            static shared int i = int.max;
            atomicOp!"-="(i, 1);
            if (i < 655350)
                i = int.max;
            _timerId = cast(socket_t) i;
            _selector.addEvent(this,  _timerId,  EventType.TIMER);
        }

        return _timerId;
    }

    void stop()
    {
        _readyClose = true;
    }

    override bool onWrite()
    {
        return true;
    }
    override bool onRead()
    {
        static if (IOMode == IO_MODE.epoll) {
            import core.sys.posix.unistd;
            ulong value;
            read(_timerId, &value, 8);
        }
        _handler(_timerId);
        if (_loopTimes > 0)
            _loopTimes --;
        return _loopTimes != 0;
    }
    override bool onClose()
    {
        static if (IOMode == IO_MODE.epoll)
        {
            import core.sys.posix.unistd;
            _selector.delEvent(this , _timerId, EventType.TIMER);
            close(_timerId);
            _timerId = cast(socket_t)(-1);
        } 
        else if(IOMode == IO_MODE.kqueue)
        {
            _selector.delEvent(this , _timerId, EventType.TIMER);
        }
        return true;
    }
	override bool isReadyClose()
    {
        return _readyClose;
    }

public:
    long _intervalTime;

    
private:
    AsynchronousChannelSelector _selector;
    timer_handler _handler;
    int _loopTimes;
    socket_t _timerId;
    bool _readyClose;
}

unittest {

    import std.stdio;

    AsynchronousChannelSelector selector = new AsynchronousChannelSelector(10);
    Timer timer = Timer.create(selector);
    timer.start(2000, (socket_t timerid) {
        writeln("timer callback~~~~~~");
    }, 3);
    selector.start();
    selector.wait();

}