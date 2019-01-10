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

module hunt.io.socket.Posix;

// dfmt off
version(Posix):

// dfmt on

import hunt.concurrency.thread.Helper;
import hunt.Functions;
import hunt.io.socket.Common;
import hunt.logging;
import hunt.system.Error;

import std.conv;
import std.exception;
import std.format;
import std.process;
import std.socket;
import std.string;

import core.stdc.errno;
import core.stdc.string;
import core.sys.posix.sys.socket : accept;

// extern (C) nothrow @nogc {
//     int     accept4(int, sockaddr*, socklen_t*, int);
// }

enum int SOCK_CLOEXEC = 0x02000000;	/* Atomically set close-on-exec flag for the
				   new descriptor(s).  */
enum int SOCK_NONBLOCK = 0x00004000;	/* Atomically mark descriptor(s) as
				   non-blocking.  */

/**
TCP Server
*/
abstract class AbstractListener : AbstractSocketChannel {
    this(Selector loop, AddressFamily family = AddressFamily.INET) {
        super(loop, ChannelType.Accept);
        setFlag(ChannelFlag.Read, true);
        this.socket = new TcpSocket(family);
    }

    protected bool onAccept(scope AcceptHandler handler) {
        version (HUNT_DEBUG)
            trace("new connection coming...");
        this.clearError();
        // http://man7.org/linux/man-pages/man2/accept.2.html
        version(linux) {
            // socket_t clientFd = cast(socket_t)(accept4(this.handle, null, null, SOCK_NONBLOCK | SOCK_CLOEXEC));
            socket_t clientFd = cast(socket_t)(accept(this.handle, null, null));
        } else {
            socket_t clientFd = cast(socket_t)(accept(this.handle, null, null));
        }
        if (clientFd == socket_t.init)
            return false;

        version (HUNT_DEBUG)
            tracef("Listener fd=%d, client fd=%d", this.handle, clientFd);

        if (handler !is null)
            handler(new Socket(clientFd, this.localAddress.addressFamily));
        return true;
    }

    override void onWriteDone() {
        version (HUNT_DEBUG)
            tracef("a new connection created");
    }
}

/**
TCP Client
*/
abstract class AbstractStream : AbstractSocketChannel, Stream {
    SimpleEventHandler disconnectionHandler;

    protected bool _isConnected; // It's always true for server.

    this(Selector loop, AddressFamily family = AddressFamily.INET, size_t bufferSize = 4096 * 2) {
        version (HUNT_DEBUG)
            trace("Buffer size for read: ", bufferSize);
        _readBuffer = new ubyte[bufferSize];
        super(loop, ChannelType.TCP);
        setFlag(ChannelFlag.Read, true);
        setFlag(ChannelFlag.Write, true);
        setFlag(ChannelFlag.ETMode, true);
    }

    /**
    */
    protected bool tryRead() {
        bool isDone = true;
        this.clearError();
        ptrdiff_t len = this.socket.receive(cast(void[]) this._readBuffer);
        version (HUNT_DEBUG)
            tracef("reading[fd=%d]: %d nbytes", this.handle, len);

        if (len > 0) {
            if (dataReceivedHandler !is null)
                dataReceivedHandler(this._readBuffer[0 .. len]);

            // It's prossible that more data are wainting for read in inner buffer.
            if (len == _readBuffer.length)
                isDone = false;
        } else if (len == Socket.ERROR) {
            // https://stackoverflow.com/questions/14595269/errno-35-eagain-returned-on-recv-call
            // FIXME: Needing refactor or cleanup -@Administrator at 2018-5-8 16:06:13
            // check more error status
            this._error = errno != EINTR && errno != EAGAIN && errno != EWOULDBLOCK;
            if (_error) {
                this._erroString = getErrorMessage(errno);
            } else {
                debug warningf("write warning: fd=%s, errno=%d, message=%s", this.handle,
                        errno, getErrorMessage(errno));
            }

            if(errno == ECONNRESET) {
                // https://stackoverflow.com/questions/1434451/what-does-connection-reset-by-peer-mean
                onDisconnected();
                this.close();
            }
        }
        else {
            version (HUNT_DEBUG)
                infof("connection broken: %s, fd:%d", _remoteAddress.toString(), this.handle);
            onDisconnected();
            this.close();
        }

        return isDone;
    }

    protected void onDisconnected() {
        _isConnected = false;
        if (disconnectionHandler !is null)
            disconnectionHandler();
    }

    protected bool canWriteAgain = true;
    int writeRetryLimit = 5;
    private int writeRetries = 0;

