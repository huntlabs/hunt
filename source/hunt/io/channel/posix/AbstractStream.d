module hunt.io.channel.posix.AbstractStream;

// dfmt off
version(Posix):
// dfmt on

import hunt.event.selector.Selector;
import hunt.Functions;
import hunt.io.BufferUtils;
import hunt.io.ByteBuffer;
import hunt.io.channel.AbstractSocketChannel;
import hunt.io.channel.ChannelTask;
import hunt.io.channel.Common;
import hunt.io.IoError;
import hunt.io.SimpleQueue;
import hunt.logging.ConsoleLogger;
import hunt.system.Error;
import hunt.util.worker;


import std.format;
import std.socket;

import core.atomic;
import core.stdc.errno;
import core.stdc.string;
import core.sys.posix.sys.socket : accept;
import core.sys.posix.unistd;

version(HUNT_METRIC) shared int dataCounter = 0;

/**
TCP Peer
*/
abstract class AbstractStream : AbstractSocketChannel {
    enum BufferSize = 4096;
    private const(ubyte)[] _readBuffer;
    private ByteBuffer writeBuffer;
    private ChannelTask _task = null;

    /**
    * Warning: The received data is stored a inner buffer. For a data safe,
    * you would make a copy of it.
    */
    protected DataReceivedHandler dataReceivedHandler;
    protected SimpleEventHandler disconnectionHandler;
    protected SimpleActionHandler dataWriteDoneHandler;

    protected AddressFamily _family;
    protected ByteBuffer _bufferForRead;
    protected WritingBufferQueue _writeQueue;
    protected bool _isWriteCancelling = false;

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

    abstract bool isClient();
    abstract bool isConnected() nothrow;
    abstract protected void onDisconnected();

    private void onTaskFinished() {
        synchronized(this) {
            _task = null;
        }
    }

    private void onDataReceived(ptrdiff_t len) {

        if (dataReceivedHandler is null) 
            return;

        version(HUNT_METRIC) {
            uint id = atomicOp!("+=")(dataCounter, 1);
        }

        Worker worker = taskWorker;

        _bufferForRead.limit(cast(int)len);
        _bufferForRead.position(0);

        if(worker is null) {
            dataReceivedHandler(_bufferForRead);
        } else {
            ByteBuffer bufferCopy = BufferUtils.clone(_bufferForRead);

            synchronized(this) {
                ChannelTask task = _task;

                if(task is null) {
                    task = new ChannelTask();
                    task.dataReceivedHandler = dataReceivedHandler;
                    task.finishedHandler = &onTaskFinished;
                    version(HUNT_METRIC) task.id = id;
                    _task = task;
                    worker.put(task);
                }

                task.buffers.enqueue(bufferCopy);
            }
        }
    }

    /**
     *
     */
    protected bool tryRead() {
        bool isDone = true;
        this.clearError();
        ptrdiff_t len = read(this.handle, cast(void*) _readBuffer.ptr, _readBuffer.length);

        // ubyte[] rb = new ubyte[BufferSize];
        // ptrdiff_t len = read(this.handle, cast(void*) rb.ptr, rb.length);
        version (HUNT_IO_DEBUG) {
            tracef("reading[fd=%d]: %d bytes", this.handle, len);
        }

        if (len > 0) {
            version(HUNT_IO_DEBUG) {
                if (len <= 32)
                    infof("fd: %d, %d bytes: %(%02X %)", this.handle, len, _readBuffer[0 .. len]);
                else
                    infof("fd: %d, 32/%d bytes: %(%02X %)", this.handle, len, _readBuffer[0 .. 32]);
            }

            onDataReceived(len);

            // It's prossible that there are more data waitting for read in the read I/O space.
            if (len == _readBuffer.length) {
                version (HUNT_IO_DEBUG) infof("Read buffer is full read %d bytes. Need to read again.", len);
                isDone = false;
            }
        } else if (len == Socket.ERROR) {
            // https://stackoverflow.com/questions/14595269/errno-35-eagain-returned-on-recv-call
            // FIXME: Needing refactor or cleanup -@Administrator at 2018-5-8 16:06:13
            // check more error status
            this._error = errno != EINTR && errno != EAGAIN && errno != EWOULDBLOCK;
            if (_error) {
                this._errorMessage = getErrorMessage(errno);

                if(errno == ECONNRESET) {
                    // https://stackoverflow.com/questions/1434451/what-does-connection-reset-by-peer-mean
                    onDisconnected();
                    errorOccurred(ErrorCode.CONNECTIONEESET , "connection reset by peer");
                } else {
                    errorOccurred(ErrorCode.INTERRUPTED , "Error occurred on read");
                }
            } else {
                debug warningf("warning on read: fd=%d, errno=%d, message=%s", this.handle,
                        errno, getErrorMessage(errno));
            }

        } else {
            version (HUNT_DEBUG)
                infof("connection broken: %s, fd:%d", _remoteAddress.toString(), this.handle);
            onDisconnected();
        }

        return isDone;
    }

