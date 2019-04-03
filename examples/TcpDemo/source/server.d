/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2018-2019 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
import std.stdio;

import hunt.collection.ByteBuffer;
import hunt.concurrency.thread.Helper;
import hunt.event;
import hunt.io.TcpListener;
import hunt.io.TcpStream;
import hunt.logging;
import hunt.util.Timer;

import std.socket;
import std.functional;
import std.exception;
import std.datetime;
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
		client.onReceived((ByteBuffer buffer) {
			ubyte[] data = cast(ubyte[])buffer.getRemaining();
			debug writeln("received bytes: ", data.length);
			// debug writefln("received: %(%02X %)", data);
			// const(ubyte)[] sentData = bigData;	// big data test
			const(ubyte)[] sentData = data; // echo test
			client.write(sentData);

			// client.write(new SocketStreamBuffer(data, (in ubyte[] wdata, size_t size) {
			// 	debug writeln("sent: size=", size, "  content: ", cast(string) wdata);
			// }));
		}).onWritten((Object obj) {
			writefln("Data write done");
		}).onDisconnected(() {
			debug writefln("client disconnected: %s", client.remoteAddress.toString());
		}).onClosed(() {
			debug writefln("connection closed, local: %s, remote: %s",
			client.localAddress.toString(), client.remoteAddress.toString());
		}).onError((string msg){
			writefln("error occurred: %s", msg);
		});
	}).start();

	writeln("Listening on: ", listener.bindingAddress.toString());

	// Timer timer = new Timer(loop);
	// timer.onTick((Object sender) {
	// 	writeln("The time now is: ", Clock.currTime.toString());
	// }).start(1000);

	loop.run();
}
