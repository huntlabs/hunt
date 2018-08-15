module hunt.security.x509.CertificateExtensions;

import hunt.security.x509.AlgorithmId;
import hunt.security.x509.CertAttrSet;

import hunt.security.x509.Extension;

// import hunt.security.cert.Extension;

import hunt.security.util.DerValue;
import hunt.security.util.DerInputStream;
import hunt.security.util.DerOutputStream;
import hunt.security.util.ObjectIdentifier;

import hunt.container;
import hunt.util.exception;
import hunt.io.common;

/**
 * This class defines the Extensions attribute for the Certificate.
 *
 * @author Amit Kapoor
 * @author Hemma Prafullchandra
 * @see CertAttrSet
 */
class CertificateExtensions : CertAttrSet!(Extension, Extension)  {
    /**
     * Identifier for this attribute, to be used with the
     * get, set, delete methods of Certificate, x509 type.
     */
    enum string IDENT = "x509.info.extensions";
    /**
     * name
     */
    enum string NAME = "extensions";

    // private enum Debug debug = Debug.getInstance("x509");

    private Map!(string,Extension) map;
    private bool unsupportedCritExt = false;

    private Map!(string,Extension) unparseableExtensions;

    /**
     * Default constructor.
     */
    this() {
        map = new TreeMap!(string,Extension)();
     }

    /**
     * Create the object, decoding the values from the passed DER stream.
     *
     * @param stream the DerInputStream to read the Extension from.
     * @exception IOException on decoding errors.
     */
    this(DerInputStream stream) {
        this();
        init(stream);
    }

    // helper routine
    private void init(DerInputStream stream) {

        DerValue[] exts = stream.getSequence(5);

        for (int i = 0; i < exts.length; i++) {
            Extension ext = new Extension(exts[i]);
            parseExtension(ext);
        }
    }

    // private static Class[] PARAMS = {Boolean.class, Object.class};

    // Parse the encoded extension
    private void parseExtension(Extension ext) {
        // try {
        //     Class<?> extClass = OIDMap.getClass(ext.getExtensionId());
        //     if (extClass is null) {   // Unsupported extension
        //         if (ext.isCritical()) {
        //             unsupportedCritExt = true;
        //         }
        //         if (map.put(ext.getExtensionId().toString(), ext) is null) {
        //             return;
        //         } else {
        //             throw new IOException("Duplicate extensions not allowed");
        //         }
        //     }
        //     Constructor<?> cons = extClass.getConstructor(PARAMS);

        //     Object[] passed = new Object[] {Boolean.valueOf(ext.isCritical()),
        //             ext.getExtensionValue()};
        //             CertAttrSet<?> certExt = (CertAttrSet<?>)
        //                     cons.newInstance(passed);
        //             if (map.put(certExt.getName(), (Extension)certExt) != null) {
        //                 throw new IOException("Duplicate extensions not allowed");
        //             }
        // } catch (InvocationTargetException invk) {
        //     Throwable e = invk.getTargetException();
        //     if (ext.isCritical() == false) {
        //         // ignore errors parsing non-critical extensions
        //         if (unparseableExtensions is null) {
        //             unparseableExtensions = new TreeMap!(string,Extension)();
        //         }
        //         unparseableExtensions.put(ext.getExtensionId().toString(),
        //                 new UnparseableExtension(ext, e));
        //         if (debug != null) {
        //             debug.println("Error parsing extension: " ~ ext);
        //             e.printStackTrace();
        //             HexDumpEncoder h = new HexDumpEncoder();
        //             System.err.println(h.encodeBuffer(ext.getExtensionValue()));
        //         }
        //         return;
        //     }
        //     if (e instanceof IOException) {
        //         throw (IOException)e;
        //     } else {
        //         throw new IOException(e);
        //     }
        // } catch (IOException e) {
        //     throw e;
        // } catch (Exception e) {
        //     throw new IOException(e);
        // }

        implementationMissing();
    }

    /**
     * Encode the extensions in DER form to the stream, setting
     * the context specific tag as needed in the X.509 v3 certificate.
     *
     * @param stream the DerOutputStream to marshal the contents to.
     * @exception CertificateException on encoding errors.
     * @exception IOException on errors.
     */
    void encode(OutputStream stream) {
        encode(stream, false);
    }

    /**
     * Encode the extensions in DER form to the stream.
     *
     * @param stream the DerOutputStream to marshal the contents to.
     * @param isCertReq if true then no context specific tag is added.
     * @exception CertificateException on encoding errors.
     * @exception IOException on errors.
     */
    void encode(OutputStream stream, bool isCertReq) {
        implementationMissing();
        // DerOutputStream extOut = new DerOutputStream();
        // Collection<Extension> allExts = map.values();
        // Object[] objs = allExts.toArray();

        // for (int i = 0; i < objs.length; i++) {
        //     if (objs[i] instanceof CertAttrSet)
        //         ((CertAttrSet)objs[i]).encode(extOut);
        //     else if (objs[i] instanceof Extension)
        //         ((Extension)objs[i]).encode(extOut);
        //     else
        //         throw new CertificateException("Illegal extension object");
        // }

        // DerOutputStream seq = new DerOutputStream();
        // seq.write(DerValue.tag_Sequence, extOut);

        // DerOutputStream tmp;
        // if (!isCertReq) { // certificate
        //     tmp = new DerOutputStream();
        //     tmp.write(DerValue.createTag(DerValue.TAG_CONTEXT, true, (byte)3),
        //             seq);
        // } else
        //     tmp = seq; // pkcs#10 certificateRequest

        // stream.write(tmp.toByteArray());
    }

