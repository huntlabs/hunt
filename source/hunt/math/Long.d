module hunt.math.Long;
import hunt.math.Number;

class Long : Number{

     // Bit Twiddling

      /**
     * A constant holding the minimum value a {@code long} can
     * have, -2<sup>63</sup>.
     */
   public static  long MIN_VALUE = 0x8000000000000000L;

    /**
     * A constant holding the maximum value a {@code long} can
     * have, 2<sup>63</sup>-1.
     */
    public static  long MAX_VALUE = 0x7fffffffffffffffL;

    /**
     * The number of bits used to represent a {@code long} value in two's
     * complement binary form.
     *
     * @since 1.5
     */
    enum int SIZE = 64;

    /**
     * The number of bytes used to represent a {@code long} value in two's
     * complement binary form.
     *
     * @since 1.8
     */
    enum BYTES = SIZE / 8;

    /**
     * Returns the signum function of the specified {@code long} value.  (The
     * return value is -1 if the specified value is negative; 0 if the
     * specified value is zero; and 1 if the specified value is positive.)
     *
     * @param i the value whose signum is to be computed
     * @return the signum function of the specified {@code long} value.
     * @since 1.5
     */
    static int signum(long i) {
        // HD, Section 2-7
        return cast(int) ((i >> 63) | (-i >>> 63));
    }


    /**
     * Returns the number of zero bits preceding the highest-order
     * ("leftmost") one-bit in the two's complement binary representation
     * of the specified {@code long} value.  Returns 64 if the
     * specified value has no one-bits in its two's complement representation,
     * in other words if it is equal to zero.
     *
     * <p>Note that this method is closely related to the logarithm base 2.
     * For all positive {@code long} values x:
     * <ul>
     * <li>floor(log<sub>2</sub>(x)) = {@code 63 - numberOfLeadingZeros(x)}
     * <li>ceil(log<sub>2</sub>(x)) = {@code 64 - numberOfLeadingZeros(x - 1)}
     * </ul>
     *
     * @param i the value whose number of leading zeros is to be computed
     * @return the number of zero bits preceding the highest-order
     *     ("leftmost") one-bit in the two's complement binary representation
     *     of the specified {@code long} value, or 64 if the value
     *     is equal to zero.
     * @since 1.5
     */
    public static int numberOfLeadingZeros(long i) {
        // HD, Figure 5-6
         if (i == 0)
            return 64;
        int n = 1;
        int x = cast(int)(i >>> 32);
        if (x == 0) { n += 32; x = cast(int)i; }
        if (x >>> 16 == 0) { n += 16; x <<= 16; }
        if (x >>> 24 == 0) { n +=  8; x <<=  8; }
        if (x >>> 28 == 0) { n +=  4; x <<=  4; }
        if (x >>> 30 == 0) { n +=  2; x <<=  2; }
        n -= x >>> 31;
        return n;
    }

    /**
     * The value of the {@code Long}.
     *
     * @serial
     */
    private  long value;

    /**
     * Constructs a newly allocated {@code Long} object that
     * represents the specified {@code long} argument.
     *
     * @param   value   the value to be represented by the
     *          {@code Long} object.
     */
    public this(long value) {
        this.value = value;
    }

    /**
     * Constructs a newly allocated {@code Long} object that
     * represents the {@code long} value indicated by the
     * {@code String} parameter. The string is converted to a
     * {@code long} value in exactly the manner used by the
     * {@code parseLong} method for radix 10.
     *
     * @param      s   the {@code String} to be converted to a
     *             {@code Long}.
     * @throws     NumberFormatException  if the {@code String} does not
     *             contain a parsable {@code long}.
     * @see        java.lang.Long#parseLong(java.lang.String, int)
     */
    // public Long(String s) throws NumberFormatException {
    //     this.value = parseLong(s, 10);
    // }

    /**
     * Returns the value of this {@code Long} as a {@code byte} after
     * a narrowing primitive conversion.
     * @jls 5.1.3 Narrowing Primitive Conversions
     */
    override public byte byteValue() {
        return cast(byte)value;
    }

    /**
     * Returns the value of this {@code Long} as a {@code short} after
     * a narrowing primitive conversion.
     * @jls 5.1.3 Narrowing Primitive Conversions
     */
    override public short shortValue() {
        return cast(short)value;
    }

    /**
     * Returns the value of this {@code Long} as an {@code int} after
     * a narrowing primitive conversion.
     * @jls 5.1.3 Narrowing Primitive Conversions
     */
    override public int intValue() {
        return cast(int)value;
    }

    /**
     * Returns the value of this {@code Long} as a
     * {@code long} value.
     */
    override public long longValue() {
        return value;
    }

    /**
     * Returns the value of this {@code Long} as a {@code float} after
     * a widening primitive conversion.
     * @jls 5.1.2 Widening Primitive Conversions
     */
    override public float floatValue() {
        return cast(float)value;
    }

    /**
     * Returns the value of this {@code Long} as a {@code double}
     * after a widening primitive conversion.
     * @jls 5.1.2 Widening Primitive Conversions
     */
    override public double doubleValue() {
        return cast(double)value;
    }

}