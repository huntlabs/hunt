module server;

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

import hunt.event;
import hunt.io.UdpSocket : UdpSocket;

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

	udpSocket.bind("0.0.0.0", 8080).onReceived((in ubyte[] data, Address addr) {
		debug writefln("Server => client: %s, received: %s", addr, cast(string) data);
		// if (data == "bye!")
		// {
		// 	udpSocket.close();
		// 	// FIXME: Needing refactor or cleanup -@zxp at 4/25/2018, 10:17:32 AM
		// 	// The evenloop should be stopped nicely.
		// 	// loop.stop(); 
		// }
		// else
			udpSocket.sendTo(data, addr);
	}).start();

	writeln("Listening on (UDP): ", udpSocket.bindAddr.toString());

	loop.run();
}
