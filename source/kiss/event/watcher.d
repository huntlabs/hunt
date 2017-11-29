module kiss.event.watcher;

import kiss.event.base;
import kiss.event.struct_;
import std.socket;

@trusted abstract class TransportWatcher(T) : Watcher 
{
    this(WatcherType type){
        super(type);
    }

    final @property  T watcher(){ return _watcher;}
    final @property  void watcher(T watcher){_watcher = watcher;}
private:
    T _watcher;
}

@trusted abstract class TimerWatcher : TransportWatcher!ReadTransport
{
    alias UintObject = BaseTypeObject!uint;

    this(){
        super(WatcherType.Timer);
    }

    final @property time(){return _timeOut;}
    final @property time(size_t tm){_timeOut = time;} 

    // onlyOnce
    void enableWhile(){}

    bool isEnableWhile();
private:
    size_t _timeOut;
}

@trusted abstract class TcpSocketWatcher : TransportWatcher!Transport
{
    alias UbyteArrayObject = BaseTypeObject!(ubyte[]);

    this(){
        super(WatcherType.TCP);
        _readBuffer = new UbyteArrayObject();
        _readBuffer.data = new ubyte[4096 * 2];
    }

    final void setFamily(AddressFamily family){
         _socket = new Socket(family,SocketType.STREAM, ProtocolType.TCP);
    }

    final Socket socket(){if(_socket is null) setFamily(AddressFamily.INET); return _socket;}
protected:
    Socket _socket;
    UbyteArrayObject _readBuffer;
}

@trusted abstract class AcceptorWatcher : TransportWatcher!ReadTransport
{
    this(AddressFamily family){
        super(WatcherType.TCP);
        _socket = new Socket(family,SocketType.STREAM, ProtocolType.TCP);
    }

    final @property  Socket socket(){return _socket;}
protected:
    Socket _socket;
}

@trusted abstract class UDPSocketWatcher : TransportWatcher!Transport
{
    this(AddressFamily family){
        super(WatcherType.UDP);
        _socket = new UdpSocket(family);
        _readBuffer = new UdpDataObject();
        _readBuffer.data = new ubyte[4096 * 2];
    }
    
    final UdpSocket socket(){return _socket;}
protected:
    UdpSocket _socket;
    UdpDataObject _readBuffer;
}