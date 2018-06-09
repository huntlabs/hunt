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
 
module kiss.event.socket.common;

import kiss.core;
import kiss.event.EventLoop;
import kiss.event.core;
import kiss.exception;
import kiss.container.ByteBuffer;

import std.socket;
import kiss.logger;


alias ConnectionHandler = void delegate(bool isSucceeded);

// dfmt off
alias UDPReadCallBack = void delegate(in ubyte[] data, Address addr);
alias AcceptCallBack = void delegate(Selector loop, Socket socket) ;
// dfmt on

alias SocketChannelBase = AbstractSocketChannel;
// alias AcceptorBase = AbstractListener;
// alias StreamSocketBase = AbstractStream;
// alias DatagramSocketBase = AbstractDatagramSocket;

/**
*/
interface IAcceptor
{
    void onClose();
    void onRead();
}

/**
*/
interface Stream
{

}

// alias IStreamSocket = Stream;

// dfmt off
mixin template ChannelSocketOption() {
    import std.functional;
    import std.datetime;
    import core.stdc.stdint;
    import std.socket;

    version (Windows) import SOCKETOPTIONS = core.sys.windows.winsock2;

    version (Posix) import SOCKETOPTIONS = core.sys.posix.sys.socket;

    /// Get a socket option.
    /// Returns: The number of bytes written to $(D result).
    //returns the length, in bytes, of the actual result - very different from getsockopt()
    pragma(inline) final int getOption(SocketOptionLevel level, SocketOption option,
        void[] result) @trusted {

        return  this.socket.getOption(level, option, result);
    }

    /// Common case of getting integer and boolean options.
    pragma(inline) final int getOption(SocketOptionLevel level,
        SocketOption option, ref int32_t result) @trusted {
        return  this.socket.getOption(level, option, result);
    }

    /// Get the linger option.
    pragma(inline) final int getOption(SocketOptionLevel level, SocketOption option,
        ref Linger result) @trusted {
        return  this.socket.getOption(level, option, result);
    }

    /// Get a timeout (duration) option.
    pragma(inline) final void getOption(SocketOptionLevel level,
        SocketOption option, ref Duration result) @trusted {
         this.socket.getOption(level, option, result);
    }

    /// Set a socket option.
    pragma(inline) final void setOption(SocketOptionLevel level, SocketOption option,
        void[] value) @trusted {
        return  this.socket.setOption(forward!(level, option, value));
    }

    /// Common case for setting integer and boolean options.
    pragma(inline) final void setOption(SocketOptionLevel level, SocketOption option,
        int32_t value) @trusted {
        return  this.socket.setOption(forward!(level, option, value));
    }

    /// Set the linger option.
    pragma(inline) final void setOption(SocketOptionLevel level, SocketOption option,
        Linger value) @trusted {
        return  this.socket.setOption(forward!(level, option, value));
    }

    pragma(inline) final void setOption(SocketOptionLevel level, SocketOption option,
        Duration value) @trusted {
        return  this.socket.setOption(forward!(level, option, value));
    }

    final @property @trusted Address remoteAddress() {
        return _remoteAddress;
    }
    protected Address _remoteAddress;

    final @property @trusted Socket socket(){
        return this.socket;
    }

    final @property @trusted Address localAddress() {
        return _localAddress;
    }
    protected Address _localAddress;
}
// dfmt on

/**
*/
abstract class AbstractSocketChannel : AbstractChannel
{
    protected AddressFamily _family;

    this(Selector loop, WatcherType type)
    {
        super(loop, type);
    }

    protected @property void socket(Socket s)
    {
        this.handle = s.handle();
        this._family = s.addressFamily;
        // _localAddress = s.localAddress();
        version (Posix)
            s.blocking = false;
        _socket = s;
        version (KissDebugMode)
            trace("new socket fd: ", this.handle);
    }

    protected @property Socket socket()
    {
        return _socket;
    }

    mixin ChannelSocketOption;

    version (Windows)
    {

        void setRead(size_t bytes)
        {
            readLen = bytes;
        }

        protected size_t readLen;
    }

    void start();

    void onWriteDone() 
    {
        assert(false, "not implemented");
    }

protected:
    Socket _socket;
}

/**
*/
interface IDatagramSocket
{

}

/**
*/
class SocketStreamBuffer : StreamWriteBuffer
{

    this(const(ubyte)[] data, DataWrittenHandler handler = null)
    {
        _data = data;
        _site = 0;
        _sentHandler = handler;
    }

    const(ubyte)[] sendData()
    {
        return _data[_site .. $];
    }

    // add send offiset and return is empty
    bool popSize(size_t size)
    {
        _site += size;
        if (_site >= _data.length)
            return true;
        else
            return false;
    }
    // do send finish
    void doFinish()
    {
        if (_sentHandler)
        {
            _sentHandler(_data, _site);
        }
        _sentHandler = null;
        _data = null;
    }

    StreamWriteBuffer next()
    {
        return _next;
    }

    void next(StreamWriteBuffer v)
    {
        _next = v;
    }

private:
    StreamWriteBuffer _next;
    size_t _site = 0;
    const(ubyte)[] _data;
    DataWrittenHandler _sentHandler;
}

/**
*/
struct WriteBufferQueue
{
    StreamWriteBuffer front() nothrow @safe
    {
        return _first;
    }

    bool empty() nothrow @safe
    {
        return _first is null;
    }

    void clear()
    {
        StreamWriteBuffer current = _first;
        while (current !is null)
        {
            _first = current.next;
            current.next = null;
            current = _first;
        }

        _first = null;
        _last = null;
    }

    void enQueue(StreamWriteBuffer wsite)
    {
        assert(wsite);
        if (_last)
        {
            _last.next = wsite;
        }
        else
        {
            _first = wsite;
        }
        wsite.next = null;
        _last = wsite;
    }

    StreamWriteBuffer deQueue()
    {
        // assert(_first && _last);
        StreamWriteBuffer wsite = _first;
        if (_first !is null)
            _first = _first.next;

        if (_first is null)
            _last = null;

        return wsite;
    }

private:
    StreamWriteBuffer _last = null;
    StreamWriteBuffer _first = null;
}
