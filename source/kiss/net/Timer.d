module kiss.net.Timer;

import kiss.net.struct_;
import kiss.event;

import std.experimental.logger;

final class Timer : ReadTransport
{

    this(EventLoop loop){
        _watcher = cast(TimerWatcher)loop.createWatcher(WatcherType.Timer);
        _watcher.watcher = this;
        _loop = loop;
    }

    Timer setTimerHandle(CloseCallBack cback){
        _timeBack = cback;
        return this;
    }

    bool start(uint mses)
    {
        _watcher.time = mses;
        return _loop.register(_watcher);
    }

    void stop(){
        onClose(_watcher);
    }

    bool active(){
        return _watcher.active;
    }

    override bool watched(){
        return _watcher.active;
    }

    
    override void close(){
        onClose(_watcher);
    }

protected:

    override bool watch() {
        return _loop.register(_watcher);
    }

    override void onRead(Watcher watcher) nothrow{
        catchAndLogException((){
            bool canRead =  true;
            while(canRead && watcher.active){
                canRead = _loop.read(watcher,(Object obj) nothrow {
                    BaseTypeObject!uint tm = cast(BaseTypeObject!uint)obj;
                    if(tm is null) return;
                    while(tm.data > 0){
                        _timeBack();
                        tm.data -- ;
                    }
                });
                if(watcher.isError){
                    canRead = false;
                    watcher.close();
                    error("the Timer Read is error: ", watcher.erroString); 
                }
            }
        }());
    }

    override void onClose(Watcher watcher) nothrow{
        catchAndLogException((){
            _watcher.close();
        }());
    }

    EventLoop eventLoop(){return _loop;}

private:
    CloseCallBack _timeBack;
    TimerWatcher _watcher;
    EventLoop _loop;
}