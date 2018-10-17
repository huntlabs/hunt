module hunt.container.Buffer;

import hunt.lang.exception;

import std.conv;

abstract class Buffer
{
    // Invariants: mark <= position <= limit <= capacity
    private int _mark = -1;
    private int _position = 0;
    private int _limit;
    private int _capacity;

    // Creates a new buffer with the given mark, position, limit, and capacity,
    // after checking invariants.
    //
    this(int mark, int pos, int lim, int cap) {       // package-private
        if (cap < 0)
            throw new IllegalArgumentException("Negative capacity: " ~ to!string(cap));
        this._capacity = cap;
        limit(lim);
        position(pos);
        if (mark >= 0) {
            if (mark > pos)
                throw new IllegalArgumentException("mark > position: ("
                                                   ~ to!string( mark) ~ " > " ~ to!string(pos) ~ ")");
            this._mark = mark;
        }
    }

    /**
     * Returns this buffer's capacity.
     *
     * @return  The capacity of this buffer
     */
    final int capacity() {
        return _capacity;
    }

    /**
     * Returns this buffer's position.
     *
     * @return  The position of this buffer
     */
    final int position() {
        return _position;
    }

    /**
     * Sets this buffer's position.  If the mark is defined and larger than the
     * new position then it is discarded.
     *
     * @param  newPosition
     *         The new position value; must be non-negative
     *         and no larger than the current limit
     *
     * @return  This buffer
     *
     * @throws  IllegalArgumentException
     *          If the preconditions on <tt>newPosition</tt> do not hold
     */
    final Buffer position(int newPosition) {
        if ((newPosition > _limit) || (newPosition < 0))
            throw new IllegalArgumentException("");
        _position = newPosition;
        if (_mark > _position) _mark = -1;
        return this;
    }

    /**
     * Returns this buffer's limit.
     *
     * @return  The limit of this buffer
     */
    final int limit() {
        return _limit;
    }

    /**
     * Sets this buffer's limit.  If the position is larger than the new limit
     * then it is set to the new limit.  If the mark is defined and larger than
     * the new limit then it is discarded.
     *
     * @param  newLimit
     *         The new limit value; must be non-negative
     *         and no larger than this buffer's capacity
     *
     * @return  This buffer
     *
     * @throws  IllegalArgumentException
     *          If the preconditions on <tt>newLimit</tt> do not hold
     */
    final Buffer limit(int newLimit) {
        if ((newLimit > _capacity) || (newLimit < 0))
            throw new IllegalArgumentException("");
        _limit = newLimit;
        if (_position > _limit) _position = _limit;
        if (_mark > _limit) _mark = -1;
        return this;
    }

    /**
     * Sets this buffer's mark at its position.
     *
     * @return  This buffer
     */
    final Buffer mark() {
        _mark = _position;
        return this;
    }

    /**
     * Resets this buffer's position to the previously-marked position.
     *
     * <p> Invoking this method neither changes nor discards the mark's
     * value. </p>
     *
     * @return  This buffer
     *
     * @throws  InvalidMarkException
     *          If the mark has not been set
     */
    final Buffer reset() {
        int m = _mark;
        if (m < 0)
            throw new InvalidMarkException("");
        _position = m;
        return this;
    }

    /**
     * Clears this buffer.  The position is set to zero, the limit is set to
     * the capacity, and the mark is discarded.
     *
     * <p> Invoke this method before using a sequence of channel-read or
     * <i>put</i> operations to fill this buffer.  For example:
     *
     * <blockquote><pre>
     * buf.clear();     // Prepare buffer for reading
     * in.read(buf);    // Read data</pre></blockquote>
     *
     * <p> This method does not actually erase the data in the buffer, but it
     * is named as if it did because it will most often be used in situations
     * in which that might as well be the case. </p>
     *
     * @return  This buffer
     */
    final Buffer clear() {
        _position = 0;
        _limit = _capacity;
        _mark = -1;
        return this;
    }

    /**
     * Flips this buffer.  The limit is set to the current position and then
     * the position is set to zero.  If the mark is defined then it is
     * discarded.
     *
     * <p> After a sequence of channel-read or <i>put</i> operations, invoke
     * this method to prepare for a sequence of channel-write or relative
     * <i>get</i> operations.  For example:
     *
     * <blockquote><pre>
     * buf.put(magic);    // Prepend header
     * in.read(buf);      // Read data into rest of buffer
     * buf.flip();        // Flip buffer
     * out.write(buf);    // Write header + data to channel</pre></blockquote>
     *
     * <p> This method is often used in conjunction with the {@link
     * java.nio.ByteBuffer#compact compact} method when transferring data from
     * one place to another.  </p>
     *
     * @return  This buffer
     */
    final Buffer flip() {
        _limit = _position;
        _position = 0;
        _mark = -1;
        return this;
    }

    /**
     * Rewinds this buffer.  The position is set to zero and the mark is
     * discarded.
     *
     * <p> Invoke this method before a sequence of channel-write or <i>get</i>
     * operations, assuming that the limit has already been set
     * appropriately.  For example:
     *
     * <blockquote><pre>
     * out.write(buf);    // Write remaining data
     * buf.rewind();      // Rewind buffer
     * buf.get(array);    // Copy data into array</pre></blockquote>
     *
     * @return  This buffer
     */
    final Buffer rewind() {
        _position = 0;
        _mark = -1;
        return this;
    }

