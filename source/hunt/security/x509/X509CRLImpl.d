module hunt.security.x509.X509CRLImpl;

import hunt.security.key;
import hunt.security.Provider;
import hunt.security.cert.X509CRL;
import hunt.security.cert.X509CRLEntry;
import hunt.security.x500.X500Principal;
import hunt.security.x509.AlgorithmId;
import hunt.security.x509.X500Name;
import hunt.security.util.DerEncoder;

import hunt.container;

import hunt.io.common;

import hunt.util.common;
import hunt.util.exception;
import hunt.util.string;

import std.algorithm;
import std.bigint;
import std.conv;
import std.datetime;

alias BigInteger = BigInt;

/**
 * <p>
 * An implementation for X509 CRL (Certificate Revocation List).
 * <p>
 * The X.509 v2 CRL format is described below in ASN.1:
 * <pre>
 * CertificateList  ::=  SEQUENCE  {
 *     tbsCertList          TBSCertList,
 *     signatureAlgorithm   AlgorithmIdentifier,
 *     signature            BIT STRING  }
 * </pre>
 * More information can be found in
 * <a href="http://www.ietf.org/rfc/rfc3280.txt">RFC 3280: Internet X.509
 * Public Key Infrastructure Certificate and CRL Profile</a>.
 * <p>
 * The ASN.1 definition of <code>tbsCertList</code> is:
 * <pre>
 * TBSCertList  ::=  SEQUENCE  {
 *     version                 Version OPTIONAL,
 *                             -- if present, must be v2
 *     signature               AlgorithmIdentifier,
 *     issuer                  Name,
 *     thisUpdate              ChoiceOfTime,
 *     nextUpdate              ChoiceOfTime OPTIONAL,
 *     revokedCertificates     SEQUENCE OF SEQUENCE  {
 *         userCertificate         CertificateSerialNumber,
 *         revocationDate          ChoiceOfTime,
 *         crlEntryExtensions      Extensions OPTIONAL
 *                                 -- if present, must be v2
 *         }  OPTIONAL,
 *     crlExtensions           [0]  EXPLICIT Extensions OPTIONAL
 *                                  -- if present, must be v2
 *     }
 * </pre>
 *
 * @author Hemma Prafullchandra
 * @see X509CRL
 */
class X509CRLImpl : X509CRL , DerEncoder {

    // CRL data, and its envelope
    private byte[]      signedCRL = null; // DER encoded crl
    private byte[]      signature = null; // raw signature bits
    private byte[]      tbsCertList = null; // DER encoded "to-be-signed" CRL
    private AlgorithmId sigAlgId = null; // sig alg in CRL

    // crl information
    private int              _version;
    private AlgorithmId      infoSigAlgId; // sig alg in "to-be-signed" crl
    private X500Name         issuer = null;
    private X500Principal    issuerPrincipal = null;
    private Date             thisUpdate = null;
    private Date             nextUpdate = null;
    private Map!(X509IssuerSerial,X509CRLEntry) revokedMap;
    private List!X509CRLEntry revokedList;
    private CRLExtensions    extensions = null;
    private enum bool isExplicit = true;
    private enum long YR_2050 = 2524636800000L;

    private bool readOnly = false;

    /**
     * PublicKey that has previously been used to successfully verify
     * the signature of this CRL. Null if the CRL has not
     * yet been verified (successfully).
     */
    private PublicKey verifiedPublicKey;
    /**
     * If verifiedPublicKey is not null, name of the provider used to
     * successfully verify the signature of this CRL, or the
     * empty string if no provider was explicitly specified.
     */
    private string verifiedProvider;

    /**
     * Not to be used. As it would lead to cases of uninitialized
     * CRL objects.
     */
    private this() {
        revokedMap = new TreeMap!(X509IssuerSerial,X509CRLEntry)();
        revokedList = new LinkedList!X509CRLEntry();
     }

    /**
     * Unmarshals an X.509 CRL from its encoded form, parsing the encoded
     * bytes.  This form of constructor is used by agents which
     * need to examine and use CRL contents. Note that the buffer
     * must include only one CRL, and no "garbage" may be left at
     * the end.
     *
     * @param crlData the encoded bytes, with no trailing padding.
     * @exception CRLException on parsing errors.
     */
    this(byte[] crlData) {
        this();
        try {
            parse(new DerValue(crlData));
        } catch (IOException e) {
            signedCRL = null;
            throw new CRLException("Parsing error: " ~ e.getMessage());
        }
    }

    /**
     * Unmarshals an X.509 CRL from an DER value.
     *
     * @param val a DER value holding at least one CRL
     * @exception CRLException on parsing errors.
     */
    this(DerValue val) {
        this();
        try {
            parse(val);
        } catch (IOException e) {
            signedCRL = null;
            throw new CRLException("Parsing error: " ~ e.getMessage());
        }
    }

    /**
     * Unmarshals an X.509 CRL from an input stream. Only one CRL
     * is expected at the end of the input stream.
     *
     * @param inStrm an input stream holding at least one CRL
     * @exception CRLException on parsing errors.
     */
    this(InputStream inStrm) {
        this();
        try {
            parse(new DerValue(inStrm));
        } catch (IOException e) {
            signedCRL = null;
            throw new CRLException("Parsing error: " ~ e.getMessage());
        }
    }

