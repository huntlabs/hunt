module hunt.concurrent.atomic.AtomicBiInteger;

/**
 * An AtomicLong with additional methods to treat it as two hi/lo integers.
 */
public class AtomicBiInteger  { // AtomicLong

   /**
     * Gets a hi value from the given encoded value.
     *
     * @param encoded the encoded value
     * @return the hi value
     */
    public static int getHi(long encoded) {
        return cast(int) ((encoded >> 32) & 0xFFFF_FFFFL);
    }

    /**
     * Gets a lo value from the given encoded value.
     *
     * @param encoded the encoded value
     * @return the lo value
     */
    public static int getLo(long encoded) {
        return cast(int) (encoded & 0xFFFF_FFFFL);
    }

       /**
     * Encodes hi and lo values into a long.
     *
     * @param hi the hi value
     * @param lo the lo value
     * @return the encoded value
     */
    public static long encode(int hi, int lo) {
        long h = (cast(long) hi) & 0xFFFF_FFFFL;
        long l = (cast(long) lo) & 0xFFFF_FFFFL;
        return (h << 32) + l;
    }

    /**
     * Sets the hi value into the given encoded value.
     *
     * @param encoded the encoded value
     * @param hi      the hi value
     * @return the new encoded value
     */
    public static long encodeHi(long encoded, int hi) {
        long h = (cast(long) hi) & 0xFFFF_FFFFL;
        long l = encoded & 0xFFFF_FFFFL;
        return (h << 32) + l;
    }

    /**
     * Sets the lo value into the given encoded value.
     *
     * @param encoded the encoded value
     * @param lo      the lo value
     * @return the new encoded value
     */
    public static long encodeLo(long encoded, int lo) {
        long h = (encoded >> 32) & 0xFFFF_FFFFL;
        long l = (cast(long) lo) & 0xFFFF_FFFFL;
        return (h << 32) + l;
    }

    /**
     * Atomically adds the given deltas to the current hi and lo values.
     *
     * @param deltaHi the delta to apply to the hi value
     * @param deltaLo the delta to apply to the lo value
     */
    public static long encode(long encoded, int deltaHi, int deltaLo) {
        // while (true) {
                return encode(getHi(encoded) + deltaHi, getLo(encoded) + deltaLo);
        // }
    }

}