module hunt.security.x509.X509Factory;

import hunt.security.x509.X509CertificatePair;
import hunt.security.x509.X509CertImpl;
import hunt.security.x509.X509CRLImpl;


import hunt.security.cert.CertificateFactorySpi;
import hunt.security.cert.Certificate;
import hunt.security.cert.CertPath;
import hunt.security.cert.CRL;
import hunt.security.cert.X509CRL;
import hunt.security.cert.X509Certificate;

import hunt.security.util.Cache;

import hunt.container;
import hunt.io.common;

import hunt.util.exception;


/**
 * This class defines a certificate factory for X.509 v3 certificates &
 * certification paths, and X.509 v2 certificate revocation lists (CRLs).
 *
 * @author Jan Luehe
 * @author Hemma Prafullchandra
 * @author Sean Mullan
 *
 *
 * @see java.security.cert.CertificateFactorySpi
 * @see java.security.cert.Certificate
 * @see java.security.cert.CertPath
 * @see java.security.cert.CRL
 * @see java.security.cert.X509Certificate
 * @see java.security.cert.X509CRL
 * @see sun.security.x509.X509CertImpl
 * @see sun.security.x509.X509CRLImpl
 */

class X509Factory : CertificateFactorySpi {

    enum string BEGIN_CERT = "-----BEGIN CERTIFICATE-----";
    enum string END_CERT = "-----END CERTIFICATE-----";

    private enum int ENC_MAX_LENGTH = 4096 * 1024; // 4 MB MAX

    private static Cache!(Object, X509CertImpl) certCache;
    private static Cache!(Object, X509CRLImpl) crlCache;

    static this()
    {
        certCache = newSoftMemoryCache!(Object, X509CertImpl)(750);
        crlCache = newSoftMemoryCache!(Object, X509CRLImpl)(750);
    }

    /**
     * Generates an X.509 certificate object and initializes it with
     * the data read from the input stream <code>inputStream</code>.
     *
     * @param inputStream an input stream with the certificate data.
     *
     * @return an X.509 certificate object initialized with the data
     * from the input stream.
     *
     * @exception CertificateException on parsing errors.
     */
    override
    Certificate engineGenerateCertificate(InputStream inputStream)
    {
        if (inputStream is null) {
            // clear the caches (for debugging)
            certCache.clear();
            X509CertificatePair.clearCache();
            throw new CertificateException("Missing input stream");
        }
        try {
            byte[] encoding = readOneBlock(inputStream);
            if (encoding !is null) {
                X509CertImpl cert = getFromCache(certCache, encoding);
                if (cert !is null) {
                    return cert;
                }
                cert = new X509CertImpl(encoding);
                addToCache(certCache, cert.getEncodedInternal(), cert);
                return cert;
            } else {
                throw new IOException("Empty input");
            }
        } catch (IOException ioe) {
            throw new CertificateException("Could not parse certificate: " ~
                    ioe.toString(), ioe);
        }
    }

    // /**
    //  * Read from the stream until length bytes have been read or EOF has
    //  * been reached. Return the number of bytes actually read.
    //  */
    // private static int readFully(InputStream inputStream, ByteArrayOutputStream bout,
    //         int length) {
    //     int read = 0;
    //     byte[] buffer = new byte[2048];
    //     while (length > 0) {
    //         int n = inputStream.read(buffer, 0, length<2048?length:2048);
    //         if (n <= 0) {
    //             break;
    //         }
    //         bout.write(buffer, 0, n);
    //         read += n;
    //         length -= n;
    //     }
    //     return read;
    // }

