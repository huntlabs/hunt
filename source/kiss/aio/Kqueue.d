


module kiss.aio.Kqueue;

import kiss.aio.AbstractPoll;
import kiss.util.Common;


static if(IOMode == IO_MODE.kqueue){

extern(C)
{
    struct kevent_t {
        uintptr_t       ident;          /* identifier for this event，比如该事件关联的文件描述符 */
        int16_t         filter;         /* filter for event，可以指定监听类型，如EVFILT_READ，EVFILT_WRITE，EVFILT_TIMER等 */
        uint16_t        flags;          /* general flags ，可以指定事件操作类型，比如EV_ADD，EV_ENABLE， EV_DELETE等 */
        uint32_t        fflags;         /* filter-specific flags */
        intptr_t        data;           /* filter-specific data */
        void            *udata;         /* opaque user data identifier，可以携带的任意数据 */
    };
}

class Kqueue : AbstractPoll{

public:
    this(int eventNum = 256)
    {
        _events.length = eventNum;
        _changes.length = eventNum;
    }

    override int poll(int milltimeout)
    {
        int result;
        return result;
    }
    override void wakeUp()
    {

    }
    override bool addEvent(Event event , int fd ,  int type)
    {
        return true;
    }
	override bool delEvent(Event event , int fd , int type)
    {
        return true;
    }
	override bool modEvent(Event event , int fd , int type)
    {
        return true;
    }
private:
    kevent_t[] _events;
    kevent_t[] _changes;
}
}