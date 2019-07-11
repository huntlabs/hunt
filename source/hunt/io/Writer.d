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

module hunt.io.Writer;

import hunt.Exceptions;
import hunt.util.Common;

import std.algorithm;
import std.array;
import std.exception;
import std.conv;
import std.string;

/**
*/
class Writer : Appendable, Closeable, Flushable {

    /**
     * Temporary buffer used to hold writes of strings and single characters
     */
    private byte[] writeBuffer;

    /**
     * Size of writeBuffer, must be >= 1
     */
    private enum int WRITE_BUFFER_SIZE = 1024;


    /**
     * The object used to synchronize operations on this stream.  For
     * efficiency, a character-stream object may use an object other than
     * itself to protect critical sections.  A subclass should therefore use
     * the object in this field rather than {@code this} or a synchronized
     * method.
     */
    protected Object lock;

    /**
     * Creates a new character-stream writer whose critical sections will
     * synchronize on the writer itself.
     */
    protected this() {
        this.lock = this;
    }

    /**
     * Creates a new character-stream writer whose critical sections will
     * synchronize on the given object.
     *
     * @param  lock
     *         Object to synchronize on
     */
    protected this(Object lock) {
        if (lock is null) {
            throw new NullPointerException();
        }
        this.lock = lock;
    }

    /**
     * Writes a single character.  The character to be written is contained in
     * the 16 low-order bits of the given integer value; the 16 high-order bits
     * are ignored.
     *
     * <p> Subclasses that intend to support efficient single-character output
     * should override this method.
     *
     * @param  c
     *         int specifying a character to be written
     *
     * @throws  IOException
     *          If an I/O error occurs
     */
    void write(int c) {
        synchronized (lock) {
            write([cast(byte) c]);
        }
    }

    /**
     * Writes an array of characters.
     *
     * @param  cbuf
     *         Array of characters to be written
     *
     * @throws  IOException
     *          If an I/O error occurs
     */
    void write(byte[] cbuf) {
        write(cbuf, 0, cast(int)cbuf.length);
    }

    /**
     * Writes a portion of an array of characters.
     *
     * @param  cbuf
     *         Array of characters
     *
     * @param  off
     *         Offset from which to start writing characters
     *
     * @param  len
     *         Number of characters to write
     *
     * @throws  IndexOutOfBoundsException
     *          Implementations should throw this exception
     *          if {@code off} is negative, or {@code len} is negative,
     *          or {@code off + len} is negative or greater than the length
     *          of the given array
     *
     * @throws  IOException
     *          If an I/O error occurs
     */
    abstract void write(byte[] cbuf, int off, int len);

    /**
     * Writes a string.
     *
     * @param  str
     *         string to be written
     *
     * @throws  IOException
     *          If an I/O error occurs
     */
    void write(string str) {
        write(cast(byte[])str);
    }

    /**
     * Writes a portion of a string.
     *
     * @implSpec
     * The implementation in this class throws an
     * {@code IndexOutOfBoundsException} for the indicated conditions;
     * overriding methods may choose to do otherwise.
     *
     * @param  str
     *         A string
     *
     * @param  off
     *         Offset from which to start writing characters
     *
     * @param  len
     *         Number of characters to write
     *
     * @throws  IndexOutOfBoundsException
     *          Implementations should throw this exception
     *          if {@code off} is negative, or {@code len} is negative,
     *          or {@code off + len} is negative or greater than the length
     *          of the given string
     *
     * @throws  IOException
     *          If an I/O error occurs
     */
    void write(string str, int off, int len) {
        synchronized (lock) {
            write(cast(byte[])str[off .. off + len]);
        }
    }


    /**
     * Appends the specified character sequence to this writer.
     *
     * <p> An invocation of this method of the form {@code out.append(csq)}
     * behaves in exactly the same way as the invocation
     *
     * <pre>
     *     out.write(csq.toString()) </pre>
     *
     * <p> Depending on the specification of {@code toString} for the
     * character sequence {@code csq}, the entire sequence may not be
     * appended. For instance, invoking the {@code toString} method of a
     * character buffer will return a subsequence whose content depends upon
     * the buffer's position and limit.
     *
     * @param  csq
     *         The character sequence to append.  If {@code csq} is
     *         {@code null}, then the four characters {@code "null"} are
     *         appended to this writer.
     *
     * @return  This writer
     *
     * @throws  IOException
     *          If an I/O error occurs
     *
     * @since  1.5
     */
    Writer append(const(char)[] csq) {
        write(cast(string)csq);
        return this;
    }