    /**
     * Return an interned X509CertImpl for the given certificate.
     * If the given X509Certificate or X509CertImpl is already present
     * in the cert cache, the cached object is returned. Otherwise,
     * if it is a X509Certificate, it is first converted to a X509CertImpl.
     * Then the X509CertImpl is added to the cache and returned.
     *
     * Note that all certificates created via generateCertificate(InputStream)
     * are already interned and this method does not need to be called.
     * It is useful for certificates that cannot be created via
     * generateCertificate() and for converting other X509Certificate
     * implementations to an X509CertImpl.
     *
     * @param c The source X509Certificate
     * @return An X509CertImpl object that is either a cached certificate or a
     *      newly built X509CertImpl from the provided X509Certificate
     * @ if failures occur while obtaining the DER
     *      encoding for certificate data.
     */
    static X509CertImpl intern(X509Certificate c) {
        implementationMissing();
        return null;
        // if (c is null) {
        //     return null;
        // }
        // bool isImpl = c instanceof X509CertImpl;
        // byte[] encoding;
        // if (isImpl) {
        //     encoding = ((X509CertImpl)c).getEncodedInternal();
        // } else {
        //     encoding = c.getEncoded();
        // }
        // X509CertImpl newC = getFromCache(certCache, encoding);
        // if (newC !is null) {
        //     return newC;
        // }
        // if (isImpl) {
        //     newC = (X509CertImpl)c;
        // } else {
        //     newC = new X509CertImpl(encoding);
        //     encoding = newC.getEncodedInternal();
        // }
        // addToCache(certCache, encoding, newC);
        // return newC;
    }

    /**
     * Return an interned X509CRLImpl for the given certificate.
     * For more information, see intern(X509Certificate).
     *
     * @param c The source X509CRL
     * @return An X509CRLImpl object that is either a cached CRL or a
     *      newly built X509CRLImpl from the provided X509CRL
     * @throws CRLException if failures occur while obtaining the DER
     *      encoding for CRL data.
     */
    static X509CRLImpl intern(X509CRL c) {
        if (c is null) {
            return null;
        }
                implementationMissing();
        return null;

        // X509CRLImpl cc = cast(X509CRLImpl)c;
        // bool isImpl = cc !is null;
        // byte[] encoding;
        // if (isImpl) {
        //     encoding = cc.getEncodedInternal();
        // } else {
        //     encoding = c.getEncoded();
        // }

        // X509CRLImpl newC = getFromCache(crlCache, encoding);
        // if (newC !is null) {
        //     return newC;
        // }
        // if (isImpl) {
        //     newC = cc;
        // } else {
        //     newC = new X509CRLImpl(encoding);
        //     encoding = newC.getEncodedInternal();
        // }
        // addToCache(crlCache, encoding, newC);
        // return newC;
    }

    /**
     * Get the X509CertImpl or X509CRLImpl from the cache.
     */
    private static V getFromCache(K,V)(Cache!(K, V) cache,
            byte[] encoding) {
        Object key = new EqualByteArray(encoding);
        return cache.get(key);
    }

    /**
     * Add the X509CertImpl or X509CRLImpl to the cache.
     */
    private static void addToCache(V)(Cache!(Object, V) cache,
            byte[] encoding, V value) {
        if (encoding.length > ENC_MAX_LENGTH) {
            return;
        }
        Object key = new EqualByteArray(encoding);
        cache.put(key, value);
    }

    // /**
    //  * Generates a <code>CertPath</code> object and initializes it with
    //  * the data read from the <code>InputStream</code> inStream. The data
    //  * is assumed to be in the default encoding.
    //  *
    //  * @param inStream an <code>InputStream</code> containing the data
    //  * @return a <code>CertPath</code> initialized with the data from the
    //  *   <code>InputStream</code>
    //  * @exception CertificateException if an exception occurs while decoding
    //  * @since 1.4
    //  */
    // override
    // CertPath engineGenerateCertPath(InputStream inStream)
        
    // {
    //     if (inStream is null) {
    //         throw new CertificateException("Missing input stream");
    //     }
    //     try {
    //         byte[] encoding = readOneBlock(inStream);
    //         if (encoding !is null) {
    //             return new X509CertPath(new ByteArrayInputStream(encoding));
    //         } else {
    //             throw new IOException("Empty input");
    //         }
    //     } catch (IOException ioe) {
    //         throw new CertificateException(ioe.msg);
    //     }
    // }

