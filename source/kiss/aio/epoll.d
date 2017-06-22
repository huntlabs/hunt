/*
 * KISS - A refined core library for dlang
 *
 * Copyright (C) 2015-2017  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module kiss.aio.Epoll;

import kiss.aio.Event;
import kiss.aio.AbstractPoll;
import kiss.util.Common;

import std.experimental.logger;
import std.conv;
import core.stdc.errno;
import core.stdc.string;
import std.stdio;
import std.string;
import core.thread;
import core.sys.posix.unistd;





static if (IOMode == IO_MODE.epoll) {


extern(C){
	alias int c_int;
	alias uint uint32_t;
	alias ulong uint64_t;
	
	union epoll_data {
		void	*ptr;
		int	  fd;
		uint32_t u32;
		uint64_t u64;
	}
	
	align(1) struct epoll_event {
	align(1):uint32_t   events;	/* Epoll events */
			epoll_data data;	  /* User data variable */
	}
	

	
	import std.conv : octal;
	import core.sys.posix.time;
	enum {
		EPOLL_CLOEXEC = octal!"2000000",
		EPOLL_NONBLOCK = octal!"4000"
	}
	
	enum EPOLL_EVENTS {
		EPOLLIN = 0x001,
		EPOLLPRI = 0x002,
		EPOLLOUT = 0x004,
		EPOLLRDNORM = 0x040,
		EPOLLRDBAND = 0x080,EPOLLWRNORM = 0x100,
		EPOLLWRBAND = 0x200,
		EPOLLMSG = 0x400,
		EPOLLERR = 0x008,
		EPOLLHUP = 0x010,
		EPOLLRDHUP = 0x2000,
		EPOLLONESHOT = (1 << 30),
		EPOLLET = (1 << 31)
	}
	
	int epoll_create1(int flags);
	int epoll_ctl(int epfd, int op, int fd, epoll_event* event);
	int epoll_wait(int epfd, epoll_event* events, int maxevents, int
		timeout);
	int close(int fd);
	
	int timerfd_create(int clockid, int flags);
	int timerfd_settime(int fd, int flags, const itimerspec * new_value, itimerspec * old_value);
	int timerfd_gettime(int fd, itimerspec * curr_value);

	enum TFD_TIMER_ABSTIME = 1 << 0;
	enum TFD_CLOEXEC = 0x80000;
	enum TFD_NONBLOCK = 0x800;

	import core.sys.posix.sys.time;
	import core.stdc.errno;
	import std.experimental.logger.core;
}

class Epoll : AbstractPoll{

    this(int eventNum = 256)
    {
		_pollEvents.length = eventNum;
        _epollFd = epoll_create1(0);
        if (_epollFd < 0)
        {
            int err = errno();
            log(LogLevel.fatal , fromStringz(strerror(err)) ~ " errno:" ~ to!string(err));
        }
    }
    ~this()
    {
        close(_epollFd);
    }
    bool opEvent(Event event  , int fd, int op , int type)
	{
		epoll_event ev;
		uint mask = 0;


		if(type & AIOEventType.OP_ACCEPTED) 
			mask |= EPOLL_EVENTS.EPOLLIN;
		if(type & AIOEventType.OP_READED)	
			mask |= EPOLL_EVENTS.EPOLLET | EPOLL_EVENTS.EPOLLIN;
		if(type & AIOEventType.OP_WRITEED || type & AIOEventType.OP_CONNECTED)	
			mask |= EPOLL_EVENTS.EPOLLET | EPOLL_EVENTS.EPOLLOUT;
		if(type & AIOEventType.OP_ERROR)
			mask = EPOLL_EVENTS.EPOLLERR; 
		
		
		if (op == EVENT_CTL_ADD)
			_mapEvents[fd]  = event;
		else if (op == EVENT_CTL_DEL)
			_mapEvents.remove(fd);
		ev.events = mask;
		
        ev.data.ptr = cast(void *)event;
		ev.data.fd = fd;
	

		if(epoll_ctl(_epollFd , op , fd , &ev) < 0)
		{
		    import std.conv;
			int err = errno();
			log(LogLevel.error , to!string(op) ~ fromStringz(strerror(err)) ~ " errno:" ~ to!string(err));
			return false;
		}
		
		
		return true;
	}


    override bool addEvent(Event event , int fd ,  int type) 
	{
		return opEvent(event , fd ,  EVENT_CTL_ADD , type);
	}

	override bool delEvent(Event event , int fd , int type)
	{
		return opEvent(event , fd , EVENT_CTL_DEL , type);
	}

	override bool modEvent(Event event , int fd , int type)
	{
		return opEvent(event ,fd ,  EVENT_CTL_MOD , type);
	}




    override int poll(int milltimeout)
	{
		int result = epoll_wait(_epollFd , _pollEvents.ptr , cast(int)_pollEvents.length , milltimeout);
		if(result < 0)
		{
			int err = errno();
			if(err == EINTR)
				return -1;
			log(LogLevel.fatal , fromStringz(strerror(err)) ~ " errno:" ~ to!string(err));
			return -1;
		}

        for(int i = 0; i < result; i++)
        {

			int fd = _pollEvents[i].data.fd;
			Event* event = null;
			event = (fd in _mapEvents);
			if(event == null)
			{
				log(LogLevel.warning , "fd:" ~ to!string(fd) ~ " maybe close by others");
				continue;
			}
			
			

			bool needDel = false;
			uint mask = _pollEvents[i].events;


			if(mask &( EPOLL_EVENTS.EPOLLERR | EPOLL_EVENTS.EPOLLHUP))
			{
				if (event.onClose())
				{
					delete event;
					continue;
				}
			}

			if(mask & EPOLL_EVENTS.EPOLLIN)
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

			if(mask & EPOLL_EVENTS.EPOLLOUT)
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
			
			if(event.isReadyClose() )
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

	override void wakeUp()
	{
		ulong ul = 1;
		core.sys.posix.unistd.write(_epollFd,  & ul, ul.sizeof);
	}


private:
    int _epollFd;
    epoll_event[] _pollEvents;
	Event[int] _mapEvents;
}
}