    /**
     * Appends a subsequence of the specified character sequence to this writer.
     * {@code Appendable}.
     *
     * <p> An invocation of this method of the form
     * {@code out.append(csq, start, end)} when {@code csq}
     * is not {@code null} behaves in exactly the
     * same way as the invocation
     *
     * <pre>{@code
     *     out.write(csq.subSequence(start, end).toString())
     * }</pre>
     *
     * @param  csq
     *         The character sequence from which a subsequence will be
     *         appended.  If {@code csq} is {@code null}, then characters
     *         will be appended as if {@code csq} contained the four
     *         characters {@code "null"}.
     *
     * @param  start
     *         The index of the first character in the subsequence
     *
     * @param  end
     *         The index of the character following the last character in the
     *         subsequence
     *
     * @return  This writer
     *
     * @throws  IndexOutOfBoundsException
     *          If {@code start} or {@code end} are negative, {@code start}
     *          is greater than {@code end}, or {@code end} is greater than
     *          {@code csq.length()}
     *
     * @throws  IOException
     *          If an I/O error occurs
     *
     * @since  1.5
     */
    Writer append(const(char)[] csq, int start, int end) {
        if (csq.empty()) csq = "null";
        return append(csq[start .. end]);
    }


    /**
     * Appends the specified character to this writer.
     *
     * <p> An invocation of this method of the form {@code out.append(c)}
     * behaves in exactly the same way as the invocation
     *
     * <pre>
     *     out.write(c) </pre>
     *
     * @param  c
     *         The 16-bit character to append
     *
     * @return  This writer
     *
     * @throws  IOException
     *          If an I/O error occurs
     */
    Writer append(char c) {
        write(c);
        return this;
    }

    /**
     * Flushes the stream.  If the stream has saved any characters from the
     * various write() methods in a buffer, write them immediately to their
     * intended destination.  Then, if that destination is another character or
     * byte stream, flush it.  Thus one flush() invocation will flush all the
     * buffers in a chain of Writers and OutputStreams.
     *
     * <p> If the intended destination of this stream is an abstraction provided
     * by the underlying operating system, for example a file, then flushing the
     * stream guarantees only that bytes previously written to the stream are
     * passed to the operating system for writing; it does not guarantee that
     * they are actually written to a physical device such as a disk drive.
     *
     * @throws  IOException
     *          If an I/O error occurs
     */
    abstract void flush();

    /**
     * Closes the stream, flushing it first. Once the stream has been closed,
     * further write() or flush() invocations will cause an IOException to be
     * thrown. Closing a previously closed stream has no effect.
     *
     * @throws  IOException
     *          If an I/O error occurs
     */
    abstract void close();
}


/**
 * Returns a new {@code Writer} which discards all characters.  The
 * returned stream is initially open.  The stream is closed by calling
 * the {@code close()} method.  Subsequent calls to {@code close()} have
 * no effect.
 *
 * <p> While the stream is open, the {@code append(char)}, {@code
 * append(CharSequence)}, {@code append(CharSequence, int, int)},
 * {@code flush()}, {@code write(int)}, {@code write(char[])}, and
 * {@code write(char[], int, int)} methods do nothing. After the stream
 * has been closed, these methods all throw {@code IOException}.
 *
 * <p> The {@link #lock object} used to synchronize operations on the
 * returned {@code Writer} is not specified.
 *
 * @return a {@code Writer} which discards all characters
 *
 */
class NullWriter : Writer {
    private shared bool closed;

    private void ensureOpen() {
        if (closed) {
            throw new IOException("Stream closed");
        }
    }

    
    override Writer append(char c) {
        ensureOpen();
        return this;
    }

    override void write(int c) {
        ensureOpen();
    }

    override void write(byte[] cbuf, int off, int len) {
        assert(off+len <= cbuf.length);
        ensureOpen();
    }

    
    override void write(string str) {
        assert(!str.empty());
        ensureOpen();
    }

    
    override void write(string str, int off, int len) {
        assert(off+len <= str.length);
        ensureOpen();
    }

    
    override void flush() {
        ensureOpen();
    }

    
    override void close() {
        closed = true;
    }
}

/**
    Helper for Writer to create a null writer.*/
Writer nullWriter() {
    return new NullWriter();
}