    // /**
    //  * Generates a <code>CertPath</code> object and initializes it with
    //  * the data read from the <code>InputStream</code> inStream. The data
    //  * is assumed to be in the specified encoding.
    //  *
    //  * @param inStream an <code>InputStream</code> containing the data
    //  * @param encoding the encoding used for the data
    //  * @return a <code>CertPath</code> initialized with the data from the
    //  *   <code>InputStream</code>
    //  * @exception CertificateException if an exception occurs while decoding or
    //  *   the encoding requested is not supported
    //  * @since 1.4
    //  */
    // override
    // CertPath engineGenerateCertPath(InputStream inStream,
    //     string encoding) 
    // {
    //     if (inStream is null) {
    //         throw new CertificateException("Missing input stream");
    //     }
    //     try {
    //         byte[] data = readOneBlock(inStream);
    //         if (data !is null) {
    //             return new X509CertPath(new ByteArrayInputStream(data), encoding);
    //         } else {
    //             throw new IOException("Empty input");
    //         }
    //     } catch (IOException ioe) {
    //         throw new CertificateException(ioe.msg);
    //     }
    // }

    // /**
    //  * Generates a <code>CertPath</code> object and initializes it with
    //  * a <code>List</code> of <code>Certificate</code>s.
    //  * <p>
    //  * The certificates supplied must be of a type supported by the
    //  * <code>CertificateFactory</code>. They will be copied out of the supplied
    //  * <code>List</code> object.
    //  *
    //  * @param certificates a <code>List</code> of <code>Certificate</code>s
    //  * @return a <code>CertPath</code> initialized with the supplied list of
    //  *   certificates
    //  * @exception CertificateException if an exception occurs
    //  * @since 1.4
    //  */
    // override
    // CertPath
    //     engineGenerateCertPath(List<? : Certificate> certificates)
        
    // {
    //     return(new X509CertPath(certificates));
    // }

    // /**
    //  * Returns an iteration of the <code>CertPath</code> encodings supported
    //  * by this certificate factory, with the default encoding first.
    //  * <p>
    //  * Attempts to modify the returned <code>Iterator</code> via its
    //  * <code>remove</code> method result in an
    //  * <code>UnsupportedOperationException</code>.
    //  *
    //  * @return an <code>Iterator</code> over the names of the supported
    //  *         <code>CertPath</code> encodings (as <code>string</code>s)
    //  * @since 1.4
    //  */
    // override
    // Iterator!string engineGetCertPathEncodings() {
    //     return(X509CertPath.getEncodingsStatic());
    // }

    /**
     * Returns a (possibly empty) collection view of X.509 certificates read
     * from the given input stream <code>is</code>.
     *
     * @param stream the input stream with the certificates.
     *
     * @return a (possibly empty) collection view of X.509 certificate objects
     * initialized with the data from the input stream.
     *
     * @exception CertificateException on parsing errors.
     */
    override
    Collection!(Certificate) engineGenerateCertificates(InputStream stream) {
        if (stream is null) {
            throw new CertificateException("Missing input stream");
        }
        try {
            return parseX509orPKCS7Cert(stream);
        } catch (IOException ioe) {
            throw new CertificateException("", ioe);
        }
    }

    /**
     * Generates an X.509 certificate revocation list (CRL) object and
     * initializes it with the data read from the given input stream
     * <code>is</code>.
     *
     * @param is an input stream with the CRL data.
     *
     * @return an X.509 CRL object initialized with the data
     * from the input stream.
     *
     * @exception CRLException on parsing errors.
     */
    override CRL engineGenerateCRL(InputStream stream)
    {
        if (stream is null) {
            // clear the cache (for debugging)
            crlCache.clear();
            throw new CRLException("Missing input stream");
        }
        try {
            // byte[] encoding = readOneBlock(stream);
            // if (encoding !is null) {
            //     X509CRLImpl crl = getFromCache(crlCache, encoding);
            //     if (crl !is null) {
            //         return crl;
            //     }
            //     crl = new X509CRLImpl(encoding);
            //     addToCache(crlCache, crl.getEncodedInternal(), crl);
            //     return crl;
            // } else {
            //     throw new IOException("Empty input");
            // }
            implementationMissing();
            return null;
        } catch (IOException ioe) {
            throw new CRLException(ioe.msg);
        }
    }

