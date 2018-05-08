module kiss.event.socket.posix;

// dfmt off
version(Posix):

// dfmt on

import kiss.event.socket.common;
import kiss.event.core;
import kiss.core;
import kiss.util.thread;

import std.conv;
import std.exception;
import std.format;
import std.process;
import std.socket;
import std.string;
import std.experimental.logger;

import core.stdc.errno;
import core.stdc.string;
import core.sys.posix.sys.socket : accept;

/**
TCP Server
*/
abstract class AbstractListener : AbstractSocketChannel
{
    this(Selector loop, AddressFamily family = AddressFamily.INET)
    {
        super(loop, WatcherType.Accept);
        setFlag(WatchFlag.Read, true);
        this.socket = new TcpSocket(family);
    }

    protected bool onAccept(scope AcceptHandler handler)
    {
        version (KissDebugMode)
            trace("new connection coming...");
        this.clearError();
        socket_t clientFd = cast(socket_t)(accept(this.handle, null, null));
        if (clientFd == socket_t.init)
            return false;

        version (KissDebugMode)
            infof("Listener fd=%d, client fd=%d", this.handle, clientFd);

        if (handler !is null)
            handler(new Socket(clientFd, this._family));
        return true;
    }

    override void onWriteDone()
    {
        version (KissDebugMode)
            tracef("a new connection created, thread: %s", getTid());
    }
}

/**
TCP Client
*/
abstract class AbstractStream : AbstractSocketChannel, Stream
{
    SimpleEventHandler disconnectionHandler;
    // DataWrittenHandler sentHandler;

    protected bool _isConnected; //if server side always true.
    // alias UbyteArrayObject = BaseTypeObject!(ubyte[]);

    this(Selector loop, AddressFamily family = AddressFamily.INET, int bufferSize = 4096 * 2)
    {
        // _readBuffer = new UbyteArrayObject();
        version (KissDebugMode)
            trace("Buffer size for read: ", bufferSize);
        _readBuffer = new ubyte[bufferSize];
        super(loop, WatcherType.TCP);
        setFlag(WatchFlag.Read, true);
        setFlag(WatchFlag.Write, true);
        setFlag(WatchFlag.ETMode, true);
    }

    protected bool tryRead()
    {
        bool canRead = false;
        this.clearError();

        ptrdiff_t len = this.socket.receive(cast(void[]) this._readBuffer);

        version (KissDebugMode)
            trace("read nbytes...", len);

        if (len > 0)
        {
            canRead = true;
            if (dataReceivedHandler !is null)
                dataReceivedHandler(this._readBuffer[0 .. len]);

            version (KissDebugMode)
                trace("continue reading...");
            tryRead();
        }
        else if (len < 0)
        {
            if (errno == 4)
            {
                canRead = true;
            }
            else if (errno != EAGAIN && errno != EWOULDBLOCK)
            {
                this._error = true;
                this._erroString = fromStringz(strerror(errno)).idup;
            }
        }
        else
        {
            version (KissDebugMode)
                warningf("connection broken: %s", _remoteAddress.toString());
            onDisconnected();
            if (_isClosed)
                this.socket.close(); // release the sources
            else
                this.close();
        }
        return canRead;
    }

    protected void onDisconnected()
    {
        _isConnected = false;
        _isClosed = true;
        if (disconnectionHandler !is null)
            disconnectionHandler();
    }

    protected bool tryWrite(in ubyte[] data, out size_t writed)
    {
        bool canWrite = false;
        this.clearError();

        const nBytes = this.socket.send(data);
        if (nBytes > 0)
        {
            writed = cast(size_t) nBytes;
            canWrite = true;

            // if (sentHandler !is null)
            //     sentHandler(nBytes);
        }
        else
        {
            if (errno == EINTR)
            {
                canWrite = true;
            }
            else if ((errno == EAGAIN) || (errno == EWOULDBLOCK))
            {
                canWrite = true;
                import core.thread;
                Thread.sleep(50.msecs);
            }
            else
            {
                this._error = true;
                this._erroString = fromStringz(strerror(errno)).idup;
            }
        }
        return canWrite;
    }

    protected void doConnect(Address addr)
    {
        this.socket.connect(addr);
    }

    void cancelWrite()
    {
        isWriteCancelling = true;
    }

    override void onWriteDone()
    {
        // notified by kqueue selector when data writing done
        version (KissDebugMode)
            tracef("done with data writing, thread: %s", getTid());
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
abstract class AbstractDatagramSocket : AbstractSocketChannel, IDatagramSocket
{
    this(Selector loop, AddressFamily family = AddressFamily.INET, int bufferSize = 4096 * 2)
    {
        super(loop, WatcherType.UDP);
        setFlag(WatchFlag.Read, true);
        setFlag(WatchFlag.ETMode, false);

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

    final void bind(Address addr)
    {
        if (_binded)
            return;
        _bindAddress = addr;
        socket.bind(_bindAddress);
        _binded = true;
    }

    final bool isBind()
    {
        return _binded;
    }

    Address bindAddr()
    {
        return _bindAddress;
    }

    protected UdpDataObject _readBuffer;
    protected bool _binded = false;
    protected Address _bindAddress;

    protected bool tryRead(scope ReadCallBack read)
    {
        scope Address createAddress()
        {
            enum ushort DPORT = 0;
            if (AddressFamily.INET == this.socket.addressFamily)
                return new InternetAddress(DPORT);
            else if (AddressFamily.INET6 == this.socket.addressFamily)
                return new Internet6Address(DPORT);
            else
                throw new AddressException(
                        "NOT SUPPORT addressFamily. It only can be AddressFamily.INET or AddressFamily.INET6");
        }

        this._readBuffer.addr = createAddress();
        auto data = this._readBuffer.data;
        scope (exit)
            this._readBuffer.data = data;
        auto len = this.socket.receiveFrom(this._readBuffer.data, this._readBuffer.addr);
        if (len > 0)
        {
            this._readBuffer.data = this._readBuffer.data[0 .. len];
            read(this._readBuffer);
        }
        return false;
    }

    override void onWriteDone()
    {
        // notified by kqueue selector when data writing done
        version (KissDebugMode)
            tracef("done with data writing, thread: %s", getTid());
    }
}
