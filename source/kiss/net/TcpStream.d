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

module kiss.net.TcpStream;

import kiss.event;
import kiss.net.core;

import std.format;
import std.socket;
import std.exception;
import kiss.logger;
import std.socket;
import core.thread;
import core.time;

import kiss.container.ByteBuffer;
import kiss.core;

/**
*/
class TcpStream : AbstractStream
{
    SimpleEventHandler closeHandler;

    // for client side
    this(Selector loop, AddressFamily family = AddressFamily.INET, int bufferSize = 4096 * 2)
    {
        super(loop, family, bufferSize);
        this.socket = new Socket(family, SocketType.STREAM, ProtocolType.TCP);

        // _localAddress = socket.localAddress();// TODO:

        _isClientSide = false;
        _isConnected = false;
    }

    // for server side
    this(Selector loop, Socket socket, size_t bufferSize = 4096 * 2)
    {
        super(loop, socket.addressFamily, bufferSize);
        this.socket = socket;
        _remoteAddress = socket.remoteAddress();
        _localAddress = socket.localAddress();

        _isClientSide = false;
        _isConnected = true;
    }

    void connect(string ip, ushort port)
    {
        connect(parseAddress(ip, port));
    }

    void connect(Address addr)
    {
        if (_isConnected)
            return;

        try
        {
            Address binded = createAddress(this.socket, 0);
            this.socket.bind(binded);
            this.doConnect(addr);
            start();
            _isConnected = true;
            _remoteAddress = addr;
            _localAddress = binded;
        }
        catch (Exception ex)
        {
            error(ex.message);
        }

        if (_connectionHandler !is null)
            _connectionHandler(_isConnected);
    }

    void reconnect(Address addr)
    {
        if (_isConnected)
            this.close();
        _isConnected = false;
        AddressFamily family = AddressFamily.INET;
        if (this.socket !is null)
            family = this.socket.addressFamily;

        this.socket = new Socket(family, SocketType.STREAM, ProtocolType.TCP);
        connect(addr);
    }

    TcpStream onConnected(ConnectionHandler cback)
    {
        _connectionHandler = cback;
        return this;
    }

    TcpStream onDataReceived(DataReceivedHandler handler)
    {
        dataReceivedHandler = handler;
        return this;
    }

    // TcpStream onDataWritten(DataWrittenHandler handler)
    // {
    //     sentHandler = handler;
    //     return this;
    // }

    TcpStream onClosed(SimpleEventHandler handler)
    {
        closeHandler = handler;
        return this;
    }

    TcpStream onDisconnected(SimpleEventHandler handler)
    {
        disconnectionHandler = handler;
        return this;
    }

    TcpStream onError(ErrorEventHandler handler)
    {
        errorHandler = handler;
        return this;
    }

    bool isConnected() nothrow
    {
        return _isConnected;
    }

    override void start()
    {
        if (_isRegistered)
            return;
        _inLoop.register(this);
        _isRegistered = true;
        version (Windows)
            this.beginRead();
    }

    void write(StreamWriteBuffer buffer)
    {
        assert(buffer !is null);

        if (!_isConnected)
        {
            warning("The connection has been closed!");
            return;
        }

        _writeQueue.enQueue(buffer);

        version (Windows)
            tryWrite();
        else
        {
            onWrite();
        }
    }

    /// safe for big data sending
    void write(in ubyte[] data, DataWrittenHandler handler = null)
    {
        if (data.length == 0)
            return;

        write(new SocketStreamBuffer(data, handler));
    }

protected:
    bool _isClientSide;
    ConnectionHandler _connectionHandler;

    override void onRead()
    {
        version (KissDebugMode)
            trace("start to read");

        version (Posix)
        {
            while (_isRegistered && !tryRead())
            {
                version (KissDebugMode)
                {
                    trace("continue reading...");
                }
            }
        }
        else
        {
            doRead();
        }

        if (this.isError)
        {
            string msg = format("Socket error on read: fd=%d, message: %s",
                    this.handle, this.erroString);
            errorf(msg);
            errorOccurred(msg);
        }
    }

    override void onClose()
    {
        version (KissDebugMode)
        {
            if (!_writeQueue.empty)
            {
                warning("Some data has not been sent yet.");
            }
        }

        _writeQueue.clear();
        super.onClose();
        _isConnected = false;
        this.socket.shutdown(SocketShutdown.BOTH);
        version (Posix)
            this.socket.close();

        if (closeHandler)
            closeHandler();
    }

    override void onWrite()
    {
        if (!_isConnected)
        {
            _isConnected = true;
            _remoteAddress = socket.remoteAddress();

            if (_connectionHandler)
                _connectionHandler(true);
            return;
        }

        // bool canWrite = true;
        version (KissDebugMode)
            trace("start to write");

        while (_isRegistered && !isWriteCancelling && !_writeQueue.empty)
        {
            version (KissDebugMode)
                trace("writting...");

            StreamWriteBuffer writeBuffer = _writeQueue.front();
            const(ubyte[]) data = writeBuffer.sendData();
            if (data.length == 0)
            {
                _writeQueue.deQueue().doFinish();
                continue;
            }

            this.clearError();
            size_t nBytes = tryWrite(data);
            if (nBytes > 0 && writeBuffer.popSize(nBytes))
            {
                version (KissDebugMode)
                    trace("finishing data writing...nBytes", nBytes);
                _writeQueue.deQueue().doFinish();
            }

            if (this.isError)
            {
                string msg = format("Socket error on write: fd=%d, message=%s",
                        this.handle, this.erroString);
                errorOccurred(msg);
                errorf(msg);
                break;
            }
        }
    }
}
