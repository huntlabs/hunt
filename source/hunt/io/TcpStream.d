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

import hunt.io.socket.Common;
import hunt.concurrency.SimpleQueue;
import hunt.event;
import hunt.logging;
import hunt.Functions;

import std.format;
import std.socket;
import std.exception;
import std.socket;

import core.atomic;
import core.thread;
import core.time;

version(HAVE_EPOLL) {
    import core.sys.linux.netinet.tcp : TCP_KEEPCNT;
}

/**
*/
class TcpStreamOption {
    string ip = "127.0.0.1";
    ushort port = 8080;

    // http://www.tldp.org/HOWTO/TCP-Keepalive-HOWTO/usingkeepalive.html
    /// the interval between the last data packet sent (simple ACKs are not considered data) and the first keepalive probe; 
    /// after the connection is marked to need keepalive, this counter is not used any further 
    int keepaliveTime = 7200; // in seconds

    /// the interval between subsequential keepalive probes, regardless of what the connection has exchanged in the meantime 
    int keepaliveInterval = 75; // in seconds

    /// the number of unacknowledged probes to send before considering the connection dead and notifying the application layer 
    int keepaliveProbes = 9; // times

    bool isKeepalive = false;

    size_t bufferSize = 1024*8;

    int retryTimes = 5;
    Duration retryInterval = 2.seconds;

    static TcpStreamOption createOption() {
        TcpStreamOption option = new TcpStreamOption();
        option.isKeepalive = true;
        option.keepaliveTime = 15; 
        option.keepaliveInterval = 3; 
        option.keepaliveProbes = 5;
        option.bufferSize = 1024*8;
        return option;
    }

    this() {

    }
}

/**
*/
class TcpStream : AbstractStream {
    SimpleEventHandler closeHandler;

    private TcpStreamOption _tcpOption;
    private int retryCount = 0;

    // for client
    this(Selector loop, AddressFamily family = AddressFamily.INET, TcpStreamOption option = null) {
        if(option is null)
           _tcpOption = TcpStreamOption.createOption();
        else
            _tcpOption = option;
        super(loop, family, _tcpOption.bufferSize);
        this.socket = new Socket(family, SocketType.STREAM, ProtocolType.TCP);

        _isClient = true;
        _isConnected = false;
    }

    // for server
    this(Selector loop, Socket socket, TcpStreamOption option = null) {
        if(option is null)
           _tcpOption = TcpStreamOption.createOption();
        else
            _tcpOption = option;
        super(loop, socket.addressFamily, _tcpOption.bufferSize);
        this.socket = socket;
        _remoteAddress = socket.remoteAddress();
        _localAddress = socket.localAddress();

        _isClient = false;
        _isConnected = true;
        setKeepalive();
    }

    void options(TcpStreamOption option) @property {
        assert(option !is null);
        this._tcpOption = option;
    }

    TcpStreamOption options() @property {
        return this._tcpOption;
    }

    override bool isBusy() {
        return _isWritting;
    }

    void connect(string ip, ushort port) {
        connect(parseAddress(ip, port));
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
        if(!_isClient) {
            throw new Exception("Only client can call this method.");
        }

        if (_isConnected || retryCount >= _tcpOption.retryTimes)
            return;

        retryCount++;
        _isConnected = false;
        this.socket = new Socket(this._family, SocketType.STREAM, ProtocolType.TCP);

        version (HUNT_DEBUG) tracef("reconnecting %d...", retryCount);
        connect(_remoteAddress);
    }

    protected override void doConnect(Address addr) {
        try {
            version (HUNT_DEBUG) tracef("connecting to %s...", addr);
            // Address binded = createAddress(this.socket.addressFamily);
            // this.socket.bind(binded);
            this.socket.blocking = true;
            super.doConnect(addr);
            this.socket.blocking = false;
            _isConnected = true;
            setKeepalive();
            _localAddress = this.socket.localAddress();
            start();
        } catch (Exception ex) {
            warning(ex.message);
        }

        if (_connectionHandler !is null)
            _connectionHandler(_isConnected);
        
    }


    // www.tldp.org/HOWTO/html_single/TCP-Keepalive-HOWTO/
    // http://www.importnew.com/27624.html
    private void setKeepalive() {
        version(HAVE_EPOLL) {
            if(_tcpOption.isKeepalive) {
                this.socket.setKeepAlive(_tcpOption.keepaliveTime, _tcpOption.keepaliveInterval);
                this.setOption(SocketOptionLevel.TCP, cast(SocketOption) TCP_KEEPCNT, 
                    _tcpOption.keepaliveProbes);
                // version (HUNT_DEBUG) checkKeepAlive();
            }
        } else version(HAVE_IOCP) {
            if(_tcpOption.isKeepalive) {
                this.socket.setKeepAlive(_tcpOption.keepaliveTime, _tcpOption.keepaliveInterval);
                // this.setOption(SocketOptionLevel.TCP, cast(SocketOption) TCP_KEEPCNT, 
                //     _tcpOption.keepaliveProbes);
                // version (HUNT_DEBUG) checkKeepAlive();
            }
        }
    }

