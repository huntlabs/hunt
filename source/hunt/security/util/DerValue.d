module hunt.security.util.DerValue;

import hunt.security.util.DerOutputStream;
import hunt.io.common;
import hunt.util.exception;

import std.conv;
import std.bigint;
import std.bitmanip;
import std.datetime;


/**
 * Represents a single DER-encoded value.  DER encoding rules are a subset
 * of the "Basic" Encoding Rules (BER), but they only support a single way
 * ("Definite" encoding) to encode any given value.
 *
 * <P>All DER-encoded data are triples <em>{type, length, data}</em>.  This
 * class represents such tagged values as they have been read (or constructed),
 * and provides structured access to the encoded data.
 *
 * <P>At this time, this class supports only a subset of the types of DER
 * data encodings which are defined.  That subset is sufficient for parsing
 * most X.509 certificates, and working with selected additional formats
 * (such as PKCS #10 certificate requests, and some kinds of PKCS #7 data).
 *
 * A note with respect to T61/Teletex strings: From RFC 1617, section 4.1.3
 * and RFC 3280, section 4.1.2.4., we assume that this kind of string will
 * contain ISO-8859-1 characters only.
 *
 *
 * @author David Brownell
 * @author Amit Kapoor
 * @author Hemma Prafullchandra
 */
class DerValue {
    /** The tag class types */
    enum byte TAG_UNIVERSAL = cast(byte)0x000;
    enum byte TAG_APPLICATION = cast(byte)0x040;
    enum byte TAG_CONTEXT = cast(byte)0x080;
    enum byte TAG_PRIVATE = cast(byte)0x0c0;

    /** The DER tag of the value; one of the tag_ constants. */
    byte                 tag;

    // protected DerInputBuffer    buffer;

    /**
     * The DER-encoded data of the value, never null
     */
    // DerInputStream data;

    private int                 _length;

    /*
     * The type starts at the first byte of the encoding, and
     * is one of these tag_* values.  That may be all the type
     * data that is needed.
     */

    /*
     * These tags are the "universal" tags ... they mean the same
     * in all contexts.  (Mask with 0x1f -- five bits.)
     */

    /** Tag value indicating an ASN.1 "BOOLEAN" value. */
    enum byte    tag_Boolean = 0x01;

    /** Tag value indicating an ASN.1 "INTEGER" value. */
    enum byte    tag_Integer = 0x02;

    /** Tag value indicating an ASN.1 "BIT STRING" value. */
    enum byte    tag_BitString = 0x03;

    /** Tag value indicating an ASN.1 "OCTET STRING" value. */
    enum byte    tag_OctetString = 0x04;

    /** Tag value indicating an ASN.1 "NULL" value. */
    enum byte    tag_Null = 0x05;

    /** Tag value indicating an ASN.1 "OBJECT IDENTIFIER" value. */
    enum byte    tag_ObjectId = 0x06;

    /** Tag value including an ASN.1 "ENUMERATED" value */
    enum byte    tag_Enumerated = 0x0A;

    /** Tag value indicating an ASN.1 "UTF8String" value. */
    enum byte    tag_UTF8String = 0x0C;

    /** Tag value including a "printable" string */
    enum byte    tag_PrintableString = 0x13;

    /** Tag value including a "teletype" string */
    enum byte    tag_T61String = 0x14;

    /** Tag value including an ASCII string */
    enum byte    tag_IA5String = 0x16;

    /** Tag value indicating an ASN.1 "UTCTime" value. */
    enum byte    tag_UtcTime = 0x17;

    /** Tag value indicating an ASN.1 "GeneralizedTime" value. */
    enum byte    tag_GeneralizedTime = 0x18;

    /** Tag value indicating an ASN.1 "GenerallString" value. */
    enum byte    tag_GeneralString = 0x1B;

    /** Tag value indicating an ASN.1 "UniversalString" value. */
    enum byte    tag_UniversalString = 0x1C;

    /** Tag value indicating an ASN.1 "BMPString" value. */
    enum byte    tag_BMPString = 0x1E;

    // CONSTRUCTED seq/set

