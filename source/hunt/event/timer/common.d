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
 
module hunt.event.timer.common;

import hunt.common;
import hunt.event.core;

import hunt.logging;
import std.datetime;
import std.exception;

import hunt.util.timer;

enum CustomTimerMinTimeOut = 50; // in ms
enum CustomTimerWheelSize = 500;
enum CustomTimer_Next_TimeOut = cast(long)(CustomTimerMinTimeOut * (2.0 / 3.0));

alias UintObject = BaseTypeObject!uint;

/**
    Timing Wheel manger Class
*/
final class TimingWheel
{
    /**
        constructor
        Params:
            wheelSize =  the Wheel's element router.
    */
    this(uint wheelSize)
    {
        if (wheelSize == 0)
            wheelSize = 2;
        _list = new NullWheelTimer[wheelSize];
        for (int i = 0; i < wheelSize; ++i)
        {
            _list[i] = new NullWheelTimer();
        }
    }

    /**
        add a Timer into the Wheel
        Params:
            tm  = the timer.
    */
    pragma(inline) void addNewTimer(WheelTimer tm, size_t wheel = 0)
    {
        size_t index;
        if (wheel > 0)
            index = nextWheel(wheel);
        else
            index = getPrev();

        NullWheelTimer timer = _list[index];
        tm._next = timer._next;
        tm._prev = timer;
        if (timer._next)
            timer._next._prev = tm;
        timer._next = tm;
        tm._manger = this;
    }

    /**
        The Wheel  go forward
        Params:
            size  = forward's element size;
        Notes:
            all forward's element will timeout.
    */
    void prevWheel(uint size = 1)
    {
        if (size == 0)
            return;
        foreach (i; 0 .. size)
        {
            NullWheelTimer timer = doNext();
            timer.onTimeOut();
        }
    }

protected:
    /// get next wheel times 's Wheel
    pragma(inline) size_t nextWheel(size_t wheel)
    {
        auto next = wheel % _list.length;
        return (_now + next) % _list.length;
    }

    /// get the index whitch is farthest with current index.
    size_t getPrev() const
    {
        if (_now == 0)
            return (_list.length - 1);
        else
            return (_now - 1);
    }
    /// go forward a element,and return the element.
    pragma(inline) NullWheelTimer doNext()
    {
        ++_now;
        if (_now == _list.length)
            _now = 0;
        return _list[_now];
    }
    /// rest a timer.
    pragma(inline) void rest(WheelTimer tm, size_t next)
    {
        remove(tm);
        addNewTimer(tm, next);
    }
    /// remove the timer.
    pragma(inline) void remove(WheelTimer tm)
    {
        tm._prev._next = tm._next;
        if (tm._next)
            tm._next._prev = tm._prev;
        tm._manger = null;
        tm._next = null;
        tm._prev = null;
    }

private:
    NullWheelTimer[] _list;
    size_t _now;
}

/**
    The timer parent's class.
*/
abstract class WheelTimer
{
    ~this()
    {
        stop();
    }
    /**
        the function will be called when the timer timeout.
    */
    void onTimeOut();

    /// rest the timer.
    pragma(inline) final void rest(size_t next = 0)
    {
        if (_manger)
        {
            _manger.rest(this, next);
        }
    }

    /// stop the time, it will remove from Wheel.
    pragma(inline) final void stop()
    {
        if (_manger)
        {
            _manger.remove(this);
        }
    }

    /// the time is active.
    pragma(inline, true) final bool isActive() const
    {
        return _manger !is null;
    }

    /// get the timer only run once.
    pragma(inline, true) final @property oneShop()
    {
        return _oneShop;
    }
    /// set the timer only run once.
    pragma(inline) final @property oneShop(bool one)
    {
        _oneShop = one;
    }

private:
    WheelTimer _next = null;
    WheelTimer _prev = null;
    TimingWheel _manger = null;
    bool _oneShop = false;
}

/// the Header Timer in the wheel.
class NullWheelTimer : WheelTimer
{
    override void onTimeOut()
    {
        WheelTimer tm = _next;

        while (tm)
        {
            // WheelTimer timer = tm._next;
            if (tm.oneShop())
            {
                tm.stop();
            }
            tm.onTimeOut();
            tm = tm._next;
        }
    }
}

