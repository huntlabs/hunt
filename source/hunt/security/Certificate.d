module hunt.security.Certificate;

import hunt.io;

/**
 * <p>This is an interface of abstract methods for managing a
 * variety of identity certificates.
 * An identity certificate is a guarantee by a principal that
 * a key is that of another principal.  (A principal represents
 * an entity such as an individual user, a group, or a corporation.)
 *
 * <p>In particular, this interface is intended to be a common
 * abstraction for constructs that have different formats but
 * important common uses.  For example, different types of
 * certificates, such as X.509 certificates and PGP certificates,
 * share general certificate functionality (the need to encode and
 * decode certificates) and some types of information, such as a
 * key, the principal whose key it is, and the guarantor
 * guaranteeing that the key is that of the specified
 * principal. So an implementation of X.509 certificates and an
 * implementation of PGP certificates can both utilize the Certificate
 * interface, even though their formats and additional types and
 * amounts of information stored are different.
 *
 * <p><b>Important</b>: This interface is useful for cataloging and
 * grouping objects sharing certain common uses. It does not have any
 * semantics of its own. In particular, a Certificate object does not
 * make any statement as to the <i>validity</i> of the binding. It is
 * the duty of the application implementing this interface to verify
 * the certificate and satisfy itself of its validity.
 *
 * @author Benjamin Renaud
 * @deprecated A new certificate handling package is created in the Java platform.
 *             This Certificate interface is entirely deprecated and
 *             is here to allow for a smooth transition to the new
 *             package.
 * @see java.security.cert.Certificate
 */
interface Certificate {

    // /**
    //  * Returns the guarantor of the certificate, that is, the principal
    //  * guaranteeing that the key associated with this certificate
    //  * is that of the principal associated with this certificate. For X.509
    //  * certificates, the guarantor will typically be a Certificate Authority
    //  * (such as the United States Postal Service or Verisign, Inc.).
    //  *
    //  * @return the guarantor which guaranteed the principal-key
    //  * binding.
    //  */
    // abstract Principal getGuarantor();

    // /**
    //  * Returns the principal of the principal-key pair being guaranteed by
    //  * the guarantor.
    //  *
    //  * @return the principal to which this certificate is bound.
    //  */
    // abstract Principal getPrincipal();

    // /**
    //  * Returns the key of the principal-key pair being guaranteed by
    //  * the guarantor.
    //  *
    //  * @return the key that this certificate certifies belongs
    //  * to a particular principal.
    //  */
    // abstract PublicKey getPublicKey();

    /**
     * Encodes the certificate to an output stream in a format that can
     * be decoded by the {@code decode} method.
     *
     * @param stream the output stream to which to encode the
     * certificate.
     *
     * @exception KeyException if the certificate is not
     * properly initialized, or data is missing, etc.
     *
     * @exception IOException if a stream exception occurs while
     * trying to output the encoded certificate to the output stream.
     *
     * @see #decode
     * @see #getFormat
     */
    abstract void encode(OutputStream stream);

    /**
     * Decodes a certificate from an input stream. The format should be
     * that returned by {@code getFormat} and produced by
     * {@code encode}.
     *
     * @param stream the input stream from which to fetch the data
     * being decoded.
     *
     * @exception KeyException if the certificate is not properly initialized,
     * or data is missing, etc.
     *
     * @exception IOException if an exception occurs while trying to input
     * the encoded certificate from the input stream.
     *
     * @see #encode
     * @see #getFormat
     */
    abstract void decode(InputStream stream);


    /**
     * Returns the name of the coding format. This is used as a hint to find
     * an appropriate parser. It could be "X.509", "PGP", etc. This is
     * the format produced and understood by the {@code encode}
     * and {@code decode} methods.
     *
     * @return the name of the coding format.
     */
    abstract string getFormat();

    /**
     * Returns a string that represents the contents of the certificate.
     *
     * @param detailed whether or not to give detailed information
     * about the certificate
     *
     * @return a string representing the contents of the certificate
     */
    string toString(bool detailed);
}