    /**
    Warning: It will try the best to write all the data.   
    TODO: create a test
    */
    protected void tryWriteAll(in ubyte[] data) {
        const nBytes = this.socket.send(data);
        version (HUNT_DEBUG)
            tracef("actually sent bytes: %d / %d", nBytes, data.length);

        if (nBytes > 0) {
            if (canWriteAgain && nBytes < data.length) { //  && writeRetries < writeRetryLimit
                // version (HUNT_DEBUG)
                writeRetries++;
                tracef("[%d] rewrite: written %d, remaining: %d, total: %d",
                        writeRetries, nBytes, data.length - nBytes, data.length);
                if (writeRetries > writeRetryLimit)
                    warning("You are writting a big block of data!!!");

                tryWriteAll(data[nBytes .. $]);
            } else
                writeRetries = 0;
        } else if (nBytes == Socket.ERROR) {
            this._error = errno != EINTR && errno != EAGAIN && errno != EWOULDBLOCK;
            if (this._error) {
                this._erroString = lastSocketError();

                warningf("write error: fd=%s, errno=%d, message=%s", this.handle,
                        errno, this._erroString);

                if(errno == ECONNRESET) {
                    // https://stackoverflow.com/questions/1434451/what-does-connection-reset-by-peer-mean
                    onDisconnected();
                    this.close();
                }
            } else {
                debug warningf("write error: fd=%s, errno=%d, message=%s", this.handle,
                        errno, lastSocketError());

                if (canWriteAgain && !_isClosed) {
                    import core.thread;
                    import core.time;

                    writeRetries++;
                    tracef("[%d] rewrite: written %d, remaining: %d, total: %d",
                            writeRetries, nBytes, data.length - nBytes, data.length);
                    if (writeRetries > writeRetryLimit)
                        warning("You are writting a Big block of data!!!");
                    warning("Wait for a 100 msecs to try again");
                    Thread.sleep(100.msecs);
                    tryWriteAll(data);
                }
            }
        } else {
            version (HUNT_DEBUG) {
                warningf("nBytes=%d, message: %s", nBytes, lastSocketError());
                assert(false, "Undefined behavior!");
            }
            else {
                this._error = true;
                this._erroString = lastSocketError();
            }
        }
    }

    /**
    Try to write a block of data.
    */
    protected ptrdiff_t tryWrite(const ubyte[] data) {
        const nBytes = this.socket.send(data);
        version (HUNT_DEBUG)
            tracef("actually sent : %d / %d bytes, fd=%d", nBytes, data.length, this.handle);

        if (nBytes > 0) {
            return nBytes;
        } else if (nBytes == Socket.ERROR) {
            // FIXME: Needing refactor or cleanup -@Administrator at 2018-5-8 16:07:38
            // check more error status
            // EPIPE/Broken pipe: 
            // https://stackoverflow.com/questions/6824265/sigpipe-broken-pipe
            this._error = errno != EINTR && errno != EAGAIN && errno != EWOULDBLOCK;
            if (_error) {
                this._erroString = getErrorMessage(errno);
            } else {
                debug warningf("warning for write: fd=%d, errno=%d, message=%s", this.handle,
                        errno, getErrorMessage(errno));
            }

            if(errno == ECONNRESET) {
                // https://stackoverflow.com/questions/1434451/what-does-connection-reset-by-peer-mean
                onDisconnected();
                this.close();
            }
        } else {
            version (HUNT_DEBUG) {
                warningf("nBytes=%d, message: %s", nBytes, lastSocketError());
                assert(false, "Undefined behavior!");
            }
            else {
                this._error = true;
                this._erroString = getErrorMessage(errno);
            }
        }
        return 0;
    }

    protected void doConnect(Address addr) {
        this.socket.connect(addr);
    }

    void cancelWrite() {
        isWriteCancelling = true;
    }

    override void onWriteDone() {
        // notified by kqueue selector when data writing done
        version (HUNT_DEBUG)
            tracef("done with data writing");
    }

    // protected UbyteArrayObject _readBuffer;
    private const(ubyte)[] _readBuffer;
    protected WriteBufferQueue _writeQueue;
    protected bool isWriteCancelling = false;

    /**
    * Warning: The received data is stored a inner buffer. For a data safe, 
    * you would make a copy of it. 
    */
    DataReceivedHandler dataReceivedHandler;

}

/**
UDP Socket
*/
abstract class AbstractDatagramSocket : AbstractSocketChannel {
    this(Selector loop, AddressFamily family = AddressFamily.INET, int bufferSize = 4096 * 2) {
        super(loop, ChannelType.UDP);
        setFlag(ChannelFlag.Read, true);
        setFlag(ChannelFlag.ETMode, false);

        this.socket = new UdpSocket(family);
        // _socket.blocking = false;
        _readBuffer = new UdpDataObject();
        _readBuffer.data = new ubyte[bufferSize];

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

    protected UdpDataObject _readBuffer;
    protected bool _binded = false;
    protected Address _bindAddress;

    protected bool tryRead(scope ReadCallBack read) {
        this._readBuffer.addr = createAddress(this.socket.addressFamily, 0);
        auto data = this._readBuffer.data;
        scope (exit)
            this._readBuffer.data = data;
        auto len = this.socket.receiveFrom(this._readBuffer.data, this._readBuffer.addr);
        if (len > 0) {
            this._readBuffer.data = this._readBuffer.data[0 .. len];
            read(this._readBuffer);
        }
        return false;
    }

    override void onWriteDone() {
        // notified by kqueue selector when data writing done
        version (HUNT_DEBUG)
            tracef("done with data writing");
    }
}
