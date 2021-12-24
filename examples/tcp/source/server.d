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

import hunt.io.ByteBuffer;
import hunt.util.ThreadHelper;
import hunt.util.TaskPool;
import hunt.event;
import hunt.io.TcpListener;
import hunt.io.TcpStream;
import hunt.io.IoError;
import hunt.logging;
import hunt.util.Timer;

import std.socket;
import std.functional;
import std.exception;
import std.datetime;
import std.process;

import core.thread;

void main() {

    debug writefln("Main thread: %s", getTid());

    EventLoop loop = new EventLoop();
    TcpListener listener = new TcpListener(loop, AddressFamily.INET, 512);

    // dfmt off
    listener
        .error((IoError error) {
            writefln("error occurred: %d  %s", error.errorCode, error.errorMsg);
        })
        .bind(8080)
        .listen(1024)
        .accepted((TcpListener sender, TcpStream client) {
            debug writefln("new connection from: %s", client.remoteAddress.toString());
            client.received((ByteBuffer buffer) {
                ubyte[] data = cast(ubyte[]) buffer.peekRemaining();
                debug writeln("received bytes: ", data.length);
                const(ubyte)[] sentData = data; // echo test
                client.write(sentData);
                return DataHandleStatus.Done;
            }).disconnected(() {
                debug writefln("client disconnected: %s", client.remoteAddress.toString());
            }).closed(() {
                debug writefln("connection closed, local: %s, remote: %s",
                client.localAddress.toString(), client.remoteAddress.toString());
                try {
                    client.write([0x41, 0x42, 0x43]);
                    client.write([0x46, 0x47, 0x48, 0x49]);
                } catch(Exception ex) {
                    warning(ex);
                }
            }).error((IoError error) {
                writefln("error occurred: %d  %s", error.errorCode, error.errorMsg);
            });
        })
        .start();

    // dfmt on

    writeln("Listening on: ", listener.bindingAddress.toString());
    loop.run();
}