    /**
     * Initial CRL constructor, no revoked certs, and no extensions.
     *
     * @param issuer the name of the CA issuing this CRL.
     * @param thisUpdate the Date of this issue.
     * @param nextUpdate the Date of the next CRL.
     */
    this(X500Name issuer, Date thisDate, Date nextDate) {
        this();
        this.issuer = issuer;
        this.thisUpdate = thisDate;
        this.nextUpdate = nextDate;
    }

    /**
     * CRL constructor, revoked certs, no extensions.
     *
     * @param issuer the name of the CA issuing this CRL.
     * @param thisUpdate the Date of this issue.
     * @param nextUpdate the Date of the next CRL.
     * @param badCerts the array of CRL entries.
     *
     * @exception CRLException on parsing/construction errors.
     */
    this(X500Name issuer, Date thisDate, Date nextDate,
                       X509CRLEntry[] badCerts)
    {
        this();
        this.issuer = issuer;
        this.thisUpdate = thisDate;
        this.nextUpdate = nextDate;
        if (badCerts !is null) {
            X500Principal crlIssuer = getIssuerX500Principal();
            X500Principal badCertIssuer = crlIssuer;
            for (int i = 0; i < badCerts.length; i++) {
                X509CRLEntryImpl badCert = cast(X509CRLEntryImpl)badCerts[i];
                try {
                    badCertIssuer = getCertIssuer(badCert, badCertIssuer);
                } catch (IOException ioe) {
                    throw new CRLException(ioe);
                }
                badCert.setCertificateIssuer(crlIssuer, badCertIssuer);
                X509IssuerSerial issuerSerial = new X509IssuerSerial
                    (badCertIssuer, badCert.getSerialNumber());
                this.revokedMap.put(issuerSerial, badCert);
                this.revokedList.add(badCert);
                if (badCert.hasExtensions()) {
                    this._version = 1;
                }
            }
        }
    }

    /**
     * CRL constructor, revoked certs and extensions.
     *
     * @param issuer the name of the CA issuing this CRL.
     * @param thisUpdate the Date of this issue.
     * @param nextUpdate the Date of the next CRL.
     * @param badCerts the array of CRL entries.
     * @param crlExts the CRL extensions.
     *
     * @exception CRLException on parsing/construction errors.
     */
    this(X500Name issuer, Date thisDate, Date nextDate,
               X509CRLEntry[] badCerts, CRLExtensions crlExts)       
    {
        this(issuer, thisDate, nextDate, badCerts);
        if (crlExts !is null) {
            this.extensions = crlExts;
            this._version = 1;
        }
    }

    /**
     * Returned the encoding as an uncloned byte array. Callers must
     * guarantee that they neither modify it nor expose it to untrusted
     * code.
     */
    byte[] getEncodedInternal() {
        if (signedCRL is null) {
            throw new CRLException("Null CRL to encode");
        }
        return signedCRL;
    }

    /**
     * Returns the ASN.1 DER encoded form of this CRL.
     *
     * @exception CRLException if an encoding error occurs.
     */
    byte[] getEncoded() {
        return getEncodedInternal().clone();
    }

    /**
     * Encodes the "to-be-signed" CRL to the OutputStream.
     *
     * @param out the OutputStream to write to.
     * @exception CRLException on encoding errors.
     */
    void encodeInfo(OutputStream outputStream) {
        try {
            DerOutputStream tmp = new DerOutputStream();
            DerOutputStream rCerts = new DerOutputStream();
            DerOutputStream seq = new DerOutputStream();

            if (_version != 0) // v2 crl encode version
                tmp.putInteger(_version);
            infoSigAlgId.encode(tmp);
            if ((_version == 0) && (issuer.toString() is null))
                throw new CRLException("Null Issuer DN not allowed in v1 CRL");
            issuer.encode(tmp);

            if (thisUpdate.getTime() < YR_2050)
                tmp.putUTCTime(thisUpdate);
            else
                tmp.putGeneralizedTime(thisUpdate);

            if (nextUpdate !is null) {
                if (nextUpdate.getTime() < YR_2050)
                    tmp.putUTCTime(nextUpdate);
                else
                    tmp.putGeneralizedTime(nextUpdate);
            }

            if (!revokedList.isEmpty()) {
                foreach (X509CRLEntry entry ; revokedList) {
                    (cast(X509CRLEntryImpl)entry).encode(rCerts);
                }
                tmp.write(DerValue.tag_Sequence, rCerts);
            }

            if (extensions !is null)
                extensions.encode(tmp, isExplicit);

            seq.write(DerValue.tag_Sequence, tmp);

            tbsCertList = seq.toByteArray();
            outputStream.write(tbsCertList);
        } catch (IOException e) {
             throw new CRLException("Encoding error: " ~ e.getMessage());
        }
    }

    /**
     * Verifies that this CRL was signed using the
     * private key that corresponds to the given key.
     *
     * @param key the PublicKey used to carry out the verification.
     *
     * @exception NoSuchAlgorithmException on unsupported signature
     * algorithms.
     * @exception InvalidKeyException on incorrect key.
     * @exception NoSuchProviderException if there's no default provider.
     * @exception SignatureException on signature errors.
     * @exception CRLException on encoding errors.
     */
    void verify(PublicKey key) {
        verify(key, "");
    }

