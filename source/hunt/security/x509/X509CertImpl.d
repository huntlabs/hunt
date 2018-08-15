module hunt.security.x509.X509CertImpl;

import hunt.security.cert.Certificate;
import hunt.security.cert.X509Certificate;

import hunt.security.key;
import hunt.security.Principal;
import hunt.security.Provider;

import hunt.security.x500.X500Principal;
import hunt.security.x509.AlgorithmId;
import hunt.security.x509.CertificateExtensions;
import hunt.security.x509.CertificateSerialNumber;
import hunt.security.x509.CertificateValidity;
import hunt.security.x509.CertificateVersion;
import hunt.security.x509.CertificateX509Key;
import hunt.security.x509.Extension;
import hunt.security.x509.KeyIdentifier;
import hunt.security.x509.SerialNumber;
import hunt.security.x509.UniqueIdentity;
import hunt.security.x509.X509CertInfo;
import hunt.security.x509.X509Factory;

import hunt.security.util.DerEncoder;
import hunt.security.util.DerValue;
import hunt.security.util.ObjectIdentifier;

import hunt.container;
import hunt.io;
import hunt.util.exception;
import hunt.util.string;

import std.conv;
import std.datetime;
import std.bigint;
import std.format;

alias BigInteger = BigInt;

/**
 * The X509CertImpl class represents an X.509 certificate. These certificates
 * are widely used to support authentication and other functionality in
 * Internet security systems.  Common applications include Privacy Enhanced
 * Mail (PEM), Transport Layer Security (SSL), code signing for trusted
 * software distribution, and Secure Electronic Transactions (SET).  There
 * is a commercial infrastructure ready to manage large scale deployments
 * of X.509 identity certificates.
 *
 * <P>These certificates are managed and vouched for by <em>Certificate
 * Authorities</em> (CAs).  CAs are services which create certificates by
 * placing data in the X.509 standard format and then digitally signing
 * that data.  Such signatures are quite difficult to forge.  CAs act as
 * trusted third parties, making introductions between agents who have no
 * direct knowledge of each other.  CA certificates are either signed by
 * themselves, or by some other CA such as a "root" CA.
 *
 * <P>RFC 1422 is very informative, though it does not describe much
 * of the recent work being done with X.509 certificates.  That includes
 * a 1996 version (X.509v3) and a variety of enhancements being made to
 * facilitate an explosion of personal certificates used as "Internet
 * Drivers' Licences", or with SET for credit card transactions.
 *
 * <P>More recent work includes the IETF PKIX Working Group efforts,
 * especially RFC2459.
 *
 * @author Dave Brownell
 * @author Amit Kapoor
 * @author Hemma Prafullchandra
 * @see X509CertInfo
 */
class X509CertImpl : X509Certificate , DerEncoder {

    // private static final long serialVersionUID = -3457612960190864406L;

    private enum string DOT = ".";
    /**
     * Public attribute names.
     */
    enum string NAME = "x509";
    enum string INFO = X509CertInfo.NAME;
    enum string ALG_ID = "algorithm";
    enum string SIGNATURE = "signature";
    enum string SIGNED_CERT = "signed_cert";

    /**
     * The following are defined for ease-of-use. These
     * are the most frequently retrieved attributes.
     */
    // x509.info.subject.dname
    enum string SUBJECT_DN = NAME ~ DOT ~ INFO ~ DOT ~
                               X509CertInfo.SUBJECT ~ DOT ~ X509CertInfo.DN_NAME;
    // x509.info.issuer.dname
    enum string ISSUER_DN = NAME ~ DOT ~ INFO ~ DOT ~
                               X509CertInfo.ISSUER ~ DOT ~ X509CertInfo.DN_NAME;
    // x509.info.serialNumber.number
    enum string SERIAL_ID = NAME ~ DOT ~ INFO ~ DOT ~
                               X509CertInfo.SERIAL_NUMBER ~ DOT ~
                               CertificateSerialNumber.NUMBER;
    // x509.info.key.value
    enum string PUBLIC_KEY = NAME ~ DOT ~ INFO ~ DOT ~
                               X509CertInfo.KEY ~ DOT ~
                               CertificateX509Key.KEY;

    // x509.info.version.value
    enum string VERSION = NAME ~ DOT ~ INFO ~ DOT ~
                               X509CertInfo.VERSION ~ DOT ~
                               CertificateVersion.VERSION;

    // x509.algorithm
    enum string SIG_ALG = NAME ~ DOT ~ ALG_ID;

    // x509.signature
    enum string SIG = NAME ~ DOT ~ SIGNATURE;    

    // when we sign and decode we set this to true
    // this is our means to make certificates immutable
    private bool readOnly = false;

    // Certificate data, and its envelope
    private byte[]              signedCert = null;
    protected X509CertInfo      info = null;
    protected AlgorithmId       algId = null;
    protected byte[]            signature = null;

    // recognized extension OIDS
    private enum string KEY_USAGE_OID = "2.5.29.15";
    private enum string EXTENDED_KEY_USAGE_OID = "2.5.29.37";
    private enum string BASIC_CONSTRAINT_OID = "2.5.29.19";
    private enum string SUBJECT_ALT_NAME_OID = "2.5.29.17";
    private enum string ISSUER_ALT_NAME_OID = "2.5.29.18";
    private enum string AUTH_INFO_ACCESS_OID = "1.3.6.1.5.5.7.1.1";

    // number of standard key usage bits.
    private enum int NUM_STANDARD_KEY_USAGE = 9;

    // SubjectAlterntativeNames cache
    // private Collection<List<?>> subjectAlternativeNames;

    // IssuerAlternativeNames cache
    // private Collection<List<?>> issuerAlternativeNames;

    // ExtendedKeyUsage cache
    private List!string extKeyUsage;

    // AuthorityInformationAccess cache
    // private Set!AccessDescription authInfoAccess;

    /**
     * PublicKey that has previously been used to verify
     * the signature of this certificate. Null if the certificate has not
     * yet been verified.
     */
    private PublicKey verifiedPublicKey;
    /**
     * If verifiedPublicKey is not null, name of the provider used to
     * successfully verify the signature of this certificate, or the
     * empty string if no provider was explicitly specified.
     */
    private string verifiedProvider;
    /**
     * If verifiedPublicKey is not null, result of the verification using
     * verifiedPublicKey and verifiedProvider. If true, verification was
     * successful, if false, it failed.
     */
    private bool verificationResult;

    /**
     * Default constructor.
     */
    this() { }

    /**
     * Unmarshals a certificate from its encoded form, parsing the
     * encoded bytes.  This form of constructor is used by agents which
     * need to examine and use certificate contents.  That is, this is
     * one of the more commonly used constructors.  Note that the buffer
     * must include only a certificate, and no "garbage" may be left at
     * the end.  If you need to ignore data at the end of a certificate,
     * use another constructor.
     *
     * @param certData the encoded bytes, with no trailing padding.
     * @exception CertificateException on parsing and initialization errors.
     */
    this(byte[] certData) {
        try {
            parse(new DerValue(certData));
        } catch (IOException e) {
            signedCert = null;
            throw new CertificateException("Unable to initialize, " ~ e.msg, e);
        }
    }

