module hunt.io.channel.iocp.AbstractStream;

// dfmt off
version (HAVE_IOCP) : 
// dfmt on

import hunt.event.selector.Selector;
import hunt.io.ByteBuffer;
import hunt.io.BufferUtils;
import hunt.io.channel.AbstractSocketChannel;
import hunt.io.channel.ChannelTask;
import hunt.io.channel.Common;
import hunt.io.channel.iocp.Common;
import hunt.logging;
import hunt.Functions;
import hunt.event.selector.IOCP;
import hunt.system.Error;
import hunt.util.ThreadHelper;
import hunt.util.worker;

import core.atomic;
import core.sys.windows.windows;
import core.sys.windows.winsock2;
import core.sys.windows.mswsock;
import std.format;
import std.socket;
import core.stdc.string;

/**
TCP Peer
*/
abstract class AbstractStream : AbstractSocketChannel {

    // data event handlers
    
    /**
    * Warning: The received data is stored a inner buffer. For a data safe, 
    * you would make a copy of it. 
    */
    protected DataReceivedHandler dataReceivedHandler;
    protected SimpleActionHandler dataWriteDoneHandler;

    protected ByteBuffer _bufferForRead;
    protected AddressFamily _family;

    private size_t _bufferSize = 4096;
    private ChannelTask _task = null;
    

    this(Selector loop, AddressFamily family = AddressFamily.INET, size_t bufferSize = 4096 * 2) {
        _bufferSize = bufferSize;
        super(loop, ChannelType.TCP);
        // setFlag(ChannelFlag.Read, true);
        // setFlag(ChannelFlag.Write, true);

        // version (HUNT_IO_DEBUG)
        //     trace("Buffer size: ", bufferSize);
        // _readBuffer = new ubyte[bufferSize];
        _bufferForRead = BufferUtils.allocate(bufferSize);
        _bufferForRead.clear();
        _readBuffer = cast(ubyte[])_bufferForRead.array();
        // _writeQueue = new WritingBufferQueue();
        // this.socket = new TcpSocket(family);

        loadWinsockExtension(this.handle);
    }

    mixin CheckIocpError;

    abstract bool isClient();

    override void onRead() {
        version (HUNT_IO_DEBUG)
            trace("ready to read");
        super.onRead();
    }

    /**
     * Should be thread-safe.
     */
    override void onWrite() {  
        version (HUNT_IO_DEBUG)
            tracef("checking write status, isWritting: %s, writeBuffer: %s", _isWritting, writeBuffer is null);

        //if(!_isWritting){
        //    version (HUNT_IO_DEBUG) infof("No data to write out. fd=%d", this.handle);
        //    return;
        //}

        if(isClosing() && _isWriteCancelling) {
            version (HUNT_IO_DEBUG) infof("Write cancelled, fd=%d", this.handle);
            resetWriteStatus();
            return;
        }
        tryNextBufferWrite();
    }
    
    protected override void onClose() {
        _isWritting = false;
        resetWriteStatus();
        if(this._socket is null) {
            import core.sys.windows.winsock2;
            .closesocket(this.handle);
        } else {
            // FIXME: Needing refactor or cleanup -@Administrator at 2019/8/9 1:20:27 pm
            //
            //while(!_isSingleWriteBusy)
            //{
                this._socket.shutdown(SocketShutdown.BOTH);
                this._socket.close();
            //}
        }
        super.onClose();
    }

    void beginRead() {
        // https://docs.microsoft.com/en-us/windows/desktop/api/winsock2/nf-winsock2-wsarecv

        ///  _isSingleWriteBusy = true;

        WSABUF _dataReadBuffer;
        _dataReadBuffer.len = cast(uint) _readBuffer.length;
        _dataReadBuffer.buf = cast(char*) _readBuffer.ptr;
        memset(&_iocpread.overlapped , 0 ,_iocpread.overlapped.sizeof );
        _iocpread.channel = this;
        _iocpread.operation = IocpOperation.read;
        DWORD dwReceived = 0;
        DWORD dwFlags = 0;
        version (HUNT_IO_DEBUG)
            tracef("start receiving [fd=%d] ", this.socket.handle);
        // _isSingleWriteBusy = true;
        int nRet = WSARecv(cast(SOCKET) this.socket.handle, &_dataReadBuffer, 1u, 
            &dwReceived, &dwFlags, &_iocpread.overlapped, cast(LPWSAOVERLAPPED_COMPLETION_ROUTINE) null);

        if (nRet == SOCKET_ERROR && (GetLastError() != ERROR_IO_PENDING)) {
            _isSingleWriteBusy = false;
            close();
        }
        //checkErro(nRet, SOCKET_ERROR);
    }

