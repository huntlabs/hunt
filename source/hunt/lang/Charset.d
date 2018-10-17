module hunt.lang.Charset;

alias Charset = string;

class StandardCharsets {

    /**
     * Seven-bit ASCII, a.k.a. ISO646-US, a.k.a. the Basic Latin block of the
     * Unicode character set
     */
    enum string US_ASCII = "US-ASCII";
    /**
     * ISO Latin Alphabet No. 1, a.k.a. ISO-LATIN-1
     */
    enum string ISO_8859_1 = "ISO-8859-1";
    /**
     * Eight-bit UCS Transformation Format
     */
    enum string UTF_8 = "UTF-8";
    /**
     * Sixteen-bit UCS Transformation Format, big-endian byte order
     */
    enum string UTF_16BE = "UTF-16BE";
    /**
     * Sixteen-bit UCS Transformation Format, little-endian byte order
     */
    enum string UTF_16LE = "UTF-16LE";
    /**
     * Sixteen-bit UCS Transformation Format, byte order identified by an
     * optional byte-order mark
     */
    enum string UTF_16 = "UTF-16";
}