unittest
{
    import std.datetime;
    import std.stdio;
    import std.conv;
    import core.thread;
    import std.exception;

    @trusted class TestWheelTimer : WheelTimer
    {
        this()
        {
            time = Clock.currTime();
        }

        override void onTimeOut() nothrow
        {
            collectException(writeln("\nname is ", name, " \tcutterTime is : ",
                    Clock.currTime().toSimpleString(), "\t new time is : ", time.toSimpleString()));
        }

        string name;
    private:
        SysTime time;
    }

    writeln("start");
    TimingWheel wheel = new TimingWheel(5);
    TestWheelTimer[] timers = new TestWheelTimer[5];
    foreach (tm; 0 .. 5)
    {
        timers[tm] = new TestWheelTimer();
    }

    int i = 0;
    foreach (timer; timers)
    {
        timer.name = to!string(i);
        wheel.addNewTimer(timer);
        writeln("i  = ", i);
        ++i;

    }
    writeln("prevWheel(5) the _now  = ", wheel._now);
    wheel.prevWheel(5);
    Thread.sleep(2.seconds);
    timers[4].stop();
    writeln("prevWheel(5) the _now  = ", wheel._now);
    wheel.prevWheel(5);
    Thread.sleep(2.seconds);
    writeln("prevWheel(3) the _now  = ", wheel._now);
    wheel.prevWheel(3);
    assert(wheel._now == 3);
    timers[2].rest();
    timers[4].rest();
    writeln("rest prevWheel(2) the _now  = ", wheel._now);
    wheel.prevWheel(2);
    assert(wheel._now == 0);

    foreach (u; 0 .. 20)
    {
        Thread.sleep(2.seconds);
        writeln("prevWheel() the _now  = ", wheel._now);
        wheel.prevWheel();
    }

}

/**
*/
struct CustomTimer
{
    void init()
    {
        if (_timeWheel is null)
            _timeWheel = new TimingWheel(CustomTimerWheelSize);
        _nextTime = (Clock.currStdTime() / 10000) + CustomTimerMinTimeOut;
    }

    int doWheel()
    {
        auto nowTime = (Clock.currStdTime() / 10000);
        // tracef("nowTime - _nextTime = %d", nowTime - _nextTime);
        while (nowTime >= _nextTime)
        {
            _timeWheel.prevWheel();
            _nextTime += CustomTimerMinTimeOut;
            nowTime = (Clock.currStdTime() / 10000);
        }
        nowTime = _nextTime - nowTime;
        return cast(int) nowTime;
    }

    TimingWheel timeWheel()
    {
        return _timeWheel;
    }

private:
    TimingWheel _timeWheel;
    long _nextTime;
}

/**
*/
abstract class TimerChannelBase : AbstractChannel, ITimer
{

    protected bool _isActive = false;
    protected size_t _interval = 1000;

    /// Timer tick handler
    TickedEventHandler ticked;

    this(Selector loop)
    {
        super(loop, WatcherType.Timer);
        _timeOut = 50;
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

    @property size_t wheelSize()
    {
        return _wheelSize;
    }

    @property size_t time()
    {
        return _interval;
    }

    void start(bool immediately = false, bool once = false)
    {
        _inLoop.register(this);
        _isRegistered = true;
        _isActive = true;
    }

    void stop()
    {
        if (_isActive)
        {
            _isActive = false;
            onClose();
        }
    }

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

    void reset(bool immediately = false, bool once = false)
    {
        if (_isActive)
        {
            stop();
            start();
        }
    }

    override void close()
    {
        onClose();
    }

    protected void onTick()
    {
        // trace("tick thread id: ", getTid());
        if (ticked !is null)
            ticked(this);
    }

protected:
    uint _wheelSize;
    uint _circle;
    size_t _timeOut;
}

alias TimeoutHandler = void delegate(Object sender);

/**
*/
class KissWheelTimer : WheelTimer
{
    this()
    {
        // time = Clock.currTime();
    }

    // override void onTimeOut() nothrow
    // {
    //     collectException(trace("\nname is ", name, " \tcutterTime is : ",
    //             Clock.currTime().toSimpleString(), "\t new time is : ", time.toSimpleString()));
    // }

    override void onTimeOut()
    {
        _now++;
        if (_now >= _circle)
        {
            _now = 0;
            // rest(_wheelSize);
            // if(_watcher)
            //     catchAndLogException(_watcher.onRead);

            if (timeout !is null)
            {
                timeout(this);
            }
        }
    }

    TimeoutHandler timeout;

private:
    // SysTime time;
    // uint _wheelSize;
    uint _circle;
    uint _now = 0;
}
