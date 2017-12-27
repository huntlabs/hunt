module kiss.net.TcpStreamClient;

import kiss.event;

public import kiss.net.struct_;

import std.experimental.logger;
import std.exception;

import kiss.net.TcpStream;

final class TcpStreamClient : TcpStream
{
    this(EventLoop loop,AddressFamily amily = AddressFamily.INET)
    {
        super(loop, amily);
    }

    TcpStream setConnectHandle(TcpConnectCallBack cback){
        _connect = cback;
        return this;
    }

    bool connect(Address addr)
    {
        bool watch_ = watch();
        if(watch_){
            watch_ = watch_ && eventLoop.connect(_watcher,addr);
        }
        return watch_;
    }

    bool isConnected() nothrow {return _isConnected;}

    override TcpStream write(StreamWriteBuffer data){
        if(!_isConnected)
            throw new Exception("The Client is not connect!");
        return super.write(data);
    }
protected:
    override void onClose(Watcher watcher) nothrow{
        if(!_isConnected){
            collectExceptionMsg(eventLoop.deregister(watcher));
            if(_connect)
                _connect(false);
            return;
        }
        _isConnected = false;
        super.onClose(watcher);
    }

    override void onWrite(Watcher watcher) nothrow{
        if(!_isConnected){
            _isConnected = true;
            if(_connect)
                _connect(true);
            return;
        }
        super.onWrite(watcher);
    }

private:
    TcpConnectCallBack _connect;
    bool _isConnected = false;
}