module kiss.net.UdpSocket;

import kiss.event;
import kiss.net.core;

import std.socket;
import std.exception;
import std.experimental.logger;

// dfmt off
deprecated("Using KissUdpSocket instead.")
alias UdpStream = KissUdpSocket;
// dfmt on


/**
*/
class KissUdpSocket : AbstractDatagramSocket
{

    this(EventLoop loop, AddressFamily amily = AddressFamily.INET)
    {
        super(loop, amily);
    }

    KissUdpSocket setReadData(UDPReadCallBack cback)
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

    KissUdpSocket bind(string ip, ushort port)
    {
        super.bind(parseAddress(ip, port));
        return this;
    }

    KissUdpSocket connect(Address addr)
    {
        this.socket.connect(addr);
        return this;
    }

    // bool watched()
    // {
    //     return this.active;
    // }

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
        version(Windows) doRead();
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
                version(KissDebugMode) trace("reading data...");
                canRead = readUdp((Object obj) nothrow{
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
