module hunt.security.x509.X509CRLEntryImpl;

import hunt.security.cert.CRLReason;
import hunt.security.x509.CRLExtensions;
import hunt.security.x509.Extension;
import hunt.security.x509.SerialNumber;
import hunt.security.x500.X500Principal;
import hunt.security.x509.X509CRLEntry;
import hunt.security.x509.X509Extension;

import hunt.security.util.DerEncoder;
import hunt.security.util.DerValue;
import hunt.security.util.DerOutputStream;
import hunt.security.util.ObjectIdentifier;

import hunt.util.exception;

import hunt.container;

import std.conv;
import std.datetime;


/**
 * <p>Abstract class for a revoked certificate in a CRL.
 * This class is for each entry in the <code>revokedCertificates</code>,
 * so it deals with the inner <em>SEQUENCE</em>.
 * The ASN.1 definition for this is:
 * <pre>
 * revokedCertificates    SEQUENCE OF SEQUENCE  {
 *     userCertificate    CertificateSerialNumber,
 *     revocationDate     ChoiceOfTime,
 *     crlEntryExtensions Extensions OPTIONAL
 *                        -- if present, must be v2
 * }  OPTIONAL
 *
 * CertificateSerialNumber  ::=  INTEGER
 *
 * Extensions  ::=  SEQUENCE SIZE (1..MAX) OF Extension
 *
 * Extension  ::=  SEQUENCE  {
 *     extnId        OBJECT IDENTIFIER,
 *     critical      BOOLEAN DEFAULT FALSE,
 *     extnValue     OCTET STRING
 *                   -- contains a DER encoding of a value
 *                   -- of the type registered for use with
 *                   -- the extnId object identifier value
 * }
 * </pre>
 *
 * @author Hemma Prafullchandra
 */

class X509CRLEntryImpl : X509CRLEntry {

    private SerialNumber serialNumber = null;
    private Date revocationDate;
    private CRLExtensions extensions = null;
    private byte[] revokedCert = null;
    private X500Principal certIssuer;

    private enum bool isExplicit = false;
    private enum long YR_2050 = 2524636800000L;

    /**
     * Constructs a revoked certificate entry using the given
     * serial number and revocation date.
     *
     * @param num the serial number of the revoked certificate.
     * @param date the Date on which revocation took place.
     */
    this(BigInteger num, Date date) {
        this.serialNumber = new SerialNumber(num);
        this.revocationDate = date;
    }

    /**
     * Constructs a revoked certificate entry using the given
     * serial number, revocation date and the entry
     * extensions.
     *
     * @param num the serial number of the revoked certificate.
     * @param date the Date on which revocation took place.
     * @param crlEntryExts the extensions for this entry.
     */
    this(BigInteger num, Date date,
                           CRLExtensions crlEntryExts) {
        this.serialNumber = new SerialNumber(num);
        this.revocationDate = date;
        this.extensions = crlEntryExts;
    }

    /**
     * Unmarshals a revoked certificate from its encoded form.
     *
     * @param revokedCert the encoded bytes.
     * @exception CRLException on parsing errors.
     */
    this(byte[] revokedCert)  {
        try {
            parse(new DerValue(revokedCert));
        } catch (IOException e) {
            this.revokedCert = null;
            throw new CRLException("Parsing error: " ~ e.toString());
        }
    }

    /**
     * Unmarshals a revoked certificate from its encoded form.
     *
     * @param derVal the DER value containing the revoked certificate.
     * @exception CRLException on parsing errors.
     */
    this(DerValue derValue)  {
        try {
            parse(derValue);
        } catch (IOException e) {
            revokedCert = null;
            throw new CRLException("Parsing error: " ~ e.toString());
        }
    }

    /**
     * Returns true if this revoked certificate entry has
     * extensions, otherwise false.
     *
     * @return true if this CRL entry has extensions, otherwise
     * false.
     */
    override bool hasExtensions() {
        return (extensions != null);
    }

    /**
     * Encodes the revoked certificate to an output stream.
     *
     * @param outStrm an output stream to which the encoded revoked
     * certificate is written.
     * @exception CRLException on encoding errors.
     */
    void encode(DerOutputStream outStrm)  {
        try {
            if (revokedCert is null) {
                DerOutputStream tmp = new DerOutputStream();
                // sequence { serialNumber, revocationDate, extensions }
                serialNumber.encode(tmp);

                if (revocationDate.getTime() < YR_2050) {
                    tmp.putUTCTime(revocationDate);
                } else {
                    tmp.putGeneralizedTime(revocationDate);
                }

                if (extensions != null)
                    extensions.encode(tmp, isExplicit);

                DerOutputStream seq = new DerOutputStream();
                seq.write(DerValue.tag_Sequence, tmp);

                revokedCert = seq.toByteArray();
            }
            outStrm.write(revokedCert);
        } catch (IOException e) {
             throw new CRLException("Encoding error: " ~ e.toString());
        }
    }

