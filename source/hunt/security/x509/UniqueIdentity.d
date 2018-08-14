module hunt.security.x509.UniqueIdentity;

import hunt.security.util.DerValue;
import hunt.security.util.DerInputStream;
import hunt.security.util.DerOutputStream;

import hunt.util.exception;
import std.bitmanip;


/**
 * This class defines the UniqueIdentity class used by certificates.
 *
 * @author Amit Kapoor
 * @author Hemma Prafullchandra
 */
class UniqueIdentity {
    // Private data members
    private BitArray    id;

    /**
     * The default constructor for this class.
     *
     * @param id the byte array containing the unique identifier.
     */
    this(BitArray id) {
        this.id = id;
    }

    /**
     * The default constructor for this class.
     *
     * @param id the byte array containing the unique identifier.
     */
    this(byte[] id) {
        // this.id = new BitArray(id.length*8, id);
        implementationMissing();
    }

    /**
     * Create the object, decoding the values from the passed DER stream.
     *
     * @param stream the DerInputStream to read the UniqueIdentity from.
     * @exception IOException on decoding errors.
     */
    this(DerInputStream stream) {
        DerValue derVal = stream.getDerValue();
        id = derVal.getUnalignedBitString(true);
    }

    /**
     * Create the object, decoding the values from the passed DER stream.
     *
     * @param derVal the DerValue decoded from the stream.
     * @param tag the tag the value is encoded under.
     * @exception IOException on decoding errors.
     */
    this(DerValue derVal) {
        id = derVal.getUnalignedBitString(true);
    }

    /**
     * Return the UniqueIdentity as a printable string.
     */
    override string toString() {
        return ("UniqueIdentity:" ~ id.toString() ~ "\n");
    }

    /**
     * Encode the UniqueIdentity in DER form to the stream.
     *
     * @param stream the DerOutputStream to marshal the contents to.
     * @param tag enocode it under the following tag.
     * @exception IOException on errors.
     */
    void encode(DerOutputStream stream, byte tag) {
        byte[] bytes = id.toByteArray();
        int excessBits = bytes.length*8 - id.length();

        stream.write(tag);
        stream.putLength(bytes.length + 1);

        stream.write(excessBits);
        stream.write(bytes);
    }

    /**
     * Return the unique id.
     */
    bool[] getId() {
        if (id is null) return null;

        return id.toBooleanArray();
    }
}
