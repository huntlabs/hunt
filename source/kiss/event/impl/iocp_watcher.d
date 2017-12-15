module kiss.event.impl.iocp_watcher;

import kiss.event.base;
import kiss.event.struct_;
import kiss.event.watcher;
import kiss.event.impl.CustomTimer;
version(Windows):
pragma(lib, "Ws2_32");

public import core.sys.windows.windows;
public import core.sys.windows.winsock2;
public import core.sys.windows.mswsock;

import std.conv;
import std.socket;
import std.exception;
import std.experimental.logger;

mixin template CheckIocpError()
{
    void checkErro(int ret, int erro = 0){
        import std.format;
        if (ret != 0) return; 
        DWORD dwLastError = GetLastError();
        if (ERROR_IO_PENDING != dwLastError) {
            this._error = true;
            this._erroString = format("AcceptEx failed with error: %s", dwLastError);
        }
    }
}

interface IOCPStream
{
    void setRead(size_t bytes);
    void setWrite(size_t bytes);
}

final class IOCPTCPWatcher : TcpStreamWatcher,IOCPStream
{
    this()
    {
        super();
        setFlag(WatchFlag.Read,true);
        setFlag(WatchFlag.Write,true);
    }
   
    mixin OverrideErro;
    mixin CheckIocpError;

    override void onRead(){
        _inRead = false;
        super.onRead();
    }

    override void onWrite(){
        _inWrite = false;
        super.onWrite();
    }

    void doRead(){
        _inRead = true;
        _iocpBuffer.len = cast(uint) _readBuffer.data.length;
        _iocpBuffer.buf = cast(char*) _readBuffer.data.ptr;
        _iocpread.watcher = this;
        _iocpread.operationType = IOCP_OP_TYPE.read;
        DWORD dwReceived = 0;
        DWORD dwFlags = 0;
        int nRet = WSARecv(cast(SOCKET) this.socket.handle, &_iocpBuffer,
                cast(uint) 1, &dwReceived, &dwFlags, &_iocpread.ol,
                cast(LPWSAOVERLAPPED_COMPLETION_ROUTINE) null);
        checkErro(nRet, SOCKET_ERROR);
    }

    size_t setWriteBuffer(in ubyte[] data) {
        if(data.length == writeLen)
            return 0;
        auto writeData = data[writeLen..$];
        _iocpWBuf.buf = cast(char *)writeData.ptr;
        _iocpWBuf.len = cast(uint)writeData.length;
        return writeData.length;
    }

    void doWrite(){
        _inWrite = true;
        DWORD dwFlags = 0;
        DWORD dwSent = 0;
        _iocpread.watcher = this;
        _iocpwrite.operationType = IOCP_OP_TYPE.write;
        int nRet = WSASend(cast(SOCKET)this.socket.handle(), &_iocpWBuf, 1,
                &dwSent, dwFlags, &_iocpwrite.ol, cast(LPWSAOVERLAPPED_COMPLETION_ROUTINE) null);
        checkErro(nRet, SOCKET_ERROR);
    }

    override void setRead(size_t bytes)
    {
        readLen = bytes;
    }

    override void setWrite(size_t bytes)
    {
        writeLen = bytes;
    }

    IOCP_DATA _iocpread;
    IOCP_DATA _iocpwrite;

    WSABUF _iocpBuffer;
    WSABUF _iocpWBuf;
    
    size_t readLen;
    size_t writeLen;

    bool _inWrite;
    bool _inRead;
}

final class IOCPUDPWatcher : UdpStreamWatcher,IOCPStream
{
    this()
    {
        super();
        setFlag(WatchFlag.Read,true);
        setFlag(WatchFlag.ETMode,false);
    }

    mixin OverrideErro;
    mixin CheckIocpError;

    void doRead() {
        _iocpBuffer.len = cast(uint)_readBuffer.data.length;
        _iocpBuffer.buf = cast(char*)_readBuffer.data.ptr;
        _iocpread.watcher = this;
        _iocpread.operationType = IOCP_OP_TYPE.read;
        remoteAddrLen = cast(int) bindAddr().nameLen();

        DWORD dwReceived = 0;
        DWORD dwFlags = 0;

        int nRet = WSARecvFrom(cast(SOCKET) socket().handle, &_iocpBuffer,
            cast(uint) 1, &dwReceived, &dwFlags,
            cast(SOCKADDR*)&remoteAddr, &remoteAddrLen, &_iocpread.ol,
            cast(LPWSAOVERLAPPED_COMPLETION_ROUTINE) null);
        checkErro(nRet, SOCKET_ERROR);
    }

