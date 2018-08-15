module hunt.security.x509.CertificateSerialNumber;

import hunt.security.x509.CertAttrSet;
import hunt.security.x509.SerialNumber;

import hunt.container.Enumeration;

import hunt.security.util.DerValue;
import hunt.security.util.DerInputStream;
import hunt.security.util.DerOutputStream;

import hunt.io.common;
import hunt.util.exception;
import hunt.util.string;

/**
 * This class defines the SerialNumber attribute for the Certificate.
 *
 * @author Amit Kapoor
 * @author Hemma Prafullchandra
 * @see CertAttrSet
 */
class CertificateSerialNumber : CertAttrSet!(string, SerialNumber) {
    /**
     * Identifier for this attribute, to be used with the
     * get, set, delete methods of Certificate, x509 type.
     */
    enum string IDENT = "x509.info.serialNumber";

    /**
     * Sub attributes name for this CertAttrSet.
     */
    enum string NAME = "serialNumber";
    enum string NUMBER = "number";

    private SerialNumber        serial;

    /**
     * Default constructor for the certificate attribute.
     *
     * @param serial the serial number for the certificate.
     */
    this(BigInteger num) {
      this.serial = new SerialNumber(num);
    }

    /**
     * Default constructor for the certificate attribute.
     *
     * @param serial the serial number for the certificate.
     */
    this(int num) {
      this.serial = new SerialNumber(num);
    }

    /**
     * Create the object, decoding the values from the passed DER stream.
     *
     * @param in the DerInputStream to read the serial number from.
     * @exception IOException on decoding errors.
     */
    this(DerInputStream stream) {
        serial = new SerialNumber(stream);
    }

    /**
     * Create the object, decoding the values from the passed stream.
     *
     * @param in the InputStream to read the serial number from.
     * @exception IOException on decoding errors.
     */
    this(InputStream stream) {
        serial = new SerialNumber(stream);
    }

    /**
     * Create the object, decoding the values from the passed DerValue.
     *
     * @param val the DER encoded value.
     * @exception IOException on decoding errors.
     */
    this(DerValue val) {
        serial = new SerialNumber(val);
    }

    /**
     * Return the serial number as user readable string.
     */
    override string toString() {
        if (serial is null) return "";
        return (serial.toString());
    }

    /**
     * Encode the serial number in DER form to the stream.
     *
     * @param stream the DerOutputStream to marshal the contents to.
     * @exception IOException on errors.
     */
    void encode(OutputStream stream) {
        DerOutputStream tmp = new DerOutputStream();
        serial.encode(tmp);

        stream.write(tmp.toByteArray());
    }

    /**
     * Set the attribute value.
     */
    void set(string name, SerialNumber obj) {
        if (obj is null) {
            throw new IOException("Attribute must be of type SerialNumber.");
        }
        if (name.equalsIgnoreCase(NUMBER)) {
            serial = obj;
        } else {
            throw new IOException("Attribute name not recognized by " ~
                                "CertAttrSet:CertificateSerialNumber.");
        }
    }

    /**
     * Get the attribute value.
     */
    SerialNumber get(string name) {
        if (name.equalsIgnoreCase(NUMBER)) {
            return (serial);
        } else {
            throw new IOException("Attribute name not recognized by " ~
                                "CertAttrSet:CertificateSerialNumber.");
        }
    }

    /**
     * Delete the attribute value.
     */
    void remove(string name) {
        if (name.equalsIgnoreCase(NUMBER)) {
            serial = null;
        } else {
            throw new IOException("Attribute name not recognized by " ~
                                "CertAttrSet:CertificateSerialNumber.");
        }
    }

    /**
     * Return an enumeration of names of attributes existing within this
     * attribute.
     */
    Enumeration!string getElements() {
        // AttributeNameEnumeration elements = new AttributeNameEnumeration();
        // elements.addElement(NUMBER);

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