    /**
     * Returns a (possibly empty) collection view of X.509 CRLs read
     * from the given input stream <code>is</code>.
     *
     * @param stream the input stream with the CRLs.
     *
     * @return a (possibly empty) collection view of X.509 CRL objects
     * initialized with the data from the input stream.
     *
     * @exception CRLException on parsing errors.
     */
    override Collection!(CRL) engineGenerateCRLs(InputStream stream)  {
        if (stream is null) {
            throw new CRLException("Missing input stream");
        }
        try {
            // return parseX509orPKCS7CRL(stream);
            implementationMissing();
            return null;
        } catch (IOException ioe) {
            throw new CRLException(ioe.msg);
        }
    }

    /*
     * Parses the data in the given input stream as a sequence of DER
     * encoded X.509 certificates (in binary or base 64 encoded format) OR
     * as a single PKCS#7 encoded blob (in binary or base64 encoded format).
     */
    private Collection!(Certificate) parseX509orPKCS7Cert(InputStream stream)  {
        int peekByte;
        byte[] data;
        // PushbackInputStream pbis = new PushbackInputStream(stream);
        Collection!X509CertImpl coll = new ArrayList!X509CertImpl();

        // // Test the InputStream for end-of-stream.  If the stream's
        // // initial state is already at end-of-stream then return
        // // an empty collection.  Otherwise, push the byte back into the
        // // stream and let readOneBlock look for the first certificate.
        // peekByte = pbis.read();
        // if (peekByte == -1) {
        //     return new ArrayList!Certificate(0);
        // } else {
        //     pbis.unread(peekByte);
        //     data = readOneBlock(pbis);
        // }

        // // If we end up with a null value after reading the first block
        // // then we know the end-of-stream has been reached and no certificate
        // // data has been found.
        // if (data is null) {
        //     throw new CertificateException("No certificate data found");
        // }

        // try {
        //     PKCS7 pkcs7 = new PKCS7(data);
        //     X509Certificate[] certs = pkcs7.getCertificates();
        //     // certs are optional in PKCS #7
        //     if (certs !is null) {
        //         return Arrays.asList(certs);
        //     } else {
        //         // no certificates provided
        //         return new ArrayList<>(0);
        //     }
        // } catch (ParsingException e) {
        //     while (data !is null) {
        //         coll.add(new X509CertImpl(data));
        //         data = readOneBlock(pbis);
        //     }
        // }
        // return coll;
        implementationMissing();
        return null;
    }

    // /*
    //  * Parses the data in the given input stream as a sequence of DER encoded
    //  * X.509 CRLs (in binary or base 64 encoded format) OR as a single PKCS#7
    //  * encoded blob (in binary or base 64 encoded format).
    //  */
    // private Collection<? : java.security.cert.CRL>
    //     parseX509orPKCS7CRL(InputStream is)
    //     , IOException
    // {
    //     int peekByte;
    //     byte[] data;
    //     PushbackInputStream pbis = new PushbackInputStream(is);
    //     Collection<X509CRLImpl> coll = new ArrayList<>();

    //     // Test the InputStream for end-of-stream.  If the stream's
    //     // initial state is already at end-of-stream then return
    //     // an empty collection.  Otherwise, push the byte back into the
    //     // stream and let readOneBlock look for the first CRL.
    //     peekByte = pbis.read();
    //     if (peekByte == -1) {
    //         return new ArrayList<>(0);
    //     } else {
    //         pbis.unread(peekByte);
    //         data = readOneBlock(pbis);
    //     }

    //     // If we end up with a null value after reading the first block
    //     // then we know the end-of-stream has been reached and no CRL
    //     // data has been found.
    //     if (data is null) {
    //         throw new CRLException("No CRL data found");
    //     }