    /**
     * Verifies that this CRL was signed using the
     * private key that corresponds to the given key,
     * and that the signature verification was computed by
     * the given provider.
     *
     * @param key the PublicKey used to carry out the verification.
     * @param sigProvider the name of the signature provider.
     *
     * @exception NoSuchAlgorithmException on unsupported signature
     * algorithms.
     * @exception InvalidKeyException on incorrect key.
     * @exception NoSuchProviderException on incorrect provider.
     * @exception SignatureException on signature errors.
     * @exception CRLException on encoding errors.
     */
    void verify(PublicKey key, string sigProvider) {
        if (sigProvider is null) {
            sigProvider = "";
        }
        if ((verifiedPublicKey !is null) && verifiedPublicKey.equals(key)) {
            // this CRL has already been successfully verified using
            // this key. Make sure providers match, too.
            if (sigProvider.equals(verifiedProvider)) {
                return;
            }
        }
        if (signedCRL is null) {
            throw new CRLException("Uninitialized CRL");
        }
        Signature   sigVerf = null;
        if (sigProvider.length() == 0) {
            sigVerf = Signature.getInstance(sigAlgId.getName());
        } else {
            sigVerf = Signature.getInstance(sigAlgId.getName(), sigProvider);
        }
        sigVerf.initVerify(key);

        if (tbsCertList is null) {
            throw new CRLException("Uninitialized CRL");
        }

        sigVerf.update(tbsCertList, 0, tbsCertList.length);

        if (!sigVerf.verify(signature)) {
            throw new SignatureException("Signature does not match.");
        }
        verifiedPublicKey = key;
        verifiedProvider = sigProvider;
    }

    /**
     * Verifies that this CRL was signed using the
     * private key that corresponds to the given key,
     * and that the signature verification was computed by
     * the given provider. Note that the specified Provider object
     * does not have to be registered in the provider list.
     *
     * @param key the PublicKey used to carry out the verification.
     * @param sigProvider the signature provider.
     *
     * @exception NoSuchAlgorithmException on unsupported signature
     * algorithms.
     * @exception InvalidKeyException on incorrect key.
     * @exception SignatureException on signature errors.
     * @exception CRLException on encoding errors.
     */
    void verify(PublicKey key, Provider sigProvider) {

        if (signedCRL is null) {
            throw new CRLException("Uninitialized CRL");
        }
        Signature sigVerf = null;
        if (sigProvider is null) {
            sigVerf = Signature.getInstance(sigAlgId.getName());
        } else {
            sigVerf = Signature.getInstance(sigAlgId.getName(), sigProvider);
        }
        sigVerf.initVerify(key);

        if (tbsCertList is null) {
            throw new CRLException("Uninitialized CRL");
        }

        sigVerf.update(tbsCertList, 0, tbsCertList.length);

        if (!sigVerf.verify(signature)) {
            throw new SignatureException("Signature does not match.");
        }
        verifiedPublicKey = key;
    }

    /**
     * This static method is the default implementation of the
     * verify(PublicKey key, Provider sigProvider) method in X509CRL.
     * Called from java.security.cert.X509CRL.verify(PublicKey key,
     * Provider sigProvider)
     */
    static void verify(X509CRL crl, PublicKey key,
            Provider sigProvider) {
        crl.verify(key, sigProvider);
    }

    /**
     * Encodes an X.509 CRL, and signs it using the given key.
     *
     * @param key the private key used for signing.
     * @param algorithm the name of the signature algorithm used.
     *
     * @exception NoSuchAlgorithmException on unsupported signature
     * algorithms.
     * @exception InvalidKeyException on incorrect key.
     * @exception NoSuchProviderException on incorrect provider.
     * @exception SignatureException on signature errors.
     * @exception CRLException if any mandatory data was omitted.
     */
    void sign(PrivateKey key, string algorithm) {
        sign(key, algorithm, null);
    }

    /**
     * Encodes an X.509 CRL, and signs it using the given key.
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
     * @exception CRLException if any mandatory data was omitted.
     */
    void sign(PrivateKey key, string algorithm, string provider) {
        try {
            if (readOnly)
                throw new CRLException("cannot over-write existing CRL");
            Signature sigEngine = null;
            if ((provider is null) || (provider.length() == 0))
                sigEngine = Signature.getInstance(algorithm);
            else
                sigEngine = Signature.getInstance(algorithm, provider);

            sigEngine.initSign(key);

                                // in case the name is reset
            sigAlgId = AlgorithmId.get(sigEngine.getAlgorithm());
            infoSigAlgId = sigAlgId;

            DerOutputStream ot = new DerOutputStream();
            DerOutputStream tmp = new DerOutputStream();

            // encode crl info
            encodeInfo(tmp);

            // encode algorithm identifier
            sigAlgId.encode(tmp);

            // Create and encode the signature itself.
            sigEngine.update(tbsCertList, 0, tbsCertList.length);
            signature = sigEngine.sign();
            tmp.putBitString(signature);

            // Wrap the signed data in a SEQUENCE { data, algorithm, sig }
            ot.write(DerValue.tag_Sequence, tmp);
            signedCRL = ot.toByteArray();
            readOnly = true;

        } catch (IOException e) {
            throw new CRLException("Error while encoding data: " ~
                                   e.getMessage());
        }
    }

