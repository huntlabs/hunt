module hunt.collection.HeapByteBuffer;

import hunt.collection.ByteBuffer;
import hunt.Exceptions;

import hunt.Integer;
import hunt.Long;
import hunt.Short;

import std.format;

/**
*/
class HeapByteBuffer : ByteBuffer {

    // For speed these fields are actually declared in X-Buffer;
    // these declarations are here as documentation

    this(int cap, int lim) { // package-private

        super(-1, 0, lim, cap, new byte[cap], 0);
        /*
        hb = new byte[cap];
        offset = 0;
        */
    }

    this(byte[] buf, int off, int len) { // package-private

        super(-1, off, off + len, cast(int) buf.length, buf, 0);
        /*
        hb = buf;
        offset = 0;
        */
    }

    protected this(byte[] buf, int mark, int pos, int lim, int cap, int off) {

        super(mark, pos, lim, cap, buf, off);
        /*
        hb = buf;
        offset = off;
        */

    }

    override ByteBuffer slice() {
        return new HeapByteBuffer(hb, -1, 0, this.remaining(),
                this.remaining(), this.position() + offset);
    }

    override ByteBuffer duplicate() {
        return new HeapByteBuffer(hb, this.markValue(), this.position(),
                this.limit(), this.capacity(), offset);
    }

    override ByteBuffer asReadOnlyBuffer() {
        return new HeapByteBuffer(hb, this.markValue(), this.position(),
                this.limit(), this.capacity(), offset);
    }

    override byte get() {
        return hb[ix(nextGetIndex())];
    }

    override byte get(int i) {
        return hb[ix(checkIndex(i))];
    }

    override ByteBuffer get(byte[] dst, int offset, int length) {
        checkBounds(offset, length, cast(int) dst.length);
        if (length > remaining())
            throw new BufferUnderflowException("");
        // System.arraycopy(hb, ix(position()), dst, offset, length);
        int sourcePos = ix(position());
        dst[offset .. offset + length] = hb[sourcePos .. sourcePos + length];
        position(position() + length);
        return this;
    }

    override bool isDirect() {
        return false;
    }

    override bool isReadOnly() {
        return false;
    }

    override ByteBuffer put(byte x) {

        hb[ix(nextPutIndex())] = x;
        return this;

    }

    override ByteBuffer put(int i, byte x) {
        hb[ix(checkIndex(i))] = x;
        return this;
    }

    override ByteBuffer put(byte[] src, int offset, int length) {

        checkBounds(offset, length, cast(int) src.length);

        if (length > remaining())
            throw new BufferOverflowException();
        int newPos = ix(position());
        hb[newPos .. newPos + length] = src[offset .. offset + length];

        position(position() + length);
        return this;

    }

    override ByteBuffer put(ByteBuffer src) {
        if (typeid(src) == typeid(HeapByteBuffer)) {
            if (src is this)
                throw new IllegalArgumentException();
            HeapByteBuffer sb = cast(HeapByteBuffer) src;
            int n = sb.remaining();
            int r = this.remaining();
            if (n > r)
                throw new BufferOverflowException(format("soure remaining: %d, this remaining: %d", n, r));

            int sourcePos = sb.ix(sb.position());
            int targetPos = ix(position());
            hb[targetPos .. targetPos + n] = sb.hb[sourcePos .. sourcePos + n];

            sb.position(sb.position() + n);
            position(position() + n);
        } else if (src.isDirect()) {
            int n = src.remaining();
            if (n > remaining())
                throw new BufferOverflowException("");
            src.get(hb, ix(position()), n);
            position(position() + n);
        } else {
            super.put(src);
        }
        return this;

    }

    // short

    private static byte short1(short x) {
        return cast(byte)(x >> 8);
    }

    private static byte short0(short x) {
        return cast(byte)(x);
    }

    override short getShort() {
        int index = ix(nextGetIndex(2));
        // short r = 0;
        // short* ptr = &r;
        // ptr[0]=hb[index+1]; // bigEndian
        // ptr[1]=hb[index]; 
        // if (bigEndian)
        //     return makeShort(hb[index], hb[index + 1]);
        // else
        //     return makeShort(hb[index + 1], hb[index]);

        return convEndian(bigEndian, makeShort(hb[index], hb[index + 1]));
    }

