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

module hunt.io.UdpSocket;

import hunt.event;
import hunt.logging;

import std.socket;
import std.exception;

/**
*/
class UdpSocket : AbstractDatagramSocket {

    private UdpDataHandler _receivedHandler;

    this(EventLoop loop, AddressFamily amily = AddressFamily.INET) {
        super(loop, amily);
    }
    
    UdpSocket enableBroadcast(bool flag) {
        this.socket.setOption(SocketOptionLevel.SOCKET, SocketOption.BROADCAST, flag);
        return this;
    }

    UdpSocket onReceived(UdpDataHandler handler) {
        _receivedHandler = handler;
        return this;
    }

    ptrdiff_t sendTo(const(void)[] buf, Address to) {
        return this.socket.sendTo(buf, to);
    }

    ptrdiff_t sendTo(const(void)[] buf) {
        return this.socket.sendTo(buf);
    }

    ptrdiff_t sendTo(const(void)[] buf, SocketFlags flags, Address to) {
        return this.socket.sendTo(buf, flags, to);
    }

    UdpSocket bind(string ip, ushort port) {
        super.bind(parseAddress(ip, port));
        return this;
    }

    UdpSocket bind(Address address) {
        super.bind(address);
        return this;
    }

    UdpSocket connect(Address addr) {
        this.socket.connect(addr);
        return this;
    }

    override void start() {
        if (!_binded) {
            socket.bind(_bindAddress);
            _binded = true;
        }

        _inLoop.register(this);
        _isRegistered = true;
        version (HAVE_IOCP)
            doRead();
    }

    protected override void onRead() nothrow {
        catchAndLogException(() {
            bool canRead = true;
            while (canRead && _isRegistered) {
                version (HUNT_IO_DEBUG)
                    trace("reading data...");
                canRead = tryRead((Object obj) nothrow{
                    collectException(() {
                        UdpDataObject data = cast(UdpDataObject) obj;
                        if (data !is null) {
                            _receivedHandler(data.data, data.addr);
                        }
                    }());
                });

                if (this.isError) {
                    canRead = false;
                    this.close();
                    error("UDP socket error: ", this.errorMessage);
                }
            }
        }());
    }

}