    /**
     * Returns the number of elements between the current position and the
     * limit.
     *
     * @return  The number of elements remaining in this buffer
     */
    final int remaining() {
        return _limit - _position;
    }

    /**
     * Tells whether there are any elements between the current position and
     * the limit.
     *
     * @return  <tt>true</tt> if, and only if, there is at least one element
     *          remaining in this buffer
     */
    final bool hasRemaining() {
        return _position < _limit;
    }

    /**
     * Tells whether or not this buffer is read-only.
     *
     * @return  <tt>true</tt> if, and only if, this buffer is read-only
     */
    abstract bool isReadOnly();

    /**
     * Tells whether or not this buffer is backed by an accessible
     * array.
     *
     * <p> If this method returns <tt>true</tt> then the {@link #array() array}
     * and {@link #arrayOffset() arrayOffset} methods may safely be invoked.
     * </p>
     *
     * @return  <tt>true</tt> if, and only if, this buffer
     *          is backed by an array and is not read-only
     *
     * @since 1.6
     */
    abstract bool hasArray();

    /**
     * Returns the array that backs this
     * buffer&nbsp;&nbsp;<i>(optional operation)</i>.
     *
     * <p> This method is intended to allow array-backed buffers to be
     * passed to native code more efficiently. Concrete subclasses
     * provide more strongly-typed return values for this method.
     *
     * <p> Modifications to this buffer's content will cause the returned
     * array's content to be modified, and vice versa.
     *
     * <p> Invoke the {@link #hasArray hasArray} method before invoking this
     * method in order to ensure that this buffer has an accessible backing
     * array.  </p>
     *
     * @return  The array that backs this buffer
     *
     * @throws  ReadOnlyBufferException
     *          If this buffer is backed by an array but is read-only
     *
     * @throws  UnsupportedOperationException
     *          If this buffer is not backed by an accessible array
     *
     * @since 1.6
     */
    // abstract Object array();

    /**
     * Returns the offset within this buffer's backing array of the first
     * element of the buffer&nbsp;&nbsp;<i>(optional operation)</i>.
     *
     * <p> If this buffer is backed by an array then buffer position <i>p</i>
     * corresponds to array index <i>p</i>&nbsp;+&nbsp;<tt>arrayOffset()</tt>.
     *
     * <p> Invoke the {@link #hasArray hasArray} method before invoking this
     * method in order to ensure that this buffer has an accessible backing
     * array.  </p>
     *
     * @return  The offset within this buffer's array
     *          of the first element of the buffer
     *
     * @throws  ReadOnlyBufferException
     *          If this buffer is backed by an array but is read-only
     *
     * @throws  UnsupportedOperationException
     *          If this buffer is not backed by an accessible array
     *
     * @since 1.6
     */
    abstract int arrayOffset();

    /**
     * Tells whether or not this buffer is
     * <a href="ByteBuffer.html#direct"><i>direct</i></a>.
     *
     * @return  <tt>true</tt> if, and only if, this buffer is direct
     *
     * @since 1.6
     */
    abstract bool isDirect();


    // -- Package-private methods for bounds checking, etc. --

    /**
     * Checks the current position against the limit, throwing a {@link
     * BufferUnderflowException} if it is not smaller than the limit, and then
     * increments the position.
     *
     * @return  The current position value, before it is incremented
     */
    final int nextGetIndex() {                          // package-private
        if (_position >= _limit)
            throw new BufferUnderflowException("");
        return _position++;
    }

    final int nextGetIndex(int nb) {                    // package-private
        if (_limit - _position < nb)
            throw new BufferUnderflowException("");
        int p = _position;
        _position += nb;
        return p;
    }

    /**
     * Checks the current position against the limit, throwing a {@link
     * BufferOverflowException} if it is not smaller than the limit, and then
     * increments the position.
     *
     * @return  The current position value, before it is incremented
     */
    final int nextPutIndex() {                          // package-private
        if (_position >= _limit)
            throw new BufferOverflowException("");
        return _position++;
    }

    final int nextPutIndex(int nb) {                    // package-private
        if (_limit - _position < nb)
            throw new BufferOverflowException("");
        int p = _position;
        _position += nb;
        return p;
    }

    /**
     * Checks the given index against the limit, throwing an {@link
     * IndexOutOfBoundsException} if it is not smaller than the limit
     * or is smaller than zero.
     */
    final int checkIndex(int i) {                       // package-private
        if ((i < 0) || (i >= _limit))
            throw new IndexOutOfBoundsException("");
        return i;
    }

    final int checkIndex(int i, int nb) {               // package-private
        if ((i < 0) || (nb > _limit - i))
            throw new IndexOutOfBoundsException("");
        return i;
    }

    final int markValue() {                             // package-private
        return _mark;
    }

    final void truncate() {                             // package-private
        _mark = -1;
        _position = 0;
        _limit = 0;
        _capacity = 0;
    }

    final void discardMark() {                          // package-private
        _mark = -1;
    }

    static void checkBounds(int off, int len, int size) { // package-private
        if ((off | len | (off + len) | (size - (off + len))) < 0)
            throw new IndexOutOfBoundsException("");
    }
}