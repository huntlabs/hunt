module kiss.socket.tcp;

import kiss.event;

import kiss.socket.struct_;

import std.experimental.logger;
import std.exception;

//No-Thread-safe
final class TCPSocket : Transport
{
    this(EventLoop loop,AddressFamily amily)
    {
        _loop = loop;
        _watcher = cast(TcpSocketWatcher)loop.createWatcher(WatcherType.TCP);
        _watcher.setFamily(amily);
    }

    this(EventLoop loop,Socket sock)
    {
        _loop = loop;
        _watcher = cast(TcpSocketWatcher)loop.createWatcher(WatcherType.TCP);
        _watcher.setSocket(sock);
    }

    void setClose(CloseCallBack cback){
        _closeBack = cback;
    }
    void setReadData(TcpReadCallBack cback){
        _readBack = cback;
    }

    void write(){}

    final EventLoop eventLoop(){return _loop;}
protected:
    override void onRead(Watcher watcher) nothrow{
        try{
            bool canRead =  true;
            while(canRead && watcher.active){
                canRead = _loop.read(watcher,(Object obj) nothrow {
                    collectException((){
                        auto buffer = cast(TcpSocketWatcher.UbyteArrayObject)obj;
                        if(buffer is null){
                            watcher.close(); 
                            return;
                        }
                        _readBack(buffer.data);
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
            //_loop.close(watcher);
            watcher.close();
        } catch(Exception e){
            collectException(()@trusted{error("the Tcp socket Close is Exception: ", e.toString());}()); 
        }
    }

    override void onWrite(Watcher watcher) nothrow{

    }

protected:
    TcpSocketWatcher _watcher;

    CloseCallBack _closeBack;
    TcpReadCallBack _readBack;
private:
    EventLoop _loop;
}
