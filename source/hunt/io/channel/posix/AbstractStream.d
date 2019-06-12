module hunt.io.channel.posix.AbstractStream;

// dfmt off
version(Posix):
// dfmt on

import hunt.collection.BufferUtils;
import hunt.collection.ByteBuffer;
import hunt.event.selector.Selector;
import hunt.Functions;
import hunt.io.channel.AbstractSocketChannel;
import hunt.io.channel.Common;
import hunt.logging.ConsoleLogger;
import hunt.system.Error;

import std.format;
import std.socket;

import core.atomic;
import core.stdc.errno;
import core.stdc.string;
import core.sys.posix.sys.socket : accept;
import core.sys.posix.unistd;

enum string ResponseData = "HTTP/1.1 200 OK\r\nContent-Length: 13\r\nConnection: Keep-Alive\r\nContent-Type: text/plain\r\nServer: Hunt/1.0\r\nDate: Wed, 17 Apr 2013 12:00:00 GMT\r\n\r\nHello, World!";

/**
TCP Peer
*/
abstract class AbstractStream : AbstractSocketChannel {
    enum BufferSize = 4096;
    private const(ubyte)[] _readBuffer;
    private ByteBuffer writeBuffer;

    protected SimpleEventHandler disconnectionHandler;
    protected SimpleActionHandler dataWriteDoneHandler;

    protected bool _isConnected; // It's always true for server.
    protected AddressFamily _family;
    protected ByteBuffer _bufferForRead;
    protected WritingBufferQueue _writeQueue;
    protected bool isWriteCancelling = false;

