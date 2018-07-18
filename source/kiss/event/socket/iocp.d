/*
 * Kiss - A refined core library for D programming language.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.cn
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module kiss.event.socket.iocp;

// dfmt off
version (Windows) : 

pragma(lib, "Ws2_32");
// dfmt on

import kiss.container.ByteBuffer;
import kiss.core;
import kiss.event.socket.common;
import kiss.event.core;
import kiss.util.thread;

import core.sys.windows.windows;
import core.sys.windows.winsock2;
import core.sys.windows.mswsock;

import std.format;
import std.conv;
import std.socket;
import std.exception;
import kiss.logger;

import std.process;

// import core.thread;

/**
TCP Server
*/
abstract class AbstractListener : AbstractSocketChannel // , IAcceptor
{
    this(Selector loop, AddressFamily family = AddressFamily.INET, size_t bufferSize = 4 * 1024)
    {
        super(loop, WatcherType.Accept);
        setFlag(WatchFlag.Read, true);
        _buffer = new ubyte[bufferSize];
        this.socket = new TcpSocket(family);
    }

    mixin CheckIocpError;

    protected void doAccept()
    {
        _iocp.watcher = this;
        _iocp.operation = IocpOperation.accept;
        _clientSocket = new Socket(_family, SocketType.STREAM, ProtocolType.TCP);
        DWORD dwBytesReceived = 0;

        version (KissDebugMode)
            tracef("client socket:accept=%s  inner socket=%s", this.handle,
                    _clientSocket.handle());
        version (KissDebugMode)
            trace("AcceptEx is :  ", AcceptEx);
        int nRet = AcceptEx(this.handle, cast(SOCKET) _clientSocket.handle,
                _buffer.ptr, 0, sockaddr_in.sizeof + 16, sockaddr_in.sizeof + 16,
                &dwBytesReceived, &_iocp.overlapped);

        version (KissDebugMode)
            trace("do AcceptEx : the return is : ", nRet);
        checkErro(nRet);
    }

    protected bool onAccept(scope AcceptHandler handler)
    {
        version (KissDebugMode)
            trace("new connection coming...");
        this.clearError();
        SOCKET slisten = cast(SOCKET) this.handle;
        SOCKET slink = cast(SOCKET) this._clientSocket.handle;
        // void[] value = (&slisten)[0..1];
        // setsockopt(slink, SocketOptionLevel.SOCKET, 0x700B, value.ptr,
        //                    cast(uint) value.length);
        version (KissDebugMode)
            tracef("slisten=%s, slink=%s", slisten, slink);
        setsockopt(slink, SocketOptionLevel.SOCKET, 0x700B, cast(void*)&slisten, slisten.sizeof);
        if (handler !is null)
            handler(this._clientSocket);

        version (KissDebugMode)
            trace("accept next connection...");
        if (this.isRegistered)
            this.doAccept();
        return true;
    }

    override void onClose()
    {
        // assert(false, "");
        // TODO: created by Administrator @ 2018-3-27 15:51:52
    }

    private IocpContext _iocp;
    private WSABUF _dataWriteBuffer;
    private ubyte[] _buffer;
    private Socket _clientSocket;
}

alias AcceptorBase = AbstractListener;

/**
TCP Client
*/
abstract class AbstractStream : AbstractSocketChannel, Stream
{
    DataReceivedHandler dataReceivedHandler;
    DataWrittenHandler sentHandler;

    this(Selector loop, AddressFamily family = AddressFamily.INET, size_t bufferSize = 4096 * 2)
    {
        super(loop, WatcherType.TCP);
        setFlag(WatchFlag.Read, true);
        setFlag(WatchFlag.Write, true);

        version (KissDebugMode)
            trace("Buffer size for read: ", bufferSize);
        _readBuffer = new ubyte[bufferSize];
        this.socket = new TcpSocket(family);
    }

    mixin CheckIocpError;

    override void onRead()
    {
        version (KissDebugMode)
            trace("ready to read");
        _inRead = false;
        super.onRead();
    }

    override void onWrite()
    {
        _inWrite = false;
        super.onWrite();
    }

    protected void beginRead()
    {
        _inRead = true;
        _dataReadBuffer.len = cast(uint) _readBuffer.length;
        _dataReadBuffer.buf = cast(char*) _readBuffer.ptr;
        _iocpread.watcher = this;
        _iocpread.operation = IocpOperation.read;
        DWORD dwReceived = 0;
        DWORD dwFlags = 0;

        version (KissDebugMode)
            tracef("receiving on thread(%d), handle=%d ", getTid(), this.socket.handle);

        int nRet = WSARecv(cast(SOCKET) this.socket.handle, &_dataReadBuffer, 1u, &dwReceived, &dwFlags,
                &_iocpread.overlapped, cast(LPWSAOVERLAPPED_COMPLETION_ROUTINE) null);

        checkErro(nRet, SOCKET_ERROR);
    }

