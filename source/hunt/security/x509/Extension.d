module hunt.security.x509.Extension;

import hunt.security.cert.Extension;

import hunt.security.util.DerValue;
import hunt.security.util.DerOutputStream;
import hunt.security.util.ObjectIdentifier;

import hunt.io.common;

/**
 * Represent a X509 Extension Attribute.
 *
 * <p>Extensions are additional attributes which can be inserted in a X509
 * v3 certificate. For example a "Driving License Certificate" could have
 * the driving license number as a extension.
 *
 * <p>Extensions are represented as a sequence of the extension identifier
 * (Object Identifier), a bool flag stating whether the extension is to
 * be treated as being critical and the extension value itself (this is again
 * a DER encoding of the extension value).
 * <pre>
 * ASN.1 definition of Extension:
 * Extension ::= SEQUENCE {
 *      ExtensionId     OBJECT IDENTIFIER,
 *      critical        BOOLEAN DEFAULT FALSE,
 *      extensionValue  OCTET STRING
 * }
 * </pre>
 * All subclasses need to implement a constructor of the form
 * <pre>
 *     <subclass> (Boolean, Object)
 * </pre>
 * where the Object is typically an array of DER encoded bytes.
 * <p>
 * @author Amit Kapoor
 * @author Hemma Prafullchandra
 */
class Extension : CertExtension {

    protected ObjectIdentifier  extensionId = null;
    protected bool           critical = false;
    protected byte[]            extensionValue = null;

    /**
     * Default constructor.  Used only by sub-classes.
     */
    this() { }

    /**
     * Constructs an extension from a DER encoded array of bytes.
     */
    this(DerValue derVal) {

        DerInputStream stream = derVal.toDerInputStream();

        // Object identifier
        extensionId = stream.getOID();

        // If the criticality flag was false, it will not have been encoded.
        DerValue val = stream.getDerValue();
        if (val.tag == DerValue.tag_Boolean) {
            critical = val.getBoolean();

            // Extension value (DER encoded)
            val = stream.getDerValue();
            extensionValue = val.getOctetString();
        } else {
            critical = false;
            extensionValue = val.getOctetString();
        }
    }

    /**
     * Constructs an Extension from individual components of ObjectIdentifier,
     * criticality and the DER encoded OctetString.
     *
     * @param extensionId the ObjectIdentifier of the extension
     * @param critical the bool indicating if the extension is critical
     * @param extensionValue the DER encoded octet string of the value.
     */
    this(ObjectIdentifier extensionId, bool critical,
                     byte[] extensionValue) {
        this.extensionId = extensionId;
        this.critical = critical;
        // passed in a DER encoded octet string, strip off the tag
        // and length
        DerValue inDerVal = new DerValue(extensionValue);
        this.extensionValue = inDerVal.getOctetString();
    }

    /**
     * Constructs an Extension from another extension. To be used for
     * creating decoded subclasses.
     *
     * @param ext the extension to create from.
     */
    this(Extension ext) {
        this.extensionId = ext.extensionId;
        this.critical = ext.critical;
        this.extensionValue = ext.extensionValue;
    }

    /**
     * Constructs an Extension from individual components of ObjectIdentifier,
     * criticality and the raw encoded extension value.
     *
     * @param extensionId the ObjectIdentifier of the extension
     * @param critical the bool indicating if the extension is critical
     * @param rawExtensionValue the raw DER-encoded extension value (this
     * is not the encoded OctetString).
     */
    static Extension newExtension(ObjectIdentifier extensionId,
        bool critical, byte[] rawExtensionValue) {
        Extension ext = new Extension();
        ext.extensionId = extensionId;
        ext.critical = critical;
        ext.extensionValue = rawExtensionValue;
        return ext;
    }

    void encode(OutputStream stream) {
        if (stream is null) {
            throw new NullPointerException();
        }

        DerOutputStream dos1 = new DerOutputStream();
        DerOutputStream dos2 = new DerOutputStream();

        dos1.putOID(extensionId);
        if (critical) {
            dos1.putBoolean(critical);
        }
        dos1.putOctetString(extensionValue);

        dos2.write(DerValue.tag_Sequence, dos1);
        stream.write(dos2.toByteArray());
    }

    /**
     * Write the extension to the DerOutputStream.
     *
     * @param stream the DerOutputStream to write the extension to.
     * @exception IOException on encoding errors
     */
    void encode(DerOutputStream stream) {

        if (extensionId is null)
            throw new IOException("Null OID to encode for the extension!");
        if (extensionValue is null)
            throw new IOException("No value to encode for the extension!");

        DerOutputStream dos = new DerOutputStream();

        dos.putOID(extensionId);
        if (critical)
            dos.putBoolean(critical);
        dos.putOctetString(extensionValue);

        stream.write(DerValue.tag_Sequence, dos);
    }

    /**
     * Returns true if extension is critical.
     */
    bool isCritical() {
        return critical;
    }

    /**
     * Returns the ObjectIdentifier of the extension.
     */
    ObjectIdentifier getExtensionId() {
        return extensionId;
    }

    byte[] getValue() {
        return extensionValue.clone();
    }

    /**
     * Returns the extension value as an byte array for further processing.
     * Note, this is the raw DER value of the extension, not the DER
     * encoded octet string which is in the certificate.
     * This method does not return a clone; it is the responsibility of the
     * caller to clone the array if necessary.
     */
    byte[] getExtensionValue() {
        return extensionValue;
    }

    string getId() {
        return extensionId.toString();
    }

    /**
     * Returns the Extension in user readable form.
     */
    override string toString() {
        string s = "ObjectId: " ~ extensionId.toString();
        if (critical) {
            s ~= " Criticality=true\n";
        } else {
            s ~= " Criticality=false\n";
        }
        return (s);
    }

    // Value to mix up the hash
    private enum int hashMagic = 31;

    /**
     * Returns a hashcode value for this Extension.
     *
     * @return the hashcode value.
     */
    override size_t toHash() @trusted const nothrow {
        size_t h = 0;
        if (extensionValue !is null) {
            byte[] val = extensionValue;
            size_t len = val.length;
            while (len > 0)
                h += len * val[--len];
        }
        h = h * hashMagic + extensionId.toHash();
        h = h * hashMagic + (critical?1231:1237);
        return h;
    }

    /**
     * Compares this Extension for equality with the specified
     * object. If the <code>other</code> object is an
     * <code>instanceof</code> <code>Extension</code>, then
     * its encoded form is retrieved and compared with the
     * encoded form of this Extension.
     *
     * @param other the object to test for equality with this Extension.
     * @return true iff the other object is of type Extension, and the
     * criticality flag, object identifier and encoded extension value of
     * the two Extensions match, false otherwise.
     */
    override bool opEquals(Object other) {
        if (this is other)
            return true;
        Extension otherExt = cast(Extension) other;
        if(otherExt is null)
            return false;
        if (critical != otherExt.critical)
            return false;
        if (!extensionId.opEquals(otherExt.extensionId))
            return false;
        return extensionValue == otherExt.extensionValue;
    }
}

alias X509Extension = Extension;