    /**
     * Returns a printable string of this CRL.
     *
     * @return value of this CRL in a printable form.
     */
    string toString() {
        StringBuffer sb = new StringBuffer();
        sb.append("X.509 CRL v" ~ (_version+1) ~ "\n");
        if (sigAlgId !is null)
            sb.append("Signature Algorithm: " ~ sigAlgId.toString() +
                  ", OID=" ~ (sigAlgId.getOID()).toString() ~ "\n");
        if (issuer !is null)
            sb.append("Issuer: " ~ issuer.toString() ~ "\n");
        if (thisUpdate !is null)
            sb.append("\nThis Update: " ~ thisUpdate.toString() ~ "\n");
        if (nextUpdate !is null)
            sb.append("Next Update: " ~ nextUpdate.toString() ~ "\n");
        if (revokedList.isEmpty())
            sb.append("\nNO certificates have been revoked\n");
        else {
            sb.append("\nRevoked Certificates: " ~ revokedList.size());
            int i = 1;
            foreach (X509CRLEntry entry; revokedList) {
                sb.append("\n[" ~ to!string(i++) ~ "] " ~ entry.toString());
            }
        }
        if (extensions !is null) {
            Collection!Extension allExts = extensions.getAllExtensions();
            Object[] objs = allExts.toArray();
            sb.append("\nCRL Extensions: " ~ objs.length);
            for (int i = 0; i < objs.length; i++) {
                sb.append("\n[" ~ (i+1) ~ "]: ");
                Extension ext = cast(Extension)objs[i];
                try {
                   if (OIDMap.getClass(ext.getExtensionId()) is null) {
                       sb.append(ext.toString());
                       byte[] extValue = ext.getExtensionValue();
                       if (extValue !is null) {
                           DerOutputStream ot = new DerOutputStream();
                           ot.putOctetString(extValue);
                           extValue = ot.toByteArray();
                           HexDumpEncoder enc = new HexDumpEncoder();
                           sb.append("Extension unknown: "
                                     ~ "DER encoded OCTET string =\n"
                                     + enc.encodeBuffer(extValue) ~ "\n");
                      }
                   } else
                       sb.append(ext.toString()); // sub-class exists
                } catch (Exception e) {
                    sb.append(", Error parsing this extension");
                }
            }
        }
        if (signature !is null) {
            HexDumpEncoder encoder = new HexDumpEncoder();
            sb.append("\nSignature:\n" ~ encoder.encodeBuffer(signature)
                      ~ "\n");
        } else
            sb.append("NOT signed yet\n");
        return sb.toString();
    }

    /**
     * Checks whether the given certificate is on this CRL.
     *
     * @param cert the certificate to check for.
     * @return true if the given certificate is on this CRL,
     * false otherwise.
     */
    bool isRevoked(Certificate cert) {
        if (revokedMap.isEmpty()) {
            return false;
        }
        X509Certificate xcert = cast(X509Certificate) cert;
        if(xcert is null)   return false;

        X509IssuerSerial issuerSerial = new X509IssuerSerial(xcert);
        return revokedMap.containsKey(issuerSerial);
    }

    /**
     * Gets the version number from this CRL.
     * The ASN.1 definition for this is:
     * <pre>
     * Version  ::=  INTEGER  {  v1(0), v2(1), v3(2)  }
     *             -- v3 does not apply to CRLs but appears for consistency
     *             -- with definition of Version for certs
     * </pre>
     * @return the version number, i.e. 1 or 2.
     */
    int getVersion() {
        return _version+1;
    }

    /**
     * Gets the issuer distinguished name from this CRL.
     * The issuer name identifies the entity who has signed (and
     * issued the CRL). The issuer name field contains an
     * X.500 distinguished name (DN).
     * The ASN.1 definition for this is:
     * <pre>
     * issuer    Name
     *
     * Name ::= CHOICE { RDNSequence }
     * RDNSequence ::= SEQUENCE OF RelativeDistinguishedName
     * RelativeDistinguishedName ::=
     *     SET OF AttributeValueAssertion
     *
     * AttributeValueAssertion ::= SEQUENCE {
     *                               AttributeType,
     *                               AttributeValue }
     * AttributeType ::= OBJECT IDENTIFIER
     * AttributeValue ::= ANY
     * </pre>
     * The Name describes a hierarchical name composed of attributes,
     * such as country name, and corresponding values, such as US.
     * The type of the component AttributeValue is determined by the
     * AttributeType; in general it will be a directoryString.
     * A directoryString is usually one of PrintableString,
     * TeletexString or UniversalString.
     * @return the issuer name.
     */
    Principal getIssuerDN() {
        return cast(Principal)issuer;
    }

    /**
     * Return the issuer as X500Principal. Overrides method in X509CRL
     * to provide a slightly more efficient version.
     */
    X500Principal getIssuerX500Principal() {
        if (issuerPrincipal is null) {
            issuerPrincipal = issuer.asX500Principal();
        }
        return issuerPrincipal;
    }

