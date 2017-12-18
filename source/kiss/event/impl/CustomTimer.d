module kiss.event.impl.CustomTimer;

import kiss.event.watcher;
import kiss.timingwheel;
import kiss.exception;
import std.datetime;

enum CustomTimerMinTimeOut = 50; // 单位 毫秒（ms）
enum CustomTimerWheelSize = 500;
enum CustomTimer_Next_TimeOut = cast(long)(CustomTimerMinTimeOut * (2.0 / 3.0));

@trusted final class CWheelTimer : WheelTimer
{
    this(TimerWatcher watcher)
    {
        _watcher = watcher;
    }

    bool setTimerOut(){
        if(_watcher && _watcher.time > 0){
            _watcher.time = _watcher.time > 20 ? _watcher.time : 20;
            auto size = _watcher.time / CustomTimerMinTimeOut;
            const auto superfluous = _watcher.time % CustomTimerMinTimeOut;
            size += superfluous > CustomTimer_Next_TimeOut ? 1 : 0;
            size = size > 0 ? size : 1;
            _wheelSize = cast(uint) size;
            _circle = _wheelSize / CustomTimerWheelSize;
            return true;
        }
        return false;
    }

    override void onTimeOut() nothrow
    {
        _now++;
        if (_now >= _circle)
        {
            _now = 0;
            rest(_wheelSize);
            if(_watcher)
                catchAndLogException(_watcher.onRead);
        }
    }

    pragma(inline, true) @property wheelSize()
    {
        return _wheelSize;
    }

private:
    uint _wheelSize;
    uint _circle;
    uint _now = 0;
    TimerWatcher _watcher;
}

struct CustomTimer
{
    void init()
    {
        if(_timeWheel is null)
            _timeWheel = new TimingWheel(CustomTimerWheelSize);
        _nextTime = (Clock.currStdTime() / 10000) + CustomTimerMinTimeOut;
    }

    int doWheel()
    {
        auto nowTime = (Clock.currStdTime() / 10000);
        while (nowTime >= _nextTime)
        {
            _timeWheel.prevWheel();
            _nextTime += CustomTimerMinTimeOut;
            nowTime = (Clock.currStdTime() / 10000);
        }
        nowTime = _nextTime - nowTime;
        return cast(int) nowTime;
    }


    TimingWheel timeWheel(){
        return _timeWheel;
    }
private:
    TimingWheel _timeWheel;
    long _nextTime;
}