    protected void doConnect(Address addr)
    {
        _iocpwrite.watcher = this;
        _iocpwrite.operation = IocpOperation.connect;
        int nRet = ConnectEx(cast(SOCKET) this.socket.handle(),
                cast(SOCKADDR*) addr.name(), addr.nameLen(), null, 0, null,
                &_iocpwrite.overlapped);
        checkErro(nRet, ERROR_IO_PENDING);
    }

    private uint doWrite()
    {
        _inWrite = true;
        DWORD dwFlags = 0;
        DWORD dwSent = 0;
        _iocpwrite.watcher = this;
        _iocpwrite.operation = IocpOperation.write;
        version (KissDebugMode)
        {
            trace("writing...handle=", this.socket.handle());
            trace("buffer content length: ", sendDataBuffer.length);
            // trace(cast(string) data);
            tracef("%(%02X %)", sendDataBuffer);
        }

        int nRet = WSASend(cast(SOCKET) this.socket.handle(), &_dataWriteBuffer, 1, &dwSent,
                dwFlags, &_iocpwrite.overlapped, cast(LPWSAOVERLAPPED_COMPLETION_ROUTINE) null);

        version (KissDebugMode)
        {
            if (dwSent != _dataWriteBuffer.len)
                warningf("dwSent=%d, BufferLength=%d", dwSent, _dataWriteBuffer.len);
        }
        // FIXME: Needing refactor or cleanup -@Administrator at 2018-5-9 16:28:55
        // The buffer may be full, so what can do here?
        // checkErro(nRet, SOCKET_ERROR); // bug:

        if (this.isError)
        {
            errorf("Socket error on write: fd=%d, message=%s", this.handle, this.erroString);
            this.close();
        }

        return dwSent;
    }

    protected void doRead()
    {
        this.clearError();
        version (KissDebugMode)
            tracef("data reading...%d nbytes", this.readLen);

        if (readLen > 0)
        {
            // import std.stdio;
            // writefln("length=%d, data: %(%02X %)", readLen, _readBuffer[0 .. readLen]);

            if (dataReceivedHandler !is null)
                dataReceivedHandler(this._readBuffer[0 .. readLen]);
            version (KissDebugMode)
                tracef("done with data reading...%d nbytes", this.readLen);

            // continue reading
            this.beginRead();
        }
        else if (readLen == 0)
        {
            version (KissDebugMode)
            {
                if (_remoteAddress !is null)
                    warningf("connection broken: %s", _remoteAddress.toString());
            }
            onDisconnected();
            if (_isClosed)
                this.socket.close(); // release the sources
            else
                this.close();
        }
        else
        {
            version (KissDebugMode)
            {
                warningf("undefined behavior on thread %d", getTid());
            }
            else
            {
                this._error = true;
                this._erroString = "undefined behavior on thread";
            }
        }
    }

    // private ThreadID lastThreadID;

    /// 
    // TODO: created by Administrator @ 2018-4-18 10:15:20
    // Send a big block of data
    protected size_t tryWrite(in ubyte[] data)
    {
        if (_isWritting)
        {
            warning("Busy in writting on thread: ", thisThreadID());
            return 0;
        }
        version (KissDebugMode)
            trace("start to write");
        _isWritting = true;

        clearError();
        setWriteBuffer(data);
        size_t nBytes = doWrite();

        return nBytes;
    }

    protected void tryWrite()
    {
        if (_isWritting)
        {
            version (KissDebugMode)
                warning("Busy in writting on thread: ", thisThreadID());
            return;
        }

        if (_writeQueue.empty)
            return;

        version (KissDebugMode)
            trace("start to write");
        _isWritting = true;

        clearError();

        writeBuffer = _writeQueue.front();
        const(ubyte)[] data = writeBuffer.sendData();
        setWriteBuffer(data);
        size_t nBytes = doWrite();

        if(nBytes < data.length) // to fix the corrupted data 
            sendDataBuffer = data.dup;
    }

    private bool _isWritting = false;

    private void setWriteBuffer(in ubyte[] data)
    {
        version (KissDebugMode)
        trace("buffer content length: ", data.length);
        // trace(cast(string) data);
        // tracef("%(%02X %)", data);

        sendDataBuffer = data; //data[writeLen .. $]; // TODO: need more tests
        _dataWriteBuffer.buf = cast(char*) sendDataBuffer.ptr;
        _dataWriteBuffer.len = cast(uint) sendDataBuffer.length;
    }

