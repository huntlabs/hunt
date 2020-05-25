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

module hunt.io.TcpStream;

import hunt.io.channel.Common;
import hunt.io.TcpStreamOptions;
import hunt.io.IoError;

import hunt.collection.ByteBuffer;
import hunt.collection.BufferUtils;
import hunt.event.selector.Selector;
import hunt.concurrency.SimpleQueue;
import hunt.event;
import hunt.logging.ConsoleLogger;
import hunt.Functions;

import std.exception;
import std.format;
import std.socket;
import std.string;

import core.atomic;
import core.stdc.errno;
import core.thread;
import core.time;

version (HAVE_EPOLL) {
    import core.sys.linux.netinet.tcp : TCP_KEEPCNT;
}



/**
 *
 */
class TcpStream : AbstractStream {
    SimpleEventHandler closeHandler;
    protected shared bool _isConnected; // It's always true for server.

    private TcpStreamOptions _tcpOption;
    private int retryCount = 0;

    // for client
    this(Selector loop, TcpStreamOptions option = null, AddressFamily family = AddressFamily.INET) {
        _isClient = true;
        _isConnected = false;

        if (option is null)
            _tcpOption = TcpStreamOptions.create();
        else
            _tcpOption = option;
        this.socket = new Socket(family, SocketType.STREAM, ProtocolType.TCP);
        super(loop, family, _tcpOption.bufferSize);
        version(HUNT_IO_DEBUG) tracef("buffer size: %d bytes", _tcpOption.bufferSize);
        

    }

    // for server
    this(Selector loop, Socket socket, TcpStreamOptions option = null) {
        if (option is null)
            _tcpOption = TcpStreamOptions.create();
        else
            _tcpOption = option;
        this.socket = socket;
        super(loop, socket.addressFamily, _tcpOption.bufferSize);
        _remoteAddress = socket.remoteAddress();
        _localAddress = socket.localAddress();

        _isClient = false;
        _isConnected = true;
        setKeepalive();
    }

    void options(TcpStreamOptions option) @property {
        assert(option !is null);
        this._tcpOption = option;
    }

    TcpStreamOptions options() @property {
        return this._tcpOption;
    }

    override bool isBusy() {
        return _isWritting;
    }

    
    override bool isClient() {
        return _isClient;
    }

    void connect(string hostname, ushort port) {
        Address[] addresses = getAddress(hostname, port);
        if(addresses is null) {
            throw new SocketException("Can't resolve hostname: " ~ hostname);
        }
        Address selectedAddress;
        foreach(Address addr; addresses) {
            string ip = addr.toAddrString();
            if(ip.startsWith("::")) // skip IPV6
                continue;
            if(ip.length <= 16) {
                selectedAddress = addr;
                break;
            }
        }

        if(selectedAddress is null) {
            warning("No IPV4 avaliable");
            selectedAddress = addresses[0];
        }
        version(HUNT_IO_DEBUG) {
            infof("connecting with: hostname=%s, ip=%s, port=%d ", hostname, selectedAddress.toAddrString(), port);
        }
        connect(selectedAddress); // always select the first one.
    }

    void connect(Address addr) {
        if (_isConnected)
            return;

        _remoteAddress = addr;
        import std.parallelism;

        auto connectionTask = task(&doConnect, addr);
        taskPool.put(connectionTask);
        // doConnect(addr);
    }

    void reconnect() {
        if (!_isClient) {
            throw new Exception("Only client can call this method.");
        }

        if (_isConnected || retryCount >= _tcpOption.retryTimes)
            return;

        retryCount++;
        _isConnected = false;
        this.socket = new Socket(this._family, SocketType.STREAM, ProtocolType.TCP);

        version (HUNT_DEBUG)
            tracef("reconnecting %d...", retryCount);
        connect(_remoteAddress);
    }

