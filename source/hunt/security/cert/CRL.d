module hunt.security.cert.CRL;

import hunt.security.cert.Certificate;

/**
 * This class is an abstraction of certificate revocation lists (CRLs) that
 * have different formats but important common uses. For example, all CRLs
 * share the functionality of listing revoked certificates, and can be queried
 * on whether or not they list a given certificate.
 * <p>
 * Specialized CRL types can be defined by subclassing off of this abstract
 * class.
 *
 * @author Hemma Prafullchandra
 *
 *
 * @see X509CRL
 * @see CertificateFactory
 *
 * @since 1.2
 */

abstract class CRL {

    // the CRL type
    private string type;

    /**
     * Creates a CRL of the specified type.
     *
     * @param type the standard name of the CRL type.
     * See Appendix A in the <a href=
     * "../../../../technotes/guides/security/crypto/CryptoSpec.html#AppA">
     * Java Cryptography Architecture API Specification &amp; Reference </a>
     * for information about standard CRL types.
     */
    protected this(string type) {
        this.type = type;
    }

    /**
     * Returns the type of this CRL.
     *
     * @return the type of this CRL.
     */
    final string getType() {
        return this.type;
    }

    /**
     * Returns a string representation of this CRL.
     *
     * @return a string representation of this CRL.
     */
    // abstract string toString();

    /**
     * Checks whether the given certificate is on this CRL.
     *
     * @param cert the certificate to check for.
     * @return true if the given certificate is on this CRL,
     * false otherwise.
     */
    abstract bool isRevoked(Certificate cert);
}