/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2018-2019 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

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
    // private ByteArrayInputStream inStream;
    private int size;

    this(int size) {
        this.size = size;
    }

    void close() {
        // inStream = null;
        outStream = null;
    }

    ByteArrayInputStream getInputStream() {
        return new ByteArrayInputStream(outStream.toByteArray());
        // if (inStream is null) {
        //     inStream = new ByteArrayInputStream(outStream.toByteArray());
        //     // outStream = null;
        // }
        // return inStream;
    }

    ByteArrayOutputStream getOutputStream() {
        if (outStream is null) {
            outStream = new ByteArrayOutputStream(size);
        }
        return outStream;
    }
}

/**
 * 
 */
class FilePipedStream : PipedStream {

    private BufferedOutputStream output;
    // private BufferedInputStream input;
    private string temp;

    this() {
        this(tempDir());
    }

    this(string tempdir) {
        import std.uuid;
        temp = tempdir  ~ dirSeparator ~ "hunt-" ~ randomUUID().toString();
    }

    void close() {
        import std.array;
        if (temp.empty())
            return;

        try {
            temp.remove();
        } finally {
            // if (input !is null)
            //     input.close();

            if (output !is null)
                output.close();
        }

        // input = null;
        output = null;
        temp = null;
    }


    BufferedInputStream getInputStream() {
        // if (input is null) {
        //     input = new BufferedInputStream(new FileInputStream(temp));
        // }
        // return input;
        return new BufferedInputStream(new FileInputStream(temp));
    }

    BufferedOutputStream getOutputStream() {
        if (output is null) {
            output = new BufferedOutputStream(new FileOutputStream(temp));
        }
        return output;
    }
}

