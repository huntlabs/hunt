module hunt.security.cert.CertificateFactorySpi;

import hunt.security.cert.Certificate;
import hunt.security.cert.CertPath;
import hunt.security.cert.CRL;

import hunt.container;
import hunt.io.common;

import hunt.util.exception;

/**
 * This class defines the <i>Service Provider Interface</i> (<b>SPI</b>)
 * for the {@code CertificateFactory} class.
 * All the abstract methods in this class must be implemented by each
 * cryptographic service provider who wishes to supply the implementation
 * of a certificate factory for a particular certificate type, e.g., X.509.
 *
 * <p>Certificate factories are used to generate certificate, certification path
 * ({@code CertPath}) and certificate revocation list (CRL) objects from
 * their encodings.
 *
 * <p>A certificate factory for X.509 must return certificates that are an
 * instance of {@code java.security.cert.X509Certificate}, and CRLs
 * that are an instance of {@code java.security.cert.X509CRL}.
 *
 * @author Hemma Prafullchandra
 * @author Jan Luehe
 * @author Sean Mullan
 *
 *
 * @see CertificateFactory
 * @see Certificate
 * @see X509Certificate
 * @see CertPath
 * @see CRL
 * @see X509CRL
 *
 * @since 1.2
 */

abstract class CertificateFactorySpi {

    /**
     * Generates a certificate object and initializes it with
     * the data read from the input stream {@code inStream}.
     *
     * <p>In order to take advantage of the specialized certificate format
     * supported by this certificate factory,
     * the returned certificate object can be typecast to the corresponding
     * certificate class. For example, if this certificate
     * factory implements X.509 certificates, the returned certificate object
     * can be typecast to the {@code X509Certificate} class.
     *
     * <p>In the case of a certificate factory for X.509 certificates, the
     * certificate provided in {@code inStream} must be DER-encoded and
     * may be supplied in binary or printable (Base64) encoding. If the
     * certificate is provided in Base64 encoding, it must be bounded at
     * the beginning by -----BEGIN CERTIFICATE-----, and must be bounded at
     * the end by -----END CERTIFICATE-----.
     *
     * <p>Note that if the given input stream does not support
     * {@link java.io.InputStream#mark(int) mark} and
     * {@link java.io.InputStream#reset() reset}, this method will
     * consume the entire input stream. Otherwise, each call to this
     * method consumes one certificate and the read position of the input stream
     * is positioned to the next available byte after the inherent
     * end-of-certificate marker. If the data in the
     * input stream does not contain an inherent end-of-certificate marker (other
     * than EOF) and there is trailing data after the certificate is parsed, a
     * {@code CertificateException} is thrown.
     *
     * @param inStream an input stream with the certificate data.
     *
     * @return a certificate object initialized with the data
     * from the input stream.
     *
     * @exception CertificateException on parsing errors.
     */
    abstract Certificate engineGenerateCertificate(InputStream inStream);

    /**
     * Generates a {@code CertPath} object and initializes it with
     * the data read from the {@code InputStream} inStream. The data
     * is assumed to be in the default encoding.
     *
     * <p> This method was added to version 1.4 of the Java 2 Platform
     * Standard Edition. In order to maintain backwards compatibility with
     * existing service providers, this method cannot be {@code abstract}
     * and by default throws an {@code UnsupportedOperationException}.
     *
     * @param inStream an {@code InputStream} containing the data
     * @return a {@code CertPath} initialized with the data from the
     *   {@code InputStream}
     * @exception CertificateException if an exception occurs while decoding
     * @exception UnsupportedOperationException if the method is not supported
     * @since 1.4
     */
    CertPath engineGenerateCertPath(InputStream inStream)
    {
        throw new UnsupportedOperationException("");
    }

    /**
     * Generates a {@code CertPath} object and initializes it with
     * the data read from the {@code InputStream} inStream. The data
     * is assumed to be in the specified encoding.
     *
     * <p> This method was added to version 1.4 of the Java 2 Platform
     * Standard Edition. In order to maintain backwards compatibility with
     * existing service providers, this method cannot be {@code abstract}
     * and by default throws an {@code UnsupportedOperationException}.
     *
     * @param inStream an {@code InputStream} containing the data
     * @param encoding the encoding used for the data
     * @return a {@code CertPath} initialized with the data from the
     *   {@code InputStream}
     * @exception CertificateException if an exception occurs while decoding or
     *   the encoding requested is not supported
     * @exception UnsupportedOperationException if the method is not supported
     * @since 1.4
     */
    CertPath engineGenerateCertPath(InputStream inStream, string encoding)
    {
        throw new UnsupportedOperationException("");
    }

    /**
     * Generates a {@code CertPath} object and initializes it with
     * a {@code List} of {@code Certificate}s.
     * <p>
     * The certificates supplied must be of a type supported by the
     * {@code CertificateFactory}. They will be copied out of the supplied
     * {@code List} object.
     *
     * <p> This method was added to version 1.4 of the Java 2 Platform
     * Standard Edition. In order to maintain backwards compatibility with
     * existing service providers, this method cannot be {@code abstract}
     * and by default throws an {@code UnsupportedOperationException}.
     *
     * @param certificates a {@code List} of {@code Certificate}s
     * @return a {@code CertPath} initialized with the supplied list of
     *   certificates
     * @exception CertificateException if an exception occurs
     * @exception UnsupportedOperationException if the method is not supported
     * @since 1.4
     */
    CertPath engineGenerateCertPath(List!(Certificate) certificates)
    {
        throw new UnsupportedOperationException("");
    }