    /**
     * unmarshals an X.509 certificate from an input stream.  If the
     * certificate is RFC1421 hex-encoded, then it must begin with
     * the line X509Factory.BEGIN_CERT and end with the line
     * X509Factory.END_CERT.
     *
     * @param in an input stream holding at least one certificate that may
     *        be either DER-encoded or RFC1421 hex-encoded version of the
     *        DER-encoded certificate.
     * @exception CertificateException on parsing and initialization errors.
     */
    this(InputStream stream) {

        DerValue der = null;

        // BufferedInputStream inBuffered = new BufferedInputStream(stream);

        // // First try reading stream as HEX-encoded DER-encoded bytes,
        // // since not mistakable for raw DER
        // try {
        //     inBuffered.mark(int.max);
        //     der = readRFC1421Cert(inBuffered);
        // } catch (IOException ioe) {
        //     try {
        //         // Next, try reading stream as raw DER-encoded bytes
        //         inBuffered.reset();
        //         der = new DerValue(inBuffered);
        //     } catch (IOException ioe1) {
        //         throw new CertificateException("Input stream must be " ~
        //                                        "either DER-encoded bytes " ~
        //                                        "or RFC1421 hex-encoded " ~
        //                                        "DER-encoded bytes: " ~
        //                                        ioe1.getMessage(), ioe1);
        //     }
        // }
        // try {
        //     parse(der);
        // } catch (IOException ioe) {
        //     signedCert = null;
        //     throw new CertificateException("Unable to parse DER value of " ~
        //                                    "certificate, " ~ ioe, ioe);
        // }
        implementationMissing();
    }

    /**
     * read input stream as HEX-encoded DER-encoded bytes
     *
     * @param stream InputStream to read
     * @returns DerValue corresponding to decoded HEX-encoded bytes
     * @throws IOException if stream can not be interpreted as RFC1421
     *                     encoded bytes
     */
    private DerValue readRFC1421Cert(InputStream stream) {
        // DerValue der = null;
        // string line = null;
        // BufferedReader certBufferedReader =
        //     new BufferedReader(new InputStreamReader(stream, "ASCII"));
        // try {
        //     line = certBufferedReader.readLine();
        // } catch (IOException ioe1) {
        //     throw new IOException("Unable to read InputStream: " ~
        //                           ioe1.getMessage());
        // }
        // if (line.equals(X509Factory.BEGIN_CERT)) {
        //     /* stream appears to be hex-encoded bytes */
        //     ByteArrayOutputStream decstream = new ByteArrayOutputStream();
        //     try {
        //         while ((line = certBufferedReader.readLine()) !is null) {
        //             if (line.equals(X509Factory.END_CERT)) {
        //                 der = new DerValue(decstream.toByteArray());
        //                 break;
        //             } else {
        //                 decstream.write(Pem.decode(line));
        //             }
        //         }
        //     } catch (IOException ioe2) {
        //         throw new IOException("Unable to read InputStream: "
        //                               + ioe2.getMessage());
        //     }
        // } else {
        //     throw new IOException("InputStream is not RFC1421 hex-encoded " ~
        //                           "DER bytes");
        // }
        // return der;
                implementationMissing();
        return null;

    }

    /**
     * Construct an initialized X509 Certificate. The certificate is stored
     * in raw form and has to be signed to be useful.
     *
     * @params info the X509CertificateInfo which the Certificate is to be
     *              created from.
     */
    this(X509CertInfo certInfo) {
        this.info = certInfo;
    }

    /**
     * Unmarshal a certificate from its encoded form, parsing a DER value.
     * This form of constructor is used by agents which need to examine
     * and use certificate contents.
     *
     * @param derVal the der value containing the encoded cert.
     * @exception CertificateException on parsing and initialization errors.
     */
    this(DerValue derVal) {
        try {
            parse(derVal);
        } catch (IOException e) {
            signedCert = null;
            throw new CertificateException("Unable to initialize, " ~ e.msg, e);
        }
    }

    /**
     * Appends the certificate to an output stream.
     *
     * @param out an input stream to which the certificate is appended.
     * @exception CertificateEncodingException on encoding errors.
     */
    void encode(OutputStream outputStream)    {
        if (signedCert is null)
            throw new CertificateEncodingException(
                          "Null certificate to encode");
        try {
            outputStream.write(signedCert.dup);
        } catch (IOException e) {
            throw new CertificateEncodingException(e.toString());
        }
    }

    /**
     * DER encode this object onto an output stream.
     * Implements the <code>DerEncoder</code> interface.
     *
     * @param outputStream the output stream on which to write the DER encoding.
     *
     * @exception IOException on encoding error.
     */
    void derEncode(OutputStream outputStream) {
        if (signedCert is null)
            throw new IOException("Null certificate to encode");
        outputStream.write(signedCert.dup);
    }

    /**
     * Returns the encoded form of this certificate. It is
     * assumed that each certificate type would have only a single
     * form of encoding; for example, X.509 certificates would
     * be encoded as ASN.1 DER.
     *
     * @exception CertificateEncodingException if an encoding error occurs.
     */
    override byte[] getEncoded() {
        return getEncodedInternal().dup;
    }

    /**
     * Returned the encoding as an uncloned byte array. Callers must
     * guarantee that they neither modify it nor expose it to untrusted
     * code.
     */
    byte[] getEncodedInternal() {
        if (signedCert is null) {
            throw new CertificateEncodingException(
                          "Null certificate to encode");
        }
        return signedCert;
    }

    /**
     * Throws an exception if the certificate was not signed using the
     * verification key provided.  Successfully verifying a certificate
     * does <em>not</em> indicate that one should trust the entity which
     * it represents.
     *
     * @param key the key used for verification.
     *
     * @exception InvalidKeyException on incorrect key.
     * @exception NoSuchAlgorithmException on unsupported signature
     * algorithms.
     * @exception NoSuchProviderException if there's no default provider.
     * @exception SignatureException on signature errors.
     * @exception CertificateException on encoding errors.
     */
    override void verify(PublicKey key){
        verify(key, "");
    }

    /**
     * Throws an exception if the certificate was not signed using the
     * verification key provided.  Successfully verifying a certificate
     * does <em>not</em> indicate that one should trust the entity which
     * it represents.
     *
     * @param key the key used for verification.
     * @param sigProvider the name of the provider.
     *
     * @exception NoSuchAlgorithmException on unsupported signature
     * algorithms.
     * @exception InvalidKeyException on incorrect key.
     * @exception NoSuchProviderException on incorrect provider.
     * @exception SignatureException on signature errors.
     * @exception CertificateException on encoding errors.
     */
    override void verify(PublicKey key, string sigProvider) {
        // if (sigProvider is null) {
        //     sigProvider = "";
        // }
        // if ((verifiedPublicKey !is null) && verifiedPublicKey.equals(key)) {
        //     // this certificate has already been verified using
        //     // this key. Make sure providers match, too.
        //     if (sigProvider.equals(verifiedProvider)) {
        //         if (verificationResult) {
        //             return;
        //         } else {
        //             throw new SignatureException("Signature does not match.");
        //         }
        //     }
        // }
        // if (signedCert is null) {
        //     throw new CertificateEncodingException("Uninitialized certificate");
        // }
        // // Verify the signature ...
        // Signature sigVerf = null;
        // if (sigProvider.length() == 0) {
        //     sigVerf = Signature.getInstance(algId.getName());
        // } else {
        //     sigVerf = Signature.getInstance(algId.getName(), sigProvider);
        // }
        // sigVerf.initVerify(key);

        // byte[] rawCert = info.getEncodedInfo();
        // sigVerf.update(rawCert, 0, rawCert.length);

        // // verify may throw SignatureException for invalid encodings, etc.
        // verificationResult = sigVerf.verify(signature);
        // verifiedPublicKey = key;
        // verifiedProvider = sigProvider;

        // if (verificationResult == false) {
        //     throw new SignatureException("Signature does not match.");
        // }
        implementationMissing();
    }