    /**
     * Tag value indicating an ASN.1
     * "SEQUENCE" (zero to N elements, order is significant).
     */
    enum byte    tag_Sequence = 0x30;

    /**
     * Tag value indicating an ASN.1
     * "SEQUENCE OF" (one to N elements, order is significant).
     */
    enum byte    tag_SequenceOf = 0x30;

    /**
     * Tag value indicating an ASN.1
     * "SET" (zero to N members, order does not matter).
     */
    enum byte    tag_Set = 0x31;

    /**
     * Tag value indicating an ASN.1
     * "SET OF" (one to N members, order does not matter).
     */
    enum byte    tag_SetOf = 0x31;

    /*
     * These values are the high order bits for the other kinds of tags.
     */

    /**
     * Returns true if the tag class is UNIVERSAL.
     */
    bool isUniversal()      { return ((tag & 0x0c0) == 0x000); }

    /**
     * Returns true if the tag class is APPLICATION.
     */
    bool isApplication()    { return ((tag & 0x0c0) == 0x040); }

    /**
     * Returns true iff the CONTEXT SPECIFIC bit is set in the type tag.
     * This is associated with the ASN.1 "DEFINED BY" syntax.
     */
    bool isContextSpecific() { return ((tag & 0x0c0) == 0x080); }

    /**
     * Returns true iff the CONTEXT SPECIFIC TAG matches the passed tag.
     */
    bool isContextSpecific(byte cntxtTag) {
        if (!isContextSpecific()) {
            return false;
        }
        return ((tag & 0x01f) == cntxtTag);
    }

    bool isPrivate()        { return ((tag & 0x0c0) == 0x0c0); }

    /** Returns true iff the CONSTRUCTED bit is set in the type tag. */
    bool isConstructed()    { return ((tag & 0x020) == 0x020); }

    /**
     * Returns true iff the CONSTRUCTED TAG matches the passed tag.
     */
    bool isConstructed(byte constructedTag) {
        if (!isConstructed()) {
            return false;
        }
        return ((tag & 0x01f) == constructedTag);
    }

    /**
     * Creates a PrintableString or UTF8string DER value from a string
     */
    this(string value) {
        bool isPrintableString = true;
        for (size_t i = 0; i < value.length; i++) {
            if (!isPrintableStringChar(value[i])) {
                isPrintableString = false;
                break;
            }
        }

        // data = init(isPrintableString ? tag_PrintableString : tag_UTF8String, value);
    }

    /**
     * Creates a string type DER value from a string object
     * @param stringTag the tag for the DER value to create
     * @param value the string object to use for the DER value
     */
    this(byte stringTag, string value) {
        // data = init(stringTag, value);
    }

    // Creates a DerValue from a tag and some DER-encoded data w/ additional
    // arg to control whether DER checks are enforced.
    this(byte tag, byte[] data, bool allowBER) {
        this.tag = tag;
        // buffer = new DerInputBuffer(data.clone(), allowBER);
        _length = cast(int)data.length;
        // this.data = new DerInputStream(buffer);
        // this.data.mark(int.max);
    }

    /**
     * Creates a DerValue from a tag and some DER-encoded data.
     *
     * @param tag the DER type tag
     * @param data the DER-encoded data
     */
    this(byte tag, byte[] data) {
        this(tag, data, true);
    }

    /*
     * package private
     */
    // this(DerInputBuffer ib) {

    //     // XXX must also parse BER-encoded constructed
    //     // values such as sequences, sets...
    //     tag = cast(byte)ib.read();
    //     byte lenByte = cast(byte)ib.read();
    //     length = DerInputStream.getLength(lenByte, ib);
    //     if (length == -1) {  // indefinite length encoding found
    //         DerInputBuffer inbuf = ib.dup();
    //         int readLen = inbuf.available();
    //         int offset = 2;     // for tag and length bytes
    //         byte[] indefData = new byte[readLen + offset];
    //         indefData[0] = tag;
    //         indefData[1] = lenByte;
    //         DataInputStream dis = new DataInputStream(inbuf);
    //         dis.readFully(indefData, offset, readLen);
    //         dis.close();
    //         DerIndefLenConverter derIn = new DerIndefLenConverter();
    //         inbuf = new DerInputBuffer(derIn.convert(indefData), ib.allowBER);
    //         if (tag != inbuf.read())
    //             throw new IOException
    //                     ("Indefinite length encoding not supported");
    //         length = DerInputStream.getLength(inbuf);
    //         buffer = inbuf.dup();
    //         buffer.truncate(length);
    //         data = new DerInputStream(buffer);
    //         // indefinite form is encoded by sending a length field with a
    //         // length of 0. - i.e. [1000|0000].
    //         // the object is ended by sending two zero bytes.
    //         ib.skip(length + offset);
    //     } else {

