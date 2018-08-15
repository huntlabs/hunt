module hunt.security.x509.X509Key;

import hunt.security.x509.AlgorithmId;

import hunt.security.key;
import hunt.security.Provider;

import hunt.security.util.DerValue;
import hunt.security.util.DerOutputStream;
// import hunt.security.InvalidKeyException;
// import hunt.security.NoSuchAlgorithmException;
// import hunt.security.spec.InvalidKeySpecException;
// import hunt.security.spec.X509EncodedKeySpec;

import hunt.util.exception;

import std.bitmanip;

/**
 * Holds an X.509 key, for example a key found in an X.509
 * certificate.  Includes a description of the algorithm to be used
 * with the key; these keys normally are used as
 * "SubjectPublicKeyInfo".
 *
 * <P>While this class can represent any kind of X.509 key, it may be
 * desirable to provide subclasses which understand how to parse keying
 * data.   For example, RSA keys have two members, one for the
 * modulus and one for the prime exponent.  If such a class is
 * provided, it is used when parsing X.509 keys.  If one is not provided,
 * the key still parses correctly.
 *
 * @author David Brownell
 */
class X509Key : PublicKey {

    /** use serialVersionUID from JDK 1.1. for interoperability */
    // private static final long serialVersionUID = -5359250853002055002L;

    /* The algorithm information (name, parameters, etc). */
    protected AlgorithmId algid;

    // /**
    //  * The key bytes, without the algorithm information.
    //  * @deprecated Use the BitArray form which does not require keys to
    //  * be byte aligned.
    //  * @see sun.security.x509.X509Key#setKey(BitArray)
    //  * @see sun.security.x509.X509Key#getKey()
    //  */
    // @Deprecated
    // protected byte[] key = null;

    // /*
    //  * The number of bits unused in the last byte of the key.
    //  * Added to keep the byte[] key form consistent with the BitArray
    //  * form. Can de deleted when byte[] key is deleted.
    //  */
    // @Deprecated
    // private int unusedBits = 0;

    // /* BitArray form of key */
    // private BitArray bitStringKey = null;

    /* The encoding for the key. */
    protected byte[] encodedKey;

    // /**
    //  * Default constructor.  The key constructed must have its key
    //  * and algorithm initialized before it may be used, for example
    //  * by using <code>decode</code>.
    //  */
    // this() { }

    // /*
    //  * Build and initialize as a "default" key.  All X.509 key
    //  * data is stored and transmitted losslessly, but no knowledge
    //  * about this particular algorithm is available.
    //  */
    // private this(AlgorithmId algid, BitArray key)
    // {
    //     this.algid = algid;
    //     setKey(key);
    //     encode();
    // }

    // /**
    //  * Sets the key in the BitArray form.
    //  */
    // protected void setKey(BitArray key) {
    //     this.bitStringKey = (BitArray)key.clone();

    //     /*
    //      * Do this to keep the byte array form consistent with
    //      * this. Can delete when byte[] key is deleted.
    //      */
    //     this.key = key.toByteArray();
    //     int remaining = key.length() % 8;
    //     this.unusedBits =
    //         ((remaining == 0) ? 0 : 8 - remaining);
    // }

    /**
     * Gets the key. The key may or may not be byte aligned.
     * @return a BitArray containing the key.
     */
    protected BitArray getKey() {
        /*
         * Do this for consistency in case a subclass
         * modifies byte[] key directly. Remove when
         * byte[] key is deleted.
         * Note: the consistency checks fail when the subclass
         * modifies a non byte-aligned key (into a byte-aligned key)
         * using the deprecated byte[] key field.
         */
        // this.bitStringKey = new BitArray(
        //                   this.key.length * 8 - this.unusedBits,
        //                   this.key);

        // return (BitArray)bitStringKey.clone();
implementationMissing();
        return BitArray.init;
    }

    /**
     * Construct X.509 subject key from a DER value.  If
     * the runtime environment is configured with a specific class for
     * this kind of key, a subclass is returned.  Otherwise, a generic
     * X509Key object is returned.
     *
     * <P>This mechanism gurantees that keys (and algorithms) may be
     * freely manipulated and transferred, without risk of losing
     * information.  Also, when a key (or algorithm) needs some special
     * handling, that specific need can be accomodated.
     *
     * @param in the DER-encoded SubjectPublicKeyInfo value
     * @exception IOException on data format errors
     */
    static PublicKey parse(DerValue value)
    {
        AlgorithmId     algorithm;
        PublicKey       subjectKey;

        // if (value.tag != DerValue.tag_Sequence)
        //     throw new IOException("corrupt subject key");

        // algorithm = AlgorithmId.parse(value.data.getDerValue());
        // try {
        //     subjectKey = buildX509Key(algorithm,
        //                               value.data.getUnalignedBitString());

        // } catch (InvalidKeyException e) {
        //     throw new IOException("subject key, " ~ e.msg, e);
        // }

        // if (value.data.available() != 0)
        //     throw new IOException("excess subject key");
        implementationMissing();
        return subjectKey;
    }

