module hunt.security.x509.SerialNumber;

import hunt.security.util.DerValue;
import hunt.security.util.DerInputStream;
import hunt.security.util.DerOutputStream;

import hunt.io.common;

import std.bigint;

alias BigInteger = BigInt;

/**
 * This class defines the SerialNumber class used by certificates.
 *
 * @author Amit Kapoor
 * @author Hemma Prafullchandra
 */
class SerialNumber {
    private BigInteger  serialNum;

    // Construct the class from the DerValue
    private void construct(DerValue derVal) {
        serialNum = derVal.getBigInteger();
        if (derVal.data.available() != 0) {
            throw new IOException("Excess SerialNumber data");
        }
    }

    /**
     * The default constructor for this class using BigInteger.
     *
     * @param num the BigInteger number used to create the serial number.
     */
    this(BigInteger num) {
        serialNum = num;
    }

    /**
     * The default constructor for this class using int.
     *
     * @param num the BigInteger number used to create the serial number.
     */
    this(int num) {
        serialNum = BigInteger(num);
    }

    /**
     * Create the object, decoding the values from the passed DER stream.
     *
     * @param in the DerInputStream to read the SerialNumber from.
     * @exception IOException on decoding errors.
     */
    this(DerInputStream stream) {
        DerValue derVal = stream.getDerValue();
        construct(derVal);
    }

    /**
     * Create the object, decoding the values from the passed DerValue.
     *
     * @param val the DerValue to read the SerialNumber from.
     * @exception IOException on decoding errors.
     */
    this(DerValue val) {
        construct(val);
    }

    /**
     * Create the object, decoding the values from the passed stream.
     *
     * @param stream the InputStream to read the SerialNumber from.
     * @exception IOException on decoding errors.
     */
    this(InputStream stream) {
        DerValue derVal = new DerValue(stream);
        construct(derVal);
    }

    /**
     * Return the SerialNumber as user readable string.
     */
    override string toString() {
        return ("SerialNumber: [" ~ Debug.toHexString(serialNum) ~ "]");
    }

    /**
     * Encode the SerialNumber in DER form to the stream.
     *
     * @param stream the DerOutputStream to marshal the contents to.
     * @exception IOException on errors.
     */
    void encode(DerOutputStream stream) {
        stream.putInteger(serialNum);
    }

    /**
     * Return the serial number.
     */
    BigInteger getNumber() {
        return serialNum;
    }
}
