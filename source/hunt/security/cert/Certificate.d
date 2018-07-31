module hunt.security.cert.Certificate;

import hunt.security.key;
import hunt.security.Provider;

import hunt.util.exception;

/**
 * <p>Abstract class for managing a variety of identity certificates.
 * An identity certificate is a binding of a principal to a key which
 * is vouched for by another principal.  (A principal represents
 * an entity such as an individual user, a group, or a corporation.)
 *<p>
 * This class is an abstraction for certificates that have different
 * formats but important common uses.  For example, different types of
 * certificates, such as X.509 and PGP, share general certificate
 * functionality (like encoding and verifying) and
 * some types of information (like a key).
 * <p>
 * X.509, PGP, and SDSI certificates can all be implemented by
 * subclassing the Certificate class, even though they contain different
 * sets of information, and they store and retrieve the information in
 * different ways.
 *
 * @see X509Certificate
 * @see CertificateFactory
 *
 * @author Hemma Prafullchandra
 */

abstract class Certificate {

    // private static final long serialVersionUID = -3585440601605666277L;

    // the certificate type
    private string type;

    /** Cache the hash code for the certiticate */
    private int hash = -1; // Default to -1

    /**
     * Creates a certificate of the specified type.
     *
     * @param type the standard name of the certificate type.
     * See the CertificateFactory section in the <a href=
     * "{@docRoot}/../technotes/guides/security/StandardNames.html#CertificateFactory">
     * Java Cryptography Architecture Standard Algorithm Name Documentation</a>
     * for information about standard certificate types.
     */
    protected this(string type) {
        this.type = type;
    }

    /**
     * Returns the type of this certificate.
     *
     * @return the type of this certificate.
     */
    final string getType() {
        return this.type;
    }

    /**
     * Compares this certificate for equality with the specified
     * object. If the {@code other} object is an
     * {@code instanceof} {@code Certificate}, then
     * its encoded form is retrieved and compared with the
     * encoded form of this certificate.
     *
     * @param other the object to test for equality with this certificate.
     * @return true iff the encoded forms of the two certificates
     * match, false otherwise.
     */
    override bool opEquals(Object other) {
        if (this is other) {
            return true;
        }
        if (typeid(other) != typeid(Certificate)) {
            return false;
        }

        implementationMissing();
        return false;
        // try {
        //     byte[] thisCert = X509CertImpl.getEncodedInternal(this);
        //     byte[] otherCert = X509CertImpl.getEncodedInternal(cast(Certificate)other);

        //     return thisCert == otherCert;
        // } catch (CertificateException e) {
        //     return false;
        // }
    }

    /**
     * Returns a hashcode value for this certificate from its
     * encoded form.
     *
     * @return the hashcode value.
     */
    // int hashCode() {
    //     int h = hash;
    //     if (h == -1) {
    //         try {
    //             h = Arrays.hashCode(X509CertImpl.getEncodedInternal(this));
    //         } catch (CertificateException e) {
    //             h = 0;
    //         }
    //         hash = h;
    //     }
    //     return h;
    // }

    /**
     * Returns the encoded form of this certificate. It is
     * assumed that each certificate type would have only a single
     * form of encoding; for example, X.509 certificates would
     * be encoded as ASN.1 DER.
     *
     * @return the encoded form of this certificate
     *
     * @exception CertificateEncodingException if an encoding error occurs.
     */
    abstract byte[] getEncoded();

    /**
     * Verifies that this certificate was signed using the
     * private key that corresponds to the specified key.
     *
     * @param key the PublicKey used to carry out the verification.
     *
     * @exception NoSuchAlgorithmException on unsupported signature
     * algorithms.
     * @exception InvalidKeyException on incorrect key.
     * @exception NoSuchProviderException if there's no default provider.
     * @exception SignatureException on signature errors.
     * @exception CertificateException on encoding errors.
     */
    abstract void verify(PublicKey key);

    /**
     * Verifies that this certificate was signed using the
     * private key that corresponds to the specified key.
     * This method uses the signature verification engine
     * supplied by the specified provider.
     *
     * @param key the PublicKey used to carry out the verification.
     * @param sigProvider the name of the signature provider.
     *
     * @exception NoSuchAlgorithmException on unsupported signature
     * algorithms.
     * @exception InvalidKeyException on incorrect key.
     * @exception NoSuchProviderException on incorrect provider.
     * @exception SignatureException on signature errors.
     * @exception CertificateException on encoding errors.
     */
    abstract void verify(PublicKey key, string sigProvider);

    /**
     * Verifies that this certificate was signed using the
     * private key that corresponds to the specified key.
     * This method uses the signature verification engine
     * supplied by the specified provider. Note that the specified
     * Provider object does not have to be registered in the provider list.
     *
     * <p> This method was added to version 1.8 of the Java Platform
     * Standard Edition. In order to maintain backwards compatibility with
     * existing service providers, this method cannot be {@code abstract}
     * and by default throws an {@code UnsupportedOperationException}.
     *
     * @param key the PublicKey used to carry out the verification.
     * @param sigProvider the signature provider.
     *
     * @exception NoSuchAlgorithmException on unsupported signature
     * algorithms.
     * @exception InvalidKeyException on incorrect key.
     * @exception SignatureException on signature errors.
     * @exception CertificateException on encoding errors.
     * @exception UnsupportedOperationException if the method is not supported
     * @since 1.8
     */
    void verify(PublicKey key, Provider sigProvider) {
        throw new UnsupportedOperationException("");
    }

    /**
     * Returns a string representation of this certificate.
     *
     * @return a string representation of this certificate.
     */
    // abstract string toString();

    /**
     * Gets the key from this certificate.
     *
     * @return the key.
     */
    abstract PublicKey getPublicKey();

    /**
     * Alternate Certificate class for serialization.
     * @since 1.3
     */
    protected static class CertificateRep  {

        // private static final long serialVersionUID = -8563758940495660020L;

        private string type;
        private byte[] data;

        /**
         * Construct the alternate Certificate class with the Certificate
         * type and Certificate encoding bytes.
         *
         * <p>
         *
         * @param type the standard name of the Certificate type. <p>
         *
         * @param data the Certificate data.
         */
        protected this(string type, byte[] data) {
            this.type = type;
            this.data = data;
        }

        /**
         * Resolve the Certificate Object.
         *
         * <p>
         *
         * @return the resolved Certificate Object
         *
         * @throws java.io.ObjectStreamException if the Certificate
         *      could not be resolved
         */
        // protected Object readResolve() {
        //     try {
        //         CertificateFactory cf = CertificateFactory.getInstance(type);
        //         return cf.generateCertificate
        //                 (new java.io.ByteArrayInputStream(data));
        //     } catch (CertificateException e) {
        //         throw new java.io.NotSerializableException
        //                         ("java.security.cert.Certificate: " ~
        //                         type +
        //                         ": " ~
        //                         e.getMessage());
        //     }
        // }
    }

    /**
     * Replace the Certificate to be serialized.
     *
     * @return the alternate Certificate object to be serialized
     *
     * @throws java.io.ObjectStreamException if a new object representing
     * this Certificate could not be created
     * @since 1.3
     */
    // protected Object writeReplace() {
    //     try {
    //         return new CertificateRep(type, getEncoded());
    //     } catch (CertificateException e) {
    //         throw new java.io.NotSerializableException
    //                             ("java.security.cert.Certificate: " ~
    //                             type ~
    //                             ": " ~
    //                             e.getMessage());
    //     }
    // }
}
