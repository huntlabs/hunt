module hunt.security.x509.CertificateVersion;

import hunt.security.x509.CertAttrSet;

import hunt.security.util.DerInputStream;
import hunt.security.util.DerOutputStream;
import hunt.security.util.DerValue;

import hunt.container;
import hunt.io.common;

import hunt.util.exception;
import hunt.util.string;

import std.conv;

/**
 * This class defines the version of the X509 Certificate.
 *
 * @author Amit Kapoor
 * @author Hemma Prafullchandra
 * @see CertAttrSet
 */
class CertificateVersion : CertAttrSet!(string, int)  {
    /**
     * X509Certificate Version 1
     */
    enum int     V1 = 0;
    /**
     * X509Certificate Version 2
     */
    enum int     V2 = 1;
    /**
     * X509Certificate Version 3
     */
    enum int     V3 = 2;
    /**
     * Identifier for this attribute, to be used with the
     * get, set, delete methods of Certificate, x509 type.
     */
    enum string IDENT = "x509.info.version";
    /**
     * Sub attributes name for this CertAttrSet.
     */
    enum string NAME = "version";
    enum string VERSION = "number";

    // Private data members
    int _version = V1;

    // Returns the version number.
    private int getVersion() {
        return(_version);
    }

    // Construct the class from the passed DerValue
    private void construct(DerValue derVal) {
        // if (derVal.isConstructed() && derVal.isContextSpecific()) {
        //     derVal = derVal.data.getDerValue();
        //     _version = derVal.getInteger();
        //     if (derVal.data.available() != 0) {
        //         throw new IOException("X.509 version, bad format");
        //     }
        // }
        implementationMissing();
    }

    /**
     * The default constructor for this class,
     *  sets the version to 0 (i.e. X.509 version 1).
     */
    this() {
        _version = V1;
    }

    /**
     * The constructor for this class for the required version.
     *
     * @param version the version for the certificate.
     * @exception IOException if the version is not valid.
     */
    this(int ver) {

        // check that it is a valid version
        if (_version == V1 || _version == V2 || _version == V3)
            this._version = ver;
        else {
            throw new IOException("X.509 Certificate version " ~
                                   ver.to!string() ~ " not supported.\n");
        }
    }

    /**
     * Create the object, decoding the values from the passed DER stream.
     *
     * @param stream the DerInputStream to read the CertificateVersion from.
     * @exception IOException on decoding errors.
     */
    this(DerInputStream stream) {
        _version = V1;
        DerValue derVal = stream.getDerValue();

        construct(derVal);
    }

    /**
     * Create the object, decoding the values from the passed stream.
     *
     * @param stream the InputStream to read the CertificateVersion from.
     * @exception IOException on decoding errors.
     */
    this(InputStream stream) {
        _version = V1;
        DerValue derVal = new DerValue(stream);

        construct(derVal);
    }

    /**
     * Create the object, decoding the values from the passed DerValue.
     *
     * @param val the Der encoded value.
     * @exception IOException on decoding errors.
     */
    this(DerValue val) {
        _version = V1;

        construct(val);
    }

    /**
     * Return the version number of the certificate.
     */
    override string toString() {
        return "Version: V" ~ (_version+1).to!string();
    }

    /**
     * Encode the CertificateVersion period in DER form to the stream.
     *
     * @param stream the OutputStream to marshal the contents to.
     * @exception IOException on errors.
     */
    void encode(OutputStream stream) {
        // Nothing for default
        if (_version == V1) {
            return;
        }
        DerOutputStream tmp = new DerOutputStream();
        tmp.putInteger(_version);

        DerOutputStream seq = new DerOutputStream();
        seq.write(DerValue.createTag(DerValue.TAG_CONTEXT, true, cast(byte)0),
                  tmp);

        stream.write(seq.toByteArray());
    }

    /**
     * Set the attribute value.
     */
    void set(string name, int obj) {
        implementationMissing();
        // if (!(obj instanceof int)) {
        //     throw new IOException("Attribute must be of type int.");
        // }
        // if (name.equalsIgnoreCase(VERSION)) {
        //     _version = ((int)obj).intValue();
        // } else {
        //     throw new IOException("Attribute name not recognized by " ~
        //                           "CertAttrSet: CertificateVersion.");
        // }
    }

    /**
     * Get the attribute value.
     */
    int get(string name) {
        if (name.equalsIgnoreCase(VERSION)) {
            return(getVersion());
        } else {
            throw new IOException("Attribute name not recognized by " ~
                                  "CertAttrSet: CertificateVersion.");
        }
    }

    /**
     * Delete the attribute value.
     */
    void remove(string name) {
        if (name.equalsIgnoreCase(VERSION)) {
            _version = V1;
        } else {
            throw new IOException("Attribute name not recognized by " ~
                                  "CertAttrSet: CertificateVersion.");
        }
    }

    /**
     * Return an enumeration of names of attributes existing within this
     * attribute.
     */
    Enumeration!string getElements() {
        // AttributeNameEnumeration elements = new AttributeNameEnumeration();
        // elements.addElement(VERSION);

        // return (elements.elements());
                implementationMissing();
        return null;

    }

    /**
     * Return the name of this attribute.
     */
    string getName() {
        return(NAME);
    }

    /**
     * Compare versions.
     */
    int compare(int vers) {
        return(_version - vers);
    }
}
