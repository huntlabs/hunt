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

module kiss.net.TcpServer;

import kiss.aio.AsynchronousChannelThreadGroup;
import kiss.aio.AsynchronousServerSocketChannel;
import kiss.aio.CompletionHandle;
import kiss.aio.AsynchronousSocketChannel;
import kiss.aio.ByteBuffer;
import std.socket;

class TcpServer : WriteCompletionHandle, ReadCompletionHandle {

public:
    this(AsynchronousSocketChannel client, int readLen)
    {
        _readBuffer = ByteBuffer.allocate(readLen);
        _server = client;
        _server.read(_readBuffer, this, null);
        _server.setOnCloseHandle((){
            onClose();
        });
    }
    void doWrite(byte[] data)
    {
        _server.write(cast(string)data, this, null);	
    }
    

    socket_t fd() { return _server.getFd(); }
	void close() { _server.close(); }
    string ip() { return _server.socket().remoteAddress.toAddrString; }
    string port() { return _server.socket().remoteAddress.toPortString; }

    abstract void onWriteCompleted(void* attachment, size_t count , ByteBuffer buffer);
	abstract void onWriteFailed(void* attachment);
    abstract void onReadCompleted(void* attachment, size_t count , ByteBuffer buffer);
	abstract void onReadFailed(void* attachment);
    abstract void onClose();
protected:
    AsynchronousSocketChannel _server;
    ByteBuffer _readBuffer;

}