    /**
     * Called by selector after data sent
     * Note: It's only for IOCP selector: 
    */
    void onWriteDone(size_t nBytes)
    {
        version (KissDebugMode)
            tracef("finishing data writing, thread: %d,  nbytes: %d) ", thisThreadID(), nBytes);
        if (isWriteCancelling)
        {
            _isWritting = false;
            isWriteCancelling = false;
            _writeQueue.clear(); // clean the data buffer 
            return;
        }

        if (writeBuffer.popSize(nBytes))
        {
            if (_writeQueue.deQueue() is null)
                warning("_writeQueue is empty!");

            writeBuffer.doFinish();
            _isWritting = false;

            version (KissDebugMode)
                tracef("done with data writing, thread: %d,  nbytes: %d) ", thisThreadID(), nBytes);

            tryWrite();
        }
        else // if (sendDataBuffer.length > nBytes) 
        {
            version (KissDebugMode)
                tracef("remaining nbytes: %d", sendDataBuffer.length - nBytes);
            // FIXME: Needing refactor or cleanup -@Administrator at 2018-6-12 13:56:17
            // sendDataBuffer corrupted
            // const(ubyte)[] data = writeBuffer.sendData();
            // tracef("%(%02X %)", data);
            // tracef("%(%02X %)", sendDataBuffer);
            setWriteBuffer(sendDataBuffer[nBytes .. $]); // send remaining
            nBytes = doWrite();
        }
    }

    void cancelWrite()
    {
        isWriteCancelling = true;
    }

    protected void onDisconnected()
    {
        _isConnected = false;
        _isClosed = true;
        if (disconnectionHandler !is null)
            disconnectionHandler();
    }

    bool _isConnected; //if server side always true.
    SimpleEventHandler disconnectionHandler;

    protected WriteBufferQueue _writeQueue;
    protected bool isWriteCancelling = false;
    private const(ubyte)[] _readBuffer;
    private const(ubyte)[] sendDataBuffer;
    private StreamWriteBuffer writeBuffer;

    private IocpContext _iocpread;
    private IocpContext _iocpwrite;

    private WSABUF _dataReadBuffer;
    private WSABUF _dataWriteBuffer;

    private bool _inWrite;
    private bool _inRead;
}

/**
UDP Socket
*/
abstract class AbstractDatagramSocket : AbstractSocketChannel, IDatagramSocket
{
    /// Constructs a blocking IPv4 UDP Socket.
    this(Selector loop, AddressFamily family = AddressFamily.INET)
    {
        super(loop, WatcherType.UDP);
        setFlag(WatchFlag.Read, true);
        setFlag(WatchFlag.ETMode, false);

        this.socket = new UdpSocket(family);
        _readBuffer = new UdpDataObject();
        _readBuffer.data = new ubyte[4096 * 2];

        if (family == AddressFamily.INET)
            _bindAddress = new InternetAddress(InternetAddress.PORT_ANY);
        else if (family == AddressFamily.INET6)
            _bindAddress = new Internet6Address(Internet6Address.PORT_ANY);
        else
            _bindAddress = new UnknownAddress();
    }

    final void bind(Address addr)
    {
        if (_binded)
            return;
        _bindAddress = addr;
        socket.bind(_bindAddress);
        _binded = true;
    }

    final bool isBind()
    {
        return _binded;
    }

    Address bindAddr()
    {
        return _bindAddress;
    }

    override void start()
    {
        if (!_binded)
        {
            socket.bind(_bindAddress);
            _binded = true;
        }
    }

    // abstract void doRead();

    private UdpDataObject _readBuffer;
    protected bool _binded = false;
    protected Address _bindAddress;

    version (Windows)
    {
        mixin CheckIocpError;

        void doRead()
        {
            version (KissDebugMode)
                trace("Receiving......");

            _dataReadBuffer.len = cast(uint) _readBuffer.data.length;
            _dataReadBuffer.buf = cast(char*) _readBuffer.data.ptr;
            _iocpread.watcher = this;
            _iocpread.operation = IocpOperation.read;
            remoteAddrLen = cast(int) bindAddr().nameLen();

            DWORD dwReceived = 0;
            DWORD dwFlags = 0;

            int nRet = WSARecvFrom(cast(SOCKET) this.handle, &_dataReadBuffer,
                    cast(uint) 1, &dwReceived, &dwFlags, cast(SOCKADDR*)&remoteAddr, &remoteAddrLen,
                    &_iocpread.overlapped, cast(LPWSAOVERLAPPED_COMPLETION_ROUTINE) null);
            checkErro(nRet, SOCKET_ERROR);
        }

        Address buildAddress()
        {
            Address tmpaddr;
            if (remoteAddrLen == 32)
            {
                sockaddr_in* addr = cast(sockaddr_in*)(&remoteAddr);
                tmpaddr = new InternetAddress(*addr);
            }
            else
            {
                sockaddr_in6* addr = cast(sockaddr_in6*)(&remoteAddr);
                tmpaddr = new Internet6Address(*addr);
            }
            return tmpaddr;
        }

        bool tryRead(scope ReadCallBack read)
        {
            this.clearError();
            if (this.readLen == 0)
            {
                read(null);
            }
            else
            {
                ubyte[] data = this._readBuffer.data;
                this._readBuffer.data = data[0 .. this.readLen];
                this._readBuffer.addr = this.buildAddress();
                scope (exit)
                    this._readBuffer.data = data;
                read(this._readBuffer);
                this._readBuffer.data = data;
                if (this.isRegistered)
                    this.doRead();
            }
            return false;
        }

        IocpContext _iocpread;
        WSABUF _dataReadBuffer;

        sockaddr remoteAddr;
        int remoteAddrLen;
    }

}

