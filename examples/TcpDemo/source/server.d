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
import hunt.io.ErrorKind;
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

    EventLoop loop = new EventLoop();
    TcpListener listener = new TcpListener(loop, AddressFamily.INET, 512);

    listener.bind(8080)
    .listen(1024)
    .error((IoError error){writefln("error occurred: %d  %s",error.errorCode , error.errorMsg);})
    .accepted((TcpListener sender, TcpStream client) {
        debug writefln("new connection from: %s", client.remoteAddress.toString());
        client.received((ByteBuffer buffer) {
          ubyte[] data = cast(ubyte[])buffer.getRemaining();
          debug writeln("received bytes: ", data.length);
          const(ubyte)[] sentData = data; // echo test
          client.write(sentData);
        }).disconnected(() {
          debug writefln("client disconnected: %s", client.remoteAddress.toString());
        }).closed(() {
          debug writefln("connection closed, local: %s, remote: %s",
          client.localAddress.toString(), client.remoteAddress.toString());
        }).error((IoError error){
            writefln("error occurred: %d  %s",error.errorCode , error.errorMsg);
        });
    })
	.start();

	writeln("Listening on: ", listener.bindingAddress.toString());

	loop.run();
}

