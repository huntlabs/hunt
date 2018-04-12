module kiss.net.TcpListener;

import kiss.event;
public import kiss.net.struct_;

import std.socket;
import std.exception;
import std.experimental.logger;
import core.thread;
import core.time;

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
    
    mixin TransportSocketOption;

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

    TcpListener reusePort(bool use) {
        _watcher.socket.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, use);
        version (Posix){
            import kiss.event.impl.epoll_watcher;
            import kiss.event.impl.kqueue_watcher;
            _watcher.socket.setOption(SocketOptionLevel.SOCKET, cast(SocketOption) SO_REUSEPORT,
                use);
        }
        version (windows) {
            if (!use) {
                import core.sys.windows.winsock2;
                _watcher.socket.setOption(SocketOptionLevel.SOCKET,
                    cast(SocketOption) SO_EXCLUSIVEADDRUSE, true);
            }
        }

        return this;
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
            debug trace("start to listen");
            while(canRead && watcher.active) // why??
            {
                debug trace("listening...");
                canRead = _loop.read(watcher,(Object obj) nothrow {
                    collectException((){
                        auto socket = cast(Socket)obj;
                        
                        if(socket !is null){
                            debug infof("new connection from %s, fd=%d", 
                                socket.remoteAddress.toString(), socket.handle());
                            _readBack(_loop,socket);
                        }
                    }());
                });

                if(watcher.isError){
                    canRead = false;
                    watcher.close();
                    error("The socket for tcp listener has an error: ", watcher.erroString); 
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
