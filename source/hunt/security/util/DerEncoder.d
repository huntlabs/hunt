module hunt.security.util.DerEncoder;

import hunt.io.common;

/**
 * Interface to an object that knows how to write its own DER
 * encoding to an output stream.
 *
 * @author D. N. Hoover
 */
interface DerEncoder {

    /**
     * DER encode this object and write the results to a stream.
     *
     * @param out  the stream on which the DER encoding is written.
     */
    void derEncode(OutputStream ot);

}