module hunt.io.channel.posix.EpollEventChannel;

// dfmt off
version (HAVE_EPOLL) : 
// dfmt on

import hunt.event.selector.Selector;
import hunt.io.channel.Common;
import hunt.io.channel.AbstractChannel;
import hunt.logging.ConsoleLogger;

// import std.conv;
import std.socket;
import core.sys.posix.unistd;
import core.sys.linux.sys.eventfd;

/**
    https://stackoverflow.com/questions/5355791/linux-cant-get-eventfd-to-work-with-epoll-together
*/
class EpollEventChannel : EventChannel {
    this(Selector loop) {
        super(loop);
        setFlag(ChannelFlag.Read, true);
        this.handle = cast(socket_t)eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
        _isRegistered = true;
    }

    ~this() {
        // close();
    }

    override void trigger() {
        version (HUNT_IO_DEBUG) tracef("trigger the epoll selector.");
        int r = eventfd_write(this.handle, 1);
        if(r != 0) {
            warningf("error: %d", r);
        }        
    }

    override void onWrite() {
        version (HUNT_IO_DEBUG) tracef("eventLoop running: %s, [fd=%d]", eventLoop.isRuning, this.handle);
        version (HUNT_IO_DEBUG) warning("do nothing");
    }

    override void onRead() {
        this.clearError();
        uint64_t value;
        int r = eventfd_read(this.handle, &value);
        version (HUNT_IO_DEBUG) {
            tracef("result=%d, value=%d, fd=%d", r, value, this.handle);
            if(r != 0) {
                warningf("error: %d", r);
            }
        }
    }

    override void onClose() {
        version (HUNT_IO_DEBUG) tracef("onClose, [fd=%d]...", this.handle);
        super.onClose();
        core.sys.posix.unistd.close(this.handle);
        version (HUNT_IO_DEBUG_MORE) tracef("onClose done, [fd=%d]", this.handle);
    }

}