    Address buildAddress(){
        Address tmpaddr;
        if (remoteAddrLen == 32) {
            sockaddr_in* addr = cast(sockaddr_in*)(&remoteAddr);
            tmpaddr = new InternetAddress(*addr);
        } else {
            sockaddr_in6* addr = cast(sockaddr_in6*)(&remoteAddr);
            tmpaddr = new Internet6Address(*addr);
        }
        return tmpaddr;
    }

    IOCP_DATA _iocpread;
    WSABUF _iocpBuffer;

    sockaddr remoteAddr; //存储数据来源IP地址
    int remoteAddrLen; //存储数据来源IP地址长度

    override void setRead(size_t bytes)
    {
        readLen = bytes;
    }

    override void setWrite(size_t bytes)
    {
    }

    size_t readLen;

    Address bindAddr(){
        if(_bindAddress is null)
            _bindAddress = socket().localAddress();
        return _bindAddress;
    }
private:
    Address _bindAddress;
}

final class IOCPAcceptWatcher : TcpListenerWatcher
{
    this()
    {
        super();
        setFlag(WatchFlag.Read,true);
        _buffer = new ubyte[4096];
    }

    mixin OverrideErro;
    mixin CheckIocpError;

    void doAccept(){
        _iocp.watcher = this;
        _iocp.operationType = IOCP_OP_TYPE.accept;
        _inSocket = new Socket(this.socket.addressFamily,
                        SocketType.STREAM, ProtocolType.TCP);
        DWORD dwBytesReceived = 0;
        int nRet = AcceptEx(this.socket.handle,
                    cast(SOCKET) _inSocket.handle, _buffer.ptr, 0,
                    sockaddr_in.sizeof + 16, sockaddr_in.sizeof + 16,
                    &dwBytesReceived, &_iocp.ol);
        checkErro(nRet);
    }

    IOCP_DATA _iocp;
    WSABUF _iocpWBuf;

    ubyte[] _buffer;
    Socket _inSocket;

    uint _addreslen;
}


final class IOCPEventWatcher : EventWatcher 
{
    this()
    {
        setFlag(WatchFlag.Read,true);
    }

    ~this(){
    }


    override void call(){
        if(active){
            _data.watcher = this;
            _data.operationType = IOCP_OP_TYPE.event;
            ()@trusted{PostQueuedCompletionStatus(_iocp, 0, 0, &_data.ol);}();
        }
    }

    override void onRead(){
        
    }

    mixin OverrideErro;

    IOCP_DATA _data;
    HANDLE _iocp;
}

final class IOCPTimerWatcher : TimerWatcher
{
    this()
    {
        super();
        setFlag(WatchFlag.Read,true);
        _timer = new CWheelTimer(this);
    }

    ~this(){
    }

    CWheelTimer _timer;
    mixin OverrideErro;

    UintObject _readBuffer;
}

enum IOCP_OP_TYPE {
    accept,
    connect,
    read,
    write,
    event
}

alias  WSAOVERLAPPED = OVERLAPPED;
alias  LPWSAOVERLAPPED = OVERLAPPED *;

struct IOCP_DATA {
    OVERLAPPED ol;
    IOCP_OP_TYPE operationType;
    Watcher watcher;
}

__gshared static LPFN_ACCEPTEX AcceptEx;
__gshared static LPFN_CONNECTEX ConnectEx;
/*__gshared LPFN_DISCONNECTEX DisconnectEx;
__gshared LPFN_GETACCEPTEXSOCKADDRS GetAcceptexSockAddrs;
__gshared LPFN_TRANSMITFILE TransmitFile;
__gshared LPFN_TRANSMITPACKETS TransmitPackets;
__gshared LPFN_WSARECVMSG WSARecvMsg;
__gshared LPFN_WSASENDMSG WSASendMsg;*/

shared static this() {
    WSADATA wsaData;
    int iResult = WSAStartup(MAKEWORD(2, 2),  & wsaData);

    SOCKET ListenSocket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    scope (exit)
        closesocket(ListenSocket);
    GUID guid;
    mixin(GET_FUNC_POINTER("WSAID_ACCEPTEX", "AcceptEx"));
    mixin(GET_FUNC_POINTER("WSAID_CONNECTEX", "ConnectEx"));
    /* mixin(GET_FUNC_POINTER("WSAID_DISCONNECTEX", "DisconnectEx"));
     mixin(GET_FUNC_POINTER("WSAID_GETACCEPTEXSOCKADDRS", "GetAcceptexSockAddrs"));
     mixin(GET_FUNC_POINTER("WSAID_TRANSMITFILE", "TransmitFile"));
     mixin(GET_FUNC_POINTER("WSAID_TRANSMITPACKETS", "TransmitPackets"));
     mixin(GET_FUNC_POINTER("WSAID_WSARECVMSG", "WSARecvMsg"));*/
}

shared static ~this() {
    WSACleanup();
}

