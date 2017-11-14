module kiss.event.impl.epoll;

import kiss.event.base;
import kiss.event.watcher;

mixin template EpollOverrideErro()
{
     override bool isError(){
        return _error;
    }
    override string erroString(){
        return _erroString;
    }

    bool _error = false;
    string _erroString;
}

final class EpollTCPWatcher : TcpSocketWatcher
{
    this()
    {
        super();
        setFlag(WatchFlag.Read,true);
        setFlag(WatchFlag.Write,true);
        setFlag(WatchFlag.ETMode,true);
    }
   
   mixin EpollOverrideErro;
}

final class EpollTimerWatcher : TimerWatcher
{
    this()
    {
        super();
        setFlag(WatchFlag.Read,true);
    }

    mixin EpollOverrideErro;
}

final class EpollUDPWatcher : UDPSocketWatcher
{
    this()
    {
        super();
        setFlag(WatchFlag.Read,true);
        setFlag(WatchFlag.ETMode,true);
    }

    mixin EpollOverrideErro;
}

final class EpollAcceptWatcher : AcceptorWatcher
{
    this()
    {
        super();
        setFlag(WatchFlag.Read,true);
    }

    mixin EpollOverrideErro;
}

final class  EpollEventWatch : Watcher 
{
    this()
    {
        super(WatcherType.Event);
        setFlag(WatchFlag.Read,true);
        setFlag(WatchFlag.ETMode,true);
    }

    mixin EpollOverrideErro;
}

final class EpollLoop : BaseLoop
{
    Watcher createWatcher(WatcherType type)
    {
        Watcher returnValue;
        switch (type) with(WatcherType)
        {
        case TCP:
            watcher = new EpollTCPWatcher();
            break;
        case UDP:
            watcher = new EpollUDPWatcher();
            break;
        case ACCEPT:
            watcher = new EpollAcceptWatcher();
            break;
        case Event:
            watcher = new EpollEventWatch();
        default:
            break;
        }
        return returnValue;
    }

    void read(Watcher watcher,scope ReadDataCallBack read)
    {
        
    }

    void read(Watcher watcher,scope ReadObjectCallBack read)
    {
        return _loop.read(watcher,read);
    }

    bool write(Watcher watcher,in ubyte[] data, out size_t writed)
    {}

    // 关闭会自动unRegister的
    bool close(Watcher watcher);

    bool register(Watcher watcher);

    bool unRegister(Watcher watcher);

    bool weakUp();

    // while(true)
    void join(scope void delegate()nothrow weak); 

    void stop();
}