    override short getShort(int i) {
        int index = ix(checkIndex(i, 2));
        return convEndian(bigEndian, makeShort(hb[index], hb[index + 1]));
        // if (bigEndian)
        //     return makeShort(hb[index], hb[index + 1]);
        // else
        //     return makeShort(hb[index + 1], hb[index]);
    }

    override ByteBuffer putShort(short x) {
        int index = ix(nextPutIndex(2));
        if (bigEndian) {
            hb[index] = short1(x);
            hb[index + 1] = short0(x);
        } else {
            hb[index] = short0(x);
            hb[index + 1] = short1(x);
        }

        return this;
    }

    override ByteBuffer putShort(int i, short x) {
        int index = ix(checkIndex(i, 2));
        if (bigEndian) {
            hb[index] = short1(x);
            hb[index + 1] = short0(x);
        } else {
            hb[index] = short0(x);
            hb[index + 1] = short1(x);
        }
        return this;
    }

    // int
    override int getInt() {
        // auto index = ix(nextGetIndex(4));
        // return _getInt(index);
        return getIntUnaligned(hb, byteOffset(nextGetIndex(4)), bigEndian);
    }

    override int getInt(int i) {
        // auto index = ix(checkIndex(i, 4));
        // return _getInt(index);
        return getIntUnaligned(hb, byteOffset(checkIndex(i, 4)), bigEndian);
    }

    // private int _getInt(size_t index) {
    //     if (bigEndian)
    //         return makeInt(hb[index], hb[index + 1], hb[index + 2], hb[index + 3]);
    //     else
    //         return makeInt(hb[index + 3], hb[index + 2], hb[index + 1], hb[index]);
    // }

    // private static int makeInt(byte b3, byte b2, byte b1, byte b0) {
    //     return ((b3) << 24) | ((b2 & 0xff) << 16) | ((b1 & 0xff) << 8) | (b0 & 0xff);
    // }

    override ByteBuffer putInt(int x) {
        putIntUnaligned(hb, ix(nextPutIndex(4)), x, bigEndian);
        return this;
    }

    override ByteBuffer putInt(int i, int x) {
        putIntUnaligned(hb, ix(checkIndex(i, 4)), x, bigEndian);
        return this;
    }

    // long

    override long getLong() {
        return getLongUnaligned(hb, ix(nextGetIndex(8)), bigEndian);
    }

    override long getLong(int i) {
        return getLongUnaligned(hb, ix(checkIndex(i, 8)), bigEndian);
    }

    override ByteBuffer putLong(long x) {
        putLongUnaligned(hb, ix(nextPutIndex(8)), x, bigEndian);
        return this;
    }

    override ByteBuffer putLong(int i, long x) {
        putLongUnaligned(hb, ix(checkIndex(i, 8)), x, bigEndian);
        return this;
    }

    // dfmt off


    private static void putShortParts(byte[] buf, size_t offset, byte i0, byte i1) {
        buf[offset + 0] = pick(i0, i1);
        buf[offset + 1] = pick(i1, i0);
    }

    private static void putIntParts(byte[] buf, size_t offset, short i0, short i1) {
        _putShort(buf, offset + 0, pick(i0, i1));
        _putShort(buf, offset + 2, pick(i1, i0));
    }

    private static void putIntParts(byte[] buf, size_t offset, byte i0, byte i1, byte i2, byte i3) {
        buf[offset + 0] = pick(i0, i3);
        buf[offset + 1] = pick(i1, i2);
        buf[offset + 2] = pick(i2, i1);
        buf[offset + 3] = pick(i3, i0);
    }
    
    private static void putIntUnaligned(byte[] buf, size_t offset, int x) {
        if ((offset & 3) == 0) {
            _putInt(buf, offset, x);
        } else if ((offset & 1) == 0) {
            putIntParts(buf, offset,
                        cast(short)(x >> 0),
                        cast(short)(x >>> 16));
        } else {
            putIntParts(buf, offset,
                        cast(byte)(x >>> 0),
                        cast(byte)(x >>> 8),
                        cast(byte)(x >>> 16),
                        cast(byte)(x >>> 24));
        }
    }

    private static void putIntUnaligned(byte[] buf, size_t offset, int x, bool bigEndian) {
        putIntUnaligned(buf, offset, convEndian(bigEndian, x));
    }


