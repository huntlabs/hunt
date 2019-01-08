module hunt.io.BufferedOutputStream;

import hunt.io.common;
import hunt.exception;

version(HUNT_DEBUG) {
    import hunt.logging;
}

/**
 * 
 */
class BufferedOutputStream : OutputStream {
    protected  OutputStream output;
    protected  int bufferSize;
    /**
     * The internal buffer where data is stored.
     */
    protected byte[] buf;

    /**
     * The number of valid bytes in the buffer. This value is always
     * in the range {@code 0} through {@code buf.length}; elements
     * {@code buf[0]} through {@code buf[count-1]} contain valid
     * byte data.
     */
    protected int count;

    this(OutputStream output, int bufferSize = 1024) {
        this.output = output;
        if (bufferSize > 1024) {
            this.bufferSize = bufferSize;
            this.buf = new byte[bufferSize];
        } else {
            this.bufferSize = 1024;
            this.buf = new byte[1024];
        }
    }

    alias write = OutputStream.write;

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

        // version(HUNT_DEBUG)
        //     tracef("%(%02X %)", buf[0 .. count]);
    }

    override
    void flush()  {
        version(HUNT_DEBUG) {
            import hunt.logging;
            // if(count == 0)
            //     warning("buffered data(bytes): 0");
            // else
            trace("buffered data(bytes): ", count);
        }
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
