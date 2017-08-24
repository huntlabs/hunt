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

module kiss.TcpServer;

import kiss.aio.AsynchronousChannelThreadGroup;
import kiss.aio.AsynchronousServerSocketChannel;
import kiss.aio.CompletionHandle;
import kiss.aio.AsynchronousSocketChannel;
import kiss.aio.ByteBuffer;
import std.socket;

class TcpServer : WriteCompletionHandle, ReadCompletionHandle {

public:
    this(AsynchronousSocketChannel client, int readLen, int writeLen)
    {
        _readBuffer = ByteBuffer.allocate(readLen);
        _writeBuffer = ByteBuffer.allocate(writeLen);
        _server = client;
        _server.read(_readBuffer, this, null);
    }
    void doWrite(byte[] data)
    {
		_writeBuffer.clear();
		_writeBuffer.put(data);
        _server.write(_writeBuffer, this, null);	
    }

    socket_t getFd() { return _server.getFd(); }
	void close() { _server.close(); }

    abstract void writeCompleted(void* attachment, size_t count , ByteBuffer buffer);
	abstract void writeFailed(void* attachment);
    abstract void readCompleted(void* attachment, size_t count , ByteBuffer buffer);
	abstract void readFailed(void* attachment);
protected:
    AsynchronousSocketChannel _server;
    ByteBuffer _readBuffer;
    ByteBuffer _writeBuffer;

}