    /**
     * Gets the thisUpdate date from the CRL.
     * The ASN.1 definition for this is:
     *
     * @return the thisUpdate date from the CRL.
     */
    Date getThisUpdate() {
        return (new Date(thisUpdate.getTime()));
    }

    /**
     * Gets the nextUpdate date from the CRL.
     *
     * @return the nextUpdate date from the CRL, or null if
     * not present.
     */
    Date getNextUpdate() {
        if (nextUpdate is null)
            return null;
        return (new Date(nextUpdate.getTime()));
    }

    /**
     * Gets the CRL entry with the given serial number from this CRL.
     *
     * @return the entry with the given serial number, or <code>null</code> if
     * no such entry exists in the CRL.
     * @see X509CRLEntry
     */
    X509CRLEntry getRevokedCertificate(BigInteger serialNumber) {
        if (revokedMap.isEmpty()) {
            return null;
        }
        // assume this is a direct CRL entry (cert and CRL issuer are the same)
        X509IssuerSerial issuerSerial = new X509IssuerSerial
            (getIssuerX500Principal(), serialNumber);
        return revokedMap.get(issuerSerial);
    }

    /**
     * Gets the CRL entry for the given certificate.
     */
    X509CRLEntry getRevokedCertificate(X509Certificate cert) {
        if (revokedMap.isEmpty()) {
            return null;
        }
        X509IssuerSerial issuerSerial = new X509IssuerSerial(cert);
        return revokedMap.get(issuerSerial);
    }

    /**
     * Gets all the revoked certificates from the CRL.
     * A Set of X509CRLEntry.
     *
     * @return all the revoked certificates or <code>null</code> if there are
     * none.
     * @see X509CRLEntry
     */
    Set!X509CRLEntry getRevokedCertificates() {
        if (revokedList.isEmpty()) {
            return null;
        } else {
            return new TreeSet!X509CRLEntry(revokedList);
        }
    }

    /**
     * Gets the DER encoded CRL information, the
     * <code>tbsCertList</code> from this CRL.
     * This can be used to verify the signature independently.
     *
     * @return the DER encoded CRL information.
     * @exception CRLException on encoding errors.
     */
    byte[] getTBSCertList() {
        if (tbsCertList is null)
            throw new CRLException("Uninitialized CRL");
        return tbsCertList.clone();
    }

    /**
     * Gets the raw Signature bits from the CRL.
     *
     * @return the signature.
     */
    byte[] getSignature() {
        if (signature is null)
            return null;
        return signature.clone();
    }

    /**
     * Gets the signature algorithm name for the CRL
     * signature algorithm. For example, the string "SHA1withDSA".
     * The ASN.1 definition for this is:
     * <pre>
     * AlgorithmIdentifier  ::=  SEQUENCE  {
     *     algorithm               OBJECT IDENTIFIER,
     *     parameters              ANY DEFINED BY algorithm OPTIONAL  }
     *                             -- contains a value of the type
     *                             -- registered for use with the
     *                             -- algorithm object identifier value
     * </pre>
     *
     * @return the signature algorithm name.
     */
    string getSigAlgName() {
        if (sigAlgId is null)
            return null;
        return sigAlgId.getName();
    }

    /**
     * Gets the signature algorithm OID string from the CRL.
     * An OID is represented by a set of positive whole number separated
     * by ".", that means,<br>
     * &lt;positive whole number&gt;.&lt;positive whole number&gt;.&lt;...&gt;
     * For example, the string "1.2.840.10040.4.3" identifies the SHA-1
     * with DSA signature algorithm defined in
     * <a href="http://www.ietf.org/rfc/rfc3279.txt">RFC 3279: Algorithms and
     * Identifiers for the Internet X.509 Public Key Infrastructure Certificate
     * and CRL Profile</a>.
     *
     * @return the signature algorithm oid string.
     */
    string getSigAlgOID() {
        if (sigAlgId is null)
            return null;
        ObjectIdentifier oid = sigAlgId.getOID();
        return oid.toString();
    }

    /**
     * Gets the DER encoded signature algorithm parameters from this
     * CRL's signature algorithm. In most cases, the signature
     * algorithm parameters are null, the parameters are usually
     * supplied with the Public Key.
     *
     * @return the DER encoded signature algorithm parameters, or
     *         null if no parameters are present.
     */
    byte[] getSigAlgParams() {
        if (sigAlgId is null)
            return null;
        try {
            return sigAlgId.getEncodedParams();
        } catch (IOException e) {
            return null;
        }
    }

    /**
     * Gets the signature AlgorithmId from the CRL.
     *
     * @return the signature AlgorithmId
     */
    AlgorithmId getSigAlgId() {
        return sigAlgId;
    }

    /**
     * return the AuthorityKeyIdentifier, if any.
     *
     * @returns AuthorityKeyIdentifier or null
     *          (if no AuthorityKeyIdentifierExtension)
     * @throws IOException on error
     */
    KeyIdentifier getAuthKeyId() {
        AuthorityKeyIdentifierExtension aki = getAuthKeyIdExtension();
        if (aki !is null) {
            KeyIdentifier keyId = cast(KeyIdentifier)aki.get(AuthorityKeyIdentifierExtension.KEY_ID);
            return keyId;
        } else {
            return null;
        }
    }