    protected bool doConnect(Address addr) {
        Address binded = createAddress(this.socket.addressFamily);
        _isSingleWriteBusy = true;
        this.socket.bind(binded);
        _iocpread.channel = this;
        _iocpread.operation = IocpOperation.connect;

        import std.datetime.stopwatch;
        auto sw = StopWatch(AutoStart.yes);
        sw.start();
        scope(exit) {
            sw.stop();
        }

        // https://docs.microsoft.com/en-us/windows/win32/api/mswsock/nc-mswsock-lpfn_connectex
        int nRet = ConnectEx(cast(SOCKET) this.socket.handle(), cast(SOCKADDR*) addr.name(), 
            addr.nameLen(), null, 0, null, &_iocpread.overlapped);
        checkErro(nRet, SOCKET_ERROR);

        if(this._error) 
            return false;

        // https://docs.microsoft.com/en-us/windows/win32/api/winsock/nf-winsock-getsockopt
        int seconds = 0;
        int bytes = seconds.sizeof;
        int iResult = 0;

        CHECK: 
        iResult = getsockopt(cast(SOCKET) this.socket.handle(), SOL_SOCKET, SO_CONNECT_TIME,
                            cast(void*)&seconds, cast(PINT)&bytes);

        bool result = false;
        if ( iResult != NO_ERROR ) {
            DWORD dwLastError = WSAGetLastError();
            warningf("getsockopt(SO_CONNECT_TIME) failed with error: code=%d, message=%s", 
                dwLastError, getErrorMessage(dwLastError));
        } else {
            if (seconds == 0xFFFFFFFF) {
                version(HUNT_IO_DEBUG) warningf("Connection not established yet (destination: %s).", addr);
                // so to check again
                goto CHECK;
            } else {
                result = true;
                version(HUNT_IO_DEBUG) {
                    //
                    infof("Connection has been established in %d msecs, destination: %s", sw.peek.total!"msecs", addr);
                }
                // https://docs.microsoft.com/en-us/windows/win32/winsock/sol-socket-socket-options
                enum SO_UPDATE_CONNECT_CONTEXT = 0x7010;
                iResult = setsockopt(cast(SOCKET) this.socket.handle(), SOL_SOCKET, 
                    SO_UPDATE_CONNECT_CONTEXT, NULL, 0 );
            }
        }
        
        return result;
    }

