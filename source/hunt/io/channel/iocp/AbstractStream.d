module hunt.io.channel.iocp.AbstractStream;

// dfmt off
version (HAVE_IOCP) : 
// dfmt on

import hunt.collection.ByteBuffer;
import hunt.collection.BufferUtils;
import hunt.event.selector.Selector;
import hunt.io.channel.AbstractSocketChannel;
import hunt.io.channel.Common;
import hunt.io.channel.iocp.Common;
import hunt.logging.ConsoleLogger;
import hunt.Functions;
import hunt.concurrency.thread.Helper;

import core.atomic;
import core.sys.windows.windows;
import core.sys.windows.winsock2;
import core.sys.windows.mswsock;

import std.format;
import std.socket;


/**
TCP Peer
*/
abstract class AbstractStream : AbstractSocketChannel {

    // data event handlers
    protected DataReceivedHandler dataReceivedHandler;
    protected SimpleActionHandler dataWriteDoneHandler;

    protected AddressFamily _family;
    protected ByteBuffer _bufferForRead;

    this(Selector loop, AddressFamily family = AddressFamily.INET, size_t bufferSize = 4096 * 2) {
        super(loop, ChannelType.TCP);
        // setFlag(ChannelFlag.Read, true);
        // setFlag(ChannelFlag.Write, true);

        version (HUNT_DEBUG)
            trace("Buffer size for read: ", bufferSize);
        // _readBuffer = new ubyte[bufferSize];
        
        _bufferForRead = BufferUtils.allocate(bufferSize);
        _bufferForRead.clear();
        _readBuffer = cast(ubyte[])_bufferForRead.array();
        _writeQueue = new WritingBufferQueue();
        this.socket = new TcpSocket(family);

        loadWinsockExtension(this.handle);
    }

    mixin CheckIocpError;

    override void onRead() {
        version (HUNT_DEBUG)
            trace("ready to read");
        super.onRead();
    }

    override void onWrite() {        
        version (HUNT_DEBUG)
            tracef("checking write status, isWritting: %s, writeBuffer: %s", _isWritting, writeBuffer is null);

        if(!_isWritting)
            return;
        if(_isClosing && isWriteCancelling) {
            version (HUNT_DEBUG) infof("Write cancelled, fd=%d", this.handle);
            resetWriteStatus();
            return;
        }

        tryNextWrite();
    }
    
    protected override void onClose() {
        _isWritting = false;
        if(this.socket is null) {
            import core.sys.windows.winsock2;
            .closesocket(this.handle);
        } else {
            this.socket.shutdown(SocketShutdown.BOTH);
            this.socket.close();
        }
        super.onClose();
    }

    protected void beginRead() {
        _dataReadBuffer.len = cast(uint) _readBuffer.length;
        _dataReadBuffer.buf = cast(char*) _readBuffer.ptr;
        _iocpread.channel = this;
        _iocpread.operation = IocpOperation.read;
        DWORD dwReceived = 0;
        DWORD dwFlags = 0;

        version (HUNT_DEBUG)
            tracef("start receiving [fd=%d] ", this.socket.handle);

        // https://docs.microsoft.com/en-us/windows/desktop/api/winsock2/nf-winsock2-wsarecv
        int nRet = WSARecv(cast(SOCKET) this.socket.handle, &_dataReadBuffer, 1u, &dwReceived, &dwFlags,
                &_iocpread.overlapped, cast(LPWSAOVERLAPPED_COMPLETION_ROUTINE) null);

        checkErro(nRet, SOCKET_ERROR);
    }

    protected void doConnect(Address addr) {
        Address binded = createAddress(this.socket.addressFamily);
        this.socket.bind(binded);
        _iocpwrite.channel = this;
        _iocpwrite.operation = IocpOperation.connect;
        int nRet = ConnectEx(cast(SOCKET) this.socket.handle(),
                cast(SOCKADDR*) addr.name(), addr.nameLen(), null, 0, null,
                &_iocpwrite.overlapped);
        checkErro(nRet, SOCKET_ERROR);
    }

