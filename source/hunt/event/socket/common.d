/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.cn
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.event.socket.common;

import hunt.container.ByteBuffer;
import hunt.event.EventLoop;
import hunt.event.core;
import hunt.logging;
import hunt.lang.common;

import std.socket;
import std.functional;
import std.datetime;
import core.stdc.stdint;
import std.socket;

version (Windows) import SOCKETOPTIONS = core.sys.windows.winsock2;

version (Posix) import SOCKETOPTIONS = core.sys.posix.sys.socket;

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
interface Stream {

}

/**
*/
abstract class AbstractSocketChannel : AbstractChannel {

    protected bool _isWritting = false;

    this(Selector loop, ChannelType type) {
        super(loop, type);
    }

    // Busy with reading or writting
    protected bool isBusy() { return false; }

    protected @property void socket(Socket s) {
        this.handle = s.handle();
        version (Posix) {
            s.blocking = false;
        }
        _socket = s;
        version (HUNT_DEBUG)
            infof("new socket: fd=%d", this.handle);
    }

    protected @property Socket socket() {
        return _socket;
    }

    protected Socket _socket;

    override void close() {
        if(_isClosing)
            return;
        _isClosing = true;
        version (HUNT_DEBUG) tracef("closing [fd=%d]...", this.handle);

        if(isBusy) {
            import std.parallelism;
            version (HUNT_DEBUG) warning("Close operation delayed");
            auto theTask = task(() {
                while(isBusy) {
                    version (HUNT_DEBUG) infof("waitting for idle [fd=%d]...", this.handle);
                    // Thread.sleep(20.msecs);
                }
                super.close();
            });
            taskPool.put(theTask);
        } else {
            super.close();
        }
    }

    /// Get a socket option.
    /// Returns: The number of bytes written to $(D result).
    //returns the length, in bytes, of the actual result - very different from getsockopt()
    pragma(inline) final int getOption(SocketOptionLevel level, SocketOption option, void[] result) @trusted {
        return this._socket.getOption(level, option, result);
    }

    /// Common case of getting integer and boolean options.
    pragma(inline) final int getOption(SocketOptionLevel level,
            SocketOption option, ref int32_t result) @trusted {
        return this._socket.getOption(level, option, result);
    }

    /// Get the linger option.
    pragma(inline) final int getOption(SocketOptionLevel level, SocketOption option,
            ref Linger result) @trusted {
        return this._socket.getOption(level, option, result);
    }

    /// Get a timeout (duration) option.
    pragma(inline) final void getOption(SocketOptionLevel level,
            SocketOption option, ref Duration result) @trusted {
        this._socket.getOption(level, option, result);
    }

    /// Set a socket option.
    pragma(inline) final void setOption(SocketOptionLevel level, SocketOption option, void[] value) @trusted {
        this._socket.setOption(forward!(level, option, value));
    }

    /// Common case for setting integer and boolean options.
    pragma(inline) final void setOption(SocketOptionLevel level, SocketOption option, int32_t value) @trusted {
        this._socket.setOption(forward!(level, option, value));
    }

    /// Set the linger option.
    pragma(inline) final void setOption(SocketOptionLevel level, SocketOption option, Linger value) @trusted {
        this._socket.setOption(forward!(level, option, value));
    }

    pragma(inline) final void setOption(SocketOptionLevel level, SocketOption option, Duration value) @trusted {
        this._socket.setOption(forward!(level, option, value));
    }

    final @property @trusted Address remoteAddress() {
        return _remoteAddress;
    }

    protected Address _remoteAddress;

    final @property @trusted Address localAddress() {
        return _localAddress;
    }

    protected Address _localAddress;

    version (Windows) {
        void setRead(size_t bytes) {
            readLen = bytes;
        }

        protected size_t readLen;
    }

    void start();

    void onWriteDone() {
        assert(false, "unimplemented");
    }

}

/**
*/
class SocketStreamBuffer : StreamWriteBuffer {

    this(const(ubyte)[] data, DataWrittenHandler handler = null) {
        _buffer = data;
        _pos = 0;
        _sentHandler = handler;
    }

    const(ubyte)[] remaining() {
        return _buffer[_pos .. $];
    }

    bool pop(size_t size) {
        _pos += size;
        if (_pos >= _buffer.length)
            return true;
        else
            return false;
    }

    void finish() {
        if (_sentHandler)
            _sentHandler(_buffer, _pos);
        _sentHandler = null;
        _buffer = null;
    }

    StreamWriteBuffer next() {
        return _next;
    }

    void next(StreamWriteBuffer v) {
        _next = v;
    }

    size_t capacity() {
        return _buffer.length;
    }

private:
    StreamWriteBuffer _next;
    size_t _pos = 0;
    const(ubyte)[] _buffer;
    DataWrittenHandler _sentHandler;
}

/**
*/
struct WriteBufferQueue {
    StreamWriteBuffer front() nothrow @safe {
        return _first;
    }

    bool empty() nothrow @safe {
        return _first is null;
    }

    void clear() {
        StreamWriteBuffer current = _first;
        while (current !is null) {
            _first = current.next;
            current.next = null;
            current = _first;
        }

        _first = null;
        _last = null;
    }

    void enQueue(StreamWriteBuffer wsite) {
        assert(wsite);
        if (_last) {
            _last.next = wsite;
        } else {
            _first = wsite;
        }
        wsite.next = null;
        _last = wsite;
    }

    StreamWriteBuffer deQueue() {
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


/**
*/
Address createAddress(AddressFamily family = AddressFamily.INET, ushort port=InternetAddress.PORT_ANY)
{
    if (family == AddressFamily.INET6) {
        // addr = new Internet6Address(port); // bug on windows
        return new Internet6Address("::", port);
    }
    else
        return new InternetAddress(port);
}
