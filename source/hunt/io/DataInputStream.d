module hunt.io.DataInputStream;

import std.conv;
import hunt.io.FilterInputStream;
import hunt.io.DataInput;
import hunt.lang;
import hunt.io.common;
import hunt.lang.exception;
import hunt.io.PushbackInputStream;

public
class DataInputStream : FilterInputStream , DataInput {

    /**
     * Creates a DataInputStream that uses the specified
     * underlying InputStream.
     *
     * @param  inputStream   the specified input stream
     */
    public this(InputStream inputStream) {
        super(inputStream);
    }

    /**
     * working arrays initialized on demand by readUTF
     */
    private byte[] bytearr = new byte[80];
    private char[] chararr = new char[80];

    /**
     * Reads some number of bytes from the contained input stream and
     * stores them into the buffer array <code>b</code>. The number of
     * bytes actually read is returned as an integer. This method blocks
     * until input data is available, end of file is detected, or an
     * exception is thrown.
     *
     * <p>If <code>b</code> is null, a <code>NullPointerException</code> is
     * thrown. If the length of <code>b</code> is zero, then no bytes are
     * read and <code>0</code> is returned; otherwise, there is an attempt
     * to read at least one byte. If no byte is available because the
     * stream is at end of file, the value <code>-1</code> is returned;
     * otherwise, at least one byte is read and stored into <code>b</code>.
     *
     * <p>The first byte read is stored into element <code>b[0]</code>, the
     * next one into <code>b[1]</code>, and so on. The number of bytes read
     * is, at most, equal to the length of <code>b</code>. Let <code>k</code>
     * be the number of bytes actually read; these bytes will be stored inputStream
     * elements <code>b[0]</code> through <code>b[k-1]</code>, leaving
     * elements <code>b[k]</code> through <code>b[b.length-1]</code>
     * unaffected.
     *
     * <p>The <code>read(b)</code> method has the same effect as:
     * <blockquote><pre>
     * read(b, 0, b.length)
     * </pre></blockquote>
     *
     * @param      b   the buffer into which the data is read.
     * @return     the total number of bytes read into the buffer, or
     *             <code>-1</code> if there is no more data because the end
     *             of the stream has been reached.
     * @exception  IOException if the first byte cannot be read for any reason
     * other than end of file, the stream has been closed and the underlying
     * input stream does not support reading after close, or another I/O
     * error occurs.
     * @see        java.io.FilterInputStream#inputStream
     * @see        java.io.InputStream#read(byte[], int, int)
     */
     override
    public final int read(byte[] b)  {
        return inputStream.read(b, 0, cast(int)(b.length));
    }

    /**
     * Reads up to <code>len</code> bytes of data from the contained
     * input stream into an array of bytes.  An attempt is made to read
     * as many as <code>len</code> bytes, but a smaller number may be read,
     * possibly zero. The number of bytes actually read is returned as an
     * integer.
     *
     * <p> This method blocks until input data is available, end of file is
     * detected, or an exception is thrown.
     *
     * <p> If <code>len</code> is zero, then no bytes are read and
     * <code>0</code> is returned; otherwise, there is an attempt to read at
     * least one byte. If no byte is available because the stream is at end of
     * file, the value <code>-1</code> is returned; otherwise, at least one
     * byte is read and stored into <code>b</code>.
     *
     * <p> The first byte read is stored into element <code>b[off]</code>, the
     * next one into <code>b[off+1]</code>, and so on. The number of bytes read
     * is, at most, equal to <code>len</code>. Let <i>k</i> be the number of
     * bytes actually read; these bytes will be stored inputStream elements
     * <code>b[off]</code> through <code>b[off+</code><i>k</i><code>-1]</code>,
     * leaving elements <code>b[off+</code><i>k</i><code>]</code> through
     * <code>b[off+len-1]</code> unaffected.
     *
     * <p> In every case, elements <code>b[0]</code> through
     * <code>b[off]</code> and elements <code>b[off+len]</code> through
     * <code>b[b.length-1]</code> are unaffected.
     *
     * @param      b     the buffer into which the data is read.
     * @param off the start offset inputStream the destination array <code>b</code>
     * @param      len   the maximum number of bytes read.
     * @return     the total number of bytes read into the buffer, or
     *             <code>-1</code> if there is no more data because the end
     *             of the stream has been reached.
     * @exception  NullPointerException If <code>b</code> is <code>null</code>.
     * @exception  IndexOutOfBoundsException If <code>off</code> is negative,
     * <code>len</code> is negative, or <code>len</code> is greater than
     * <code>b.length - off</code>
     * @exception  IOException if the first byte cannot be read for any reason
     * other than end of file, the stream has been closed and the underlying
     * input stream does not support reading after close, or another I/O
     * error occurs.
     * @see        java.io.FilterInputStream#inputStream
     * @see        java.io.InputStream#read(byte[], int, int)
     */
    override
    public final int read(byte[] b, int off, int len)  {
        return inputStream.read(b, off, len);
    }

