module kiss.socket.udp;

import kiss.event.base;
import kiss.event.loop;
import kiss.event.watcher;

import std.socket;
import std.exception;
import std.experimental.logger;

final class UDPSocket : Transport
{
    
    void setClose(){}
    void setData(){}

    void write(){}
    
    override void close(){}

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
                        // auto buffer = cast(TcpSocketWatcher.UbyteArrayObject)obj;
                        // if(buffer is null){
                        //     watcher.close(); 
                        //     return;
                        // }
                        // _readBack(buffer.data);
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

    override void onClose(Watcher watcher)  nothrow{
        try{
            _watcher.close();
        } catch(Exception e){
            collectException(()@trusted{error("the Tcp socket Read is Exception: ", e.toString());}()); 
        }
    }

    override void onWrite(Watcher watcher) nothrow{

    }

private:
    UDPSocketWatcher _watcher;
    ReadCallBack _readCallBack;
    EventLoop _loop;
}