private {
    bool GetFunctionPointer(FuncPointer)(SOCKET sock, ref FuncPointer pfn, ref GUID guid) {
        DWORD dwBytesReturned = 0;
        if (WSAIoctl(sock, SIO_GET_EXTENSION_FUNCTION_POINTER,  & guid,
                guid.sizeof,  & pfn, pfn.sizeof,  & dwBytesReturned, null, null) == SOCKET_ERROR) {
            error("Get function failed with error:", GetLastError());
            return false;
        }

        return true;
    }

    string GET_FUNC_POINTER(string GuidValue, string pft) {
        string str = " guid = " ~ GuidValue ~ ";";
        str ~= "if( !GetFunctionPointer( ListenSocket, " ~ pft ~ ", guid ) ) { errnoEnforce(false,\"iocp get function error!\"); } ";
        return str;
    }
}

struct WSABUF {
    uint len;
    char * buf;
}

alias WSABUF * LPWSABUF;

enum : DWORD {
    IOCPARAM_MASK = 0x7f,
    IOC_VOID = 0x20000000,
    IOC_OUT = 0x40000000,
    IOC_IN = 0x80000000,
    IOC_INOUT = IOC_IN | IOC_OUT
}

enum IOC_UNIX = 0x00000000;
enum IOC_WS2 = 0x08000000;
enum IOC_PROTOCOL = 0x10000000;
enum IOC_VENDOR = 0x18000000;

template _WSAIO(int x, int y) {
    enum _WSAIO = IOC_VOID | x | y;
}
template _WSAIOR(int x, int y) {
    enum _WSAIOR = IOC_OUT | x | y;
}
template _WSAIOW(int x, int y) {
    enum _WSAIOW = IOC_IN | x | y;
}
template _WSAIORW(int x, int y) {
    enum _WSAIORW = IOC_INOUT | x | y;
}

enum SIO_ASSOCIATE_HANDLE = _WSAIOW!(IOC_WS2, 1);
enum SIO_ENABLE_CIRCULAR_QUEUEING = _WSAIO!(IOC_WS2, 2);
enum SIO_FIND_ROUTE = _WSAIOR!(IOC_WS2, 3);
enum SIO_FLUSH = _WSAIO!(IOC_WS2, 4);
enum SIO_GET_BROADCAST_ADDRESS = _WSAIOR!(IOC_WS2, 5);
enum SIO_GET_EXTENSION_FUNCTION_POINTER = _WSAIORW!(IOC_WS2, 6);
enum SIO_GET_QOS = _WSAIORW!(IOC_WS2, 7);
enum SIO_GET_GROUP_QOS = _WSAIORW!(IOC_WS2, 8);
enum SIO_MULTIPOINT_LOOPBACK = _WSAIOW!(IOC_WS2, 9);
enum SIO_MULTICAST_SCOPE = _WSAIOW!(IOC_WS2, 10);
enum SIO_SET_QOS = _WSAIOW!(IOC_WS2, 11);
enum SIO_SET_GROUP_QOS = _WSAIOW!(IOC_WS2, 12);
enum SIO_TRANSLATE_HANDLE = _WSAIORW!(IOC_WS2, 13);
enum SIO_ROUTING_INTERFACE_QUERY = _WSAIORW!(IOC_WS2, 20);
enum SIO_ROUTING_INTERFACE_CHANGE = _WSAIOW!(IOC_WS2, 21);
enum SIO_ADDRESS_LIST_QUERY = _WSAIOR!(IOC_WS2, 22);
enum SIO_ADDRESS_LIST_CHANGE = _WSAIO!(IOC_WS2, 23);
enum SIO_QUERY_TARGET_PNP_HANDLE = _WSAIOR!(IOC_WS2, 24);
enum SIO_NSP_NOTIFY_CHANGE = _WSAIOW!(IOC_WS2, 25);

extern (Windows) : nothrow : int WSARecv(SOCKET, LPWSABUF, DWORD, LPDWORD,
    LPDWORD, LPWSAOVERLAPPED, LPWSAOVERLAPPED_COMPLETION_ROUTINE);
int WSARecvDisconnect(SOCKET, LPWSABUF);
int WSARecvFrom(SOCKET, LPWSABUF, DWORD, LPDWORD, LPDWORD, SOCKADDR * , LPINT,
    LPWSAOVERLAPPED, LPWSAOVERLAPPED_COMPLETION_ROUTINE);

int WSASend(SOCKET, LPWSABUF, DWORD, LPDWORD, DWORD, LPWSAOVERLAPPED,
    LPWSAOVERLAPPED_COMPLETION_ROUTINE);
int WSASendDisconnect(SOCKET, LPWSABUF);
int WSASendTo(SOCKET, LPWSABUF, DWORD, LPDWORD, DWORD, const(SOCKADDR) * , int,
    LPWSAOVERLAPPED, LPWSAOVERLAPPED_COMPLETION_ROUTINE);
