/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.cn
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
module hunt.util.timer;

import hunt.event;
import hunt.event.timer;
import hunt.logging;
import hunt.lang.common;

import core.time;
import std.datetime;


/**
*/
class Timer : AbstractTimer
{

    this(Selector loop)
    {
        super(loop);
        this.interval = 1000;
    }

    this(Selector loop, size_t interval)
    {
        super(loop);
        this.interval = interval;
    }

    this(Selector loop, Duration duration)
    {
        super(loop);
        this.interval = duration;
    }

protected:

    override void onRead()
    {
        bool canRead = true;
        while (canRead && _isRegistered)
        {
            canRead = readTimer((Object obj) {
                BaseTypeObject!uint tm = cast(BaseTypeObject!uint) obj;
                if (tm is null)
                    return;
                while (tm.data > 0)
                {
                    if (ticked !is null)
                        ticked(this);
                    tm.data--;
                }
            });
            if (this.isError)
            {
                canRead = false;
                this.close();
                error("the Timer Read is error: ", this.erroString);
            }
        }
    }

}

// dfmt off
version (Windows) : 

// dfmt on

import std.datetime;
import std.exception;
import std.process;

import hunt.logging;
import core.sys.windows.windows;
import core.thread;
import core.time;

/**
*/
abstract class AbstractNativeTimer : ITimer
{
    protected bool _isActive = false;
    protected size_t _interval = 1000;

    /// Timer tick handler
    TickedEventHandler ticked;

    this()
    {
        this(1000);
    }

    this(size_t interval)
    {
        this.interval = interval;
    }

    this(Duration duration)
    {
        this.interval = duration;
    }

    /// 
    @property bool isActive()
    {
        return _isActive;
    }

    /// in ms
    @property size_t interval()
    {
        return _interval;
    }

    /// ditto
    @property ITimer interval(size_t v)
    {
        _interval = v;
        return this;
    }

    /// ditto
    @property ITimer interval(Duration duration)
    {
        _interval = cast(size_t) duration.total!("msecs");
        return this;
    }

    /// The handler will be handled in another thread.
    ITimer onTick(TickedEventHandler handler)
    {
        this.ticked = handler;
        return this;
    }

    /// immediately: true to call first event immediately
    /// once: true to call timed event only once
    abstract void start(bool immediately = false, bool once = false);
    void start(uint interval)
    {
        this.interval = interval;
        start();
    }

    abstract void stop();

    abstract void reset(bool immediately = false, bool once = false);

    void reset(size_t interval)
    {
        this.interval = interval;
        reset();
    }

    void reset(Duration duration)
    {
        this.interval = duration;
        reset();
    }

    protected void onTick()
    {
        // trace("tick thread id: ", getTid());
        if (ticked !is null)
            ticked(this);
    }
}


/**
* See_also:
*	https://www.codeproject.com/articles/146617/simple-c-timer-wrapper
*	https://msdn.microsoft.com/en-us/library/ms687003(v=vs.85)
*/
class NativeTimer : AbstractNativeTimer
{
    protected HANDLE _handle = null;

    this()
    {
        super(1000);
    }

    this(size_t interval)
    {
        super(interval);
    }

    this(Duration duration)
    {
        super(duration);
    }

    /// immediately: true to call first event immediately
    /// once: true to call timed event only once
    override void start(bool immediately = false, bool once = false)
    {
        version(HUNT_DEBUG) trace("main thread id: ", thisThreadID());
        if (_isActive)
            return;
        BOOL r = CreateTimerQueueTimer(&_handle, null, &timerProc,
                cast(PVOID) this, immediately ? 0 : cast(int) interval, once ? 0
                : cast(int) interval, WT_EXECUTEINTIMERTHREAD);
        assert(r != 0);
        _isActive = true;
    }

    override void stop()
    {
        if (_isActive)
        {
            DeleteTimerQueueTimer(null, _handle, null);
            _isActive = false;
        }
    }

    override void reset(bool immediately = false, bool once = false)
    {
        if (_isActive)
        {
            assert(ChangeTimerQueueTimer(null, _handle, immediately ? 0
                    : cast(int) interval, once ? 0 : cast(int) interval) != 0);
        }
    }

    /// https://msdn.microsoft.com/en-us/library/ms687066(v=vs.85)
    extern (Windows) static private void timerProc(PVOID param, bool timerCalled)
    {
        version(HUNT_DEBUG) trace("handler thread id: ", thisThreadID());
        AbstractNativeTimer timer = cast(AbstractNativeTimer)(param);
        assert(timer !is null);
        timer.onTick();
    }
}
