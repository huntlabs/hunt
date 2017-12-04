module kiss.socket.tcp;

import kiss.event;

public import kiss.socket.struct_;

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
        _watcher.watcher(this);
    }

    this(EventLoop loop,Socket sock)
    {
        _loop = loop;
        _watcher = cast(TcpSocketWatcher)loop.createWatcher(WatcherType.TCP);
        _watcher.setSocket(sock);
        _watcher.watcher(this);
    }

    TCPSocket setClose(CloseCallBack cback){
        _closeBack = cback;
        return this;
    }
    TCPSocket setReadData(TcpReadCallBack cback){
        _readBack = cback;
        return this;
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

    TCPSocket write(TCPWriteBuffer data){
        if(_watcher.active){
            _writeQueue.enQueue(data);
            onWrite(_watcher);
        } else {
            warning("tcp socket is not is eventLoop!");
            data.doFinish();
        }
        return this;
    }

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
            watcher.close();
            while(!_writeQueue.empty){
                TCPWriteBuffer buffer = _writeQueue.deQueue();
                buffer.doFinish();
            }
            if(_closeBack)
                _closeBack();
        } catch(Exception e){
            collectException(()@trusted{error("the Tcp socket Close is Exception: ", e.toString());}()); 
        }
    }

    override void onWrite(Watcher watcher) nothrow{
        try{
            bool canWrite = true;
            while(canWrite && watcher.active && !_writeQueue.empty){
                TCPWriteBuffer buffer = _writeQueue.front();
                const(ubyte[]) data = buffer.sendData();
                if(data.length == 0){
                    buffer.doFinish();
                    continue;
                }
                size_t writedSize;
                canWrite = _loop.write(_watcher,data,writedSize);
                if(buffer.popSize(writedSize)){
                    buffer.doFinish();
                    _writeQueue.deQueue();
                }
                if(watcher.isError){
                    canWrite = false;
                    watcher.close();
                    error("the Tcp socket Read is error: ", watcher.erroString); 
                }
            }
        } catch(Exception e){
            collectException(()@trusted{error("the Tcp socket Close is Exception: ", e.toString());}()); 
        }
    }

protected:
    TcpSocketWatcher _watcher;

    CloseCallBack _closeBack;
    TcpReadCallBack _readBack;
    WriteBufferQueue _writeQueue;
private:
    EventLoop _loop;
}