    /**
     * See the general contract of the {@code readFully}
     * method of {@code DataInput}.
     * <p>
     * Bytes
     * for this operation are read from the contained
     * input stream.
     *
     * @param   b   the buffer into which the data is read.
     * @throws  NullPointerException if {@code b} is {@code null}.
     * @throws  EOFException  if this input stream reaches the end before
     *          reading all the bytes.
     * @throws  IOException   the stream has been closed and the contained
     *          input stream does not support reading after close, or
     *          another I/O error occurs.
     * @see     java.io.FilterInputStream#inputStream
     */
    public final void readFully(byte[] b)  {
        readFully(b, 0, cast(int)(b.length));
    }

    /**
     * See the general contract of the {@code readFully}
     * method of {@code DataInput}.
     * <p>
     * Bytes
     * for this operation are read from the contained
     * input stream.
     *
     * @param      b     the buffer into which the data is read.
     * @param      off   the start offset inputStream the data array {@code b}.
     * @param      len   the number of bytes to read.
     * @exception  NullPointerException if {@code b} is {@code null}.
     * @exception  IndexOutOfBoundsException if {@code off} is negative,
     *             {@code len} is negative, or {@code len} is greater than
     *             {@code b.length - off}.
     * @exception  EOFException  if this input stream reaches the end before
     *             reading all the bytes.
     * @exception  IOException   the stream has been closed and the contained
     *             input stream does not support reading after close, or
     *             another I/O error occurs.
     * @see        java.io.FilterInputStream#inputStream
     */
    public final void readFully(byte[] b, int off, int len)  {
        if (len < 0)
            throw new IndexOutOfBoundsException();
        int n = 0;
        while (n < len) {
            int count = inputStream.read(b, off + n, len - n);
            if (count < 0)
                throw new EOFException();
            n += count;
        }
    }

    /**
     * See the general contract of the <code>skipBytes</code>
     * method of <code>DataInput</code>.
     * <p>
     * Bytes for this operation are read from the contained
     * input stream.
     *
     * @param      n   the number of bytes to be skipped.
     * @return     the actual number of bytes skipped.
     * @exception  IOException  if the contained input stream does not support
     *             seek, or the stream has been closed and
     *             the contained input stream does not support
     *             reading after close, or another I/O error occurs.
     */
    public final int skipBytes(int n)  {
        int total = 0;
        int cur = 0;

        while ((total<n) && ((cur = cast(int) inputStream.skip(n-total)) > 0)) {
            total += cur;
        }

        return total;
    }

    /**
     * See the general contract of the <code>readBoolean</code>
     * method of <code>DataInput</code>.
     * <p>
     * Bytes for this operation are read from the contained
     * input stream.
     *
     * @return     the <code>bool</code> value read.
     * @exception  EOFException  if this input stream has reached the end.
     * @exception  IOException   the stream has been closed and the contained
     *             input stream does not support reading after close, or
     *             another I/O error occurs.
     * @see        java.io.FilterInputStream#inputStream
     */
    public final bool readBoolean()  {
        int ch = inputStream.read();
        if (ch < 0)
            throw new EOFException();
        return (ch != 0);
    }

    /**
     * See the general contract of the <code>readByte</code>
     * method of <code>DataInput</code>.
     * <p>
     * Bytes
     * for this operation are read from the contained
     * input stream.
     *
     * @return     the next byte of this input stream as a signed 8-bit
     *             <code>byte</code>.
     * @exception  EOFException  if this input stream has reached the end.
     * @exception  IOException   the stream has been closed and the contained
     *             input stream does not support reading after close, or
     *             another I/O error occurs.
     * @see        java.io.FilterInputStream#inputStream
     */
    public final byte readByte()  {
        int ch = inputStream.read();
        if (ch < 0)
            throw new EOFException();
        return cast(byte)(ch);
    }