    //         buffer = ib.dup();
    //         buffer.truncate(length);
    //         data = new DerInputStream(buffer);

    //         ib.skip(length);
    //     }
    // }

    // Get an ASN.1/DER encoded datum from a buffer w/ additional
    // arg to control whether DER checks are enforced.
    this(byte[] buf, bool allowBER) {
        implementationMissing();
        // data = init(true, new ByteArrayInputStream(buf), allowBER);
    }

    /**
     * Get an ASN.1/DER encoded datum from a buffer.  The
     * entire buffer must hold exactly one datum, including
     * its tag and length.
     *
     * @param buf buffer holding a single DER-encoded datum.
     */
    this(byte[] buf) {
        this(buf, true);
    }

    // Get an ASN.1/DER encoded datum from part of a buffer w/ additional
    // arg to control whether DER checks are enforced.
    this(byte[] buf, int offset, int len, bool allowBER)
        {

        implementationMissing();
        // data = init(true, new ByteArrayInputStream(buf, offset, len), allowBER);
    }

    /**
     * Get an ASN.1/DER encoded datum from part of a buffer.
     * That part of the buffer must hold exactly one datum, including
     * its tag and length.
     *
     * @param buf the buffer
     * @param offset start point of the single DER-encoded dataum
     * @param length how many bytes are in the encoded datum
     */
    this(byte[] buf, int offset, int len) {
        this(buf, offset, len, true);
    }

    // Get an ASN1/DER encoded datum from an input stream w/ additional
    // arg to control whether DER checks are enforced.
    this(InputStream inputStream, bool allowBER) {
        // data = init(false, inputStream, allowBER);
        implementationMissing();
    }

    /**
     * Get an ASN1/DER encoded datum from an input stream.  The
     * stream may have additional data following the encoded datum.
     * In case of indefinite length encoded datum, the input stream
     * must hold only one datum.
     *
     * @param in the input stream holding a single DER datum,
     *  which may be followed by additional data
     */
    this(InputStream inputStream) {
        this(inputStream, true);
    }

    // private DerInputStream init(byte stringTag, string value)
    //     {
    //     string enc = null;

    //     tag = stringTag;

    //     switch (stringTag) {
    //     case tag_PrintableString:
    //     case tag_IA5String:
    //     case tag_GeneralString:
    //         enc = "ASCII";
    //         break;
    //     case tag_T61String:
    //         enc = "ISO-8859-1";
    //         break;
    //     case tag_BMPString:
    //         enc = "UnicodeBigUnmarked";
    //         break;
    //     case tag_UTF8String:
    //         enc = "UTF8";
    //         break;
    //         // TBD: Need encoder for UniversalString before it can
    //         // be handled.
    //     default:
    //         throw new IllegalArgumentException("Unsupported DER string type");
    //     }

    //     byte[] buf = value.getBytes(enc);
    //     length = buf.length;
    //     buffer = new DerInputBuffer(buf, true);
    //     DerInputStream result = new DerInputStream(buffer);
    //     result.mark(int.max);
    //     return result;
    // }

    // /*
    //  * helper routine
    //  */
    // private DerInputStream init(bool fullyBuffered, InputStream inputStream,
    //     bool allowBER) {

