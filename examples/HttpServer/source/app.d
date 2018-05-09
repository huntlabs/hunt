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

import std.socket;
import std.functional;
import std.getopt;
import std.exception;
import std.experimental.logger;
import std.datetime;

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
			string writeData = "HTTP/1.1 200 OK\r\nContent-Length: 13\r\nConnection: Keep-Alive\r\nContent-Type: text/plain\r\nServer: Kiss\r\nDate: Wed, 17 Apr 2013 12:00:00 GMT\r\n\r\nHello, World!";
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
