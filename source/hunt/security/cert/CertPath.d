module hunt.security.cert.CertPath;

import hunt.security.cert.Certificate;

import hunt.container;

import std.array;
import std.conv;


/**
 * An immutable sequence of certificates (a certification path).
 * <p>
 * This is an abstract class that defines the methods common to all
 * {@code CertPath}s. Subclasses can handle different kinds of
 * certificates (X.509, PGP, etc.).
 * <p>
 * All {@code CertPath} objects have a type, a list of
 * {@code Certificate}s, and one or more supported encodings. Because the
 * {@code CertPath} class is immutable, a {@code CertPath} cannot
 * change in any externally visible way after being constructed. This
 * stipulation applies to all fields and methods of this class and any
 * added or overridden by subclasses.
 * <p>
 * The type is a {@code string} that identifies the type of
 * {@code Certificate}s in the certification path. For each
 * certificate {@code cert} in a certification path {@code certPath},
 * {@code cert.getType().equals(certPath.getType())} must be
 * {@code true}.
 * <p>
 * The list of {@code Certificate}s is an ordered {@code List} of
 * zero or more {@code Certificate}s. This {@code List} and all
 * of the {@code Certificate}s contained in it must be immutable.
 * <p>
 * Each {@code CertPath} object must support one or more encodings
 * so that the object can be translated into a byte array for storage or
 * transmission to other parties. Preferably, these encodings should be
 * well-documented standards (such as PKCS#7). One of the encodings supported
 * by a {@code CertPath} is considered the default encoding. This
 * encoding is used if no encoding is explicitly requested (for the
 * {@link #getEncoded() getEncoded()} method, for instance).
 * <p>
 * All {@code CertPath} objects are also {@code Serializable}.
 * {@code CertPath} objects are resolved into an alternate
 * {@link CertPathRep CertPathRep} object during serialization. This allows
 * a {@code CertPath} object to be serialized into an equivalent
 * representation regardless of its underlying implementation.
 * <p>
 * {@code CertPath} objects can be created with a
 * {@code CertificateFactory} or they can be returned by other classes,
 * such as a {@code CertPathBuilder}.
 * <p>
 * By convention, X.509 {@code CertPath}s (consisting of
 * {@code X509Certificate}s), are ordered starting with the target
 * certificate and ending with a certificate issued by the trust anchor. That
 * is, the issuer of one certificate is the subject of the following one. The
 * certificate representing the {@link TrustAnchor TrustAnchor} should not be
 * included in the certification path. Unvalidated X.509 {@code CertPath}s
 * may not follow these conventions. PKIX {@code CertPathValidator}s will
 * detect any departure from these conventions that cause the certification
 * path to be invalid and throw a {@code CertPathValidatorException}.
 *
 * <p> Every implementation of the Java platform is required to support the
 * following standard {@code CertPath} encodings:
 * <ul>
 * <li>{@code PKCS7}</li>
 * <li>{@code PkiPath}</li>
 * </ul>
 * These encodings are described in the <a href=
 * "{@docRoot}/../technotes/guides/security/StandardNames.html#CertPathEncodings">
 * CertPath Encodings section</a> of the
 * Java Cryptography Architecture Standard Algorithm Name Documentation.
 * Consult the release documentation for your implementation to see if any
 * other encodings are supported.
 * <p>
 * <b>Concurrent Access</b>
 * <p>
 * All {@code CertPath} objects must be thread-safe. That is, multiple
 * threads may concurrently invoke the methods defined in this class on a
 * single {@code CertPath} object (or more than one) with no
 * ill effects. This is also true for the {@code List} returned by
 * {@code CertPath.getCertificates}.
 * <p>
 * Requiring {@code CertPath} objects to be immutable and thread-safe
 * allows them to be passed around to various pieces of code without worrying
 * about coordinating access.  Providing this thread-safety is
 * generally not difficult, since the {@code CertPath} and
 * {@code List} objects in question are immutable.
 *
 * @see CertificateFactory
 * @see CertPathBuilder
 *
 * @author      Yassir Elley
 * @since       1.4
 */
abstract class CertPath {

    // private static final long serialVersionUID = 6068470306649138683L;

    private string type;        // the type of certificates in this chain

    /**
     * Creates a {@code CertPath} of the specified type.
     * <p>
     * This constructor is protected because most users should use a
     * {@code CertificateFactory} to create {@code CertPath}s.
     *
     * @param type the standard name of the type of
     * {@code Certificate}s in this path
     */
    protected this(string type) {
        this.type = type;
    }

    /**
     * Returns the type of {@code Certificate}s in this certification
     * path. This is the same string that would be returned by
     * {@link java.security.cert.Certificate#getType() cert.getType()}
     * for all {@code Certificate}s in the certification path.
     *
     * @return the type of {@code Certificate}s in this certification
     * path (never null)
     */
    string getType() {
        return type;
    }

    /**
     * Returns an iteration of the encodings supported by this certification
     * path, with the default encoding first. Attempts to modify the returned
     * {@code Iterator} via its {@code remove} method result in an
     * {@code UnsupportedOperationException}.
     *
     * @return an {@code Iterator} over the names of the supported
     *         encodings (as Strings)
     */
    abstract Iterator!string getEncodings();

