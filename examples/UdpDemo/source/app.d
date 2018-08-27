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

import hunt.io.event;
import hunt.io.net.UdpSocket : UdpSocket;

import std.socket;
import std.functional;
import std.exception;
import core.thread;
import core.time;

void main()
{
	EventLoop loop = new EventLoop();

	// UDP Server
	UdpSocket udpSocket = new UdpSocket(loop);

	udpSocket.bind("0.0.0.0", 8090).setReadData((in ubyte[] data, Address addr) {
		debug writefln("Server => client: %s, received: %s", addr, cast(string) data);
		if (data == "bye!")
		{
			udpSocket.close();
			// FIXME: Needing refactor or cleanup -@zxp at 4/25/2018, 10:17:32 AM
			// The evenloop should be stopped nicely.
			// loop.stop(); 
		}
		else
			udpSocket.sendTo(data, addr);
	}).start();

	writeln("Listening on (UDP): ", udpSocket.bindAddr.toString());

	// UDP Client
	UdpSocket udpClient = new UdpSocket(loop);

	int count = 3;
	udpClient.setReadData((in ubyte[] data, Address addr) {
		debug writefln("Client => count=%d, server: %s, received: %s", count,
			addr, cast(string) data);
		if (--count > 0)
		{
			udpClient.sendTo(data, addr);
		}
		else
		{
			udpClient.sendTo(cast(const(void)[]) "bye!", addr);
			udpClient.close();
			// loop.stop();
		}
	}).start();

	// FIXME: noticed by Administrator @ 2018-3-29 16:13:54
	// udpClient.sendTo(cast(const(void)[]) "Hello world!", parseAddress("255.255.255.255", 8090));
	udpClient.sendTo(cast(const(void)[]) "Hello world!", parseAddress("127.0.0.1", 8090));

	loop.join();
}