    //     tag = cast(byte)inputStream.read();
    //     byte lenByte = cast(byte)inputStream.read();
    //     length = DerInputStream.getLength(lenByte, inputStream);
    //     if (length == -1) { // indefinite length encoding found
    //         int readLen = inputStream.available();
    //         int offset = 2;     // for tag and length bytes
    //         byte[] indefData = new byte[readLen + offset];
    //         indefData[0] = tag;
    //         indefData[1] = lenByte;
    //         DataInputStream dis = new DataInputStream(inputStream);
    //         dis.readFully(indefData, offset, readLen);
    //         dis.close();
    //         DerIndefLenConverter derIn = new DerIndefLenConverter();
    //         inputStream = new ByteArrayInputStream(derIn.convert(indefData));
    //         if (tag != inputStream.read())
    //             throw new IOException
    //                     ("Indefinite length encoding not supported");
    //         length = DerInputStream.getLength(inputStream);
    //     }

    //     if (fullyBuffered && inputStream.available() != length)
    //         throw new IOException("extra data given to DerValue constructor");

    //     byte[] bytes = IOUtils.readFully(inputStream, length, true);

    //     buffer = new DerInputBuffer(bytes, allowBER);
    //     return new DerInputStream(buffer);
    // }

    // /**
    //  * Encode an ASN1/DER encoded datum onto a DER output stream.
    //  */
    // void encode(DerOutputStream ot)
    // {
    //     ot.write(tag);
    //     ot.putLength(length);
    //     // XXX yeech, excess copies ... DerInputBuffer.write(OutStream)
    //     if (length > 0) {
    //         byte[] value = new byte[length];
    //         // always synchronized on data
    //         synchronized (data) {
    //             buffer.reset();
    //             if (buffer.read(value) != length) {
    //                 throw new IOException("short DER value read (encode)");
    //             }
    //             ot.write(value);
    //         }
    //     }
    // }

    // final DerInputStream getData() {
    //     return data;
    // }

    final byte getTag() {
        return tag;
    }

    /**
     * Returns an ASN.1 BOOLEAN
     *
     * @return the bool held in this DER value
     */
    bool getBoolean() {
        if (tag != tag_Boolean) {
            throw new IOException("DerValue.getBoolean, not a BOOLEAN " ~ tag);
        }
        if (length != 1) {
            throw new IOException("DerValue.getBoolean, invalid length "
                                        ~ length.to!string());
        }
        // if (buffer.read() != 0) {
        //     return true;
        // }
        implementationMissing();
        return false;
    }

    /**
     * Returns an ASN.1 OBJECT IDENTIFIER.
     *
     * @return the OID held in this DER value
     */
    // ObjectIdentifier getOID() {
    //     if (tag != tag_ObjectId)
    //         throw new IOException("DerValue.getOID, not an OID " ~ tag);
    //     return new ObjectIdentifier(buffer);
    // }

    private byte[] append(byte[] a, byte[] b) {
        if (a is null)
            return b;

        // byte[] ret = new byte[a.length + b.length];
        // ret = a ~ b;
        // System.arraycopy(a, 0, ret, 0, a.length);
        // System.arraycopy(b, 0, ret, a.length, b.length);

        return a ~ b;
    }

    /**
     * Returns an ASN.1 OCTET STRING
     *
     * @return the octet string held in this DER value
     */
    byte[] getOctetString() {
        byte[] bytes;

        if (tag != tag_OctetString && !isConstructed(tag_OctetString)) {
            throw new IOException(
                "DerValue.getOctetString, not an Octet string: " ~ tag);
        }
        bytes = new byte[length];
        // Note: do not tempt to call buffer.read(bytes) at all. There's a
        // known bug that it returns -1 instead of 0.
        if (length == 0) {
            return bytes;
        }
        // if (buffer.read(bytes) != length)
        //     throw new IOException("short read on DerValue buffer");
        // if (isConstructed()) {
        //     DerInputStream inputStream = new DerInputStream(bytes, 0, bytes.length,
        //         buffer.allowBER);
        //     bytes = null;
        //     while (inputStream.available() != 0) {
        //         bytes = append(bytes, inputStream.getOctetString());
        //     }
        // }
        implementationMissing();
        return bytes;
    }

    /**
     * Returns an ASN.1 INTEGER value as an integer.
     *
     * @return the integer held in this DER value.
     */
    int getInteger() {
        if (tag != tag_Integer) {
            throw new IOException("DerValue.getInteger, not an int " ~ tag);
        }
        implementationMissing();
        return 0 ; //buffer.getInteger(data.available());
    }