    private uint doWrite(const(ubyte)[] data) {
        DWORD dwSent = 0;//cast(DWORD)data.length;
        DWORD dwFlags = 0;

        memset(&_iocpwrite.overlapped , 0 ,_iocpwrite.overlapped.sizeof );
        _iocpwrite.channel = this;
        _iocpwrite.operation = IocpOperation.write;
        // tracef("To write %d bytes, fd=%d", data.length, this.socket.handle());
        version (HUNT_IO_DEBUG) {
            size_t bufferLength = data.length;
            tracef("To write %d bytes", bufferLength);
            if (bufferLength > 32)
                tracef("%(%02X %) ...", data[0 .. 32]);
            else
                tracef("%s", data);
        }
        // size_t bufferLength = data.length;
        //     tracef("To write %d bytes", bufferLength);
        //     tracef("%s", data);
        WSABUF _dataWriteBuffer;

        //char[] bf = new char[data.length];
        //memcpy(bf.ptr,data.ptr,data.length);
        //_dataWriteBuffer.buf =  bf.ptr;
        _dataWriteBuffer.buf = cast(char*) data.ptr;
        _dataWriteBuffer.len = cast(uint) data.length;
        // _isSingleWriteBusy = true;
        int nRet = WSASend( cast(SOCKET) this.socket.handle(), &_dataWriteBuffer, 1, &dwSent,
        dwFlags, &_iocpwrite.overlapped, cast(LPWSAOVERLAPPED_COMPLETION_ROUTINE) null);
        // if (nRet != NO_ERROR && (GetLastError() != ERROR_IO_PENDING))
        // {
        //     _isSingleWriteBusy = false;
        //     // close();
        // }

        checkErro( nRet, SOCKET_ERROR);

        // FIXME: Needing refactor or cleanup -@Administrator at 2019/8/9 12:18:20 pm
        // Keep this to prevent the buffer corrupted. Why?
        version (HUNT_IO_DEBUG) {
            tracef("sent: %d / %d bytes, fd=%d", dwSent, bufferLength, this.handle);
        }

        if (this.isError) {
            errorf("Socket error on write: fd=%d, message=%s", this.handle, this.errorMessage);
            this.close();
        }

        return dwSent;
    }

    protected void doRead() {
        //_isSingleWriteBusy = false;
        this.clearError();
        version (HUNT_IO_DEBUG)
            tracef("start reading: %d nbytes", this.readLen);

        if (readLen > 0) {
            // import std.stdio;
            // writefln("length=%d, data: %(%02X %)", readLen, _readBuffer[0 .. readLen]);
            handleReceivedData(readLen);

            if (isClient()) {
                this.beginRead();
            }

        } else if (readLen == 0) {
            version (HUNT_IO_DEBUG) {
                if (_remoteAddress !is null)
                    warningf("connection broken: %s", _remoteAddress.toString());
            }
            onDisconnected();
            // if (_isClosed)
            //     this.close();
        } else {
            version (HUNT_IO_DEBUG) {
                warningf("undefined behavior on thread %d", getTid());
            } else {
                this._error = true;
                this._errorMessage = "undefined behavior on thread";
            }
        }
    }

    private void handleReceivedData(ptrdiff_t len) {
        version (HUNT_IO_DEBUG)
            tracef("reading done: %d nbytes", readLen);

        if (dataReceivedHandler is null) 
            return;

        _bufferForRead.limit(cast(int)readLen);
        _bufferForRead.position(0);
        // dataReceivedHandler(_bufferForRead);

        ByteBuffer bufferCopy = BufferUtils.clone(_bufferForRead);
        if(taskWorker is null) {
            dataReceivedHandler(bufferCopy);
        } else {
            ChannelTask task = _task;

            // FIXME: Needing refactor or cleanup -@zhangxueping at 2021-02-05T09:18:02+08:00
            // More tests needed
            if(task is null || task.isFinishing()) {
                task = createChannelTask();
                _task = task;

            } else {
                version(HUNT_METRIC) {
                    warningf("Request peeding... Task status: %s", task.status);
                }
            }

            task.put(bufferCopy);
        }        

    }

    private ChannelTask createChannelTask() {
        ChannelTask task = new ChannelTask();
        task.dataReceivedHandler = dataReceivedHandler;
        taskWorker.put(task);
        return task;
    }

    // try to write a block of data directly
    protected size_t tryWrite(const ubyte[] data) {        
        version (HUNT_IO_DEBUG)
            tracef("start to write, total=%d bytes, fd=%d", data.length, this.handle);
        clearError();
        size_t nBytes;
        //scope(exit) {
        //    _isSingleWriteBusy = false;
        //}
        if (!_isSingleWriteBusy)
        {
             nBytes = doWrite(data);
        }

        return nBytes;
    }

