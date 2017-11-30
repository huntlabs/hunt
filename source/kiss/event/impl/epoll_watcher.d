module kiss.event.impl.epoll_watcher;

import kiss.event.base;
import kiss.event.watcher;
import kiss.event.struct_;
public import kiss.event.impl.posix_watcher;

import core.sys.posix.unistd;
import core.sys.posix.time : itimerspec, CLOCK_MONOTONIC;

final class EpollEventWatcher : Watcher 
{
    alias UlongObject = BaseTypeObject!ulong;
    this()
    {
        super(WatcherType.Event);
        setFlag(WatchFlag.Read,true);
         _readBuffer = new UlongObject();
         _eventFD = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
    }

    ~this(){
        close();
    }

    void call(){
        ulong value = 1;
        core.sys.posix.unistd.write(_eventFD,  &value, value.sizeof);
    }

    override void onRead(){
        ()@trusted{readEvent(this,(Object obj){});}();
    }

    mixin PosixOverrideErro;

    UlongObject _readBuffer;

    int _eventFD;
}

final class EpollTimerWatcher : TimerWatcher
{
    this()
    {
        super();
        setFlag(WatchFlag.Read,true);
        _readBuffer = new UintObject();
       _timerFD = timerfd_create(CLOCK_MONOTONIC, TFD_CLOEXEC | TFD_NONBLOCK);
    }

    ~this(){
        close();
    }

    mixin PosixOverrideErro;

    UintObject _readBuffer;

    int _timerFD;
}

bool readTimer(EpollTimerWatcher watch, scope ReadCallBack read)
{
    if(watch is null) return false;
    watch.clearError();
    uint value;
    core.sys.posix.unistd.read(watch._timerFD, &value, 8);
    watch._readBuffer.data = value;
    if(read)
        read(watch._readBuffer);
    return false;
}

bool readEvent(EpollEventWatcher watch, scope ReadCallBack read)
{
    if(watch is null) return false;
        watch.clearError();
    ulong value;
    core.sys.posix.unistd.read(watch._eventFD, &value, value.sizeof);
    watch._readBuffer.data = value;
    if(read)
        read(watch._readBuffer);
    return false;
}


extern (C) : @system : nothrow : enum {
    EFD_SEMAPHORE = 0x1,
    EFD_CLOEXEC = 0x80000,
    EFD_NONBLOCK = 0x800
};

enum {
    EPOLL_CLOEXEC = 0x80000,
    EPOLL_NONBLOCK = 0x800
}

enum {
    EPOLLIN = 0x001,
    EPOLLPRI = 0x002,
    EPOLLOUT = 0x004,
    EPOLLRDNORM = 0x040,
    EPOLLRDBAND = 0x080,
    EPOLLWRNORM = 0x100,
    EPOLLWRBAND = 0x200,
    EPOLLMSG = 0x400,
    EPOLLERR = 0x008,
    EPOLLHUP = 0x010,
    EPOLLRDHUP = 0x2000, // since Linux 2.6.17
    EPOLLONESHOT = 1u << 30,
    EPOLLET = 1u << 31
}

/* Valid opcodes ( "op" parameter ) to issue to epoll_ctl().  */
enum {
    EPOLL_CTL_ADD = 1, // Add a file descriptor to the interface.
    EPOLL_CTL_DEL = 2, // Remove a file descriptor from the interface.
    EPOLL_CTL_MOD = 3, // Change file descriptor epoll_event structure.
}

align(1) struct epoll_event {
    align(1) : uint events;
    epoll_data_t data;
}

union epoll_data_t {
    void * ptr;
    int fd;
    uint u32;
    ulong u64;
}

int epoll_create(int size);
int epoll_create1(int flags);
int epoll_ctl(int epfd, int op, int fd, epoll_event * event);
int epoll_wait(int epfd, epoll_event * events, int maxevents, int timeout);

int eventfd(uint initval, int flags);

//timerfd

int timerfd_create(int clockid, int flags);
int timerfd_settime(int fd, int flags, const itimerspec * new_value, itimerspec * old_value);
int timerfd_gettime(int fd, itimerspec * curr_value);

enum TFD_TIMER_ABSTIME = 1 << 0;
enum TFD_CLOEXEC = 0x80000;
enum TFD_NONBLOCK = 0x800;