    private uint doWrite() {
        DWORD dwFlags = 0;
        DWORD dwSent = 0;
        _iocpwrite.channel = this;
        _iocpwrite.operation = IocpOperation.write;
        version (HUNT_DEBUG) {
            size_t bufferLength = sendDataBuffer.length;
            tracef("To write %d nbytes: fd=%d", bufferLength, this.socket.handle());
            // trace(cast(string) data);
            if (bufferLength > 32)
                tracef("%(%02X %) ...", sendDataBuffer[0 .. 32]);
            else
                tracef("%(%02X %)", sendDataBuffer[0 .. $]);
        }

        int nRet = WSASend(cast(SOCKET) this.socket.handle(), &_dataWriteBuffer, 1, &dwSent,
                dwFlags, &_iocpwrite.overlapped, cast(LPWSAOVERLAPPED_COMPLETION_ROUTINE) null);

        version (HUNT_DEBUG) {
            if (dwSent != _dataWriteBuffer.len)
                warningf("dwSent=%d, BufferLength=%d", dwSent, _dataWriteBuffer.len);
        }

        checkErro(nRet, SOCKET_ERROR);

        if (this.isError) {
            errorf("Socket error on write: fd=%d, message=%s", this.handle, this.erroString);
            this.close();
        }

        return dwSent;
    }

    protected void doRead() {
        this.clearError();
        version (HUNT_DEBUG)
            tracef("start reading: %d nbytes", this.readLen);

        if (readLen > 0) {
            // import std.stdio;
            // writefln("length=%d, data: %(%02X %)", readLen, _readBuffer[0 .. readLen]);
            version (HUNT_DEBUG)
                tracef("reading done: %d nbytes", readLen);

            if (dataReceivedHandler !is null) {
                _bufferForRead.limit(cast(int)readLen);
                _bufferForRead.position(0);
                dataReceivedHandler(_bufferForRead);
            }

            // continue reading
            this.beginRead();
        } else if (readLen == 0) {
            version (HUNT_DEBUG) {
                if (_remoteAddress !is null)
                    warningf("connection broken: %s", _remoteAddress.toString());
            }
            onDisconnected();
            // if (_isClosed)
            //     this.close();
        } else {
            version (HUNT_DEBUG) {
                warningf("undefined behavior on thread %d", getTid());
            } else {
                this._error = true;
                this._erroString = "undefined behavior on thread";
            }
        }
    }

    // try to write a block of data directly
    protected size_t tryWrite(const ubyte[] data) {
        // if (_isWritting) {
        //     version (HUNT_DEBUG) warning("Busy in writting on thread: ");
        //     return 0;
        // }
        version (HUNT_DEBUG)
            trace("start to write");
        // _isWritting = true;

        clearError();
        setWriteBuffer(data);
        size_t nBytes = doWrite();

        return nBytes;
    }

    // try to write a block of data from the write queue
    private void tryNextWrite() {
        if(checkAllWriteDone()){
            return;
        } 
        clearError();

        bool haveBuffer = _writeQueue.tryDequeue(writeBuffer);
        if(!haveBuffer) {
            version (HUNT_DEBUG)
                warning("No buffer in queue");
            return;
        }
        const(ubyte)[] data = cast(const(ubyte)[])writeBuffer.getRemaining();
        setWriteBuffer(data);
        size_t nBytes = doWrite();

        version (HUNT_DEBUG)
            tracef("written data: %d bytes", nBytes);

        if (nBytes < data.length) { // to fix the corrupted data 
            version (HUNT_DEBUG)
                warningf("remaining data: %d / %d ", data.length - nBytes, data.length);
            sendDataBuffer = data.dup;
        }        
    }
    