    /**
     * Set the attribute value.
     * @param name the extension name used in the cache.
     * @param obj the object to set.
     * @exception IOException if the object could not be cached.
     */
    void set(string name, Extension obj) {
        if (obj !is null) {
            map.put(name, obj);
        } else {
            throw new IOException("Unknown extension type.");
        }
    }

    /**
     * Get the attribute value.
     * @param name the extension name used in the lookup.
     * @exception IOException if named extension is not found.
     */
    Extension get(string name) {
        Extension obj = map.get(name);
        if (obj is null) {
            throw new IOException("No extension found with name " ~ name);
        }
        return (obj);
    }

    // Similar to get(string), but throw no exception, might return null.
    // Used in X509CertImpl::getExtension(OID).
    Extension getExtension(string name) {
        return map.get(name);
    }

    /**
     * Delete the attribute value.
     * @param name the extension name used in the lookup.
     * @exception IOException if named extension is not found.
     */
    void remove(string name) {
        Object obj = map.get(name);
        if (obj is null) {
            throw new IOException("No extension found with name " ~ name);
        }
        map.remove(name);
    }

    string getNameByOid(ObjectIdentifier oid) {
        // for (string name: map.keySet()) {
        foreach (string name; map.byKey()) {
            if (map.get(name).getExtensionId().opEquals(cast(Object)oid)) {
                return name;
            }
        }
        return null;
    }

    /**
     * Return an enumeration of names of attributes existing within this
     * attribute.
     */
    Enumeration!Extension getElements() {
        // return Collections.enumeration(map.values());
                implementationMissing();
        return null;

    }

    /**
     * Return a collection view of the extensions.
     * @return a collection view of the extensions in this Certificate.
     */
    Extension[] getAllExtensions() {
        // return map.values();
                implementationMissing();
        return null;

    }

    Map!(string,Extension) getUnparseableExtensions() {
        if (unparseableExtensions is null) {
            return Collections.emptyMap!(string,Extension)();
        } else {
            return unparseableExtensions;
        }
    }

    /**
     * Return the name of this attribute.
     */
    string getName() {
        return NAME;
    }

    /**
     * Return true if a critical extension is found that is
     * not supported, otherwise return false.
     */
    bool hasUnsupportedCriticalExtension() {
        return unsupportedCritExt;
    }

    /**
     * Compares this CertificateExtensions for equality with the specified
     * object. If the <code>other</code> object is an
     * <code>instanceof</code> <code>CertificateExtensions</code>, then
     * all the entries are compared with the entries from this.
     *
     * @param other the object to test for equality with this
     * CertificateExtensions.
     * @return true iff all the entries match that of the Other,
     * false otherwise.
     */
    override bool opEquals(Object other) {
        if (this is other)
            return true;
        CertificateExtensions otherC = cast(CertificateExtensions)other;
        if (otherC is null)
            return false;
            
        Extension[] objs = otherC.getAllExtensions();

        size_t len = objs.length;
        if (len != map.size())
            return false;

        Extension otherExt, thisExt;
        string key = null;
        for (size_t i = 0; i < len; i++) {
            implementationMissing();
            // CertAttrSet!string cert = cast(CertAttrSet!string)objs[i];
            // if (cert !is null)
            //     key = cert.getName();
            // otherExt = objs[i];
            // if (key is null)
            //     key = otherExt.getExtensionId().toString();
            // thisExt = map.get(key);
            // if (thisExt is null)
            //     return false;
            // if (! thisExt.opEquals(otherExt))
            //     return false;
        }
        return this.getUnparseableExtensions().opEquals(cast(Object)(
                (cast(CertificateExtensions)other).getUnparseableExtensions()));
    }

    /**
     * Returns a hashcode value for this CertificateExtensions.
     *
     * @return the hashcode value.
     */
    override size_t toHash() @trusted nothrow {
        try {
            return map.toHash() + getUnparseableExtensions().toHash();
        }
        catch(Exception)
        {
            return 0;
        }
    }

    /**
     * Returns a string representation of this <tt>CertificateExtensions</tt>
     * object in the form of a set of entries, enclosed in braces and separated
     * by the ASCII characters "<tt>,&nbsp;</tt>" (comma and space).
     * <p>Overrides to <tt>toString</tt> method of <tt>Object</tt>.
     *
     * @return  a string representation of this CertificateExtensions.
     */
    override string toString() {
        return map.toString();
    }

}


/**
*/
class UnparseableExtension : Extension {
    private string name;
    private Throwable why;

    this(Extension ext, Throwable why) {
        super(ext);

        name = "";
        // try {
        //     Class<?> extClass = OIDMap.getClass(ext.getExtensionId());
        //     if (extClass != null) {
        //         Field field = extClass.getDeclaredField("NAME");
        //         name = (string)(field.get(null)) ~ " ";
        //     }
        // } catch (Exception e) {
        //     // If we cannot find the name, just ignore it
        // }

        this.why = why;
    }

    override string toString() {
        return super.toString() ~
                "Unparseable " ~ name ~ "extension due to\n" ~ why.toString() ~ "\n\n"; // ~
                // new sun.misc.HexDumpEncoder().encodeBuffer(getExtensionValue());
    }
}
