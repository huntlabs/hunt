module hunt.io.channel.posix.KqueueEventChannel;

// dfmt off
version(HAVE_KQUEUE):
// dfmt on

import hunt.event.selector.Selector;
import hunt.io.channel.AbstractChannel;
import hunt.io.channel.Common;

import std.socket;

/**
*/
class KqueueEventChannel : EventChannel {
    this(Selector loop) {
        super(loop);
        setFlag(ChannelFlag.Read, true);
        _pair = socketPair();
        _pair[0].blocking = false;
        _pair[1].blocking = false;
        this.handle = _pair[1].handle;
    }

    ~this() @nogc {
        // close();
    }

    override void trigger() {
        _pair[0].send("call");
    }

    override void onRead() {
        ubyte[128] data;
        while (true) {
            if (_pair[1].receive(data) <= 0)
                break;
        }
    }

    Socket[2] _pair;
}