module kiss.aio.AsyncTcpServer;

import kiss.event.Event;
import kiss.event.Poll;
import kiss.aio.Acceptor;
import kiss.aio.AsyncTcpBase;

import std.socket;
import std.stdio;
import std.experimental.logger;

class AsyncTcpServer(T ): Event
{

	this(Poll poll )
	{
		_poll = poll;
		_acceptor = new Acceptor();
	}

	bool open(string ipaddr, ushort port ,int back_log = 5 ,  bool breuse = true)
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
		return t.open();
	}

	protected bool onClose()
	{
		_acceptor.close();
		return true;
	}

	protected bool	   _isreadclose = false;
	protected Poll	   _poll;
	protected Acceptor _acceptor;
}


unittest
{
	import kiss.event.Epoll;
	import kiss.aio.AsyncTcpBase;
	import kiss.aio.AsyncTcpClient;


	Poll poll = new Epoll();
	auto server = new AsyncTcpServer!AsyncTcpBase(poll);
	server.open("0.0.0.0" , 8123);

	auto client1 = new AsyncTcpClient(poll);
	client1.open("127.0.0.1" , 8124);

	auto client0 = new AsyncTcpClient(poll);
	client0.open("127.0.0.1" , 8123);

	poll.run();
}