    /**
     * return the AuthorityKeyIdentifierExtension, if any.
     *
     * @returns AuthorityKeyIdentifierExtension or null (if no such extension)
     * @throws IOException on error
     */
    AuthorityKeyIdentifierExtension getAuthKeyIdExtension() {
        Object obj = getExtension(PKIXExtensions.AuthorityKey_Id);
        return cast(AuthorityKeyIdentifierExtension)obj;
    }

    /**
     * return the CRLNumberExtension, if any.
     *
     * @returns CRLNumberExtension or null (if no such extension)
     * @throws IOException on error
     */
    CRLNumberExtension getCRLNumberExtension() {
        Object obj = getExtension(PKIXExtensions.CRLNumber_Id);
        return cast(CRLNumberExtension)obj;
    }

    /**
     * return the CRL number from the CRLNumberExtension, if any.
     *
     * @returns number or null (if no such extension)
     * @throws IOException on error
     */
    BigInteger getCRLNumber() {
        CRLNumberExtension numExt = getCRLNumberExtension();
        if (numExt !is null) {
            BigInteger num = numExt.get(CRLNumberExtension.NUMBER);
            return num;
        } else {
            return null;
        }
    }

    /**
     * return the DeltaCRLIndicatorExtension, if any.
     *
     * @returns DeltaCRLIndicatorExtension or null (if no such extension)
     * @throws IOException on error
     */
    DeltaCRLIndicatorExtension getDeltaCRLIndicatorExtension()
        {
        Object obj = getExtension(PKIXExtensions.DeltaCRLIndicator_Id);
        return cast(DeltaCRLIndicatorExtension)obj;
    }

    /**
     * return the base CRL number from the DeltaCRLIndicatorExtension, if any.
     *
     * @returns number or null (if no such extension)
     * @throws IOException on error
     */
    BigInteger getBaseCRLNumber() {
        DeltaCRLIndicatorExtension dciExt = getDeltaCRLIndicatorExtension();
        if (dciExt !is null) {
            BigInteger num = dciExt.get(DeltaCRLIndicatorExtension.NUMBER);
            return num;
        } else {
            return null;
        }
    }

    /**
     * return the IssuerAlternativeNameExtension, if any.
     *
     * @returns IssuerAlternativeNameExtension or null (if no such extension)
     * @throws IOException on error
     */
    IssuerAlternativeNameExtension getIssuerAltNameExtension() {
        Object obj = getExtension(PKIXExtensions.IssuerAlternativeName_Id);
        return cast(IssuerAlternativeNameExtension)obj;
    }

    /**
     * return the IssuingDistributionPointExtension, if any.
     *
     * @returns IssuingDistributionPointExtension or null
     *          (if no such extension)
     * @throws IOException on error
     */
    IssuingDistributionPointExtension getIssuingDistributionPointExtension() {
        Object obj = getExtension(PKIXExtensions.IssuingDistributionPoint_Id);
        return cast(IssuingDistributionPointExtension) obj;
    }

    /**
     * Return true if a critical extension is found that is
     * not supported, otherwise return false.
     */
    bool hasUnsupportedCriticalExtension() {
        if (extensions is null)
            return false;
        return extensions.hasUnsupportedCriticalExtension();
    }

    /**
     * Gets a Set of the extension(s) marked CRITICAL in the
     * CRL. In the returned set, each extension is represented by
     * its OID string.
     *
     * @return a set of the extension oid strings in the
     * CRL that are marked critical.
     */
    Set!string getCriticalExtensionOIDs() {
        if (extensions is null) {
            return null;
        }
        Set!string extSet = new TreeSet!string();
        foreach (Extension ex ; extensions.getAllExtensions()) {
            if (ex.isCritical()) {
                extSet.add(ex.getExtensionId().toString());
            }
        }
        return extSet;
    }

    /**
     * Gets a Set of the extension(s) marked NON-CRITICAL in the
     * CRL. In the returned set, each extension is represented by
     * its OID string.
     *
     * @return a set of the extension oid strings in the
     * CRL that are NOT marked critical.
     */
    Set!string getNonCriticalExtensionOIDs() {
        if (extensions is null) {
            return null;
        }
        Set!string extSet = new TreeSet!string();
        foreach (Extension ex ; extensions.getAllExtensions()) {
            if (!ex.isCritical()) {
                extSet.add(ex.getExtensionId().toString());
            }
        }
        return extSet;
    }

