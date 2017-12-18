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
    final @property time(size_t tm){_timeOut = tm;} 

    override void onClose()
    {
        if(watcher)
            watcher.onClose(this);
    }

    override void onRead()
    {
        if(watcher)
            watcher.onRead(this);
    }

private:
    size_t _timeOut;
}

@trusted abstract class TcpStreamWatcher : TransportWatcher!Transport
{
    alias UbyteArrayObject = BaseTypeObject!(ubyte[]);

    this(){
        super(WatcherType.TCP);
        _readBuffer = new UbyteArrayObject();
        _readBuffer.data = new ubyte[4096 * 2];
    }

    final void setFamily(AddressFamily family){
         setSocket(new Socket(family,SocketType.STREAM, ProtocolType.TCP));
    }

    void setSocket(Socket sock){
        _socket = sock;
    }

    override void onClose()
    {
        if(watcher)
            watcher.onClose(this);
    }

    override void onRead()
    {
        if(watcher)
            watcher.onRead(this);
    }

    override void onWrite()
    {
        if(watcher)
            watcher.onWrite(this);
    }

    final Socket socket(){if(_socket is null) setFamily(AddressFamily.INET); return _socket;}

    UbyteArrayObject _readBuffer;

private:
    Socket _socket;
}

@trusted abstract class TcpListenerWatcher : TransportWatcher!ReadTransport
{
    this(){
        super(WatcherType.ACCEPT);
    }

    final void setFamily(AddressFamily family){
        setSocket(new Socket(family,SocketType.STREAM, ProtocolType.TCP));
    }

    void setSocket(Socket sock){
        _socket = sock;
    }

    override void onClose()
    {
        if(watcher)
            watcher.onClose(this);
    }

    override void onRead()
    {
        if(watcher)
            watcher.onRead(this);
    }

    final @property  Socket socket(){return _socket;}
private:
    Socket _socket;
}

@trusted abstract class UdpStreamWatcher : TransportWatcher!Transport
{
    this(){
        super(WatcherType.UDP);
        _readBuffer = new UdpDataObject();
        _readBuffer.data = new ubyte[4096 * 2];
    }

    final void setFamily(AddressFamily family){
         _socket = new UdpSocket(family);
         _socket.blocking = false;
    }

    final void bind(Address addr){
        socket.bind(addr);
        _binded = true;
    }

    final bool isBind(){return _binded;}

    override void onClose()
    {
        _binded = false;
        if(watcher)
            watcher.onClose(this);
    }

    override void onRead()
    {
        if(watcher)
            watcher.onRead(this);
    }
    
    final UdpSocket socket(){return _socket;}
    UdpDataObject _readBuffer;
private:
    bool _binded = false;
    UdpSocket _socket;
}

@trusted abstract class EventWatcher : TransportWatcher!Transport
{
    this(){
        super(WatcherType.Event);
    }
    void call();
    override void onRead()
    {
        if(watcher)
            watcher.onRead(this);
    }
}

mixin template OverrideErro()
{
    override bool isError(){
        return _error;
    }
    override string erroString(){
        return _erroString;
    }

    void clearError(){
        _error = false;
        _erroString = "";
    }

    bool _error = false;
    string _erroString;
}

socket_t getSocketFD(T)(Watcher watcher){
    T watch = cast(T)watcher;
    if(watch !is null && watch.socket !is null){
        return watch.socket.handle;
    }
    return socket_t.init;
}