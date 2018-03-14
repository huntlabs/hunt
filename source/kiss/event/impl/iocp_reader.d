module kiss.event.impl.iocp_reader;

import kiss.event.base;
import kiss.event.struct_;
import kiss.event.watcher;
version(Windows):
import kiss.event.impl.iocp_watcher;

bool readTcp(IOCPTCPWatcher watch, scope ReadCallBack read)
{
    assert(watch !is null && read !is null);
    if(watch is null || read is null) return false;
    watch.clearError();

    debug trace("readLen=", watch.readLen);

    if(watch.readLen == 0) {
        read(null);
    } else {
        ubyte[] data  =  watch._readBuffer.data;
        watch._readBuffer.data = data[0..watch.readLen];
        read(watch._readBuffer);
        watch._readBuffer.data = data;
        if(watch.active)
            watch.doRead();
    }
    return false;
}

bool readAccept(IOCPAcceptWatcher watch, scope ReadCallBack read)
{
    assert(watch !is null && read !is null);
    if(watch is null || read is null) return false;
    debug trace("new connection coming...");
    watch.clearError();
    SOCKET slisten = cast(SOCKET) watch.socket.handle;
    SOCKET slink = cast(SOCKET) watch._inSocket.handle;
    // void[] value = (&slisten)[0..1];
    // setsockopt(slink, SocketOptionLevel.SOCKET, 0x700B, value.ptr,
    //                    cast(uint) value.length);
    debug tracef("slisten=%s, slink=%s", slisten, slink);
    setsockopt(slink, SocketOptionLevel.SOCKET, 0x700B, cast(void*)&slisten, slisten.sizeof);
    if(read !is null)
        read(watch._inSocket);
        
    debug trace("accept next connection...");
    if(watch.active)
        watch.doAccept();
    return true;
}

bool readTimer(IOCPTimerWatcher watch, scope ReadCallBack read)
{
    if(watch is null) return false;
    watch.clearError();
    watch._readBuffer.data = 1;
    if(read)
        read(watch._readBuffer);
    return false;
}

bool readUdp(IOCPUDPWatcher watch, scope ReadCallBack read)
{
    if(watch is null || read is null) return false;
    watch.clearError();
    if(watch.readLen == 0) {
        read(null);
    } else {
        ubyte[] data  =  watch._readBuffer.data;
        watch._readBuffer.data = data[0..watch.readLen];
        watch._readBuffer.addr = watch.buildAddress();
        scope(exit) watch._readBuffer.data = data;
        read(watch._readBuffer);
        watch._readBuffer.data = data;
        if(watch.active)
            watch.doRead();
        
    }
    return false;
}


bool writeTcp(IOCPTCPWatcher watch,in ubyte[] data, out size_t writed)
{
    assert(watch !is null);
    if(watch is null) return false;
    watch.clearError();
    
    const size_t toWrite = watch.setWriteBuffer(data);
    if(toWrite == 0) 
        return true;
    writed = watch.doWrite();
    return false;
}

bool connectTCP(IOCPTCPWatcher watch, Address addr){
    if(watch is null || addr is null) return false;
    import kiss.exception;
    Address binded = createAddress(watch.socket,0);
    catchAndLogException(watch.socket.bind(binded));
    watch.doConnect(addr);
    return true;
}