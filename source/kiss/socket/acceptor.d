module kiss.socket.acceptor;

import kiss.event;
public import kiss.socket.struct_;

import std.socket;
import std.exception;
import std.experimental.logger;

final class Acceptor : ReadTransport
{
    this(EventLoop loop,AddressFamily amily)
    {
        _loop = loop;
        _watcher = cast(AcceptorWatcher)loop.createWatcher(WatcherType.ACCEPT);
        _watcher.setFamily(amily);
        _watcher.watcher(this);
    }

    this(EventLoop loop,Socket sock)
    {
        _loop = loop;
        _watcher = cast(AcceptorWatcher)loop.createWatcher(WatcherType.ACCEPT);
        _watcher.setSocket(sock);
        _watcher.watcher(this);
    }

    Acceptor setClose(CloseCallBack cback){
        _closeBack = cback;
        return this;
    }
    Acceptor setReadData(AcceptCallBack cback){
        _readBack = cback;
        return this;
    }

    Acceptor bind(Address addr){
        _watcher.socket.bind(addr);
        return this;
    }

    Address bind(){
        return _watcher.socket.localAddress();
    }

    Acceptor listen(int backlog){
        _watcher.socket.listen(backlog);
        return this;
    }

    EventLoop eventLoop(){return _loop;}

    override bool watched(){
        return _watcher.active;
    }

    override bool watch() {
        return _loop.register(_watcher);
    }

    override void close(){
        onClose(_watcher);
    }
protected:
    override void onRead(Watcher watcher) nothrow{
        catchException((){
            bool canRead =  true;
            while(canRead && watcher.active){
                canRead = _loop.read(watcher,(Object obj) nothrow {
                    collectException((){
                        auto socket = cast(Socket)obj;
                        if(socket !is null){
                            _readBack(_loop,socket);
                        }
                    }());
                });
                if(watcher.isError){
                    canRead = false;
                    watcher.close();
                    error("the Tcp socket Read is error: ", watcher.erroString); 
                }
            }
        }());
    }

    override void onClose(Watcher watcher) nothrow{
        catchException((){
            _watcher.close();
        }());
    }

protected:
    AcceptorWatcher _watcher;

    CloseCallBack _closeBack;
    AcceptCallBack _readBack;
    WriteBufferQueue _writeQueue;
private:
    EventLoop _loop;
}
