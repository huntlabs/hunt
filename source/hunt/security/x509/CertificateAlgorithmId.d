module hunt.security.x509.CertificateAlgorithmId;

import hunt.security.x509.AlgorithmId;
import hunt.security.x509.CertAttrSet;

import hunt.security.util.DerValue;
import hunt.security.util.DerInputStream;
import hunt.security.util.DerOutputStream;

import hunt.util.exception;
import hunt.util.string;

import hunt.io.common;
import hunt.container;

import std.conv;


/**
 * This class defines the AlgorithmId for the Certificate.
 *
 * @author Amit Kapoor
 * @author Hemma Prafullchandra
 */
class CertificateAlgorithmId : CertAttrSet!(string, AlgorithmId) {
    private AlgorithmId algId;

    /**
     * Identifier for this attribute, to be used with the
     * get, set, delete methods of Certificate, x509 type.
     */
    enum string IDENT = "x509.info.algorithmID";
    /**
     * Sub attributes name for this CertAttrSet.
     */
    enum string NAME = "algorithmID";

    /**
     * Identifier to be used with get, set, and delete methods. When
     * using this identifier the associated object being passed in or
     * returned is an instance of AlgorithmId.
     * @see sun.security.x509.AlgorithmId
     */
    enum string ALGORITHM = "algorithm";

    /**
     * Default constructor for the certificate attribute.
     *
     * @param algId the Algorithm identifier
     */
    this(AlgorithmId algId) {
        this.algId = algId;
    }

    /**
     * Create the object, decoding the values from the passed DER stream.
     *
     * @param stream the DerInputStream to read the serial number from.
     * @exception IOException on decoding errors.
     */
    this(DerInputStream stream) {
        DerValue val = stream.getDerValue();
        algId = AlgorithmId.parse(val);
    }

    /**
     * Create the object, decoding the values from the passed stream.
     *
     * @param stream the InputStream to read the serial number from.
     * @exception IOException on decoding errors.
     */
    this(InputStream stream) {
        DerValue val = new DerValue(stream);
        algId = AlgorithmId.parse(val);
    }

    /**
     * Return the algorithm identifier as user readable string.
     */
    override string toString() {
        if (algId is null) return "";
        return (algId.toString() ~
                ", OID = " ~ (algId.getOID()).toString() ~ "\n");
    }

    /**
     * Encode the algorithm identifier in DER form to the stream.
     *
     * @param stream the DerOutputStream to marshal the contents to.
     * @exception IOException on errors.
     */
    void encode(OutputStream stream) {
        DerOutputStream tmp = new DerOutputStream();
        algId.encode(tmp);

        stream.write(tmp.toByteArray());
    }

    /**
     * Set the attribute value.
     */
    void set(string name, AlgorithmId obj) {
        if (obj is null) {
            throw new IOException("Attribute must be of type AlgorithmId.");
        }
        if (name.equalsIgnoreCase(ALGORITHM)) {
            algId = cast(AlgorithmId)obj;
        } else {
            throw new IOException("Attribute name not recognized by " ~
                              "CertAttrSet:CertificateAlgorithmId.");
        }
    }

    /**
     * Get the attribute value.
     */
    AlgorithmId get(string name) {
        if (name.equalsIgnoreCase(ALGORITHM)) {
            return (algId);
        } else {
            throw new IOException("Attribute name not recognized by " ~
                               "CertAttrSet:CertificateAlgorithmId.");
        }
    }

    /**
     * Delete the attribute value.
     */
    void remove(string name) {
        if (name.equalsIgnoreCase(ALGORITHM)) {
            algId = null;
        } else {
            throw new IOException("Attribute name not recognized by " ~
                               "CertAttrSet:CertificateAlgorithmId.");
        }
    }

    /**
     * Return an enumeration of names of attributes existing within this
     * attribute.
     */
    Enumeration!string getElements() {
        // AttributeNameEnumeration elements = new AttributeNameEnumeration();
        // elements.addElement(ALGORITHM);
        // return (elements.elements());
        implementationMissing();
        return null;
    }

   /**
    * Return the name of this attribute.
    */
   string getName() {
      return (NAME);
   }
}
