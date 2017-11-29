module kiss.event.impl.epoll;

import kiss.event.base;
import kiss.event.watcher;
import kiss.event.impl.epoll_watcher;

import std.socket;
import std.string;

import core.time;
import core.stdc.string;
import core.sys.posix.sys.types; // for ssize_t, size_t
import core.sys.posix.netinet.tcp;
import core.sys.posix.netinet.in_;
import core.sys.posix.time : itimerspec, CLOCK_MONOTONIC;
import core.sys.posix.unistd;


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

    bool read(Watcher watcher,scope ReadCallBack read)
    {
        bool canRead = false;
        switch(watcher.type){
            case WatcherType.Timer:
                canRead = readTimer(cast(EpollTimerWatcher)watcher,read);
            break;
            case WatcherType.ACCEPT:
                canRead = readAccept(cast(PosixAcceptWatcher)watcher, read);
            break;
            case WatcherType.Event:
                canRead = readEvent(cast(EpollEventWatch)watcher,read);
            break;
            case WatcherType.TCP:
                canRead = readTcp(cast(PosixTCPWatcher)watcher,read);
            break;
            case WatcherType.UDP:
                canRead = readUdp(cast(PosixUDPWatcher)watcher,read);
            break;
            default:
            break;
        }
        return canRead;
    }

    bool write(Watcher watcher,in ubyte[] data, out size_t writed)
    {
    }

    // 关闭会自动unRegister的
    bool close(Watcher watcher);

    bool register(Watcher watcher);

    bool unRegister(Watcher watcher);

    bool weakUp();

    // while(true)
    void join(scope void delegate()nothrow weak); 

    void stop();

}
