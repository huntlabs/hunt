module hunt.security.x509.CertificateValidity;


import hunt.security.x509.CertAttrSet;

import hunt.security.util.DerValue;
import hunt.security.util.DerInputStream;

import hunt.container.Enumeration;

import hunt.io.common;
import hunt.util.exception;
import hunt.util.string;

import std.datetime;

/**
 * This class defines the interval for which the certificate is valid.
 *
 * @author Amit Kapoor
 * @author Hemma Prafullchandra
 * @see CertAttrSet
 */
class CertificateValidity : CertAttrSet!string {
    /**
     * Identifier for this attribute, to be used with the
     * get, set, delete methods of Certificate, x509 type.
     */
    enum string IDENT = "x509.info.validity";
    /**
     * Sub attributes name for this CertAttrSet.
     */
    enum string NAME = "validity";
    enum string NOT_BEFORE = "notBefore";
    enum string NOT_AFTER = "notAfter";
    private enum long YR_2050 = 2524636800000L;

    // Private data members
    private Date        notBefore;
    private Date        notAfter;

    // Returns the first time the certificate is valid.
    private Date getNotBefore() {
        // return (new Date(notBefore.getTime()));
        return notBefore;
    }

    // Returns the last time the certificate is valid.
    private Date getNotAfter() {
    //    return (new Date(notAfter.getTime()));
        return notAfter;
    }

    // Construct the class from the DerValue
    private void construct(DerValue derVal) {
        if (derVal.tag != DerValue.tag_Sequence) {
            throw new IOException("Invalid encoded CertificateValidity, " ~
                                  "starting sequence tag missing.");
        }
        // check if UTCTime encoded or GeneralizedTime
        if (derVal.data.available() == 0)
            throw new IOException("No data encoded for CertificateValidity");

        DerInputStream derIn = new DerInputStream(derVal.toByteArray());
        DerValue[] seq = derIn.getSequence(2);
        if (seq.length != 2)
            throw new IOException("Invalid encoding for CertificateValidity");

        if (seq[0].tag == DerValue.tag_UtcTime) {
            notBefore = derVal.data.getUTCTime();
        } else if (seq[0].tag == DerValue.tag_GeneralizedTime) {
            notBefore = derVal.data.getGeneralizedTime();
        } else {
            throw new IOException("Invalid encoding for CertificateValidity");
        }

        if (seq[1].tag == DerValue.tag_UtcTime) {
            notAfter = derVal.data.getUTCTime();
        } else if (seq[1].tag == DerValue.tag_GeneralizedTime) {
            notAfter = derVal.data.getGeneralizedTime();
        } else {
            throw new IOException("Invalid encoding for CertificateValidity");
        }
    }

    /**
     * Default constructor for the class.
     */
    this() { }

    /**
     * The default constructor for this class for the specified interval.
     *
     * @param notBefore the date and time before which the certificate
     *                   is not valid.
     * @param notAfter the date and time after which the certificate is
     *                  not valid.
     */
    this(Date notBefore, Date notAfter) {
        this.notBefore = notBefore;
        this.notAfter = notAfter;
    }

    /**
     * Create the object, decoding the values from the passed DER stream.
     *
     * @param stream the DerInputStream to read the CertificateValidity from.
     * @exception IOException on decoding errors.
     */
    this(DerInputStream stream) {
        DerValue derVal = stream.getDerValue();
        construct(derVal);
    }

    /**
     * Return the validity period as user readable string.
     */
    override string toString() {
        if (notBefore is null || notAfter is null)
            return "";
        return ("Validity: [From: " ~ notBefore.toString() ~
             ",\n               To: " ~ notAfter.toString() ~ "]");
    }

    /**
     * Encode the CertificateValidity period in DER form to the stream.
     *
     * @param stream the OutputStream to marshal the contents to.
     * @exception IOException on errors.
     */
    void encode(OutputStream stream) {

        // in cases where default constructor is used check for
        // null values
        if (notBefore is null || notAfter is null) {
            throw new IOException("CertAttrSet:CertificateValidity:" ~
                                  " null values to encode.\n");
        }
        DerOutputStream pair = new DerOutputStream();

        if (notBefore.getTime() < YR_2050) {
            pair.putUTCTime(notBefore);
        } else
            pair.putGeneralizedTime(notBefore);

        if (notAfter.getTime() < YR_2050) {
            pair.putUTCTime(notAfter);
        } else {
            pair.putGeneralizedTime(notAfter);
        }
        DerOutputStream seq = new DerOutputStream();
        seq.write(DerValue.tag_Sequence, pair);

        stream.write(seq.toByteArray());
    }

    /**
     * Set the attribute value.
     */
    void set(string name, Object obj) {
        implementationMissing();
        // if (!(obj instanceof Date)) {
        //     throw new IOException("Attribute must be of type Date.");
        // }
        // if (name.equalsIgnoreCase(NOT_BEFORE)) {
        //     notBefore = (Date)obj;
        // } else if (name.equalsIgnoreCase(NOT_AFTER)) {
        //     notAfter = (Date)obj;
        // } else {
        //     throw new IOException("Attribute name not recognized by " ~
        //                     "CertAttrSet: CertificateValidity.");
        // }
    }

    /**
     * Get the attribute value.
     */
    Date get(string name) {
        if (name.equalsIgnoreCase(NOT_BEFORE)) {
            return (getNotBefore());
        } else if (name.equalsIgnoreCase(NOT_AFTER)) {
            return (getNotAfter());
        } else {
            throw new IOException("Attribute name not recognized by " ~
                            "CertAttrSet: CertificateValidity.");
        }
    }

    /**
     * Delete the attribute value.
     */
    void remove(string name) {
        if (name.equalsIgnoreCase(NOT_BEFORE)) {
            notBefore = null;
        } else if (name.equalsIgnoreCase(NOT_AFTER)) {
            notAfter = null;
        } else {
            throw new IOException("Attribute name not recognized by " ~
                            "CertAttrSet: CertificateValidity.");
        }
    }

    /**
     * Return an enumeration of names of attributes existing within this
     * attribute.
     */
    Enumeration!string getElements() {
        AttributeNameEnumeration elements = new AttributeNameEnumeration();
        elements.addElement(NOT_BEFORE);
        elements.addElement(NOT_AFTER);

        return (elements.elements());
    }

    /**
     * Return the name of this attribute.
     */
    string getName() {
        return (NAME);
    }

    /**
     * Verify that the current time is within the validity period.
     *
     * @exception CertificateExpiredException if the certificate has expired.
     * @exception CertificateNotYetValidException if the certificate is not
     * yet valid.
     */
    void valid() {
        Date now = cast(Date)(Clock.currTime);
        valid(now);
    }

    /**
     * Verify that the passed time is within the validity period.
     * @param now the Date against which to compare the validity
     * period.
     *
     * @exception CertificateExpiredException if the certificate has expired
     * with respect to the <code>Date</code> supplied.
     * @exception CertificateNotYetValidException if the certificate is not
     * yet valid with respect to the <code>Date</code> supplied.
     *
     */
    void valid(Date now) {
        /*
         * we use the internal Dates rather than the passed in Date
         * because someone could override the Date methods after()
         * and before() to do something entirely different.
         */
        if (notBefore > now) {
            throw new CertificateNotYetValidException("NotBefore: " ~
                                                      notBefore.toString());
        }
        if (notAfter < now) {
            throw new CertificateExpiredException("NotAfter: " ~
                                                  notAfter.toString());
        }
    }
}