    /**
     * See the general contract of the <code>readUnsignedByte</code>
     * method of <code>DataInput</code>.
     * <p>
     * Bytes
     * for this operation are read from the contained
     * input stream.
     *
     * @return     the next byte of this input stream, interpreted as an
     *             unsigned 8-bit number.
     * @exception  EOFException  if this input stream has reached the end.
     * @exception  IOException   the stream has been closed and the contained
     *             input stream does not support reading after close, or
     *             another I/O error occurs.
     * @see         java.io.FilterInputStream#inputStream
     */
    public final int readUnsignedByte()  {
        int ch = inputStream.read();
        if (ch < 0)
            throw new EOFException();
        return ch;
    }

    /**
     * See the general contract of the <code>readShort</code>
     * method of <code>DataInput</code>.
     * <p>
     * Bytes
     * for this operation are read from the contained
     * input stream.
     *
     * @return     the next two bytes of this input stream, interpreted as a
     *             signed 16-bit number.
     * @exception  EOFException  if this input stream reaches the end before
     *               reading two bytes.
     * @exception  IOException   the stream has been closed and the contained
     *             input stream does not support reading after close, or
     *             another I/O error occurs.
     * @see        java.io.FilterInputStream#inputStream
     */
    public final short readShort()  {
        int ch1 = inputStream.read();
        int ch2 = inputStream.read();
        if ((ch1 | ch2) < 0)
            throw new EOFException();
        return cast(short)((ch1 << 8) + (ch2 << 0));
    }

    /**
     * See the general contract of the <code>readUnsignedShort</code>
     * method of <code>DataInput</code>.
     * <p>
     * Bytes
     * for this operation are read from the contained
     * input stream.
     *
     * @return     the next two bytes of this input stream, interpreted as an
     *             unsigned 16-bit integer.
     * @exception  EOFException  if this input stream reaches the end before
     *             reading two bytes.
     * @exception  IOException   the stream has been closed and the contained
     *             input stream does not support reading after close, or
     *             another I/O error occurs.
     * @see        java.io.FilterInputStream#inputStream
     */
    public final int readUnsignedShort()  {
        int ch1 = inputStream.read();
        int ch2 = inputStream.read();
        if ((ch1 | ch2) < 0)
            throw new EOFException();
        return (ch1 << 8) + (ch2 << 0);
    }

    /**
     * See the general contract of the <code>readChar</code>
     * method of <code>DataInput</code>.
     * <p>
     * Bytes
     * for this operation are read from the contained
     * input stream.
     *
     * @return     the next two bytes of this input stream, interpreted as a
     *             <code>char</code>.
     * @exception  EOFException  if this input stream reaches the end before
     *               reading two bytes.
     * @exception  IOException   the stream has been closed and the contained
     *             input stream does not support reading after close, or
     *             another I/O error occurs.
     * @see        java.io.FilterInputStream#inputStream
     */
    public final char readChar()  {
        return readByte();
        // int ch1 = inputStream.read();
        // return cast(char)ch1;
        // int ch2 = inputStream.read();
        // if ((ch1 | ch2) < 0)
        //     throw new EOFException();
        // return cast(char)((ch1 << 8) + (ch2 << 0));
    }

    /**
     * See the general contract of the <code>readInt</code>
     * method of <code>DataInput</code>.
     * <p>
     * Bytes
     * for this operation are read from the contained
     * input stream.
     *
     * @return     the next four bytes of this input stream, interpreted as an
     *             <code>int</code>.
     * @exception  EOFException  if this input stream reaches the end before
     *               reading four bytes.
     * @exception  IOException   the stream has been closed and the contained
     *             input stream does not support reading after close, or
     *             another I/O error occurs.
     * @see        java.io.FilterInputStream#inputStream
     */
    public final int readInt()  {
        int ch1 = inputStream.read();
        int ch2 = inputStream.read();
        int ch3 = inputStream.read();
        int ch4 = inputStream.read();
        if ((ch1 | ch2 | ch3 | ch4) < 0)
            throw new EOFException();
        return ((ch1 << 24) + (ch2 << 16) + (ch3 << 8) + (ch4 << 0));
    }

    private byte[] readBuffer = new byte[8];

    /**
     * See the general contract of the <code>readLong</code>
     * method of <code>DataInput</code>.
     * <p>
     * Bytes
     * for this operation are read from the contained
     * input stream.
     *
     * @return     the next eight bytes of this input stream, interpreted as a
     *             <code>long</code>.
     * @exception  EOFException  if this input stream reaches the end before
     *               reading eight bytes.
     * @exception  IOException   the stream has been closed and the contained
     *             input stream does not support reading after close, or
     *             another I/O error occurs.
     * @see        java.io.FilterInputStream#inputStream
     */
    public final long readLong()  {
        readFully(readBuffer, 0, 8);
        return ((cast(long)readBuffer[0] << 56) +
                (cast(long)(readBuffer[1] & 255) << 48) +
                (cast(long)(readBuffer[2] & 255) << 40) +
                (cast(long)(readBuffer[3] & 255) << 32) +
                (cast(long)(readBuffer[4] & 255) << 24) +
                ((readBuffer[5] & 255) << 16) +
                ((readBuffer[6] & 255) <<  8) +
                ((readBuffer[7] & 255) <<  0));
    }

