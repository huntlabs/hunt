module hunt.math.Double;


import hunt.util.exception;
import hunt.math.Number;
import std.conv;

class Double : Number{
    
    /**
     * A constant holding the positive infinity of type
     * {@code double}. It is equal to the value returned by
     * {@code Double.longBitsToDouble(0x7ff0000000000000L)}.
     */
    enum double POSITIVE_INFINITY = double.infinity; //1.0 / 0.0;

    /**
     * A constant holding the negative infinity of type
     * {@code double}. It is equal to the value returned by
     * {@code Double.longBitsToDouble(0xfff0000000000000L)}.
     */
    enum double NEGATIVE_INFINITY = -double.infinity; // -1.0 / 0.0;

    /**
     * A constant holding a Not-a-Number (NaN) value of type
     * {@code double}. It is equivalent to the value returned by
     * {@code Double.longBitsToDouble(0x7ff8000000000000L)}.
     */
    enum double NaN = double.nan; // 0.0d / 0.0;

    /**
     * A constant holding the largest positive finite value of type
     * {@code double},
     * (2-2<sup>-52</sup>)&middot;2<sup>1023</sup>.  It is equal to
     * the hexadecimal floating-point literal
     * {@code 0x1.fffffffffffffP+1023} and also equal to
     * {@code Double.longBitsToDouble(0x7fefffffffffffffL)}.
     */
    enum double MAX_VALUE = double.max; // 0x1.fffffffffffffP+1023; // 1.7976931348623157e+308

    /**
     * A constant holding the smallest positive normal value of type
     * {@code double}, 2<sup>-1022</sup>.  It is equal to the
     * hexadecimal floating-point literal {@code 0x1.0p-1022} and also
     * equal to {@code Double.longBitsToDouble(0x0010000000000000L)}.
     *
     * @since 1.6
     */
    enum double MIN_NORMAL = double.min_normal; // 0x1.0p-1022; // 2.2250738585072014E-308

    /**
     * A constant holding the smallest positive nonzero value of type
     * {@code double}, 2<sup>-1074</sup>. It is equal to the
     * hexadecimal floating-point literal
     * {@code 0x0.0000000000001P-1022} and also equal to
     * {@code Double.longBitsToDouble(0x1L)}.
     */
    enum double MIN_VALUE = double.min_10_exp; // 0x0.0000000000001P-1022; // 4.9e-324

    /**
     * Maximum exponent a finite {@code double} variable may have.
     * It is equal to the value returned by
     * {@code Math.getExponent(Double.MAX_VALUE)}.
     *
     * @since 1.6
     */
    enum int MAX_EXPONENT = 1023;

    /**
     * Minimum exponent a normalized {@code double} variable may
     * have.  It is equal to the value returned by
     * {@code Math.getExponent(Double.MIN_NORMAL)}.
     *
     * @since 1.6
     */
    enum int MIN_EXPONENT = -1022;

    /**
     * The number of bits used to represent a {@code double} value.
     *
     * @since 1.5
     */
    enum int SIZE = 64;

    /**
     * The number of bytes used to represent a {@code double} value.
     *
     * @since 1.8
     */
    enum int BYTES = SIZE / 8;