    protected bool checkAllWriteDone() {
        if(_writeQueue is null || _writeQueue.isEmpty()) {
            resetWriteStatus();        
            version (HUNT_DEBUG)
                tracef("All data are written out. fd=%d", this.handle);
            if(dataWriteDoneHandler !is null)
                dataWriteDoneHandler(this);
            return true;
        }

        return false;
    }
    
    void resetWriteStatus() {
        if(_writeQueue !is null)
            _writeQueue.clear();
        atomicStore(_isWritting, false);
        isWriteCancelling = false;
        sendDataBuffer = null;
    }

    private void setWriteBuffer(in ubyte[] data) {
        version (HUNT_DEBUG)
            tracef("buffering data temporarily: %d bytes, fd=%d", data.length, this.handle);
        // trace(cast(string) data);
        // tracef("%(%02X %)", data);

        sendDataBuffer = data; //data[writeLen .. $]; // TODO: need more tests
        _dataWriteBuffer.buf = cast(char*) sendDataBuffer.ptr;
        _dataWriteBuffer.len = cast(uint) sendDataBuffer.length;
    }

    /**
     * Called by selector after data sent
     * Note: It's only for IOCP selector: 
    */
    void onWriteDone(size_t nBytes) {
        version (HUNT_DEBUG) {
            tracef("write out once: %d bytes, isWritting: %s, writeBuffer: %s, isWriteCancelling:%s",
                 nBytes, _isWritting, writeBuffer is null, isWriteCancelling);
        }

        if(!_isWritting)
            return;

        if (isWriteCancelling) {
            resetWriteStatus();
            return;
        }

        if(writeBuffer is null) {
            if(sendDataBuffer.length == nBytes) {
                version (HUNT_DEBUG)
                    tracef("try next write");
                tryNextWrite();
            } else if(sendDataBuffer.length > 0) {
                version (HUNT_DEBUG)
                    tracef("continue to write remaining data: %d bytes", sendDataBuffer.length - nBytes);
                
                setWriteBuffer(sendDataBuffer[nBytes .. $]); // send remaining
                doWrite();
            }
        } else {
            writeBuffer.nextGetIndex(cast(int)nBytes);
            if (!writeBuffer.hasRemaining()) {
                // writeBuffer.clear();
                version (HUNT_DEBUG)
                    tracef("try next write");

                tryNextWrite();
            } else // if (sendDataBuffer.length > nBytes) 
            {
                // version (HUNT_DEBUG)
                version (HUNT_DEBUG)
                    tracef("continue to write remaining data: %d bytes", sendDataBuffer.length - nBytes);
                // FIXME: Needing refactor or cleanup -@Administrator at 2018-6-12 13:56:17
                // sendDataBuffer corrupted
                // const(ubyte)[] data = writeBuffer.remaining();
                // tracef("%(%02X %)", data);
                // tracef("%(%02X %)", sendDataBuffer);
                setWriteBuffer(sendDataBuffer[nBytes .. $]); // send remaining
                nBytes = doWrite();
            }
        }
    }

    private void notifyDataWrittenDone() {
        if(dataWriteDoneHandler !is null && (_writeQueue is null || _writeQueue.isEmpty())) {
            dataWriteDoneHandler(this);
        }
    }

    void cancelWrite() {
        isWriteCancelling = true;
    }

    protected void onDisconnected() {
        _isConnected = false;
        _isClosed = true;
        if (disconnectionHandler !is null)
            disconnectionHandler();
    }

    protected void initializeWriteQueue() {
        if (_writeQueue is null) {
            _writeQueue = new WritingBufferQueue();
        }
    }

    bool _isConnected; //if server side always true.
    SimpleEventHandler disconnectionHandler;

    protected WritingBufferQueue _writeQueue;
    protected bool isWriteCancelling = false;
    private const(ubyte)[] _readBuffer;
    private const(ubyte)[] sendDataBuffer;
    private ByteBuffer writeBuffer;

    private IocpContext _iocpread;
    private IocpContext _iocpwrite;

    private WSABUF _dataReadBuffer;
    private WSABUF _dataWriteBuffer;
}