    //     try {
    //         PKCS7 pkcs7 = new PKCS7(data);
    //         X509CRL[] crls = pkcs7.getCRLs();
    //         // CRLs are optional in PKCS #7
    //         if (crls !is null) {
    //             return Arrays.asList(crls);
    //         } else {
    //             // no crls provided
    //             return new ArrayList<>(0);
    //         }
    //     } catch (ParsingException e) {
    //         while (data !is null) {
    //             coll.add(new X509CRLImpl(data));
    //             data = readOneBlock(pbis);
    //         }
    //     }
    //     return coll;
    // }

    /**
     * Returns an ASN.1 SEQUENCE from a stream, which might be a BER-encoded
     * binary block or a PEM-style BASE64-encoded ASCII data. In the latter
     * case, it's de-BASE64'ed before return.
     *
     * After the reading, the input stream pointer is after the BER block, or
     * after the newline character after the -----END SOMETHING----- line.
     *
     * @param is the InputStream
     * @returns byte block or null if end of stream
     * @If any parsing error
     */
    private static byte[] readOneBlock(InputStream stream) {
        implementationMissing();
        return null;
        // The first character of a BLOCK.
        // int c = stream.read();
        // if (c == -1) {
        //     return null;
        // }
        // if (c == DerValue.tag_Sequence) {
        //     ByteArrayOutputStream bout = new ByteArrayOutputStream(2048);
        //     bout.write(c);
        //     readBERInternal(stream, bout, c);
        //     return bout.toByteArray();
        // } else {
        //     // Read BASE64 encoded data, might skip info at the beginning
        //     char[] data = new char[2048];
        //     int pos = 0;

        //     // Step 1: Read until header is found
        //     int hyphen = (c=='-') ? 1: 0;   // count of consequent hyphens
        //     int last = (c=='-') ? -1: c;    // the char before hyphen
        //     while (true) {
        //         int next = stream.read();
        //         if (next == -1) {
        //             // We accept useless data after the last block,
        //             // say, empty lines.
        //             return null;
        //         }
        //         if (next == '-') {
        //             hyphen++;
        //         } else {
        //             hyphen = 0;
        //             last = next;
        //         }
        //         if (hyphen == 5 && (last == -1 || last == '\r' || last == '\n')) {
        //             break;
        //         }
        //     }

        //     // Step 2: Read the rest of header, determine the line end
        //     int end;
        //     StringBuilder header = new StringBuilder("-----");
        //     while (true) {
        //         int next = stream.read();
        //         if (next == -1) {
        //             throw new IOException("Incomplete data");
        //         }
        //         if (next == '\n') {
        //             end = '\n';
        //             break;
        //         }
        //         if (next == '\r') {
        //             next = stream.read();
        //             if (next == -1) {
        //                 throw new IOException("Incomplete data");
        //             }
        //             if (next == '\n') {
        //                 end = '\n';
        //             } else {
        //                 end = '\r';
        //                 data[pos++] = (char)next;
        //             }
        //             break;
        //         }
        //         header.append((char)next);
        //     }

        //     // Step 3: Read the data
        //     while (true) {
        //         int next = stream.read();
        //         if (next == -1) {
        //             throw new IOException("Incomplete data");
        //         }
        //         if (next != '-') {
        //             data[pos++] = (char)next;
        //             if (pos >= data.length) {
        //                 data = Arrays.copyOf(data, data.length+1024);
        //             }
        //         } else {
        //             break;
        //         }
        //     }

        //     // Step 4: Consume the footer
        //     StringBuilder footer = new StringBuilder("-");
        //     while (true) {
        //         int next = stream.read();
        //         // Add next == '\n' for maximum safety, in case endline
        //         // is not consistent.
        //         if (next == -1 || next == end || next == '\n') {
        //             break;
        //         }
        //         if (next != '\r') footer.append((char)next);
        //     }

        //     checkHeaderFooter(header.toString(), footer.toString());

        //     return Pem.decode(new string(data, 0, pos));
        // }
    }

