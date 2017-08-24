/*
 * KISS - A refined core library for dlang
 *
 * Copyright (C) 2015-2017  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs
 *
 * Licensed under the Apache-2.0 License.
 *
 */

import kiss.aio.AsynchronousServerSocketChannel;
import kiss.aio.AsynchronousSocketChannel;
import kiss.aio.AsynchronousChannelThreadGroup;
import kiss.aio.CompletionHandle;
import kiss.aio.ByteBuffer;
import kiss.TcpAccept;
import kiss.TcpServer;
import kiss.aio.AsynchronousChannelSelector;
import kiss.util.Timer;

import std.socket;
import std.stdio;
import core.thread;
import std.parallelism;
import std.string;
import std.conv;
import std.experimental.logger.core;

class TestTcpServer : TcpServer {
public:
    this(AsynchronousSocketChannel client) {
        super(client, 200, 200);
        _needClose = false;

    }
    override void writeCompleted(void* attachment, size_t count , ByteBuffer buffer) {
        if (_needClose) {
            _server.close();
        }
    }
	override void writeFailed(void* attachment) {

    }
    override void readCompleted(void* attachment, size_t count , ByteBuffer buffer) {
        string readBufer = cast(string)(buffer.getCurBuffer());
        if (indexOf(readBufer, "HTTP/1.1") >= 0)
            _needClose = false;
        else
            _needClose = true;
        string s = "HTTP/1.1 200 OK\r\nContent-Length: 13\r\nConnection: Keep-Alive\r\nContent-Type: text/plain\r\nServer: Kiss\r\nDate: Wed, 17 Apr 2013 12:00:00 GMT\r\n\r\nHello, World!";
        doWrite(cast(byte[])s);
    }
	override void readFailed(void* attachment) {

    }
private: 
    bool _needClose;
}

class TestTcpAccept : TcpAccept {
public:
    this(string ip, ushort port, AsynchronousChannelThreadGroup group) {
        super(ip, port, group);
    }
    override void acceptCompleted(void* attachment, AsynchronousSocketChannel result) {
        TestTcpServer server = new TestTcpServer(result);
    }
    override void acceptFailed(void* attachment) {
        writeln("server accept failed ");
    }
}



void testTimer() {
    
    AsynchronousChannelSelector selector = new AsynchronousChannelSelector(10);
    Timer timer = Timer.create(selector);
    timer.start(2000, (int timerid) {
        writeln("timer callback~~~~~~");
    }, 3);
    selector.start();
    selector.wait();
}

void testServer() {
    int threadNum = totalCPUs;
    AsynchronousChannelThreadGroup group = AsynchronousChannelThreadGroup.open(5,threadNum);
    for(int i = 0; i < threadNum; i++)
    {
        TestTcpAccept server = new TestTcpAccept("0.0.0.0",20001,group);
    }
    writeln("please open http://0.0.0.0:20001/ on your browser");
    group.start();
    group.wait();
}

void main()
{
    testServer();
}