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

    protected void onClose() {
        _isRegistered = false;
        _isClosing = false;
        version (HAVE_IOCP) {
        } else {
            _inLoop.deregister(this);
        }
        clear();

        version (HUNT_DEBUG_MORE)
            tracef("channel closed [fd=%d]...", this.handle);
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

    void close() {
        if (cas(&_isClosed, false, true)) {
            version (HUNT_DEBUG_MORE)
                tracef("channel[fd=%d] closing...", this.handle);
            onClose();
            version (HUNT_DEBUG_MORE)
                tracef("channel[fd=%d] closed...", this.handle);
        } else {
            debug warningf("The channel[fd=%d] has already been closed", this.handle);
        }
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