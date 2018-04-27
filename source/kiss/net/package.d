module kiss.net;

public import kiss.net.core;
public import kiss.net.TcpListener;
public import kiss.net.TcpStream;


import kiss.event;
import std.parallelism;
import std.socket;
import std.stdio;

/**
*/
abstract class AbstractTcpServer
{
	protected EventLoopGroup _group = null;
	protected bool _isStarted = false;
	protected Address _address;

	this(Address address, int thread = (totalCPUs - 1))
	{
		this._address = address;
		_group = new EventLoopGroup(cast(uint) thread);
	}

    @property Address bindingAddress() { return _address; }

	void start()
	{
		if (_isStarted)
			return;
		debug writeln("start to listen:");

		for (size_t i = 0; i < _group.length; ++i)
		{
			createServer(_group[i]);
			debug writefln("lister[%d] created", i);
		}
		debug writefln("All the servers is listening on %s.", _address.toString());
		_group.start();
		_isStarted = true;
	}

	protected void createServer(EventLoop loop)
	{
		TcpListener listener = new TcpListener(loop, _address.addressFamily);

		listener.reusePort(true);
		listener.bind(_address).listen(1024);
		listener.acceptHandler = &onConnectionAccepted;
		listener.start();
	}

	protected void onConnectionAccepted(TcpListener sender, TcpStream client);

	void stop()
	{
		if (!_isStarted)
			return;
		_isStarted = false;
		_group.stop();
	}
}