    /**
     * Returns the ASN.1 DER-encoded form of this CRL Entry,
     * which corresponds to the inner SEQUENCE.
     *
     * @exception CRLException if an encoding error occurs.
     */
    override byte[] getEncoded()  {
        return getEncoded0().clone();
    }

    // Called internally to avoid clone
    private byte[] getEncoded0()  {
        if (revokedCert is null)
            this.encode(new DerOutputStream());
        return revokedCert;
    }

    override
    X500Principal getCertificateIssuer() {
        return certIssuer;
    }

    void setCertificateIssuer(X500Principal crlIssuer, X500Principal certIssuer) {
        if (crlIssuer.equals(certIssuer)) {
            this.certIssuer = null;
        } else {
            this.certIssuer = certIssuer;
        }
    }

    /**
     * Gets the serial number from this X509CRLEntry,
     * i.e. the <em>userCertificate</em>.
     *
     * @return the serial number.
     */
    override BigInteger getSerialNumber() {
        return serialNumber.getNumber();
    }

    /**
     * Gets the revocation date from this X509CRLEntry,
     * the <em>revocationDate</em>.
     *
     * @return the revocation date.
     */
    override Date getRevocationDate() {
        return new Date(revocationDate.getTime());
    }

    /**
     * This method is the overridden implementation of the getRevocationReason
     * method in X509CRLEntry. It is better performance-wise since it returns
     * cached values.
     */
    override
    CRLReason getRevocationReason() {
        Extension ext = getExtension(PKIXExtensions.ReasonCode_Id);
        if (ext is null) {
            return null;
        }

        implementationMissing();
        // CRLReasonCodeExtension rcExt = cast(CRLReasonCodeExtension) ext;
        // return rcExt.getReasonCode();
    }


    /**
     * get Reason Code from CRL entry.
     *
     * @returns int or null, if no such extension
     * @throws IOException on error
     */
    int getReasonCode() {
        implementationMissing();
        // Object obj = getExtension(PKIXExtensions.ReasonCode_Id);
        // if (obj is null)
        //     return null;
        // CRLReasonCodeExtension reasonCode = cast(CRLReasonCodeExtension)obj;
        // return reasonCode.get(CRLReasonCodeExtension.REASON);
    }

