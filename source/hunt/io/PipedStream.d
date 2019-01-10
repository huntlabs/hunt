module hunt.io.PipedStream;

import hunt.io.Common;
import hunt.io.ByteArrayInputStream;
import hunt.io.ByteArrayOutputStream;
import hunt.io.BufferedInputStream;
import hunt.io.BufferedOutputStream;
import hunt.io.FileInputStream;
import hunt.io.FileOutputStream;
import hunt.util.Common;

// import hunt.logging;

import std.path;
import std.file;

interface PipedStream : Closeable {

    InputStream getInputStream();

    OutputStream getOutputStream();
}

/**
*/
class ByteArrayPipedStream : PipedStream {

    private ByteArrayOutputStream outStream;
    private ByteArrayInputStream inStream;
    private int size;

    this(int size) {
        this.size = size;
    }

    void close() {
        inStream = null;
        outStream = null;
    }

    InputStream getInputStream() {
        if (inStream is null) {
            inStream = new ByteArrayInputStream(outStream.toByteArray());
            outStream = null;
        }
        return inStream;
    }

    OutputStream getOutputStream() {
        if (outStream is null) {
            outStream = new ByteArrayOutputStream(size);
        }
        return outStream;
    }
}

/**
*/
class FilePipedStream : PipedStream {

    private OutputStream output;
    private InputStream input;
    private string temp;

    this() {
        import std.uuid;
        this(tempDir() ~ dirSeparator ~ randomUUID().toString());
    }

    this(string tempdir) {
        temp = tempdir;
    }

    void close() {
        import std.array;
        if (temp.empty())
            return;

        try {
            temp.remove();
        } finally {
            if (input !is null)
                input.close();

            if (output !is null)
                output.close();
        }

        input = null;
        output = null;
        temp = null;
    }


    InputStream getInputStream() {
        if (input is null) {
            input = new BufferedInputStream(new FileInputStream(temp));
        }
        return input;
    }

    OutputStream getOutputStream() {
        if (output is null) {
            output = new BufferedOutputStream(new FileOutputStream(temp));
        }
        return output;
    }
}

