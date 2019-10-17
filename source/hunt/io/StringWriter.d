module hunt.io.StringWriter;

import hunt.Exceptions;
import hunt.util.Common;
import hunt.io.Writer;

import std.algorithm;
import std.array;
import std.exception;
import std.conv;
import std.string;



/**
 * A character stream that collects its output in a string buffer, which can
 * then be used to construct a string.
 * <p>
 * Closing a {@code StringWriter} has no effect. The methods in this class
 * can be called after the stream has been closed without generating an
 * {@code IOException}.
 *
 * @author      Mark Reinhold
 */

class StringWriter : Writer {

    private Appender!(string) buf;

    /**
     * Create a new string writer using the default initial string-buffer
     * size.
     */
    this() {
        buf.reserve(1024);
        lock = this;
    }

    /**
     * Create a new string writer using the specified initial string-buffer
     * size.
     *
     * @param initialSize
     *        The number of {@code char} values that will fit into this buffer
     *        before it is automatically expanded
     *
     * @throws IllegalArgumentException
     *         If {@code initialSize} is negative
     */
    this(int initialSize) {
        if (initialSize < 0) {
            throw new IllegalArgumentException("Negative buffer size");
        }
        buf.reserve(initialSize);
        lock = this;
    }

    /**
     * Write a single character.
     */
    override void write(int c) {
        buf.put(to!string(cast(char)c));
    }

    /**
     * Write a portion of an array of characters.
     *
     * @param  cbuf  Array of characters
     * @param  off   Offset from which to start writing characters
     * @param  len   Number of characters to write
     *
     * @throws  IndexOutOfBoundsException
     *          If {@code off} is negative, or {@code len} is negative,
     *          or {@code off + len} is negative or greater than the length
     *          of the given array
     */
    override void write(byte[] cbuf, int off, int len) {
        if ((off < 0) || (off > cbuf.length) || (len < 0) ||
            ((off + len) > cbuf.length) || ((off + len) < 0)) {
            throw new IndexOutOfBoundsException();
        } else if (len == 0) {
            return;
        }
        buf.put(cast(string)cbuf[off .. off+ len]);
    }

    /**
     * Write a string.
     */
    override void write(string str) {
        buf.put(str);
    }

    /**
     * Write a portion of a string.
     *
     * @param  str  string to be written
     * @param  off  Offset from which to start writing characters
     * @param  len  Number of characters to write
     *
     * @throws  IndexOutOfBoundsException
     *          If {@code off} is negative, or {@code len} is negative,
     *          or {@code off + len} is negative or greater than the length
     *          of the given string
     */
    override void write(string str, int off, int len) {
        buf.put(str[off .. off+ len]);
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
     */
    override StringWriter append(char c) {
        write(c);
        return this;
    }

    /**
     * Return the buffer's current value as a string.
     */
    override string toString() {
        return buf.data;
    }

    /**
     * Return the string buffer itself.
     *
     * @return StringBuffer holding the current buffer value.
     */
    ref Appender!(string) getBuffer() {
        return buf;
    }

    /**
     * Flush the stream.
     */
    override void flush() {
    }

    /**
     * Closing a {@code StringWriter} has no effect. The methods in this
     * class can be called after the stream has been closed without generating
     * an {@code IOException}.
     */
    override void close() {
    }

}
