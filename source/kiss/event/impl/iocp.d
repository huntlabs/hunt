module kiss.event.impl.iocp;

import kiss.event.base;
import kiss.event.struct_;
import kiss.event.watcher;
import kiss.event.impl.iocp_reader;
import kiss.event.impl.iocp_watcher;
import kiss.event.impl.CustomTimer;
version(Windows):
class IOCPLoop : BaseLoop
{
    this(){
        _IOCPFD = CreateIoCompletionPort(INVALID_HANDLE_VALUE, null, 0, 1);
        _event = new IOCPEventWatcher();
        register(_event);
        _timer.init();
    }

    ~this(){
        // .close(_IOCPFD);
    }

    override Watcher createWatcher(WatcherType type)
    {
        Watcher returnValue;
        switch (type) with(WatcherType)
        {
        case TCP:
            returnValue = new IOCPTCPWatcher();
            break;
        case UDP:
            returnValue = new IOCPUDPWatcher();
            break;
        case ACCEPT:
            returnValue = new IOCPAcceptWatcher();
            break;
        case Event:
            returnValue = new IOCPEventWatcher();
            break;
        case Timer:
            returnValue = new IOCPTimerWatcher();
            break;
        default:
            break;
        }
        return returnValue;
    }

    override bool read(Watcher watcher,scope ReadCallBack read)
    {
        bool canRead ;
        switch(watcher.type){
            case WatcherType.ACCEPT:
                canRead = readAccept(cast(IOCPAcceptWatcher)watcher, read);
            break;
            case WatcherType.TCP:
                canRead = readTcp(cast(IOCPTCPWatcher)watcher,read);
            break;
            case WatcherType.UDP:
                canRead = readUdp(cast(IOCPUDPWatcher)watcher,read);
            break;
            case WatcherType.Timer:
                canRead = readTimer(cast(IOCPTimerWatcher)watcher,read);
            break;
            default:
            break;
        }
        return canRead;
    }

    override bool connect(Watcher watcher,Address addr)
    {
        if(watcher.type == WatcherType.TCP){
            return connectTCP(cast(IOCPTCPWatcher)watcher,addr);
        }
        return false;
    }

    override bool write(Watcher watcher,in ubyte[] data, out size_t writed)
    {
        if(watcher.type == WatcherType.TCP){
            return writeTcp(cast(IOCPTCPWatcher)watcher,data,writed);
        }
        writed = 0;
        return false;
    }

    override bool close(Watcher watcher)
    {
        deregister(watcher);
        if(watcher.type == WatcherType.TCP){
            TcpStreamWatcher wt = cast(TcpStreamWatcher)watcher;
            // Linger optLinger;
            // optLinger.on = 1;
            // optLinger.time = 0;
            // wt.socket.setOption(SocketOptionLevel.SOCKET, SocketOption.LINGER, optLinger);
            wt.socket.close();
        } else if(watcher.type == WatcherType.ACCEPT){
            IOCPAcceptWatcher wt = cast(IOCPAcceptWatcher)watcher;
            wt.socket.close();
        }else if(watcher.type == WatcherType.UDP) {
            UdpStreamWatcher wt = cast(UdpStreamWatcher)watcher;
            wt.socket.close();
        }
        return true;
    }

    override bool register(Watcher watcher)
    {
         if(watcher is null || watcher.active) return false;
        if (watcher.type == WatcherType.Timer) {
            IOCPTimerWatcher wt = cast(IOCPTimerWatcher)watcher;
            if(wt is  null || !wt._timer.setTimerOut) return false;
            _timer.timeWheel().addNewTimer(wt._timer,wt._timer.wheelSize());
        } else if(watcher.type ==  WatcherType.Event){
            IOCPEventWatcher wt = cast(IOCPEventWatcher)watcher;
            if(wt is  null) return false;
            wt._iocp = this._IOCPFD;
        } else if(watcher.type == WatcherType.UDP){
            IOCPUDPWatcher wt = cast(IOCPUDPWatcher)watcher;
            if(wt is  null) return false;
            if(!wt.isBind)
                wt.bind(createAddress(wt.socket,0));
        }
        watcher.currtLoop = this;
        _event.setNext(watcher);
        return true;
    }

    override bool reregister(Watcher watcher)
    {
        throw new LoopException("The IOCP does not support reregister!");
        //return false;
    }

    override bool deregister(Watcher watcher)
    {
        if(watcher is null || watcher.currtLoop !is this) return false;
        if (watcher.type == WatcherType.Timer) {
           IOCPTimerWatcher wt = cast(IOCPTimerWatcher)watcher;
            if(wt){
                wt._timer.stop();
            }
        }
        watcher.currtLoop = null;
        watcher.clear();
        return true;
    }

    override bool weakUp(){
        _event.call();
        return true;
    }

    // while(true)
    override void join(scope void delegate()nothrow weak)
    {
        _runing = true;
        _timer.init();
        do{
            weak();
            auto timeout = _timer.doWheel();
            OVERLAPPED * overlapped;
            ULONG_PTR key = 0;
            DWORD bytes = 0;
            const int ret = GetQueuedCompletionStatus(_IOCPFD,  & bytes,  & key,  &overlapped,timeout);
            if(overlapped !is null) continue;
            if(ret == 0){
                const auto erro = GetLastError();
                if (erro == WAIT_TIMEOUT){
                    continue;
                }
                auto ev = cast(IOCP_DATA * ) overlapped;
                if (ev && ev.watcher) {
                    ev.watcher.onClose();
                }
                continue;
            }
            auto ev = cast(IOCP_DATA * ) overlapped;
            if(ev is null || ev.watcher is null) continue;
            final switch (ev.operationType) {
            case IOCP_OP_TYPE.accept : 
                    ev.watcher.onRead();
                break;
            case IOCP_OP_TYPE.connect : 
                 setStreamRead(ev.watcher,0);
                break;
            case IOCP_OP_TYPE.read : 
                    setStreamRead(ev.watcher,bytes);
                break;
            case IOCP_OP_TYPE.write : 
                    setStreamWrite(ev.watcher,bytes);
                break;
            case IOCP_OP_TYPE.event : 
                    ev.watcher.onRead();
                break;
            }
            
        } while(_runing);
    }

    override void stop()
    {
        _runing = false;
        weakUp();
    }

    void handleTimer(){

    }

    void setStreamRead(Watcher wt, size_t len){
        auto io = cast(IOCPStream)wt;
        if(io is null) return;
        io.setRead(len);
        wt.onRead();
    }

    void setStreamWrite(Watcher wt, size_t len){
        auto io = cast(IOCPStream)wt;
        if(io is null) return;
        io.setWrite(len);
        wt.onWrite();
    }

private:
    bool _runing;
    HANDLE _IOCPFD;
    IOCPEventWatcher _event;
    CustomTimer _timer;
}