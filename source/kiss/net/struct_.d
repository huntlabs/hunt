module kiss.net.struct_;

public import std.socket;
import kiss.event.loop;

alias CloseCallBack = void delegate() @trusted nothrow;

alias TcpReadCallBack = void delegate(in ubyte[] data) @trusted nothrow;

alias TcpConnectCallBack = void delegate(bool connected) @trusted nothrow;

alias UDPReadCallBack = void delegate(in ubyte[] data, Address addr) @trusted nothrow;

alias AcceptCallBack = void delegate(EventLoop loop, Socket socket) @trusted nothrow;

alias TCPWriteCallBack = void delegate(in ubyte[] data, size_t size) @trusted nothrow;


@trusted abstract class StreamWriteBuffer
{
    // todo Write Data;
    const(ubyte)[] sendData() nothrow;
    // add send offiset and return is empty
    bool popSize(size_t size) nothrow;
    // do send finish
    void doFinish() nothrow;

private:
    StreamWriteBuffer _next;
}

final class WarpStreamBuffer : StreamWriteBuffer
{
    this(const(ubyte)[] data, TCPWriteCallBack cback = null)
    {
        _data = data;
        _site = 0;
        _cback = cback;
    }

    override const(ubyte)[] sendData() nothrow
    {
        return _data[_site .. $];
    }

    // add send offiset and return is empty
    override bool popSize(size_t size) nothrow
    {
        _site += size;
        if (_site >= _data.length)
            return true;
        else
            return false;
    }
    // do send finish
    override void doFinish() nothrow
    {
        if (_cback)
        {
			_cback(_data, _site);
        }
        _cback = null;
        _data = null;
    }

private:
    size_t _site = 0;
    const(ubyte)[] _data;
    TCPWriteCallBack _cback;
}

struct WriteBufferQueue
{
	@safe StreamWriteBuffer  front() nothrow{
		return _frist;
	}

	@safe bool empty() nothrow{
		return _frist is null;
	}

	@safe void enQueue(StreamWriteBuffer wsite) nothrow
	in{
		assert(wsite);
	}body{
		if(_last){
			_last._next = wsite;
		} else {
			_frist = wsite;
		}
		wsite._next = null;
		_last = wsite;
	}

	@safe StreamWriteBuffer deQueue() nothrow
	in{
		assert(_frist && _last);
	}body{
		StreamWriteBuffer  wsite = _frist;
		_frist = _frist._next;
		if(_frist is null)
			_last = null;
		return wsite;
	}

private:
	StreamWriteBuffer  _last = null;
	StreamWriteBuffer  _frist = null;
}