


module kiss.aio.Kqueue;

import kiss.aio.AbstractPoll;
import kiss.util.Common;
import kiss.aio.Event;
import kiss.util.Timer;
import kiss.aio.AsynchronousChannelBase;
import kiss.aio.AsynchronousSelectionKey;


import std.exception;
import std.datetime;
import std.experimental.logger;
import core.sys.posix.sys.types;
import core.stdc.stdint;
import core.sys.posix.signal;
import core.stdc.errno;
import core.sys.posix.unistd;


static if(IOMode == IO_MODE.kqueue) {

extern(C)
{

    struct kevent_t {
        uintptr_t       ident;          /* identifier for this event */
        int16_t         filter;         /* filter for event */
        uint16_t        flags;          /* general flags */
        uint32_t        fflags;         /* filter-specific flags */
        intptr_t        data;           /* filter-specific data */
        void            *udata;         /* opaque user data identifier */
    };
    enum : short
    {
        EVFILT_READ = -1,
        EVFILT_WRITE = -2,
        EVFILT_AIO = -3, /* attached to aio requests */
        EVFILT_VNODE = -4, /* attached to vnodes */
        EVFILT_PROC = -5, /* attached to struct proc */
        EVFILT_SIGNAL = -6, /* attached to struct proc */
        EVFILT_TIMER = -7, /* timers */
        EVFILT_MACHPORT = -8, /* Mach portsets */
        EVFILT_FS = -9, /* filesystem events */
        EVFILT_USER = -10, /* User events */
        EVFILT_VM = -12, /* virtual memory events */
        EVFILT_SYSCOUNT = 11
    }
    enum
    {
        /* actions */
        EV_ADD = 0x0001, /* add event to kq (implies enable) */
        EV_DELETE = 0x0002, /* delete event from kq */
        EV_ENABLE = 0x0004, /* enable event */
        EV_DISABLE = 0x0008, /* disable event (not reported) */

        /* flags */
        EV_ONESHOT = 0x0010, /* only report one occurrence */
        EV_CLEAR = 0x0020, /* clear event state after reporting */
        EV_RECEIPT = 0x0040, /* force EV_ERROR on success, data=0 */
        EV_DISPATCH = 0x0080, /* disable event after reporting */

        EV_SYSFLAGS = 0xF000, /* reserved by system */
        EV_FLAG1 = 0x2000, /* filter-specific flag */

        /* returned values */
        EV_EOF = 0x8000, /* EOF detected */
        EV_ERROR = 0x4000, /* error, data contains errno */
    }
    extern (D) void EV_SET(kevent_t* kevp, typeof(kevent_t.tupleof) args)
    {
        *kevp = kevent_t(args);
    }

    int kqueue();
    int kevent(int kq, kevent_t* changelist, int nchanges, kevent_t *eventlist, int nevents, 
            const timespec *timeout);

}

class Kqueue : AbstractPoll{

public:
    this(int eventNum = 128)
    {
        _keventFd = kqueue();
        _kqueueEvents.length = eventNum;
        if (_keventFd < 0)
            throw new Exception("kqueue create failed !!!");
    }
    override int poll(int milltimeout)
    {

        timespec time = timespec(milltimeout / 1000, (milltimeout % 1000) * 1000000);
        int result = kevent(_keventFd, null, 0, _kqueueEvents.ptr, cast(int)_kqueueEvents.length, &time);
        

        _index ++;


        for(int i = 0; i < result; i++)
        {
            int fd = cast(int)(_kqueueEvents[i].ident);
            Event event;

            if (_kqueueEvents[i].filter == EVFILT_TIMER) {
                if ((fd in _mapTimerEvents) == null){
                    trace("error", fd);
                    continue;
                }
                event = cast(Event)(_mapTimerEvents[fd]); 
                if(!event.onRead())
				{
					if (event.onClose())
					{
						delete event;
						continue;
					}
				}
            }
            else {

                if ((fd in _mapEvents) == null){
                    trace("error", fd);
                    continue;
                }

                event = cast(Event)(_mapEvents[fd]); 
                AsynchronousSelectionKey key = cast(AsynchronousSelectionKey)_mapEvents[fd];
                
                if (_kqueueEvents[i].filter == EVFILT_READ)
                {
                    if(!event.onRead())
                    {
                        if (event.onClose())
                        {
                            delete event;
                            continue;
                        }
                    }
                }
                
                if(_kqueueEvents[i].filter == EVFILT_WRITE)
                {
                    if(!event.onWrite())
                    {
                        if (event.onClose())
                        {
                            delete event;
                            continue;
                        }
                    }
                }
                if (event.isReadyClose() )
                {	
                    if (event.onClose())
                    {
                        delete event;
                        continue;
                    }
                }
            }
        } 
        return result;
    }

    bool opEvent(Event event, int fd, int op, EventType mask)
    {   
        kevent_t change;
        int ev;

        if (op == EVENT_CTL_ADD) {
            ev = EV_ADD;
            _mapEvents[fd] = event;
        }
        else if (op == EVENT_CTL_DEL) {
            ev = EV_DELETE;
        }
        else if (op == EVENT_CTL_MOD) {
            ev = EV_DELETE;
            mask = EventType.READ | EventType.WRITE;
            _mapEvents.remove(fd);
        }

        if (mask & EventType.READ) {
            EV_SET(&change, cast(ulong)fd, cast(short)EVFILT_READ, cast(ushort)ev, cast(uint)0, cast(long)0, null);  
            if ((kevent(_keventFd, &change, 1, null, 0, null) == -1) && op != EVENT_CTL_MOD) {
                trace("kevent read error ", op);
            }
        }
        if (mask & EventType.WRITE) {
            EV_SET(&change, cast(ulong)fd, cast(short)EVFILT_WRITE, cast(ushort)ev, cast(uint)0, cast(long)0, null);  
            if ((kevent(_keventFd, &change, 1, null, 0, null) == -1) && op != EVENT_CTL_MOD) {
                trace("kevent write error ", op);
            }
        }

        return true;
    }
    override void wakeUp()
    {
        byte c = 1;
        if (1 != core.sys.posix.unistd.write(_keventFd, &c, 1) ) {
            trace(LogLevel.error, "wakeUp error", errno);
        }
    }
    override bool addEvent(Event event , int fd, int type)
    {

        kevent_t change;
        if (type & EventType.TIMER) {
            log("(cast(Timer)event)._intervalTime = ",(cast(Timer)event)._intervalTime, fd);
            _mapTimerEvents[fd] = event;
            EV_SET(&change, cast(ulong)fd, EVFILT_TIMER, EV_ADD | EV_ENABLE | EV_CLEAR, 0, (cast(Timer)event)._intervalTime, &event); //单位毫秒
            kevent(_keventFd, &change, 1, null, 0, null);
        }   
        else {
            _mapEvents[fd] = event;
            if (type & EventType.READ) {
                EV_SET(&change, cast(ulong)fd, cast(short)EVFILT_READ, cast(ushort)EV_ADD, cast(uint)0, cast(long)0, null);  
                if ((kevent(_keventFd, &change, 1, null, 0, null) == -1)) {
                    trace("kevent read error ", type);
                    return false;
                }
            }
            if (type & EventType.WRITE) {
                EV_SET(&change, cast(ulong)fd, cast(short)EVFILT_WRITE, cast(ushort)EV_ADD, cast(uint)0, cast(long)0, null);  
                if ((kevent(_keventFd, &change, 1, null, 0, null) == -1)) {
                    trace("kevent write error ", type);
                    return false;
                }
            }
        }

        return true;
    }

	override bool delEvent(Event event , int fd, int type)
    {
        kevent_t change;
        if (type & EventType.TIMER) {
            log("remove");
            _mapTimerEvents.remove(fd);
            type = EventType.READ;
            EV_SET(&change, cast(ulong)fd, EVFILT_TIMER, EV_DELETE, 0, 0, &event);
            kevent(_keventFd, &change, 1, null, 0, null);
        }   
        else {
            _mapEvents.remove(fd);
            EV_SET(&change, cast(ulong)fd, cast(short)EVFILT_READ, cast(ushort)EV_DELETE, cast(uint)0, cast(long)0, null);  
            kevent(_keventFd, &change, 1, null, 0, null);
            EV_SET(&change, cast(ulong)fd, cast(short)EVFILT_WRITE, cast(ushort)EV_DELETE, cast(uint)0, cast(long)0, null);  
            kevent(_keventFd, &change, 1, null, 0, null);
        }
        
        return true;
    }
	override bool modEvent(Event event , int fd , int type, int oldType)
    {
        kevent_t change;
        int c = oldType ^ type;
        if (c & EventType.READ) {
            
            ushort add = type & EventType.READ ? EV_ADD : EV_DELETE;
            EV_SET(&change, cast(ulong)fd, cast(short)EVFILT_READ, add, cast(uint)0, cast(long)0, null);  
            if ((kevent(_keventFd, &change, 1, null, 0, null) == -1)) {
                trace("kevent read error ", type);
                return false;
            }
        }
        if (c & EventType.WRITE) {
            ushort add = type & EventType.WRITE ? EV_ADD : EV_DELETE;
            EV_SET(&change, cast(ulong)fd, cast(short)EVFILT_WRITE, add, cast(uint)0, cast(long)0, null);  
            if ((kevent(_keventFd, &change, 1, null, 0, null) == -1)) {
                trace("kevent write error ", type);
                return false;
            }
        }
        return true;
    }

public:
    int _index = 0;
    
private:
    int _keventFd;
    kevent_t[] _kqueueEvents;
    Event[int] _mapEvents;
    Event[int] _mapTimerEvents;
}
}