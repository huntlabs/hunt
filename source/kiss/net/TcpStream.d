module kiss.net.TcpStream;

import kiss.event;

public import kiss.net.struct_;

import std.experimental.logger;
import std.exception;

debug __gshared int streamCounter = 0;

//No-Thread-safe
@trusted class TcpStream : Transport
{
    private Socket m_socket;
    this(EventLoop loop,AddressFamily amily)
    {
        _loop = loop;
        _watcher = cast(TcpStreamWatcher)loop.createWatcher(WatcherType.TCP);
        _watcher.setFamily(amily);
        _watcher.watcher(this);
        m_socket = _watcher.socket;
    }

    this(EventLoop loop,Socket socket)
    {
        _loop = loop;
        _watcher = cast(TcpStreamWatcher)loop.createWatcher(WatcherType.TCP);
        _watcher.setSocket(socket);
        _watcher.watcher(this);
        m_socket = socket;

        debug synchronized{
        streamCounter++;
        _watcher.number = streamCounter;
        }

    }

    mixin TransportSocketOption;

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
        if(_watcher.active)
            onClose(_watcher);
        else
            warningf("The watcher(fd=%d) has already been closed", _watcher.fd);
    }

    TcpStream write(StreamWriteBuffer data){
        if(_watcher.active){
            _writeQueue.enQueue(data);
            onWrite(_watcher);
        } else {
            warningf("The watcher(fd=%d) is down!", _watcher.fd);
            data.doFinish();
        }
        return this;
    }

    final EventLoop eventLoop(){return _loop;}

protected:

    TcpStreamWatcher _watcher;
    CloseCallBack _closeBack;
    TcpReadCallBack _readBack;
    WriteBufferQueue _writeQueue;

    override void onRead(Watcher watcher) nothrow{
        catchAndLogException((){
            bool canRead =  true;
            while(canRead && watcher.active){
                canRead = _loop.read(watcher,(Object obj) nothrow {
                    collectException((){
                        auto buffer = cast(TcpStreamWatcher.UbyteArrayObject)obj;
                        if(buffer is null){
                            error("buffer is null. The watcher will be closed.");
                            watcher.close(); 
                            return;
                        }
                        _readBack(buffer.data);
                    }());
                });

                if(watcher.isError){
                    errorf("Socket error on read: fd=%d, message=%s", watcher.fd, watcher.erroString); 
                    canRead = false;
                    watcher.close();
                }
            }
        }());
    }

    override void onClose(Watcher watcher) nothrow{
        catchAndLogException((){
            // debug infof("onClose=>watcher[%d].fd=%d, active=%s", watcher.number, 
            //     watcher.fd, watcher.active);

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

                // debug infof("onWrite=>streamCounter[%d]=%d, data length=%d", 
                //     watcher.number,  readCounter, data.length );
            
                size_t writedSize;
                canWrite = _loop.write(_watcher,data,writedSize);
                if(buffer.popSize(writedSize)){
                    buffer.doFinish();
                    if(watcher.active)
                    _writeQueue.deQueue();
                }

                if(watcher.isError){
                    errorf("Socket error on write: fd=%d, message=%s", watcher.fd, watcher.erroString); 
                    canWrite = false;
                    watcher.close();
                }
            }
        }());
    }

private:
    EventLoop _loop;
}
