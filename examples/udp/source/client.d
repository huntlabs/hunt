module client;

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

// http://www.cs.ubbcluj.ro/~dadi/compnet/labs/lab3/udp-broadcast.html
void main()
{
	EventLoop loop = new EventLoop();

	// UDP Client
	UdpSocket udpClient = new UdpSocket(loop);

	int count = 3;
	Address address = new InternetAddress(InternetAddress.ADDR_ANY, InternetAddress.PORT_ANY);
	udpClient.enableBroadcast(true)
			 .bind(address)
			//  .bind("10.1.222.120", InternetAddress.PORT_ANY)
			 .onReceived((in ubyte[] data, Address addr) {
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
			})
			.start();

	udpClient.sendTo(cast(const(void)[]) "Hello world!", parseAddress("255.255.255.255", 8080));
	// udpClient.sendTo(cast(const(void)[]) "Hello world!", parseAddress("127.0.0.1", 8090));
	// udpClient.sendTo(cast(const(void)[]) "Hello world!", parseAddress("10.1.222.120", 8080));

	loop.run();
}