    /**
     * Returns the {@code double} value corresponding to a given
     * bit representation.
     * The argument is considered to be a representation of a
     * floating-point value according to the IEEE 754 floating-point
     * "double format" bit layout.
     *
     * <p>If the argument is {@code 0x7ff0000000000000L}, the result
     * is positive infinity.
     *
     * <p>If the argument is {@code 0xfff0000000000000L}, the result
     * is negative infinity.
     *
     * <p>If the argument is any value in the range
     * {@code 0x7ff0000000000001L} through
     * {@code 0x7fffffffffffffffL} or in the range
     * {@code 0xfff0000000000001L} through
     * {@code 0xffffffffffffffffL}, the result is a NaN.  No IEEE
     * 754 floating-point operation provided by Java can distinguish
     * between two NaN values of the same type with different bit
     * patterns.  Distinct values of NaN are only distinguishable by
     * use of the {@code Double.doubleToRawLongBits} method.
     *
     * <p>In all other cases, let <i>s</i>, <i>e</i>, and <i>m</i> be three
     * values that can be computed from the argument:
     *
     * <blockquote><pre>{@code
     * int s = ((bits >> 63) == 0) ? 1 : -1;
     * int e = (int)((bits >> 52) & 0x7ffL);
     * long m = (e == 0) ?
     *                 (bits & 0xfffffffffffffL) << 1 :
     *                 (bits & 0xfffffffffffffL) | 0x10000000000000L;
     * }</pre></blockquote>
     *
     * Then the floating-point result equals the value of the mathematical
     * expression <i>s</i>&middot;<i>m</i>&middot;2<sup><i>e</i>-1075</sup>.
     *
     * <p>Note that this method may not be able to return a
     * {@code double} NaN with exactly same bit pattern as the
     * {@code long} argument.  IEEE 754 distinguishes between two
     * kinds of NaNs, quiet NaNs and <i>signaling NaNs</i>.  The
     * differences between the two kinds of NaN are generally not
     * visible in Java.  Arithmetic operations on signaling NaNs turn
     * them into quiet NaNs with a different, but often similar, bit
     * pattern.  However, on some processors merely copying a
     * signaling NaN also performs that conversion.  In particular,
     * copying a signaling NaN to return it to the calling method
     * may perform this conversion.  So {@code longBitsToDouble}
     * may not be able to return a {@code double} with a
     * signaling NaN bit pattern.  Consequently, for some
     * {@code long} values,
     * {@code doubleToRawLongBits(longBitsToDouble(start))} may
     * <i>not</i> equal {@code start}.  Moreover, which
     * particular bit patterns represent signaling NaNs is platform
     * dependent; although all NaN bit patterns, quiet or signaling,
     * must be in the NaN range identified above.
     *
     * @param   bits   any {@code long} integer.
     * @return  the {@code double} floating-point value with the same
     *          bit pattern.
     */
    public static double longBitsToDouble(long bits) {
        implementationMissing(false);
        return 0;
    }

    /**
     * The value of the Double.
     *
     * @serial
     */
    private  double value;

    /**
     * Constructs a newly allocated {@code Double} object that
     * represents the primitive {@code double} argument.
     *
     * @param   value   the value to be represented by the {@code Double}.
     */
    public this(double value) {
        this.value = value;
    }

    /**
     * Constructs a newly allocated {@code Double} object that
     * represents the floating-point value of type {@code double}
     * represented by the string. The string is converted to a
     * {@code double} value as if by the {@code valueOf} method.
     *
     * @param  s  a string to be converted to a {@code Double}.
     * @throws    NumberFormatException  if the string does not contain a
     *            parsable number.
     * @see       java.lang.Double#valueOf(java.lang.String)
     */
    // public Double(String s) throws NumberFormatException {
    //     value = parseDouble(s);
    // }

    /**
     * Returns {@code true} if this {@code Double} value is
     * a Not-a-Number (NaN), {@code false} otherwise.
     *
     * @return  {@code true} if the value represented by this object is
     *          NaN; {@code false} otherwise.
     */
    public static bool isNaN(double v) {
        return isNaN(v);
    }

    /**
     * Returns {@code true} if this {@code Double} value is
     * infinitely large in magnitude, {@code false} otherwise.
     *
     * @return  {@code true} if the value represented by this object is
     *          positive infinity or negative infinity;
     *          {@code false} otherwise.
     */
    // public boolean isInfinite() {
    //     return isInfinite(value);
    // }

    /**
     * Returns a string representation of this {@code Double} object.
     * The primitive {@code double} value represented by this
     * object is converted to a string exactly as if by the method
     * {@code toString} of one argument.
     *
     * @return  a {@code String} representation of this object.
     * @see java.lang.Double#toString(double)
     */
    override string toString() {
        return to!string(value);
    }

    /**
     * Returns the value of this {@code Double} as a {@code byte}
     * after a narrowing primitive conversion.
     *
     * @return  the {@code double} value represented by this object
     *          converted to type {@code byte}
     * @jls 5.1.3 Narrowing Primitive Conversions
     * @since JDK1.1
     */
    override public byte byteValue() {
        return cast(byte)value;
    }

    /**
     * Returns the value of this {@code Double} as a {@code short}
     * after a narrowing primitive conversion.
     *
     * @return  the {@code double} value represented by this object
     *          converted to type {@code short}
     * @jls 5.1.3 Narrowing Primitive Conversions
     * @since JDK1.1
     */
    override public short shortValue() {
        return cast(short)value;
    }

    /**
     * Returns the value of this {@code Double} as an {@code int}
     * after a narrowing primitive conversion.
     * @jls 5.1.3 Narrowing Primitive Conversions
     *
     * @return  the {@code double} value represented by this object
     *          converted to type {@code int}
     */
    override public int intValue() {
        return cast(int)value;
    }

    /**
     * Returns the value of this {@code Double} as a {@code long}
     * after a narrowing primitive conversion.
     *
     * @return  the {@code double} value represented by this object
     *          converted to type {@code long}
     * @jls 5.1.3 Narrowing Primitive Conversions
     */
    override public long longValue() {
        return cast(long)value;
    }