    /**
     * Compares this certification path for equality with the specified
     * object. Two {@code CertPath}s are equal if and only if their
     * types are equal and their certificate {@code List}s (and by
     * implication the {@code Certificate}s in those {@code List}s)
     * are equal. A {@code CertPath} is never equal to an object that is
     * not a {@code CertPath}.
     * <p>
     * This algorithm is implemented by this method. If it is overridden,
     * the behavior specified here must be maintained.
     *
     * @param other the object to test for equality with this certification path
     * @return true if the specified object is equal to this certification path,
     * false otherwise
     */
    override bool opEquals(Object other) {
        if (this is other)
            return true;

        if (other is null)
            return false;

        CertPath otherCP = cast(CertPath) other;
        if (otherCP is null || otherCP.getType() != type)
            return false;

        List!Certificate thisCertList = this.getCertificates();
        List!Certificate otherCertList = otherCP.getCertificates();
        return(thisCertList == otherCertList);
    }

    /**
     * Returns the hashcode for this certification path. The hash code of
     * a certification path is defined to be the result of the following
     * calculation:
     * <pre>{@code
     *  hashCode = path.getType().hashCode();
     *  hashCode = 31*hashCode + path.getCertificates().hashCode();
     * }</pre>
     * This ensures that {@code path1.equals(path2)} implies that
     * {@code path1.hashCode()==path2.hashCode()} for any two certification
     * paths, {@code path1} and {@code path2}, as required by the
     * general contract of {@code Object.hashCode}.
     *
     * @return the hashcode value for this certification path
     */
    override size_t toHash() @trusted nothrow {
        size_t hashCode = hashOf(type);
        hashCode = 31*hashCode + getCertificates().toHash();
        return hashCode;
    }

    /**
     * Returns a string representation of this certification path.
     * This calls the {@code toString} method on each of the
     * {@code Certificate}s in the path.
     *
     * @return a string representation of this certification path
     */
    override string toString() {
        Appender!string sb;
        List!Certificate certificates = getCertificates();

        sb.put("\n" ~ type ~ " Cert Path: length = "
            ~ certificates.size().to!string() ~ ".\n");
        sb.put("[\n");
        int i = 1;
        foreach(Certificate stringCert; certificates) {
            sb.put("=========================================="
                ~ "===============Certificate " ~ i.to!string() ~ " start.\n");
            sb.put(stringCert.toString());
            sb.put("\n========================================"
                ~ "=================Certificate " ~ i.to!string() ~ " end.\n\n\n");
            i++;
        }

        sb.put("\n]");
        return sb.data;
    }

    /**
     * Returns the encoded form of this certification path, using the default
     * encoding.
     *
     * @return the encoded bytes
     * @exception CertificateEncodingException if an encoding error occurs
     */
    abstract byte[] getEncoded();

    /**
     * Returns the encoded form of this certification path, using the
     * specified encoding.
     *
     * @param encoding the name of the encoding to use
     * @return the encoded bytes
     * @exception CertificateEncodingException if an encoding error occurs or
     *   the encoding requested is not supported
     */
    abstract byte[] getEncoded(string encoding);

    /**
     * Returns the list of certificates in this certification path.
     * The {@code List} returned must be immutable and thread-safe.
     *
     * @return an immutable {@code List} of {@code Certificate}s
     *         (may be empty, but not null)
     */
    abstract List!Certificate getCertificates() @trusted nothrow;

    /**
     * Replaces the {@code CertPath} to be serialized with a
     * {@code CertPathRep} object.
     *
     * @return the {@code CertPathRep} to be serialized
     *
     * @throws ObjectStreamException if a {@code CertPathRep} object
     * representing this certification path could not be created
     */
    // protected Object writeReplace() {
    //     try {
    //         return new CertPathRep(type, getEncoded());
    //     } catch (CertificateException ce) {
    //         NotSerializableException nse =
    //             new NotSerializableException
    //                 ("java.security.cert.CertPath: " ~ type);
    //         nse.initCause(ce);
    //         throw nse;
    //     }
    // }

    /**
     * Alternate {@code CertPath} class for serialization.
     * @since 1.4
     */
    protected static class CertPathRep {

        // private static final long serialVersionUID = 3015633072427920915L;

        /** The Certificate type */
        private string type;
        /** The encoded form of the cert path */
        private byte[] data;

        /**
         * Creates a {@code CertPathRep} with the specified
         * type and encoded form of a certification path.
         *
         * @param type the standard name of a {@code CertPath} type
         * @param data the encoded form of the certification path
         */
        protected this(string type, byte[] data) {
            this.type = type;
            this.data = data;
        }

        /**
         * Returns a {@code CertPath} constructed from the type and data.
         *
         * @return the resolved {@code CertPath} object
         *
         * @throws ObjectStreamException if a {@code CertPath} could not
         * be constructed
         */
        // protected Object readResolve() {
        //     try {
        //         CertificateFactory cf = CertificateFactory.getInstance(type);
        //         return cf.generateCertPath(new ByteArrayInputStream(data));
        //     } catch (CertificateException ce) {
        //         NotSerializableException nse =
        //             new NotSerializableException
        //                 ("java.security.cert.CertPath: " ~ type);
        //         nse.initCause(ce);
        //         throw nse;
        //     }
        // }
    }
}