    /**
     * Throws an exception if the certificate was not signed using the
     * verification key provided.  This method uses the signature verification
     * engine supplied by the specified provider. Note that the specified
     * Provider object does not have to be registered in the provider list.
     * Successfully verifying a certificate does <em>not</em> indicate that one
     * should trust the entity which it represents.
     *
     * @param key the key used for verification.
     * @param sigProvider the provider.
     *
     * @exception NoSuchAlgorithmException on unsupported signature
     * algorithms.
     * @exception InvalidKeyException on incorrect key.
     * @exception SignatureException on signature errors.
     * @exception CertificateException on encoding errors.
     */
    override void verify(PublicKey key, Provider sigProvider){
        // if (signedCert is null) {
        //     throw new CertificateEncodingException("Uninitialized certificate");
        // }
        // // Verify the signature ...
        // Signature sigVerf = null;
        // if (sigProvider is null) {
        //     sigVerf = Signature.getInstance(algId.getName());
        // } else {
        //     sigVerf = Signature.getInstance(algId.getName(), sigProvider);
        // }
        // sigVerf.initVerify(key);

        // byte[] rawCert = info.getEncodedInfo();
        // sigVerf.update(rawCert, 0, rawCert.length);

        // // verify may throw SignatureException for invalid encodings, etc.
        // verificationResult = sigVerf.verify(signature);
        // verifiedPublicKey = key;

        // if (verificationResult == false) {
        //     throw new SignatureException("Signature does not match.");
        // }
        implementationMissing();
    }

     /**
     * This static method is the default implementation of the
     * verify(PublicKey key, Provider sigProvider) method in X509Certificate.
     * Called from java.security.cert.X509Certificate.verify(PublicKey key,
     * Provider sigProvider)
     */
    static void verify(X509Certificate cert, PublicKey key,
            Provider sigProvider) {
        cert.verify(key, sigProvider);
    }

    /**
     * Creates an X.509 certificate, and signs it using the given key
     * (associating a signature algorithm and an X.500 name).
     * This operation is used to implement the certificate generation
     * functionality of a certificate authority.
     *
     * @param key the private key used for signing.
     * @param algorithm the name of the signature algorithm used.
     *
     * @exception InvalidKeyException on incorrect key.
     * @exception NoSuchAlgorithmException on unsupported signature
     * algorithms.
     * @exception NoSuchProviderException if there's no default provider.
     * @exception SignatureException on signature errors.
     * @exception CertificateException on encoding errors.
     */
    void sign(PrivateKey key, string algorithm) {
        sign(key, algorithm, null);
    }

    /**
     * Creates an X.509 certificate, and signs it using the given key
     * (associating a signature algorithm and an X.500 name).
     * This operation is used to implement the certificate generation
     * functionality of a certificate authority.
     *
     * @param key the private key used for signing.
     * @param algorithm the name of the signature algorithm used.
     * @param provider the name of the provider.
     *
     * @exception NoSuchAlgorithmException on unsupported signature
     * algorithms.
     * @exception InvalidKeyException on incorrect key.
     * @exception NoSuchProviderException on incorrect provider.
     * @exception SignatureException on signature errors.
     * @exception CertificateException on encoding errors.
     */
    void sign(PrivateKey key, string algorithm, string provider) {
    //     try {
    //         if (readOnly)
    //             throw new CertificateEncodingException(
    //                           "cannot over-write existing certificate");
    //         Signature sigEngine = null;
    //         if ((provider is null) || (provider.length() == 0))
    //             sigEngine = Signature.getInstance(algorithm);
    //         else
    //             sigEngine = Signature.getInstance(algorithm, provider);

    //         sigEngine.initSign(key);

    //                             // in case the name is reset
    //         algId = AlgorithmId.get(sigEngine.getAlgorithm());

    //         DerOutputStream outputStream = new DerOutputStream();
    //         DerOutputStream tmp = new DerOutputStream();

    //         // encode certificate info
    //         info.encode(tmp);
    //         byte[] rawCert = tmp.toByteArray();

    //         // encode algorithm identifier
    //         algId.encode(tmp);

    //         // Create and encode the signature itself.
    //         sigEngine.update(rawCert, 0, rawCert.length);
    //         signature = sigEngine.sign();
    //         tmp.putBitString(signature);

    //         // Wrap the signed data in a SEQUENCE { data, algorithm, sig }
    //         outputStream.write(DerValue.tag_Sequence, tmp);
    //         signedCert = outputStream.toByteArray();
    //         readOnly = true;

    //     } catch (IOException e) {
    //         throw new CertificateEncodingException(e.toString());
    //   }
    implementationMissing();
    }

    /**
     * Checks that the certificate is currently valid, i.e. the current
     * time is within the specified validity period.
     *
     * @exception CertificateExpiredException if the certificate has expired.
     * @exception CertificateNotYetValidException if the certificate is not
     * yet valid.
     */
    override void checkValidity() {
        Date date =  cast(Date)Clock.currTime;
        checkValidity(date);
    }

    /**
     * Checks that the specified date is within the certificate's
     * validity period, or basically if the certificate would be
     * valid at the specified date/time.
     *
     * @param date the Date to check against to see if this certificate
     *        is valid at that date/time.
     *
     * @exception CertificateExpiredException if the certificate has expired
     * with respect to the <code>date</code> supplied.
     * @exception CertificateNotYetValidException if the certificate is not
     * yet valid with respect to the <code>date</code> supplied.
     */
    override void checkValidity(Date date) {
        CertificateValidity interval = null;
        try {
            interval = cast(CertificateValidity)info.get(CertificateValidity.NAME);
        } catch (Exception e) {
            throw new CertificateNotYetValidException("Incorrect validity period");
        }
        if (interval is null)
            throw new CertificateNotYetValidException("Null validity period");
        interval.valid(date);
    }

    /**
     * Return the requested attribute from the certificate.
     *
     * Note that the X509CertInfo is not cloned for performance reasons.
     * Callers must ensure that they do not modify it. All other
     * attributes are cloned.
     *
     * @param name the name of the attribute.
     * @exception CertificateParsingException on invalid attribute identifier.
     */
    Object get(string name)
    {
        // X509AttributeName attr = new X509AttributeName(name);
        // string id = attr.getPrefix();
        // if (!(id.equalsIgnoreCase(NAME))) {
        //     throw new CertificateParsingException("Invalid root of "
        //                   ~ "attribute name, expected [" ~ NAME +
        //                   "], received " ~ "[" ~ id ~ "]");
        // }
        // attr = new X509AttributeName(attr.getSuffix());
        // id = attr.getPrefix();

        // if (id.equalsIgnoreCase(INFO)) {
        //     if (info is null) {
        //         return null;
        //     }
        //     if (attr.getSuffix() !is null) {
        //         try {
        //             return info.get(attr.getSuffix());
        //         } catch (IOException e) {
        //             throw new CertificateParsingException(e.toString());
        //         } catch (CertificateException e) {
        //             throw new CertificateParsingException(e.toString());
        //         }
        //     } else {
        //         return info;
        //     }
        // } else if (id.equalsIgnoreCase(ALG_ID)) {
        //     return(algId);
        // } else if (id.equalsIgnoreCase(SIGNATURE)) {
        //     if (signature !is null)
        //         return signature.dup;
        //     else
        //         return null;
        // } else if (id.equalsIgnoreCase(SIGNED_CERT)) {
        //     if (signedCert !is null)
        //         return signedCert.dup;
        //     else
        //         return null;
        // } else {
        //     throw new CertificateParsingException("Attribute name not "
        //          ~ "recognized or get() not allowed for the same: " ~ id);
        // }
                implementationMissing();
        return null;

    }

    /**
     * Set the requested attribute in the certificate.
     *
     * @param name the name of the attribute.
     * @param obj the value of the attribute.
     * @exception CertificateException on invalid attribute identifier.
     * @exception IOException on encoding error of attribute.
     */
    void set(string name, Object obj) {
        // check if immutable
        if (readOnly)
            throw new CertificateException("cannot over-write existing"
                                           ~ " certificate");

        // X509AttributeName attr = new X509AttributeName(name);
        // string id = attr.getPrefix();
        // if (!(id.equalsIgnoreCase(NAME))) {
        //     throw new CertificateException("Invalid root of attribute name,"
        //                    ~ " expected [" ~ NAME ~ "], received " ~ id);
        // }
        // attr = new X509AttributeName(attr.getSuffix());
        // id = attr.getPrefix();

        // if (id.equalsIgnoreCase(INFO)) {
        //     if (attr.getSuffix() is null) {
        //         if (!(obj instanceof X509CertInfo)) {
        //             throw new CertificateException("Attribute value should"
        //                             ~ " be of type X509CertInfo.");
        //         }
        //         info = (X509CertInfo)obj;
        //         signedCert = null;  //reset this as certificate data has changed
        //     } else {
        //         info.set(attr.getSuffix(), obj);
        //         signedCert = null;  //reset this as certificate data has changed
        //     }
        // } else {
        //     throw new CertificateException("Attribute name not recognized or " ~
        //                       "set() not allowed for the same: " ~ id);
        // }
        implementationMissing();
    }

