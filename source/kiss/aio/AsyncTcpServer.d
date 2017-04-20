module kiss.aio.AsyncTcpServer;

import kiss.event.Event;
import kiss.event.Poll;
import kiss.aio.Acceptor;
import kiss.aio.AsyncTcpBase;
import kiss.event.GroupPoll;

import std.socket;
import std.stdio;
import core.memory;


final class AsyncTcpServer(T ): Event
{

	this(Poll poll )
	{
		_poll = poll;
		_acceptor = new Acceptor();
	}

	public void retain()
	{
		version(EPOOL_NOGC)
		{
			GC.addRoot(cast(void*)this);
			GC.setAttr(cast(void*)this, GC.BlkAttr.NO_MOVE);
		}
	}
	
	public void release()
	{
		version(EPOOL_NOGC)
		{
			GC.removeRoot(cast(void*)this);
			GC.clrAttr(cast(void*)this, GC.BlkAttr.NO_MOVE);
		}else{
			delete this;
		}
	}

	bool open(string ipaddr, ushort port ,int back_log = 1024 ,  bool breuse = true)
	{

		if(!_acceptor.open(ipaddr , port , back_log , breuse))
		{
			return false;
		}

		_poll.addEvent(this , _acceptor.fd ,  IOEventType.IO_EVENT_READ);

		return true;
	}


	void close()
	{
		_isreadclose = true;
	}

	protected bool isReadyClose()
	{
		return _isreadclose;
	}


	protected bool onWrite()
	{
		return true;
	}

	protected bool onRead()
	{
		T t = new T(_poll);
		Socket socket = _acceptor.accept();
		socket.blocking(false);
		t.setSocket(socket);

		t.retain();
	
		return t.open();
	}

	protected bool onClose()
	{
		_acceptor.close();
		return true;
	}

	protected bool	   			_isreadclose = false;
	protected Poll	   			_poll;
	protected Acceptor 			_acceptor;
}

