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
            log(LogLevel.fatal , fromStringz(strerror(errno)) ~ " errno:" ~ to!string(errno));
        }
    }
    ~this()
    {
        close(_epollFd);
    }

	bool addEvent(Event event, int fd, int type) {
		_mapEvent[fd] = event;
		return opEvent(event, fd, type, EVENT_CTL_ADD);
	}
	bool delEvent(Event event, int fd, int type) {
		_mapEvent.remove(fd);
		return opEvent(event, fd, type, EVENT_CTL_DEL);
	}
	bool modEvent(Event event, int fd, int type, int oldType) {
		return opEvent(event, fd, type, EVENT_CTL_MOD);
	}
	bool opEvent(Event event, int fd, int type,int op) {
		int mask = 0;
		if (type & EventType.READ || type & EventType.TIMER) 
			mask |= EPOLL_EVENTS.EPOLLIN;
		if (type & EventType.WRITE)
			mask |= EPOLL_EVENTS.EPOLLOUT;
		if (type & EventType.ETMODE)
			mask |= EPOLL_EVENTS.EPOLLET;

		
		epoll_event ev;
		ev.events = mask;
		ev.data.fd = fd;

		//log("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
		//log("fd ",fd);
		//log("op ",op);
		//log("type ",type);
		//log("index ",index);

		// ev.data.ptr = cast(void *)event;
		if(epoll_ctl(_epollFd , op , fd , &ev) < 0)
		{
		    import std.conv;
			log(LogLevel.error , to!string(type) ~ fromStringz(strerror(errno)) ~ " errno:" ~ to!string(errno));
			return false;
		}
		return true;
		
	}

    override int poll(int milltimeout)
	{
		int result = epoll_wait(_epollFd , _pollEvents.ptr , cast(int)_pollEvents.length , milltimeout);
		if(result < 0)
		{
			if(errno == EINTR)
				return -1;
			log(LogLevel.fatal , fromStringz(strerror(errno)) ~ " errno:" ~ to!string(errno));
			return -1;
		}


        for(int i = 0; i < result; i++)
        {


			// Event event = cast(Event)_pollEvents[i].data.ptr;
			int fd = _pollEvents[i].data.fd;
			Event* event = fd in _mapEvent;
			
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
	Event[int] _mapEvent;
	//long index = 0;
}
}