    /**
     * Delete the requested attribute from the certificate.
     *
     * @param name the name of the attribute.
     * @exception CertificateException on invalid attribute identifier.
     * @exception IOException on other errors.
     */
    void remove(string name) {
        // check if immutable
        // if (readOnly)
        //     throw new CertificateException("cannot over-write existing"
        //                                    ~ " certificate");

        // X509AttributeName attr = new X509AttributeName(name);
        // string id = attr.getPrefix();
        // if (!(id.equalsIgnoreCase(NAME))) {
        //     throw new CertificateException("Invalid root of attribute name,"
        //                            ~ " expected ["
        //                            + NAME ~ "], received " ~ id);
        // }
        // attr = new X509AttributeName(attr.getSuffix());
        // id = attr.getPrefix();

        // if (id.equalsIgnoreCase(INFO)) {
        //     if (attr.getSuffix() !is null) {
        //         info = null;
        //     } else {
        //         info.remove(attr.getSuffix());
        //     }
        // } else if (id.equalsIgnoreCase(ALG_ID)) {
        //     algId = null;
        // } else if (id.equalsIgnoreCase(SIGNATURE)) {
        //     signature = null;
        // } else if (id.equalsIgnoreCase(SIGNED_CERT)) {
        //     signedCert = null;
        // } else {
        //     throw new CertificateException("Attribute name not recognized or " ~
        //                       "remove() not allowed for the same: " ~ id);
        // }
        implementationMissing();
    }

