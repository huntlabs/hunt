module hunt.io.channel.AbstractChannel;

import hunt.event.selector.Selector;
import hunt.io.channel.Common;
import hunt.logging.ConsoleLogger;

import core.atomic;
import std.bitmanip;
import std.socket : socket_t;

/**
*/
abstract class AbstractChannel : Channel {
    socket_t handle = socket_t.init;
    ErrorEventHandler errorHandler;

    protected bool _isRegistered = false;
    protected bool _isClosing = false;
    protected shared bool _isClosed = false;

    this(Selector loop, ChannelType type) {
        this._inLoop = loop;
        _type = type;
        _flags = BitArray([false, false, false, false, false, false, false,
                false, false, false, false, false, false, false, false, false]);
    }

    /**
    */
    bool isRegistered() {
        return _isRegistered;
    }

    /**
    */
    bool isClosed() {
        return _isClosing || _isClosed;
    }

    void close() {
        if (cas(&_isClosed, false, true)) {
            version (HUNT_IO_DEBUG_MORE)
                tracef("channel[fd=%d] closing...", this.handle);
            onClose();
            version (HUNT_IO_DEBUG)
                tracef("channel[fd=%d] closed", this.handle);
        } else {
            debug warningf("The channel[fd=%d] has already been closed", this.handle);
        }
    }

    protected void onClose() {
        version (HUNT_IO_DEBUG)
            tracef("onClose [fd=%d]...", this.handle);

        _isRegistered = false;
        _isClosing = false;
        version (HAVE_IOCP) {
        } else {
            _inLoop.deregister(this);
        }
        clear();

        version (HUNT_IO_DEBUG_MORE)
            tracef("onClose done [fd=%d]...", this.handle);
    }

    protected void errorOccurred(string msg) {
        debug warningf("isRegistered: %s, isClosed: %s, msg=%s", _isRegistered, _isClosed, msg);
        if (errorHandler !is null) {
            errorHandler(msg);
        }
    }

    void onRead() {
        assert(false, "not implemented");
    }

    void onWrite() {
        assert(false, "not implemented");
    }

    final bool hasFlag(ChannelFlag index) {
        return _flags[index];
    }

    @property ChannelType type() {
        return _type;
    }

    @property Selector eventLoop() {
        return _inLoop;
    }

    void setNext(AbstractChannel next) {
        if (next is this)
            return; // Can't set to self
        next._next = _next;
        next._priv = this;
        if (_next)
            _next._priv = next;
        this._next = next;
    }

    void clear() {
        if (_priv)
            _priv._next = _next;
        if (_next)
            _next._priv = _priv;
        _next = null;
        _priv = null;
    }

    mixin OverrideErro;

protected:
    final void setFlag(ChannelFlag index, bool enable) {
        _flags[index] = enable;
    }

    Selector _inLoop;

private:
    BitArray _flags;
    ChannelType _type;

    AbstractChannel _priv;
    AbstractChannel _next;
}



/**
    https://stackoverflow.com/questions/40361869/how-to-wake-up-epoll-wait-before-any-event-happened
*/
class EventChannel : AbstractChannel {
    this(Selector loop) {
        super(loop, ChannelType.Event);
    }

    abstract void trigger();
    // override void close() {
    //     if(_isClosing)
    //         return;
    //     _isClosing = true;
    //     version (HUNT_DEBUG) tracef("closing [fd=%d]...", this.handle);

    //     if(isBusy) {
    //         import std.parallelism;
    //         version (HUNT_DEBUG) warning("Close operation delayed");
    //         auto theTask = task(() {
    //             while(isBusy) {
    //                 version (HUNT_DEBUG) infof("waitting for idle [fd=%d]...", this.handle);
    //                 // Thread.sleep(20.msecs);
    //             }
    //             super.close();
    //         });
    //         taskPool.put(theTask);
    //     } else {
    //         super.close();
    //     }
    // }
}

mixin template OverrideErro() {
    bool isError() {
        return _error;
    }

    string erroString() {
        return _erroString;
    }

    void clearError() {
        _error = false;
        _erroString = "";
    }

    bool _error = false;
    string _erroString;
}