    /**
     * Returns a printable string of this revoked certificate.
     *
     * @return value of this revoked certificate in a printable form.
     */
    override
    string toString() {
        StringBuilder sb = new StringBuilder();

        sb.append(serialNumber.toString());
        sb.append("  On: " ~ revocationDate.toString());
        if (certIssuer != null) {
            sb.append("\n    Certificate issuer: " ~ certIssuer);
        }
        if (extensions != null) {
            Extension[] exts = extensions.getAllExtensions();

            sb.append("\n    CRL Entry Extensions: " ~ exts.length);
            for (size_t i = 0; i < exts.length; i++) {
                sb.append("\n    [" ~ (i+1).to!string() ~ "]: ");
                Extension ext = exts[i];
                try {
                    if (OIDMap.getClass(ext.getExtensionId()) is null) {
                        sb.append(ext.toString());
                        byte[] extValue = ext.getExtensionValue();
                        if (extValue != null) {
                            DerOutputStream stream = new DerOutputStream();
                            stream.putOctetString(extValue);
                            extValue = stream.toByteArray();
                            HexDumpEncoder enc = new HexDumpEncoder();
                            sb.append("Extension unknown: "
                                      ~ "DER encoded OCTET string =\n"
                                      + enc.encodeBuffer(extValue) ~ "\n");
                        }
                    } else
                        sb.append(ext.toString()); //sub-class exists
                } catch (Exception e) {
                    sb.append(", Error parsing this extension");
                }
            }
        }
        sb.append("\n");
        return sb.toString();
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
     * Gets a Set of the extension(s) marked CRITICAL in this
     * X509CRLEntry.  In the returned set, each extension is
     * represented by its OID string.
     *
     * @return a set of the extension oid strings in the
     * Object that are marked critical.
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
     * Gets a Set of the extension(s) marked NON-CRITICAL in this
     * X509CRLEntry. In the returned set, each extension is
     * represented by its OID string.
     *
     * @return a set of the extension oid strings in the
     * Object that are marked critical.
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
     * (<em>extnValue</em>) identified by the passed in oid string.
     * The <code>oid</code> string is
     * represented by a set of positive whole number separated
     * by ".", that means,<br>
     * &lt;positive whole number&gt;.&lt;positive whole number&gt;.&lt;positive
     * whole number&gt;.&lt;...&gt;
     *
     * @param oid the Object Identifier value for the extension.
     * @return the DER encoded octet string of the extension value.
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
                    if (inCertOID.opEquals(cast(Object)findOID)) {
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

            DerOutputStream stream = new DerOutputStream();
            stream.putOctetString(extData);
            return stream.toByteArray();
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * get an extension
     *
     * @param oid ObjectIdentifier of extension desired
     * @returns Extension of type <extension> or null, if not found
     */
    Extension getExtension(ObjectIdentifier oid) {
        if (extensions is null)
            return null;

        // following returns null if no such OID in map
        //XXX consider cloning this
        return extensions.get(OIDMap.getName(oid));
    }

    private void parse(DerValue derVal) {

        if (derVal.tag != DerValue.tag_Sequence) {
            throw new CRLException("Invalid encoded RevokedCertificate, " ~
                                  "starting sequence tag missing.");
        }
        if (derVal.data.available() == 0)
            throw new CRLException("No data encoded for RevokedCertificates");

        revokedCert = derVal.toByteArray();
        // serial number
        DerInputStream stream = derVal.toDerInputStream();
        DerValue val = stream.getDerValue();
        this.serialNumber = new SerialNumber(val);

        // revocationDate
        int nextByte = derVal.data.peekByte();
        if (cast(byte)nextByte == DerValue.tag_UtcTime) {
            this.revocationDate = derVal.data.getUTCTime();
        } else if (cast(byte)nextByte == DerValue.tag_GeneralizedTime) {
            this.revocationDate = derVal.data.getGeneralizedTime();
        } else
            throw new CRLException("Invalid encoding for revocation date");

        if (derVal.data.available() == 0)
            return;  // no extensions

        // crlEntryExtensions
        this.extensions = new CRLExtensions(derVal.toDerInputStream());
    }

    /**
     * Utility method to convert an arbitrary instance of X509CRLEntry
     * to a X509CRLEntryImpl. Does a cast if possible, otherwise reparses
     * the encoding.
     */
    static X509CRLEntryImpl toImpl(X509CRLEntry entry)
             {
        X509CRLEntryImpl impl = cast(X509CRLEntryImpl)entry;
        if (impl !is null) {
            return impl;
        } else {
            return new X509CRLEntryImpl(entry.getEncoded());
        }
    }

    /**
     * Returns the CertificateIssuerExtension
     *
     * @return the CertificateIssuerExtension, or null if it does not exist
     */
    // CertificateIssuerExtension getCertificateIssuerExtension() {
    //     return cast(CertificateIssuerExtension)
    //         getExtension(PKIXExtensions.CertificateIssuer_Id);
    // }

    /**
     * Returns all extensions for this entry in a map
     * @return the extension map, can be empty, but not null
     */
    // Map!(string, CertExtension) getExtensions() {
    //     if (extensions is null) {
    //         return Collections.emptyMap!(string, CertExtension)();
    //     }
    //     Extension[] exts = extensions.getAllExtensions();
    //     Map!(string, CertExtension) map = new TreeMap!(string, CertExtension)();
    //     foreach (Extension ext ; exts) {
    //         map.put(ext.getId(), ext);
    //     }
    //     return map;
    // }

    // override
    int compareTo(X509CRLEntryImpl that) {
        int compSerial = getSerialNumber().compareTo(that.getSerialNumber());
        if (compSerial != 0) {
            return compSerial;
        }
        try {
            byte[] thisEncoded = this.getEncoded0();
            byte[] thatEncoded = that.getEncoded0();
            for (int i=0; i<thisEncoded.length && i<thatEncoded.length; i++) {
                int a = thisEncoded[i] & 0xff;
                int b = thatEncoded[i] & 0xff;
                if (a != b) return a-b;
            }
            return thisEncoded.length -thatEncoded.length;
        } catch (CRLException ce) {
            return -1;
        }
    }
}
