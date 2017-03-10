module kiss.aio.AsyncTcpBase;

import kiss.time.timer;

import std.string;
import std.socket;
import std.experimental.logger;
import std.conv;
import kiss.event.Event;
import kiss.event.Poll;
import core.stdc.errno;
import core.stdc.string;
import std.container:DList;
import core.stdc.time;


alias TcpWriteFinish = void delegate(Object ob);


class AsyncTcpBase:Event , Timer
{
	//public function below

	this(Poll poll)
	{
		_poll = poll;
		_readbuffer = new byte[1024];
	}

	~this()
	{
		log(LogLevel.info , "~this");
	}

	public bool doWrite(byte[] writebuf , Object ob , TcpWriteFinish finish )
	{
		if(_writebuffer.empty())
		{
			long ret = _socket.send(writebuf);
			if(ret == writebuf.length)
			{
				if(finish !is null)
				{
					finish( ob);
				}
			}
			else if(ret > 0)
			{
				QueueBuffer buffer = {writebuf , ob , cast(int)ret , finish};
				_writebuffer.insertBack(buffer);
				schedule_write();
			}
			else
			{
				if(net_error())
				{
					log(LogLevel.error , "write net error");
					close();
					return false;
				}
				//blocking rarely happened.
				log(LogLevel.warning , "blocking rarely happened");
				QueueBuffer buffer = {writebuf , ob , 0 , finish};
				_writebuffer.insertBack(buffer);
				schedule_write();
			}
			
		}
		else
		{
			QueueBuffer buffer = {writebuf , ob , 0};
			_writebuffer.insertBack(buffer);
		}	
		return true;
	}

	public void close()
	{
		_isreadclose = true;
	}

	public bool open()
	{
		_accepttime = cast(int)time(null);
		_remoteipaddr = _socket.remoteAddress.toAddrString();
		return onEstablished();
	}


	//protected function below

	protected int getFd()
	{
		return _socket.handle;
	}
	
	protected bool isReadyClose()
	{
		return _isreadclose;
	}

	protected bool onTimer(TimerFd fd , ulong ticks)
	{
		log(LogLevel.info , "timeout" ~ to!string(ticks));
		return true;
	}

	protected bool onEstablished()
	{
		log(LogLevel.info , "on Open");
		//_keepalive = _poll.addTimer(this , _keepalivetime  , WheelType.WHEEL_PERIODIC);
		_poll.addEvent(this ,_socket.handle ,  _curEventType = IOEventType.IO_EVENT_READ);
		return true;
	}

	protected bool onWrite()
	{
		while(!_writebuffer.empty())
		{
			auto data = _writebuffer.front();
			long ret = _socket.send(data.buffer[data.index .. data.buffer.length]);
			if(ret == data.buffer.length - data.index)
			{
				if(data.finish !is null)
				{
					data.finish(data.ob);
				}
				_writebuffer.removeFront();
			}
			else if(ret > 0)
			{
				data.index += ret;
				return true;
			}
			else if ( ret <= 0)
			{
				if(net_error())
				{
					log(LogLevel.error , "write net error");
					close();
					return false;
				}
				return true;
			}

		}
		schedule_cancel_write();
		return true;

	}

	protected bool onRead()
	{
		long ret = _socket.receive(_readbuffer);
		if(ret > 0)
		{
			return doRead(_readbuffer , cast(int)ret);
		}
		if(ret == 0) 
		{	
			log(LogLevel.info , "peer close socket");
			return false;
		}
		else if(ret == -1 && net_error())
		{
			log(LogLevel.error , "error");
			return false;
		}
		
		return true;	
	}

	protected @property void readBuff(byte []bt)
	{
		_readbuffer = bt;
	}


	protected bool doRead(byte[] data , int length)
	{
		_lastMsgTime = cast(int)time(null);
		log(LogLevel.info , to!string(length));
		return true;
	}


	protected bool onClose()
	{
		log(LogLevel.info , "on close");
//		if(_keepalive !is null)
//		{	
//			_poll.delTimer(_keepalive);
//			_keepalive = null;
//		}
		_poll.delEvent(this , _socket.handle , _curEventType = IOEventType.IO_EVENT_NONE);
		_socket.close();
		return true;
	}

	protected @property poll()
	{
		return _poll;
	}

	void setSocket(Socket socket)
	{
		_socket = socket;
	}

	//private member's below
	private void schedule_write()
	{
		if(_curEventType & IOEventType.IO_EVENT_WRITE)
		{
			log(LogLevel.error , "already IO_EVENT_WRITE");
		}
		
		_curEventType |= IOEventType.IO_EVENT_WRITE;
		_poll.modEvent(this , _socket.handle , _curEventType);
	}
	
	private void schedule_cancel_write()
	{
		if(! (_curEventType & IOEventType.IO_EVENT_WRITE))
		{
			log(LogLevel.error , "already no IO_EVENT_WRITE");
		}
		
		_curEventType &= ~IOEventType.IO_EVENT_WRITE;
		_poll.modEvent(this , _socket.handle , _curEventType);
	}


	private struct QueueBuffer
	{
		byte[] 			buffer;
		Object 			ob;
		int	   			index;
		TcpWriteFinish	finish;
	}


	//static function's below

	//static void setArgs(int keepalivetime = 60 * 1000)
	//{
	//	_keepalivetime = keepalivetime;
	//	log(LogLevel.info , to!string(_keepalivetime));
	//}


	static package bool net_error()
	{
		int err = errno();
		if(err == 0 || err == EAGAIN || err == EWOULDBLOCK || err == EINTR || err == EINPROGRESS)
			return false;	
		return true;
	}

	protected DList!QueueBuffer _writebuffer;
	protected byte[]	_readbuffer;
	protected bool		_isreadclose = false;
	protected Socket 	_socket;
	protected Poll 		_poll;
//	protected TimerFd 	_keepalive;
	protected IOEventType 	_curEventType = IOEventType.IO_EVENT_NONE;
	

	protected uint			_accepttime;
	protected uint			_lastMsgTime;
	protected string		_remoteipaddr;

	//protected static int _keepalivetime;
}



