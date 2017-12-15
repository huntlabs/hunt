module kiss.net.TcpListener;

import kiss.event;
public import kiss.net.struct_;

import std.socket;
import std.exception;
import std.experimental.logger;

final class TcpListener : ReadTransport
{
    this(EventLoop loop,AddressFamily amily)
    {
        _loop = loop;
        _watcher = cast(TcpListenerWatcher)loop.createWatcher(WatcherType.ACCEPT);
        _watcher.setFamily(amily);
        _watcher.watcher(this);
    }

    this(EventLoop loop,Socket sock)
    {
        _loop = loop;
        _watcher = cast(TcpListenerWatcher)loop.createWatcher(WatcherType.ACCEPT);
        _watcher.setSocket(sock);
        _watcher.watcher(this);
    }

    TcpListener setCloseHandle(CloseCallBack cback){
        _closeBack = cback;
        return this;
    }
    TcpListener setReadHandle(AcceptCallBack cback){
        _readBack = cback;
        return this;
    }

    TcpListener bind(string ip,ushort port){
        _watcher.socket.bind(parseAddress(ip,port));
        return this;
    }

    TcpListener bind(ushort port){
        _watcher.socket.bind(createAddress(_watcher.socket,port));
        return this;
    }

    TcpListener bind(Address addr){
        _watcher.socket.bind(addr);
        return this;
    }

    Address bind(){
        return _watcher.socket.localAddress();
    }

    TcpListener listen(int backlog){
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
        catchAndLogException((){
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
        catchAndLogException((){
            _watcher.close();
        }());
    }

protected:
    TcpListenerWatcher _watcher;

    CloseCallBack _closeBack;
    AcceptCallBack _readBack;
private:
    EventLoop _loop;
}
