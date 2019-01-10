/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2018-2019 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.io.socket.IOCP;

// dfmt off
version (Windows) : 

pragma(lib, "Ws2_32");
// dfmt on

import hunt.collection.ByteBuffer;
import hunt.io.socket.common;
import hunt.io.socket.Common;
import hunt.logging;
import hunt.Exceptions;
import hunt.concurrency.thread.Helper;

import core.sys.windows.windows;
import core.sys.windows.winsock2;
import core.sys.windows.mswsock;

import std.conv;
import std.exception;
import std.format;
import std.process;
import std.socket;
import std.stdio;

/**
TCP Server
*/
abstract class AbstractListener : AbstractSocketChannel {
    this(Selector loop, AddressFamily family = AddressFamily.INET, size_t bufferSize = 4 * 1024) {
        super(loop, ChannelType.Accept);
        setFlag(ChannelFlag.Read, true);
        _buffer = new ubyte[bufferSize];
        this.socket = new TcpSocket(family);

        loadWinsockExtension(this.handle);
    }

    mixin CheckIocpError;

    protected void doAccept() {
        _iocp.channel = this;
        _iocp.operation = IocpOperation.accept;
        _clientSocket = new Socket(this.localAddress.addressFamily,
                SocketType.STREAM, ProtocolType.TCP);
        DWORD dwBytesReceived = 0;

        version (HUNT_DEBUG) {
            tracef("client socket: acceptor=%s  inner socket=%s", this.handle,
                    _clientSocket.handle());
            // info("AcceptEx@", AcceptEx);
        }
        uint sockaddrSize = cast(uint) sockaddr_storage.sizeof;
        // https://docs.microsoft.com/en-us/windows/desktop/api/mswsock/nf-mswsock-acceptex
        BOOL ret = AcceptEx(this.handle, cast(SOCKET) _clientSocket.handle, _buffer.ptr,
                0, sockaddrSize + 16, sockaddrSize + 16, &dwBytesReceived, &_iocp.overlapped);
        version (HUNT_DEBUG)
            trace("AcceptEx return: ", ret);
        checkErro(ret, FALSE);
    }

    protected bool onAccept(scope AcceptHandler handler) {
        version (HUNT_DEBUG)
            trace("a new connection coming...");
        this.clearError();
        SOCKET slisten = cast(SOCKET) this.handle;
        SOCKET slink = cast(SOCKET) this._clientSocket.handle;
        // void[] value = (&slisten)[0..1];
        // setsockopt(slink, SocketOptionLevel.SOCKET, 0x700B, value.ptr,
        //                    cast(uint) value.length);
        version (HUNT_DEBUG)
            tracef("slisten=%s, slink=%s", slisten, slink);
        setsockopt(slink, SocketOptionLevel.SOCKET, 0x700B, cast(void*)&slisten, slisten.sizeof);
        if (handler !is null)
            handler(this._clientSocket);

        version (HUNT_DEBUG)
            trace("accepting next connection...");
        if (this.isRegistered)
            this.doAccept();
        return true;
    }