    /**
     * Return an enumeration of names of attributes existing within this
     * attribute.
     */
    Enumeration!string getElements() {
        // AttributeNameEnumeration elements = new AttributeNameEnumeration();
        // elements.addElement(NAME ~ DOT ~ INFO);
        // elements.addElement(NAME ~ DOT ~ ALG_ID);
        // elements.addElement(NAME ~ DOT ~ SIGNATURE);
        // elements.addElement(NAME ~ DOT ~ SIGNED_CERT);

        // return elements.elements();
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
     * Returns a printable representation of the certificate.  This does not
     * contain all the information available to distinguish this from any
     * other certificate.  The certificate must be fully constructed
     * before this function may be called.
     */
    override string toString() {
        if (info is null || algId is null || signature is null)
            return "";

        StringBuilder sb = new StringBuilder();

        sb.append("[\n");
        sb.append(info.toString() ~ "\n");
        sb.append("  Algorithm: [" ~ algId.to!string() ~ "]\n");

        // HexDumpEncoder encoder = new HexDumpEncoder();
        sb.append("  Signature:\n" ~ format("%(%02X%)", signature));
        sb.append("\n]");

        return sb.toString();
    }

    // the strongly typed gets, as per java.security.cert.X509Certificate

    /**
     * Gets the publickey from this certificate.
     *
     * @return the publickey.
     */
    override PublicKey getPublicKey() {
        if (info is null)
            return null;
        try {
            PublicKey key = cast(PublicKey)info.get(CertificateX509Key.NAME
                                ~ DOT ~ CertificateX509Key.KEY);
            return key;
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Gets the version number from the certificate.
     *
     * @return the version number, i.e. 1, 2 or 3.
     */
    override int getVersion() {
        if (info is null)
            return -1;
        try {
            // int vers = ((Integer)info.get(CertificateVersion.NAME
            //             ~ DOT ~ CertificateVersion.VERSION)).intValue();
            // return vers+1;
            implementationMissing();
            return 0;
        } catch (Exception e) {
            return -1;
        }
    }

    /**
     * Gets the serial number from the certificate.
     *
     * @return the serial number.
     */
    override BigInteger getSerialNumber() {
        SerialNumber ser = getSerialNumberObject();

        return ser !is null ? ser.getNumber() : BigInteger.init;
    }

    /**
     * Gets the serial number from the certificate as
     * a SerialNumber object.
     *
     * @return the serial number.
     */
    SerialNumber getSerialNumberObject() {
        if (info is null)
            return null;
        try {
            SerialNumber ser = cast(SerialNumber)info.get(
                              CertificateSerialNumber.NAME ~ DOT ~
                              CertificateSerialNumber.NUMBER);
           return ser;
        } catch (Exception e) {
            return null;
        }
    }


    /**
     * Gets the subject distinguished name from the certificate.
     *
     * @return the subject name.
     */
    override Principal getSubjectDN() {
        if (info is null)
            return null;
        try {
            Principal subject = cast(Principal)info.get(X509CertInfo.SUBJECT ~ DOT ~
                                                    X509CertInfo.DN_NAME);
            return subject;
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Get subject name as X500Principal. Overrides implementation in
     * X509Certificate with a slightly more efficient version that is
     * also aware of X509CertImpl mutability.
     */
    override X500Principal getSubjectX500Principal() {
        if (info is null) {
            return null;
        }
        try {
            X500Principal subject = cast(X500Principal)info.get(
                                            X509CertInfo.SUBJECT ~ DOT ~
                                            "x500principal");
            return subject;
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Gets the issuer distinguished name from the certificate.
     *
     * @return the issuer name.
     */
    override Principal getIssuerDN() {
        if (info is null)
            return null;
        try {
            Principal issuer = cast(Principal)info.get(X509CertInfo.ISSUER ~ DOT ~
                                                   X509CertInfo.DN_NAME);
            return issuer;
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Get issuer name as X500Principal. Overrides implementation in
     * X509Certificate with a slightly more efficient version that is
     * also aware of X509CertImpl mutability.
     */
    override X500Principal getIssuerX500Principal() {
        if (info is null) {
            return null;
        }
        try {
            X500Principal issuer = cast(X500Principal)info.get(
                                            X509CertInfo.ISSUER ~ DOT ~
                                            "x500principal");
            return issuer;
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Gets the notBefore date from the validity period of the certificate.
     *
     * @return the start date of the validity period.
     */
    override Date getNotBefore() {
        // if (info is null)
        //     return null;
        // try {
        //     Date d = (Date) info.get(CertificateValidity.NAME ~ DOT ~
        //                                 CertificateValidity.NOT_BEFORE);
        //     return d;
        // } catch (Exception e) {
        //     return null;
        // }

        implementationMissing();
        return Date.init;
    }

    /**
     * Gets the notAfter date from the validity period of the certificate.
     *
     * @return the end date of the validity period.
     */
    override Date getNotAfter() {
        // if (info is null)
        //     return null;
        // try {
        //     Date d = info.get(CertificateValidity.NAME ~ DOT ~
        //                              CertificateValidity.NOT_AFTER);
        //     return d;
        // } catch (Exception e) {
        //     return null;
        // }
        implementationMissing();
        return Date.init;
    }

    /**
     * Gets the DER encoded certificate informations, the
     * <code>tbsCertificate</code> from this certificate.
     * This can be used to verify the signature independently.
     *
     * @return the DER encoded certificate information.
     * @exception CertificateEncodingException if an encoding error occurs.
     */
    override byte[] getTBSCertificate() {
        if (info !is null) {
            return info.getEncodedInfo();
        } else
            throw new CertificateEncodingException("Uninitialized certificate");
    }

    /**
     * Gets the raw Signature bits from the certificate.
     *
     * @return the signature.
     */
    override byte[] getSignature() {
        if (signature is null)
            return null;
        return signature.dup;
    }

    /**
     * Gets the signature algorithm name for the certificate
     * signature algorithm.
     * For example, the string "SHA-1/DSA" or "DSS".
     *
     * @return the signature algorithm name.
     */
    override string getSigAlgName() {
        if (algId is null)
            return null;
        return (algId.getName());
    }

    /**
     * Gets the signature algorithm OID string from the certificate.
     * For example, the string "1.2.840.10040.4.3"
     *
     * @return the signature algorithm oid string.
     */
    override string getSigAlgOID() {
        if (algId is null)
            return null;
        ObjectIdentifier oid = algId.getOID();
        return (oid.toString());
    }

    /**
     * Gets the DER encoded signature algorithm parameters from this
     * certificate's signature algorithm.
     *
     * @return the DER encoded signature algorithm parameters, or
     *         null if no parameters are present.
     */
    override byte[] getSigAlgParams() {
        if (algId is null)
            return null;
        try {
            return algId.getEncodedParams();
        } catch (IOException e) {
            return null;
        }
    }

    /**
     * Gets the Issuer Unique Identity from the certificate.
     *
     * @return the Issuer Unique Identity.
     */
    override bool[] getIssuerUniqueID() {
        if (info is null)
            return null;
        try {
            UniqueIdentity id = cast(UniqueIdentity)info.get(
                                 X509CertInfo.ISSUER_ID);
            if (id is null)
                return null;
            else
                return (id.getId());
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Gets the Subject Unique Identity from the certificate.
     *
     * @return the Subject Unique Identity.
     */
    override bool[] getSubjectUniqueID() {
        if (info is null)
            return null;
        try {
            UniqueIdentity id = cast(UniqueIdentity)info.get(
                                 X509CertInfo.SUBJECT_ID);
            if (id is null)
                return null;
            else
                return (id.getId());
        } catch (Exception e) {
            return null;
        }
    }

    KeyIdentifier getAuthKeyId() {
        // AuthorityKeyIdentifierExtension aki
        //     = getAuthorityKeyIdentifierExtension();
        // if (aki !is null) {
        //     try {
        //         return cast(KeyIdentifier)aki.get(
        //             AuthorityKeyIdentifierExtension.KEY_ID);
        //     } catch (IOException ioe) {} // not possible
        // }
        implementationMissing();
        return null;
    }

    /**
     * Returns the subject's key identifier, or null
     */
    KeyIdentifier getSubjectKeyId() {
        // SubjectKeyIdentifierExtension ski = getSubjectKeyIdentifierExtension();
        // if (ski !is null) {
        //     try {
        //         return cast(KeyIdentifier)ski.get(
        //             SubjectKeyIdentifierExtension.KEY_ID);
        //     } catch (IOException ioe) {} // not possible
        // }
        // return null;
                implementationMissing();
        return null;

    }

    // /**
    //  * Get AuthorityKeyIdentifier extension
    //  * @return AuthorityKeyIdentifier object or null (if no such object
    //  * in certificate)
    //  */
    // AuthorityKeyIdentifierExtension getAuthorityKeyIdentifierExtension()
    // {
    //     return cast(AuthorityKeyIdentifierExtension)
    //         getExtension(PKIXExtensions.AuthorityKey_Id);
    // }

    // /**
    //  * Get BasicConstraints extension
    //  * @return BasicConstraints object or null (if no such object in
    //  * certificate)
    //  */
    // BasicConstraintsExtension getBasicConstraintsExtension() {
    //     return cast(BasicConstraintsExtension)
    //         getExtension(PKIXExtensions.BasicConstraints_Id);
    // }

    // /**
    //  * Get CertificatePoliciesExtension
    //  * @return CertificatePoliciesExtension or null (if no such object in
    //  * certificate)
    //  */
    // CertificatePoliciesExtension getCertificatePoliciesExtension() {
    //     return cast(CertificatePoliciesExtension)
    //         getExtension(PKIXExtensions.CertificatePolicies_Id);
    // }

    // /**
    //  * Get ExtendedKeyUsage extension
    //  * @return ExtendedKeyUsage extension object or null (if no such object
    //  * in certificate)
    //  */
    // ExtendedKeyUsageExtension getExtendedKeyUsageExtension() {
    //     return cast(ExtendedKeyUsageExtension)
    //         getExtension(PKIXExtensions.ExtendedKeyUsage_Id);
    // }

    // /**
    //  * Get IssuerAlternativeName extension
    //  * @return IssuerAlternativeName object or null (if no such object in
    //  * certificate)
    //  */
    // IssuerAlternativeNameExtension getIssuerAlternativeNameExtension() {
    //     return cast(IssuerAlternativeNameExtension)
    //         getExtension(PKIXExtensions.IssuerAlternativeName_Id);
    // }

    // /**
    //  * Get NameConstraints extension
    //  * @return NameConstraints object or null (if no such object in certificate)
    //  */
    // NameConstraintsExtension getNameConstraintsExtension() {
    //     return cast(NameConstraintsExtension)
    //         getExtension(PKIXExtensions.NameConstraints_Id);
    // }

    // /**
    //  * Get PolicyConstraints extension
    //  * @return PolicyConstraints object or null (if no such object in
    //  * certificate)
    //  */
    // PolicyConstraintsExtension getPolicyConstraintsExtension() {
    //     return cast(PolicyConstraintsExtension)
    //         getExtension(PKIXExtensions.PolicyConstraints_Id);
    // }

    // /**
    //  * Get PolicyMappingsExtension extension
    //  * @return PolicyMappingsExtension object or null (if no such object
    //  * in certificate)
    //  */
    // PolicyMappingsExtension getPolicyMappingsExtension() {
    //     return cast(PolicyMappingsExtension)
    //         getExtension(PKIXExtensions.PolicyMappings_Id);
    // }

    // /**
    //  * Get PrivateKeyUsage extension
    //  * @return PrivateKeyUsage object or null (if no such object in certificate)
    //  */
    // PrivateKeyUsageExtension getPrivateKeyUsageExtension() {
    //     return cast(PrivateKeyUsageExtension)
    //         getExtension(PKIXExtensions.PrivateKeyUsage_Id);
    // }

    // /**
    //  * Get SubjectAlternativeName extension
    //  * @return SubjectAlternativeName object or null (if no such object in
    //  * certificate)
    //  */
    // SubjectAlternativeNameExtension getSubjectAlternativeNameExtension()
    // {
    //     return cast(SubjectAlternativeNameExtension)
    //         getExtension(PKIXExtensions.SubjectAlternativeName_Id);
    // }

    // /**
    //  * Get SubjectKeyIdentifier extension
    //  * @return SubjectKeyIdentifier object or null (if no such object in
    //  * certificate)
    //  */
    // SubjectKeyIdentifierExtension getSubjectKeyIdentifierExtension() {
    //     return cast(SubjectKeyIdentifierExtension)
    //         getExtension(PKIXExtensions.SubjectKey_Id);
    // }

    // /**
    //  * Get CRLDistributionPoints extension
    //  * @return CRLDistributionPoints object or null (if no such object in
    //  * certificate)
    //  */
    // CRLDistributionPointsExtension getCRLDistributionPointsExtension() {
    //     return cast(CRLDistributionPointsExtension)
    //         getExtension(PKIXExtensions.CRLDistributionPoints_Id);
    // }

    /**
     * Return true if a critical extension is found that is
     * not supported, otherwise return false.
     */
    bool hasUnsupportedCriticalExtension() {
        if (info is null)
            return false;
        try {
            CertificateExtensions exts = cast(CertificateExtensions)info.get(
                                         CertificateExtensions.NAME);
            if (exts is null)
                return false;
            return exts.hasUnsupportedCriticalExtension();
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Gets a Set of the extension(s) marked CRITICAL in the
     * certificate. In the returned set, each extension is
     * represented by its OID string.
     *
     * @return a set of the extension oid strings in the
     * certificate that are marked critical.
     */
    Set!string getCriticalExtensionOIDs() {
        if (info is null) {
            return null;
        }
        try {
            CertificateExtensions exts = cast(CertificateExtensions)info.get(
                                         CertificateExtensions.NAME);
            if (exts is null) {
                return null;
            }
            Set!string extSet = new TreeSet!string();
            foreach (Extension ex ; exts.getAllExtensions()) {
                if (ex.isCritical()) {
                    extSet.add(ex.getExtensionId().toString());
                }
            }
            return extSet;
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Gets a Set of the extension(s) marked NON-CRITICAL in the
     * certificate. In the returned set, each extension is
     * represented by its OID string.
     *
     * @return a set of the extension oid strings in the
     * certificate that are NOT marked critical.
     */
    Set!string getNonCriticalExtensionOIDs() {
        // if (info is null) {
        //     return null;
        // }
        // try {
        //     CertificateExtensions exts = cast(CertificateExtensions)info.get(
        //                                  CertificateExtensions.NAME);
        //     if (exts is null) {
        //         return null;
        //     }
        //     Set!string extSet = new TreeSet!string();
        //     foreach (Extension ex ; exts.getAllExtensions()) {
        //         if (!ex.isCritical()) {
        //             extSet.add(ex.getExtensionId().toString());
        //         }
        //     }
        //     extSet.addAll(exts.getUnparseableExtensions().keySet());
        //     return extSet;
        // } catch (Exception e) {
        //     return null;
        // }
                implementationMissing();
        return null;

    }

    /**
     * Gets the extension identified by the given ObjectIdentifier
     *
     * @param oid the Object Identifier value for the extension.
     * @return Extension or null if certificate does not contain this
     *         extension
     */
    Extension getExtension(ObjectIdentifier oid) {
        if (info is null) {
            return null;
        }
        try {
            CertificateExtensions extensions;
            try {
                extensions = cast(CertificateExtensions)info.get(CertificateExtensions.NAME);
            } catch (CertificateException ce) {
                return null;
            }
            if (extensions is null) {
                return null;
            } else {
                Extension ex = extensions.getExtension(oid.toString());
                if (ex !is null) {
                    return ex;
                }
                foreach (Extension ex2; extensions.getAllExtensions()) {
                    if (ex2.getExtensionId().opEquals(cast(Object)oid)) {
                        //XXXX May want to consider cloning this
                        return ex2;
                    }
                }
                /* no such extension in this certificate */
                return null;
            }
        } catch (IOException ioe) {
            return null;
        }
    }

    Extension getUnparseableExtension(ObjectIdentifier oid) {
        if (info is null) {
            return null;
        }
        try {
            CertificateExtensions extensions;
            try {
                extensions = cast(CertificateExtensions)info.get(CertificateExtensions.NAME);
            } catch (CertificateException ce) {
                return null;
            }
            if (extensions is null) {
                return null;
            } else {
                return extensions.getUnparseableExtensions().get(oid.toString());
            }
        } catch (IOException ioe) {
            return null;
        }
    }

    /**
     * Gets the DER encoded extension identified by the given
     * oid string.
     *
     * @param oid the Object Identifier value for the extension.
     */
    byte[] getExtensionValue(string oid) {
                implementationMissing();
        return null;

        // try {
        //     ObjectIdentifier findOID = new ObjectIdentifier(oid);
        //     string extAlias = OIDMap.getName(findOID);
        //     Extension certExt = null;
        //     CertificateExtensions exts = (CertificateExtensions)info.get(
        //                              CertificateExtensions.NAME);

        //     if (extAlias is null) { // may be unknown
        //         // get the extensions, search thru' for this oid
        //         if (exts is null) {
        //             return null;
        //         }

        //         foreach (Extension ex ; exts.getAllExtensions()) {
        //             ObjectIdentifier inCertOID = ex.getExtensionId();
        //             if (inCertOID == findOID)) {
        //                 certExt = ex;
        //                 break;
        //             }
        //         }
        //     } else { // there's sub-class that can handle this extension
        //         try {
        //             certExt = cast(Extension)this.get(extAlias);
        //         } catch (CertificateException e) {
        //             // get() throws an Exception instead of returning null, ignore
        //         }
        //     }
        //     if (certExt is null) {
        //         if (exts !is null) {
        //             certExt = exts.getUnparseableExtensions().get(oid);
        //         }
        //         if (certExt is null) {
        //             return null;
        //         }
        //     }
        //     byte[] extData = certExt.getExtensionValue();
        //     if (extData is null) {
        //         return null;
        //     }
        //     DerOutputStream outputStream = new DerOutputStream();
        //     outputStream.putOctetString(extData);
        //     return outputStream.toByteArray();
        // } catch (Exception e) {
        //     return null;
        // }
    }

    /**
     * Get a bool array representing the bits of the KeyUsage extension,
     * (oid = 2.5.29.15).
     * @return the bit values of this extension as an array of booleans.
     */
    override bool[] getKeyUsage() {
        // try {
        //     string extAlias = OIDMap.getName(PKIXExtensions.KeyUsage_Id);
        //     if (extAlias is null)
        //         return null;

        //     KeyUsageExtension certExt = cast(KeyUsageExtension)this.get(extAlias);
        //     if (certExt is null)
        //         return null;

        //     bool[] ret = certExt.getBits();
        //     if (ret.length < NUM_STANDARD_KEY_USAGE) {
        //         bool[] usageBits = new bool[NUM_STANDARD_KEY_USAGE];
        //         System.arraycopy(ret, 0, usageBits, 0, ret.length);
        //         ret = usageBits;
        //     }
        //     return ret;
        // } catch (Exception e) {
        //     return null;
        // }
               implementationMissing();
        return null;

    }

    /**
     * This method are the overridden implementation of
     * getExtendedKeyUsage method in X509Certificate in the Sun
     * provider. It is better performance-wise since it returns cached
     * values.
     */
    List!string getExtendedKeyUsage() {
        // if (readOnly && extKeyUsage !is null) {
        //     return extKeyUsage;
        // } else {
        //     ExtendedKeyUsageExtension ext = getExtendedKeyUsageExtension();
        //     if (ext is null) {
        //         return null;
        //     }
        //     extKeyUsage =
        //         Collections.unmodifiableList(ext.getExtendedKeyUsage());
        //     return extKeyUsage;
        // }        
        implementationMissing();
        return null;

    }

    /**
     * This static method is the default implementation of the
     * getExtendedKeyUsage method in X509Certificate. A
     * X509Certificate provider generally should overwrite this to
     * provide among other things caching for better performance.
     */
    static List!string getExtendedKeyUsage(X509Certificate cert) {
        // try {
        //     byte[] ext = cert.getExtensionValue(EXTENDED_KEY_USAGE_OID);
        //     if (ext is null)
        //         return null;
        //     DerValue val = new DerValue(ext);
        //     byte[] data = val.getOctetString();

        //     ExtendedKeyUsageExtension ekuExt =
        //         new ExtendedKeyUsageExtension(false, data);
        //     return Collections.unmodifiableList(ekuExt.getExtendedKeyUsage());
        // } catch (IOException ioe) {
        //     throw new CertificateParsingException(ioe);
        // }
                implementationMissing();
        return null;

    }

    /**
     * Get the certificate constraints path length from the
     * the critical BasicConstraints extension, (oid = 2.5.29.19).
     * @return the length of the constraint.
     */
    override int getBasicConstraints() {
                implementationMissing();
        return 0;

        // try {
        //     string extAlias = OIDMap.getName(PKIXExtensions.BasicConstraints_Id);
        //     if (extAlias is null)
        //         return -1;
        //     BasicConstraintsExtension certExt =
        //                 cast(BasicConstraintsExtension)this.get(extAlias);
        //     if (certExt is null)
        //         return -1;

        //     if (((bool)certExt.get(BasicConstraintsExtension.IS_CA)
        //          ).booleanValue() == true)
        //         return ((Integer)certExt.get(
        //                 BasicConstraintsExtension.PATH_LEN)).intValue();
        //     else
        //         return -1;
        // } catch (Exception e) {
        //     return -1;
        // }
    }

    /**
     * Converts a GeneralNames structure into an immutable Collection of
     * alternative names (subject or issuer) in the form required by
     * {@link #getSubjectAlternativeNames} or
     * {@link #getIssuerAlternativeNames}.
     *
     * @param names the GeneralNames to be converted
     * @return an immutable Collection of alternative names
     */
    // private static Collection<List<?>> makeAltNames(GeneralNames names) {
    //     if (names.isEmpty()) {
    //         return Collections.<List<?>>emptySet();
    //     }
    //     List<List<?>> newNames = new ArrayList<>();
    //     for (GeneralName gname : names.names()) {
    //         GeneralNameInterface name = gname.getName();
    //         List<Object> nameEntry = new ArrayList<>(2);
    //         nameEntry.add(Integer.valueOf(name.getType()));
    //         switch (name.getType()) {
    //         case GeneralNameInterface.NAME_RFC822:
    //             nameEntry.add(((RFC822Name) name).getName());
    //             break;
    //         case GeneralNameInterface.NAME_DNS:
    //             nameEntry.add(((DNSName) name).getName());
    //             break;
    //         case GeneralNameInterface.NAME_DIRECTORY:
    //             nameEntry.add(((X500Name) name).getRFC2253Name());
    //             break;
    //         case GeneralNameInterface.NAME_URI:
    //             nameEntry.add(((URIName) name).getName());
    //             break;
    //         case GeneralNameInterface.NAME_IP:
    //             try {
    //                 nameEntry.add(((IPAddressName) name).getName());
    //             } catch (IOException ioe) {
    //                 // IPAddressName in cert is bogus
    //                 throw new RuntimeException("IPAddress cannot be parsed",
    //                     ioe);
    //             }
    //             break;
    //         case GeneralNameInterface.NAME_OID:
    //             nameEntry.add(((OIDName) name).getOID().toString());
    //             break;
    //         default:
    //             // add DER encoded form
    //             DerOutputStream derOut = new DerOutputStream();
    //             try {
    //                 name.encode(derOut);
    //             } catch (IOException ioe) {
    //                 // should not occur since name has already been decoded
    //                 // from cert (this would indicate a bug in our code)
    //                 throw new RuntimeException("name cannot be encoded", ioe);
    //             }
    //             nameEntry.add(derOut.toByteArray());
    //             break;
    //         }
    //         newNames.add(Collections.unmodifiableList(nameEntry));
    //     }
    //     return Collections.unmodifiableCollection(newNames);
    // }

    /**
     * Checks a Collection of altNames and clones any name entries of type
     * byte [].
     */ // only partially generified due to javac bug
    // private static Collection<List<?>> cloneAltNames(Collection<List<?>> altNames) {
    //     bool mustClone = false;
    //     for (List<?> nameEntry : altNames) {
    //         if (nameEntry.get(1) instanceof byte[]) {
    //             // must clone names
    //             mustClone = true;
    //         }
    //     }
    //     if (mustClone) {
    //         List<List<?>> namesCopy = new ArrayList<>();
    //         for (List<?> nameEntry : altNames) {
    //             Object nameObject = nameEntry.get(1);
    //             if (nameObject instanceof byte[]) {
    //                 List<Object> nameEntryCopy =
    //                                     new ArrayList<>(nameEntry);
    //                 nameEntryCopy.set(1, ((byte[])nameObject).dup);
    //                 namesCopy.add(Collections.unmodifiableList(nameEntryCopy));
    //             } else {
    //                 namesCopy.add(nameEntry);
    //             }
    //         }
    //         return Collections.unmodifiableCollection(namesCopy);
    //     } else {
    //         return altNames;
    //     }
    // }

    /**
     * This method are the overridden implementation of
     * getSubjectAlternativeNames method in X509Certificate in the Sun
     * provider. It is better performance-wise since it returns cached
     * values.
     */
    // Collection<List<?>> getSubjectAlternativeNames()
    //     {
    //     // return cached value if we can
    //     if (readOnly && subjectAlternativeNames !is null)  {
    //         return cloneAltNames(subjectAlternativeNames);
    //     }
    //     SubjectAlternativeNameExtension subjectAltNameExt =
    //         getSubjectAlternativeNameExtension();
    //     if (subjectAltNameExt is null) {
    //         return null;
    //     }
    //     GeneralNames names;
    //     try {
    //         names = subjectAltNameExt.get(
    //                 SubjectAlternativeNameExtension.SUBJECT_NAME);
    //     } catch (IOException ioe) {
    //         // should not occur
    //         return Collections.<List<?>>emptySet();
    //     }
    //     subjectAlternativeNames = makeAltNames(names);
    //     return subjectAlternativeNames;
    // }

    /**
     * This static method is the default implementation of the
     * getSubjectAlternaitveNames method in X509Certificate. A
     * X509Certificate provider generally should overwrite this to
     * provide among other things caching for better performance.
     */
    // static Collection<List<?>> getSubjectAlternativeNames(X509Certificate cert)
    //     {
    //     try {
    //         byte[] ext = cert.getExtensionValue(SUBJECT_ALT_NAME_OID);
    //         if (ext is null) {
    //             return null;
    //         }
    //         DerValue val = new DerValue(ext);
    //         byte[] data = val.getOctetString();

    //         SubjectAlternativeNameExtension subjectAltNameExt =
    //             new SubjectAlternativeNameExtension(false,
    //                                                 data);

    //         GeneralNames names;
    //         try {
    //             names = subjectAltNameExt.get(
    //                     SubjectAlternativeNameExtension.SUBJECT_NAME);
    //         }  catch (IOException ioe) {
    //             // should not occur
    //             return Collections.<List<?>>emptySet();
    //         }
    //         return makeAltNames(names);
    //     } catch (IOException ioe) {
    //         throw new CertificateParsingException(ioe);
    //     }
    // }

    /**
     * This method are the overridden implementation of
     * getIssuerAlternativeNames method in X509Certificate in the Sun
     * provider. It is better performance-wise since it returns cached
     * values.
     */
    // Collection<List<?>> getIssuerAlternativeNames()
    //     {
    //     // return cached value if we can
    //     if (readOnly && issuerAlternativeNames !is null) {
    //         return cloneAltNames(issuerAlternativeNames);
    //     }
    //     IssuerAlternativeNameExtension issuerAltNameExt =
    //         getIssuerAlternativeNameExtension();
    //     if (issuerAltNameExt is null) {
    //         return null;
    //     }
    //     GeneralNames names;
    //     try {
    //         names = issuerAltNameExt.get(
    //                 IssuerAlternativeNameExtension.ISSUER_NAME);
    //     } catch (IOException ioe) {
    //         // should not occur
    //         return Collections.<List<?>>emptySet();
    //     }
    //     issuerAlternativeNames = makeAltNames(names);
    //     return issuerAlternativeNames;
    // }

    /**
     * This static method is the default implementation of the
     * getIssuerAlternaitveNames method in X509Certificate. A
     * X509Certificate provider generally should overwrite this to
     * provide among other things caching for better performance.
     */
    // static Collection<List<?>> getIssuerAlternativeNames(X509Certificate cert)
    //     {
    //     try {
    //         byte[] ext = cert.getExtensionValue(ISSUER_ALT_NAME_OID);
    //         if (ext is null) {
    //             return null;
    //         }

    //         DerValue val = new DerValue(ext);
    //         byte[] data = val.getOctetString();

    //         IssuerAlternativeNameExtension issuerAltNameExt =
    //             new IssuerAlternativeNameExtension(false,
    //                                                 data);
    //         GeneralNames names;
    //         try {
    //             names = issuerAltNameExt.get(
    //                     IssuerAlternativeNameExtension.ISSUER_NAME);
    //         }  catch (IOException ioe) {
    //             // should not occur
    //             return Collections.<List<?>>emptySet();
    //         }
    //         return makeAltNames(names);
    //     } catch (IOException ioe) {
    //         throw new CertificateParsingException(ioe);
    //     }
    // }

    // AuthorityInfoAccessExtension getAuthorityInfoAccessExtension() {
    //     return (AuthorityInfoAccessExtension)
    //         getExtension(PKIXExtensions.AuthInfoAccess_Id);
    // }

    /************************************************************/

    /*
     * Cert is a SIGNED ASN.1 macro, a three elment sequence:
     *
     *  - Data to be signed (ToBeSigned) -- the "raw" cert
     *  - Signature algorithm (SigAlgId)
     *  - The signature bits
     *
     * This routine unmarshals the certificate, saving the signature
     * parts away for later verification.
     */
    private void parse(DerValue val) {
        // check if can over write the certificate
        if (readOnly)
            throw new CertificateParsingException(
                      "cannot over-write existing certificate");

    //     if (val.data is null || val.tag != DerValue.tag_Sequence)
    //         throw new CertificateParsingException(
    //                   "invalid DER-encoded certificate data");

    //     signedCert = val.toByteArray();
    //     DerValue[] seq = new DerValue[3];

    //     seq[0] = val.data.getDerValue();
    //     seq[1] = val.data.getDerValue();
    //     seq[2] = val.data.getDerValue();

    //     if (val.data.available() != 0) {
    //         throw new CertificateParsingException("signed overrun, bytes = "
    //                                  + val.data.available());
    //     }
    //     if (seq[0].tag != DerValue.tag_Sequence) {
    //         throw new CertificateParsingException("signed fields invalid");
    //     }

    //     algId = AlgorithmId.parse(seq[1]);
    //     signature = seq[2].getBitString();

    //     if (seq[1].data.available() != 0) {
    //         throw new CertificateParsingException("algid field overrun");
    //     }
    //     if (seq[2].data.available() != 0)
    //         throw new CertificateParsingException("signed fields overrun");

    //     // The CertificateInfo
    //     info = new X509CertInfo(seq[0]);

    //     // the "inner" and "outer" signature algorithms must match
    //     AlgorithmId infoSigAlg = (AlgorithmId)info.get(
    //                                           CertificateAlgorithmId.NAME
    //                                           ~ DOT ~
    //                                           CertificateAlgorithmId.ALGORITHM);
    //     if (! algId.equals(infoSigAlg))
    //         throw new CertificateException("Signature algorithm mismatch");
    //     readOnly = true;

            implementationMissing();
    }

    /**
     * Extract the subject or issuer X500Principal from an X509Certificate.
     * Parses the encoded form of the cert to preserve the principal's
     * ASN.1 encoding.
     */
    private static X500Principal getX500Principal(X509Certificate cert,
            bool getIssuer) {
        // byte[] encoded = cert.getEncoded();
        // DerInputStream derIn = new DerInputStream(encoded);
        // DerValue tbsCert = derIn.getSequence(3)[0];
        // DerInputStream tbsIn = tbsCert.data;
        // DerValue tmp;
        // tmp = tbsIn.getDerValue();
        // // skip version number if present
        // if (tmp.isContextSpecific(cast(byte)0)) {
        //   tmp = tbsIn.getDerValue();
        // }
        // // tmp always contains serial number now
        // tmp = tbsIn.getDerValue();              // skip signature
        // tmp = tbsIn.getDerValue();              // issuer
        // if (!getIssuer) {
        //     tmp = tbsIn.getDerValue();          // skip validity
        //     tmp = tbsIn.getDerValue();          // subject
        // }
        // byte[] principalBytes = tmp.toByteArray();
        // return new X500Principal(principalBytes);
            implementationMissing();
        return null;

    }

    /**
     * Extract the subject X500Principal from an X509Certificate.
     * Called from java.security.cert.X509Certificate.getSubjectX500Principal().
     */
    static X500Principal getSubjectX500Principal(X509Certificate cert) {
        try {
            return getX500Principal(cert, false);
        } catch (Exception e) {
            throw new RuntimeException("Could not parse subject", e);
        }
    }

    /**
     * Extract the issuer X500Principal from an X509Certificate.
     * Called from java.security.cert.X509Certificate.getIssuerX500Principal().
     */
    static X500Principal getIssuerX500Principal(X509Certificate cert) {
        try {
            return getX500Principal(cert, true);
        } catch (Exception e) {
            throw new RuntimeException("Could not parse issuer", e);
        }
    }

    /**
     * Returned the encoding of the given certificate for internal use.
     * Callers must guarantee that they neither modify it nor expose it
     * to untrusted code. Uses getEncodedInternal() if the certificate
     * is instance of X509CertImpl, getEncoded() otherwise.
     */
    static byte[] getEncodedInternal(Certificate cert) {
        X509CertImpl impl = cast(X509CertImpl)cert;
        if (impl !is null) {
            return impl.getEncodedInternal();
        } else {
            return cert.getEncoded();
        }
    }

    /**
     * Utility method to convert an arbitrary instance of X509Certificate
     * to a X509CertImpl. Does a cast if possible, otherwise reparses
     * the encoding.
     */
    static X509CertImpl toImpl(X509Certificate cert) {
        X509CertImpl impl = cast(X509CertImpl)cert;
        if (impl !is null) {
            return impl;
        } else {
            return X509Factory.intern(cert);
        }
    }

    /**
     * Utility method to test if a certificate is self-issued. This is
     * the case iff the subject and issuer X500Principals are equal.
     */
    static bool isSelfIssued(X509Certificate cert) {
        X500Principal subject = cert.getSubjectX500Principal();
        X500Principal issuer = cert.getIssuerX500Principal();
        return subject == issuer;
    }

    /**
     * Utility method to test if a certificate is self-signed. This is
     * the case iff the subject and issuer X500Principals are equal
     * AND the certificate's subject key can be used to verify
     * the certificate. In case of exception, returns false.
     */
    static bool isSelfSigned(X509Certificate cert,
        string sigProvider) {
        if (isSelfIssued(cert)) {
            // try {
            //     if (sigProvider is null) {
            //         cert.verify(cert.getPublicKey());
            //     } else {
            //         cert.verify(cert.getPublicKey(), sigProvider);
            //     }
            //     return true;
            // } catch (Exception e) {
            //     // In case of exception, return false
            // }
                    implementationMissing();

        }
        return false;
    }

    // private ConcurrentHashMap<string,string> fingerprints =
    //         new ConcurrentHashMap<>(2);

    string getFingerprint(string algorithm) {
        // return fingerprints.computeIfAbsent(algorithm,
        //         x -> getFingerprint(x, this));
                implementationMissing();
        return null;

    }

    /**
     * Gets the requested finger print of the certificate. The result
     * only contains 0-9 and A-F. No small case, no colon.
     */
    static string getFingerprint(string algorithm,
            X509Certificate cert) {
        // string fingerPrint = "";
        // try {
        //     byte[] encCertInfo = cert.getEncoded();
        //     MessageDigest md = MessageDigest.getInstance(algorithm);
        //     byte[] digest = md.digest(encCertInfo);
        //     StringBuffer buf = new StringBuffer();
        //     for (int i = 0; i < digest.length; i++) {
        //         byte2hex(digest[i], buf);
        //     }
        //     fingerPrint = buf.toString();
        // } catch (Exception e) {
        //     // ignored
        // }
        // return fingerPrint;
                implementationMissing();
        return null;

    }

    /**
     * Converts a byte to hex digit and writes to the supplied buffer
     */
    // private static void byte2hex(byte b, StringBuffer buf) {
    //     char[] hexChars = { '0', '1', '2', '3', '4', '5', '6', '7', '8',
    //             '9', 'A', 'B', 'C', 'D', 'E', 'F' };
    //     int high = ((b & 0xf0) >> 4);
    //     int low = (b & 0x0f);
    //     buf.append(hexChars[high]);
    //     buf.append(hexChars[low]);
    // }
}
