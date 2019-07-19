module hunt.io.TcpOutputStream;

import hunt.Exceptions;
import hunt.io.Common;
import hunt.io.TcpStream;

import std.array;
import std.format;

/**
*/
class TcpOutputStream : OutputStream {

    private TcpStream tcp;

    this(TcpStream tcp) {
        assert(tcp !is null);
        this.tcp = tcp;
    }


    override void write(int b) {
        tcp.write(cast(byte[]) [cast (byte) b]);
    }

    override void write(byte[] b, int off, int len) {

        int bufferSize = cast(int)b.length;
        if (b.empty) {
            throw new NullPointerException();
        } else if ((off < 0) || (off > bufferSize) || (len < 0) ||
                   ((off + len) > bufferSize) || ((off + len) < 0)) {
            string msg = format("buffer error, size: %d, offset: %d, length: %d",
                bufferSize, off, len);
            throw new IndexOutOfBoundsException(msg);
        } else if (len == 0) {
            return;
        }

        tcp.write(cast(ubyte[])b[off .. off+len]);
    }

    override void flush()  {
        // do nothing
    }

    override void close()  {
        tcp.shutdownOutput();
    }
}