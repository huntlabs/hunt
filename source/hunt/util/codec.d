module hunt.util.codec;


/**
 * Fast B64 Encoder/Decoder as described in RFC 1421.
 * <p>Does not insert or interpret whitespace as described in RFC
 * 1521. If you require this you must pre/post process your data.
 * <p> Note that in a web context the usual case is to not want
 * linebreaks or other white space in the encoded output.
 */
class B64Code {
    private enum char __pad = '=';
    private enum char[] __rfc1421alphabet =
            [
                    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
                    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
                    'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
                    'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'
            ];

    private __gshared byte[] __rfc1421nibbles;

    private enum char[] __rfc4648urlAlphabet =
            [
                    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
                    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
                    'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
                    'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '-', '_'
            ];

    private __gshared byte[] __rfc4648urlNibbles;

    shared static this() {
        
        __rfc1421nibbles = new byte[256];
        for (int i = 0; i < 256; i++)
            __rfc1421nibbles[i] = -1;
        for (byte b = 0; b < 64; b++)
            __rfc1421nibbles[cast(byte) __rfc1421alphabet[b]] = b;
        __rfc1421nibbles[cast(byte) __pad] = 0;

        __rfc4648urlNibbles = new byte[256];
        for (int i = 0; i < 256; i++)
            __rfc4648urlNibbles[i] = -1;
        for (byte b = 0; b < 64; b++)
            __rfc4648urlNibbles[cast(byte) __rfc4648urlAlphabet[b]] = b;
        __rfc4648urlNibbles[cast(byte) __pad] = 0;
    }

    private this() {
    }


    
    /**
     * Fast Base 64 encode as described in RFC 1421.
     * <p>Does not insert whitespace as described in RFC 1521.
     * <p> Avoids creating extra copies of the input/output.
     *
     * @param b byte array to encode.
     * @return char array containing the encoded form of the input.
     */
    static char[] encode(byte[] b) {
        if (b == null)
            return null;

        int bLen = cast(int)b.length;
        int cLen = ((bLen + 2) / 3) * 4;
        char[] c = new char[cLen];
        int ci = 0;
        int bi = 0;
        byte b0, b1, b2;
        int stop = (bLen / 3) * 3;
        while (bi < stop) {
            b0 = b[bi++];
            b1 = b[bi++];
            b2 = b[bi++];
            c[ci++] = __rfc1421alphabet[(b0 >>> 2) & 0x3f];
            c[ci++] = __rfc1421alphabet[(b0 << 4) & 0x3f | (b1 >>> 4) & 0x0f];
            c[ci++] = __rfc1421alphabet[(b1 << 2) & 0x3f | (b2 >>> 6) & 0x03];
            c[ci++] = __rfc1421alphabet[b2 & 0x3f];
        }

        if (bLen != bi) {
            switch (bLen % 3) {
                case 2:
                    b0 = b[bi++];
                    b1 = b[bi++];
                    c[ci++] = __rfc1421alphabet[(b0 >>> 2) & 0x3f];
                    c[ci++] = __rfc1421alphabet[(b0 << 4) & 0x3f | (b1 >>> 4) & 0x0f];
                    c[ci++] = __rfc1421alphabet[(b1 << 2) & 0x3f];
                    c[ci++] = __pad;
                    break;

                case 1:
                    b0 = b[bi++];
                    c[ci++] = __rfc1421alphabet[(b0 >>> 2) & 0x3f];
                    c[ci++] = __rfc1421alphabet[(b0 << 4) & 0x3f];
                    c[ci++] = __pad;
                    c[ci++] = __pad;
                    break;

                default:
                    break;
            }
        }

        return c;
    }

}