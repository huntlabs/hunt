module hunt.io.channel.AbstractSocketChannel;

import hunt.event.selector.Selector;
import hunt.io.channel.AbstractChannel;
import hunt.io.channel.Common;
import hunt.logging.ConsoleLogger;

import core.time;
import std.functional;
import std.socket;
import core.stdc.stdint;

/**
 * 
 */
abstract class AbstractSocketChannel : AbstractChannel {

    protected shared bool _isWritting = false; // keep a data write operation atomic

    this(Selector loop, ChannelType type) {
        super(loop, type);
    }

    // Busy with reading or writting
    protected bool isBusy() {
        return false;
    }

    protected @property void socket(Socket s) {
        this.handle = s.handle();
        version (Posix) {
            s.blocking = false;
        }
        _socket = s;
        version (HUNT_DEBUG_MORE)
            infof("new socket: fd=%d", this.handle);
    }

    protected @property Socket socket() {
        return _socket;
    }

    protected Socket _socket;

    override void close() {
        // if (_isClosing) {
        //     // debug warningf("already closed [fd=%d]", this.handle);
        //     return;
        // }
        // _isClosing = true;
        version (HUNT_IO_MORE)
            tracef("socket channel closing [fd=%d]...", this.handle);
        version (HAVE_IOCP)
        {
            super.close();
        } else
        {
            if (isBusy()) {
                import std.parallelism;

                version (HUNT_DEBUG)
                    warning("Close operation delayed");
                auto theTask = task(() {
                    super.close();
                    while (isBusy()) {
                        version (HUNT_DEBUG)
                            infof("waitting for idle [fd=%d]...", this.handle);
                        // Thread.sleep(20.msecs);
                    }
                });
                taskPool.put(theTask);
            } else {
                super.close();
            }
        }
    }

    /// Get a socket option.
    /// Returns: The number of bytes written to $(D result).
    ///    returns the length, in bytes, of the actual result - very different from getsockopt()
    pragma(inline) final int getOption(SocketOptionLevel level, SocketOption option, void[] result) @trusted {
        return this._socket.getOption(level, option, result);
    }

    /// Common case of getting integer and boolean options.
    pragma(inline) final int getOption(SocketOptionLevel level,
            SocketOption option, ref int32_t result) @trusted {
        return this._socket.getOption(level, option, result);
    }

    /// Get the linger option.
    pragma(inline) final int getOption(SocketOptionLevel level, SocketOption option,
            ref Linger result) @trusted {
        return this._socket.getOption(level, option, result);
    }

    /// Get a timeout (duration) option.
    pragma(inline) final void getOption(SocketOptionLevel level,
            SocketOption option, ref Duration result) @trusted {
        this._socket.getOption(level, option, result);
    }

    /// Set a socket option.
    pragma(inline) final void setOption(SocketOptionLevel level, SocketOption option, void[] value) @trusted {
        this._socket.setOption(forward!(level, option, value));
    }

    /// Common case for setting integer and boolean options.
    pragma(inline) final void setOption(SocketOptionLevel level, SocketOption option, int32_t value) @trusted {
        this._socket.setOption(forward!(level, option, value));
    }

    /// Set the linger option.
    pragma(inline) final void setOption(SocketOptionLevel level, SocketOption option, Linger value) @trusted {
        this._socket.setOption(forward!(level, option, value));
    }

    pragma(inline) final void setOption(SocketOptionLevel level, SocketOption option, Duration value) @trusted {
        this._socket.setOption(forward!(level, option, value));
    }

    final @property @trusted Address remoteAddress() {
        return _remoteAddress;
    }

    protected Address _remoteAddress;

    final @property @trusted Address localAddress() {
        return _localAddress;
    }

    protected Address _localAddress;

    version (HAVE_IOCP) {
        void setRead(size_t bytes) {
            readLen = bytes;
        }

        protected size_t readLen;
    }

    void start();

    void onWriteDone() {
        assert(false, "unimplemented");
    }

}
