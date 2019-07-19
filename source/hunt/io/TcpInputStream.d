module hunt.io.TcpInputStream;

import hunt.io.Common;
import hunt.io.TcpStream;
import hunt.logging.ConsoleLogger;

import std.algorithm;
import std.format;

import hunt.collection.ByteBuffer;
import hunt.concurrency.SimpleQueue;


class TcpInputStream : InputStream {

    private TcpStream tcp;
    private SimpleQueue!ByteBuffer bufferQueue;

    this(TcpStream tcp) {
        assert(tcp !is null);
        bufferQueue = new SimpleQueue!ByteBuffer();
        this.tcp = tcp;
        this.tcp.dataReceivedHandler = &dataReceived;
    }

    private void dataReceived(ByteBuffer buffer) {
        version(HUNT_DEBUG) trace("data enqueue...");
        bufferQueue.enqueue(buffer);
    }

    override int read(byte[] b, int off, int len) {
        version(HUNT_DEBUG) info("waitting....");
        ByteBuffer buffer = bufferQueue.dequeue();
        int r = buffer.remaining();
        version(HUNT_DEBUG) info("read....", buffer.toString());
        r =  min(len, r);

        // buffer.get(b, off, r);
        b[off .. off + r] = buffer.array[0 .. r];
        return r;
    }

    override int read() {
        version(HUNT_DEBUG) trace("waitting....");
        ByteBuffer buffer = bufferQueue.dequeue();
        version(HUNT_DEBUG) trace("read....");
        return buffer.get();
    }

}

