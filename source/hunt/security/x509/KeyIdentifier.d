module hunt.security.x509.KeyIdentifier;

import hunt.security.x509.AlgorithmId;
import hunt.security.util.DerValue;
import hunt.security.util.DerOutputStream;

import hunt.security.key;
import hunt.util.exception;

import std.format;

/**
 * Represent the Key Identifier ASN.1 object.
 *
 * @author Amit Kapoor
 * @author Hemma Prafullchandra
 */
class KeyIdentifier {
    private byte[] octetString;

    /**
     * Create a KeyIdentifier with the passed bit settings.
     *
     * @param octetString the octet string identifying the key identifier.
     */
    this(byte[] octetString) {
        this.octetString = octetString.dup;
    }

    /**
     * Create a KeyIdentifier from the DER encoded value.
     *
     * @param val the DerValue
     */
    this(DerValue val) {
        octetString = val.getOctetString();
    }

    /**
     * Creates a KeyIdentifier from a public-key value.
     *
     * <p>From RFC2459: Two common methods for generating key identifiers from
     * the key are:
     * <ol>
     * <li>The keyIdentifier is composed of the 160-bit SHA-1 hash of the
     * value of the BIT STRING subjectPublicKey (excluding the tag,
     * length, and number of unused bits).
     * <p>
     * <li>The keyIdentifier is composed of a four bit type field with
     * the value 0100 followed by the least significant 60 bits of the
     * SHA-1 hash of the value of the BIT STRING subjectPublicKey.
     * </ol>
     * <p>This method supports method 1.
     *
     * @param pubKey the key from which to construct this KeyIdentifier
     * @throws IOException on parsing errors
     */
    this(PublicKey pubKey)
    {
        DerValue algAndKey = new DerValue(pubKey.getEncoded());
        if (algAndKey.tag != DerValue.tag_Sequence)
            throw new IOException("PublicKey value is not a valid "
                                  ~ "X.509 key");

        // AlgorithmId algid = AlgorithmId.parse(algAndKey.data.getDerValue());
        // byte[] key = algAndKey.data.getUnalignedBitString().toByteArray();

        // MessageDigest md = null;
        // try {
        //     md = MessageDigest.getInstance("SHA1");
        // } catch (NoSuchAlgorithmException e3) {
        //     throw new IOException("SHA1 not supported");
        // }
        // md.update(key);
        // this.octetString = md.digest();
        implementationMissing();
    }

    /**
     * Return the value of the KeyIdentifier as byte array.
     */
    byte[] getIdentifier() {
        return octetString.dup;
    }

    /**
     * Returns a printable representation of the KeyUsage.
     */
    override string toString() {
        // string s = "KeyIdentifier [\n";

        // HexDumpEncoder encoder = new HexDumpEncoder();
        // s += encoder.encodeBuffer(octetString);
        // s += "]\n";
        string s = format("KeyIdentifier [\n%(%02X%)]\n", octetString);
        return (s);
    }

    /**
     * Write the KeyIdentifier to the DerOutputStream.
     *
     * @param stream the DerOutputStream to write the object to.
     * @exception IOException
     */
    void encode(DerOutputStream stream) {
        stream.putOctetString(octetString);
    }

    /**
     * Returns a hash code value for this object.
     * Objects that are equal will also have the same hashcode.
     */
    override size_t toHash() @trusted const nothrow {
        size_t retval = 0;
        for (size_t i = 0; i < octetString.length; i++)
            retval += octetString[i] * i;
        return retval;
    }

    /**
     * Indicates whether some other object is "equal to" this one.
     */
    override bool opEquals(Object other) {
        if (this is other)
            return true;
        KeyIdentifier id = cast(KeyIdentifier)other;
        if(id is null)
            return false;
        byte[] otherString = id.octetString;
        return octetString == otherString;
    }
}