    private static int getIntUnaligned(byte[] buf, size_t offset) {
        if ((offset & 3) == 0) {
            return _getInt(buf, offset);
        } else if ((offset & 1) == 0) {
            return makeInt(_getShort(buf, offset),
                           _getShort(buf, offset + 2));
        } else {
            return makeInt(buf[offset],
                           buf[offset + 1],
                           buf[offset + 2],
                           buf[offset + 3]);
        }
    }

    private static int getIntUnaligned(byte[] buf, size_t offset, bool bigEndian) {
        return convEndian(bigEndian, getIntUnaligned(buf, offset));
    }    

    /**
     * Fetches a value at some byte offset into a given Java object.
     * More specifically, fetches a value within the given object
     * <code>o</code> at the given offset, or (if <code>o</code> is
     * null) from the memory address whose numerical value is the
     * given offset.  <p>
     *
     * The specification of this method is the same as {@link
     * #getLong(Object, long)} except that the offset does not need to
     * have been obtained from {@link #objectFieldOffset} on the
     * {@link java.lang.reflect.Field} of some Java field.  The value
     * in memory is raw data, and need not correspond to any Java
     * variable.  Unless <code>o</code> is null, the value accessed
     * must be entirely within the allocated object.  The endianness
     * of the value in memory is the endianness of the native platform.
     *
     * <p> The read will be atomic with respect to the largest power
     * of two that divides the GCD of the offset and the storage size.
     * For example, getLongUnaligned will make atomic reads of 2-, 4-,
     * or 8-byte storage units if the offset is zero mod 2, 4, or 8,
     * respectively.  There are no other guarantees of atomicity.
     * <p>
     * 8-byte atomicity is only guaranteed on platforms on which
     * support atomic accesses to longs.
     *
     * @param o Java heap object in which the value resides, if any, else
     *        null
     * @param offset The offset in bytes from the start of the object
     * @return the value fetched from the indicated object
     * @throws RuntimeException No defined exceptions are thrown, not even
     *         {@link NullPointerException}
     */
    private static long getLongUnaligned(byte[] buf, size_t offset) {
        if ((offset & 7) == 0) {
            return _getLong(buf, offset);
        } else if ((offset & 3) == 0) {
            return makeLong(_getInt(buf, offset),
                            _getInt(buf, offset + 4));
        } else if ((offset & 1) == 0) {
            return makeLong(_getShort(buf, offset),
                            _getShort(buf, offset + 2),
                            _getShort(buf, offset + 4),
                            _getShort(buf, offset + 6));
        } else {
            return makeLong(buf[offset],
                            buf[offset + 1],
                            buf[offset + 2],
                            buf[offset + 3],
                            buf[offset + 4],
                            buf[offset + 5],
                            buf[offset + 6],
                            buf[offset + 7]);
        }
    }

    /**
     * As {@link #getLongUnaligned(Object, long)} but with an
     * additional argument which specifies the endianness of the value
     * as stored in memory.
     *
     * @param o Java heap object in which the variable resides
     * @param offset The offset in bytes from the start of the object
     * @param bigEndian The endianness of the value
     * @return the value fetched from the indicated object
     */
    private static long getLongUnaligned(byte[] hb,  size_t offset, bool bigEndian) {
        return convEndian(bigEndian, getLongUnaligned(hb, offset));
    }

    /**
     * As {@link #putLongUnaligned(Object, long, long)} but with an additional
     * argument which specifies the endianness of the value as stored in memory.
     * @param o Java heap object in which the value resides
     * @param offset The offset in bytes from the start of the object
     * @param x the value to store
     * @param bigEndian The endianness of the value
     * @throws RuntimeException No defined exceptions are thrown, not even
     *         {@link NullPointerException}
     */
    private static void putLongUnaligned(byte[] buf, size_t offset, long x, bool bigEndian) {
        putLongUnaligned(buf, offset, convEndian(bigEndian, x));
    }

