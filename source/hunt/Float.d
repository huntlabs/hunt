/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2018-2019 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.Float;

import hunt.Exceptions;
import hunt.Nullable;
import hunt.Number;
import std.conv;

class Float : AbstractNumber!float {
    /**
     * A constant holding the positive infinity of type
     * {@code float}. It is equal to the value returned by
     * {@code Float.intBitsToFloat(0x7f800000)}.
     */
    enum float POSITIVE_INFINITY = float.infinity; // 1.0f / 0.0f;

    /**
     * A constant holding the negative infinity of type
     * {@code float}. It is equal to the value returned by
     * {@code Float.intBitsToFloat(0xff800000)}.
     */
    enum float NEGATIVE_INFINITY = -float.infinity; // -1.0f / 0.0f;

    /**
     * A constant holding a Not-a-Number (NaN) value of type
     * {@code float}.  It is equivalent to the value returned by
     * {@code Float.intBitsToFloat(0x7fc00000)}.
     */
    enum float NaN = float.nan; // 0.0f / 0.0f;

    /**
     * A constant holding the largest positive finite value of type
     * {@code float}, (2-2<sup>-23</sup>)&middot;2<sup>127</sup>.
     * It is equal to the hexadecimal floating-point literal
     * {@code 0x1.fffffeP+127f} and also equal to
     * {@code Float.intBitsToFloat(0x7f7fffff)}.
     */
    enum float MAX_VALUE = float.max; // 0x1.fffffeP+127f; // 3.4028235e+38f

    /**
     * A constant holding the smallest positive normal value of type
     * {@code float}, 2<sup>-126</sup>.  It is equal to the
     * hexadecimal floating-point literal {@code 0x1.0p-126f} and also
     * equal to {@code Float.intBitsToFloat(0x00800000)}.
     *
     */
    enum float MIN_NORMAL = float.min_normal; // 0x1.0p-126f; // 1.17549435E-38f

    /**
     * A constant holding the smallest positive nonzero value of type
     * {@code float}, 2<sup>-149</sup>. It is equal to the
     * hexadecimal floating-point literal {@code 0x0.000002P-126f}
     * and also equal to {@code Float.intBitsToFloat(0x1)}.
     */
    enum float MIN_VALUE = float.min_10_exp; //0x0.000002P-126f; // 1.4e-45f

    /**
     * Maximum exponent a finite {@code float} variable may have.  It
     * is equal to the value returned by {@code
     * Math.getExponent(Float.MAX_VALUE)}.
     *
     */
    enum int MAX_EXPONENT = 127;

    /**
     * Minimum exponent a normalized {@code float} variable may have.
     * It is equal to the value returned by {@code
     * Math.getExponent(Float.MIN_NORMAL)}.
     *
     */
    enum int MIN_EXPONENT = -126;

    /**
     * The number of bits used to represent a {@code float} value.
     *
     */
    enum int SIZE = 32;

    /**
     * The number of bytes used to represent a {@code float} value.
     *
     */
    enum int BYTES = SIZE / 8;


    /**
     * Returns the {@code float} value corresponding to a given
     * bit representation.
     * The argument is considered to be a representation of a
     * floating-point value according to the IEEE 754 floating-point
     * "single format" bit layout.
     *
     * <p>If the argument is {@code 0x7f800000}, the result is positive
     * infinity.
     *
     * <p>If the argument is {@code 0xff800000}, the result is negative
     * infinity.
     *
     * <p>If the argument is any value in the range
     * {@code 0x7f800001} through {@code 0x7fffffff} or in
     * the range {@code 0xff800001} through
     * {@code 0xffffffff}, the result is a NaN.  No IEEE 754
     * floating-point operation provided by Java can distinguish
     * between two NaN values of the same type with different bit
     * patterns.  Distinct values of NaN are only distinguishable by
     * use of the {@code Float.floatToRawIntBits} method.
     *
     * <p>In all other cases, let <i>s</i>, <i>e</i>, and <i>m</i> be three
     * values that can be computed from the argument:
     *
     * <blockquote><pre>{@code
     * int s = ((bits >> 31) == 0) ? 1 : -1;
     * int e = ((bits >> 23) & 0xff);
     * int m = (e == 0) ?
     *                 (bits & 0x7fffff) << 1 :
     *                 (bits & 0x7fffff) | 0x800000;
     * }</pre></blockquote>
     *
     * Then the floating-point result equals the value of the mathematical
     * expression <i>s</i>&middot;<i>m</i>&middot;2<sup><i>e</i>-150</sup>.
     *
     * <p>Note that this method may not be able to return a
     * {@code float} NaN with exactly same bit pattern as the
     * {@code int} argument.  IEEE 754 distinguishes between two
     * kinds of NaNs, quiet NaNs and <i>signaling NaNs</i>.  The
     * differences between the two kinds of NaN are generally not
     * visible in Java.  Arithmetic operations on signaling NaNs turn
     * them into quiet NaNs with a different, but often similar, bit
     * pattern.  However, on some processors merely copying a
     * signaling NaN also performs that conversion.  In particular,
     * copying a signaling NaN to return it to the calling method may
     * perform this conversion.  So {@code intBitsToFloat} may
     * not be able to return a {@code float} with a signaling NaN
     * bit pattern.  Consequently, for some {@code int} values,
     * {@code floatToRawIntBits(intBitsToFloat(start))} may
     * <i>not</i> equal {@code start}.  Moreover, which
     * particular bit patterns represent signaling NaNs is platform
     * dependent; although all NaN bit patterns, quiet or signaling,
     * must be in the NaN range identified above.
     *
     * @param   bits   an integer.
     * @return  the {@code float} floating-point value with the same bit
     *          pattern.
     */
    static float intBitsToFloat(int bits) {
        implementationMissing(false);
        return 0;
    }