    /**
     * Returns an ASN.1 INTEGER value as a BigInt.
     *
     * @return the integer held in this DER value as a BigInt.
     */
    BigInt getBigInteger() {
        if (tag != tag_Integer)
            throw new IOException("DerValue.getBigInteger, not an int " ~ tag);
        // return buffer.getBigInteger(data.available(), false);
        implementationMissing();
        return BigInt(0);
    }

    /**
     * Returns an ASN.1 INTEGER value as a positive BigInt.
     * This is just to deal with implementations that incorrectly encode
     * some values as negative.
     *
     * @return the integer held in this DER value as a BigInt.
     */
    BigInt getPositiveBigInteger() {
        if (tag != tag_Integer)
            throw new IOException("DerValue.getBigInteger, not an int " ~ tag);
        // return buffer.getBigInteger(data.available(), true);
        implementationMissing();
        return BigInt(0);
    }

    /**
     * Returns an ASN.1 ENUMERATED value.
     *
     * @return the integer held in this DER value.
     */
    // int getEnumerated() {
    //     if (tag != tag_Enumerated) {
    //         throw new IOException("DerValue.getEnumerated, incorrect tag: "
    //                               + tag);
    //     }
    //     return buffer.getInteger(data.available());
    // }

    /**
     * Returns an ASN.1 BIT STRING value.  The bit string must be byte-aligned.
     *
     * @return the bit string held in this value
     */
    // byte[] getBitString() {
    //     if (tag != tag_BitString)
    //         throw new IOException(
    //             "DerValue.getBitString, not a bit string " ~ tag);

    //     return buffer.getBitString();
    // }

    /**
     * Returns an ASN.1 BIT STRING value that need not be byte-aligned.
     *
     * @return a BitArray representing the bit string held in this value
     */
    // BitArray getUnalignedBitString() {
    //     if (tag != tag_BitString)
    //         throw new IOException(
    //             "DerValue.getBitString, not a bit string " ~ tag);

    //     return buffer.getUnalignedBitString();
    // }

    /**
     * Returns the name component as a Java string, regardless of its
     * encoding restrictions (ASCII, T61, Printable, IA5, BMP, UTF8).
     */
    // TBD: Need encoder for UniversalString before it can be handled.
    string getAsString() {
        if (tag == tag_UTF8String)
            return getUTF8String();
        else if (tag == tag_PrintableString)
            return getPrintableString();
        else if (tag == tag_T61String)
            return getT61String();
        else if (tag == tag_IA5String)
            return getIA5String();
        /*
          else if (tag == tag_UniversalString)
          return getUniversalString();
        */
        else if (tag == tag_BMPString)
            return getBMPString();
        else if (tag == tag_GeneralString)
            return getGeneralString();
        else
            return null;
    }

    /**
     * Returns an ASN.1 BIT STRING value, with the tag assumed implicit
     * based on the parameter.  The bit string must be byte-aligned.
     *
     * @params tagImplicit if true, the tag is assumed implicit.
     * @return the bit string held in this value
     */
    // byte[] getBitString(bool tagImplicit) {
    //     if (!tagImplicit) {
    //         if (tag != tag_BitString)
    //             throw new IOException("DerValue.getBitString, not a bit string "
    //                                    + tag);
    //         }
    //     return buffer.getBitString();
    // }

    /**
     * Returns an ASN.1 BIT STRING value, with the tag assumed implicit
     * based on the parameter.  The bit string need not be byte-aligned.
     *
     * @params tagImplicit if true, the tag is assumed implicit.
     * @return the bit string held in this value
     */
    // BitArray getUnalignedBitString(bool tagImplicit)
    // {
    //     if (!tagImplicit) {
    //         if (tag != tag_BitString)
    //             throw new IOException("DerValue.getBitString, not a bit string "
    //                                    ~ tag.to!string());
    //         }
    //     return buffer.getUnalignedBitString();
    // }

    /**
     * Helper routine to return all the bytes contained in the
     * DerInputStream associated with this object.
     */
    byte[] getDataBytes() {
        byte[] retVal = new byte[length];
        // synchronized (data) {
        //     data.reset();
        //     data.getBytes(retVal);
        // }
        implementationMissing();
        return retVal;
    }

