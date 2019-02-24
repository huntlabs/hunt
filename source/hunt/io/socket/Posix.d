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
import hunt.logging.ConsoleLogger;
import hunt.system.Error;

import std.conv;
import std.exception;
import std.format;
import std.process;
import std.socket;
import std.string;

import core.atomic;
import core.stdc.errno;
import core.stdc.string;
import core.sys.posix.sys.socket : accept;


extern(C) {
    ssize_t read(int, scope void*, size_t);
    ssize_t write(int __fd, const void *__buf, size_t __n);
}  

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
        version(HAVE_EPOLL) {
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
TCP Peer
*/
abstract class AbstractStream : AbstractSocketChannel {
    SimpleEventHandler disconnectionHandler;

    enum BufferSize = 4096;

    protected bool _isConnected; // It's always true for server.
    protected AddressFamily _family;

    this(Selector loop, AddressFamily family = AddressFamily.INET, size_t bufferSize = 4096 * 2) {
        this._family = family;
        _readBuffer = new ubyte[bufferSize];
        _writeQueue = new WritingBufferQueue();
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
        // ubyte[BufferSize] _readBuffer;
        // ptrdiff_t len = this.socket.receive(cast(void[]) _readBuffer);
        ptrdiff_t len = read(this.socket.handle, cast(void*) _readBuffer.ptr, _readBuffer.length);
        version (HUNT_DEBUG)
            tracef("reading[fd=%d]: %d nbytes", this.handle, len);

        if (len > 0) {
            if (dataReceivedHandler !is null)
                dataReceivedHandler(_readBuffer[0 .. len]);

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
                debug warningf("warning on read: fd=%d, errno=%d, message=%s", this.handle,
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
    // protected void tryWriteAll(in ubyte[] data) {
    //     const nBytes = this.socket.send(data);
    //     version (HUNT_DEBUG)
    //         tracef("actually sent bytes: %d / %d", nBytes, data.length);

    //     if (nBytes > 0) {
    //         if (canWriteAgain && nBytes < data.length) { //  && writeRetries < writeRetryLimit
    //             // version (HUNT_DEBUG)
    //             writeRetries++;
    //             tracef("[%d] rewrite: written %d, remaining: %d, total: %d",
    //                     writeRetries, nBytes, data.length - nBytes, data.length);
    //             if (writeRetries > writeRetryLimit)
    //                 warning("You are writting a big block of data!!!");

    //             tryWriteAll(data[nBytes .. $]);
    //         } else
    //             writeRetries = 0;
    //     } else if (nBytes == Socket.ERROR) {
    //         this._error = errno != EINTR && errno != EAGAIN && errno != EWOULDBLOCK;
    //         if (this._error) {
    //             this._erroString = lastSocketError();

    //             warningf("error on write: fd=%s, errno=%d, message=%s", this.handle,
    //                     errno, this._erroString);

    //             if(errno == ECONNRESET) {
    //                 // https://stackoverflow.com/questions/1434451/what-does-connection-reset-by-peer-mean
    //                 onDisconnected();
    //                 this.close();
    //             }
    //         } else {
    //             debug warningf("error on write: fd=%s, errno=%d, message=%s", this.handle,
    //                     errno, lastSocketError());

    //             if (canWriteAgain && !_isClosed) {
    //                 import core.thread;
    //                 import core.time;

    //                 writeRetries++;
    //                 tracef("[%d] rewrite: written %d, remaining: %d, total: %d",
    //                         writeRetries, nBytes, data.length - nBytes, data.length);
    //                 if (writeRetries > writeRetryLimit)
    //                     warning("You are writting a Big block of data!!!");
    //                 warning("Wait for a 100 msecs to try again");
    //                 Thread.sleep(100.msecs);
    //                 tryWriteAll(data);
    //             }
    //         }
    //     } else {
    //         version (HUNT_DEBUG) {
    //             warningf("nBytes=%d, message: %s", nBytes, lastSocketError());
    //             assert(false, "Undefined behavior!");
    //         }
    //         else {
    //             this._error = true;
    //             this._erroString = lastSocketError();
    //         }
    //     }
    // }

    // private size_t doWrite(const ubyte[] data) {
    //     size_t total = 0;
    //     ptrdiff_t s = 0;
    //     // buf += offset;
    //     size_t length = data.length;

    //     while (total != length) {
    //         errno = 0;
    //         s = write(this.handle, data.ptr + total, length - total);
    //         version (HUNT_DEBUG)
    //             tracef("write to fd %d, written %d, with offset %d and length %d\n", this.handle, s, 0, length);

    //         if (s == -1) {
    // //            fprintf(stderr, "write error on fd %d, %d %s\n", fd, errno, strerror(errno));
    //             if (errno != EAGAIN) {
    //                 debug warningf("warning on write: fd=%d, errno=%d, message=%s", this.handle,
    //                     errno, getErrorMessage(errno));
    //             }
    //             return total;
    //         }

    //         total += s;
    //     }

    //     return total;
    // }

    /**
    Try to write a block of data.
    */
    protected ptrdiff_t tryWrite(const ubyte[] data) {

        this.clearError();

        const nBytes = this.socket.send(data);
        // const nBytes = doWrite(data);

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
                debug warningf("warning on write: fd=%d, errno=%d, message=%s", this.handle,
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

        if (this.isError) {
            string msg = format("Socket error on write: fd=%d, message=%s",
                    this.handle, this.erroString);
            debug errorf(msg);
            errorOccurred(msg);
        }

        return 0;
    }


    override void onWrite() {
        // if (!_isConnected) {
        //     _isConnected = true;
        //     _remoteAddress = socket.remoteAddress();

        //     debug warning("Why here?");

        //     if (_connectionHandler)
        //         _connectionHandler(true);
        //     return;
        // }

        if(_writeQueue.isEmpty()) {
            version (HUNT_DEBUG) warningf("The _writeQueue is empty: [fd=%d]", this.handle);
            return;
        }

        if(!cas(&_isWritting, false, true)) {
            version (HUNT_DEBUG) warningf("Busy in writting: [fd=%d]", this.handle);
            return;
        }

        version (HUNT_DEBUG)
            tracef("start to write [fd=%d]", this.handle);

        StreamWriteBuffer writeBuffer;
        bool haveBuffer = _writeQueue.tryDequeue(writeBuffer);
        while(!_isClosing && !isWriteCancelling && haveBuffer) {
            version (HUNT_DEBUG)
                tracef("writing a buffer [fd=%d]", this.handle);

            const(ubyte)[] data = writeBuffer.remaining();
            while(!_isClosing && !isWriteCancelling && data.length > 0) {
                size_t nBytes = tryWrite(data);
                if (nBytes > 0) {
                    version (HUNT_DEBUG)
                        tracef("writing: %d / %d bytes, fd=%d", nBytes, data.length, this.handle);
                    writeBuffer.pop(nBytes);                        
                    data = writeBuffer.remaining();
                }
            }

            if(!_isClosing && !isWriteCancelling)
                writeBuffer.finish();

            version (HUNT_DEBUG) {
                tracef("buffer writing done: [fd=%d], writeQueue is empty: %s", 
                    this.handle, _writeQueue.isEmpty());
                // tracef("_writeQueue is empty: %s, [fd=%d]", _writeQueue.isEmpty(), this.handle);
            }
            haveBuffer = _writeQueue.tryDequeue(writeBuffer);
        }

        atomicStore(_isWritting, false);
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
            tracef("data writing done [fd=%d]", this.handle,);
    }

    private const(ubyte)[] _readBuffer;
    protected WritingBufferQueue _writeQueue;
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
        // auto len = this.socket.receiveFrom(this._readBuffer.data, this._readBuffer.addr);

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
