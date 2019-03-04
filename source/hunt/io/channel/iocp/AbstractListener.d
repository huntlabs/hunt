module hunt.io.channel.iocp.AbstractListener;

// dfmt off
version (HAVE_IOCP) : 
// dfmt on

import hunt.event.selector.Selector;
import hunt.io.channel.AbstractSocketChannel;
import hunt.io.channel.Common;
import hunt.io.channel.iocp.Common;
import hunt.logging.ConsoleLogger;
import hunt.Functions;

import core.sys.windows.windows;
import core.sys.windows.winsock2;
import core.sys.windows.mswsock;

import std.socket;



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
        
        // version (HUNT_DEBUG)
        //     tracef("_isWritting=%s", _isWritting);
        // _isWritting = false;
        // assert(false, "");
        // TODO: created by Administrator @ 2018-3-27 15:51:52
    }

    private IocpContext _iocp;
    private WSABUF _dataWriteBuffer;
    private ubyte[] _buffer;
    private Socket _clientSocket;
}
