module hunt.io.TcpInputStream;

import hunt.io.Common;
import hunt.io.TcpStream;
import hunt.logging.ConsoleLogger;

import core.time;
import std.algorithm;
import std.format;

import hunt.collection.ByteBuffer;
import hunt.collection.BufferUtils;
import hunt.concurrency.SimpleQueue;

/**
 *
 */
class TcpInputStream : InputStream {

    private Duration _timeout;
    private TcpStream _tcp;
    private SimpleQueue!ByteBuffer _bufferQueue;

    this(TcpStream tcp, Duration timeout = 5.seconds) {
        assert(tcp !is null);
        _bufferQueue = new SimpleQueue!ByteBuffer();
        _timeout = timeout;
        _tcp = tcp;
        _tcp.received(&dataReceived);
    }

    private void dataReceived(ByteBuffer buffer) {
        int size = buffer.remaining();
        if(size == 0) {
            warningf("Empty data");
        } else {
            // clone the buffer for data safe
            ByteBuffer copy = BufferUtils.allocate(size);
            copy.put(buffer).flip();
            version(HUNT_NET_DEBUG) tracef("data enqueue (%s)...", copy.toString());
            _bufferQueue.enqueue(copy);
        }
    }

    override int read(byte[] b, int off, int len) {
        version(HUNT_NET_DEBUG) info("waitting for data....");
        // TODO: Tasks pending completion -@zxp at 7/20/2019, 11:32:52 AM
        // Support timeout
        ByteBuffer buffer = _bufferQueue.dequeue(_timeout);
        int r = buffer.remaining();
        version(HUNT_NET_DEBUG) info("read....", buffer.toString());
        r =  min(len, r);

        b[off .. off + r] = buffer.array[0 .. r];
        return r;
    }

    override int read() {
        version(HUNT_NET_DEBUG) trace("waitting....");
        ByteBuffer buffer = _bufferQueue.dequeue(_timeout);
        version(HUNT_NET_DEBUG) trace("read....");
        return buffer.get();
    }

}