    this(Selector loop, AddressFamily family = AddressFamily.INET, size_t bufferSize = 4096 * 2) {
        this._family = family;
        _bufferForRead = BufferUtils.allocate(bufferSize);
        _bufferForRead.limit(cast(int)bufferSize);
        _readBuffer = cast(ubyte[])_bufferForRead.array();
        // _writeQueue = new WritingBufferQueue();
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
        ptrdiff_t len = read(this.handle, cast(void*) _readBuffer.ptr, _readBuffer.length);
        version (HUNT_DEBUG)
            tracef("reading[fd=%d]: %d bytes", this.handle, len);

        if (len > 0) {
            if (dataReceivedHandler !is null) {
                _bufferForRead.limit(cast(int)len);
                _bufferForRead.position(0);
                dataReceivedHandler(_bufferForRead);
            }

            // size_t nBytes = tryWrite(cast(ubyte[])ResponseData);

            // if(nBytes < ResponseData.length) {
            //     warning("data lost");
            // }

            // It's prossible that there are more data waitting for read in the read I/O space.
            if (len == _readBuffer.length) {
                version (HUNT_DEBUG) infof("Need read again");
                isDone = false;
            }
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

    protected override void onClose() {
        version (HUNT_DEBUG) {
            infof("_isWritting=%s, writeBuffer: %s, _writeQueue: %s", _isWritting, writeBuffer is null, 
                _writeQueue is null || _writeQueue.isEmpty());
        }
        resetWriteStatus();

        if(this.socket is null) {
            import core.sys.posix.unistd;
            core.sys.posix.unistd.close(this.handle);
        } else {
            this.socket.shutdown(SocketShutdown.BOTH);
            this.socket.close();
        }
        super.onClose();
    }

    protected void onDisconnected() {
        _isConnected = false;
        if (disconnectionHandler !is null)
            disconnectionHandler();
    }

    /**
    Try to write a block of data.
    */
    protected ptrdiff_t tryWrite(const ubyte[] data) {
        clearError();
        // const nBytes = this.socket.send(data);
        version (HUNT_DEBUG_MORE)
            tracef("try to write: %d bytes, fd=%d", data.length, this.handle);
        const nBytes = write(this.handle, data.ptr, data.length);
        version (HUNT_DEBUG_MORE)
            tracef("actually written: %d / %d bytes, fd=%d", nBytes, data.length, this.handle);

        if (nBytes > 0) {
            return nBytes;
        } else if (nBytes == Socket.ERROR) {
            // FIXME: Needing refactor or cleanup -@Administrator at 2018-5-8 16:07:38
            // check more error status
            // EPIPE/Broken pipe: 
            // https://stackoverflow.com/questions/6824265/sigpipe-broken-pipe
            this._error = (errno != EINTR && errno != EAGAIN && errno != EWOULDBLOCK);
            if (this._error) {
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
            version (HUNT_DEBUG_MORE) {
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

    private bool tryNextWrite(ByteBuffer buffer) {
        const(ubyte)[] data = cast(const(ubyte)[])buffer.getRemaining();
        version (HUNT_DEBUG_MORE)
            tracef("writting data from a buffer [fd=%d], %d bytes", this.handle, data.length);
        if(data.length == 0)
            return true;

        size_t nBytes = tryWrite(data);
        version (HUNT_DEBUG_MORE)
            tracef("write out once: %d / %d bytes, fd=%d", nBytes, data.length, this.handle);
        if (nBytes > 0) {
            buffer.nextGetIndex(cast(int)nBytes);
            if(!buffer.hasRemaining()) {
                version (HUNT_DEBUG_MORE)
                    tracef("A buffer is written out. fd=%d", this.handle);
                // buffer.clear();
                return true;
            }
        }

        return false;        
    }

    void resetWriteStatus() {
        if(_writeQueue !is null)
            _writeQueue.clear();
        atomicStore(_isWritting, false);
        isWriteCancelling = false;
        writeBuffer = null;
    }

    override void onWrite() {
        version (HUNT_DEBUG_MORE) {
            tracef("checking write status, isWritting: %s, writeBuffer: %s", _isWritting, writeBuffer is null);
            if(writeBuffer !is null) {
                infof("writeBuffer: %s", writeBuffer.toString());
            }
        }

        if(!_isWritting) {
            version (HUNT_DEBUG) warning("not ready for write...");
            return;
        }

        if(_isClosing && isWriteCancelling) {
            version (HUNT_DEBUG_MORE) infof("Write cancelled, fd=%d", this.handle);
            resetWriteStatus();
            return;
        }

        if(writeBuffer !is null) {
            if(tryNextWrite(writeBuffer)) {
                writeBuffer = null;
            } else {
                version (HUNT_DEBUG_MORE) {
                    tracef("waiting to try again... fd=%d, writeBuffer: %s", 
                        this.handle, writeBuffer.toString());
                }
                return;
            }
            version (HUNT_DEBUG_MORE)
                tracef("running here, fd=%d", this.handle);
        }

        if(checkAllWriteDone()) {
            return;
        }

        version (HUNT_DEBUG_MORE) {
            tracef("start to write [fd=%d], writeBuffer %s empty", this.handle, writeBuffer is null ? "is" : "is not");
        }

        if(_writeQueue.tryDequeue(writeBuffer)) {
            if(tryNextWrite(writeBuffer)) {
                writeBuffer = null;  
                checkAllWriteDone();            
            } else {
            version (HUNT_DEBUG_MORE)
                tracef("waiting to try again: fd=%d, writeBuffer: %s", this.handle, writeBuffer.toString());
            }
            version (HUNT_DEBUG_MORE)
                tracef("running here, fd=%d", this.handle);
        }
    }

    protected bool checkAllWriteDone() {
        version (HUNT_DEBUG_MORE) {
            infof("checking remaining: fd=%d, empty: %s", this.handle, 
                _writeQueue is null ? true : _writeQueue.isEmpty());
        }

        if(_writeQueue is null || _writeQueue.isEmpty()) {
            resetWriteStatus();        
            version (HUNT_DEBUG)
                infof("All data are written out. fd=%d", this.handle);
            if(dataWriteDoneHandler !is null)
                dataWriteDoneHandler(this);
            return true;
        }

        return false;
    }

    protected void doConnect(Address addr) {
        this.socket.connect(addr);
    }

    void cancelWrite() {
        isWriteCancelling = true;
    }


    protected void initializeWriteQueue() {
        version(HUNT_DEBUG_MORE) info("_writeQueue: ", _writeQueue is null);
        if (_writeQueue is null) {
            _writeQueue = new WritingBufferQueue();
        }
    }

    /**
    * Warning: The received data is stored a inner buffer. For a data safe, 
    * you would make a copy of it. 
    */
    DataReceivedHandler dataReceivedHandler;

}
