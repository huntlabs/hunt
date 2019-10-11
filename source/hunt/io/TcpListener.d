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

module hunt.io.TcpListener;

import hunt.io.TcpStream;
import hunt.io.TcpStreamOptions;

import hunt.event;
import hunt.Exceptions;
import hunt.Functions;
import hunt.logging.ConsoleLogger;
import hunt.util.Common;

import std.socket;
import std.exception;
import core.thread;
import core.time;


alias AcceptEventHandler = void delegate(TcpListener sender, TcpStream stream);
alias PeerCreateHandler = TcpStream delegate(TcpListener sender, Socket socket, size_t bufferSize);

/**
*/
class TcpListener : AbstractListener {
    private bool _isSslEnabled = false;
    private bool _isBlocking = false;
    private bool _isBinded = false;
    private TcpStreamOptions _tcpStreamoption;
    protected EventHandler _shutdownHandler;

    /// event handlers
    AcceptEventHandler acceptHandler;
    SimpleEventHandler closeHandler;
    PeerCreateHandler peerCreateHandler;

    this(EventLoop loop, AddressFamily family = AddressFamily.INET, size_t bufferSize = 4 * 1024) {
        _tcpStreamoption = TcpStreamOptions.create();
        _tcpStreamoption.bufferSize = bufferSize;
        version (HAVE_IOCP)
            super(loop, family, bufferSize);
        else
            super(loop, family);
    }

    TcpListener onConnectionAccepted(AcceptEventHandler handler) {
        acceptHandler = handler;
        return this;
    }

    TcpListener onPeerCreating(PeerCreateHandler handler) {
        peerCreateHandler = handler;
        return this;
    }

    TcpListener onShutdown(EventHandler handler) {
        _shutdownHandler = handler;
        return this;
    }

    TcpListener bind(string ip, ushort port) {
        return bind(parseAddress(ip, port));
    }

    TcpListener bind(ushort port) {
        return bind(createAddress(this.socket.addressFamily, port));
    }

    TcpListener bind(Address addr) {
        this.socket.bind(addr);
        this.socket.blocking = _isBlocking;
        _localAddress = _socket.localAddress();
        _isBinded = true;
        return this;
    }

    Address bindingAddress() {
        return _localAddress;
    }

    void blocking(bool flag) {
        _isBlocking = flag;
        // if(_isBinded)
        this.socket.blocking = flag;
    }

    bool blocking() {
        return _isBlocking;
    }

    /**
     * https://stackoverflow.com/questions/14388706/socket-options-so-reuseaddr-and-so-reuseport-how-do-they-differ-do-they-mean-t
     * https://www.cnblogs.com/xybaby/p/7341579.html
     * https://rextester.com/BUAFK86204
     */
    TcpListener reusePort(bool flag) {
        if(_isBinded) {
            throw new IOException("Must be set before binding.");
        }

        version (Posix) {
            import core.sys.posix.sys.socket;

            this.socket.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, flag);
            this.socket.setOption(SocketOptionLevel.SOCKET, cast(SocketOption) SO_REUSEPORT, flag);
        } else version (Windows) {
            // https://docs.microsoft.com/en-us/windows/win32/winsock/using-so-reuseaddr-and-so-exclusiveaddruse
            // https://docs.microsoft.com/zh-cn/windows/win32/winsock/so-exclusiveaddruse
            import core.sys.windows.winsock2;
            this.socket.setOption(SocketOptionLevel.SOCKET, cast(SocketOption) SO_EXCLUSIVEADDRUSE, !flag);
        }

        return this;
    }

    TcpListener listen(int backlog) {
        this.socket.listen(backlog);
        return this;
    }

    override void start() {
        _inLoop.register(this);
        _isRegistered = true;
        version (HAVE_IOCP)
            this.doAccept();
    }

    override void close() {
        if (closeHandler !is null)
            closeHandler();
        else if (_shutdownHandler !is null)
            _shutdownHandler(this, null);
        this.onClose();
    }

    protected override void onRead() {
        bool canRead = true;
        version (HUNT_DEBUG)
            trace("start to listen");
        // while(canRead && this.isRegistered) // why??
        {
            version (HUNT_DEBUG)
                trace("listening...");

            canRead = onAccept((Socket socket) {

                version (HUNT_DEBUG) {
                    infof("new connection from %s, fd=%d",
                        socket.remoteAddress.toString(), socket.handle());
                }

                if (acceptHandler !is null) {
                    TcpStream stream;
                    if (peerCreateHandler is null) {
                        stream = new TcpStream(_inLoop, socket, _tcpStreamoption);
                    }
                    else
                        stream = peerCreateHandler(this, socket, _tcpStreamoption.bufferSize);

                    acceptHandler(this, stream);
                    stream.start();
                }
            });

            if (this.isError) {
                canRead = false;
                error("listener error: ", this.erroString);
                this.close();
            }
        }
    }
}



// dfmt off
version(linux):
// dfmt on
static if (CompilerHelper.isLessThan(2078)) {
    version (X86) {
        enum SO_REUSEPORT = 15;
    } else version (X86_64) {
        enum SO_REUSEPORT = 15;
    } else version (MIPS32) {
        enum SO_REUSEPORT = 0x0200;
    } else version (MIPS64) {
        enum SO_REUSEPORT = 0x0200;
    } else version (PPC) {
        enum SO_REUSEPORT = 15;
    } else version (PPC64) {
        enum SO_REUSEPORT = 15;
    } else version (ARM) {
        enum SO_REUSEPORT = 15;
    }
    
}

version (AArch64) {
    enum SO_REUSEPORT = 15;
}