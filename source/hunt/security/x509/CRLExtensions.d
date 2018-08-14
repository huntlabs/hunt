module hunt.security.x509.CRLExtensions;


import hunt.security.util.DerInputStream;
import hunt.security.util.DerOutputStream;
import hunt.security.util.DerValue;
import hunt.security.x509.CertAttrSet;
import hunt.security.x509.Extension;

import hunt.io.common;

import hunt.container;
import hunt.util.exception;

/**
 * This class defines the CRL Extensions.
 * It is used for both CRL Extensions and CRL Entry Extensions,
 * which are defined are follows:
 * <pre>
 * TBSCertList  ::=  SEQUENCE  {
 *    version              Version OPTIONAL,   -- if present, must be v2
 *    signature            AlgorithmIdentifier,
 *    issuer               Name,
 *    thisUpdate           Time,
 *    nextUpdate           Time  OPTIONAL,
 *    revokedCertificates  SEQUENCE OF SEQUENCE  {
 *        userCertificate         CertificateSerialNumber,
 *        revocationDate          Time,
 *        crlEntryExtensions      Extensions OPTIONAL  -- if present, must be v2
 *    }  OPTIONAL,
 *    crlExtensions        [0] EXPLICIT Extensions OPTIONAL  -- if present, must be v2
 * }
 * </pre>
 *
 * @author Hemma Prafullchandra
 */
class CRLExtensions {

    private Map!(string,Extension) map;
    private bool unsupportedCritExt = false;

    /**
     * Default constructor.
     */
    this() { 
        map = new TreeMap!(string,Extension)();
        // map = Collections.synchronizedMap(
        //     new TreeMap!(string,Extension)());
    }

    /**
     * Create the object, decoding the values from the passed DER stream.
     *
     * @param in the DerInputStream to read the Extension from, i.e. the
     *        sequence of extensions.
     * @exception CRLException on decoding errors.
     */
    this(DerInputStream inputStream) {
        this();
        init(inputStream);
    }

    // helper routine
    private void init(DerInputStream derStrm) {
        try {
            DerInputStream str = derStrm;

            byte nextByte = cast(byte)derStrm.peekByte();
            // check for context specific byte 0; skip it
            if (((nextByte & 0x0c0) == 0x080) &&
                ((nextByte & 0x01f) == 0x000)) {
                DerValue val = str.getDerValue();
                str = val.data;
            }

            DerValue[] exts = str.getSequence(5);
            for (int i = 0; i < exts.length; i++) {
                Extension ext = new Extension(exts[i]);
                parseExtension(ext);
            }
        } catch (IOException e) {
            throw new CRLException("Parsing error: " ~ e.toString());
        }
    }

    // private static final Class[] PARAMS = {Boolean.class, Object.class};

    // Parse the encoded extension
    private void parseExtension(Extension ext) {
        implementationMissing();
        // try {
        //     Class<?> extClass = OIDMap.getClass(ext.getExtensionId());
        //     if (extClass is null) {   // Unsupported extension
        //         if (ext.isCritical())
        //             unsupportedCritExt = true;
        //         if (map.put(ext.getExtensionId().toString(), ext) !is null)
        //             throw new CRLException("Duplicate extensions not allowed");
        //         return;
        //     }
        //     Constructor<?> cons = extClass.getConstructor(PARAMS);
        //     Object[] passed = new Object[] {Boolean.valueOf(ext.isCritical()),
        //                                     ext.getExtensionValue()};
        //     CertAttrSet<?> crlExt = (CertAttrSet<?>)cons.newInstance(passed);
        //     if (map.put(crlExt.getName(), (Extension)crlExt) !is null) {
        //         throw new CRLException("Duplicate extensions not allowed");
        //     }
        // } catch (InvocationTargetException invk) {
        //     throw new CRLException(invk.getTargetException().getMessage());
        // } catch (Exception e) {
        //     throw new CRLException(e.toString());
        // }
    }

