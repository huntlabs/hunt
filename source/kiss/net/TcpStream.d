module kiss.net.TcpStream;

import kiss.event;

public import kiss.net.struct_;

import std.experimental.logger;
import std.exception;

//No-Thread-safe
final class TcpStream : Transport
{
    this(EventLoop loop,AddressFamily amily)
    {
        _loop = loop;
        _watcher = cast(TcpStreamWatcher)loop.createWatcher(WatcherType.TCP);
        _watcher.setFamily(amily);
        _watcher.watcher(this);
    }

    this(EventLoop loop,Socket sock)
    {
        _loop = loop;
        _watcher = cast(TcpStreamWatcher)loop.createWatcher(WatcherType.TCP);
        _watcher.setSocket(sock);
        _watcher.watcher(this);
    }

    TcpStream setCloseHandle(CloseCallBack cback){
        _closeBack = cback;
        return this;
    }
    TcpStream setReadHandle(TcpReadCallBack cback){
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

    TcpStream write(StreamWriteBuffer data){
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
        catchAndLogException((){
            bool canRead =  true;
            while(canRead && watcher.active){
                canRead = _loop.read(watcher,(Object obj) nothrow {
                    collectException((){
                        auto buffer = cast(TcpStreamWatcher.UbyteArrayObject)obj;
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
        }());
    }

    override void onClose(Watcher watcher) nothrow{
        catchAndLogException((){
            watcher.close();
            while(!_writeQueue.empty){
                StreamWriteBuffer buffer = _writeQueue.deQueue();
                buffer.doFinish();
            }
            if(_closeBack)
                _closeBack();
        }());
    }

    override void onWrite(Watcher watcher) nothrow{
        catchAndLogException((){
            bool canWrite = true;
            while(canWrite && watcher.active && !_writeQueue.empty){
                StreamWriteBuffer buffer = _writeQueue.front();
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
        }());
    }

protected:
    TcpStreamWatcher _watcher;

    CloseCallBack _closeBack;
    TcpReadCallBack _readBack;
    WriteBufferQueue _writeQueue;
private:
    EventLoop _loop;
}