    // These methods write integers to memory from smaller parts
    // provided by their caller.  The ordering in which these parts
    // are written is the native endianness of this platform.
    private static void putLongParts(byte[] buf, size_t offset, byte i0, byte i1, byte i2, 
        byte i3, byte i4, byte i5, byte i6, byte i7) {
        buf[offset + 0] = pick(i0, i7);
        buf[offset + 1] = pick(i1, i6);
        buf[offset + 2] = pick(i2, i5);
        buf[offset + 3] = pick(i3, i4);
        buf[offset + 4] = pick(i4, i3);
        buf[offset + 5] = pick(i5, i2);
        buf[offset + 6] = pick(i6, i1);
        buf[offset + 7] = pick(i7, i0);
    }

    private static void putLongParts(byte[] buf, size_t offset, short i0, short i1, short i2, short i3) {
        _putShort(buf, offset + 0, pick(i0, i3));
        _putShort(buf, offset + 2, pick(i1, i2));
        _putShort(buf, offset + 4, pick(i2, i1));
        _putShort(buf, offset + 6, pick(i3, i0));
    }

    private static void putLongParts(byte[] buf, size_t offset, int i0, int i1) {
        _putInt(buf, offset + 0, pick(i0, i1));
        _putInt(buf, offset + 4, pick(i1, i0));
    }

    private static void putLongUnaligned(byte[] hb, size_t offset, long x) {
        if ((offset & 7) == 0) {
            _putLong(hb, offset, x);
        } else if ((offset & 3) == 0) {
            putLongParts(hb, offset,
                         cast(int)(x >> 0),
                         cast(int)(x >>> 32));
        } else if ((offset & 1) == 0) {
            putLongParts(hb, offset,
                         cast(short)(x >>> 0),
                         cast(short)(x >>> 16),
                         cast(short)(x >>> 32),
                         cast(short)(x >>> 48));
        } else {
            putLongParts(hb, offset,
                         cast(byte)(x >>> 0),
                         cast(byte)(x >>> 8),
                         cast(byte)(x >>> 16),
                         cast(byte)(x >>> 24),
                         cast(byte)(x >>> 32),
                         cast(byte)(x >>> 40),
                         cast(byte)(x >>> 48),
                         cast(byte)(x >>> 56));
        }
    }

    private static short _getShort(byte[] buf, size_t offset) {
        short* ptr = cast(short*)(buf.ptr + offset);
        return *ptr;
    }

    private static void _putShort(byte[] buf, size_t offset, short x) {
        buf[offset] = short0(x);
        buf[offset + 1] = short1(x);
    }

    private static int _getInt(byte[] buf, size_t offset) {
        int* ptr = cast(int*)(buf.ptr + offset);
        return *ptr;
    }

    private static void _putInt(byte[] buf, size_t offset, int x) {
        buf[offset] = int0(x);
        buf[offset + 1] = int1(x);
        buf[offset + 2] = int2(x);
        buf[offset + 3] = int3(x);
    }

    private static long _getLong(byte[] buf, size_t offset) {
        long* ptr = cast(long*)(buf.ptr + offset);
        return *ptr;
    }

    private static void  _putLong(byte[] buf, size_t offset, long x) {
        buf[offset] = long0(x);
        buf[offset + 1] = long1(x);
        buf[offset + 2] = long2(x);
        buf[offset + 3] = long3(x);

        buf[offset + 4] = long4(x);
        buf[offset + 5] = long5(x);
        buf[offset + 6] = long6(x);
        buf[offset + 7] = long7(x);
    }

    private static long makeLong(byte i0, byte i1, byte i2, byte i3, byte i4, byte i5, byte i6, byte i7) {
        return ((toUnsignedLong(i0) << pickPos(56, 0))
              | (toUnsignedLong(i1) << pickPos(56, 8))
              | (toUnsignedLong(i2) << pickPos(56, 16))
              | (toUnsignedLong(i3) << pickPos(56, 24))
              | (toUnsignedLong(i4) << pickPos(56, 32))
              | (toUnsignedLong(i5) << pickPos(56, 40))
              | (toUnsignedLong(i6) << pickPos(56, 48))
              | (toUnsignedLong(i7) << pickPos(56, 56)));
    }

    private static long makeLong(short i0, short i1, short i2, short i3) {
        return ((toUnsignedLong(i0) << pickPos(48, 0))
              | (toUnsignedLong(i1) << pickPos(48, 16))
              | (toUnsignedLong(i2) << pickPos(48, 32))
              | (toUnsignedLong(i3) << pickPos(48, 48)));
    }