    version (HUNT_DEBUG)
    private void checkKeepAlive() {
        version(HAVE_EPOLL) {
        int time ;
        int ret1 = getOption(SocketOptionLevel.TCP, cast(SocketOption) TCP_KEEPIDLE, time);
        tracef("ret=%d, time=%d", ret1, time);

        int interval;
        int ret2 = getOption(SocketOptionLevel.TCP, cast(SocketOption) TCP_KEEPINTVL, interval);
        tracef("ret=%d, interval=%d", ret2, interval);

        int isKeep;
        int ret3 = getOption(SocketOptionLevel.SOCKET, SocketOption.KEEPALIVE, isKeep);
        tracef("ret=%d, keepalive=%s", ret3, isKeep==1);

        int probe;
        int ret4 = getOption(SocketOptionLevel.TCP, cast(SocketOption) TCP_KEEPCNT, probe);
        tracef("ret=%d, interval=%d", ret4, probe);
        }
    }

    TcpStream onConnected(ConnectionHandler handler) {
        _connectionHandler = handler;
        return this;
    }

    TcpStream onDataReceived(DataReceivedHandler handler) {
        dataReceivedHandler = handler;
        return this;
    }

    TcpStream onDataWritten(SimpleActionHandler handler) {
        dataWriteDoneHandler = handler;
        return this;
    }

    TcpStream onClosed(SimpleEventHandler handler) {
        closeHandler = handler;
        return this;
    }

    TcpStream onDisconnected(SimpleEventHandler handler) {
        disconnectionHandler = handler;
        return this;
    }

    TcpStream onError(ErrorEventHandler handler) {
        errorHandler = handler;
        return this;
    }

    bool isConnected() nothrow {
        return _isConnected;
    }

    override void start() {
        if (_isRegistered)
            return;
        _inLoop.register(this);
        _isRegistered = true;
        version (HAVE_IOCP)
            this.beginRead();
    }

    void write(StreamWriteBuffer buffer) {
        assert(buffer !is null);
   
        if(!_isConnected) {
            throw new Exception("The connection is down!");
        }

        version (HUNT_DEBUG)
            infof("data buffered (%d bytes): fd=%d",  buffer.capacity, this.handle);
        _isWritting = true;
        initializeWriteQueue();
        _writeQueue.enqueue(buffer);
        onWrite();
        
        // version (HAVE_IOCP) {
        //     if (!_isWritting)  tryWrite();
        // } else {
        //     onWrite();
        // }
    }

    /**
    */
    void write(const(ubyte)[] data) {
        if (data.length == 0 || !_isConnected)
            return;
        
        if(!_isConnected) {
            throw new Exception("The connection is down!");
        }

        if ((_writeQueue is null || _writeQueue.isEmpty()) && !_isWritting) {
            _isWritting = true;
            const(ubyte)[] d = data;

            while (!_isClosing && !isWriteCancelling && d.length > 0) {
            version (HUNT_DEBUG)
                tracef("write data directly, fd=%d, %d bytes", this.handle, d.length);
                size_t nBytes = tryWrite(d);
                
                if(nBytes == d.length) {
                    version (HUNT_DEBUG)
                        tracef("write out once: %d / %d bytes, fd=%d", nBytes, d.length, this.handle);
                    checkAllWriteDone();
                    break;
                } else if (nBytes > 0) {
                    version (HUNT_DEBUG)
                        tracef("written: %d / %d bytes, fd=%d", nBytes, d.length, this.handle);
                    d = d[nBytes..$];
                } else {
                    version (HUNT_DEBUG)
                        warningf("buffering remaining data: %d bytes, fd=%d", d.length, this.handle);
                    initializeWriteQueue();
                    _writeQueue.enqueue(new SocketStreamBuffer(d));
                    break;
                }
            }
        } else {
            write(new SocketStreamBuffer(data));
        }
    }

    void shutdownInput() {
        this.socket.shutdown(SocketShutdown.RECEIVE);
    }

    void shutdownOutput() {
        this.socket.shutdown(SocketShutdown.SEND);
    }


protected:
    bool _isClient;
    ConnectionHandler _connectionHandler;



    override void onRead() {
        version (HUNT_DEBUG)
            trace("start to read");

        version (Posix) {
            while (!_isClosed && !tryRead()) {
                version (HUNT_DEBUG)
                    trace("continue reading...");
            }
        } else {
            doRead();
        }

        if (this.isError) {
            string msg = format("Socket error on read: fd=%d, message: %s",
                    this.handle, this.erroString);
            // version (HUNT_DEBUG)
            debug errorf(msg);
            if(!isClosed)
                errorOccurred(msg);
        }
    }

    override void onClose() {
        version (HUNT_DEBUG) {
            if (_writeQueue !is null && !_writeQueue.isEmpty) {
                warningf("Some data has not been sent yet: fd=%d", this.handle);
            }

            infof("close connection with: %s", this.remoteAddress);
        }

        resetWriteStatus();
        _isConnected = false;
        // if(this.socket is null) {
        //     import core.sys.posix.unistd;
        //     core.sys.posix.unistd.close(this.handle);
        // } else {
        //     this.socket.shutdown(SocketShutdown.BOTH);
        //     this.socket.close();
        // }
        super.onClose();

        version (HUNT_DEBUG) infof("notify TCP stream down: fd=%d", this.handle);
        if (closeHandler)
            closeHandler();
    }

}
