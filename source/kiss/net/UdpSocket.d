/*
 * Kiss - A refined core library for D programming language.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.cn
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module kiss.net.UdpSocket;

import kiss.event;
import kiss.net.core;
import kiss.exception;

import std.socket;
import std.exception;
import std.experimental.logger;

// dfmt off
deprecated("Using UdpSocket instead.")
alias UdpStream = KissUdpSocket;
deprecated("Using UdpSocket instead.")
alias KissUdpSocket = UdpSocket;
// dfmt on

/**
*/
class UdpSocket : AbstractDatagramSocket
{

    this(EventLoop loop, AddressFamily amily = AddressFamily.INET)
    {
        super(loop, amily);
    }

    UdpSocket setReadData(UDPReadCallBack cback)
    {
        _readBack = cback;
        return this;
    }

    ptrdiff_t sendTo(const(void)[] buf, Address to)
    {
        return this.socket.sendTo(buf, to);
    }

    ptrdiff_t sendTo(const(void)[] buf)
    {
        return this.socket.sendTo(buf);
    }

    ptrdiff_t sendTo(const(void)[] buf, SocketFlags flags, Address to)
    {
        return this.socket.sendTo(buf, flags, to);
    }

    UdpSocket bind(string ip, ushort port)
    {
        super.bind(parseAddress(ip, port));
        return this;
    }

    UdpSocket connect(Address addr)
    {
        this.socket.connect(addr);
        return this;
    }

    deprecated("Using start instead!")
    bool watch()
    {
        start();
        return true;
    }

    override void start()
    {
        if (!_binded)
        {
            socket.bind(_bindAddress);
            _binded = true;
        }

        _inLoop.register(this);
        _isRegistered = true;
        version (Windows)
            doRead();
    }

    // override void close()
    // {
    //     onClose();
    // }

protected:
    override void onRead() nothrow
    {
        catchAndLogException(() {
            bool canRead = true;
            while (canRead && _isRegistered)
            {
                version (KissDebugMode)
                    trace("reading data...");
                canRead = tryRead((Object obj) nothrow{
                    collectException(() {
                        UdpDataObject data = cast(UdpDataObject) obj;
                        if (data !is null)
                        {
                            _readBack(data.data, data.addr);
                        }
                    }());
                });

                if (this.isError)
                {
                    canRead = false;
                    this.close();
                    error("UDP socket error: ", this.erroString);
                }
            }
        }());
    }

private:
    UDPReadCallBack _readBack;
}
