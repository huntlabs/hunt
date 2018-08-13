module hunt.io.BufferedNetOutputStream;

import hunt.io.common;
import hunt.util.exception;

/**
 * 
 */
class BufferedNetOutputStream : OutputStream {
    protected  OutputStream output;
    protected  int bufferSize;
    private byte[] buf;
    private int count;

    this(OutputStream output, int bufferSize) {
        this.output = output;
        this.bufferSize = bufferSize;
        if (bufferSize > 1024) {
            this.buf = new byte[bufferSize];
        } else {
            this.buf = new byte[1024];
        }
    }

    override
    void write(int b)  {
        if (count >= buf.length) {
            flush();
        }
        buf[count++] = cast(byte) b;
    }

    override
    void write(byte[] array, int offset, int length)  {
        if (array is null || array.length == 0 || length <= 0) {
            return;
        }

        if (offset < 0) {
            throw new IllegalArgumentException("the offset is less than 0");
        }

        if (length >= buf.length) {
            flush();
            output.write(array, offset, length);
            return;
        }
        if (length > buf.length - count) {
            flush();
        }
        buf[count .. count+length] = array[offset .. offset+length];
        count += length;

        // version(HuntDebugMode)
        //     tracef("%(%02X %)", buf[0 .. count]);
    }

    override
    void flush()  {
        if (count > 0) {
            output.write(buf, 0, count);
            count = 0;
            buf = new byte[bufferSize];
        }
    }

    override
    void close()  {
        flush();
        output.close();
    }
}