    protected override bool doConnect(Address addr)  {
        try {
            version (HUNT_DEBUG)
                tracef("Connecting to %s...", addr);
            // Address binded = createAddress(this.socket.addressFamily);
            // this.socket.bind(binded);
            this.socket.blocking = false;
            version (HAVE_IOCP) {
                start();
                if(super.doConnect(addr)) {
                    this.socket.blocking = false;
                    setKeepalive();
                    _localAddress = this.socket.localAddress();
                    _isConnected = true;
                } else {
                    errorOccurred(ErrorCode.CONNECTIONEFUSED,"Connection refused");
                    _isConnected = false;
                }
            } else {
                if(super.doConnect(addr)) {
                    this.socket.blocking = false;
                    setKeepalive();
                    _localAddress = this.socket.localAddress();
                    start();
                    _isConnected = true;
                } else {
                    errorOccurred(ErrorCode.CONNECTIONEFUSED,"Connection refused");
                    _isConnected = false;
                }
            }
        } catch (Throwable ex) {
            // Must try the best to catch all the exceptions, because it will be executed in another thread.
            debug warning(ex.msg);
            version(HUNT_DEBUG) warning(ex);
            errorOccurred(ErrorCode.CONNECTIONEFUSED,"Connection refused");
            _isConnected = false;
        } 

        if (_connectionHandler !is null) {
            try {
                _connectionHandler(_isConnected);
            } catch(Throwable ex) {
                debug warning(ex.msg);
                version(HUNT_DEBUG) warning(ex);
            }
        }
        return true;
    }

    // www.tldp.org/HOWTO/html_single/TCP-Keepalive-HOWTO/
    // http://www.importnew.com/27624.html
    private void setKeepalive() {
        version (HAVE_EPOLL) {
            if (_tcpOption.isKeepalive) {
                this.socket.setKeepAlive(_tcpOption.keepaliveTime, _tcpOption.keepaliveInterval);
                this.setOption(SocketOptionLevel.TCP,
                        cast(SocketOption) TCP_KEEPCNT, _tcpOption.keepaliveProbes);
                // version (HUNT_DEBUG) checkKeepAlive();
            }
        } else version (HAVE_IOCP) {
            if (_tcpOption.isKeepalive) {
                this.socket.setKeepAlive(_tcpOption.keepaliveTime, _tcpOption.keepaliveInterval);
                // this.setOption(SocketOptionLevel.TCP, cast(SocketOption) TCP_KEEPCNT,
                //     _tcpOption.keepaliveProbes);
                // version (HUNT_DEBUG) checkKeepAlive();
            }
        }
    }

    version (HUNT_DEBUG) private void checkKeepAlive() {
        version (HAVE_EPOLL) {
            int time;
            int ret1 = getOption(SocketOptionLevel.TCP, cast(SocketOption) TCP_KEEPIDLE, time);
            tracef("ret=%d, time=%d", ret1, time);

            int interval;
            int ret2 = getOption(SocketOptionLevel.TCP, cast(SocketOption) TCP_KEEPINTVL, interval);
            tracef("ret=%d, interval=%d", ret2, interval);

            int isKeep;
            int ret3 = getOption(SocketOptionLevel.SOCKET, SocketOption.KEEPALIVE, isKeep);
            tracef("ret=%d, keepalive=%s", ret3, isKeep == 1);

            int probe;
            int ret4 = getOption(SocketOptionLevel.TCP, cast(SocketOption) TCP_KEEPCNT, probe);
            tracef("ret=%d, interval=%d", ret4, probe);
        }
    }

    TcpStream connected(ConnectionHandler handler) {
        _connectionHandler = handler;
        return this;
    }

    TcpStream received(DataReceivedHandler handler) {
        dataReceivedHandler = handler;
        return this;
    }

    TcpStream writed(SimpleActionHandler handler) {
        dataWriteDoneHandler = handler;
        return this;
    }
    alias onWritten = writed;

    TcpStream closed(SimpleEventHandler handler) {
        closeHandler = handler;
        return this;
    }

    TcpStream disconnected(SimpleEventHandler handler) {
        disconnectionHandler = handler;
        return this;
    }

    TcpStream error(ErrorEventHandler handler) {
        errorHandler = handler;
        return this;
    }

    override bool isConnected() nothrow {
        return _isConnected;
    }

    override void start() {
        if (_isRegistered)
            return;
        _inLoop.register(this);
        _isRegistered = true;
        version (HAVE_IOCP)
        {
        //    this.beginRead();
        }
    }