    /**
     * Returns the value of this {@code Double} as a {@code float}
     * after a narrowing primitive conversion.
     *
     * @return  the {@code double} value represented by this object
     *          converted to type {@code float}
     * @jls 5.1.3 Narrowing Primitive Conversions
     * @since JDK1.0
     */
    override public float floatValue() {
        return cast(float)value;
    }

    /**
     * Returns the {@code double} value of this {@code Double} object.
     *
     * @return the {@code double} value represented by this object
     */
    override public double doubleValue() {
        return value;
    }

    /**
     * Returns a hash code for a {@code double} value; compatible with
     * {@code Double.hashCode()}.
     *
     * @param value the value to hash
     * @return a hash code value for a {@code double} value.
     * @since 1.8
     */
    override public size_t toHash() @safe nothrow {
        return hashOf(value);
    }

    /**
     * Compares this object against the specified object.  The result
     * is {@code true} if and only if the argument is not
     * {@code null} and is a {@code Double} object that
     * represents a {@code double} that has the same value as the
     * {@code double} represented by this object. For this
     * purpose, two {@code double} values are considered to be
     * the same if and only if the method {@link
     * #doubleToLongBits(double)} returns the identical
     * {@code long} value when applied to each.
     *
     * <p>Note that in most cases, for two instances of class
     * {@code Double}, {@code d1} and {@code d2}, the
     * value of {@code d1.equals(d2)} is {@code true} if and
     * only if
     *
     * <blockquote>
     *  {@code d1.doubleValue() == d2.doubleValue()}
     * </blockquote>
     *
     * <p>also has the value {@code true}. However, there are two
     * exceptions:
     * <ul>
     * <li>If {@code d1} and {@code d2} both represent
     *     {@code Double.NaN}, then the {@code equals} method
     *     returns {@code true}, even though
     *     {@code Double.NaN==Double.NaN} has the value
     *     {@code false}.
     * <li>If {@code d1} represents {@code +0.0} while
     *     {@code d2} represents {@code -0.0}, or vice versa,
     *     the {@code equal} test has the value {@code false},
     *     even though {@code +0.0==-0.0} has the value {@code true}.
     * </ul>
     * This definition allows hash tables to operate properly.
     * @param   obj   the object to compare with.
     * @return  {@code true} if the objects are the same;
     *          {@code false} otherwise.
     * @see java.lang.Double#doubleToLongBits(double)
     */
    override public bool opEquals(Object obj) {
        auto dl = cast(Double)obj;
        if(dl !is null)
        {
            return to!string(value) == dl.toString;
        }

        return false;
    }


}


/**
 * This class contains additional constants documenting limits of the
 * {@code double} type.
 *
 * @author Joseph D. Darcy
 */

public class DoubleConsts {
    /**
     * Don't let anyone instantiate this class.
     */
    private this() {}

    /**
     * The number of logical bits in the significand of a
     * {@code double} number, including the implicit bit.
     */
    enum int SIGNIFICAND_WIDTH   = 53;

    /**
     * The exponent the smallest positive {@code double}
     * subnormal value would have if it could be normalized..
     */
    enum int     MIN_SUB_EXPONENT = Double.MIN_EXPONENT -
                                                   (SIGNIFICAND_WIDTH - 1);

    /**
     * Bias used in representing a {@code double} exponent.
     */
    enum int     EXP_BIAS        = 1023;

    /**
     * Bit mask to isolate the sign bit of a {@code double}.
     */
    enum long    SIGN_BIT_MASK   = 0x8000000000000000L;

    /**
     * Bit mask to isolate the exponent field of a
     * {@code double}.
     */
    enum long    EXP_BIT_MASK    = 0x7FF0000000000000L;

    /**
     * Bit mask to isolate the significand field of a
     * {@code double}.
     */
    enum long    SIGNIF_BIT_MASK = 0x000FFFFFFFFFFFFFL;

    // static {
    //     // verify bit masks cover all bit positions and that the bit
    //     // masks are non-overlapping
    //     assert(((SIGN_BIT_MASK | EXP_BIT_MASK | SIGNIF_BIT_MASK) == ~0L) &&
    //            (((SIGN_BIT_MASK & EXP_BIT_MASK) == 0L) &&
    //             ((SIGN_BIT_MASK & SIGNIF_BIT_MASK) == 0L) &&
    //             ((EXP_BIT_MASK & SIGNIF_BIT_MASK) == 0L)));
    // }

}