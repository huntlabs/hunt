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

module kiss.net.TcpClient;

import kiss.aio.AsynchronousChannelSelector;
import kiss.aio.CompletionHandle;
import kiss.aio.AsynchronousSocketChannel;
import kiss.aio.ByteBuffer;
import std.socket;
import std.stdio;

class TcpClient : ConnectCompletionHandle, WriteCompletionHandle, ReadCompletionHandle {

public:
    this(string ip, ushort port, AsynchronousChannelSelector sel, int readLen)
    {
        _ip = ip;
        _port = port;
        _client = AsynchronousSocketChannel.open(sel);
        _client.connect(ip, port, this, null);
        _client.setOnCloseHandle((){
            onClose();
        });
        _readBuffer = ByteBuffer.allocate(readLen);
    }
    void doWrite(byte[] data, void* attachment = null)
    {
        _client.write(cast(string)data, this, attachment);	
    }

    void doRead(void* attachment = null) 
    {
        _client.read(_readBuffer, this, attachment); 
    }
    
    void reConnect() 
    {
        _client.connect(_ip, _port, this, null);
    }


	void close() { _client.close(); }
    socket_t fd() { return _client.getFd(); }
    string ip() { return _client.socket().remoteAddress.toAddrString; }
    string port() { return _client.socket().remoteAddress.toPortString; }

    abstract void onConnectCompleted(void* attachment);
    abstract void onConnectFailed(void* attachment);
    abstract void onWriteCompleted(void* attachment, size_t count , ByteBuffer buffer);
	abstract void onWriteFailed(void* attachment);
    abstract void onReadCompleted(void* attachment, size_t count , ByteBuffer buffer);
	abstract void onReadFailed(void* attachment);
    abstract void onClose();

protected:
    AsynchronousSocketChannel _client;
    ByteBuffer _readBuffer;
private:
    string _ip;
    ushort _port;

}