    /**
     * Gets the DER encoded OCTET string for the extension value
     * (<code>extnValue</code>) identified by the passed in oid string.
     * The <code>oid</code> string is
     * represented by a set of positive whole number separated
     * by ".", that means,<br>
     * &lt;positive whole number&gt;.&lt;positive whole number&gt;.&lt;...&gt;
     *
     * @param oid the Object Identifier value for the extension.
     * @return the der encoded octet string of the extension value.
     */
    byte[] getExtensionValue(string oid) {
        if (extensions is null)
            return null;
        try {
            string extAlias = OIDMap.getName(new ObjectIdentifier(oid));
            Extension crlExt = null;

            if (extAlias is null) { // may be unknown
                ObjectIdentifier findOID = new ObjectIdentifier(oid);
                Extension ex = null;
                ObjectIdentifier inCertOID;
                for (Enumeration!Extension e = extensions.getElements();
                                                 e.hasMoreElements();) {
                    ex = e.nextElement();
                    inCertOID = ex.getExtensionId();
                    if (inCertOID.equals(cast(Object)findOID)) {
                        crlExt = ex;
                        break;
                    }
                }
            } else
                crlExt = extensions.get(extAlias);
            if (crlExt is null)
                return null;
            byte[] extData = crlExt.getExtensionValue();
            if (extData is null)
                return null;
            DerOutputStream ot = new DerOutputStream();
            ot.putOctetString(extData);
            return ot.toByteArray();
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * get an extension
     *
     * @param oid ObjectIdentifier of extension desired
     * @returns Object of type <extension> or null, if not found
     * @throws IOException on error
     */
    Object getExtension(ObjectIdentifier oid) {
        if (extensions is null)
            return null;

        // XXX Consider cloning this
        return extensions.get(OIDMap.getName(oid));
    }

    /*
     * Parses an X.509 CRL, should be used only by constructors.
     */
    private void parse(DerValue val) {
        // check if can over write the certificate
        if (readOnly)
            throw new CRLException("cannot over-write existing CRL");

        if ( val.getData() is null || val.tag != DerValue.tag_Sequence)
            throw new CRLException("Invalid DER-encoded CRL data");

        signedCRL = val.toByteArray();
        DerValue[] seq = new DerValue[3];

        seq[0] = val.data.getDerValue();
        seq[1] = val.data.getDerValue();
        seq[2] = val.data.getDerValue();

        if (val.data.available() != 0)
            throw new CRLException("signed overrun, bytes = "
                                     + val.data.available());

        if (seq[0].tag != DerValue.tag_Sequence)
            throw new CRLException("signed CRL fields invalid");

        sigAlgId = AlgorithmId.parse(seq[1]);
        signature = seq[2].getBitString();

        if (seq[1].data.available() != 0)
            throw new CRLException("AlgorithmId field overrun");

        if (seq[2].data.available() != 0)
            throw new CRLException("Signature field overrun");

        // the tbsCertsList
        tbsCertList = seq[0].toByteArray();

        // parse the information
        DerInputStream derStrm = seq[0].data;
        DerValue       tmp;
        byte           nextByte;

        // version (optional if v1)
        _version = 0;   // by default, version = v1 == 0
        nextByte = cast(byte)derStrm.peekByte();
        if (nextByte == DerValue.tag_Integer) {
            _version = derStrm.getInteger();
            if (_version != 1)  // i.e. v2
                throw new CRLException("Invalid version");
        }
        tmp = derStrm.getDerValue();

        // signature
        AlgorithmId tmpId = AlgorithmId.parse(tmp);

        // the "inner" and "outer" signature algorithms must match
        if (! tmpId.equals(sigAlgId))
            throw new CRLException("Signature algorithm mismatch");
        infoSigAlgId = tmpId;

        // issuer
        issuer = new X500Name(derStrm);
        if (issuer.isEmpty()) {
            throw new CRLException("Empty issuer DN not allowed in X509CRLs");
        }

        // thisUpdate
        // check if UTCTime encoded or GeneralizedTime

        nextByte = cast(byte)derStrm.peekByte();
        if (nextByte == DerValue.tag_UtcTime) {
            thisUpdate = derStrm.getUTCTime();
        } else if (nextByte == DerValue.tag_GeneralizedTime) {
            thisUpdate = derStrm.getGeneralizedTime();
        } else {
            throw new CRLException("Invalid encoding for thisUpdate"
                                   ~ " (tag=" ~ nextByte ~ ")");
        }

        if (derStrm.available() == 0)
           return;     // done parsing no more optional fields present

        // nextUpdate (optional)
        nextByte = cast(byte)derStrm.peekByte();
        if (nextByte == DerValue.tag_UtcTime) {
            nextUpdate = derStrm.getUTCTime();
        } else if (nextByte == DerValue.tag_GeneralizedTime) {
            nextUpdate = derStrm.getGeneralizedTime();
        } // else it is not present

        if (derStrm.available() == 0)
            return;     // done parsing no more optional fields present

        // revokedCertificates (optional)
        nextByte = cast(byte)derStrm.peekByte();
        if ((nextByte == DerValue.tag_SequenceOf)
            && (! ((nextByte & 0x0c0) == 0x080))) {
            DerValue[] badCerts = derStrm.getSequence(4);

            X500Principal crlIssuer = getIssuerX500Principal();
            X500Principal badCertIssuer = crlIssuer;
            for (int i = 0; i < badCerts.length; i++) {
                X509CRLEntryImpl entry = new X509CRLEntryImpl(badCerts[i]);
                badCertIssuer = getCertIssuer(entry, badCertIssuer);
                entry.setCertificateIssuer(crlIssuer, badCertIssuer);
                X509IssuerSerial issuerSerial = new X509IssuerSerial
                    (badCertIssuer, entry.getSerialNumber());
                revokedMap.put(issuerSerial, entry);
                revokedList.add(entry);
            }
        }

        if (derStrm.available() == 0)
            return;     // done parsing no extensions

        // crlExtensions (optional)
        tmp = derStrm.getDerValue();
        if (tmp.isConstructed() && tmp.isContextSpecific(cast(byte)0)) {
            extensions = new CRLExtensions(tmp.data);
        }
        readOnly = true;
    }

    /**
     * Extract the issuer X500Principal from an X509CRL. Parses the encoded
     * form of the CRL to preserve the principal's ASN.1 encoding.
     *
     * Called by java.security.cert.X509CRL.getIssuerX500Principal().
     */
    static X500Principal getIssuerX500Principal(X509CRL crl) {
        try {
            byte[] encoded = crl.getEncoded();
            DerInputStream derIn = new DerInputStream(encoded);
            DerValue tbsCert = derIn.getSequence(3)[0];
            DerInputStream tbsIn = tbsCert.data;

            DerValue tmp;
            // skip version number if present
            byte nextByte = cast(byte)tbsIn.peekByte();
            if (nextByte == DerValue.tag_Integer) {
                tmp = tbsIn.getDerValue();
            }

            tmp = tbsIn.getDerValue();  // skip signature
            tmp = tbsIn.getDerValue();  // issuer
            byte[] principalBytes = tmp.toByteArray();
            return new X500Principal(principalBytes);
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
    static byte[] getEncodedInternal(X509CRL crl) {
        X509CRLImpl crlImpl = cast(X509CRLImpl)crl;
        if (crlImpl is null) {
            return crl.getEncoded();
        } else {
            return crlImpl.getEncodedInternal();
        }
    }

    /**
     * Utility method to convert an arbitrary instance of X509CRL
     * to a X509CRLImpl. Does a cast if possible, otherwise reparses
     * the encoding.
     */
    static X509CRLImpl toImpl(X509CRL crl) {
        X509CRLImpl crlImpl = cast(X509CRLImpl)crl;
        if (crlImpl is null) {
            return X509Factory.intern(crl);
        } else {
            return crlImpl;
        }
    }

    /**
     * Returns the X500 certificate issuer DN of a CRL entry.
     *
     * @param entry the entry to check
     * @param prevCertIssuer the previous entry's certificate issuer
     * @return the X500Principal in a CertificateIssuerExtension, or
     *   prevCertIssuer if it does not exist
     */
    private X500Principal getCertIssuer(X509CRLEntryImpl entry,
        X500Principal prevCertIssuer) {

        CertificateIssuerExtension ciExt =
            entry.getCertificateIssuerExtension();
        if (ciExt !is null) {
            GeneralNames names = ciExt.get(CertificateIssuerExtension.ISSUER);
            X500Name issuerDN = cast(X500Name) names.get(0).getName();
            return issuerDN.asX500Principal();
        } else {
            return prevCertIssuer;
        }
    }

    override
    void derEncode(OutputStream ot) {
        if (signedCRL is null)
            throw new IOException("Null CRL to encode");
        ot.write(signedCRL.clone());
    }

    /**
     * Immutable X.509 Certificate Issuer DN and serial number pair
     */
    private final static class X509IssuerSerial : Comparable!X509IssuerSerial {
        X500Principal issuer;
        BigInteger serial;
        size_t hashcode = 0;

        /**
         * Create an X509IssuerSerial.
         *
         * @param issuer the issuer DN
         * @param serial the serial number
         */
        this(X500Principal issuer, BigInteger serial) {
            this.issuer = issuer;
            this.serial = serial;
        }

        /**
         * Construct an X509IssuerSerial from an X509Certificate.
         */
        this(X509Certificate cert) {
            this(cert.getIssuerX500Principal(), cert.getSerialNumber());
        }

        /**
         * Returns the issuer.
         *
         * @return the issuer
         */
        X500Principal getIssuer() {
            return issuer;
        }

        /**
         * Returns the serial number.
         *
         * @return the serial number
         */
        BigInteger getSerial() {
            return serial;
        }

        /**
         * Compares this X509Serial with another and returns true if they
         * are equivalent.
         *
         * @param o the other object to compare with
         * @return true if equal, false otherwise
         */
        override bool opEquals(Object o) {
            if(o is null)   return false;

            if (o is this) {
                return true;
            }

            X509IssuerSerial other = cast(X509IssuerSerial) o;
            if(other is null)  return false;

            if (serial == other.getSerial() &&
                issuer == other.getIssuer()) {
                return true;
            }
            return false;
        }

        /**
         * Returns a hash code value for this X509IssuerSerial.
         *
         * @return the hash code value
         */
        override size_t toHash() @trusted nothrow {
            if (hashcode == 0) {
                size_t result = 17;
                result = 37*result + issuer.toHash();
                result = 37*result + serial.toHash();
                hashcode = result;
            }
            return hashcode;
        }

        int compareTo(X509IssuerSerial another) {
            int cissuer =  std.algorithm.cmp(issuer.toString(), another.issuer.toString());
            if (cissuer != 0) return cissuer;
            return this.serial - another.serial;
        }
    }
}