    override protected void doClose() {
        version (HUNT_IO_DEBUG) {
            infof("peer socket %s closing: fd=%d", this.remoteAddress.toString(), this.handle);
        }
        if(this.socket is null) {
          import core.sys.posix.unistd;
          core.sys.posix.unistd.close(this.handle);
        } else {
          this.socket.shutdown(SocketShutdown.BOTH);
          this.socket.close();
        }
            
        version (HUNT_IO_DEBUG) {
            infof("peer socket %s closed: fd=%d", this.remoteAddress.toString, this.handle);
        }

        Task task = _task;
        if(task !is null) {
            task.stop();
        }
    }


    /**
     * Try to write a block of data.
     */
    protected ptrdiff_t tryWrite(const(ubyte)[] data) {
        clearError();
        // const nBytes = this.socket.send(data);
        version (HUNT_IO_DEBUG)
            tracef("try to write: %d bytes, fd=%d", data.length, this.handle);
        const nBytes = write(this.handle, data.ptr, data.length);
        version (HUNT_IO_DEBUG)
            tracef("actually written: %d / %d bytes, fd=%d", nBytes, data.length, this.handle);

        if (nBytes > 0) {
            return nBytes;
        }

        if (nBytes == Socket.ERROR) {
            // FIXME: Needing refactor or cleanup -@Administrator at 2018-5-8 16:07:38
            // check more error status
            // EPIPE/Broken pipe:
            // https://github.com/angrave/SystemProgramming/wiki/Networking%2C-Part-7%3A-Nonblocking-I-O%2C-select%28%29%2C-and-epoll

            if(errno == EAGAIN) {
                version (HUNT_IO_DEBUG) {
                    warningf("warning on write: fd=%d, errno=%d, message=%s", this.handle,
                        errno, getErrorMessage(errno));
                }
            } else if(errno == EINTR || errno == EWOULDBLOCK) {
                // https://stackoverflow.com/questions/38964745/can-a-socket-become-writeable-after-an-ewouldblock-but-before-an-epoll-wait
                debug warningf("warning on write: fd=%d, errno=%d, message=%s", this.handle,
                        errno, getErrorMessage(errno));
                // eventLoop.update(this);
            } else {
                this._error = true;
                this._errorMessage = getErrorMessage(errno);
                if(errno == ECONNRESET) {
                    // https://stackoverflow.com/questions/1434451/what-does-connection-reset-by-peer-mean
                    onDisconnected();
                    errorOccurred(ErrorCode.CONNECTIONEESET , "connection reset by peer");
                } else if(errno == EPIPE) {
                    // https://stackoverflow.com/questions/6824265/sigpipe-broken-pipe
                    // Handle SIGPIPE signal
                    onDisconnected();
                    errorOccurred(ErrorCode.BROKENPIPE , "Broken pipe detected!");
                }

            }
        } else {
            version (HUNT_DEBUG) {
                warningf("nBytes=%d, message: %s", nBytes, lastSocketError());
                assert(false, "Undefined behavior!");
            } else {
                this._error = true;
            }
        }

        return 0;
    }

    private bool tryNextWrite(ByteBuffer buffer) {
        const(ubyte)[] data = cast(const(ubyte)[])buffer.getRemaining();
        version (HUNT_IO_DEBUG) {
            tracef("writting from a buffer [fd=%d], %d bytes, buffer: %s",
                this.handle, data.length, buffer.toString());
        }

        ptrdiff_t remaining = data.length;
        if(data.length == 0)
            return true;

        while(remaining > 0 && !_error && !isClosing() && !_isWriteCancelling) {
            ptrdiff_t nBytes = tryWrite(data);
            version (HUNT_IO_DEBUG)
            {
                tracef("write out once: fd=%d, %d / %d bytes, remaining: %d buffer: %s",
                    this.handle, nBytes, data.length, remaining, buffer.toString());
            }

            if (nBytes > 0) {
                remaining -= nBytes;
                data = data[nBytes .. $];
            }
        }

        version (HUNT_IO_DEBUG) {
            if(remaining == 0) {
                    tracef("A buffer is written out. fd=%d", this.handle);
                return true;
            } else {
                warningf("Writing cancelled or an error ocurred. fd=%d", this.handle);
                return false;
            }
        } else {
            return remaining == 0;
        }
    }

