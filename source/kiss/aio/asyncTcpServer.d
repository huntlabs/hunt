module kiss.aio.AsyncTcpServer;

import kiss.event.Event;
import kiss.event.Poll;
import kiss.aio.Acceptor;
import kiss.aio.AsyncTcpBase;
import kiss.event.GroupPoll;

import std.socket;
import std.stdio;
import std.experimental.logger;

class AsyncTcpServer(T ): Event
{

	this(Group poll )
	{
		_poll = poll.accept_next();
		_groupworks = poll;
		_acceptor = new Acceptor();
	}

	bool open(string ipaddr, ushort port ,int back_log = 5 ,  bool breuse = false)
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
		T t = new T(_groupworks);
		Socket socket = _acceptor.accept();
		log(LogLevel.info , "accept new client");
		socket.blocking(false);
		t.setSocket(socket);
		return t.open();
	}

	protected bool onClose()
	{
		_acceptor.close();
		return true;
	}

	protected bool	   			_isreadclose = false;
	protected Poll	   			_poll;
	protected Group				_groupworks;
	protected Acceptor 			_acceptor;
}


unittest
{
	import kiss.event.Epoll;
	import kiss.aio.AsyncTcpBase;
	import kiss.aio.AsyncTcpClient;
	import kiss.event.GroupPoll;


	auto poll = new GroupPoll!();
	auto server = new AsyncTcpServer!AsyncTcpBase(poll);
	server.open("0.0.0.0" , 8123);
	auto client0 = new AsyncTcpClient(poll);
	client0.open("127.0.0.1" , 8123);
	poll.start();
	poll.wait();
}