    // try to write a block of data from the write queue
    private void tryNextBufferWrite() {
        if(checkAllWriteDone()){
            _isSingleWriteBusy = false;
            if (!isClient())
            {
                this.beginRead();
            }
            return;
        } 
        
        // keep thread-safe here
        //if(!cas(&_isSingleWriteBusy, false, true)) {
        //    version (HUNT_IO_DEBUG) warningf("busy writing. fd=%d", this.handle);
        //    return;
        //}

        //scope(exit) {
        //    _isSingleWriteBusy = false;
        //}

        clearError();

        bool haveBuffer = _writeQueue.tryDequeue(writeBuffer);
        if(haveBuffer) {
            writeBufferRemaining();
        } else {
            version (HUNT_IO_DEBUG)
                warning("No buffer in queue");
        }
    }

    private void writeBufferRemaining() {
        if (writeBuffer is null )
        {
            return;
        }
        const(ubyte)[] data = cast(const(ubyte)[])writeBuffer.peekRemaining();

        size_t nBytes = doWrite(data);

        version (HUNT_IO_DEBUG)
            tracef("written data: %d bytes, fd=%d", nBytes, this.handle);
        if(nBytes == data.length) {
            writeBuffer = null;
        } else if (nBytes > 0) { 
            writeBuffer.nextGetIndex(cast(int)nBytes);
            version (HUNT_IO_DEBUG)
                warningf("remaining data: %d / %d, fd=%d", data.length - nBytes, data.length, this.handle);
        } else { 
            version (HUNT_IO_DEBUG)
            warningf("I/O busy: writing. fd=%d", this.handle);
        }   
    }
    
    protected bool checkAllWriteDone() {
        if(_writeQueue is null || (_writeQueue.isEmpty() && writeBuffer is null)) {
            resetWriteStatus();        
            version (HUNT_IO_DEBUG)
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
        _isWritting = false;
        _isWriteCancelling = false;
        sendDataBuffer = null;
        sendDataBackupBuffer = null;
        writeBuffer = null;
        _isSingleWriteBusy = false;
    }

    /**
     * Called by selector after data sent
     * Note: It's only for IOCP selector: 
    */
    void onWriteDone(size_t nBytes) {
        version (HUNT_IO_DEBUG) {
            tracef("write done once: %d bytes, isWritting: %s, writeBuffer: %s, fd=%d",
                 nBytes, _isWritting, writeBuffer is null, this.handle);
        }
        //if (_isWriteCancelling) {
        //    version (HUNT_IO_DEBUG) tracef("write cancelled.");
        //    resetWriteStatus();
        //    return;
        //}


        //while(_isSingleWriteBusy) {
        //    version(HUNT_IO_DEBUG)
        //    info("waiting for last writting get finished...");
        //}

        version (HUNT_IO_DEBUG) {
            tracef("write done once: %d bytes, isWritting: %s, writeBuffer: %s, fd=%d",
                 nBytes, _isWritting, writeBuffer is null, this.handle);
        }

        if (writeBuffer !is null && writeBuffer.hasRemaining()) {
            version (HUNT_IO_DEBUG) tracef("try to write the remaining in buffer.");
            writeBufferRemaining();
        }  else {
            version (HUNT_IO_DEBUG) tracef("try to write next buffer.");
            tryNextBufferWrite();
        }
    }

    private void notifyDataWrittenDone() {
        if(dataWriteDoneHandler !is null && _writeQueue.isEmpty()) {
            dataWriteDoneHandler(this);
        }
    }
 
    
    DataReceivedHandler getDataReceivedHandler() {
        return dataReceivedHandler;
    }

    void cancelWrite() {
        _isWriteCancelling = true;
    }

    abstract bool isConnected() nothrow;
    abstract protected void onDisconnected();

    protected void initializeWriteQueue() {
        if (_writeQueue is null) {
            _writeQueue = new WritingBufferQueue();
        }
    }

    SimpleEventHandler disconnectionHandler;
    
    protected WritingBufferQueue _writeQueue;
    protected bool _isWriteCancelling = false;
    private  bool _isSingleWriteBusy = false; // keep a single I/O write operation atomic
    private const(ubyte)[] _readBuffer;
    private const(ubyte)[] sendDataBuffer;
    private const(ubyte)[] sendDataBackupBuffer;
    private ByteBuffer writeBuffer; 

    private IocpContext _iocpread;
    private IocpContext _iocpwrite;
}
