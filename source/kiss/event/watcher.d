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

    final override void onClose()
    {
        if(watcher)
            watcher.onClose(this);
    }

    final override void onRead()
    {
        if(watcher)
            watcher.onRead(this);
    }

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

    final override void onClose()
    {
        if(watcher)
            watcher.onClose(this);
    }

    final override void onRead()
    {
        if(watcher)
            watcher.onRead(this);
    }

    final override void onWrite()
    {
        if(watcher)
            watcher.onWrite(this);
    }

    final Socket socket(){if(_socket is null) setFamily(AddressFamily.INET); return _socket;}

    UbyteArrayObject _readBuffer;
protected:
    Socket _socket;
}

@trusted abstract class AcceptorWatcher : TransportWatcher!ReadTransport
{
    this(){
        super(WatcherType.ACCEPT);
    }

    final void setFamily(AddressFamily family){
         _socket = new Socket(family,SocketType.STREAM, ProtocolType.TCP);
    }

    final override void onClose()
    {
        if(watcher)
            watcher.onClose(this);
    }

    final override void onRead()
    {
        if(watcher)
            watcher.onRead(this);
    }

    final @property  Socket socket(){return _socket;}
protected:
    Socket _socket;
}

@trusted abstract class UDPSocketWatcher : TransportWatcher!Transport
{
    this(){
        super(WatcherType.UDP);
        _readBuffer = new UdpDataObject();
        _readBuffer.data = new ubyte[4096 * 2];
    }

    final void setFamily(AddressFamily family){
         _socket = new UdpSocket(family);
    }

    final override void onClose()
    {
        if(watcher)
            watcher.onClose(this);
    }

    final override void onRead()
    {
        if(watcher)
            watcher.onRead(this);
    }
    
    final UdpSocket socket(){return _socket;}
    UdpDataObject _readBuffer;
protected:
    UdpSocket _socket;
}

socket_t getSocketFD(T)(Watcher watcher){
    T watch = cast(T)watcher;
    if(watch !is null && watch.socket !is null){
        return watch.socket.handle;
    }
    return socket_t.init;
}