    void write(ByteBuffer buffer) {
        assert(buffer !is null);

        if (!_isConnected) {
            throw new Exception(format("The connection is down! remote: %s",
                this.remoteAddress.toString()));
        }

        version (HUNT_IO_DEBUG)
            infof("data buffered (%d bytes): fd=%d", buffer.limit(), this.handle);
        _isWritting = true;
        initializeWriteQueue();
        _writeQueue.enqueue(buffer);
        onWrite();
    }

    /**
    */
    void write(const(ubyte)[] data) {
        if (data.length == 0 || !_isConnected)
            return;

        if (!_isConnected) {
            throw new Exception("The connection is down!");
        }
        version (HAVE_IOCP)
        {
            return write(BufferUtils.toBuffer(cast(byte[])data));
        } else
        {
            version (HUNT_IO_DEBUG_MORE) {
                infof("%d bytes(fd=%d): %(%02X %)", data.length, this.handle, data[0 .. $]);
            } else  version (HUNT_IO_DEBUG) {
                if (data.length <= 32)
                    infof("%d bytes(fd=%d): %(%02X %)", data.length, this.handle, data[0 .. $]);
                else
                    infof("%d bytes(fd=%d): %(%02X %)", data.length, this.handle, data[0 .. 32]);
            }

            if (_writeQueue is null || (_writeQueue.isEmpty()) && !_isWritting) {
                _isWritting = true;
                const(ubyte)[] d = data;

                while (!isClosing() && !isWriteCancelling && d.length > 0) {
                    version (HUNT_IO_DEBUG)
                        infof("to write directly %d bytes, fd=%d", d.length, this.handle);
                    size_t nBytes = tryWrite(d);

                    if (nBytes == d.length) {
                        version (HUNT_IO_DEBUG)
                            tracef("write all out at once: %d / %d bytes, fd=%d", nBytes, d.length, this.handle);
                        checkAllWriteDone();
                        break;
                    } else if (nBytes > 0) {
                        version (HUNT_IO_DEBUG)
                            tracef("write out partly: %d / %d bytes, fd=%d", nBytes, d.length, this.handle);
                        d = d[nBytes .. $];
                    } else {
                        version (HUNT_IO_DEBUG)
                            warningf("buffering data: %d bytes, fd=%d", d.length, this.handle);
                        initializeWriteQueue();
                        _writeQueue.enqueue(BufferUtils.toBuffer(cast(byte[]) d));
                        break;
                    }
                }
            } else {
                write(BufferUtils.toBuffer(cast(byte[]) data));
            }
        }
    }

    void shutdownInput() {
        this.socket.shutdown(SocketShutdown.RECEIVE);
    }

    void shutdownOutput() {
        this.socket.shutdown(SocketShutdown.SEND);
    }

    override protected void onDisconnected() {
        version(HUNT_DEBUG) {
            infof("peer disconnected: fd=%d", this.handle);
        }
        if (disconnectionHandler !is null)
            disconnectionHandler();

        this.close();
    }

protected:
    bool _isClient;
    ConnectionHandler _connectionHandler;

    override void onRead() {
        version (HUNT_IO_DEBUG)
            trace("start to read");

        version (Posix) {
            while (!_isClosed && !tryRead()) {
                version (HUNT_IO_DEBUG)
                    trace("continue reading...");
            }
        } else {
            if (!_isClosed)
            {
                doRead();
            }

        }

        //if (this.isError) {
        //    string msg = format("Socket error on read: fd=%d, code=%d, message: %s",
        //            this.handle, errno, this.errorMessage);
        //    debug errorf(msg);
        //    if (!isClosed())
        //        errorOccurred(msg);
        //}
    }

    override void onClose() {
        bool lastConnectStatus = _isConnected;
        super.onClose();
        if(lastConnectStatus) {
            version (HUNT_IO_DEBUG) {
                if (_writeQueue !is null && !_writeQueue.isEmpty) {
                    warningf("Some data has not been sent yet: fd=%d", this.handle);
                }
                infof("Closing a connection with: %s, fd=%d", this.remoteAddress, this.handle);
            }

            resetWriteStatus();
            _isConnected = false;
            version (HUNT_IO_DEBUG)
                infof("notifying TCP stream down: fd=%d", this.handle);
            if (closeHandler !is null)
                closeHandler();
        }

    }

}
