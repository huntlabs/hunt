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

module hunt.io.socket.Common;

// import hunt.collection.ByteBuffer;
import hunt.concurrency.MagedQueue;
import hunt.concurrency.TaskPool;
import hunt.event.EventLoop;
import hunt.Exceptions;
import hunt.Functions;
import hunt.logging;
import hunt.system.Memory;
import hunt.util.Common;
import hunt.Version;

import core.atomic;
import core.stdc.stdint;

import std.bitmanip;
import std.datetime;
import std.exception;
import std.functional;
import std.socket;

version (HAVE_IOCP) import SOCKETOPTIONS = core.sys.windows.winsock2;

version (Posix) import SOCKETOPTIONS = core.sys.posix.sys.socket;

alias ReadCallBack = void delegate(Object obj);
alias DataReceivedHandler = void delegate(const ubyte[] data);
alias DataWrittenHandler = void delegate(const ubyte[] data, size_t size);
alias AcceptHandler = void delegate(Socket socket);

alias ConnectionHandler = void delegate(bool isSucceeded);

// dfmt off
alias UDPReadCallBack = void delegate(in ubyte[] data, Address addr);
alias AcceptCallBack = void delegate(Selector loop, Socket socket) ;
// dfmt on

@property TaskPool ioWorkersPool() @trusted {
    import std.concurrency : initOnce;

    __gshared TaskPool pool;
    return initOnce!pool({
        auto p = new TaskPool(defaultPoolThreads);
        p.isDaemon = true;
        return p;
    }());
}

private shared uint _defaultPoolThreads = uint.max;

/**
These properties get and set the number of worker threads in the `TaskPool`
instance returned by `taskPool`.  The default value is `totalCPUs` - 1.
Calling the setter after the first call to `taskPool` does not changes
number of worker threads in the instance returned by `taskPool`.
*/
@property uint defaultPoolThreads() @trusted {
    const local = atomicLoad(_defaultPoolThreads);
    return local < uint.max ? local : totalCPUs - 1;
}

/// Ditto
@property void defaultPoolThreads(uint newVal) @trusted {
    atomicStore(_defaultPoolThreads, newVal);
}

/**
*/
interface StreamWriteBuffer {
    // todo Write Data;
    const(ubyte)[] remaining();

    // add send offiset and return is empty
    bool pop(size_t size);

    // do send finish
    void finish();

    StreamWriteBuffer next();
    
    void next(StreamWriteBuffer);

    size_t capacity();
}

/**
*/
interface Channel {

}

/**
http://tutorials.jenkov.com/java-nio/selectors.html
*/
abstract class Selector {

    protected shared bool _running;

    abstract bool register(AbstractChannel channel);

    abstract bool reregister(AbstractChannel channel);

    abstract bool deregister(AbstractChannel channel);

    void stop() {
        atomicStore(_running, false);
        version (HUNT_DEBUG)
            trace("Selector stopped.");
    }

    abstract void dispose();

    /**
     * Tells whether or not this selector is open.
     *
     * @return <tt>true</tt> if, and only if, this selector is open
     */
    bool isOpen() {
        return atomicLoad(_running);
    }

    alias isRuning = isOpen;

    /**
        timeout: in millisecond
    */
    protected void onLoop(scope void delegate() wakeup, long timeout = -1) {
        _running = true;
        do {
            // version (HUNT_DEBUG) trace("Selector rolled once.");
            wakeup();
            lockAndDoSelect(timeout);
        }
        while (_running);
        dispose();
    }

    /**
        timeout: in millisecond
    */
    int select(long timeout) {
        if (timeout < 0)
            throw new IllegalArgumentException("Negative timeout");
        return lockAndDoSelect((timeout == 0) ? -1 : timeout);
    }

    int select() {
        return select(0);
    }

    int selectNow() {
        return lockAndDoSelect(0);
    }

    protected abstract int doSelect(long timeout);

    private int lockAndDoSelect(long timeout) {
        // synchronized (this) {
        // if (!isOpen())
        //     throw new ClosedSelectorException();
        // synchronized (publicKeys) {
        //     synchronized (publicSelectedKeys) {
        //         return doSelect(timeout);
        //     }
        // }
        return doSelect(timeout);
        // }
    }
}

/**
*/
abstract class AbstractChannel : Channel {
    socket_t handle = socket_t.init;
    ErrorEventHandler errorHandler;

    protected bool _isRegistered = false;
    protected bool _isClosing = false;
    protected bool _isClosed = false;

    this(Selector loop, ChannelType type) {
        this._inLoop = loop;
        _type = type;
        _flags = BitArray([false, false, false, false, false, false, false,
                false, false, false, false, false, false, false, false, false]);
    }

    /**
    */
    bool isRegistered() {
        return _isRegistered;
    }

    /**
    */
    bool isClosed() {
        return _isClosing || _isClosed;
    }

    protected void onClose() {
        _isRegistered = false;
        _isClosed = true;
        _isClosing = false;
        version (HAVE_IOCP) {
        } else {
            _inLoop.deregister(this);
        }
        clear();

        version (HUNT_DEBUG)
            tracef("closed [fd=%d]...", this.handle);
    }

    protected void errorOccurred(string msg) {
        debug warningf("isRegistered: %s, isClosed: %s, msg=%s", _isRegistered, _isClosed, msg);
        if (errorHandler !is null) {
            errorHandler(msg);
        }
    }

    void onRead() {
        assert(false, "not implemented");
    }

    void onWrite() {
        assert(false, "not implemented");
    }

    final bool hasFlag(ChannelFlag index) {
        return _flags[index];
    }

    @property ChannelType type() {
        return _type;
    }

    @property Selector eventLoop() {
        return _inLoop;
    }

