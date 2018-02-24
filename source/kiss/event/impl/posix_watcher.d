module kiss.event.impl.posix_watcher;

version(Posix):

import kiss.event.base;
import kiss.event.watcher;
import kiss.event.struct_;

import std.socket;
import std.string;
import std.experimental.logger;

import core.stdc.errno;
import core.stdc.string;
import core.sys.posix.sys.socket;

/**
*/
final class PosixTCPWatcher : TcpStreamWatcher
{
    this()
    {
        super();
        setFlag(WatchFlag.Read,true);
        setFlag(WatchFlag.Write,true);
        setFlag(WatchFlag.ETMode,true);
    }
   
   mixin OverrideErro;

    override void setSocket(Socket sock){
        sock.blocking = false;
        super.setSocket(sock);
    }
}

final class PosixUDPWatcher : UdpStreamWatcher
{
    this()
    {
        super();
        setFlag(WatchFlag.Read,true);
        setFlag(WatchFlag.ETMode,false);
    }

    mixin OverrideErro;
}

final class PosixAcceptWatcher : TcpListenerWatcher
{
    this()
    {
        super();
        setFlag(WatchFlag.Read,true);
    }

    mixin OverrideErro;

    override void setSocket(Socket sock){
        sock.blocking = false;
        super.setSocket(sock);
    }
}

bool connectTCP(PosixTCPWatcher watch, Address addr){
    if(watch is null || addr is null) return false;
    watch.socket.connect(addr);
    return true;
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
            watch._erroString = fromStringz(strerror(errno)).idup;
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

    debug infof("readAccept server fd=%d, remote fd=%d", watch.socket.handle, fd);

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
    scope(exit) watch._readBuffer.data = data;
    auto len = watch.socket.receiveFrom(watch._readBuffer.data, watch._readBuffer.addr);
    if (len > 0){
        watch._readBuffer.data = watch._readBuffer.data[0..len];
        read(watch._readBuffer);
    }
    return false;
}


bool writeTcp(PosixTCPWatcher watch,in ubyte[] data, out size_t writed)
{
    if(watch is null) return false;
    bool canWrite = false;
    watch.clearError();

    const auto len = watch.socket.send(data);
    if (len > 0) {
        writed = cast(size_t)len;
        canWrite = true;
    } else {
        if (errno == 4) {
            canWrite = true;
        } else if (errno != EAGAIN && errno != EWOULDBLOCK) {
            watch._error = true;
            watch._erroString = fromStringz(strerror(errno)).idup;
        }
    }
    return canWrite;
}