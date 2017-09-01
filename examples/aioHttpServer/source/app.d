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
import kiss.net.TcpAcceptor;
import kiss.net.TcpServer;
import kiss.net.TcpClient;
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
        super(client, 200);
        _needClose = false;

    }
    override void onWriteCompleted(void* attachment, size_t count , ByteBuffer buffer) {
        if (_needClose) {
            _server.close();
        }
    }
	override void onWriteFailed(void* attachment) {

    }
    override void onReadCompleted(void* attachment, size_t count , ByteBuffer buffer) {
        string readBufer = cast(string)(buffer.getCurBuffer());

        if (indexOf(readBufer, "HTTP/1.1") >= 0)
            _needClose = false;
        else
            _needClose = true;

        string s = "HTTP/1.1 200 OK\r\nContent-Length: 13\r\nConnection: Keep-Alive\r\nContent-Type: text/plain\r\nServer: Kiss\r\nDate: Wed, 17 Apr 2013 12:00:00 GMT\r\n\r\nHello, World!";
        doWrite(cast(byte[])s);
        _readBuffer.clear();
    }
	override void onReadFailed(void* attachment) {

    }
    override void onClose() {

    }
private: 
    bool _needClose;
}

class TestTcpAcceptor : TcpAcceptor {
public:
    this(string ip, ushort port, AsynchronousChannelSelector sel) {
        super(ip, port, sel);
    }
    override void onAcceptCompleted(void* attachment, AsynchronousSocketChannel result) {
        TestTcpServer server = new TestTcpServer(result);
    }
    override void onAcceptFailed(void* attachment) {
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
        TestTcpAcceptor server = new TestTcpAcceptor("0.0.0.0",20001,group.getWorkSelector());
    }
    writeln("please open http://0.0.0.0:20001/ on your browser");
    group.start();
    group.wait();
}


class TestClient : TcpClient {
    this(string ip, ushort port, AsynchronousChannelSelector sel, int readLen) {
        super(ip, port, sel, readLen);
    }
    override void onConnectCompleted(void* attachment) {
        log("onConnectCompleted");
        doRead();
    }
    override void onConnectFailed(void* attachment) {
        log("onConnectFailed");
    }
    override void onWriteCompleted(void* attachment, size_t count , ByteBuffer buffer) {
        log("onWriteCompleted");
    }
	override void onWriteFailed(void* attachment) {
        log("onWriteFailed");
    }
    override void onReadCompleted(void* attachment, size_t count , ByteBuffer buffer) {
        log("onReadCompleted");
    }
	override void onReadFailed(void* attachment) {
        log("onReadFailed");   
    }
    override void onClose() {

    }
}


void testClient() {
    AsynchronousChannelSelector selector = new AsynchronousChannelSelector(10);
    TestClient client = new TestClient("0.0.0.0", 20001, selector, 200);
    selector.start();
    selector.wait();
}

void main()
{
    testServer();

}