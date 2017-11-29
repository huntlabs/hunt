module kiss.event.impl.posix_watcher;

import kiss.event.base;
import kiss.event.watcher;
import kiss.event.struct_;

import std.socket;
import std.string;

import core.sys.posix.sys.socket;


mixin template PosixOverrideErro()
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

final class PosixTCPWatcher : TcpSocketWatcher
{
    this()
    {
        super();
        setFlag(WatchFlag.Read,true);
        setFlag(WatchFlag.Write,true);
        setFlag(WatchFlag.ETMode,true);
    }
   
   mixin PosixOverrideErro;
}

final class PosixUDPWatcher : UDPSocketWatcher
{
    this()
    {
        super();
        setFlag(WatchFlag.Read,true);
        setFlag(WatchFlag.ETMode,false);
    }

    mixin PosixOverrideErro;
}

final class PosixAcceptWatcher : AcceptorWatcher
{
    this()
    {
        super();
        setFlag(WatchFlag.Read,true);
    }

    mixin PosixOverrideErro;
}



bool readTcp(PosixTCPWatcher watch, scope ReadCallBack read)
{
    bool canRead = false;
    if(watch is null || read is null) return canRead;
    watch.clearError();
    auto data = watch._readBuffer.data;
    scope(exit)watch._readBuffer.data = data;
    auto len = watch.socket.receive(watch._readBuffer.data);
    if(len > 0){
        canRead = true;
        watch._readBuffer.data = watch._readBuffer.data[0..len];
        read(watch._readBuffer);
    } else if(len < 0){
        if (errno == 4) {
            canRead = true;
        } else if (errno != EAGAIN && errno != EWOULDBLOCK) {
            watch._error = true;
            watch.erroString = fromStringz(strerror(errno));
        }
    } else {
        read(null);
    }
    return canRead;
}

bool readAccept(PosixAcceptWatcher watch, scope ReadCallBack read)
{
    if(watch is null || read is null) return false;
    watch.clearError();
    socket_t fd = cast(socket_t)(.accept(watch.socket.handle, null, null));
    if (fd == socket_t.init)
        return false;
    Socket sock = new Socket(fd, watch.socket.addressFamily);
    read(sock);
    return true;
}

bool readUdp(PosixUDPWatcher watch, scope ReadCallBack read)
{
    if(watch is null || read is null) return false;
    
    scope Address createAddress() {
        enum ushort DPORT = 0;
        if (AddressFamily.INET == watch.socket.addressFamily)
            return new InternetAddress(DPORT);
        else if (AddressFamily.INET6 == watch.socket.addressFamily)
            return new Internet6Address(DPORT);
        else
            throw new AddressException(
                "NOT SUPPORT addressFamily. It only can be AddressFamily.INET or AddressFamily.INET6");
    }
    watch._readBuffer.addr = createAddress();
    auto data = watch._readBuffer.data;
    scope(exit)watch._readBuffer.data = data;
    auto len = _socket.receiveFrom(watch._readBuffer.data, watch._readBuffer.addr);
    if (len > 0){
        canRead = true;
        watch._readBuffer.data = watch._readBuffer.data[0..len];
        read(watch._readBuffer);
    }
    return false;
}

