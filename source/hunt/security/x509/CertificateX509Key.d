module hunt.security.x509.CertificateX509Key;

import hunt.security.x509.CertAttrSet;

import hunt.security.key;
import hunt.security.util.DerInputStream;
import hunt.security.util.DerOutputStream;

import hunt.container.Enumeration;
import hunt.io.common;

/**
 * This class defines the X509Key attribute for the Certificate.
 *
 * @author Amit Kapoor
 * @author Hemma Prafullchandra
 * @see CertAttrSet
 */
class CertificateX509Key : CertAttrSet!string {
    /**
     * Identifier for this attribute, to be used with the
     * get, set, delete methods of Certificate, x509 type.
     */
    enum string IDENT = "x509.info.key";
    /**
     * Sub attributes name for this CertAttrSet.
     */
    enum string NAME = "key";
    enum string KEY = "value";

    // Private data member
    private PublicKey key;

    /**
     * Default constructor for the certificate attribute.
     *
     * @param key the X509Key
     */
    this(PublicKey key) {
        this.key = key;
    }

    /**
     * Create the object, decoding the values from the passed DER stream.
     *
     * @param stream the DerInputStream to read the X509Key from.
     * @exception IOException on decoding errors.
     */
    this(DerInputStream stream) {
        DerValue val = stream.getDerValue();
        key = X509Key.parse(val);
    }

    /**
     * Create the object, decoding the values from the passed stream.
     *
     * @param stream the InputStream to read the X509Key from.
     * @exception IOException on decoding errors.
     */
    this(InputStream stream) {
        DerValue val = new DerValue(stream);
        key = X509Key.parse(val);
    }

    /**
     * Return the key as printable string.
     */
    override string toString() {
        if (key is null) return "";
        return(key.toString());
    }

    /**
     * Encode the key in DER form to the stream.
     *
     * @param stream the OutputStream to marshal the contents to.
     * @exception IOException on errors.
     */
    void encode(OutputStream stream) {
        DerOutputStream tmp = new DerOutputStream();
        tmp.write(key.getEncoded());

        stream.write(tmp.toByteArray());
    }

    /**
     * Set the attribute value.
     */
    void set(string name, Object obj) {
        if (name.equalsIgnoreCase(KEY)) {
            this.key = cast(PublicKey)obj;
        } else {
            throw new IOException("Attribute name not recognized by " ~
                                  "CertAttrSet: CertificateX509Key.");
        }
    }

    /**
     * Get the attribute value.
     */
    PublicKey get(string name) {
        if (name.equalsIgnoreCase(KEY)) {
            return(key);
        } else {
            throw new IOException("Attribute name not recognized by " ~
                                  "CertAttrSet: CertificateX509Key.");
        }
    }

    /**
     * Delete the attribute value.
     */
    void remove(string name) {
      if (name.equalsIgnoreCase(KEY)) {
        key = null;
      } else {
            throw new IOException("Attribute name not recognized by " ~
                                  "CertAttrSet: CertificateX509Key.");
      }
    }

    /**
     * Return an enumeration of names of attributes existing within this
     * attribute.
     */
    Enumeration!string getElements() {
        AttributeNameEnumeration elements = new AttributeNameEnumeration();
        elements.addElement(KEY);

        return(elements.elements());
    }

    /**
     * Return the name of this attribute.
     */
    string getName() {
        return(NAME);
    }
}