    /**
     * Encode the extensions in DER form to the stream.
     *
     * @param stream the DerOutputStream to marshal the contents to.
     * @param isExplicit the tag indicating whether this is an entry
     * extension (false) or a CRL extension (true).
     * @exception CRLException on encoding errors.
     */
    void encode(OutputStream stream, bool isExplicit)
    {
        implementationMissing();
        // try {
        //     DerOutputStream extOut = new DerOutputStream();
        //     Collection<Extension> allExts = map.values();
        //     Object[] objs = allExts.toArray();

        //     for (int i = 0; i < objs.length; i++) {
        //         if (objs[i] instanceof CertAttrSet)
        //             ((CertAttrSet)objs[i]).encode(extOut);
        //         else if (objs[i] instanceof Extension)
        //             ((Extension)objs[i]).encode(extOut);
        //         else
        //             throw new CRLException("Illegal extension object");
        //     }

        //     DerOutputStream seq = new DerOutputStream();
        //     seq.write(DerValue.tag_Sequence, extOut);

        //     DerOutputStream tmp = new DerOutputStream();
        //     if (isExplicit)
        //         tmp.write(DerValue.createTag(DerValue.TAG_CONTEXT,
        //                                      true, cast(byte)0), seq);
        //     else
        //         tmp = seq;

        //     stream.write(tmp.toByteArray());
        // } catch (IOException e) {
        //     throw new CRLException("Encoding error: " ~ e.toString());
        // } catch (CertificateException e) {
        //     throw new CRLException("Encoding error: " ~ e.toString());
        // }
    }

    /**
     * Get the extension with this as.
     *
     * @param as the identifier string for the extension to retrieve.
     */
    Extension get(string as) {
        X509AttributeName attr = new X509AttributeName(as);
        string name;
        string id = attr.getPrefix();
        if (id.equalsIgnoreCase(X509CertImpl.NAME)) { // fully qualified
            int index = as.lastIndexOf(".");
            name = as.substring(index + 1);
        } else
            name = as;
        return map.get(name);
    }

    /**
     * Set the extension value with this as.
     *
     * @param as the identifier string for the extension to set.
     * @param obj the Object to set the extension identified by the
     *        as.
     */
    void set(string as, Object obj) {
        map.put(as, cast(Extension)obj);
    }

    /**
     * Delete the extension value with this as.
     *
     * @param as the identifier string for the extension to delete.
     */
    void remove(string as) {
        map.remove(as);
    }

    /**
     * Return an enumeration of the extensions.
     * @return an enumeration of the extensions in this CRL.
     */
    Enumeration!Extension getElements() {
        return Collections.enumeration(map.values());
    }

    /**
     * Return a collection view of the extensions.
     * @return a collection view of the extensions in this CRL.
     */
    Extension[] getAllExtensions() {
        return map.values();
    }

    /**
     * Return true if a critical extension is found that is
     * not supported, otherwise return false.
     */
    bool hasUnsupportedCriticalExtension() {
        return unsupportedCritExt;
    }

    /**
     * Compares this CRLExtensions for equality with the specified
     * object. If the <code>other</code> object is an
     * <code>instanceof</code> <code>CRLExtensions</code>, then
     * all the entries are compared with the entries from this.
     *
     * @param other the object to test for equality with this CRLExtensions.
     * @return true iff all the entries match that of the Other,
     * false otherwise.
     */
    override bool opEquals(Object other) {
        if (this is other)
            return true;
        CRLExtensions crlExtensions = cast(CRLExtensions)other;
        if (crlExtensions is null)
            return false;
        // Collection<Extension> otherC =
        //                 ((CRLExtensions)other).getAllExtensions();
        Extension[] objs = crlExtensions.getAllExtensions();

        size_t len = objs.length;
        if (len != map.size())
            return false;

        Extension otherExt, thisExt;
        string key = null;
        for (int i = 0; i < len; i++) {
            CertAttrSet certAttrSet = cast(CertAttrSet)objs[i];
            if (certAttrSet !is null)
                key = certAttrSet.getName();
            otherExt = objs[i];
            if (key is null)
                key = otherExt.getExtensionId().toString();
            thisExt = map.get(key);
            if (thisExt is null)
                return false;
            if (! thisExt.opEquals(otherExt))
                return false;
        }
        return true;
    }

    /**
     * Returns a hashcode value for this CRLExtensions.
     *
     * @return the hashcode value.
     */
    int hashCode() {
        return map.hashCode();
    }

    /**
     * Returns a string representation of this <tt>CRLExtensions</tt> object
     * in the form of a set of entries, enclosed in braces and separated
     * by the ASCII characters "<tt>,&nbsp;</tt>" (comma and space).
     * <p>Overrides to <tt>toString</tt> method of <tt>Object</tt>.
     *
     * @return  a string representation of this CRLExtensions.
     */
    override string toString() {
        return map.toString();
    }
}