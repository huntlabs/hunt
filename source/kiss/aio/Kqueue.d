


module kiss.aio.Kqueue;

import kiss.aio.AbstractPoll;
import kiss.util.Common;
import kiss.aio.Event;

import std.exception;
import core.sys.posix.sys.types;
import core.stdc.stdint;
import std.experimental.logger;
import std.datetime;
import core.sys.posix.signal;


static if(IOMode == IO_MODE.kqueue){

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
    this(int eventNum = 256)
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
        for(int i = 0; i < result; i++)
        {
			Event* event = null;
			event = (cast(int)_kqueueEvents[i].ident in _mapEvents);
			if(event == null)
			{
				// log(LogLevel.warning , "fd:" ~ _kqueueEvents[i].ident ~ " maybe close by others");
				continue;
			}
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
            else if(_kqueueEvents[i].filter == EVFILT_WRITE)
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

        
        return result;
    }

    bool opEvent(Event event, int fd, int op, int type)
    {
        
        kevent_t[2] changes;
        kevent_t[2] errors;

        int r = EV_DELETE;
        int w = EV_DELETE;

        if(type & AIOEventType.OP_ACCEPTED || type & AIOEventType.OP_READED)
            r = EV_ADD;
        if(type & AIOEventType.OP_CONNECTED || type & AIOEventType.OP_WRITEED)
            w = EV_ADD;
        if (op == EVENT_CTL_ADD)
            _mapEvents[fd] = event;
		else if (op == EVENT_CTL_DEL)
			_mapEvents.remove(fd);
        
        EV_SET(&changes[0], cast(ulong)fd, cast(short)EVFILT_READ, cast(ushort)r, cast(uint)0, cast(long)0, null);    
        EV_SET(&changes[1], cast(ulong)fd, cast(short)EVFILT_WRITE, cast(ushort)w, cast(uint)0, cast(long)0, null);    

        kevent(_keventFd, changes.ptr, 2, null, 0, null);

        return true;
    }
    override void wakeUp()
    {

    }
    override bool addEvent(Event event , int fd ,  int type)
    {
        return opEvent(event, fd, EVENT_CTL_ADD, type);
    }
	override bool delEvent(Event event , int fd , int type)
    {
        return opEvent(event, fd, EVENT_CTL_DEL, type);
    }
	override bool modEvent(Event event , int fd , int type)
    {
        return opEvent(event, fd, EVENT_CTL_MOD, type);
    }
private:
    int _keventFd;
    kevent_t[] _kqueueEvents;
    Event[int] _mapEvents;
}
}