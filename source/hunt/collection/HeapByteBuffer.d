module hunt.collection.HeapByteBuffer;

import hunt.collection.ByteBuffer;
import hunt.Exceptions;

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
            if (n > remaining())
                throw new BufferOverflowException("");

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

    private static short makeShort(byte b1, byte b0) {
        return cast(short)((b1 << 8) | (b0 & 0xff));
    }

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
        if (bigEndian)
            return makeShort(hb[index], hb[index + 1]);
        else
            return makeShort(hb[index + 1], hb[index]);
    }

    override short getShort(int i) {
        int index = ix(checkIndex(i, 2));
        if (bigEndian)
            return makeShort(hb[index], hb[index + 1]);
        else
            return makeShort(hb[index + 1], hb[index]);
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
        auto index = ix(nextGetIndex(4));
        return _getInt(index);
    }

    override int getInt(int i) {
        auto index = ix(checkIndex(i, 4));
        return _getInt(index);
    }

    version (LittleEndian) private int _getInt(size_t index) {
        if (bigEndian)
            return makeInt(hb[index], hb[index + 1], hb[index + 2], hb[index + 3]);
        else
            return makeInt(hb[index + 3], hb[index + 2], hb[index + 1], hb[index]);
    }

    private static int makeInt(byte b3, byte b2, byte b1, byte b0) {
        return ((b3) << 24) | ((b2 & 0xff) << 16) | ((b1 & 0xff) << 8) | (b0 & 0xff);
    }

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

    private int getLongUnaligned(size_t index) {
        implementationMissing(false);
        return 0;
        // TODO: Tasks pending completion -@zhangxueping at 4/19/2019, 4:57:17 PM
        // 
        // if (bigEndian)
        //     return makeInt(hb[index], hb[index + 1], hb[index + 2], hb[index + 3]);
        // else
        //     return makeInt(hb[index + 3], hb[index + 2], hb[index + 1], hb[index]);
    }

    override ByteBuffer putLong(long x) {
        putLongUnaligned(hb, ix(nextPutIndex(8)), x, bigEndian);
        return this;
    }

    override ByteBuffer putLong(int i, long x) {
        putLongUnaligned(hb, ix(checkIndex(i, 8)), x, bigEndian);
        return this;
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
     * @since 9
     */
    final long getLongUnaligned(byte[] hb,  long offset, bool bigEndian) {
        // return convEndian(bigEndian, getLongUnaligned(hb, offset));
        return 0;
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
     * @since 9
     */
    final void putLongUnaligned(byte[] hb, long offset, long x, bool bigEndian) {
        // putLongUnaligned(hb, offset, convEndian(bigEndian, x));
        // TODO: Tasks pending completion -@zhangxueping at 4/19/2019, 4:56:43 PM
        // 
    }

    // dfmt off
    private static void putIntUnaligned(byte[] hb,
            int offset, int x, bool bigEndian) {
        if (bigEndian) {
            hb[offset] = int3(x);
            hb[offset + 1] = int2(x);
            hb[offset + 2] = int1(x);
            hb[offset + 3] = int0(x);
        } else {
            hb[offset] = int0(x);
            hb[offset + 1] = int1(x);
            hb[offset + 2] = int2(x);
            hb[offset + 3] = int3(x);
        }
    }

    private static void putLongUnaligned(byte[] hb, long offset, long x) {
        if ((offset & 7) == 0) {
            _putLong(hb, offset, x);
        } else if ((offset & 3) == 0) {
            // putLongParts(hb, offset,
            //              cast(int)(x >> 0),
            //              cast(int)(x >>> 32));
        } else if ((offset & 1) == 0) {
            // putLongParts(hb, offset,
            //              cast(short)(x >>> 0),
            //              cast(short)(x >>> 16),
            //              cast(short)(x >>> 32),
            //              cast(short)(x >>> 48));
        } else {
            // putLongParts(hb, offset,
            //              cast(byte)(x >>> 0),
            //              cast(byte)(x >>> 8),
            //              cast(byte)(x >>> 16),
            //              cast(byte)(x >>> 24),
            //              cast(byte)(x >>> 32),
            //              cast(byte)(x >>> 40),
            //              cast(byte)(x >>> 48),
            //              cast(byte)(x >>> 56));
        }
    }

    private static void  _putLong(byte[] hb, long offset, long x) {
            // hb[offset] = int3(x);
            // hb[offset + 1] = int2(x);
            // hb[offset + 2] = int1(x);
            // hb[offset + 3] = int0(x);
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

    version (LittleEndian) {
            // Maybe byte-reverse an integer
        // private static char convEndian(bool big, char n)   { return big == BE ? n : Character.reverseBytes(n); }
        // private static short convEndian(bool big, short n) { return big == BE ? n : Short.reverseBytes(n)    ; }
        // private static int convEndian(bool big, int n)     { return big == BE ? n : Integer.reverseBytes(n)  ; }
        // private static long convEndian(bool big, long n)   { return big == BE ? n : Long.reverseBytes(n)     ; }

        private static byte  pick(byte  le, byte  be) { return le; }
        private static short pick(short le, short be) { return le; }
        private static int   pick(int   le, int   be) { return le; }

        private static int pickPos(int top, int pos) { return pos; }
    } else {
            // Maybe byte-reverse an integer
        // private static char convEndian(bool big, char n)   { return big == BE ? n : Character.reverseBytes(n); }
        // private static short convEndian(bool big, short n) { return big == BE ? n : Short.reverseBytes(n)    ; }
        // private static int convEndian(bool big, int n)     { return big == BE ? n : Integer.reverseBytes(n)  ; }
        // private static long convEndian(bool big, long n)   { return big == BE ? n : Long.reverseBytes(n)     ; }

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

    private static byte int3(int x) { return cast(byte)(x >> 24); }
    private static byte int2(int x) { return cast(byte)(x >> 16); }
    private static byte int1(int x) { return cast(byte)(x >>  8); }
    private static byte int0(int x) { return cast(byte)(x      ); }
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
