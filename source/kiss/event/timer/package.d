module kiss.event.timer;

public import kiss.event.timer.common;

version (linux)
{
    public import kiss.event.timer.epoll;
}
else version (Kqueue)
{
    public import kiss.event.timer.kqueue;
}
else version (Windows)
{
    public import kiss.event.timer.iocp;
}