    /**
     * See the general contract of the <code>readFloat</code>
     * method of <code>DataInput</code>.
     * <p>
     * Bytes
     * for this operation are read from the contained
     * input stream.
     *
     * @return     the next four bytes of this input stream, interpreted as a
     *             <code>float</code>.
     * @exception  EOFException  if this input stream reaches the end before
     *               reading four bytes.
     * @exception  IOException   the stream has been closed and the contained
     *             input stream does not support reading after close, or
     *             another I/O error occurs.
     * @see        java.io.DataInputStream#readInt()
     * @see        java.lang.Float#intBitsToFloat(int)
     */
    public final float readFloat()  {
        return Float.intBitsToFloat(readInt());
    }

    /**
     * See the general contract of the <code>readDouble</code>
     * method of <code>DataInput</code>.
     * <p>
     * Bytes
     * for this operation are read from the contained
     * input stream.
     *
     * @return     the next eight bytes of this input stream, interpreted as a
     *             <code>double</code>.
     * @exception  EOFException  if this input stream reaches the end before
     *               reading eight bytes.
     * @exception  IOException   the stream has been closed and the contained
     *             input stream does not support reading after close, or
     *             another I/O error occurs.
     * @see        java.io.DataInputStream#readLong()
     * @see        java.lang.Double#longBitsToDouble(long)
     */
    public final double readDouble()  {
        return Double.longBitsToDouble(readLong());
    }

    private char[] lineBuffer;

    /**
     * See the general contract of the <code>readLine</code>
     * method of <code>DataInput</code>.
     * <p>
     * Bytes
     * for this operation are read from the contained
     * input stream.
     *
     * @deprecated This method does not properly convert bytes to characters.
     * As of JDK&nbsp;1.1, the preferred way to read lines of text is via the
     * <code>BufferedReader.readLine()</code> method.  Programs that use the
     * <code>DataInputStream</code> class to read lines can be converted to use
     * the <code>BufferedReader</code> class by replacing code of the form:
     * <blockquote><pre>
     *     DataInputStream d =&nbsp;new&nbsp;DataInputStream(inputStream);
     * </pre></blockquote>
     * with:
     * <blockquote><pre>
     *     BufferedReader d
     *          =&nbsp;new&nbsp;BufferedReader(new&nbsp;InputStreamReader(inputStream));
     * </pre></blockquote>
     *
     * @return     the next line of text from this input stream.
     * @exception  IOException  if an I/O error occurs.
     * @see        java.io.BufferedReader#readLine()
     * @see        java.io.FilterInputStream#inputStream
     */
    // @Deprecated
    public final string readLine()  {
        char[] buf = lineBuffer;

        if (buf is null) {
            buf = lineBuffer = new char[128];
        }

        int room = cast(int)(buf.length);
        int offset = 0;
        int c;

loop:   while (true) {
            switch (c = inputStream.read()) {
              case -1:
              case '\n':
                break loop;

              case '\r':
                int c2 = inputStream.read();
                if ((c2 != '\n') && (c2 != -1)) {
                    if (!(cast(PushbackInputStream)inputStream !is null)) {
                        this.inputStream = new PushbackInputStream(inputStream);
                    }
                    (cast(PushbackInputStream)inputStream).unread(c2);
                }
                break loop;

              default:
                if (--room < 0) {
                    buf = new char[offset + 128];
                    room = cast(int)(buf.length) - offset - 1;
                    // System.arraycopy(lineBuffer, 0, buf, 0, offset);
                    buf[0 .. offset ] = lineBuffer[0..offset];
                    lineBuffer = buf;
                }
                buf[offset++] = cast(char) c;
                break;
            }
        }
        if ((c == -1) && (offset == 0)) {
            return null;
        }
        return cast(string)buf[0..offset];
    }