    /**
     * Returns an ASN.1 STRING value
     *
     * @return the printable string held in this value
     */
    string getPrintableString()
    {
        if (tag != tag_PrintableString)
            throw new IOException(
                "DerValue.getPrintableString, not a string " ~ tag);

        return cast(string)getDataBytes();
    }

    /**
     * Returns an ASN.1 T61 (Teletype) STRING value
     *
     * @return the teletype string held in this value
     */
    string getT61String() {
        if (tag != tag_T61String)
            throw new IOException(
                "DerValue.getT61String, not T61 " ~ tag);

        return cast(string)getDataBytes();
    }

    /**
     * Returns an ASN.1 IA5 (ASCII) STRING value
     *
     * @return the ASCII string held in this value
     */
    string getIA5String() {
        if (tag != tag_IA5String)
            throw new IOException(
                "DerValue.getIA5String, not IA5 " ~ tag);

        return cast(string)getDataBytes();
    }

    /**
     * Returns the ASN.1 BMP (Unicode) STRING value as a Java string.
     *
     * @return a string corresponding to the encoded BMPString held in
     * this value
     */
    string getBMPString() {
        if (tag != tag_BMPString)
            throw new IOException(
                "DerValue.getBMPString, not BMP " ~ tag);

        // BMPString is the same as Unicode in big endian, unmarked
        // format.
        return cast(string)getDataBytes();
    }

    /**
     * Returns the ASN.1 UTF-8 STRING value as a Java string.
     *
     * @return a string corresponding to the encoded UTF8String held in
     * this value
     */
    string getUTF8String() {
        if (tag != tag_UTF8String)
            throw new IOException(
                "DerValue.getUTF8String, not UTF-8 " ~ tag);

        return cast(string)getDataBytes();
    }

    /**
     * Returns the ASN.1 GENERAL STRING value as a Java string.
     *
     * @return a string corresponding to the encoded GeneralString held in
     * this value
     */
    string getGeneralString() {
        if (tag != tag_GeneralString)
            throw new IOException(
                "DerValue.getGeneralString, not GeneralString " ~ tag);

        return cast(string)getDataBytes();
    }

    /**
     * Returns a Date if the DerValue is UtcTime.
     *
     * @return the Date held in this DER value
     */
    // Date getUTCTime() {
    //     if (tag != tag_UtcTime) {
    //         throw new IOException("DerValue.getUTCTime, not a UtcTime: " ~ tag);
    //     }
    //     return buffer.getUTCTime(data.available());
    // }

    /**
     * Returns a Date if the DerValue is GeneralizedTime.
     *
     * @return the Date held in this DER value
     */
    // Date getGeneralizedTime() {
    //     if (tag != tag_GeneralizedTime) {
    //         throw new IOException(
    //             "DerValue.getGeneralizedTime, not a GeneralizedTime: " ~ tag);
    //     }
    //     return buffer.getGeneralizedTime(data.available());
    // }

    /**
     * Returns true iff the other object is a DER value which
     * is bitwise equal to this one.
     *
     * @param other the object being compared with this one
     */
    override
    bool opEquals(Object other) {
        if (typeid(other) == typeid(DerValue))
            return opEquals(cast(DerValue)other);
        else
            return false;
    }

    /**
     * Bitwise equality comparison.  DER encoded values have a single
     * encoding, so that bitwise equality of the encoded values is an
     * efficient way to establish equivalence of the unencoded values.
     *
     * @param other the object being compared with this one
     */
    bool opEquals(DerValue other) {
        if (this is other) {
            return true;
        }
        if (tag != other.tag) {
            return false;
        }
        implementationMissing();
        return false;
        // if (data == other.data) {
        //     return true;
        // }

        // // make sure the order of lock is always consistent to avoid a deadlock
        // return hashOf(this.data)
        //         > hashOf(other.data) ?
        //         doEquals(this, other):
        //         doEquals(other, this);
    }

