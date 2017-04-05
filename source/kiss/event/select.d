module kiss.event.select;

import kiss.event.Poll;
import kiss.event.Event;
import kiss.time.timer;
import kiss.time.itimer;

import core.thread;

import std.socket;
import kiss.util.log;
import std.conv;
import std.stdio;

import kiss.util.log;
import object;


final class select : Thread , Poll
{

	class Data
	{

		this(socket_t f , Event e , IOEventType t)
		{
			fd = f;
			event = e;
			type = t;
		}

		socket_t    fd;
		Event	 	event;
		IOEventType type;
	}



	this(int timeout = 10)
	{	
		 _rset = new SocketSet();
		 _wset = new SocketSet();
		 _eset = new SocketSet();
		_wheeltimer = new WheelTimer();
		_timeout = timeout;
		_maxfd = _rset.max();
		super(&run);
	}

	~this()
	{
		_wheeltimer.destroy();
		_eset.destroy();
		_wset.destroy();
		_rset.destroy();
	}

	bool addEvent(Event event , int fd , IOEventType type)
	{
		socket_t s_fd = cast(socket_t)fd;
	
		Data data = new Data(s_fd , event , type);
		synchronized(this)
		{
			if(_mapevents.length >= _maxfd )
			{
				log_error("too much fd , len :" ~ to!string(_mapevents.length) ~ "max:" ~ to!string(_maxfd));
					return false;
			}

			assert(s_fd !in _mapevents);
			_mapevents[s_fd]  = data;
		}
		return true;
	}

	bool delEvent(Event event , int fd , IOEventType type)
	{
		socket_t s_fd = cast(socket_t)fd;
		synchronized(this)
		{
			assert(s_fd in _mapevents);
			_mapevents.remove(s_fd);
		}
		return true;
	}

	bool modEvent(Event event , int fd , IOEventType type)
	{
		socket_t s_fd = cast(socket_t)fd;
	
		synchronized(this)
		{
			assert(s_fd in _mapevents);
			_mapevents[s_fd].type = type;
		}
		return true;
	}

	bool poll(int milltimeout)
	{
		TimeVal val;
		val.seconds = milltimeout/1000 ;
		val.microseconds = milltimeout * 1000 - val.seconds * 1000 * 1000;
		_rset.reset();
		_wset.reset();
		_eset.reset();

		scope(exit) { _wheeltimer.poll();}
	
		Data[] datas;

		synchronized(this){
			if(_mapevents.length == 0)
				return true;
			datas = _mapevents.values();
		}
		foreach(v ; datas )
		{
			if(v.type & IOEventType.IO_EVENT_READ)
			{
				_rset.add(v.fd);
			}

			if( v.type & IOEventType.IO_EVENT_WRITE)
			{	
				_wset.add(v.fd);
			}

			if(v.type & IOEventType.IO_EVENT_ERROR)
			{
				_eset.add(v.fd);
			}
		}

		int ret = Socket.select(_rset ,_wset , _eset  , &val);
	
		if(ret <= 0)
		{
			return true;
		}
		else
		{
			foreach(v ; datas)
			{
				
				//close
				if(v.event.isReadyClose())
				{
					if(v.event.onClose())
						delete v.event;
					continue;																																									
				}
			
				//error
				if(_eset.isSet(v.fd))
				{

					if(v.type & (~IOEventType.IO_EVENT_ERROR)) 
					{
						log_error("io_event_error");
					}

					if(!v.event.onClose())
						delete v.event;	
					continue;
				}

				//read
				else if(_rset.isSet(v.fd))
				{

					if(v.type & (~IOEventType.IO_EVENT_READ)) 
					{
						log_error("io_event_read");
					}

					if(!v.event.onRead())
					{
						if(v.event.onClose())
							delete v.event;	
						continue;
					}
				}
				//write
				else if( _wset.isSet(v.fd))
				{
					if(v.type & (~IOEventType.IO_EVENT_WRITE))
					{
						log_error("io_event_write");
					}

					if(!v.event.onWrite())
					{
						if(v.event.onClose())
							delete v.event;
						continue;
					}
				}
			
			}

		}

		return true;

	}


	void run()
	{
		while(_flag)
			poll(_timeout);
	}


	TimerFd addTimer(Timer timer , ulong interval , WheelType type)
	{
		stNodeLink st = new stNodeLink(timer , interval ,type);
		_wheeltimer.add(st);
		return st;
	}
	
	void delTimer(TimerFd fd)
	{
		_wheeltimer.del(cast(stNodeLink)fd);
	}
	
	// thread 
	void start()
	{
		if(_flag)
		{
			log_error("already started");
			return ;
		}
		_flag = true;
		
		super.start();
	}
	void stop()
	{
		_flag = false;
	}
	void wait()
	{
		super.join();
	}


	SocketSet 							_rset;
	SocketSet 							_wset;
	SocketSet 							_eset;
	bool								_flag;
	int									_maxfd;
	private	int							_timeout;
	private Data[socket_t]				_mapevents;
	private WheelTimer					_wheeltimer;

}