    // /**
    //  * Parse the key bits.  This may be redefined by subclasses to take
    //  * advantage of structure within the key.  For example, RSA public
    //  * keys encapsulate two unsigned integers (modulus and exponent) as
    //  * DER values within the <code>key</code> bits; Diffie-Hellman and
    //  * DSS/DSA keys encapsulate a single unsigned integer.
    //  *
    //  * <P>This function is called when creating X.509 SubjectPublicKeyInfo
    //  * values using the X509Key member functions, such as <code>parse</code>
    //  * and <code>decode</code>.
    //  *
    //  * @exception IOException on parsing errors.
    //  * @exception InvalidKeyException on invalid key encodings.
    //  */
    // protected void parseKeyBits(), InvalidKeyException {
    //     encode();
    // }

    // /*
    //  * Factory interface, building the kind of key associated with this
    //  * specific algorithm ID or else returning this generic base class.
    //  * See the description above.
    //  */
    // static PublicKey buildX509Key(AlgorithmId algid, BitArray key)
    //  , InvalidKeyException
    // {
    //     /*
    //      * Use the algid and key parameters to produce the ASN.1 encoding
    //      * of the key, which will then be used as the input to the
    //      * key factory.
    //      */
    //     DerOutputStream x509EncodedKeyStream = new DerOutputStream();
    //     encode(x509EncodedKeyStream, algid, key);
    //     X509EncodedKeySpec x509KeySpec
    //         = new X509EncodedKeySpec(x509EncodedKeyStream.toByteArray());

    //     try {
    //         // Instantiate the key factory of the appropriate algorithm
    //         KeyFactory keyFac = KeyFactory.getInstance(algid.getName());

    //         // Generate the key
    //         return keyFac.generatePublic(x509KeySpec);
    //     } catch (NoSuchAlgorithmException e) {
    //         // Return generic X509Key with opaque key data (see below)
    //     } catch (InvalidKeySpecException e) {
    //         throw new InvalidKeyException(e.msg, e);
    //     }

    //     /*
    //      * Try again using JDK1.1-style for backwards compatibility.
    //      */
    //     string classname = "";
    //     try {
    //         Properties props;
    //         string keytype;
    //         Provider sunProvider;

    //         sunProvider = Security.getProvider("SUN");
    //         if (sunProvider == null)
    //             throw new InstantiationException();
    //         classname = sunProvider.getProperty("PublicKey.X.509." ~
    //           algid.getName());
    //         if (classname == null) {
    //             throw new InstantiationException();
    //         }

    //         Class<?> keyClass = null;
    //         try {
    //             keyClass = Class.forName(classname);
    //         } catch (ClassNotFoundException e) {
    //             ClassLoader cl = ClassLoader.getSystemClassLoader();
    //             if (cl != null) {
    //                 keyClass = cl.loadClass(classname);
    //             }
    //         }

    //         @SuppressWarnings("deprecation")
    //         Object      inst = (keyClass != null) ? keyClass.newInstance() : null;
    //         X509Key     result;

    //         if (inst instanceof X509Key) {
    //             result = (X509Key) inst;
    //             result.algid = algid;
    //             result.setKey(key);
    //             result.parseKeyBits();
    //             return result;
    //         }
    //     } catch (ClassNotFoundException e) {
    //     } catch (InstantiationException e) {
    //     } catch (IllegalAccessException e) {
    //         // this should not happen.
    //         throw new IOException (classname + " [internal error]");
    //     }

    //     X509Key result = new X509Key(algid, key);
    //     return result;
    // }

    /**
     * Returns the algorithm to be used with this key.
     */
    string getAlgorithm() {
        return algid.getName();
    }

    /**
     * Returns the algorithm ID to be used with this key.
     */
    AlgorithmId  getAlgorithmId() { return algid; }

    /**
     * Encode SubjectPublicKeyInfo sequence on the DER output stream.
     *
     * @exception IOException on encoding errors.
     */
    final void encode(DerOutputStream stream)
    {
        encode(stream, this.algid, getKey());
    }

    /**
     * Returns the DER-encoded form of the key as a byte array.
     */
    byte[] getEncoded() {
        try {
            return getEncodedInternal().dup;
        } catch (InvalidKeyException e) {
            // XXX
        }
        return null;
    }

    byte[] getEncodedInternal() {
        byte[] encoded = encodedKey;
        if (encoded == null) {
            try {
                DerOutputStream stream = new DerOutputStream();
                encode(stream);
                encoded = stream.toByteArray();
            } catch (IOException e) {
                throw new InvalidKeyException("IOException : " ~
                                               e.msg);
            }
            encodedKey = encoded;
        }
        return encoded;
    }

