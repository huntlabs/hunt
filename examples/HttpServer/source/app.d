/*
 * Kiss - A refined core library for D programming language.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.cn
 *
 * Licensed under the Apache-2.0 License.
 *
 */

import std.stdio;

import kiss.event;
import kiss.net.TcpListener;
import kiss.net.TcpStream;
import kiss.util.timer;

import std.array;
import std.socket;
import std.functional;
import std.getopt;
import std.exception;
import kiss.logger;
import std.datetime;

import datefmt;

void main(string[] args)
{
	// globalLogLevel(LogLevel.warning);

	ushort port = 8090;
	GetoptResult o = getopt(args, "port|p", "Port (default 8090)", &port);
	if (o.helpWanted)
	{
		defaultGetoptPrinter("A simple http echo server!", o.options);
		return;
	}

	EventLoop loop = new EventLoop();
	TcpListener listener = new TcpListener(loop, AddressFamily.INET);

	listener.reusePort(true);
	listener.bind(port).listen(1024).onConnectionAccepted((TcpListener sender, TcpStream client) {

		client.onDataReceived((in ubyte[] data) {
			debug writeln("received: ", cast(string) data);

			//string writeData = "HTTP/1.1 200 OK\r\nContent-Length: 13\r\nConnection: Keep-Alive\r\nContent-Type: text/plain\r\nServer: Kiss\r\nDate: Wed, 17 Apr 2013 12:00:00 GMT\r\n\r\nHello, World!";
			
			string writeData = buildResponse("Hello, World!");
			client.write(cast(ubyte[]) writeData, (in ubyte[] wdata, size_t size) {
				debug writeln("sent bytes: ", size, "  content: ", cast(string) writeData);
				// client.close(); // comment out for Keep-Alive
			});
			// client.write(new SocketStreamBuffer(cast(ubyte[]) writeData,
			// (in ubyte[] wdata, size_t size) {
			// 	debug writeln("sent bytes: ", size, "  content: ", cast(string) writeData);
			// 	// client.close();
			// }));
		}).onClosed(() { debug writeln("The connection is closed!"); }).onError((string msg) {
			writeln("Error: ", msg);
		});
	}).start();

	writefln("The server is listening on %s.", listener.bindingAddress.toString());
	loop.run();
}

string buildResponse(string content)
{
	Appender!string sb;
	sb.put("HTTP/1.1 200 OK\r\n");
	sb.put("Server: Kiss/0.3\r\n");
	sb.put("Connection: Keep-Alive\r\n");
	sb.put("Content-Type: text/plain\r\n");
	sb.put("Content-Length: " ~ to!string(content.length) ~ "\r\n");
	sb.put("Date: " ~ Clock.currTime.format("%a, %d %b %Y %H:%M:%S GMT"));
	sb.put("\r\n\r\n");
	sb.put(content);
	return sb.data;
}
