module hunt.security.x509.CertAttrSet;

import hunt.container.Enumeration;

import hunt.io.common;

/**
 * This interface defines the methods required of a certificate attribute.
 * Examples of X.509 certificate attributes are Validity, Issuer_Name, and
 * Subject Name. A CertAttrSet may comprise one attribute or many
 * attributes.
 * <p>
 * A CertAttrSet itself can also be comprised of other sub-sets.
 * In the case of X.509 V3 certificates, for example, the "extensions"
 * attribute has subattributes, such as those for KeyUsage and
 * AuthorityKeyIdentifier.
 *
 * @author Amit Kapoor
 * @author Hemma Prafullchandra
 * @see CertificateException
 */
interface CertAttrSet(T, V) {
    /**
     * Returns a short string describing this certificate attribute.
     *
     * @return value of this certificate attribute in
     *         printable form.
     */
    string toString();

    /**
     * Encodes the attribute to the output stream in a format
     * that can be parsed by the <code>decode</code> method.
     *
     * @param outputStream the OutputStream to encode the attribute to.
     *
     * @exception CertificateException on encoding or validity errors.
     * @exception IOException on other errors.
     */
    void encode(OutputStream outputStream);

    /**
     * Sets an attribute value within this CertAttrSet.
     *
     * @param name the name of the attribute (e.g. "x509.info.key")
     * @param obj the attribute object.
     *
     * @exception CertificateException on attribute handling errors.
     * @exception IOException on other errors.
     */
    void set(string name, V obj);

    /**
     * Gets an attribute value for this CertAttrSet.
     *
     * @param name the name of the attribute to return.
     *
     * @exception CertificateException on attribute handling errors.
     * @exception IOException on other errors.
     */
    V get(string name);

    /**
     * Deletes an attribute value from this CertAttrSet.
     *
     * @param name the name of the attribute to delete.
     *
     * @exception CertificateException on attribute handling errors.
     * @exception IOException on other errors.
     */
    void remove(string name);

    /**
     * Returns an enumeration of the names of the attributes existing within
     * this attribute.
     *
     * @return an enumeration of the attribute names.
     */
    Enumeration!T getElements();

    /**
     * Returns the name (identifier) of this CertAttrSet.
     *
     * @return the name of this CertAttrSet.
     */
    string getName();
}