    /**
     * Returns the format for this key: "X.509"
     */
    string getFormat() {
        return "X.509";
    }

    /**
     * Returns the DER-encoded form of the key as a byte array.
     *
     * @exception InvalidKeyException on encoding errors.
     */
    byte[] encode() {
        return getEncodedInternal().dup;
    }

    /*
     * Returns a printable representation of the key
     */
    // string toString()
    // {
    //     HexDumpEncoder  encoder = new HexDumpEncoder();

    //     return "algorithm = " ~ algid.toString()
    //         + ", unparsed keybits = \n" ~ encoder.encodeBuffer(key);
    // }

    // /**
    //  * Initialize an X509Key object from an input stream.  The data on that
    //  * input stream must be encoded using DER, obeying the X.509
    //  * <code>SubjectPublicKeyInfo</code> format.  That is, the data is a
    //  * sequence consisting of an algorithm ID and a bit string which holds
    //  * the key.  (That bit string is often used to encapsulate another DER
    //  * encoded sequence.)
    //  *
    //  * <P>Subclasses should not normally redefine this method; they should
    //  * instead provide a <code>parseKeyBits</code> method to parse any
    //  * fields inside the <code>key</code> member.
    //  *
    //  * <P>The exception to this rule is that since private keys need not
    //  * be encoded using the X.509 <code>SubjectPublicKeyInfo</code> format,
    //  * private keys may override this method, <code>encode</code>, and
    //  * of course <code>getFormat</code>.
    //  *
    //  * @param in an input stream with a DER-encoded X.509
    //  *          SubjectPublicKeyInfo value
    //  * @exception InvalidKeyException on parsing errors.
    //  */
    // void decode(InputStream in)
    //
    // {
    //     DerValue        val;

    //     try {
    //         val = new DerValue(in);
    //         if (val.tag != DerValue.tag_Sequence)
    //             throw new InvalidKeyException("invalid key format");

    //         algid = AlgorithmId.parse(val.data.getDerValue());
    //         setKey(val.data.getUnalignedBitString());
    //         parseKeyBits();
    //         if (val.data.available() != 0)
    //             throw new InvalidKeyException ("excess key data");

    //     } catch (IOException e) {
    //         throw new InvalidKeyException("IOException: " ~
    //                                       e.msg);
    //     }
    // }

    // void decode(byte[] encodedKey) {
    //     decode(new ByteArrayInputStream(encodedKey));
    // }

    // /**
    //  * Serialization write ... X.509 keys serialize as
    //  * themselves, and they're parsed when they get read back.
    //  */
    // private void writeObject(ObjectOutputStream stream) {
    //     stream.write(getEncoded());
    // }

    // /**
    //  * Serialization read ... X.509 keys serialize as
    //  * themselves, and they're parsed when they get read back.
    //  */
    // private void readObject(ObjectInputStream stream) {
    //     try {
    //         decode(stream);
    //     } catch (InvalidKeyException e) {
    //         e.printStackTrace();
    //         throw new IOException("deserialized key is invalid: " ~
    //                               e.msg);
    //     }
    // }

    // boolean equals(Object obj) {
    //     if (this == obj) {
    //         return true;
    //     }
    //     if (obj instanceof Key == false) {
    //         return false;
    //     }
    //     try {
    //         byte[] thisEncoded = this.getEncodedInternal();
    //         byte[] otherEncoded;
    //         if (obj instanceof X509Key) {
    //             otherEncoded = ((X509Key)obj).getEncodedInternal();
    //         } else {
    //             otherEncoded = ((Key)obj).getEncoded();
    //         }
    //         return Arrays.equals(thisEncoded, otherEncoded);
    //     } catch (InvalidKeyException e) {
    //         return false;
    //     }
    // }

    // /**
    //  * Calculates a hash code value for the object. Objects
    //  * which are equal will also have the same hashcode.
    //  */
    // int hashCode() {
    //     try {
    //         byte[] b1 = getEncodedInternal();
    //         int r = b1.length;
    //         for (int i = 0; i < b1.length; i++) {
    //             r += (b1[i] & 0xff) * 37;
    //         }
    //         return r;
    //     } catch (InvalidKeyException e) {
    //         // should not happen
    //         return 0;
    //     }
    // }

    /*
     * Produce SubjectPublicKey encoding from algorithm id and key material.
     */
    static void encode(DerOutputStream stream, AlgorithmId algid, BitArray key)
        {
            DerOutputStream tmp = new DerOutputStream();
            algid.encode(tmp);
            tmp.putUnalignedBitString(key);
            stream.write(DerValue.tag_Sequence, tmp);
    }
}
