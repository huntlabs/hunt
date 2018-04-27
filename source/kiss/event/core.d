module kiss.event.core;

import kiss.core;

import std.socket;
import std.exception;
import std.bitmanip;
import std.experimental.logger;

alias ReadCallBack = void delegate(Object obj);

alias DataReceivedHandler = void delegate(in ubyte[] data);
alias DataWrittenHandler = void delegate(in ubyte[] data, size_t size);
alias AcceptHandler = void delegate(Socket socket);

// dfmt off
deprecated("Using AbstractChannel instead.") 
alias Watcher = AbstractChannel;

deprecated("Using Channel instead.") 
alias BaseTransport = Channel;

@trusted interface  ReadTransport : Channel {

    void close();

    void onRead(AbstractChannel watcher) nothrow;

    void onClose(AbstractChannel watcher) nothrow;
}


@trusted interface WriteTransport : Channel {
    
    void onWrite(AbstractChannel watcher) nothrow;

    void onClose(AbstractChannel watcher) nothrow;
}


@trusted interface Transport  : ReadTransport, WriteTransport {
}

// dfmt on

interface StreamWriteBuffer
{
    // todo Write Data;
    const(ubyte)[] sendData();

    // add send offiset and return is empty
    bool popSize(size_t size);

    // do send finish
    void doFinish();

    StreamWriteBuffer next();
    void next(StreamWriteBuffer);
}

alias ChannelBase = AbstractChannel;

/**
*/
interface Channel
{

}

/**
*/
interface Selector
{
    bool register(AbstractChannel channel);

    bool reregister(AbstractChannel channel);

    bool deregister(AbstractChannel channel);

    void stop();

    void dispose();
}

/**
*/
abstract class AbstractChannel : Channel
{
    version (KissDebugMode) int number;
    socket_t handle = socket_t.init;

    ErrorEventHandler errorHandler;

    this(Selector loop, WatcherType type)
    {
        this._inLoop = loop;
        _type = type;
        _flags = BitArray([false, false, false, false, false, false, false,
                false, false, false, false, false, false, false, false, false]);
    }

    /**
    */
    bool isRegistered()
    {
        return _isRegistered;
    }

    protected bool _isRegistered = false;

    deprecated("Using isRegistered instead.") bool watched()
    {
        return _isRegistered;
    }

    /**
    */
    bool isClosed()
    {
        return _isClosed;
    }

    protected bool _isClosed = false;

    protected void onClose()
    {
        _inLoop.deregister(this);
        //  _inLoop = null;
        _isRegistered = false;
        _isClosed = true;
        clear();
    }

    protected void errorOccurred(string msg)
    {
        if (errorHandler !is null)
            errorHandler(msg);
    }

    void onRead()
    {
        assert(false, "not implemented");
    }

    void onWrite()
    {
        assert(false, "not implemented");
    }

    final bool flag(WatchFlag index)
    {
        return _flags[index];
    }

    @property WatcherType type()
    {
        return _type;
    }

    @property Selector eventLoop()
    {
        return _inLoop;
    }

    void close()
    {
        if (!_isClosed)
        {
            version (KissDebugMode)
                trace("channel closing...");
            onClose();
            version (KissDebugMode)
                trace("channel closed...");
        }
        else
        {
            debug warningf("The watcher(fd=%d) has already been closed", this.handle);
        }
    }

    void setNext(AbstractChannel next)
    {
        if (next is this)
            return; // Can't set to self
        next._next = _next;
        next._priv = this;
        if (_next)
            _next._priv = next;
        this._next = next;
    }

    void clear()
    {
        if (_priv)
            _priv._next = _next;
        if (_next)
            _next._priv = _priv;
        _next = null;
        _priv = null;
    }

    mixin OverrideErro;

protected:
    final void setFlag(WatchFlag index, bool enable)
    {
        _flags[index] = enable;
    }

    Selector _inLoop;

private:
    BitArray _flags;
    WatcherType _type;

    AbstractChannel _priv;
    AbstractChannel _next;
}

/**
*/
class EventChannel : AbstractChannel
{
    this(Selector loop)
    {
        super(loop, WatcherType.Event);
    }

    void call()
    {
        assert(false);
    }
}

mixin template OverrideErro()
{
    bool isError()
    {
        return _error;
    }

    string erroString()
    {
        return _erroString;
    }

    void clearError()
    {
        _error = false;
        _erroString = "";
    }

    bool _error = false;
    string _erroString;
}

enum WatcherType : ubyte
{
    Accept = 0,
    TCP,
    UDP,
    Timer,
    Event,
    File,
    None
}

enum WatchFlag : ushort
{
    None = 0,
    Read,
    Write,

    OneShot = 8,
    ETMode = 16
}

final class UdpDataObject
{
    Address addr;
    ubyte[] data;
}

final class BaseTypeObject(T)
{
    T data;
}

class LoopException : Exception
{
    mixin basicExceptionCtors;
}


// dfmt off
version(linux):
// dfmt on
static if (isCompilerVersionBelow(2078))
{
    version (X86)
    {
        enum SO_REUSEPORT = 15;
    }
    else version (X86_64)
    {
        enum SO_REUSEPORT = 15;
    }
    else version (MIPS32)
    {
        enum SO_REUSEPORT = 0x0200;
    }
    else version (MIPS64)
    {
        enum SO_REUSEPORT = 0x0200;
    }
    else version (PPC)
    {
        enum SO_REUSEPORT = 15;
    }
    else version (PPC64)
    {
        enum SO_REUSEPORT = 15;
    }
    else version (ARM)
    {
        enum SO_REUSEPORT = 15;
    }
}