    void resetWriteStatus() {
        if(_writeQueue !is null)
            _writeQueue.clear();
        atomicStore(_isWritting, false);
        _isWriteCancelling = false;
    }

    /**
     * Should be thread-safe.
     */
    override void onWrite() {
        version (HUNT_IO_DEBUG)
        {
            tracef("checking status, isWritting: %s, writeBuffer: %s",
                _isWritting, writeBuffer is null ? "null" : writeBuffer.toString());
        }

        if(!_isWritting) {
            version (HUNT_IO_DEBUG)
            infof("No data needs to be written out. fd=%d", this.handle);
            return;
        }

        if(isClosing() && _isWriteCancelling) {
            version (HUNT_DEBUG) infof("Write cancelled or closed, fd=%d", this.handle);
            resetWriteStatus();
            return;
        }

        // FIXME: Needing refactor or cleanup -@zhangxueping at 2020-04-24T14:26:45+08:00
        // More tests are needed
        // keep thread-safe here
        if(!cas(&_isBusyWritting, false, true)) {
            // version (HUNT_IO_DEBUG)
            version(HUNT_DEBUG) warningf("busy writing. fd=%d", this.handle);
            return;
        }

        scope(exit) {
            _isBusyWritting = false;
        }

        if(writeBuffer !is null) {
            if(tryNextWrite(writeBuffer)) {
                writeBuffer = null;
            } else {
                version (HUNT_IO_DEBUG)
                {
                    infof("waiting to try again... fd=%d, writeBuffer: %s",
                        this.handle, writeBuffer.toString());
                }
                // eventLoop.update(this);
                return;
            }
            version (HUNT_IO_DEBUG)
                tracef("running here, fd=%d", this.handle);
        }

        if(checkAllWriteDone()) {
            return;
        }

        version (HUNT_IO_DEBUG) {
            tracef("start to write [fd=%d], writeBuffer %s empty", this.handle, writeBuffer is null ? "is" : "is not");
        }

        if(_writeQueue.tryDequeue(writeBuffer)) {
            if(tryNextWrite(writeBuffer)) {
                writeBuffer = null;
                checkAllWriteDone();
            } else {
            version (HUNT_IO_DEBUG)
                infof("waiting to try again: fd=%d, writeBuffer: %s", this.handle, writeBuffer.toString());

                // eventLoop.update(this);
            }
            version (HUNT_IO_DEBUG) {
                warningf("running here, fd=%d", this.handle);
            }
        }
    }
    private shared bool _isBusyWritting = false;

    protected bool checkAllWriteDone() {
        version (HUNT_IO_DEBUG) {
            import std.conv;
            tracef("checking remaining: fd=%d, writeQueue empty: %s", this.handle,
               _writeQueue is null ||  _writeQueue.isEmpty().to!string());
        }

        if(_writeQueue is null || _writeQueue.isEmpty()) {
            resetWriteStatus();
            version (HUNT_IO_DEBUG)
                infof("All data are written out: fd=%d", this.handle);
            if(dataWriteDoneHandler !is null)
                dataWriteDoneHandler(this);
            return true;
        }

        return false;
    }

    protected void initializeWriteQueue() {
        if (_writeQueue is null) {
            _writeQueue = new WritingBufferQueue();
        }
    }

    protected bool doConnect(Address addr) {
        try {
            this.socket.connect(addr);
        } catch (SocketOSException e) {
            error(e.msg);
            version(HUNT_DEBUG) error(e);
            return false;
        }
        return true;
    }

    void cancelWrite() {
        _isWriteCancelling = true;
    }

    bool isWriteCancelling() {
        return _isWriteCancelling;
    }

    DataReceivedHandler getDataReceivedHandler() {
        return dataReceivedHandler;
    }

}
