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

module hunt.event.core;

import hunt.init;
import hunt.lang.common;
import hunt.lang.exception;
import hunt.logging;

import core.atomic;
import std.bitmanip;
import std.exception;
import std.socket;

alias ReadCallBack = void delegate(Object obj);

alias DataReceivedHandler = void delegate(const ubyte[] data);
alias DataWrittenHandler = void delegate(const ubyte[] data, size_t size);
alias AcceptHandler = void delegate(Socket socket);
// dfmt on

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

alias ChannelBase = AbstractChannel;

/**
*/
interface Channel {

}

/**
http://tutorials.jenkov.com/java-nio/selectors.html
*/
abstract class Selector {

    protected shared bool _running;
    // protected shared bool _isOpen = true;

    abstract bool register(AbstractChannel channel);

    abstract bool reregister(AbstractChannel channel);

    abstract bool deregister(AbstractChannel channel);

    void stop() {
        atomicStore(_running, false);
        version (HUNT_DEBUG) trace("Selector stopped.");
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

    protected void onLoop(scope void delegate() weakup, long timeout = -1) {
        _running = true;
        do {
            // version (HUNT_DEBUG) trace("Selector rolled once.");
            weakup();
            lockAndDoSelect(timeout);
        } while (_running);
    }

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
        synchronized (this) {
            // if (!isOpen())
            //     throw new ClosedSelectorException();
            // synchronized (publicKeys) {
            //     synchronized (publicSelectedKeys) {
            //         return doSelect(timeout);
            //     }
            // }
            return doSelect(timeout);
        }
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
        version (Windows) {
        }
        else {
            _inLoop.deregister(this);
        }
        //  _inLoop = null;
        clear();

        version (HUNT_DEBUG) tracef("closed [fd=%d]...", this.handle);
    }

    protected void errorOccurred(string msg) {
        warningf("isRegistered: %s, isClosed: %s, msg=%s", _isRegistered, _isClosed, msg);
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
        }
        else {
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

// dfmt off
version(linux):
// dfmt on
static if (CompilerHelper.isSmaller(2078)) {
    version (X86) {
        enum SO_REUSEPORT = 15;
    }
    else version (X86_64) {
        enum SO_REUSEPORT = 15;
    }
    else version (MIPS32) {
        enum SO_REUSEPORT = 0x0200;
    }
    else version (MIPS64) {
        enum SO_REUSEPORT = 0x0200;
    }
    else version (PPC) {
        enum SO_REUSEPORT = 15;
    }
    else version (PPC64) {
        enum SO_REUSEPORT = 15;
    }
    else version (ARM) {
        enum SO_REUSEPORT = 15;
    }
}
