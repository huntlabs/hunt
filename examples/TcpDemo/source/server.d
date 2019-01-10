/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2015-2019  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.net
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
import std.stdio;

import hunt.event;
import hunt.io.TcpListener;
import hunt.io.TcpStream;
import hunt.util.timer;
import hunt.concurrent.thread.Helper;

import std.socket;
import std.functional;
import std.exception;
import std.datetime;
import hunt.logging;
import std.process;

void main()
{
	debug writefln("Main thread: %s", getTid());
	// globalLogLevel(LogLevel.warning);

	// to test big block data sending
	int bufferSize = 8192 * 2 + 1;
	ubyte[] bigData = new ubyte[bufferSize];
	bigData[0] = 1;
	bigData[$ - 1] = 2;

	EventLoop loop = new EventLoop();
	// TcpListener listener = new TcpListener(loop, AddressFamily.INET6, 512);
	TcpListener listener = new TcpListener(loop, AddressFamily.INET, 512);

	listener.bind(8080).listen(1024).onConnectionAccepted((TcpListener sender, TcpStream client) {
		debug writefln("new connection from: %s", client.remoteAddress.toString());
		client.onDataReceived((in ubyte[] data) {
			debug writeln("received bytes: ", data.length);
			// debug writefln("received: %(%02X %)", data);
			// const(ubyte)[] sentData = bigData;	// big data test
			const(ubyte)[] sentData = data; // echo test
			client.write(sentData, (in ubyte[] wdata, size_t nBytes) {
				debug writefln("thread: %s, sent bytes: %d", getTid(), nBytes);

				if (sentData.length > nBytes)
					writefln("remaining bytes: ", sentData.length - nBytes);
			});

			// client.write(new SocketStreamBuffer(data, (in ubyte[] wdata, size_t size) {
			// 	debug writeln("sent: size=", size, "  content: ", cast(string) wdata);
			// }));
		}).onDisconnected(() {
			debug writefln("client disconnected: %s", client.remoteAddress.toString());
		}).onClosed(() {
			debug writefln("connection closed, local: %s, remote: %s",
			client.localAddress.toString(), client.remoteAddress.toString());
		});
	}).start();

	writeln("Listening on: ", listener.bindingAddress.toString());

	// Timer timer = new Timer(loop);
	// timer.onTick((Object sender) {
	// 	writeln("The time now is: ", Clock.currTime.toString());
	// }).start(1000);

	loop.run();
}
