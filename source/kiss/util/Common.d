
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

enum EVENT_CTL_ADD = 1;
enum EVENT_CTL_DEL = 2;
enum EVENT_CTL_MOD = 3;


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

static assert(IOMode == IO_MODE.iocp);

static if (IOMode == IO_MODE.epoll) 
{
    version (X86) {
        enum SO_REUSEPORT = 15;
    }
    else version (X86_64) {
        enum SO_REUSEPORT = 15;
    }
    else version (MIPS32) {
        enum SO_REUSEPORT = 0x0200;
    }
    else version (MIPS64) {
        enum SO_REUSEPORT = 0x0200;
    }
    else version (PPC) {
        enum SO_REUSEPORT = 15;
    }
    else version (PPC64) {
        enum SO_REUSEPORT = 15;
    }
    else version (ARM) {
        enum SO_REUSEPORT = 15;
    }
}
else static if (IOMode == IO_MODE.kqueue) 
{
    enum SO_REUSEPORT = 0x0200;
}
