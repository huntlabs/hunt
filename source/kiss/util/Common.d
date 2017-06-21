
module kiss.util.Common;


enum IO_MODE
{
    epoll,
    kqueue,
    iocp,
    select,
    poll,
    port,
    none
}

version (FreeBSD)
{
    enum IO_MODE IOMode = IO_MODE.kqueue;
    enum CustomTimer = false;
}
else version (OpenBSD)
{
    enum IO_MODE IOMode = IO_MODE.kqueue;
    enum CustomTimer = false;
}
else version (NetBSD)
{
    enum IO_MODE IOMode = IO_MODE.kqueue;
    enum CustomTimer = false;
}
else version (OSX)
{
    enum IO_MODE IOMode = IO_MODE.kqueue;
    enum CustomTimer = false;
}
else version (linux)
{
    enum IO_MODE IOMode = IO_MODE.epoll;
    enum CustomTimer = false;
}
else version (Windows)
{
    enum IO_MODE IOMode = IO_MODE.iocp;
    enum CustomTimer = true;
}
else
{
    enum IO_MODE IOMode = IO_MODE.select;
    enum CustomTimer = true;
}