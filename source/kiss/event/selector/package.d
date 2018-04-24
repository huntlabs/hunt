module kiss.event.selector;

import kiss.event.core;
import std.conv;

version (linux)
{
    public import kiss.event.selector.epoll;

    // alias KissSelector = AbstractSelector;

}
else version (Kqueue)
{
    import kiss.event.impl.kqueue;

    // alias KissSelector = KqueueLoop;

    public import kiss.event.impl.kqueue_watcher;

    // override Watcher createWatcher(WatcherType type)
    // {
    //     Watcher returnValue;
    //     switch (type) with (WatcherType)
    //     {
    //     case TCP:
    //         returnValue = new PosixTCPWatcher();
    //         break;
    //     case UDP:
    //         returnValue = new PosixUDPWatcher();
    //         break;
    //     case ACCEPT:
    //         returnValue = new PosixAcceptWatcher();
    //         break;
    //     case Event:
    //         returnValue = new KqueueEventWatcher();
    //         break;
    //     case Timer:
    //         returnValue = new KqueueTimerWatcher();
    //         break;
    //     default:
    //         break;
    //     }
    //     return returnValue;
    // }
}
else version (Windows)
{
    public import kiss.event.selector.iocp;

    // alias KissSelector = IocpSelector;

}
else
{
    static assert(false, "unsupported platform");
}
