/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.cn
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
import std.stdio;

import hunt.event;
import hunt.io;
import hunt.util.timer;
import hunt.util.thread;

import std.conv;
import std.json;
import std.functional;
import std.getopt;
import std.exception;
import hunt.logging;
import std.datetime;
import std.parallelism;
import std.socket;
import std.string;

// https://www.techempower.com/benchmarks/

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

	@property Address bindingAddress()
	{
		return _address;
	}

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

/**
*/
class HttpServer : AbstractTcpServer
{
	this(string ip, ushort port, int thread = (totalCPUs - 1))
	{
		super(new InternetAddress(ip, port), thread);
	}

	this(Address address, int thread = (totalCPUs - 1))
	{
		super(address, thread);
	}

	override protected void onConnectionAccepted(TcpListener sender, TcpStream client)
	{
		client.onDataReceived((in ubyte[] data) {
			notifyDataReceived(client, data);
		}).onClosed(() { notifyClientClosed(client); }).onError((string msg) {
			writeln("Error: ", msg);
		});
	}

	protected void notifyDataReceived(TcpStream client, in ubyte[] data)
	{
		debug writefln("on thread:%s, data received: %s", getTid(), cast(string) data);
		string request = cast(string) data;
		bool keepAlive = indexOf(request, " keep-alive", CaseSensitive.no) > 0;

		ptrdiff_t index = indexOf(request, "/plaintext ", CaseSensitive.no);
		if (index > 0)
			respondPlaintext(client, keepAlive);
		else if (indexOf(request, "/json ", CaseSensitive.no) > 0)
		{
			respondJson(client, keepAlive);
		}
		else
		{
			badRequest(client);
		}

	}

	private void respondPlaintext(TcpStream client, bool keepAlive)
	{
		// string currentTime = Clock.currTime.toString();
		string currentTime = "Wed, 17 Apr 2013 12:00:00 GMT";
		// string writeData = "HTTP/1.1 200 OK\r\nContent-Length: 13\r\nConnection: Keep-Alive\r\nContent-Type: text/plain\r\nServer: Hunt/0.3\r\nDate: Wed, 17 Apr 2013 12:00:00 GMT\r\n\r\nHello, World!";
		string writeData = "HTTP/1.1 200 OK\r\nContent-Length: 13\r\nConnection: Keep-Alive\r\nContent-Type: text/plain\r\nServer: Hunt/0.3\r\nDate: " ~ currentTime ~ "\r\n\r\nHello, World!";
		client.write(cast(ubyte[]) writeData, (in ubyte[] wdata, size_t size) {
			debug writeln("sent bytes: ", size, "  content: ", cast(string) writeData);
			if (!keepAlive)
				client.close();
		});
	}

	private void respondJson(TcpStream client, bool keepAlive)
	{
		JSONValue js;
		js["message"] = "Hello, World!";
		string content = js.toString();

		string writeData = "HTTP/1.1 200 OK\r\nConnection: Keep-Alive\r\nContent-Type: application/json\r\nContent-Length: " ~ to!string(
				content.length)
			~ "\r\nServer: Hunt/0.3\r\nDate: Wed, 17 Apr 2013 12:00:00 GMT\r\n\r\n";
		writeData ~= content;
		client.write(cast(ubyte[]) writeData, (in ubyte[] wdata, size_t size) {
			debug writeln("sent bytes: ", size, "  content: ", cast(string) writeData);
			if (!keepAlive)
				client.close();
		});
	}

	private void badRequest(TcpStream client)
	{
		// string writeData = "HTTP/1.1 404 Not Found\r\nServer: Hunt/0.3\r\nConnection: close\r\n\r\n";
		string writeData = `HTTP/1.1 404 Not Found
Server: Hunt/0.3
Content-Type: text/html
Content-Length: 165
Connection: keep-alive

<html>
<head><title>404 Not Found</title></head>
<body bgcolor="white">
<center><h1>404 Not Found</h1></center>
<hr><center>Hunt/0.3</center>
</body>
</html>
`;
		client.write(cast(ubyte[]) writeData);
		client.close();
	}

	protected void notifyClientClosed(TcpStream client)
	{
		debug writefln("The connection[%s] is closed on thread %s",
				client.remoteAddress(), getTid());
	}
}

void main(string[] args)
{
	// globalLogLevel(LogLevel.warning);

	ushort port = 8080;
	GetoptResult o = getopt(args, "port|p", "Port (default 8080)", &port);
	if (o.helpWanted)
	{
		defaultGetoptPrinter("A simple http server powered by KISS!", o.options);
		return;
	}

	HttpServer httpServer = new HttpServer("0.0.0.0", port, totalCPUs);
	writefln("listening on %s", httpServer.bindingAddress.toString());
	httpServer.start();
}