    /**
     * See the general contract of the <code>readUTF</code>
     * method of <code>DataInput</code>.
     * <p>
     * Bytes
     * for this operation are read from the contained
     * input stream.
     *
     * @return     a Unicode string.
     * @exception  EOFException  if this input stream reaches the end before
     *               reading all the bytes.
     * @exception  IOException   the stream has been closed and the contained
     *             input stream does not support reading after close, or
     *             another I/O error occurs.
     * @exception  UTFDataFormatException if the bytes do not represent a valid
     *             modified UTF-8 encoding of a string.
     * @see        java.io.DataInputStream#readUTF(java.io.DataInput)
     */
    public final string readUTF()  {
        return readUTF(this);
    }

    /**
     * Reads from the
     * stream <code>inputStream</code> a representation
     * of a Unicode  character string encoded inputStream
     * <a href="DataInput.html#modified-utf-8">modified UTF-8</a> format;
     * this string of characters is then returned as a <code>String</code>.
     * The details of the modified UTF-8 representation
     * are  exactly the same as for the <code>readUTF</code>
     * method of <code>DataInput</code>.
     *
     * @param      inputStream   a data input stream.
     * @return     a Unicode string.
     * @exception  EOFException            if the input stream reaches the end
     *               before all the bytes.
     * @exception  IOException   the stream has been closed and the contained
     *             input stream does not support reading after close, or
     *             another I/O error occurs.
     * @exception  UTFDataFormatException  if the bytes do not represent a
     *               valid modified UTF-8 encoding of a Unicode string.
     * @see        java.io.DataInputStream#readUnsignedShort()
     */
    public static final string readUTF(DataInput inputStream)  {
        int utflen = inputStream.readUnsignedShort();
        byte[] bytearr = null;
        import hunt.logging;
            // trace("11111111=>", utflen);
        // char[] chararr = null;
        if (cast(DataInputStream)inputStream !is null ) {
            // trace("xxxx=>");
        //     DataInputStream dis = cast(DataInputStream)inputStream;
        //     if (dis.bytearr.length < utflen){
        //         dis.bytearr = new byte[utflen*2];
        //         dis.chararr = new char[utflen*2];
        //     }
        //     chararr = dis.chararr;
        //     bytearr = dis.bytearr;
        } else {
            // trace("yyyyyyyy=>");
        //     bytearr = new byte[utflen];
        //     chararr = new char[utflen];
        }

        bytearr = new byte[utflen];

        // int c, char2, char3;
        // int count = 0;
        // int chararr_count=0;

        inputStream.readFully(bytearr, 0, utflen);

        // while (count < utflen) {
        //     c = cast(int) bytearr[count] & 0xff;
        //     if (c > 127) break;
        //     count++;
        //     auto t = cast(char)c;
        //     chararr[chararr_count++]= t;
        // }

        // trace("ccc=>", cast(string)bytearr);

        return cast(string)bytearr;

        // while (count < utflen) {
        //     c = cast(int) bytearr[count] & 0xff;
        //     switch (c >> 4) {
        //         case 0: case 1: case 2: case 3: case 4: case 5: case 6: case 7:
        //             /* 0xxxxxxx*/
        //             count++;
        //             chararr[chararr_count++]=cast(char)c;
        //             break;
        //         case 12: case 13:
        //             /* 110x xxxx   10xx xxxx*/
        //             count += 2;
        //             if (count > utflen)
        //                 throw new Exception(
        //                     "malformed input: partial character at end");
        //             char2 = cast(int) bytearr[count-1];
        //             if ((char2 & 0xC0) != 0x80)
        //                 throw new Exception(
        //                     "malformed input around byte " ~ count.to!string);
        //             chararr[chararr_count++]=cast(char)(((c & 0x1F) << 6) |
        //                                             (char2 & 0x3F));
        //             break;
        //         case 14:
        //             /* 1110 xxxx  10xx xxxx  10xx xxxx */
        //             count += 3;
        //             if (count > utflen)
        //                 throw new Exception(
        //                     "malformed input: partial character at end");
        //             char2 = cast(int) bytearr[count-2];
        //             char3 = cast(int) bytearr[count-1];
        //             if (((char2 & 0xC0) != 0x80) || ((char3 & 0xC0) != 0x80))
        //                 throw new Exception(
        //                     "malformed input around byte " ~ (count-1).to!string);
        //             chararr[chararr_count++]=cast(char)(((c     & 0x0F) << 12) |
        //                                             ((char2 & 0x3F) << 6)  |
        //                                             ((char3 & 0x3F) << 0));
        //             break;
        //         default:
        //             /* 10xx xxxx,  1111 xxxx */
        //             throw new Exception(
        //                 "malformed input around byte " ~ count.to!string);
        //     }
        // }
        // The number of chars produced may be less than utflen
        // return cast(string)chararr[0..chararr_count];
    }
}
