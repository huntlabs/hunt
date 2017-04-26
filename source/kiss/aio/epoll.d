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

module kiss.aio.epoll;
import kiss.aio.SelectionKey;
import std.experimental.logger;
import std.conv;
import core.stdc.errno;
import core.stdc.string;
import std.stdio;
import std.string;
import core.thread;



//version(linux):
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
	
	enum EPOLL_CTL_ADD = 1;
	enum EPOLL_CTL_DEL = 2;
	enum EPOLL_CTL_MOD = 3;
	
	
	import std.conv : octal;
	enum {
		EPOLL_CLOEXEC = octal!"2000000",
		EPOLL_NONBLOCK = octal!"4000"
	}
	
	enum EPOLL_EVENTS {
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
		EPOLLRDHUP = 0x2000,
		EPOLLONESHOT = (1 << 30),
		EPOLLET = (1 << 31)
	}
	
	int epoll_create1(int flags);
	int epoll_ctl(int epfd, int op, int fd, epoll_event* event);
	int epoll_wait(int epfd, epoll_event* events, int maxevents, int
		timeout);
	int close(int fd);
	
	import core.sys.posix.sys.time;
	import core.stdc.errno;
	import std.experimental.logger.core;
}






class Epoll {

    this()
    {
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
    bool opEvent(SelectionKey key  , int fd, int op , int type)
	{
		epoll_event ev;
		uint mask = 0;
		if(type & SelectionKey.OP_READ) 
			mask = EPOLL_EVENTS.EPOLLIN;
        else if(type & SelectionKey.OP_CONNECT) 
			mask = EPOLL_EVENTS.EPOLLOUT;
        else if(type & SelectionKey.OP_ACCEPT) 
			mask = EPOLL_EVENTS.EPOLLIN;
		else if(type & SelectionKey.OP_WRITE) 
			mask = EPOLL_EVENTS.EPOLLOUT;

		



		ev.events = mask;

        
        ev.data.ptr = cast(void *)key;
      

		if(epoll_ctl(_epollFd , op , fd , &ev) < 0)
		{
		import std.conv;
			int err = errno();
			log(LogLevel.error , to!string(op) ~ fromStringz(strerror(err)) ~ " errno:" ~ to!string(err));
			return false;
		}
		
		
		return true;
	}


    bool addEvent(SelectionKey key , int fd ,  int type) 
	{
		return opEvent(key , fd ,  EPOLL_CTL_ADD , type);
	}

	bool delEvent(SelectionKey key , int fd , int type)
	{
		return opEvent(key , fd , EPOLL_CTL_DEL , type);
	}

	bool modEvent(SelectionKey key , int fd , int type)
	{
		return opEvent(key ,fd ,  EPOLL_CTL_MOD , type);
	}



    int poll(int milltimeout)
	{
        //TODO
		// scope(exit) _wheeltimer.poll();
		int result = epoll_wait(_epollFd , _pollEvents.ptr , _pollEvents.length , milltimeout);
		if(result < 0)
		{

			int err = errno();
			if(err == EINTR)
				return -1;

			log(LogLevel.fatal , fromStringz(strerror(err)) ~ " errno:" ~ to!string(err));
			return -1;
		}
		return result;
	}

    epoll_event getEpollEvent(int index){ 
        return _pollEvents[index];
    }

private:
    int _epollFd;
    private epoll_event[256] 	_pollEvents;

}