    override void onClose() {
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
abstract class AbstractStream : AbstractSocketChannel, Stream {
    DataReceivedHandler dataReceivedHandler;
    DataWrittenHandler sentHandler;

    this(Selector loop, AddressFamily family = AddressFamily.INET, size_t bufferSize = 4096 * 2) {
        super(loop, ChannelType.TCP);
        setFlag(ChannelFlag.Read, true);
        setFlag(ChannelFlag.Write, true);

        version (HUNT_DEBUG)
            trace("Buffer size for read: ", bufferSize);
        _readBuffer = new ubyte[bufferSize];
        this.socket = new TcpSocket(family);
    }

    mixin CheckIocpError;

    override void onRead() {
        version (HUNT_DEBUG)
            trace("ready to read");
        _inRead = false;
        super.onRead();
    }

    override void onWrite() {
        _inWrite = false;
        super.onWrite();
    }

    protected void beginRead() {
        _inRead = true;
        _dataReadBuffer.len = cast(uint) _readBuffer.length;
        _dataReadBuffer.buf = cast(char*) _readBuffer.ptr;
        _iocpread.channel = this;
        _iocpread.operation = IocpOperation.read;
        DWORD dwReceived = 0;
        DWORD dwFlags = 0;

        version (HUNT_DEBUG)
            tracef("start receiving by handle[fd=%d] ", this.socket.handle);

        // https://docs.microsoft.com/en-us/windows/desktop/api/winsock2/nf-winsock2-wsarecv
        int nRet = WSARecv(cast(SOCKET) this.socket.handle, &_dataReadBuffer, 1u, &dwReceived, &dwFlags,
                &_iocpread.overlapped, cast(LPWSAOVERLAPPED_COMPLETION_ROUTINE) null);

        checkErro(nRet, SOCKET_ERROR);
    }

    protected void doConnect(Address addr) {
        _iocpwrite.channel = this;
        _iocpwrite.operation = IocpOperation.connect;
        int nRet = ConnectEx(cast(SOCKET) this.socket.handle(),
                cast(SOCKADDR*) addr.name(), addr.nameLen(), null, 0, null,
                &_iocpwrite.overlapped);
        checkErro(nRet, SOCKET_ERROR);
    }

    private uint doWrite() {
        _inWrite = true;
        DWORD dwFlags = 0;
        DWORD dwSent = 0;
        _iocpwrite.channel = this;
        _iocpwrite.operation = IocpOperation.write;
        version (HUNT_DEBUG) {
            size_t bufferLength = sendDataBuffer.length;
            tracef("To be written %d nbytes by handle[fd=%d]", bufferLength, this.socket.handle());
            // trace(cast(string) data);
            if (bufferLength > 32)
                tracef("%(%02X %) ...", sendDataBuffer[0 .. 32]);
            else
                tracef("%(%02X %)", sendDataBuffer[0 .. $]);
        }

        int nRet = WSASend(cast(SOCKET) this.socket.handle(), &_dataWriteBuffer, 1, &dwSent,
                dwFlags, &_iocpwrite.overlapped, cast(LPWSAOVERLAPPED_COMPLETION_ROUTINE) null);

        version (HUNT_DEBUG) {
            if (dwSent != _dataWriteBuffer.len)
                warningf("dwSent=%d, BufferLength=%d", dwSent, _dataWriteBuffer.len);
        }

        checkErro(nRet, SOCKET_ERROR);

        if (this.isError) {
            errorf("Socket error on write: fd=%d, message=%s", this.handle, this.erroString);
            this.close();
        }

        return dwSent;
    }

    protected void doRead() {
        this.clearError();
        version (HUNT_DEBUG)
            tracef("start reading: %d nbytes", this.readLen);

        if (readLen > 0) {
            // import std.stdio;
            // writefln("length=%d, data: %(%02X %)", readLen, _readBuffer[0 .. readLen]);

            if (dataReceivedHandler !is null)
                dataReceivedHandler(this._readBuffer[0 .. readLen]);
            version (HUNT_DEBUG)
                tracef("reading done: %d nbytes", this.readLen);

            // continue reading
            this.beginRead();
        } else if (readLen == 0) {
            version (HUNT_DEBUG) {
                if (_remoteAddress !is null)
                    warningf("connection broken: %s", _remoteAddress.toString());
            }
            onDisconnected();
            // if (_isClosed)
            //     this.close();
        } else {
            version (HUNT_DEBUG) {
                warningf("undefined behavior on thread %d", getTid());
            } else {
                this._error = true;
                this._erroString = "undefined behavior on thread";
            }
        }
    }

    // private ThreadID lastThreadID;

    /// 
    // TODO: created by Administrator @ 2018-4-18 10:15:20
    // Send a big block of data
    protected size_t tryWrite(const ubyte[] data) {
        if (_isWritting) {
            warning("Busy in writting on thread: ");
            return 0;
        }
        version (HUNT_DEBUG)
            trace("start to write");
        _isWritting = true;

        clearError();
        setWriteBuffer(data);
        size_t nBytes = doWrite();

        return nBytes;
    }

    protected void tryWrite() {
        if (_writeQueue.empty)
            return;

        version (HUNT_DEBUG)
            trace("start writting...");
        _isWritting = true;
        clearError();

        writeBuffer = _writeQueue.front();
        const(ubyte)[] data = writeBuffer.remaining();
        setWriteBuffer(data);
        size_t nBytes = doWrite();

        if (nBytes < data.length) { // to fix the corrupted data 
            version (HUNT_DEBUG)
                warningf("remaining data: %d / %d ", data.length - nBytes, data.length);
            sendDataBuffer = data.dup;
        }
    }

    private void setWriteBuffer(in ubyte[] data) {
        version (HUNT_DEBUG)
            tracef("data length: %d nbytes", data.length);
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
    package(hunt.event) void onWriteDone(size_t nBytes) {
        version (HUNT_DEBUG)
            tracef("finishing writting: %d bytes", nBytes);
        if (isWriteCancelling) {
            _isWritting = false;
            isWriteCancelling = false;
            _writeQueue.clear(); // clean the data buffer 
            return;
        }

        if (writeBuffer.pop(nBytes)) {
            if (_writeQueue.deQueue() is null) {
                version (HUNT_DEBUG)
                    warning("_writeQueue is empty!");
            }

            writeBuffer.finish();
            _isWritting = false;

            version (HUNT_DEBUG)
                tracef("writting done: %d bytes", nBytes);

            tryWrite();
        } else // if (sendDataBuffer.length > nBytes) 
        {
            // version (HUNT_DEBUG)
            tracef("remaining nbytes: %d", sendDataBuffer.length - nBytes);
            // FIXME: Needing refactor or cleanup -@Administrator at 2018-6-12 13:56:17
            // sendDataBuffer corrupted
            // const(ubyte)[] data = writeBuffer.remaining();
            // tracef("%(%02X %)", data);
            // tracef("%(%02X %)", sendDataBuffer);
            setWriteBuffer(sendDataBuffer[nBytes .. $]); // send remaining
            nBytes = doWrite();
        }
    }

    void cancelWrite() {
        isWriteCancelling = true;
    }

    protected void onDisconnected() {
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
abstract class AbstractDatagramSocket : AbstractSocketChannel {
    /// Constructs a blocking IPv4 UDP Socket.
    this(Selector loop, AddressFamily family = AddressFamily.INET) {
        super(loop, ChannelType.UDP);
        setFlag(ChannelFlag.Read, true);
        setFlag(ChannelFlag.ETMode, false);

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

    final void bind(Address addr) {
        if (_binded)
            return;
        _bindAddress = addr;
        socket.bind(_bindAddress);
        _binded = true;
    }

    final bool isBind() {
        return _binded;
    }

    Address bindAddr() {
        return _bindAddress;
    }

    override void start() {
        if (!_binded) {
            socket.bind(_bindAddress);
            _binded = true;
        }
    }

    // abstract void doRead();

    private UdpDataObject _readBuffer;
    protected bool _binded = false;
    protected Address _bindAddress;

    version (Windows) {
        mixin CheckIocpError;

        void doRead() {
            version (HUNT_DEBUG)
                trace("Receiving......");

            _dataReadBuffer.len = cast(uint) _readBuffer.data.length;
            _dataReadBuffer.buf = cast(char*) _readBuffer.data.ptr;
            _iocpread.channel = this;
            _iocpread.operation = IocpOperation.read;
            remoteAddrLen = cast(int) bindAddr().nameLen();

            DWORD dwReceived = 0;
            DWORD dwFlags = 0;

            int nRet = WSARecvFrom(cast(SOCKET) this.handle, &_dataReadBuffer,
                    cast(uint) 1, &dwReceived, &dwFlags, cast(SOCKADDR*)&remoteAddr, &remoteAddrLen,
                    &_iocpread.overlapped, cast(LPWSAOVERLAPPED_COMPLETION_ROUTINE) null);
            checkErro(nRet, SOCKET_ERROR);
        }

        Address buildAddress() {
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

        bool tryRead(scope ReadCallBack read) {
            this.clearError();
            if (this.readLen == 0) {
                read(null);
            } else {
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
mixin template CheckIocpError() {
    void checkErro(int ret, int erro = 0) {
        DWORD dwLastError = GetLastError();
        version (HUNT_DEBUG)
            infof("erro=%d, dwLastError=%d", erro, dwLastError);
        if (ret != erro || dwLastError == 0)
            return;

        if (ERROR_IO_PENDING != dwLastError) { // ERROR_IO_PENDING
            import hunt.system.Error;
            warningf("erro=%d, dwLastError=%d", erro, dwLastError);
            this._error = true;
            this._erroString = getErrorMessage(dwLastError); // format("IOCP error: code=%s", dwLastError);
        }
    }
}

enum IocpOperation {
    accept,
    connect,
    read,
    write,
    event,
    close
}

struct IocpContext {
    OVERLAPPED overlapped;
    IocpOperation operation;
    AbstractChannel channel = null;
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

shared static this() {
    WSADATA wsaData;
    int iResult = WSAStartup(MAKEWORD(2, 2), &wsaData);
    if (iResult != 0) {
        stderr.writeln("unable to load Winsock!");
    }
}

shared static ~this() {
    WSACleanup();
}

void loadWinsockExtension(SOCKET socket) {
    if (isApiLoaded)
        return;
    isApiLoaded = true;

    // SOCKET ListenSocket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    // scope (exit)
    //     closesocket(ListenSocket);
    GUID guid;
    mixin(GET_FUNC_POINTER("WSAID_ACCEPTEX", "AcceptEx", socket.stringof));
    mixin(GET_FUNC_POINTER("WSAID_CONNECTEX", "ConnectEx"));
    /* mixin(GET_FUNC_POINTER("WSAID_DISCONNECTEX", "DisconnectEx"));
     mixin(GET_FUNC_POINTER("WSAID_GETACCEPTEXSOCKADDRS", "GetAcceptexSockAddrs"));
     mixin(GET_FUNC_POINTER("WSAID_TRANSMITFILE", "TransmitFile"));
     mixin(GET_FUNC_POINTER("WSAID_TRANSMITPACKETS", "TransmitPackets"));
     mixin(GET_FUNC_POINTER("WSAID_WSARECVMSG", "WSARecvMsg"));*/
}

private __gshared bool isApiLoaded = false;

private bool GetFunctionPointer(FuncPointer)(SOCKET sock, ref FuncPointer pfn, ref GUID guid) {
    DWORD dwBytesReturned = 0;
    if (WSAIoctl(sock, SIO_GET_EXTENSION_FUNCTION_POINTER, &guid, guid.sizeof,
            &pfn, pfn.sizeof, &dwBytesReturned, null, null) == SOCKET_ERROR) {
        error("Get function failed with error:", GetLastError());
        return false;
    }

    return true;
}

private string GET_FUNC_POINTER(string GuidValue, string pft, string socket = "socket") {
    string str = " guid = " ~ GuidValue ~ ";";
    str ~= "if( !GetFunctionPointer( " ~ socket ~ ", " ~ pft
        ~ ", guid ) ) { errnoEnforce(false,\"get function error!\"); } ";
    return str;
}

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