    private static long makeLong(int i0, int i1) {
        return (toUnsignedLong(i0) << pickPos(32, 0))
             | (toUnsignedLong(i1) << pickPos(32, 32));
    }

    private static int makeInt(short i0, short i1) {
        return (toUnsignedInt(i0) << pickPos(16, 0))
             | (toUnsignedInt(i1) << pickPos(16, 16));
    }

    private static int makeInt(byte i0, byte i1, byte i2, byte i3) {
        return ((toUnsignedInt(i0) << pickPos(24, 0))
              | (toUnsignedInt(i1) << pickPos(24, 8))
              | (toUnsignedInt(i2) << pickPos(24, 16))
              | (toUnsignedInt(i3) << pickPos(24, 24)));
    }

    static short makeShort(byte i0, byte i1) {
        return cast(short)((toUnsignedInt(i0) << pickPos(8, 0))
                     | (toUnsignedInt(i1) << pickPos(8, 8)));
    }

    version (LittleEndian) {
        // Maybe byte-reverse an integer
        // private static char convEndian(bool big, char n)   { return big == BE ? n : Char.reverseBytes(n); }
        private static short convEndian(bool big, short n) { return big ? Short.reverseBytes(n) : n   ; }
        private static int convEndian(bool big, int n)     { return big ? Integer.reverseBytes(n) : n ; }
        private static long convEndian(bool big, long n)   { return big ? Long.reverseBytes(n) : n    ; }

        private static byte  pick(byte  le, byte  be) { return le; }
        private static short pick(short le, short be) { return le; }
        private static int   pick(int   le, int   be) { return le; }

        private static int pickPos(int top, int pos) { return pos; }
    } else {
        // Maybe byte-reverse an integer
        // private static char convEndian(bool big, char n)   { return big == BE ? n : Character.reverseBytes(n); }
        private static short convEndian(bool big, short n) { return big ? n : Short.reverseBytes(n)    ; }
        private static int convEndian(bool big, int n)     { return big ? n : Integer.reverseBytes(n)  ; }
        private static long convEndian(bool big, long n)   { return big ? n : Long.reverseBytes(n)     ; }

        private static byte  pick(byte  le, byte  be) { return be; }
        private static short pick(short le, short be) { return be; }
        private static int   pick(int   le, int   be) { return be; }

        private static int pickPos(int top, int pos) { return top - pos; }
    }

    // Zero-extend an integer
    private static int toUnsignedInt(byte n)    { return n & 0xff; }
    private static int toUnsignedInt(short n)   { return n & 0xffff; }
    private static long toUnsignedLong(byte n)  { return n & 0xffL; }
    private static long toUnsignedLong(short n) { return n & 0xffffL; }
    private static long toUnsignedLong(int n)   { return n & 0xffffffffL; }

    // private static byte short1(short x) { return cast(byte)(x >> 8); }
    // private static byte short0(short x) { return cast(byte)(x     ); }

    private static byte int3(int x) { return cast(byte)(x >> 24); }
    private static byte int2(int x) { return cast(byte)(x >> 16); }
    private static byte int1(int x) { return cast(byte)(x >>  8); }
    private static byte int0(int x) { return cast(byte)(x      ); }

    private static byte long7(long x) { return cast(byte)(x >> 56); }
    private static byte long6(long x) { return cast(byte)(x >> 48); }
    private static byte long5(long x) { return cast(byte)(x >> 40); }
    private static byte long4(long x) { return cast(byte)(x >> 32); }
    private static byte long3(long x) { return cast(byte)(x >> 24); }
    private static byte long2(long x) { return cast(byte)(x >> 16); }
    private static byte long1(long x) { return cast(byte)(x >>  8); }
    private static byte long0(long x) { return cast(byte)(x      ); }

    // dfmt on

    override ByteBuffer compact() {
        int sourceIndex = ix(position());
        int targetIndex = ix(0);
        int len = remaining();
        // tracef("hb.length=%d, remaining=%d, targetIndex=%d, sourceIndex=%d", hb.length, len, targetIndex, sourceIndex) ;
        if(targetIndex != sourceIndex) {
            hb[targetIndex .. targetIndex + len] = hb[sourceIndex .. sourceIndex + len];
            position(len);
            limit(capacity());
            discardMark();
        }
        return this;

    }
}