    /**
     * Helper for method equals()
     */
    private static bool doEquals(DerValue d1, DerValue d2) {
        // synchronized (d1.data) {
        //     synchronized (d2.data) {
        //         d1.data.reset();
        //         d2.data.reset();
        //         return d1.buffer.equals(d2.buffer);
        //     }
        // }
        implementationMissing();
        return false;
    }

    /**
     * Returns a printable representation of the value.
     *
     * @return printable representation of the value
     */
    override string toString() {
        try {

            string str = getAsString();
            if (str !is null)
                return "\"" ~ str ~ "\"";
            if (tag == tag_Null)
                return "[DerValue, null]";
            // if (tag == tag_ObjectId)
            //     return "OID." ~ getOID();

            // integers
            else
                return "[DerValue, tag = " ~ tag
                        ~ ", length = " ~ _length.to!string() ~ "]";
        } catch (IOException e) {
            throw new IllegalArgumentException("misformatted DER value");
        }
    }

    /**
     * Returns a DER-encoded value, such that if it's passed to the
     * DerValue constructor, a value equivalent to "this" is returned.
     *
     * @return DER-encoded value, including tag and length.
     */
    byte[] toByteArray() {
        DerOutputStream ot = new DerOutputStream();
implementationMissing();
        // encode(ot);
        // data.reset();
        return ot.toByteArray();
    }

    /**
     * For "set" and "sequence" types, this function may be used
     * to return a DER stream of the members of the set or sequence.
     * This operation is not supported for primitive types such as
     * integers or bit strings.
     */
    // DerInputStream toDerInputStream() {
    //     if (tag == tag_Sequence || tag == tag_Set)
    //         return new DerInputStream(buffer);
    //     throw new IOException("toDerInputStream rejects tag type " ~ tag);
    // }

    /**
     * Get the length of the encoded value.
     */
    int length() {
        return _length;
    }

    /**
     * Determine if a character is one of the permissible characters for
     * PrintableString:
     * A-Z, a-z, 0-9, space, apostrophe (39), left and right parentheses,
     * plus sign, comma, hyphen, period, slash, colon, equals sign,
     * and question mark.
     *
     * Characters that are *not* allowed in PrintableString include
     * exclamation point, quotation mark, number sign, dollar sign,
     * percent sign, ampersand, asterisk, semicolon, less than sign,
     * greater than sign, at sign, left and right square brackets,
     * backslash, circumflex (94), underscore, back quote (96),
     * left and right curly brackets, vertical line, tilde,
     * and the control codes (0-31 and 127).
     *
     * This list is based on X.680 (the ASN.1 spec).
     */
    static bool isPrintableStringChar(char ch) {
        if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') ||
            (ch >= '0' && ch <= '9')) {
            return true;
        } else {
            switch (ch) {
                case ' ':       /* space */
                case '\'':      /* apostrophe */
                case '(':       /* left paren */
                case ')':       /* right paren */
                case '+':       /* plus */
                case ',':       /* comma */
                case '-':       /* hyphen */
                case '.':       /* period */
                case '/':       /* slash */
                case ':':       /* colon */
                case '=':       /* equals */
                case '?':       /* question mark */
                    return true;
                default:
                    return false;
            }
        }
    }

    /**
     * Create the tag of the attribute.
     *
     * @params class the tag class type, one of UNIVERSAL, CONTEXT,
     *               APPLICATION or PRIVATE
     * @params form if true, the value is constructed, otherwise it
     * is primitive.
     * @params val the tag value
     */
    static byte createTag(byte tagClass, bool form, byte val) {
        byte tag = cast(byte)(tagClass | val);
        if (form) {
            tag |= cast(byte)0x20;
        }
        return (tag);
    }

    /**
     * Set the tag of the attribute. Commonly used to reset the
     * tag value used for IMPLICIT encodings.
     *
     * @params tag the tag value
     */
    void resetTag(byte tag) {
        this.tag = tag;
    }

    /**
     * Returns a hashcode for this DerValue.
     *
     * @return a hashcode for this DerValue.
     */
    override size_t toHash() @trusted nothrow {
        try
        {
            string s = toString(); 
            return hashOf(toString());
        }
        catch(Exception)
        {
            return super.toHash();
        }
    }
}
