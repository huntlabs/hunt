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

import core.memory;
import core.sys.posix.time;
import core.thread;
import std.variant;
import std.socket;

alias timer_handler = void delegate(int timerId);

class Timer : Event{

public:
    
    static create(AsynchronousChannelSelector selector = null)
    {
        if (selector is null) {
            Thread thread = Thread.getThis();
            if (typeid(thread) == typeid(AsynchronousChannelSelector))
                throw new Exception("Timer must create in io thread!!!");
            return new Timer(cast(AsynchronousChannelSelector)thread);
        }   
        else {
            return new Timer(selector);
        }    
    }
    
    this(AsynchronousChannelSelector sel)
    {
        _selector = sel;
        
    }
    
    int start(long delay, timer_handler handler, bool loop)
    {
        _handler = handler;
        _loop = loop;
        _readyClose = false;
        version(linux) {
            import kiss.aio.Epoll;

            _timerId = cast(int)timerfd_create(CLOCK_REALTIME, TFD_NONBLOCK | TFD_CLOEXEC);
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
                _timerId = -1;
                return -1;
            }
        }
        _selector.addEvent(this,  _timerId,  AIOEventType.OP_READED);
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
        version(linux) {
            import core.sys.posix.unistd;
            ulong value;
            read(_timerId, &value, 8);
        }
        _handler(_timerId);
        return _loop;
    }
    override bool onClose()
    {
        version(linux)
        {
            import core.sys.posix.unistd;
            _selector.delEvent(this , _timerId, AIOEventType.OP_NONE);
            close(_timerId);
            _timerId = -1;
        } 
        return true;
    }
	override bool isReadyClose()
    {
        return _readyClose;
    }

private:
    AsynchronousChannelSelector _selector;
    timer_handler _handler;
    bool _loop;
    int _timerId;
    bool _readyClose;
}

unittest {
    AsynchronousChannelSelector selector = new AsynchronousChannelSelector(10);
    Timer timer = Timer.create(selector);
    timer.start(2000, (int timerid) {
        writeln("timer callback~~~~~~");
    }, true);
    selector.start();
    selector.wait();
}