module kiss.socket.udp;

import kiss.event;
public import kiss.socket.struct_;

import std.socket;
import std.exception;
import std.experimental.logger;

final class UDPSocket : Transport
{
    
    this(EventLoop loop,AddressFamily amily)
    {
        _loop = loop;
        _watcher = cast(UDPSocketWatcher)loop.createWatcher(WatcherType.UDP);
        _watcher.setFamily(amily);
        _watcher.watcher(this);
    }

    UDPSocket setReadData(UDPReadCallBack cback){
        _readBack = cback;
        return this;
    }


    ptrdiff_t sendTo(const(void)[] buf, Address to){
        return _watcher.socket.sendTo(buf,to);
    }

    ptrdiff_t sendTo(const(void)[] buf){
        return _watcher.socket.sendTo(buf);
    }

    ptrdiff_t sendTo(const(void)[] buf, SocketFlags flags, Address to){
        return _watcher.socket.sendTo(buf,flags,to);
    }

    UDPSocket bind(Address addr){
        _watcher.bind(addr);
        return this;
    }

    UDPSocket connect(Address addr){
        _watcher.socket.connect(addr);
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
                        UdpDataObject data = cast(UdpDataObject)obj;
                        if(data !is null){
                            _readBack(data.data,data.addr);
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

    override void onClose(Watcher watcher)  nothrow{
        catchAndLogException((){
            _watcher.close();
        }());
    }

    override void onWrite(Watcher watcher) nothrow{
        
    }

private:
    UDPSocketWatcher _watcher;
    UDPReadCallBack _readBack;
    EventLoop _loop;
}