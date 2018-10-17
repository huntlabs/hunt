module hunt.io.PipedStream;

import hunt.io.common;
import hunt.io.ByteArrayInputStream;
import hunt.io.ByteArrayOutputStream;
import hunt.lang.common;
import hunt.lang.exception;

// import hunt.logging;
import std.algorithm;


interface PipedStream : Closeable {

	InputStream getInputStream();
	
	OutputStream getOutputStream();
}

class ByteArrayPipedStream : PipedStream {

    private ByteArrayOutputStream outStream;
    private ByteArrayInputStream inStream;
    private int size;

    this(int size) {
        this.size = size;
    }

    override
    void close() {
        inStream = null;
        outStream = null;
    }

    override
    InputStream getInputStream() {
        if (inStream is null) {
            inStream = new ByteArrayInputStream(outStream.toByteArray());
            outStream = null;
        }
        return inStream;
    }

    override
    OutputStream getOutputStream() {
        if (outStream is null) {
            outStream = new ByteArrayOutputStream(size);
        }
        return outStream;
    }

}
