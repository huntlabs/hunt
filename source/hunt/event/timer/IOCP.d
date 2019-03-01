/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2018-2019 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
module hunt.event.timer.IOCP;

// dfmt off
version (HAVE_IOCP) : 
// dfmt on

import hunt.Functions;
import hunt.io.socket.Common;
import hunt.event.timer.Common;

import core.time;
import std.datetime;
import std.exception;
import hunt.logging;


/**
*/
class AbstractTimer : TimerChannelBase
{
    this(Selector loop)
    {
        super(loop);
        setFlag(ChannelFlag.Read, true);
        _timer = new HuntWheelTimer();
        _timer.timeout = &onTimerTimeout;
        _readBuffer = new UintObject();
    }

    bool readTimer(scope SimpleActionHandler read)
    {
        this.clearError();
        this._readBuffer.data = 1;
        if (read)
            read(this._readBuffer);
        return false;
    }

    // override void start(bool immediately = false, bool once = false)
    // {
    //     this.setTimerOut();
    //     super.start(immediately, once);
    // }

    private void onTimerTimeout(Object) 
    {        
        _timer.rest(wheelSize);
        this.onRead();
    }

    override void stop()
    {
        _timer.stop();
        super.stop();
    }

    
    bool setTimerOut()
    {
        if (_interval > 0)
        {
            _interval = _interval > 20 ? _interval : 20;
            auto size = _interval / CustomTimerMinTimeOut;
            const auto superfluous = _interval % CustomTimerMinTimeOut;
            size += superfluous > CustomTimer_Next_TimeOut ? 1 : 0;
            size = size > 0 ? size : 1;
            _wheelSize = cast(uint) size;
            _circle = _wheelSize / CustomTimerWheelSize;
            return true;
        }
        return false;
    }


    @property HuntWheelTimer timer() { return _timer; }
    // mixin OverrideErro;

    UintObject _readBuffer;

    private HuntWheelTimer _timer;
}
