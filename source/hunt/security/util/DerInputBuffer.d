module hunt.security.util.DerInputBuffer;

import hunt.io.ByteArrayInputStream;
import hunt.io.common;

import hunt.util.Character;
import hunt.util.exception;

import std.bigint;
import std.bitmanip;
import std.conv;

alias BigInteger = BigInt;

/**
 * DER input buffer ... this is the main abstraction in the DER library
 * which actively works with the "untyped byte stream" abstraction.  It
 * does so with impunity, since it's not intended to be exposed to
 * anyone who could violate the "typed value stream" DER model and hence
 * corrupt the input stream of DER values.
 *
 * @author David Brownell
 */
class DerInputBuffer : ByteArrayInputStream {

    bool allowBER = true;

    // used by sun/security/util/DerInputBuffer/DerInputBufferEqualsHashCode.java
    this(byte[] buf) {
        this(buf, true);
    }

    this(byte[] buf, bool allowBER) {
        super(buf);
        this.allowBER = allowBER;
    }

    this(byte[] buf, int offset, int len, bool allowBER) {
        super(buf, offset, len);
        this.allowBER = allowBER;
    }

    // DerInputBuffer dup() {
    //     try {
    //         DerInputBuffer retval = (DerInputBuffer)clone();
    //         retval.mark(int.max);
    //         return retval;
    //     } catch (CloneNotSupportedException e) {
    //         throw new IllegalArgumentException(e.toString());
    //     }
    // }

    byte[] toByteArray() {
        int     len = available();
        if (len <= 0)
            return null;
        byte[] retval = buf[pos .. pos+len].dup;
        // byte[]  retval = new byte[len];

        // System.arraycopy(buf, pos, retval, 0, len);

        return retval;
    }

    int peek() {
        if (pos >= count)
            throw new IOException("out of data");
        else
            return buf[pos];
    }

    /**
     * Compares this DerInputBuffer for equality with the specified
     * object.
     */
    override bool opEquals(Object other) {
        DerInputBuffer buffer = cast(DerInputBuffer)other;
        if (buffer !is null)
            return equals(buffer);
        else
            return false;
    }

    bool equals(DerInputBuffer other) {
        if (this is other)
            return true;

        int max = this.available();
        if (other.available() != max)
            return false;
        for (int i = 0; i < max; i++) {
            if (this.buf[this.pos + i] != other.buf[other.pos + i]) {
                return false;
            }
        }
        return true;
    }

    /**
     * Returns a hashcode for this DerInputBuffer.
     *
     * @return a hashcode for this DerInputBuffer.
     */
    override size_t toHash() @trusted const nothrow {
        size_t retval = 0;

        int len = available();
        int p = pos;

        for (int i = 0; i < len; i++)
            retval += buf[p + i] * i;
        return retval;
    }

    void truncate(int len) {
        if (len > available())
            throw new IOException("insufficient data");
        count = pos + len;
    }

    /**
     * Returns the integer which takes up the specified number
     * of bytes in this buffer as a BigInteger.
     * @param len the number of bytes to use.
     * @param makePositive whether to always return a positive value,
     *   irrespective of actual encoding
     * @return the integer as a BigInteger.
     */
    BigInteger getBigInteger(int len, bool makePositive) {
        if (len > available())
            throw new IOException("short read of integer");

        if (len == 0) {
            throw new IOException("Invalid encoding: zero length Int value");
        }
        byte[] bytes = buf[pos .. pos+len].dup;

        // byte[] bytes = new byte[len];

        // System.arraycopy(buf, pos, bytes, 0, len);
        skip(len);

        // BER allows leading 0s but DER does not
        if (!allowBER && (len >= 2 && (bytes[0] == 0) && (bytes[1] >= 0))) {
            throw new IOException("Invalid encoding: redundant leading 0s");
        }

        if (makePositive) {
            return new BigInteger(1, bytes);
        } else {
            return new BigInteger(bytes);
        }
    }

