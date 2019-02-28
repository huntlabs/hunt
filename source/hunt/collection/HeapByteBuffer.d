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
            throw new BufferOverflowException("");
        // System.arraycopy(src, offset, hb, ix(position()), length);
        int newPos = ix(position());
        hb[newPos .. newPos + length] = src[offset .. offset + length];

        position(position() + length);
        return this;

    }

    override ByteBuffer put(ByteBuffer src) {
        if (typeid(src) == typeid(HeapByteBuffer)) {
            if (src is this)
                throw new IllegalArgumentException("");
            HeapByteBuffer sb = cast(HeapByteBuffer) src;
            int n = sb.remaining();
            if (n > remaining())
                throw new BufferOverflowException("");
            // System.arraycopy(sb.hb, sb.ix(sb.position()), hb, ix(position()), n);

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

    version (LittleEndian) private static void putIntUnaligned(byte[] hb,
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

    // dfmt off
    private static byte int3(int x) { return cast(byte)(x >> 24); }
    private static byte int2(int x) { return cast(byte)(x >> 16); }
    private static byte int1(int x) { return cast(byte)(x >>  8); }
    private static byte int0(int x) { return cast(byte)(x      ); }
    // dfmt on

    override ByteBuffer compact() {
        int sourceIndex = ix(position());
        int targetIndex = ix(0);
        int len = remaining();
        hb[targetIndex .. targetIndex + len] = hb[sourceIndex .. sourceIndex + len];

        position(remaining());
        limit(capacity());
        discardMark();
        return this;

    }
}