    /**
     * The value of the Float.
     *
     * @serial
     */
    // private  float value;

    /**
     * Constructs a newly allocated {@code Float} object that
     * represents the primitive {@code float} argument.
     *
     * @param   value   the value to be represented by the {@code Float}.
     */
    this(float value) {
        // this.value = value;
        super(value);
    }

    /**
     * Constructs a newly allocated {@code Float} object that
     * represents the argument converted to type {@code float}.
     *
     * @param   value   the value to be represented by the {@code Float}.
     */
    this(double value) {
        // this.value = cast(float)value;
        super(cast(float)value);
    }


    static float parseFloat(string s) {
        return to!float(s);
    }

    /**
     * Constructs a newly allocated {@code Float} object that
     * represents the floating-point value of type {@code float}
     * represented by the string. The string is converted to a
     * {@code float} value as if by the {@code valueOf} method.
     *
     * @param      s   a string to be converted to a {@code Float}.
     * @throws  NumberFormatException  if the string does not contain a
     *               parsable number.
     * @see        java.lang.Float#valueOf(java.lang.string)
     */
    // Float(string s) throws NumberFormatException {
    //     value = parseFloat(s);
    // }

    /**
     * Returns {@code true} if this {@code Float} value is a
     * Not-a-Number (NaN), {@code false} otherwise.
     *
     * @return  {@code true} if the value represented by this object is
     *          NaN; {@code false} otherwise.
     */
    // bool isNaN() {
    //     return isNaN(value);
    // }

    /**
     * Returns {@code true} if this {@code Float} value is
     * infinitely large in magnitude, {@code false} otherwise.
     *
     * @return  {@code true} if the value represented by this object is
     *          positive infinity or negative infinity;
     *          {@code false} otherwise.
     */
    // bool isInfinite() {
    //     return isInfinite(value);
    // }


    /**
     * Returns a {@code Float} instance representing the specified
     * {@code float} value.
     * If a new {@code Float} instance is not required, this method
     * should generally be used in preference to the constructor
     * {@link #Float(float)}, as this method is likely to yield
     * significantly better space and time performance by caching
     * frequently requested values.
     *
     * @param  f a float value.
     * @return a {@code Float} instance representing {@code f}.
     * @since  1.5
     */
    static Float valueOf(float f) {
        return new Float(f);
    }

    /**
     * Returns a hash code for a {@code double} value; compatible with
     * {@code Double.hashCode()}.
     *
     * @param value the value to hash
     * @return a hash code value for a {@code double} value.
     */
    override size_t toHash() @safe nothrow {
        return hashOf(value);
    }

}


/**
 * This class contains additional constants documenting limits of the
 * {@code float} type.
 *
 * @author Joseph D. Darcy
 */

class FloatConsts {
    /**
     * Don't let anyone instantiate this class.
     */
    private this() {}

    /**
     * The number of logical bits in the significand of a
     * {@code float} number, including the implicit bit.
     */
    enum int SIGNIFICAND_WIDTH   = 24;

    /**
     * The exponent the smallest positive {@code float} subnormal
     * value would have if it could be normalized.
     */
    enum int     MIN_SUB_EXPONENT = Float.MIN_EXPONENT -
                                                   (SIGNIFICAND_WIDTH - 1);

    /**
     * Bias used in representing a {@code float} exponent.
     */
    enum int     EXP_BIAS        = 127;

    /**
     * Bit mask to isolate the sign bit of a {@code float}.
     */
    enum int     SIGN_BIT_MASK   = 0x80000000;

    /**
     * Bit mask to isolate the exponent field of a
     * {@code float}.
     */
    enum int     EXP_BIT_MASK    = 0x7F800000;

    /**
     * Bit mask to isolate the significand field of a
     * {@code float}.
     */
    enum int     SIGNIF_BIT_MASK = 0x007FFFFF;

    // static {
    //     // verify bit masks cover all bit positions and that the bit
    //     // masks are non-overlapping
    //     assert(((SIGN_BIT_MASK | EXP_BIT_MASK | SIGNIF_BIT_MASK) == ~0) &&
    //            (((SIGN_BIT_MASK & EXP_BIT_MASK) == 0) &&
    //             ((SIGN_BIT_MASK & SIGNIF_BIT_MASK) == 0) &&
    //             ((EXP_BIT_MASK & SIGNIF_BIT_MASK) == 0)));
    // }
}