    /**
     * Returns the integer which takes up the specified number
     * of bytes in this buffer.
     * @throws IOException if the result is not within the valid
     * range for integer, i.e. between int.min and
     * int.max.
     * @param len the number of bytes to use.
     * @return the integer.
     */
    int getInteger(int len) {

        BigInteger result = getBigInteger(len, false);
        if (result < int.min) {
            throw new IOException("Integer below minimum valid value");
        }
        if (result > int.max) > 0) {
            throw new IOException("Integer exceeds maximum valid value");
        }
        return result.intValue();
    }

    /**
     * Returns the bit string which takes up the specified
     * number of bytes in this buffer.
     */
    byte[] getBitString(int len) {
        if (len > available())
            throw new IOException("short read of bit string");

        if (len == 0) {
            throw new IOException("Invalid encoding: zero length bit string");
        }

        int numOfPadBits = buf[pos];
        if ((numOfPadBits < 0) || (numOfPadBits > 7)) {
            throw new IOException("Invalid number of padding bits");
        }
        // minus the first byte which indicates the number of padding bits
        // byte[] retval = new byte[len - 1];
        // System.arraycopy(buf, pos + 1, retval, 0, len - 1);
        byte[] retval = buf[pos+1 .. pos+len].dup;
        if (numOfPadBits != 0) {
            // get rid of the padding bits
            retval[len - 2] &= (0xff << numOfPadBits);
        }
        skip(len);
        return retval;
    }

    /**
     * Returns the bit string which takes up the rest of this buffer.
     */
    byte[] getBitString() {
        return getBitString(available());
    }

    /**
     * Returns the bit string which takes up the rest of this buffer.
     * The bit string need not be byte-aligned.
     */
    BitArray getUnalignedBitString() {
        if (pos >= count)
            return null;
        // /*
        //  * Just copy the data into an aligned, padded octet buffer,
        //  * and consume the rest of the buffer.
        //  */
        // int len = available();
        // int unusedBits = buf[pos] & 0xff;
        // if (unusedBits > 7 ) {
        //     throw new IOException("Invalid value for unused bits: " ~ unusedBits.to!string());
        // }
        // byte[] bits = new byte[len - 1];
        // // number of valid bits
        // int length = (bits.length == 0) ? 0 : bits.length * 8 - unusedBits;

        // // System.arraycopy(buf, pos + 1, bits, 0, len - 1);
        // bits[0 .. $] = buf[pos + 1 .. pos + len].dup;

        // BitArray bitArray = new BitArray(length, bits);
        // pos = count;
        // return bitArray;

        implementationMissing();

        return BitArray.init;
    }

    /**
     * Returns the UTC Time value that takes up the specified number
     * of bytes in this buffer.
     * @param len the number of bytes to use
     */
    // Date getUTCTime(int len) {
    //     if (len > available())
    //         throw new IOException("short read of DER UTC Time");

    //     if (len < 11 || len > 17)
    //         throw new IOException("DER UTC Time length error");

    //     return getTime(len, false);
    // }

    /**
     * Returns the Generalized Time value that takes up the specified
     * number of bytes in this buffer.
     * @param len the number of bytes to use
     */
    // Date getGeneralizedTime(int len) {
    //     if (len > available())
    //         throw new IOException("short read of DER Generalized Time");

    //     if (len < 13 || len > 23)
    //         throw new IOException("DER Generalized Time length error");

    //     return getTime(len, true);

    // }

    /**
     * Private helper routine to extract time from the der value.
     * @param len the number of bytes to use
     * @param generalized true if Generalized Time is to be read, false
     * if UTC Time is to be read.
     */
    // private Date getTime(int len, bool generalized) {

    //     /*
    //      * UTC time encoded as ASCII chars:
    //      *       YYMMDDhhmmZ
    //      *       YYMMDDhhmmssZ
    //      *       YYMMDDhhmm+hhmm
    //      *       YYMMDDhhmm-hhmm
    //      *       YYMMDDhhmmss+hhmm
    //      *       YYMMDDhhmmss-hhmm
    //      * UTC Time is broken in storing only two digits of year.
    //      * If YY < 50, we assume 20YY;
    //      * if YY >= 50, we assume 19YY, as per RFC 3280.
    //      *
    //      * Generalized time has a four-digit year and allows any
    //      * precision specified in ISO 8601. However, for our purposes,
    //      * we will only allow the same format as UTC time, except that
    //      * fractional seconds (millisecond precision) are supported.
    //      */

    //     int year, month, day, hour, minute, second, millis;
    //     string type = null;

    //     if (generalized) {
    //         type = "Generalized";
    //         year = 1000 * Character.digit(cast(char)buf[pos++], 10);
    //         year += 100 * Character.digit(cast(char)buf[pos++], 10);
    //         year += 10 * Character.digit(cast(char)buf[pos++], 10);
    //         year += Character.digit(cast(char)buf[pos++], 10);
    //         len -= 2; // For the two extra YY
    //     } else {
    //         type = "UTC";
    //         year = 10 * Character.digit(cast(char)buf[pos++], 10);
    //         year += Character.digit(cast(char)buf[pos++], 10);

    //         if (year < 50)              // origin 2000
    //             year += 2000;
    //         else
    //             year += 1900;   // origin 1900
    //     }

    //     month = 10 * Character.digit(cast(char)buf[pos++], 10);
    //     month += Character.digit(cast(char)buf[pos++], 10);

    //     day = 10 * Character.digit(cast(char)buf[pos++], 10);
    //     day += Character.digit(cast(char)buf[pos++], 10);

    //     hour = 10 * Character.digit(cast(char)buf[pos++], 10);
    //     hour += Character.digit(cast(char)buf[pos++], 10);

    //     minute = 10 * Character.digit(cast(char)buf[pos++], 10);
    //     minute += Character.digit(cast(char)buf[pos++], 10);

    //     len -= 10; // YYMMDDhhmm

    //     /*
    //      * We allow for non-encoded seconds, even though the
    //      * IETF-PKIX specification says that the seconds should
    //      * always be encoded even if it is zero.
    //      */

    //     millis = 0;
    //     if (len > 2 && len < 12) {
    //         second = 10 * Character.digit(cast(char)buf[pos++], 10);
    //         second += Character.digit(cast(char)buf[pos++], 10);
    //         len -= 2;
    //         // handle fractional seconds (if present)
    //         if (buf[pos] == '.' || buf[pos] == ',') {
    //             len --;
    //             pos++;
    //             // handle upto milisecond precision only
    //             int precision = 0;
    //             int peek = pos;
    //             while (buf[peek] != 'Z' &&
    //                    buf[peek] != '+' &&
    //                    buf[peek] != '-') {
    //                 peek++;
    //                 precision++;
    //             }
    //             switch (precision) {
    //             case 3:
    //                 millis += 100 * Character.digit(cast(char)buf[pos++], 10);
    //                 millis += 10 * Character.digit(cast(char)buf[pos++], 10);
    //                 millis += Character.digit(cast(char)buf[pos++], 10);
    //                 break;
    //             case 2:
    //                 millis += 100 * Character.digit(cast(char)buf[pos++], 10);
    //                 millis += 10 * Character.digit(cast(char)buf[pos++], 10);
    //                 break;
    //             case 1:
    //                 millis += 100 * Character.digit(cast(char)buf[pos++], 10);
    //                 break;
    //             default:
    //                     throw new IOException("Parse " ~ type +
    //                         " time, unsupported precision for seconds value");
    //             }
    //             len -= precision;
    //         }
    //     } else
    //         second = 0;

    //     if (month == 0 || day == 0
    //         || month > 12 || day > 31
    //         || hour >= 24 || minute >= 60 || second >= 60)
    //         throw new IOException("Parse " ~ type ~ " time, invalid format");

    //     /*
    //      * Generalized time can theoretically allow any precision,
    //      * but we're not supporting that.
    //      */
    //     CalendarSystem gcal = CalendarSystem.getGregorianCalendar();
    //     CalendarDate date = gcal.newCalendarDate(null); // no time zone
    //     date.setDate(year, month, day);
    //     date.setTimeOfDay(hour, minute, second, millis);
    //     long time = gcal.getTime(date);

    //     /*
    //      * Finally, "Z" or "+hhmm" or "-hhmm" ... offsets change hhmm
    //      */
    //     if (! (len == 1 || len == 5))
    //         throw new IOException("Parse " ~ type ~ " time, invalid offset");

    //     int hr, min;

    //     switch (buf[pos++]) {
    //     case '+':
    //         hr = 10 * Character.digit(cast(char)buf[pos++], 10);
    //         hr += Character.digit(cast(char)buf[pos++], 10);
    //         min = 10 * Character.digit(cast(char)buf[pos++], 10);
    //         min += Character.digit(cast(char)buf[pos++], 10);

    //         if (hr >= 24 || min >= 60)
    //             throw new IOException("Parse " ~ type ~ " time, +hhmm");

    //         time -= ((hr * 60) + min) * 60 * 1000;
    //         break;

    //     case '-':
    //         hr = 10 * Character.digit(cast(char)buf[pos++], 10);
    //         hr += Character.digit(cast(char)buf[pos++], 10);
    //         min = 10 * Character.digit(cast(char)buf[pos++], 10);
    //         min += Character.digit(cast(char)buf[pos++], 10);

    //         if (hr >= 24 || min >= 60)
    //             throw new IOException("Parse " ~ type ~ " time, -hhmm");

    //         time += ((hr * 60) + min) * 60 * 1000;
    //         break;

    //     case 'Z':
    //         break;

    //     default:
    //         throw new IOException("Parse " ~ type ~ " time, garbage offset");
    //     }
    //     return new Date(time);
    // }
}