/**
*/
mixin template CheckIocpError()
{
    void checkErro(int ret, int erro = 0)
    {
        DWORD dwLastError = GetLastError();
        if (ret != 0 || dwLastError == 0)
            return;

        version (KissDebugMode)
            tracef("erro=%d, dwLastError=%d", erro, dwLastError);

        if (ERROR_IO_PENDING != dwLastError)
        {
            this._error = true;
            this._erroString = format("AcceptEx failed with error: code=%s", dwLastError);
        }
    }
}

enum IocpOperation
{
    accept,
    connect,
    read,
    write,
    event,
    close
}

struct IocpContext
{
    OVERLAPPED overlapped;
    IocpOperation operation;
    AbstractChannel watcher = null;
}

alias WSAOVERLAPPED = OVERLAPPED;
alias LPWSAOVERLAPPED = OVERLAPPED*;

__gshared static LPFN_ACCEPTEX AcceptEx;
__gshared static LPFN_CONNECTEX ConnectEx;
/*__gshared LPFN_DISCONNECTEX DisconnectEx;
__gshared LPFN_GETACCEPTEXSOCKADDRS GetAcceptexSockAddrs;
__gshared LPFN_TRANSMITFILE TransmitFile;
__gshared LPFN_TRANSMITPACKETS TransmitPackets;
__gshared LPFN_WSARECVMSG WSARecvMsg;
__gshared LPFN_WSASENDMSG WSASendMsg;*/

shared static this()
{
    WSADATA wsaData;
    int iResult = WSAStartup(MAKEWORD(2, 2), &wsaData);

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

shared static ~this()
{
    WSACleanup();
}

private
{
    bool GetFunctionPointer(FuncPointer)(SOCKET sock, ref FuncPointer pfn, ref GUID guid)
    {
        DWORD dwBytesReturned = 0;
        if (WSAIoctl(sock, SIO_GET_EXTENSION_FUNCTION_POINTER, &guid, guid.sizeof,
                &pfn, pfn.sizeof, &dwBytesReturned, null, null) == SOCKET_ERROR)
        {
            error("Get function failed with error:", GetLastError());
            return false;
        }

        return true;
    }

    string GET_FUNC_POINTER(string GuidValue, string pft)
    {
        string str = " guid = " ~ GuidValue ~ ";";
        str ~= "if( !GetFunctionPointer( ListenSocket, " ~ pft
            ~ ", guid ) ) { errnoEnforce(false,\"get function error!\"); } ";
        return str;
    }
}

enum : DWORD
{
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

template _WSAIO(int x, int y)
{
    enum _WSAIO = IOC_VOID | x | y;
}

template _WSAIOR(int x, int y)
{
    enum _WSAIOR = IOC_OUT | x | y;
}

template _WSAIOW(int x, int y)
{
    enum _WSAIOW = IOC_IN | x | y;
}

template _WSAIORW(int x, int y)
{
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

extern (Windows):
nothrow:
int WSARecv(SOCKET, LPWSABUF, DWORD, LPDWORD, LPDWORD, LPWSAOVERLAPPED,
        LPWSAOVERLAPPED_COMPLETION_ROUTINE);
int WSARecvDisconnect(SOCKET, LPWSABUF);
int WSARecvFrom(SOCKET, LPWSABUF, DWORD, LPDWORD, LPDWORD, SOCKADDR*, LPINT,
        LPWSAOVERLAPPED, LPWSAOVERLAPPED_COMPLETION_ROUTINE);

int WSASend(SOCKET, LPWSABUF, DWORD, LPDWORD, DWORD, LPWSAOVERLAPPED,
        LPWSAOVERLAPPED_COMPLETION_ROUTINE);
int WSASendDisconnect(SOCKET, LPWSABUF);
int WSASendTo(SOCKET, LPWSABUF, DWORD, LPDWORD, DWORD, const(SOCKADDR)*, int,
        LPWSAOVERLAPPED, LPWSAOVERLAPPED_COMPLETION_ROUTINE);
