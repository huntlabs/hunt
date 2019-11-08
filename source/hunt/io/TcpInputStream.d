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
        this.tcp.onReceived(&dataReceived);
    }

    private void dataReceived(ByteBuffer buffer) {
        version(HUNT_IO_DEBUG) trace("data enqueue...");
        bufferQueue.enqueue(buffer);
    }

    override int read(byte[] b, int off, int len) {
        version(HUNT_IO_DEBUG) info("waitting....");
        // TODO: Tasks pending completion -@zxp at 7/20/2019, 11:32:52 AM
        // Support timeout
        ByteBuffer buffer = bufferQueue.dequeue();
        int r = buffer.remaining();
        version(HUNT_IO_DEBUG) info("read....", buffer.toString());
        r =  min(len, r);

        // buffer.get(b, off, r);
        b[off .. off + r] = buffer.array[0 .. r];
        return r;
    }

    override int read() {
        version(HUNT_IO_DEBUG) trace("waitting....");
        ByteBuffer buffer = bufferQueue.dequeue();
        version(HUNT_IO_DEBUG) trace("read....");
        return buffer.get();
    }

}

