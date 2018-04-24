module kiss.event.timer;

public import kiss.event.timer.common;

import kiss.event.core;

version (linux)
{
    public import kiss.event.timer.epoll;
    // alias KissTimer = EpollTimer;
}
else version (Kqueue)
{

}
else version (Windows)
{
    public import kiss.event.timer.iocp;
    // alias KissTimer = IocpTimer;
}
