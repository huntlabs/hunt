module kiss.event.timer.iocp;

// dfmt off
version (Windows) : 
// dfmt on


import kiss.event.core;
import kiss.event.timer.common;

import core.time;
import std.datetime;
import std.exception;
import std.experimental.logger;


/**
*/
class AbstractTimer : TimerChannelBase
{
    this(Selector loop)
    {
        super(loop);
        setFlag(WatchFlag.Read, true);
        _timer = new KissWheelTimer();
        _timer.timeout = &onTimerTimeout;
        _readBuffer = new UintObject();
    }

    bool readTimer(scope ReadCallBack read)
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


    @property KissWheelTimer timer() { return _timer; }
    // mixin OverrideErro;

    UintObject _readBuffer;

    private KissWheelTimer _timer;
}
