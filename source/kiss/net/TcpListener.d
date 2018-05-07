module kiss.net.TcpListener;

import kiss.event;
import kiss.net.core;

import std.socket;
import std.exception;
import std.experimental.logger;
import core.thread;
import core.time;

import kiss.core;
import kiss.net.TcpStream;

alias AcceptEventHandler = void delegate(TcpListener sender, TcpStream stream);

// dfmt off
deprecated("Using TcpListener instead.") 
alias Acceptor = TcpListener;


// dfmt on

/**
*/
class TcpListener : AbstractListener
{
    private int _bufferSize = 4 * 1024;

    this(EventLoop loop, AddressFamily family = AddressFamily.INET, int bufferSize = 4 * 1024)
    {
        _bufferSize = bufferSize;
        version (Windows)
            super(loop, family, bufferSize);
        else
            super(loop, family);
        // reusePort(true);
    }
    

    // this(EventLoop loop, Socket sock)
    // {
    //     assert(sock !is null);
    //     super(loop);
    //     this.socket = sock;
    // }

    // dfmt off
    // deprecated("Using onConnectionAccepted instead.")
    TcpListener setReadHandle(AcceptCallBack cback)
    {
        _readBack = cback;
        return this;
        // assert(false, "Using onConnectionAccepted instead.");
    }

    deprecated("Using onShutdown instead.")
    TcpListener setCloseHandle(CloseCallBack cback)
    {
        closeHandler = cback;
        return this;
    }
    
    deprecated("Using bindingAddress instead!") 
    Address bind()
    {
        return _localAddress;
    }

    deprecated("Using start instead.")
    bool watch()
    {
        start();
        return true;
    }
    // dfmt on

    TcpListener onConnectionAccepted(AcceptEventHandler handler)
    {
        acceptHandler = handler;
        return this;
    }

    TcpListener onShutdown(EventHandler handler)
    {
        _shutdownHandler = handler;
        return this;
    }

    TcpListener bind(string ip, ushort port)
    {
        bind(parseAddress(ip, port));
        return this;
    }

    TcpListener bind(ushort port)
    {
        bind(createAddress(this.socket, port));
        return this;
    }

    TcpListener bind(Address addr)
    {
        this.socket.bind(addr);
        _localAddress = _socket.localAddress();
        return this;
    }

    Address bindingAddress()
    {
        return _localAddress; // this.socket.localAddress();
    }

    TcpListener reusePort(bool use)
    {
        this.socket.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, use);

        version (Posix)
        {
            import core.sys.posix.sys.socket;
            this.socket.setOption(SocketOptionLevel.SOCKET, cast(SocketOption) SO_REUSEPORT, use);
        }

        version (windows)
        {
            if (!use)
            {
                import core.sys.windows.winsock2;

                this.socket.setOption(SocketOptionLevel.SOCKET,
                        cast(SocketOption) SO_EXCLUSIVEADDRUSE, true);
            }
        }

        return this;
    }

    TcpListener listen(int backlog)
    {
        this.socket.listen(backlog);
        return this;
    }

    override void start()
    {
        _inLoop.register(this);
        _isRegistered = true;
        version (Windows)
            this.doAccept();
    }

    override void close()
    {
        if (closeHandler !is null)
            closeHandler();
        else if (_shutdownHandler !is null)
            _shutdownHandler(this, null);
        this.onClose();
    }

    override void onRead()
    {
        bool canRead = true;
        version (KissDebugMode)
            trace("start to listen");
        // while(canRead && this.isRegistered) // why??
        {
            version (KissDebugMode)
                trace("listening...");
            canRead = onAccept((Socket socket) {

                version (KissDebugMode)
                    infof("new connection from %s, fd=%d",
                        socket.remoteAddress.toString(), socket.handle());

                if (acceptHandler !is null)
                {
                    TcpStream stream = new TcpStream(_inLoop, socket, _bufferSize);
                    acceptHandler(this, stream);
                    stream.start();
                }
                if(_readBack !is null)
                    _readBack(_inLoop, socket);
            });

            if (this.isError)
            {
                canRead = false;
                error("listener error: ", this.erroString);
                this.close();
            }
        }
    }

    
    AcceptEventHandler acceptHandler;
    SimpleEventHandler closeHandler;

protected:
    AcceptCallBack _readBack;
    EventHandler _shutdownHandler;

}
