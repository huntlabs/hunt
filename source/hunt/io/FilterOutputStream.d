module hunt.io.FilterOutputStream;

import hunt.io.common;
import hunt.lang.exception;

version(HUNT_DEBUG) {
    import hunt.logging;
}

/**
 * This class is the superclass of all classes that filter output
 * streams. These streams sit on top of an already existing output
 * stream (the <i>underlying</i> output stream) which it uses as its
 * basic sink of data, but possibly transforming the data along the
 * way or providing additional functionality.
 * <p>
 * The class <code>FilterOutputStream</code> itself simply overrides
 * all methods of <code>OutputStream</code> with versions that pass
 * all requests to the underlying output stream. Subclasses of
 * <code>FilterOutputStream</code> may further override some of these
 * methods as well as provide additional methods and fields.
 *
 * @author  Jonathan Payne
 * @since   1.0
 */
class FilterOutputStream : OutputStream {
    /**
     * The underlying output stream to be filtered.
     */
    protected OutputStream outputStream;

    /**
     * Whether the stream is closed; implicitly initialized to false.
     */
    private bool closed;

    /**
     * Object used to prevent a race on the 'closed' instance variable.
     */
    private Object closeLock;

    /**
     * Creates an output stream filter built on top of the specified
     * underlying output stream.
     *
     * @param   outputStream   the underlying output stream to be assigned to
     *                the field {@code this.outputStream} for later use, or
     *                <code>null</code> if this instance is to be
     *                created without an underlying stream.
     */
    this(OutputStream outputStream) {
        this.outputStream = outputStream;
        closeLock = new Object();
    }

    /**
     * Writes the specified <code>byte</code> to this output stream.
     * <p>
     * The <code>write</code> method of <code>FilterOutputStream</code>
     * calls the <code>write</code> method of its underlying output stream,
     * that is, it performs {@code outputStream.write(b)}.
     * <p>
     * Implements the abstract {@code write} method of {@code OutputStream}.
     *
     * @param      b   the <code>byte</code>.
     * @exception  IOException  if an I/O error occurs.
     */
    override
    void write(int b) {
        outputStream.write(b);
    }

    /**
     * Writes <code>b.length</code> bytes to this output stream.
     * <p>
     * The <code>write</code> method of <code>FilterOutputStream</code>
     * calls its <code>write</code> method of three arguments with the
     * arguments <code>b</code>, <code>0</code>, and
     * <code>b.length</code>.
     * <p>
     * Note that this method does not call the one-argument
     * <code>write</code> method of its underlying output stream with
     * the single argument <code>b</code>.
     *
     * @param      b   the data to be written.
     * @exception  IOException  if an I/O error occurs.
     * @see        java.io.FilterOutputStream#write(byte[], int, int)
     */
    override
    void write(byte[] b) {
        write(b, 0, cast(int)b.length);
    }

    /**
     * Writes <code>len</code> bytes from the specified
     * <code>byte</code> array starting at offset <code>off</code> to
     * this output stream.
     * <p>
     * The <code>write</code> method of <code>FilterOutputStream</code>
     * calls the <code>write</code> method of one argument on each
     * <code>byte</code> to output.
     * <p>
     * Note that this method does not call the <code>write</code> method
     * of its underlying output stream with the same arguments. Subclasses
     * of <code>FilterOutputStream</code> should provide a more efficient
     * implementation of this method.
     *
     * @param      b     the data.
     * @param      off   the start offset in the data.
     * @param      len   the number of bytes to write.
     * @exception  IOException  if an I/O error occurs.
     * @see        java.io.FilterOutputStream#write(int)
     */
    override
    void write(byte[] b, int off, int len) {
        if ((off | len | (b.length - (len + off)) | (off + len)) < 0)
            throw new IndexOutOfBoundsException();

        for (int i = 0 ; i < len ; i++) {
            write(b[off + i]);
        }
    }

    /**
     * Flushes this output stream and forces any buffered output bytes
     * to be written out to the stream.
     * <p>
     * The <code>flush</code> method of <code>FilterOutputStream</code>
     * calls the <code>flush</code> method of its underlying output stream.
     *
     * @exception  IOException  if an I/O error occurs.
     * @see        java.io.FilterOutputStream#outputStream
     */
    override
    void flush() {
        outputStream.flush();
    }

    /**
     * Closes this output stream and releases any system resources
     * associated with the stream.
     * <p>
     * When not already closed, the {@code close} method of {@code
     * FilterOutputStream} calls its {@code flush} method, and then
     * calls the {@code close} method of its underlying output stream.
     *
     * @exception  IOException  if an I/O error occurs.
     * @see        java.io.FilterOutputStream#flush()
     * @see        java.io.FilterOutputStream#outputStream
     */
    override
    void close() {
        if (closed) {
            return;
        }
        synchronized (closeLock) {
            if (closed) {
                return;
            }
            closed = true;
        }

        Throwable flushException = null;
        try {
            flush();
        } catch (Throwable e) {
            flushException = e;
            throw e;
        } finally {
            outputStream.close();            
        }
    }
}
