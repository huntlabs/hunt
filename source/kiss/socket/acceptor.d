module kiss.socket.acceptor;

import kiss.event;
import kiss.socket.struct_;

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
    }

    this(EventLoop loop,Socket sock)
    {
        _loop = loop;
        _watcher = cast(AcceptorWatcher)loop.createWatcher(WatcherType.ACCEPT);
        _watcher.setSocket(sock);
    }

    void setClose(CloseCallBack cback){
        _closeBack = cback;
    }
    void setReadData(AcceptCallBack cback){
        _readBack = cback;
    }

    void bind(Address addr){
        _watcher.socket.bind(addr);
    }
    Address bind(){
        return _watcher.socket.localAddress();
    }
    void listen(int backlog){
        _watcher.socket.listen(backlog);
    }

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
        try{
            bool canRead =  true;
            while(canRead && watcher.active){
                canRead = _loop.read(watcher,(Object obj) nothrow {
                    collectException((){
                        auto socket = cast(Socket)obj;
                        if(socket !is null){
                            _readBack(socket);
                        }
                    }());
                });
                if(watcher.isError){
                    canRead = false;
                    watcher.close();
                    error("the Tcp socket Read is error: ", watcher.erroString); 
                }
            }
        } catch(Exception e){
            collectException(()@trusted{error("the Tcp socket Read is Exception: ", e.toString());}()); 
        }
    }

    override void onClose(Watcher watcher) nothrow{
        try{
            _watcher.close();
        } catch(Exception e){
            collectException(()@trusted{error("the Tcp socket Read is Exception: ", e.toString());}()); 
        }
    }

protected:
    AcceptorWatcher _watcher;

    CloseCallBack _closeBack;
    AcceptCallBack _readBack;
    WriteBufferQueue _writeQueue;
private:
    EventLoop _loop;
}