    /**
     * Returns an iteration of the {@code CertPath} encodings supported
     * by this certificate factory, with the default encoding first. See
     * the CertPath Encodings section in the <a href=
     * "{@docRoot}/../technotes/guides/security/StandardNames.html#CertPathEncodings">
     * Java Cryptography Architecture Standard Algorithm Name Documentation</a>
     * for information about standard encoding names.
     * <p>
     * Attempts to modify the returned {@code Iterator} via its
     * {@code remove} method result in an
     * {@code UnsupportedOperationException}.
     *
     * <p> This method was added to version 1.4 of the Java 2 Platform
     * Standard Edition. In order to maintain backwards compatibility with
     * existing service providers, this method cannot be {@code abstract}
     * and by default throws an {@code UnsupportedOperationException}.
     *
     * @return an {@code Iterator} over the names of the supported
     *         {@code CertPath} encodings (as {@code string}s)
     * @exception UnsupportedOperationException if the method is not supported
     * @since 1.4
     */
    Iterator!string engineGetCertPathEncodings() {
        throw new UnsupportedOperationException("");
    }

    /**
     * Returns a (possibly empty) collection view of the certificates read
     * from the given input stream {@code inStream}.
     *
     * <p>In order to take advantage of the specialized certificate format
     * supported by this certificate factory, each element in
     * the returned collection view can be typecast to the corresponding
     * certificate class. For example, if this certificate
     * factory implements X.509 certificates, the elements in the returned
     * collection can be typecast to the {@code X509Certificate} class.
     *
     * <p>In the case of a certificate factory for X.509 certificates,
     * {@code inStream} may contain a single DER-encoded certificate
     * in the formats described for
     * {@link CertificateFactory#generateCertificate(java.io.InputStream)
     * generateCertificate}.
     * In addition, {@code inStream} may contain a PKCS#7 certificate
     * chain. This is a PKCS#7 <i>SignedData</i> object, with the only
     * significant field being <i>certificates</i>. In particular, the
     * signature and the contents are ignored. This format allows multiple
     * certificates to be downloaded at once. If no certificates are present,
     * an empty collection is returned.
     *
     * <p>Note that if the given input stream does not support
     * {@link java.io.InputStream#mark(int) mark} and
     * {@link java.io.InputStream#reset() reset}, this method will
     * consume the entire input stream.
     *
     * @param inStream the input stream with the certificates.
     *
     * @return a (possibly empty) collection view of
     * java.security.cert.Certificate objects
     * initialized with the data from the input stream.
     *
     * @exception CertificateException on parsing errors.
     */
    abstract Collection!Certificate
            engineGenerateCertificates(InputStream inStream);

    /**
     * Generates a certificate revocation list (CRL) object and initializes it
     * with the data read from the input stream {@code inStream}.
     *
     * <p>In order to take advantage of the specialized CRL format
     * supported by this certificate factory,
     * the returned CRL object can be typecast to the corresponding
     * CRL class. For example, if this certificate
     * factory implements X.509 CRLs, the returned CRL object
     * can be typecast to the {@code X509CRL} class.
     *
     * <p>Note that if the given input stream does not support
     * {@link java.io.InputStream#mark(int) mark} and
     * {@link java.io.InputStream#reset() reset}, this method will
     * consume the entire input stream. Otherwise, each call to this
     * method consumes one CRL and the read position of the input stream
     * is positioned to the next available byte after the inherent
     * end-of-CRL marker. If the data in the
     * input stream does not contain an inherent end-of-CRL marker (other
     * than EOF) and there is trailing data after the CRL is parsed, a
     * {@code CRLException} is thrown.
     *
     * @param inStream an input stream with the CRL data.
     *
     * @return a CRL object initialized with the data
     * from the input stream.
     *
     * @exception CRLException on parsing errors.
     */
    abstract CRL engineGenerateCRL(InputStream inStream);

    /**
     * Returns a (possibly empty) collection view of the CRLs read
     * from the given input stream {@code inStream}.
     *
     * <p>In order to take advantage of the specialized CRL format
     * supported by this certificate factory, each element in
     * the returned collection view can be typecast to the corresponding
     * CRL class. For example, if this certificate
     * factory implements X.509 CRLs, the elements in the returned
     * collection can be typecast to the {@code X509CRL} class.
     *
     * <p>In the case of a certificate factory for X.509 CRLs,
     * {@code inStream} may contain a single DER-encoded CRL.
     * In addition, {@code inStream} may contain a PKCS#7 CRL
     * set. This is a PKCS#7 <i>SignedData</i> object, with the only
     * significant field being <i>crls</i>. In particular, the
     * signature and the contents are ignored. This format allows multiple
     * CRLs to be downloaded at once. If no CRLs are present,
     * an empty collection is returned.
     *
     * <p>Note that if the given input stream does not support
     * {@link java.io.InputStream#mark(int) mark} and
     * {@link java.io.InputStream#reset() reset}, this method will
     * consume the entire input stream.
     *
     * @param inStream the input stream with the CRLs.
     *
     * @return a (possibly empty) collection view of
     * java.security.cert.CRL objects initialized with the data from the input
     * stream.
     *
     * @exception CRLException on parsing errors.
     */
    abstract Collection!CRL engineGenerateCRLs(InputStream inStream);
}