    void close() {
        if (!_isClosed) {
            version (HUNT_DEBUG)
                tracef("channel[fd=%d] closing...", this.handle);
            onClose();
            version (HUNT_DEBUG)
                tracef("channel[fd=%d] closed...", this.handle);
        } else {
            debug warningf("The channel[fd=%d] has already been closed", this.handle);
        }
    }

    void setNext(AbstractChannel next) {
        if (next is this)
            return; // Can't set to self
        next._next = _next;
        next._priv = this;
        if (_next)
            _next._priv = next;
        this._next = next;
    }

    void clear() {
        if (_priv)
            _priv._next = _next;
        if (_next)
            _next._priv = _priv;
        _next = null;
        _priv = null;
    }

    mixin OverrideErro;

protected:
    final void setFlag(ChannelFlag index, bool enable) {
        _flags[index] = enable;
    }

    Selector _inLoop;

private:
    BitArray _flags;
    ChannelType _type;

    AbstractChannel _priv;
    AbstractChannel _next;
}

/**
*/
class EventChannel : AbstractChannel {
    this(Selector loop) {
        super(loop, ChannelType.Event);
    }

    void call() {
        assert(false);
    }

    // override void close() {
    //     if(_isClosing)
    //         return;
    //     _isClosing = true;
    //     version (HUNT_DEBUG) tracef("closing [fd=%d]...", this.handle);

    //     if(isBusy) {
    //         import std.parallelism;
    //         version (HUNT_DEBUG) warning("Close operation delayed");
    //         auto theTask = task(() {
    //             while(isBusy) {
    //                 version (HUNT_DEBUG) infof("waitting for idle [fd=%d]...", this.handle);
    //                 // Thread.sleep(20.msecs);
    //             }
    //             super.close();
    //         });
    //         taskPool.put(theTask);
    //     } else {
    //         super.close();
    //     }
    // }
}

mixin template OverrideErro() {
    bool isError() {
        return _error;
    }

    string erroString() {
        return _erroString;
    }

    void clearError() {
        _error = false;
        _erroString = "";
    }

    bool _error = false;
    string _erroString;
}

enum ChannelType : ubyte {
    Accept = 0,
    TCP,
    UDP,
    Timer,
    Event,
    File,
    None
}

enum ChannelFlag : ushort {
    None = 0,
    Read,
    Write,

    OneShot = 8,
    ETMode = 16
}

final class UdpDataObject {
    Address addr;
    ubyte[] data;
}

final class BaseTypeObject(T) {
    T data;
}

class LoopException : Exception {
    mixin basicExceptionCtors;
}

/**
*/
interface Stream {

}

/**
*/
abstract class AbstractSocketChannel : AbstractChannel {

    protected shared bool _isWritting = false;

    this(Selector loop, ChannelType type) {
        super(loop, type);
    }

    // Busy with reading or writting
    protected bool isBusy() {
        return false;
    }

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
        if (_isClosing) {
            // debug warningf("already closed [fd=%d]", this.handle);
            return;
        }
        _isClosing = true;
        version (HUNT_DEBUG)
            tracef("closing [fd=%d]...", this.handle);

        if (isBusy) {
            import std.parallelism;

            version (HUNT_DEBUG)
                warning("Close operation delayed");
            auto theTask = task(() {
                while (isBusy) {
                    version (HUNT_DEBUG)
                        infof("waitting for idle [fd=%d]...", this.handle);
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

    version (HAVE_IOCP) {
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


alias WritingBufferQueue = MagedNonBlockingQueue!StreamWriteBuffer;

// class WriteBufferQueue : MagedBlockingQueue!StreamWriteBuffer {

// }

/**
*/
// struct WriteBufferQueue {
//     StreamWriteBuffer front() nothrow @safe {
//         return _first;
//     }

//     bool empty() nothrow @safe {
//         return _first is null;
//     }

//     void clear() {
//         StreamWriteBuffer current = _first;
//         while (current !is null) {
//             _first = current.next;
//             current.next = null;
//             current = _first;
//         }

//         _first = null;
//         _last = null;
//     }

//     void enQueue(StreamWriteBuffer wsite) {
//         assert(wsite);
//         if (_last) {
//             _last.next = wsite;
//         } else {
//             _first = wsite;
//         }
//         wsite.next = null;
//         _last = wsite;
//     }

//     StreamWriteBuffer deQueue() {
//         // assert(_first && _last);
//         StreamWriteBuffer wsite = _first;
//         if (_first !is null)
//             _first = _first.next;

//         if (_first is null)
//             _last = null;

//         return wsite;
//     }

// private:
//     StreamWriteBuffer _last = null;
//     StreamWriteBuffer _first = null;
// }

/**
*/
Address createAddress(AddressFamily family = AddressFamily.INET,
        ushort port = InternetAddress.PORT_ANY) {
    if (family == AddressFamily.INET6) {
        // addr = new Internet6Address(port); // bug on windows
        return new Internet6Address("::", port);
    } else
        return new InternetAddress(port);
}

// dfmt off
version(linux):
// dfmt on
static if (CompilerHelper.isLessThan(2078)) {
    version (X86) {
        enum SO_REUSEPORT = 15;
    } else version (X86_64) {
        enum SO_REUSEPORT = 15;
    } else version (MIPS32) {
        enum SO_REUSEPORT = 0x0200;
    } else version (MIPS64) {
        enum SO_REUSEPORT = 0x0200;
    } else version (PPC) {
        enum SO_REUSEPORT = 15;
    } else version (PPC64) {
        enum SO_REUSEPORT = 15;
    } else version (ARM) {
        enum SO_REUSEPORT = 15;
    }
}