    // private static void checkHeaderFooter(string header,
    //         string footer) {
    //     if (header.length() < 16 || !header.startsWith("-----BEGIN ") ||
    //             !header.endsWith("-----")) {
    //         throw new IOException("Illegal header: " ~ header);
    //     }
    //     if (footer.length() < 14 || !footer.startsWith("-----END ") ||
    //             !footer.endsWith("-----")) {
    //         throw new IOException("Illegal footer: " ~ footer);
    //     }
    //     string headerType = header.substring(11, header.length()-5);
    //     string footerType = footer.substring(9, footer.length()-5);
    //     if (!headerType.equals(footerType)) {
    //         throw new IOException("Header and footer do not match: " ~
    //                 header ~ " " ~ footer);
    //     }
    // }

    // /**
    //  * Read one BER data block. This method is aware of indefinite-length BER
    //  * encoding and will read all of the sub-sections in a recursive way
    //  *
    //  * @param stream    Read from this InputStream
    //  * @param bout  Write into this OutputStream
    //  * @param tag   Tag already read (-1 mean not read)
    //  * @returns     The current tag, used to check EOC in indefinite-length BER
    //  * @Any parsing error
    //  */
    // private static int readBERInternal(InputStream stream,
    //         ByteArrayOutputStream bout, int tag) {

    //     if (tag == -1) {        // Not read before the call, read now
    //         tag = stream.read();
    //         if (tag == -1) {
    //             throw new IOException("BER/DER tag info absent");
    //         }
    //         if ((tag & 0x1f) == 0x1f) {
    //             throw new IOException("Multi octets tag not supported");
    //         }
    //         bout.write(tag);
    //     }

    //     int n = stream.read();
    //     if (n == -1) {
    //         throw new IOException("BER/DER length info absent");
    //     }
    //     bout.write(n);

    //     int length;

    //     if (n == 0x80) {        // Indefinite-length encoding
    //         if ((tag & 0x20) != 0x20) {
    //             throw new IOException(
    //                     "Non constructed encoding must have definite length");
    //         }
    //         while (true) {
    //             int subTag = readBERInternal(stream, bout, -1);
    //             if (subTag == 0) {   // EOC, end of indefinite-length section
    //                 break;
    //             }
    //         }
    //     } else {
    //         if (n < 0x80) {
    //             length = n;
    //         } else if (n == 0x81) {
    //             length = stream.read();
    //             if (length == -1) {
    //                 throw new IOException("Incomplete BER/DER length info");
    //             }
    //             bout.write(length);
    //         } else if (n == 0x82) {
    //             int highByte = stream.read();
    //             int lowByte = stream.read();
    //             if (lowByte == -1) {
    //                 throw new IOException("Incomplete BER/DER length info");
    //             }
    //             bout.write(highByte);
    //             bout.write(lowByte);
    //             length = (highByte << 8) | lowByte;
    //         } else if (n == 0x83) {
    //             int highByte = stream.read();
    //             int midByte = stream.read();
    //             int lowByte = stream.read();
    //             if (lowByte == -1) {
    //                 throw new IOException("Incomplete BER/DER length info");
    //             }
    //             bout.write(highByte);
    //             bout.write(midByte);
    //             bout.write(lowByte);
    //             length = (highByte << 16) | (midByte << 8) | lowByte;
    //         } else if (n == 0x84) {
    //             int highByte = stream.read();
    //             int nextByte = stream.read();
    //             int midByte = stream.read();
    //             int lowByte = stream.read();
    //             if (lowByte == -1) {
    //                 throw new IOException("Incomplete BER/DER length info");
    //             }
    //             if (highByte > 127) {
    //                 throw new IOException("Invalid BER/DER data (a little huge?)");
    //             }
    //             bout.write(highByte);
    //             bout.write(nextByte);
    //             bout.write(midByte);
    //             bout.write(lowByte);
    //             length = (highByte << 24 ) | (nextByte << 16) |
    //                     (midByte << 8) | lowByte;
    //         } else { // ignore longer length forms
    //             throw new IOException("Invalid BER/DER data (too huge?)");
    //         }
    //         if (readFully(stream, bout, length) != length) {
    //             throw new IOException("Incomplete BER/DER data");
    //         }
    //     }
    //     return tag;
    // }
}
