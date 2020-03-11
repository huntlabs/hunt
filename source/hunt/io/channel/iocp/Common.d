module hunt.io.channel.iocp.Common;


// dfmt off
version (HAVE_IOCP) : 

pragma(lib, "Ws2_32");
// dfmt on

import hunt.collection.ByteBuffer;
import hunt.io.channel.AbstractChannel;
import hunt.io.channel.Common;
import hunt.logging.ConsoleLogger;
import hunt.Functions;

import core.atomic;
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
*/
mixin template CheckIocpError() {
    void checkErro(int ret, int erro = 0) {
        DWORD dwLastError = GetLastError();
        version (HUNT_IO_DEBUG)
            infof("erro=%d, dwLastError=%d", erro, dwLastError);
        if (ret != erro || dwLastError == 0)
            return;

        if (ERROR_IO_PENDING != dwLastError) { // ERROR_IO_PENDING
            import hunt.system.Error;
            warningf("erro=%d, dwLastError=%d", erro, dwLastError);
            this._error = true;
            this._errorMessage = getErrorMessage(dwLastError); // format("IOCP error: code=%s", dwLastError);
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
