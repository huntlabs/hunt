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

module hunt.math.BigInteger;

import hunt.Double;
import hunt.Float;
import hunt.Integer;
import hunt.Long;
import hunt.Number;

import hunt.Character;
import hunt.text.CharacterData;
import hunt.Exceptions;
import hunt.text;

import std.algorithm;
import std.conv;
import std.math;
import std.random;
import std.string;

/**
 * Immutable arbitrary-precision integers.  All operations behave as if
 * BigIntegers were represented in two's-complement notation (like Java's
 * primitive integer types).  BigInteger provides analogues to all of Java's
 * primitive integer operators, and all relevant methods from java.lang.std.math.
 * Additionally, BigInteger provides operations for modular arithmetic, GCD
 * calculation, primality testing, prime generation, bit manipulation,
 * and a few other miscellaneous operations.
 *
 * <p>Semantics of arithmetic operations exactly mimic those of Java's integer
 * arithmetic operators, as defined in <i>The Java Language Specification</i>.
 * For example, division by zero throws an {@code ArithmeticException}, and
 * division of a negative by a positive yields a negative (or zero) remainder.
 * All of the details in the Spec concerning overflow are ignored, as
 * BigIntegers are made as large as necessary to accommodate the results of an
 * operation.
 *
 * <p>Semantics of shift operations extend those of Java's shift operators
 * to allow for negative shift distances.  A right-shift with a negative
 * shift distance results in a left shift, and vice-versa.  The unsigned
 * right shift operator ({@code >>>}) is omitted, as this operation makes
 * little sense in combination with the "infinite word size" abstraction
 * provided by this class.
 *
 * <p>Semantics of bitwise logical operations exactly mimic those of Java's
 * bitwise integer operators.  The binary operators ({@code and},
 * {@code or}, {@code xor}) implicitly perform sign extension on the shorter
 * of the two operands prior to performing the operation.
 *
 * <p>Comparison operations perform signed integer comparisons, analogous to
 * those performed by Java's relational and equality operators.
 *
 * <p>Modular arithmetic operations are provided to compute residues, perform
 * exponentiation, and compute multiplicative inverses.  These methods always
 * return a non-negative result, between {@code 0} and {@code (modulus - 1)},
 * inclusive.
 *
 * <p>Bit operations operate on a single bit of the two's-complement
 * representation of their operand.  If necessary, the operand is sign-
 * extended so that it contains the designated bit.  None of the single-bit
 * operations can produce a BigInteger with a different sign from the
 * BigInteger being operated on, as they affect only a single bit, and the
 * "infinite word size" abstraction provided by this class ensures that there
 * are infinitely many "virtual sign bits" preceding each BigInteger.
 *
 * <p>For the sake of brevity and clarity, pseudo-code is used throughout the
 * descriptions of BigInteger methods.  The pseudo-code expression
 * {@code (i + j)} is shorthand for "a BigInteger whose value is
 * that of the BigInteger {@code i} plus that of the BigInteger {@code j}."
 * The pseudo-code expression {@code (i == j)} is shorthand for
 * "{@code true} if and only if the BigInteger {@code i} represents the same
 * value as the BigInteger {@code j}."  Other pseudo-code expressions are
 * interpreted similarly.
 *
 * <p>All methods and constructors in this class throw
 * {@code NullPointerException} when passed
 * a null object reference for any input parameter.
 *
 * BigInteger must support values in the range
 * -2<sup>{@code int.max}</sup> (exclusive) to
 * +2<sup>{@code int.max}</sup> (exclusive)
 * and may support values outside of that range.
 *
 * The range of probable prime values is limited and may be less than
 * the full supported positive range of {@code BigInteger}.
 * The range must be at least 1 to 2<sup>500000000</sup>.
 *
 * @implNote
 * BigInteger constructors and operations throw {@code ArithmeticException} when
 * the result is out of the supported range of
 * -2<sup>{@code int.max}</sup> (exclusive) to
 * +2<sup>{@code int.max}</sup> (exclusive).
 *
 * @see     BigDecimal
 * @jls     4.2.2 Integer Operations
 * @author  Josh Bloch
 * @author  Michael McCloskey
 * @author  Alan Eliasen
 * @author  Timothy Buktu
 * @since 1.1
 */

class BigInteger : Number {
    /**
     * The signum of this BigInteger: -1 for negative, 0 for zero, or
     * 1 for positive.  Note that the BigInteger zero <em>must</em> have
     * a signum of 0.  This is necessary to ensures that there is exactly one
     * representation for each BigInteger value.
     */
    private int _signum;

    /**
     * The magnitude of this BigInteger, in <i>big-endian</i> order: the
     * zeroth element of this array is the most-significant int of the
     * magnitude.  The magnitude must be "minimal" in that the most-significant
     * int ({@code mag[0]}) must be non-zero.  This is necessary to
     * ensure that there is exactly one representation for each BigInteger
     * value.  Note that this implies that the BigInteger zero has a
     * zero-length mag array.
     */
    private int[] mag;

    // The following fields are stable variables. A stable variable's value
    // changes at most once from the default zero value to a non-zero stable
    // value. A stable value is calculated lazily on demand.

    /**
     * One plus the bitCount of this BigInteger. This is a stable variable.
     *
     * @see #bitCount
     */
    private int bitCountPlusOne;

    /**
     * One plus the bitLength of this BigInteger. This is a stable variable.
     * (either value is acceptable).
     *
     * @see #bitLength()
     */
    private int bitLengthPlusOne;

    /**
     * Two plus the lowest set bit of this BigInteger. This is a stable variable.
     *
     * @see #getLowestSetBit
     */
    private int lowestSetBitPlusTwo;

    /**
     * Two plus the index of the lowest-order int in the magnitude of this
     * BigInteger that contains a nonzero int. This is a stable variable. The
     * least significant int has int-number 0, the next int in order of
     * increasing significance has int-number 1, and so forth.
     *
     * <p>Note: never used for a BigInteger with a magnitude of zero.
     *
     * @see #firstNonzeroIntNum()
     */
    private int firstNonzeroIntNumPlusTwo;

    /**
     * This mask is used to obtain the value of an int as if it were unsigned.
     */
    enum long LONG_MASK = 0xffffffffL;

    /**
     * This constant limits {@code mag.length} of BigIntegers to the supported
     * range.
     */
    private enum int MAX_MAG_LENGTH = int.max / int.sizeof + 1; // (1 << 26)

    /**
     * Bit lengths larger than this constant can cause overflow in searchLen
     * calculation and in BitSieve.singleSearch method.
     */
    private enum int PRIME_SEARCH_BIT_LENGTH_LIMIT = 500000000;

    /**
     * The threshold value for using Karatsuba multiplication.  If the number
     * of ints in both mag arrays are greater than this number, then
     * Karatsuba multiplication will be used.   This value is found
     * experimentally to work well.
     */
    private enum int KARATSUBA_THRESHOLD = 80;

    /**
     * The threshold value for using 3-way Toom-Cook multiplication.
     * If the number of ints in each mag array is greater than the
     * Karatsuba threshold, and the number of ints in at least one of
     * the mag arrays is greater than this threshold, then Toom-Cook
     * multiplication will be used.
     */
    private enum int TOOM_COOK_THRESHOLD = 240;

    /**
     * The threshold value for using Karatsuba squaring.  If the number
     * of ints in the number are larger than this value,
     * Karatsuba squaring will be used.   This value is found
     * experimentally to work well.
     */
    private enum int KARATSUBA_SQUARE_THRESHOLD = 128;

    /**
     * The threshold value for using Toom-Cook squaring.  If the number
     * of ints in the number are larger than this value,
     * Toom-Cook squaring will be used.   This value is found
     * experimentally to work well.
     */
    private enum int TOOM_COOK_SQUARE_THRESHOLD = 216;

    /**
     * The threshold value for using Burnikel-Ziegler division.  If the number
     * of ints in the divisor are larger than this value, Burnikel-Ziegler
     * division may be used.  This value is found experimentally to work well.
     */
    enum int BURNIKEL_ZIEGLER_THRESHOLD = 80;

    /**
     * The offset value for using Burnikel-Ziegler division.  If the number
     * of ints in the divisor exceeds the Burnikel-Ziegler threshold, and the
     * number of ints in the dividend is greater than the number of ints in the
     * divisor plus this value, Burnikel-Ziegler division will be used.  This
     * value is found experimentally to work well.
     */
    enum int BURNIKEL_ZIEGLER_OFFSET = 40;

    /**
     * The threshold value for using Schoenhage recursive base conversion. If
     * the number of ints in the number are larger than this value,
     * the Schoenhage algorithm will be used.  In practice, it appears that the
     * Schoenhage routine is faster for any threshold down to 2, and is
     * relatively flat for thresholds between 2-25, so this choice may be
     * varied within this range for very small effect.
     */
    private enum int SCHOENHAGE_BASE_CONVERSION_THRESHOLD = 20;

    /**
     * The threshold value for using squaring code to perform multiplication
     * of a {@code BigInteger} instance by itself.  If the number of ints in
     * the number are larger than this value, {@code multiply(this)} will
     * return {@code square()}.
     */
    private enum int MULTIPLY_SQUARE_THRESHOLD = 20;

    /**
     * The threshold for using an intrinsic version of
     * implMontgomeryXXX to perform Montgomery multiplication.  If the
     * number of ints in the number is more than this value we do not
     * use the intrinsic.
     */
    private enum int MONTGOMERY_INTRINSIC_THRESHOLD = 512;


    // Constructors

    /**
     * Translates a byte sub-array containing the two's-complement binary
     * representation of a BigInteger into a BigInteger.  The sub-array is
     * specified via an offset into the array and a length.  The sub-array is
     * assumed to be in <i>big-endian</i> byte-order: the most significant
     * byte is the element at index {@code off}.  The {@code val} array is
     * assumed to be unchanged for the duration of the constructor call.
     *
     * An {@code IndexOutOfBoundsException} is thrown if the length of the array
     * {@code val} is non-zero and either {@code off} is negative, {@code len}
     * is negative, or {@code off+len} is greater than the length of
     * {@code val}.
     *
     * @param  val byte array containing a sub-array which is the big-endian
     *         two's-complement binary representation of a BigInteger.
     * @param  off the start offset of the binary representation.
     * @param  len the number of bytes to use.
     * @throws NumberFormatException {@code val} is zero bytes long.
     * @throws IndexOutOfBoundsException if the provided array offset and
     *         length would cause an index into the byte array to be
     *         negative or greater than or equal to the array length.
     * @since 9
     */
    this(byte[] val, int off, int len) {
        if (val.length == 0) {
            throw new NumberFormatException("Zero length BigInteger");
        } else if ((off < 0) || (off >= cast(int)val.length) || (len < 0) ||
                   (len > val.length - off)) { // 0 <= off < val.length
            throw new IndexOutOfBoundsException();
        }

        if (val[off] < 0) {
            mag = makePositive(val, off, len);
            _signum = -1;
        } else {
            mag = stripLeadingZeroBytes(val, off, len);
            _signum = (mag.length == 0 ? 0 : 1);
        }
        if (mag.length >= MAX_MAG_LENGTH) {
            checkRange();
        }
    }

    /**
     * Translates a byte array containing the two's-complement binary
     * representation of a BigInteger into a BigInteger.  The input array is
     * assumed to be in <i>big-endian</i> byte-order: the most significant
     * byte is in the zeroth element.  The {@code val} array is assumed to be
     * unchanged for the duration of the constructor call.
     *
     * @param  val big-endian two's-complement binary representation of a
     *         BigInteger.
     * @throws NumberFormatException {@code val} is zero bytes long.
     */
    this(byte[] val) {
        this(val, 0, cast(int)val.length);
    }

    /**
     * This private constructor translates an int array containing the
     * two's-complement binary representation of a BigInteger into a
     * BigInteger. The input array is assumed to be in <i>big-endian</i>
     * int-order: the most significant int is in the zeroth element.  The
     * {@code val} array is assumed to be unchanged for the duration of
     * the constructor call.
     */
    private this(int[] val) {
        if (val.length == 0)
            throw new NumberFormatException("Zero length BigInteger");

        if (val[0] < 0) {
            mag = makePositive(val);
            _signum = -1;
        } else {
            mag = trustedStripLeadingZeroInts(val);
            _signum = (mag.length == 0 ? 0 : 1);
        }
        if (mag.length >= MAX_MAG_LENGTH) {
            checkRange();
        }
    }

    /**
     * Translates the sign-magnitude representation of a BigInteger into a
     * BigInteger.  The sign is represented as an integer signum value: -1 for
     * negative, 0 for zero, or 1 for positive.  The magnitude is a sub-array of
     * a byte array in <i>big-endian</i> byte-order: the most significant byte
     * is the element at index {@code off}.  A zero value of the length
     * {@code len} is permissible, and will result in a BigInteger value of 0,
     * whether signum is -1, 0 or 1.  The {@code magnitude} array is assumed to
     * be unchanged for the duration of the constructor call.
     *
     * An {@code IndexOutOfBoundsException} is thrown if the length of the array
     * {@code magnitude} is non-zero and either {@code off} is negative,
     * {@code len} is negative, or {@code off+len} is greater than the length of
     * {@code magnitude}.
     *
     * @param  signum signum of the number (-1 for negative, 0 for zero, 1
     *         for positive).
     * @param  magnitude big-endian binary representation of the magnitude of
     *         the number.
     * @param  off the start offset of the binary representation.
     * @param  len the number of bytes to use.
     * @throws NumberFormatException {@code signum} is not one of the three
     *         legal values (-1, 0, and 1), or {@code signum} is 0 and
     *         {@code magnitude} contains one or more non-zero bytes.
     * @throws IndexOutOfBoundsException if the provided array offset and
     *         length would cause an index into the byte array to be
     *         negative or greater than or equal to the array length.
     * @since 9
     */
    this(int signum, byte[] magnitude, int off, int len) {
        if (signum < -1 || signum > 1) {
            throw(new NumberFormatException("Invalid signum value"));
        } else if ((off < 0) || (len < 0) ||
            (len > 0 &&
                ((off >= magnitude.length) ||
                 (len > magnitude.length - off)))) { // 0 <= off < magnitude.length
            throw new IndexOutOfBoundsException();
        }

        // stripLeadingZeroBytes() returns a zero length array if len == 0
        this.mag = stripLeadingZeroBytes(magnitude, off, len);

        if (this.mag.length == 0) {
            this._signum = 0;
        } else {
            if (signum == 0)
                throw(new NumberFormatException("signum-magnitude mismatch"));
            this._signum = signum;
        }
        if (mag.length >= MAX_MAG_LENGTH) {
            checkRange();
        }
    }

    /**
     * Translates the sign-magnitude representation of a BigInteger into a
     * BigInteger.  The sign is represented as an integer signum value: -1 for
     * negative, 0 for zero, or 1 for positive.  The magnitude is a byte array
     * in <i>big-endian</i> byte-order: the most significant byte is the
     * zeroth element.  A zero-length magnitude array is permissible, and will
     * result in a BigInteger value of 0, whether signum is -1, 0 or 1.  The
     * {@code magnitude} array is assumed to be unchanged for the duration of
     * the constructor call.
     *
     * @param  signum signum of the number (-1 for negative, 0 for zero, 1
     *         for positive).
     * @param  magnitude big-endian binary representation of the magnitude of
     *         the number.
     * @throws NumberFormatException {@code signum} is not one of the three
     *         legal values (-1, 0, and 1), or {@code signum} is 0 and
     *         {@code magnitude} contains one or more non-zero bytes.
     */
    this(int signum, byte[] magnitude) {
         this(signum, magnitude, 0, cast(int)magnitude.length);
    }

    /**
     * A constructor for internal use that translates the sign-magnitude
     * representation of a BigInteger into a BigInteger. It checks the
     * arguments and copies the magnitude so this constructor would be
     * safe for external use.  The {@code magnitude} array is assumed to be
     * unchanged for the duration of the constructor call.
     */
    private this(int signum, int[] magnitude) {
        this.mag = stripLeadingZeroInts(magnitude);

        if (signum < -1 || signum > 1)
            throw(new NumberFormatException("Invalid signum value"));

        if (this.mag.length == 0) {
            this._signum = 0;
        } else {
            if (signum == 0)
                throw(new NumberFormatException("signum-magnitude mismatch"));
            this._signum = signum;
        }
        if (mag.length >= MAX_MAG_LENGTH) {
            checkRange();
        }
    }

    /**
     * Translates the string representation of a BigInteger in the
     * specified radix into a BigInteger.  The string representation
     * consists of an optional minus or plus sign followed by a
     * sequence of one or more digits in the specified radix.  The
     * character-to-digit mapping is provided by {@code
     * CharacterHelper.digit}.  The string may not contain any extraneous
     * characters (whitespace, for example).
     *
     * @param val string representation of BigInteger.
     * @param radix radix to be used in interpreting {@code val}.
     * @throws NumberFormatException {@code val} is not a valid representation
     *         of a BigInteger in the specified radix, or {@code radix} is
     *         outside the range from {@link Character#MIN_RADIX} to
     *         {@link Character#MAX_RADIX}, inclusive.
     * @see    Character#digit
     */
    this(string val, int radix) {
        int cursor = 0, numDigits;
        int len = cast(int)val.length;

        if (radix < Character.MIN_RADIX || radix > Character.MAX_RADIX)
            throw new NumberFormatException("Radix out of range");
        if (len == 0)
            throw new NumberFormatException("Zero length BigInteger");

        // Check for at most one leading sign
        int sign = 1;
        ptrdiff_t index1 = val.lastIndexOf('-');
        ptrdiff_t index2 = val.lastIndexOf('+');
        if (index1 >= 0) {
            if (index1 != 0 || index2 >= 0) {
                throw new NumberFormatException("Illegal embedded sign character");
            }
            sign = -1;
            cursor = 1;
        } else if (index2 >= 0) {
            if (index2 != 0) {
                throw new NumberFormatException("Illegal embedded sign character");
            }
            cursor = 1;
        }
        if (cursor == len)
            throw new NumberFormatException("Zero length BigInteger");

        // Skip leading zeros and compute number of digits in magnitude
        while (cursor < len &&
               CharacterHelper.digit(val[cursor], radix) == 0) {
            cursor++;
        }

        if (cursor == len) {
            _signum = 0;
            mag = ZERO.mag;
            return;
        }

        numDigits = len - cursor;
        _signum = sign;

        // Pre-allocate array of expected size. May be too large but can
        // never be too small. Typically exact.
        long numBits = ((numDigits * bitsPerDigit[radix]) >>> 10) + 1;
        if (numBits + 31 >= (1L << 32)) {
            reportOverflow();
        }
        int numWords = cast(int) (numBits + 31) >>> 5;
        int[] magnitude = new int[numWords];

        // Process first (potentially short) digit group
        int firstGroupLen = numDigits % digitsPerInt[radix];
        if (firstGroupLen == 0)
            firstGroupLen = digitsPerInt[radix];
        string group = val.substring(cursor, cursor += firstGroupLen);
        magnitude[numWords - 1] = to!int(group, radix);
        if (magnitude[numWords - 1] < 0)
            throw new NumberFormatException("Illegal digit");

        // Process remaining digit groups
        int superRadix = intRadix[radix];
        int groupVal = 0;
        while (cursor < len) {
            group = val.substring(cursor, cursor += digitsPerInt[radix]);
            groupVal = to!int(group, radix);
            if (groupVal < 0)
                throw new NumberFormatException("Illegal digit");
            destructiveMulAdd(magnitude, superRadix, groupVal);
        }
        // Required for cases where the array was overallocated.
        mag = trustedStripLeadingZeroInts(magnitude);
        if (mag.length >= MAX_MAG_LENGTH) {
            checkRange();
        }
    }

    /*
     * Constructs a new BigInteger using a char array with radix=10.
     * Sign is precalculated outside and not allowed in the val. The {@code val}
     * array is assumed to be unchanged for the duration of the constructor
     * call.
     */
    this(char[] val, int sign, int len) {
        int cursor = 0, numDigits;

        // Skip leading zeros and compute number of digits in magnitude
        while (cursor < len && CharacterHelper.digit(val[cursor], 10) == 0) {
            cursor++;
        }
        if (cursor == len) {
            _signum = 0;
            mag = ZERO.mag;
            return;
        }

        numDigits = len - cursor;
        _signum = sign;
        // Pre-allocate array of expected size
        int numWords;
        if (len < 10) {
            numWords = 1;
        } else {
            long numBits = ((numDigits * bitsPerDigit[10]) >>> 10) + 1;
            if (numBits + 31 >= (1L << 32)) {
                reportOverflow();
            }
            numWords = cast(int) (numBits + 31) >>> 5;
        }
        int[] magnitude = new int[numWords];

        // Process first (potentially short) digit group
        int firstGroupLen = numDigits % digitsPerInt[10];
        if (firstGroupLen == 0)
            firstGroupLen = digitsPerInt[10];
        magnitude[numWords - 1] = parseInt(val, cursor,  cursor += firstGroupLen);

        // Process remaining digit groups
        while (cursor < len) {
            int groupVal = parseInt(val, cursor, cursor += digitsPerInt[10]);
            destructiveMulAdd(magnitude, intRadix[10], groupVal);
        }
        mag = trustedStripLeadingZeroInts(magnitude);
        if (mag.length >= MAX_MAG_LENGTH) {
            checkRange();
        }
    }

    // Create an integer with the digits between the two indexes
    // Assumes start < end. The result may be negative, but it
    // is to be treated as an unsigned value.
    private int parseInt(char[] source, int start, int end) {
        int result = CharacterHelper.digit(source[start++], 10);
        if (result == -1)
            throw new NumberFormatException(cast(string)(source));

        for (int index = start; index < end; index++) {
            int nextVal = CharacterHelper.digit(source[index], 10);
            if (nextVal == -1)
                throw new NumberFormatException(cast(string)(source));
            result = 10*result + nextVal;
        }

        return result;
    }

    // bitsPerDigit in the given radix times 1024
    // Rounded up to avoid underallocation.
    private enum long[] bitsPerDigit = [ 0, 0,
        1024, 1624, 2048, 2378, 2648, 2875, 3072, 3247, 3402, 3543, 3672,
        3790, 3899, 4001, 4096, 4186, 4271, 4350, 4426, 4498, 4567, 4633,
        4696, 4756, 4814, 4870, 4923, 4975, 5025, 5074, 5120, 5166, 5210,
                                           5253, 5295];

    // Multiply x array times word y in place, and add word z
    private static void destructiveMulAdd(int[] x, int y, int z) {
        // Perform the multiplication word by word
        long ylong = y & LONG_MASK;
        long zlong = z & LONG_MASK;
        int len = cast(int)x.length;

        long product = 0;
        long carry = 0;
        for (int i = len-1; i >= 0; i--) {
            product = ylong * (x[i] & LONG_MASK) + carry;
            x[i] = cast(int)product;
            carry = product >>> 32;
        }

        // Perform the addition
        long sum = (x[len-1] & LONG_MASK) + zlong;
        x[len-1] = cast(int)sum;
        carry = sum >>> 32;
        for (int i = len-2; i >= 0; i--) {
            sum = (x[i] & LONG_MASK) + carry;
            x[i] = cast(int)sum;
            carry = sum >>> 32;
        }
    }

    /**
     * Translates the decimal string representation of a BigInteger into a
     * BigInteger.  The string representation consists of an optional minus
     * sign followed by a sequence of one or more decimal digits.  The
     * character-to-digit mapping is provided by {@code CharacterHelper.digit}.
     * The string may not contain any extraneous characters (whitespace, for
     * example).
     *
     * @param val decimal string representation of BigInteger.
     * @throws NumberFormatException {@code val} is not a valid representation
     *         of a BigInteger.
     * @see    Character#digit
     */
    this(string val) {
        this(val, 10);
    }

    /**
     * Constructs a randomly generated BigInteger, uniformly distributed over
     * the range 0 to (2<sup>{@code numBits}</sup> - 1), inclusive.
     * The uniformity of the distribution assumes that a fair source of random
     * bits is provided in {@code rnd}.  Note that this constructor always
     * constructs a non-negative BigInteger.
     *
     * @param  numBits maximum bitLength of the new BigInteger.
     * @param  rnd source of randomness to be used in computing the new
     *         BigInteger.
     * @throws IllegalArgumentException {@code numBits} is negative.
     * @see #bitLength()
     */
    this(int numBits, Random* rnd) {
        this(1, randomBits(numBits, rnd));
    }

    private static byte[] randomBits(int numBits, Random* rnd) {
        if (numBits < 0)
            throw new IllegalArgumentException("numBits must be non-negative");
        int numBytes = cast(int)((cast(long)numBits+7)/8); // avoid overflow
        byte[] buffer = new byte[numBytes];

        // Generate random bytes and mask out any excess bits
        if (numBytes > 0) {
            for(int i=0; i<numBytes; i++) {
                buffer[i] = uniform(byte.min, byte.max, rnd);
            }
            int excessBits = 8*numBytes - numBits;
            buffer[0] &= (1 << (8-excessBits)) - 1;
        }
        return buffer;
    }

    /**
     * Constructs a randomly generated positive BigInteger that is probably
     * prime, with the specified bitLength.
     *
     * @apiNote It is recommended that the {@link #probablePrime probablePrime}
     * method be used in preference to this constructor unless there
     * is a compelling need to specify a certainty.
     *
     * @param  bitLength bitLength of the returned BigInteger.
     * @param  certainty a measure of the uncertainty that the caller is
     *         willing to tolerate.  The probability that the new BigInteger
     *         represents a prime number will exceed
     *         (1 - 1/2<sup>{@code certainty}</sup>).  The execution time of
     *         this constructor is proportional to the value of this parameter.
     * @param  rnd source of random bits used to select candidates to be
     *         tested for primality.
     * @throws ArithmeticException {@code bitLength < 2} or {@code bitLength} is too large.
     * @see    #bitLength()
     */
    this(int bitLength, int certainty, Random* rnd) {
        BigInteger prime;

        if (bitLength < 2)
            throw new ArithmeticException("bitLength < 2");
        prime = (bitLength < SMALL_PRIME_THRESHOLD
                                ? smallPrime(bitLength, certainty, rnd)
                                : largePrime(bitLength, certainty, rnd));
        _signum = 1;
        mag = prime.mag;
    }

    // Minimum size in bits that the requested prime number has
    // before we use the large prime number generating algorithms.
    // The cutoff of 95 was chosen empirically for best performance.
    private enum int SMALL_PRIME_THRESHOLD = 95;

    // Certainty required to meet the spec of probablePrime
    private enum int DEFAULT_PRIME_CERTAINTY = 100;

    /**
     * Returns a positive BigInteger that is probably prime, with the
     * specified bitLength. The probability that a BigInteger returned
     * by this method is composite does not exceed 2<sup>-100</sup>.
     *
     * @param  bitLength bitLength of the returned BigInteger.
     * @param  rnd source of random bits used to select candidates to be
     *         tested for primality.
     * @return a BigInteger of {@code bitLength} bits that is probably prime
     * @throws ArithmeticException {@code bitLength < 2} or {@code bitLength} is too large.
     * @see    #bitLength()
     * @since 1.4
     */
    // static BigInteger probablePrime(int bitLength, Random* rnd) {
    //     if (bitLength < 2)
    //         throw new ArithmeticException("bitLength < 2");

    //     return (bitLength < SMALL_PRIME_THRESHOLD ?
    //             smallPrime(bitLength, DEFAULT_PRIME_CERTAINTY, rnd) :
    //             largePrime(bitLength, DEFAULT_PRIME_CERTAINTY, rnd));
    // }

    /**
     * Find a random number of the specified bitLength that is probably prime.
     * This method is used for smaller primes, its performance degrades on
     * larger bitlengths.
     *
     * This method assumes bitLength > 1.
     */
    private static BigInteger smallPrime(int bitLength, int certainty, Random* rnd) {
        int magLen = (bitLength + 31) >>> 5;
        int[] temp = new int[magLen];
        int highBit = 1 << ((bitLength+31) & 0x1f);  // High bit of high int
        int highMask = (highBit << 1) - 1;  // Bits to keep in high int

        while (true) {
            // Construct a candidate
            for (int i=0; i < magLen; i++)
                temp[i] = uniform(int.min, int.max, rnd);
            temp[0] = (temp[0] & highMask) | highBit;  // Ensure exact length
            if (bitLength > 2)
                temp[magLen-1] |= 1;  // Make odd if bitlen > 2

            BigInteger p = new BigInteger(temp, 1);

            // Do cheap "pre-test" if applicable
            if (bitLength > 6) {
                long r = p.remainder(SMALL_PRIME_PRODUCT).longValue();
                if ((r%3==0)  || (r%5==0)  || (r%7==0)  || (r%11==0) ||
                    (r%13==0) || (r%17==0) || (r%19==0) || (r%23==0) ||
                    (r%29==0) || (r%31==0) || (r%37==0) || (r%41==0))
                    continue; // Candidate is composite; try another
            }

            // All candidates of bitLength 2 and 3 are prime by this point
            if (bitLength < 4)
                return p;

            // Do expensive test if we survive pre-test (or it's inapplicable)
            if (p.primeToCertainty(certainty, rnd))
                return p;
        }
    }

    private __gshared BigInteger SMALL_PRIME_PRODUCT;

    shared static this() {
        SMALL_PRIME_PRODUCT = valueOf(3L*5*7*11*13*17*19*23*29*31*37*41);
    }

    /**
     * Find a random number of the specified bitLength that is probably prime.
     * This method is more appropriate for larger bitlengths since it uses
     * a sieve to eliminate most composites before using a more expensive
     * test.
     */
    private static BigInteger largePrime(int bitLength, int certainty, Random* rnd) {
        BigInteger p;
        p = new BigInteger(bitLength, rnd).setBit(bitLength-1);
        p.mag[$-1] &= 0xfffffffe;

        // Use a sieve length likely to contain the next prime number
        int searchLen = getPrimeSearchLen(bitLength);
        BitSieve searchSieve = new BitSieve(p, searchLen);
        BigInteger candidate = searchSieve.retrieve(p, certainty, rnd);

        while ((candidate is null) || (candidate.bitLength() != bitLength)) {
            p = p.add(BigInteger.valueOf(2*searchLen));
            if (p.bitLength() != bitLength)
                p = new BigInteger(bitLength, rnd).setBit(bitLength-1);
            p.mag[$-1] &= 0xfffffffe;
            searchSieve = new BitSieve(p, searchLen);
            candidate = searchSieve.retrieve(p, certainty, rnd);
        }
        return candidate;
    }

   /**
    * Returns the first integer greater than this {@code BigInteger} that
    * is probably prime.  The probability that the number returned by this
    * method is composite does not exceed 2<sup>-100</sup>. This method will
    * never skip over a prime when searching: if it returns {@code p}, there
    * is no prime {@code q} such that {@code this < q < p}.
    *
    * @return the first integer greater than this {@code BigInteger} that
    *         is probably prime.
    * @throws ArithmeticException {@code this < 0} or {@code this} is too large.
    * @since 1.5
    */
    BigInteger nextProbablePrime() {
        if (this._signum < 0)
            throw new ArithmeticException("start < 0: " ~ this.toString());

        // Handle trivial cases
        if ((this._signum == 0) || this.equals(ONE))
            return TWO;

        BigInteger result = this.add(ONE);

        // Fastpath for small numbers
        if (result.bitLength() < SMALL_PRIME_THRESHOLD) {

            // Ensure an odd number
            if (!result.testBit(0))
                result = result.add(ONE);

            while (true) {
                // Do cheap "pre-test" if applicable
                if (result.bitLength() > 6) {
                    long r = result.remainder(SMALL_PRIME_PRODUCT).longValue();
                    if ((r%3==0)  || (r%5==0)  || (r%7==0)  || (r%11==0) ||
                        (r%13==0) || (r%17==0) || (r%19==0) || (r%23==0) ||
                        (r%29==0) || (r%31==0) || (r%37==0) || (r%41==0)) {
                        result = result.add(TWO);
                        continue; // Candidate is composite; try another
                    }
                }

                // All candidates of bitLength 2 and 3 are prime by this point
                if (result.bitLength() < 4)
                    return result;

                // The expensive test
                if (result.primeToCertainty(DEFAULT_PRIME_CERTAINTY, null))
                    return result;

                result = result.add(TWO);
            }
        }

        // Start at previous even number
        if (result.testBit(0))
            result = result.subtract(ONE);

        // Looking for the next large prime
        int searchLen = getPrimeSearchLen(result.bitLength());

        while (true) {
           BitSieve searchSieve = new BitSieve(result, searchLen);
           BigInteger candidate = searchSieve.retrieve(result,
                                                 DEFAULT_PRIME_CERTAINTY, null);
           if (candidate !is null)
               return candidate;
           result = result.add(BigInteger.valueOf(2 * searchLen));
        }
    }

    private static int getPrimeSearchLen(int bitLength) {
        if (bitLength > PRIME_SEARCH_BIT_LENGTH_LIMIT + 1) {
            throw new ArithmeticException("Prime search implementation restriction on bitLength");
        }
        return bitLength / 20 * 64;
    }

    /**
     * Returns {@code true} if this BigInteger is probably prime,
     * {@code false} if it's definitely composite.
     *
     * This method assumes bitLength > 2.
     *
     * @param  certainty a measure of the uncertainty that the caller is
     *         willing to tolerate: if the call returns {@code true}
     *         the probability that this BigInteger is prime exceeds
     *         {@code (1 - 1/2<sup>certainty</sup>)}.  The execution time of
     *         this method is proportional to the value of this parameter.
     * @return {@code true} if this BigInteger is probably prime,
     *         {@code false} if it's definitely composite.
     */
    bool primeToCertainty(int certainty, Random* random) {
        int rounds = 0;
        int n = (std.algorithm.min(certainty, int.max-1)+1)/2;

        // The relationship between the certainty and the number of rounds
        // we perform is given in the draft standard ANSI X9.80, "PRIME
        // NUMBER GENERATION, PRIMALITY TESTING, AND PRIMALITY CERTIFICATES".
        int sizeInBits = this.bitLength();
        if (sizeInBits < 100) {
            rounds = 50;
            rounds = n < rounds ? n : rounds;
            return passesMillerRabin(rounds, random);
        }

        if (sizeInBits < 256) {
            rounds = 27;
        } else if (sizeInBits < 512) {
            rounds = 15;
        } else if (sizeInBits < 768) {
            rounds = 8;
        } else if (sizeInBits < 1024) {
            rounds = 4;
        } else {
            rounds = 2;
        }
        rounds = n < rounds ? n : rounds;

        return passesMillerRabin(rounds, random) && passesLucasLehmer();
    }

    /**
     * Returns true iff this BigInteger is a Lucas-Lehmer probable prime.
     *
     * The following assumptions are made:
     * This BigInteger is a positive, odd number.
     */
    private bool passesLucasLehmer() {
        BigInteger thisPlusOne = this.add(ONE);

        // Step 1
        int d = 5;
        while (jacobiSymbol(d, this) != -1) {
            // 5, -7, 9, -11, ...
            d = (d < 0) ? std.math.abs(d)+2 : -(d+2);
        }

        // Step 2
        BigInteger u = lucasLehmerSequence(d, thisPlusOne, this);

        // Step 3
        return u.mod(this).equals(ZERO);
    }

    /**
     * Computes Jacobi(p,n).
     * Assumes n positive, odd, n>=3.
     */
    private static int jacobiSymbol(int p, BigInteger n) {
        if (p == 0)
            return 0;

        // Algorithm and comments adapted from Colin Plumb's C library.
        int j = 1;
        int u = n.mag[$-1];

        // Make p positive
        if (p < 0) {
            p = -p;
            int n8 = u & 7;
            if ((n8 == 3) || (n8 == 7))
                j = -j; // 3 (011) or 7 (111) mod 8
        }

        // Get rid of factors of 2 in p
        while ((p & 3) == 0)
            p >>= 2;
        if ((p & 1) == 0) {
            p >>= 1;
            if (((u ^ (u>>1)) & 2) != 0)
                j = -j; // 3 (011) or 5 (101) mod 8
        }
        if (p == 1)
            return j;
        // Then, apply quadratic reciprocity
        if ((p & u & 2) != 0)   // p = u = 3 (mod 4)?
            j = -j;
        // And reduce u mod p
        u = n.mod(BigInteger.valueOf(p)).intValue();

        // Now compute Jacobi(u,p), u < p
        while (u != 0) {
            while ((u & 3) == 0)
                u >>= 2;
            if ((u & 1) == 0) {
                u >>= 1;
                if (((p ^ (p>>1)) & 2) != 0)
                    j = -j;     // 3 (011) or 5 (101) mod 8
            }
            if (u == 1)
                return j;
            // Now both u and p are odd, so use quadratic reciprocity
            assert (u < p);
            int t = u; u = p; p = t;
            if ((u & p & 2) != 0) // u = p = 3 (mod 4)?
                j = -j;
            // Now u >= p, so it can be reduced
            u %= p;
        }
        return 0;
    }

    private static BigInteger lucasLehmerSequence(int z, BigInteger k, BigInteger n) {
        BigInteger d = BigInteger.valueOf(z);
        BigInteger u = ONE; BigInteger u2;
        BigInteger v = ONE; BigInteger v2;

        for (int i=k.bitLength()-2; i >= 0; i--) {
            u2 = u.multiply(v).mod(n);

            v2 = v.square().add(d.multiply(u.square())).mod(n);
            if (v2.testBit(0))
                v2 = v2.subtract(n);

            v2 = v2.shiftRight(1);

            u = u2; v = v2;
            if (k.testBit(i)) {
                u2 = u.add(v).mod(n);
                if (u2.testBit(0))
                    u2 = u2.subtract(n);

                u2 = u2.shiftRight(1);
                v2 = v.add(d.multiply(u)).mod(n);
                if (v2.testBit(0))
                    v2 = v2.subtract(n);
                v2 = v2.shiftRight(1);

                u = u2; v = v2;
            }
        }
        return u;
    }

    /**
     * Returns true iff this BigInteger passes the specified number of
     * Miller-Rabin tests. This test is taken from the DSA spec (NIST FIPS
     * 186-2).
     *
     * The following assumptions are made:
     * This BigInteger is a positive, odd number greater than 2.
     * iterations<=50.
     */
    private bool passesMillerRabin(int iterations, Random* rnd) {
        // Find a and m such that m is odd and this == 1 + 2**a * m
        BigInteger thisMinusOne = this.subtract(ONE);
        BigInteger m = thisMinusOne;
        int a = m.getLowestSetBit();
        m = m.shiftRight(a);

        // Do the tests
        // if (rnd is null) {
        //     rnd = ThreadLocalRandom.current();
        // }
        for (int i=0; i < iterations; i++) {
            // Generate a uniform random on (1, this)
            BigInteger b;
            do {
                b = new BigInteger(this.bitLength(), rnd);
            } while (b.compareTo(ONE) <= 0 || b.compareTo(this) >= 0);

            int j = 0;
            BigInteger z = b.modPow(m, this);
            while (!((j == 0 && z.equals(ONE)) || z.equals(thisMinusOne))) {
                if (j > 0 && z.equals(ONE) || ++j == a)
                    return false;
                z = z.modPow(TWO, this);
            }
        }
        return true;
    }

    /**
     * This internal constructor differs from its cousin
     * with the arguments reversed in two ways: it assumes that its
     * arguments are correct, and it doesn't copy the magnitude array.
     */
    this(int[] magnitude, int signum) {
        this._signum = (magnitude.length == 0 ? 0 : signum);
        this.mag = magnitude;
        if (mag.length >= MAX_MAG_LENGTH) {
            checkRange();
        }
    }

    /**
     * This private constructor is for internal use and assumes that its
     * arguments are correct.  The {@code magnitude} array is assumed to be
     * unchanged for the duration of the constructor call.
     */
    private this(byte[] magnitude, int signum) {
        this._signum = (magnitude.length == 0 ? 0 : signum);
        this.mag = stripLeadingZeroBytes(magnitude, 0, cast(int)magnitude.length);
        if (mag.length >= MAX_MAG_LENGTH) {
            checkRange();
        }
    }

    /**
     * Throws an {@code ArithmeticException} if the {@code BigInteger} would be
     * out of the supported range.
     *
     * @throws ArithmeticException if {@code this} exceeds the supported range.
     */
    private void checkRange() {
        if (mag.length > MAX_MAG_LENGTH || mag.length == MAX_MAG_LENGTH && mag[0] < 0) {
            reportOverflow();
        }
    }

    private static void reportOverflow() {
        throw new ArithmeticException("BigInteger would overflow supported range");
    }

    //Static Factory Methods

    /**
     * Returns a BigInteger whose value is equal to that of the
     * specified {@code long}.
     *
     * @apiNote This static factory method is provided in preference
     * to a ({@code long}) constructor because it allows for reuse of
     * frequently used BigIntegers.
     *
     * @param  val value of the BigInteger to return.
     * @return a BigInteger with the specified value.
     */
    static BigInteger valueOf(long val) {
        // If -MAX_CONSTANT < val < MAX_CONSTANT, return stashed constant
        if (val == 0)
            return ZERO;
        if (val > 0 && val <= MAX_CONSTANT)
            return posConst[cast(int) val];
        else if (val < 0 && val >= -MAX_CONSTANT)
            return negConst[cast(int) -val];

        return new BigInteger(val);
    }

    /**
     * Constructs a BigInteger with the specified value, which may not be zero.
     */
    private this(long val) {
        if (val < 0) {
            val = -val;
            _signum = -1;
        } else {
            _signum = 1;
        }

        int highWord = cast(int)(val >>> 32);
        if (highWord == 0) {
            mag = new int[1];
            mag[0] = cast(int)val;
        } else {
            mag = new int[2];
            mag[0] = highWord;
            mag[1] = cast(int)val;
        }
    }

    /**
     * Returns a BigInteger with the given two's complement representation.
     * Assumes that the input array will not be modified (the returned
     * BigInteger will reference the input array if feasible).
     */
    private static BigInteger valueOf(int[] val) {
        return (val[0] > 0 ? new BigInteger(val, 1) : new BigInteger(val));
    }

    // Constants

    /**
     * Initialize static constant array when class is loaded.
     */
    private enum int MAX_CONSTANT = 16;
    private __gshared BigInteger[] posConst;
    private __gshared BigInteger[] negConst;

    /**
     * The cache of powers of each radix.  This allows us to not have to
     * recalculate powers of radix^(2^n) more than once.  This speeds
     * Schoenhage recursive base conversion significantly.
     */
    private __gshared BigInteger[][] powerCache;

    /** The cache of logarithms of radices for base conversion. */
    private __gshared double[] logCache;

    /** The natural log of 2.  This is used in computing cache indices. */
    private __gshared immutable double LOG_TWO;

    shared static this() {
        LOG_TWO = std.math.log(2.0);
        posConst = new BigInteger[MAX_CONSTANT+1];
        negConst = new BigInteger[MAX_CONSTANT+1];

        for (int i = 1; i <= MAX_CONSTANT; i++) {
            int[] magnitude = [i];
            posConst[i] = new BigInteger(magnitude,  1);
            negConst[i] = new BigInteger(magnitude, -1);
        }

        /*
         * Initialize the cache of radix^(2^x) values used for base conversion
         * with just the very first value.  Additional values will be created
         * on demand.
         */
        powerCache = new BigInteger[][Character.MAX_RADIX+1];
        logCache = new double[Character.MAX_RADIX+1];

        for (int i=Character.MIN_RADIX; i <= Character.MAX_RADIX; i++) {
            powerCache[i] = [BigInteger.valueOf(i)];
            logCache[i] = std.math.log(i);
        }
    }

    /**
     * The BigInteger constant zero.
     *
     * @since   1.2
     */
    __gshared static BigInteger ZERO;

    /**
     * The BigInteger constant one.
     *
     * @since   1.2
     */
    __gshared static BigInteger ONE;

    /**
     * The BigInteger constant two.
     *
     * @since   9
     */
    __gshared static BigInteger TWO;

    /**
     * The BigInteger constant -1.  (Not exported.)
     */
    private __gshared static BigInteger NEGATIVE_ONE;

    /**
     * The BigInteger constant ten.
     *
     * @since   1.5
     */
    __gshared static BigInteger TEN;

    shared static this() {
        ZERO = new BigInteger(cast(byte[])[], 0);
        ONE = valueOf(1);
        TWO = valueOf(2);
        NEGATIVE_ONE = valueOf(-1);
        TEN = valueOf(10);
    }

    // Arithmetic Operations

    /**
     * Returns a BigInteger whose value is {@code (this + val)}.
     *
     * @param  val value to be added to this BigInteger.
     * @return {@code this + val}
     */
    BigInteger add(BigInteger val) {
        if (val._signum == 0)
            return this;
        if (_signum == 0)
            return val;
        if (val._signum == signum)
            return new BigInteger(add(mag, val.mag), signum);

        int cmp = compareMagnitude(val);
        if (cmp == 0)
            return ZERO;
        int[] resultMag = (cmp > 0 ? subtract(mag, val.mag)
                           : subtract(val.mag, mag));
        resultMag = trustedStripLeadingZeroInts(resultMag);

        return new BigInteger(resultMag, cmp == signum ? 1 : -1);
    }

    /**
     * Package private methods used by BigDecimal code to add a BigInteger
     * with a long. Assumes val is not equal to INFLATED.
     */
    BigInteger add(long val) {
        if (val == 0)
            return this;
        if (_signum == 0)
            return valueOf(val);
        if (Long.signum(val) == signum)
            return new BigInteger(add(mag, std.math.abs(val)), signum);
        int cmp = compareMagnitude(val);
        if (cmp == 0)
            return ZERO;
        int[] resultMag = (cmp > 0 ? subtract(mag, std.math.abs(val)) : subtract(std.math.abs(val), mag));
        resultMag = trustedStripLeadingZeroInts(resultMag);
        return new BigInteger(resultMag, cmp == signum ? 1 : -1);
    }

    /**
     * Adds the contents of the int array x and long value val. This
     * method allocates a new int array to hold the answer and returns
     * a reference to that array.  Assumes x.length &gt; 0 and val is
     * non-negative
     */
    private static int[] add(int[] x, long val) {
        int[] y;
        long sum = 0;
        int xIndex = cast(int)x.length;
        int[] result;
        int highWord = cast(int)(val >>> 32);
        if (highWord == 0) {
            result = new int[xIndex];
            sum = (x[--xIndex] & LONG_MASK) + val;
            result[xIndex] = cast(int)sum;
        } else {
            if (xIndex == 1) {
                result = new int[2];
                sum = val  + (x[0] & LONG_MASK);
                result[1] = cast(int)sum;
                result[0] = cast(int)(sum >>> 32);
                return result;
            } else {
                result = new int[xIndex];
                sum = (x[--xIndex] & LONG_MASK) + (val & LONG_MASK);
                result[xIndex] = cast(int)sum;
                sum = (x[--xIndex] & LONG_MASK) + (highWord & LONG_MASK) + (sum >>> 32);
                result[xIndex] = cast(int)sum;
            }
        }
        // Copy remainder of longer number while carry propagation is required
        bool carry = (sum >>> 32 != 0);
        while (xIndex > 0 && carry)
            carry = ((result[--xIndex] = x[xIndex] + 1) == 0);
        // Copy remainder of longer number
        while (xIndex > 0)
            result[--xIndex] = x[xIndex];
        // Grow result if necessary
        if (carry) {
            size_t len = cast(int)result.length;
            int[] bigger = new int[len + 1];
            // System.arraycopy(result, 0, bigger, 1, result.length);
            bigger[1 .. len+1] = result[0..$];
            bigger[0] = 0x01;
            return bigger;
        }
        return result;
    }

    /**
     * Adds the contents of the int arrays x and y. This method allocates
     * a new int array to hold the answer and returns a reference to that
     * array.
     */
    private static int[] add(int[] x, int[] y) {
        // If x is shorter, swap the two arrays
        if (x.length < y.length) {
            int[] tmp = x;
            x = y;
            y = tmp;
        }

        int xIndex = cast(int)x.length;
        int yIndex = cast(int)y.length;
        int[] result = new int[xIndex];
        long sum = 0;
        if (yIndex == 1) {
            sum = (x[--xIndex] & LONG_MASK) + (y[0] & LONG_MASK) ;
            result[xIndex] = cast(int)sum;
        } else {
            // Add common parts of both numbers
            while (yIndex > 0) {
                sum = (x[--xIndex] & LONG_MASK) +
                      (y[--yIndex] & LONG_MASK) + (sum >>> 32);
                result[xIndex] = cast(int)sum;
            }
        }
        // Copy remainder of longer number while carry propagation is required
        bool carry = (sum >>> 32 != 0);
        while (xIndex > 0 && carry)
            carry = ((result[--xIndex] = x[xIndex] + 1) == 0);

        // Copy remainder of longer number
        while (xIndex > 0)
            result[--xIndex] = x[xIndex];

        // Grow result if necessary
        if (carry) {
            size_t len = cast(int)result.length;
            int[] bigger = new int[len + 1];
            // System.arraycopy(result, 0, bigger, 1, result.length);
            bigger[1 .. 1+len] = result[0 .. $];
            bigger[0] = 0x01;
            return bigger;
        }
        return result;
    }

    private static int[] subtract(long val, int[] little) {
        int highWord = cast(int)(val >>> 32);
        if (highWord == 0) {
            int[] result = new int[1];
            result[0] = cast(int)(val - (little[0] & LONG_MASK));
            return result;
        } else {
            int[] result = new int[2];
            if (little.length == 1) {
                long difference = (cast(int)val & LONG_MASK) - (little[0] & LONG_MASK);
                result[1] = cast(int)difference;
                // Subtract remainder of longer number while borrow propagates
                bool borrow = (difference >> 32 != 0);
                if (borrow) {
                    result[0] = highWord - 1;
                } else {        // Copy remainder of longer number
                    result[0] = highWord;
                }
                return result;
            } else { // little.length == 2
                long difference = (cast(int)val & LONG_MASK) - (little[1] & LONG_MASK);
                result[1] = cast(int)difference;
                difference = (highWord & LONG_MASK) - (little[0] & LONG_MASK) + (difference >> 32);
                result[0] = cast(int)difference;
                return result;
            }
        }
    }

    /**
     * Subtracts the contents of the second argument (val) from the
     * first (big).  The first int array (big) must represent a larger number
     * than the second.  This method allocates the space necessary to hold the
     * answer.
     * assumes val &gt;= 0
     */
    private static int[] subtract(int[] big, long val) {
        int highWord = cast(int)(val >>> 32);
        int bigIndex = cast(int)big.length;
        int[] result = new int[bigIndex];
        long difference = 0;

        if (highWord == 0) {
            difference = (big[--bigIndex] & LONG_MASK) - val;
            result[bigIndex] = cast(int)difference;
        } else {
            difference = (big[--bigIndex] & LONG_MASK) - (val & LONG_MASK);
            result[bigIndex] = cast(int)difference;
            difference = (big[--bigIndex] & LONG_MASK) - (highWord & LONG_MASK) + (difference >> 32);
            result[bigIndex] = cast(int)difference;
        }

        // Subtract remainder of longer number while borrow propagates
        bool borrow = (difference >> 32 != 0);
        while (bigIndex > 0 && borrow)
            borrow = ((result[--bigIndex] = big[bigIndex] - 1) == -1);

        // Copy remainder of longer number
        while (bigIndex > 0)
            result[--bigIndex] = big[bigIndex];

        return result;
    }

    /**
     * Returns a BigInteger whose value is {@code (this - val)}.
     *
     * @param  val value to be subtracted from this BigInteger.
     * @return {@code this - val}
     */
    BigInteger subtract(BigInteger val) {
        if (val._signum == 0)
            return this;
        if (_signum == 0)
            return val.negate();
        if (val.signum != signum)
            return new BigInteger(add(mag, val.mag), signum);

        int cmp = compareMagnitude(val);
        if (cmp == 0)
            return ZERO;
        int[] resultMag = (cmp > 0 ? subtract(mag, val.mag)
                           : subtract(val.mag, mag));
        resultMag = trustedStripLeadingZeroInts(resultMag);
        return new BigInteger(resultMag, cmp == signum ? 1 : -1);
    }

    /**
     * Subtracts the contents of the second int arrays (little) from the
     * first (big).  The first int array (big) must represent a larger number
     * than the second.  This method allocates the space necessary to hold the
     * answer.
     */
    private static int[] subtract(int[] big, int[] little) {
        int bigIndex = cast(int)big.length;
        int[] result = new int[bigIndex];
        int littleIndex = cast(int)little.length;
        long difference = 0;

        // Subtract common parts of both numbers
        while (littleIndex > 0) {
            difference = (big[--bigIndex] & LONG_MASK) -
                         (little[--littleIndex] & LONG_MASK) +
                         (difference >> 32);
            result[bigIndex] = cast(int)difference;
        }

        // Subtract remainder of longer number while borrow propagates
        bool borrow = (difference >> 32 != 0);
        while (bigIndex > 0 && borrow)
            borrow = ((result[--bigIndex] = big[bigIndex] - 1) == -1);

        // Copy remainder of longer number
        while (bigIndex > 0)
            result[--bigIndex] = big[bigIndex];

        return result;
    }

    /**
     * Returns a BigInteger whose value is {@code (this * val)}.
     *
     * @implNote An implementation may offer better algorithmic
     * performance when {@code val == this}.
     *
     * @param  val value to be multiplied by this BigInteger.
     * @return {@code this * val}
     */
    BigInteger multiply(BigInteger val) {
        if (val._signum == 0 || _signum == 0)
            return ZERO;

        int xlen = cast(int)mag.length;

        if (val == this && xlen > MULTIPLY_SQUARE_THRESHOLD) {
            return square();
        }

        int ylen = cast(int)val.mag.length;

        if ((xlen < KARATSUBA_THRESHOLD) || (ylen < KARATSUBA_THRESHOLD)) {
            int resultSign = _signum == val.signum ? 1 : -1;
            if (val.mag.length == 1) {
                return multiplyByInt(mag,val.mag[0], resultSign);
            }
            if (mag.length == 1) {
                return multiplyByInt(val.mag,mag[0], resultSign);
            }
            int[] result = multiplyToLen(mag, xlen,
                                         val.mag, ylen, null);
            result = trustedStripLeadingZeroInts(result);
            return new BigInteger(result, resultSign);
        } else {
            if ((xlen < TOOM_COOK_THRESHOLD) && (ylen < TOOM_COOK_THRESHOLD)) {
                return multiplyKaratsuba(this, val);
            } else {
                return multiplyToomCook3(this, val);
            }
        }
    }

    private static BigInteger multiplyByInt(int[] x, int y, int sign) {
        if (Integer.bitCount(y) == 1) {
            return new BigInteger(shiftLeft(x, Integer.numberOfTrailingZeros(y)), sign);
        }
        int xlen = cast(int)x.length;
        int[] rmag =  new int[xlen + 1];
        long carry = 0;
        long yl = y & LONG_MASK;
        int rstart = cast(int)rmag.length - 1;
        for (int i = xlen - 1; i >= 0; i--) {
            long product = (x[i] & LONG_MASK) * yl + carry;
            rmag[rstart--] = cast(int)product;
            carry = product >>> 32;
        }
        if (carry == 0L) {
            rmag = rmag[1 .. $]; // java.util.Arrays.copyOfRange(rmag, 1, rmag.length);
        } else {
            rmag[rstart] = cast(int)carry;
        }
        return new BigInteger(rmag, sign);
    }

    /**
     * Package private methods used by BigDecimal code to multiply a BigInteger
     * with a long. Assumes v is not equal to INFLATED.
     */
    BigInteger multiply(long v) {
        if (v == 0 || _signum == 0)
          return ZERO;
        if (v == long.min)
            return multiply(BigInteger.valueOf(v));
        int rsign = (v > 0 ? signum : -signum);
        if (v < 0)
            v = -v;
        long dh = v >>> 32;      // higher order bits
        long dl = v & LONG_MASK; // lower order bits

        int xlen = cast(int)mag.length;
        int[] value = mag;
        int[] rmag = (dh == 0L) ? (new int[xlen + 1]) : (new int[xlen + 2]);
        long carry = 0;
        int rstart = cast(int)rmag.length - 1;
        for (int i = xlen - 1; i >= 0; i--) {
            long product = (value[i] & LONG_MASK) * dl + carry;
            rmag[rstart--] = cast(int)product;
            carry = product >>> 32;
        }
        rmag[rstart] = cast(int)carry;
        if (dh != 0L) {
            carry = 0;
            rstart = cast(int)rmag.length - 2;
            for (int i = xlen - 1; i >= 0; i--) {
                long product = (value[i] & LONG_MASK) * dh +
                    (rmag[rstart] & LONG_MASK) + carry;
                rmag[rstart--] = cast(int)product;
                carry = product >>> 32;
            }
            rmag[0] = cast(int)carry;
        }
        if (carry == 0L)
            rmag = rmag[1 .. $]; //java.util.Arrays.copyOfRange(rmag, 1, rmag.length);
        return new BigInteger(rmag, rsign);
    }

    /**
     * Multiplies int arrays x and y to the specified lengths and places
     * the result into z. There will be no leading zeros in the resultant array.
     */
    private static int[] multiplyToLen(int[] x, int xlen, int[] y, int ylen, int[] z) {
        multiplyToLenCheck(x, xlen);
        multiplyToLenCheck(y, ylen);
        return implMultiplyToLen(x, xlen, y, ylen, z);
    }

    
    private static int[] implMultiplyToLen(int[] x, int xlen, int[] y, int ylen, int[] z) {
        int xstart = xlen - 1;
        int ystart = ylen - 1;

        if (z is null || z.length < (xlen+ ylen))
            z = new int[xlen+ylen];

        long carry = 0;
        for (int j=ystart, k=ystart+1+xstart; j >= 0; j--, k--) {
            long product = (y[j] & LONG_MASK) *
                           (x[xstart] & LONG_MASK) + carry;
            z[k] = cast(int)product;
            carry = product >>> 32;
        }
        z[xstart] = cast(int)carry;

        for (int i = xstart-1; i >= 0; i--) {
            carry = 0;
            for (int j=ystart, k=ystart+1+i; j >= 0; j--, k--) {
                long product = (y[j] & LONG_MASK) *
                               (x[i] & LONG_MASK) +
                               (z[k] & LONG_MASK) + carry;
                z[k] = cast(int)product;
                carry = product >>> 32;
            }
            z[i] = cast(int)carry;
        }
        return z;
    }

    private static void multiplyToLenCheck(int[] array, int length) {
        if (length <= 0) {
            return;  // not an error because multiplyToLen won't execute if len <= 0
        }

        assert(array !is null);

        if (length > array.length) {
            throw new ArrayIndexOutOfBoundsException(length - 1);
        }
    }

    /**
     * Multiplies two BigIntegers using the Karatsuba multiplication
     * algorithm.  This is a recursive divide-and-conquer algorithm which is
     * more efficient for large numbers than what is commonly called the
     * "grade-school" algorithm used in multiplyToLen.  If the numbers to be
     * multiplied have length n, the "grade-school" algorithm has an
     * asymptotic complexity of O(n^2).  In contrast, the Karatsuba algorithm
     * has complexity of O(n^(log2(3))), or O(n^1.585).  It achieves this
     * increased performance by doing 3 multiplies instead of 4 when
     * evaluating the product.  As it has some overhead, should be used when
     * both numbers are larger than a certain threshold (found
     * experimentally).
     *
     * See:  http://en.wikipedia.org/wiki/Karatsuba_algorithm
     */
    private static BigInteger multiplyKaratsuba(BigInteger x, BigInteger y) {
        int xlen = cast(int)x.mag.length;
        int ylen = cast(int)y.mag.length;

        // The number of ints in each half of the number.
        int half = (std.algorithm.max(xlen, ylen)+1) / 2;

        // xl and yl are the lower halves of x and y respectively,
        // xh and yh are the upper halves.
        BigInteger xl = x.getLower(half);
        BigInteger xh = x.getUpper(half);
        BigInteger yl = y.getLower(half);
        BigInteger yh = y.getUpper(half);

        BigInteger p1 = xh.multiply(yh);  // p1 = xh*yh
        BigInteger p2 = xl.multiply(yl);  // p2 = xl*yl

        // p3=(xh+xl)*(yh+yl)
        BigInteger p3 = xh.add(xl).multiply(yh.add(yl));

        // result = p1 * 2^(32*2*half) + (p3 - p1 - p2) * 2^(32*half) + p2
        BigInteger result = p1.shiftLeft(32*half).add(p3.subtract(p1).subtract(p2)).shiftLeft(32*half).add(p2);

        if (x.signum != y.signum) {
            return result.negate();
        } else {
            return result;
        }
    }

    /**
     * Multiplies two BigIntegers using a 3-way Toom-Cook multiplication
     * algorithm.  This is a recursive divide-and-conquer algorithm which is
     * more efficient for large numbers than what is commonly called the
     * "grade-school" algorithm used in multiplyToLen.  If the numbers to be
     * multiplied have length n, the "grade-school" algorithm has an
     * asymptotic complexity of O(n^2).  In contrast, 3-way Toom-Cook has a
     * complexity of about O(n^1.465).  It achieves this increased asymptotic
     * performance by breaking each number into three parts and by doing 5
     * multiplies instead of 9 when evaluating the product.  Due to overhead
     * (additions, shifts, and one division) in the Toom-Cook algorithm, it
     * should only be used when both numbers are larger than a certain
     * threshold (found experimentally).  This threshold is generally larger
     * than that for Karatsuba multiplication, so this algorithm is generally
     * only used when numbers become significantly larger.
     *
     * The algorithm used is the "optimal" 3-way Toom-Cook algorithm outlined
     * by Marco Bodrato.
     *
     *  See: http://bodrato.it/toom-cook/
     *       http://bodrato.it/papers/#WAIFI2007
     *
     * "Towards Optimal Toom-Cook Multiplication for Univariate and
     * Multivariate Polynomials in Characteristic 2 and 0." by Marco BODRATO;
     * In C.Carlet and B.Sunar, Eds., "WAIFI'07 proceedings", p. 116-133,
     * LNCS #4547. Springer, Madrid, Spain, June 21-22, 2007.
     *
     */
    private static BigInteger multiplyToomCook3(BigInteger a, BigInteger b) {
        int alen = cast(int)a.mag.length;
        int blen = cast(int)b.mag.length;

        int largest = std.algorithm.max(alen, blen);

        // k is the size (in ints) of the lower-order slices.
        int k = (largest+2)/3;   // Equal to ceil(largest/3)

        // r is the size (in ints) of the highest-order slice.
        int r = largest - 2*k;

        // Obtain slices of the numbers. a2 and b2 are the most significant
        // bits of the numbers a and b, and a0 and b0 the least significant.
        BigInteger a0, a1, a2, b0, b1, b2;
        a2 = a.getToomSlice(k, r, 0, largest);
        a1 = a.getToomSlice(k, r, 1, largest);
        a0 = a.getToomSlice(k, r, 2, largest);
        b2 = b.getToomSlice(k, r, 0, largest);
        b1 = b.getToomSlice(k, r, 1, largest);
        b0 = b.getToomSlice(k, r, 2, largest);

        BigInteger v0, v1, v2, vm1, vinf, t1, t2, tm1, da1, db1;

        v0 = a0.multiply(b0);
        da1 = a2.add(a0);
        db1 = b2.add(b0);
        vm1 = da1.subtract(a1).multiply(db1.subtract(b1));
        da1 = da1.add(a1);
        db1 = db1.add(b1);
        v1 = da1.multiply(db1);
        v2 = da1.add(a2).shiftLeft(1).subtract(a0).multiply(
             db1.add(b2).shiftLeft(1).subtract(b0));
        vinf = a2.multiply(b2);

        // The algorithm requires two divisions by 2 and one by 3.
        // All divisions are known to be exact, that is, they do not produce
        // remainders, and all results are positive.  The divisions by 2 are
        // implemented as right shifts which are relatively efficient, leaving
        // only an exact division by 3, which is done by a specialized
        // linear-time algorithm.
        t2 = v2.subtract(vm1).exactDivideBy3();
        tm1 = v1.subtract(vm1).shiftRight(1);
        t1 = v1.subtract(v0);
        t2 = t2.subtract(t1).shiftRight(1);
        t1 = t1.subtract(tm1).subtract(vinf);
        t2 = t2.subtract(vinf.shiftLeft(1));
        tm1 = tm1.subtract(t2);

        // Number of bits to shift left.
        int ss = k*32;

        BigInteger result = vinf.shiftLeft(ss).add(t2).shiftLeft(ss).add(t1).shiftLeft(ss).add(tm1).shiftLeft(ss).add(v0);

        if (a.signum != b.signum) {
            return result.negate();
        } else {
            return result;
        }
    }


    /**
     * Returns a slice of a BigInteger for use in Toom-Cook multiplication.
     *
     * @param lowerSize The size of the lower-order bit slices.
     * @param upperSize The size of the higher-order bit slices.
     * @param slice The index of which slice is requested, which must be a
     * number from 0 to size-1. Slice 0 is the highest-order bits, and slice
     * size-1 are the lowest-order bits. Slice 0 may be of different size than
     * the other slices.
     * @param fullsize The size of the larger integer array, used to align
     * slices to the appropriate position when multiplying different-sized
     * numbers.
     */
    private BigInteger getToomSlice(int lowerSize, int upperSize, int slice,
                                    int fullsize) {
        int start, end, sliceSize, len, offset;

        len = cast(int)mag.length;
        offset = fullsize - len;

        if (slice == 0) {
            start = 0 - offset;
            end = upperSize - 1 - offset;
        } else {
            start = upperSize + (slice-1)*lowerSize - offset;
            end = start + lowerSize - 1;
        }

        if (start < 0) {
            start = 0;
        }
        if (end < 0) {
           return ZERO;
        }

        sliceSize = (end-start) + 1;

        if (sliceSize <= 0) {
            return ZERO;
        }

        // While performing Toom-Cook, all slices are positive and
        // the sign is adjusted when the final number is composed.
        if (start == 0 && sliceSize >= len) {
            return this.abs();
        }

        int[] intSlice = mag[start .. start + sliceSize];
        // int[] intSlice = new int[sliceSize];
        //System.arraycopy(mag, start, intSlice, 0, sliceSize);

        return new BigInteger(trustedStripLeadingZeroInts(intSlice), 1);
    }

    /**
     * Does an exact division (that is, the remainder is known to be zero)
     * of the specified number by 3.  This is used in Toom-Cook
     * multiplication.  This is an efficient algorithm that runs in linear
     * time.  If the argument is not exactly divisible by 3, results are
     * undefined.  Note that this is expected to be called with positive
     * arguments only.
     */
    private BigInteger exactDivideBy3() {
        int len = cast(int)mag.length;
        int[] result = new int[len];
        long x, w, q, borrow;
        borrow = 0L;
        for (int i=len-1; i >= 0; i--) {
            x = (mag[i] & LONG_MASK);
            w = x - borrow;
            if (borrow > x) {      // Did we make the number go negative?
                borrow = 1L;
            } else {
                borrow = 0L;
            }

            // 0xAAAAAAAB is the modular inverse of 3 (mod 2^32).  Thus,
            // the effect of this is to divide by 3 (mod 2^32).
            // This is much faster than division on most architectures.
            q = (w * 0xAAAAAAABL) & LONG_MASK;
            result[i] = cast(int) q;

            // Now check the borrow. The second check can of course be
            // eliminated if the first fails.
            if (q >= 0x55555556L) {
                borrow++;
                if (q >= 0xAAAAAAABL)
                    borrow++;
            }
        }
        result = trustedStripLeadingZeroInts(result);
        return new BigInteger(result, signum);
    }

    /**
     * Returns a new BigInteger representing n lower ints of the number.
     * This is used by Karatsuba multiplication and Karatsuba squaring.
     */
    private BigInteger getLower(int n) {
        int len = cast(int)mag.length;

        if (len <= n) {
            return abs();
        }

        int[] lowerInts = mag[len-n .. len];
        // int[] lowerInts = new int[n];
        // System.arraycopy(mag, len-n, lowerInts, 0, n);

        return new BigInteger(trustedStripLeadingZeroInts(lowerInts), 1);
    }

    /**
     * Returns a new BigInteger representing mag.length-n upper
     * ints of the number.  This is used by Karatsuba multiplication and
     * Karatsuba squaring.
     */
    private BigInteger getUpper(int n) {
        int len = cast(int)mag.length;

        if (len <= n) {
            return ZERO;
        }

        int upperLen = len - n;
        int[] upperInts = mag[0 .. upperLen];
        // int[] upperInts = new int[upperLen];
        // System.arraycopy(mag, 0, upperInts, 0, upperLen);

        return new BigInteger(trustedStripLeadingZeroInts(upperInts), 1);
    }

    // Squaring

    /**
     * Returns a BigInteger whose value is {@code (this<sup>2</sup>)}.
     *
     * @return {@code this<sup>2</sup>}
     */
    private BigInteger square() {
        if (_signum == 0) {
            return ZERO;
        }
        int len = cast(int)mag.length;

        if (len < KARATSUBA_SQUARE_THRESHOLD) {
            int[] z = squareToLen(mag, len, null);
            return new BigInteger(trustedStripLeadingZeroInts(z), 1);
        } else {
            if (len < TOOM_COOK_SQUARE_THRESHOLD) {
                return squareKaratsuba();
            } else {
                return squareToomCook3();
            }
        }
    }

    /**
     * Squares the contents of the int array x. The result is placed into the
     * int array z.  The contents of x are not changed.
     */
    private static int[] squareToLen(int[] x, int len, int[] z) {
         int zlen = len << 1;
         if (z is null || z.length < zlen)
             z = new int[zlen];

         // Execute checks before calling intrinsified method.
         implSquareToLenChecks(x, len, z, zlen);
         return implSquareToLen(x, len, z, zlen);
     }

     /**
      * Parameters validation.
      */
     private static void implSquareToLenChecks(int[] x, int len, int[] z, int zlen) {
         if (len < 1) {
             throw new IllegalArgumentException("invalid input length: " ~ len.to!string().to!string());
         }
         if (len > x.length) {
             throw new IllegalArgumentException("input length out of bound: " ~
                                        len.to!string() ~ " > " ~ x.length.to!string());
         }
         if (len * 2 > z.length) {
             throw new IllegalArgumentException("input length out of bound: " ~
                                        (len * 2).to!string() ~ " > " ~ z.length.to!string());
         }
         if (zlen < 1) {
             throw new IllegalArgumentException("invalid input length: " ~ zlen.to!string());
         }
         if (zlen > z.length) {
             throw new IllegalArgumentException("input length out of bound: " ~
                                        len.to!string() ~ " > " ~ z.length.to!string());
         }
     }

     /**
      * Java Runtime may use intrinsic for this method.
      */
     
     private static final int[] implSquareToLen(int[] x, int len, int[] z, int zlen) {
        /*
         * The algorithm used here is adapted from Colin Plumb's C library.
         * Technique: Consider the partial products in the multiplication
         * of "abcde" by itself:
         *
         *               a  b  c  d  e
         *            *  a  b  c  d  e
         *          ==================
         *              ae be ce de ee
         *           ad bd cd dd de
         *        ac bc cc cd ce
         *     ab bb bc bd be
         *  aa ab ac ad ae
         *
         * Note that everything above the main diagonal:
         *              ae be ce de = (abcd) * e
         *           ad bd cd       = (abc) * d
         *        ac bc             = (ab) * c
         *     ab                   = (a) * b
         *
         * is a copy of everything below the main diagonal:
         *                       de
         *                 cd ce
         *           bc bd be
         *     ab ac ad ae
         *
         * Thus, the sum is 2 * (off the diagonal) + diagonal.
         *
         * This is accumulated beginning with the diagonal (which
         * consist of the squares of the digits of the input), which is then
         * divided by two, the off-diagonal added, and multiplied by two
         * again.  The low bit is simply a copy of the low bit of the
         * input, so it doesn't need special care.
         */

        // Store the squares, right shifted one bit (i.e., divided by 2)
        int lastProductLowWord = 0;
        for (int j=0, i=0; j < len; j++) {
            long piece = (x[j] & LONG_MASK);
            long product = piece * piece;
            z[i++] = (lastProductLowWord << 31) | cast(int)(product >>> 33);
            z[i++] = cast(int)(product >>> 1);
            lastProductLowWord = cast(int)product;
        }

        // Add in off-diagonal sums
        for (int i=len, offset=1; i > 0; i--, offset+=2) {
            int t = x[i-1];
            t = mulAdd(z, x, offset, i-1, t);
            addOne(z, offset-1, i, t);
        }

        // Shift back up and set low bit
        primitiveLeftShift(z, zlen, 1);
        z[zlen-1] |= x[len-1] & 1;

        return z;
    }

    /**
     * Squares a BigInteger using the Karatsuba squaring algorithm.  It should
     * be used when both numbers are larger than a certain threshold (found
     * experimentally).  It is a recursive divide-and-conquer algorithm that
     * has better asymptotic performance than the algorithm used in
     * squareToLen.
     */
    private BigInteger squareKaratsuba() {
        int half = cast(int)(mag.length+1) / 2;

        BigInteger xl = getLower(half);
        BigInteger xh = getUpper(half);

        BigInteger xhs = xh.square();  // xhs = xh^2
        BigInteger xls = xl.square();  // xls = xl^2

        // xh^2 << 64  +  (((xl+xh)^2 - (xh^2 + xl^2)) << 32) + xl^2
        return xhs.shiftLeft(half*32).add(xl.add(xh).square().subtract(xhs.add(xls))).shiftLeft(half*32).add(xls);
    }

    /**
     * Squares a BigInteger using the 3-way Toom-Cook squaring algorithm.  It
     * should be used when both numbers are larger than a certain threshold
     * (found experimentally).  It is a recursive divide-and-conquer algorithm
     * that has better asymptotic performance than the algorithm used in
     * squareToLen or squareKaratsuba.
     */
    private BigInteger squareToomCook3() {
        int len = cast(int)mag.length;

        // k is the size (in ints) of the lower-order slices.
        int k = (len+2)/3;   // Equal to ceil(largest/3)

        // r is the size (in ints) of the highest-order slice.
        int r = len - 2*k;

        // Obtain slices of the numbers. a2 is the most significant
        // bits of the number, and a0 the least significant.
        BigInteger a0, a1, a2;
        a2 = getToomSlice(k, r, 0, len);
        a1 = getToomSlice(k, r, 1, len);
        a0 = getToomSlice(k, r, 2, len);
        BigInteger v0, v1, v2, vm1, vinf, t1, t2, tm1, da1;

        v0 = a0.square();
        da1 = a2.add(a0);
        vm1 = da1.subtract(a1).square();
        da1 = da1.add(a1);
        v1 = da1.square();
        vinf = a2.square();
        v2 = da1.add(a2).shiftLeft(1).subtract(a0).square();

        // The algorithm requires two divisions by 2 and one by 3.
        // All divisions are known to be exact, that is, they do not produce
        // remainders, and all results are positive.  The divisions by 2 are
        // implemented as right shifts which are relatively efficient, leaving
        // only a division by 3.
        // The division by 3 is done by an optimized algorithm for this case.
        t2 = v2.subtract(vm1).exactDivideBy3();
        tm1 = v1.subtract(vm1).shiftRight(1);
        t1 = v1.subtract(v0);
        t2 = t2.subtract(t1).shiftRight(1);
        t1 = t1.subtract(tm1).subtract(vinf);
        t2 = t2.subtract(vinf.shiftLeft(1));
        tm1 = tm1.subtract(t2);

        // Number of bits to shift left.
        int ss = k*32;

        return vinf.shiftLeft(ss).add(t2).shiftLeft(ss).add(t1).shiftLeft(ss).add(tm1).shiftLeft(ss).add(v0);
    }

    // Division

    /**
     * Returns a BigInteger whose value is {@code (this / val)}.
     *
     * @param  val value by which this BigInteger is to be divided.
     * @return {@code this / val}
     * @throws ArithmeticException if {@code val} is zero.
     */
    BigInteger divide(BigInteger val) {
        // if (val.mag.length < BURNIKEL_ZIEGLER_THRESHOLD ||
        //         mag.length - val.mag.length < BURNIKEL_ZIEGLER_OFFSET) {
        //     return divideKnuth(val);
        // } else {
        //     return divideBurnikelZiegler(val);
        // }
        return null;
    }

    /**
     * Returns a BigInteger whose value is {@code (this / val)} using an O(n^2) algorithm from Knuth.
     *
     * @param  val value by which this BigInteger is to be divided.
     * @return {@code this / val}
     * @throws ArithmeticException if {@code val} is zero.
     * @see MutableBigInteger#divideKnuth(MutableBigInteger, MutableBigInteger, bool)
     */
    // private BigInteger divideKnuth(BigInteger val) {
    //     MutableBigInteger q = new MutableBigInteger(),
    //                       a = new MutableBigInteger(this.mag),
    //                       b = new MutableBigInteger(val.mag);

    //     a.divideKnuth(b, q, false);
    //     return q.toBigInteger(this._signum * val.signum);
    // }

    /**
     * Returns an array of two BigIntegers containing {@code (this / val)}
     * followed by {@code (this % val)}.
     *
     * @param  val value by which this BigInteger is to be divided, and the
     *         remainder computed.
     * @return an array of two BigIntegers: the quotient {@code (this / val)}
     *         is the initial element, and the remainder {@code (this % val)}
     *         is the final element.
     * @throws ArithmeticException if {@code val} is zero.
     */
    BigInteger[] divideAndRemainder(BigInteger val) {
        if (val.mag.length < BURNIKEL_ZIEGLER_THRESHOLD ||
                mag.length - val.mag.length < BURNIKEL_ZIEGLER_OFFSET) {
            return divideAndRemainderKnuth(val);
        } else {
            return divideAndRemainderBurnikelZiegler(val);
        }
    }

    /** Long division */
    private BigInteger[] divideAndRemainderKnuth(BigInteger val) {
        BigInteger[] result = new BigInteger[2];
        MutableBigInteger q = new MutableBigInteger(),
                          a = new MutableBigInteger(this.mag),
                          b = new MutableBigInteger(val.mag);
        MutableBigInteger r = a.divideKnuth(b, q);
        result[0] = q.toBigInteger(this._signum == val.signum ? 1 : -1);
        result[1] = r.toBigInteger(this._signum);
        return result;
    }

    /**
     * Returns a BigInteger whose value is {@code (this % val)}.
     *
     * @param  val value by which this BigInteger is to be divided, and the
     *         remainder computed.
     * @return {@code this % val}
     * @throws ArithmeticException if {@code val} is zero.
     */
    BigInteger remainder(BigInteger val) {
        if (val.mag.length < BURNIKEL_ZIEGLER_THRESHOLD ||
                mag.length - val.mag.length < BURNIKEL_ZIEGLER_OFFSET) {
            return remainderKnuth(val);
        } else {
            return remainderBurnikelZiegler(val);
        }
    }

    /** Long division */
    private BigInteger remainderKnuth(BigInteger val) {
        MutableBigInteger q = new MutableBigInteger(),
                          a = new MutableBigInteger(this.mag),
                          b = new MutableBigInteger(val.mag);

        return a.divideKnuth(b, q).toBigInteger(this._signum);
    }

    /**
     * Calculates {@code this / val} using the Burnikel-Ziegler algorithm.
     * @param  val the divisor
     * @return {@code this / val}
     */
    private BigInteger divideBurnikelZiegler(BigInteger val) {
        return divideAndRemainderBurnikelZiegler(val)[0];
    }

    /**
     * Calculates {@code this % val} using the Burnikel-Ziegler algorithm.
     * @param val the divisor
     * @return {@code this % val}
     */
    private BigInteger remainderBurnikelZiegler(BigInteger val) {
        return divideAndRemainderBurnikelZiegler(val)[1];
    }

    /**
     * Computes {@code this / val} and {@code this % val} using the
     * Burnikel-Ziegler algorithm.
     * @param val the divisor
     * @return an array containing the quotient and remainder
     */
    private BigInteger[] divideAndRemainderBurnikelZiegler(BigInteger val) {
        MutableBigInteger q = new MutableBigInteger();
        MutableBigInteger r = new MutableBigInteger(this).divideAndRemainderBurnikelZiegler(new MutableBigInteger(val), q);
        BigInteger qBigInt = q.isZero() ? ZERO : q.toBigInteger(signum*val.signum);
        BigInteger rBigInt = r.isZero() ? ZERO : r.toBigInteger(signum);
        return [qBigInt, rBigInt];
    }

    /**
     * Returns a BigInteger whose value is <code>(this<sup>exponent</sup>)</code>.
     * Note that {@code exponent} is an integer rather than a BigInteger.
     *
     * @param  exponent exponent to which this BigInteger is to be raised.
     * @return <code>this<sup>exponent</sup></code>
     * @throws ArithmeticException {@code exponent} is negative.  (This would
     *         cause the operation to yield a non-integer value.)
     */
    BigInteger pow(int exponent) {
        if (exponent < 0) {
            throw new ArithmeticException("Negative exponent");
        }
        if (_signum == 0) {
            return (exponent == 0 ? ONE : this);
        }

        BigInteger partToSquare = this.abs();

        // Factor out powers of two from the base, as the exponentiation of
        // these can be done by left shifts only.
        // The remaining part can then be exponentiated faster.  The
        // powers of two will be multiplied back at the end.
        int powersOfTwo = partToSquare.getLowestSetBit();
        long bitsToShift = cast(long)powersOfTwo * exponent;
        if (bitsToShift > int.max) {
            reportOverflow();
        }

        int remainingBits;

        // Factor the powers of two out quickly by shifting right, if needed.
        if (powersOfTwo > 0) {
            partToSquare = partToSquare.shiftRight(powersOfTwo);
            remainingBits = partToSquare.bitLength();
            if (remainingBits == 1) {  // Nothing left but +/- 1?
                if (signum < 0 && (exponent&1) == 1) {
                    return NEGATIVE_ONE.shiftLeft(powersOfTwo*exponent);
                } else {
                    return ONE.shiftLeft(powersOfTwo*exponent);
                }
            }
        } else {
            remainingBits = partToSquare.bitLength();
            if (remainingBits == 1) { // Nothing left but +/- 1?
                if (signum < 0  && (exponent&1) == 1) {
                    return NEGATIVE_ONE;
                } else {
                    return ONE;
                }
            }
        }

        // This is a quick way to approximate the size of the result,
        // similar to doing log2[n] * exponent.  This will give an upper bound
        // of how big the result can be, and which algorithm to use.
        long scaleFactor = cast(long)remainingBits * exponent;

        // Use slightly different algorithms for small and large operands.
        // See if the result will safely fit into a long. (Largest 2^63-1)
        if (partToSquare.mag.length == 1 && scaleFactor <= 62) {
            // Small number algorithm.  Everything fits into a long.
            int newSign = (signum <0  && (exponent&1) == 1 ? -1 : 1);
            long result = 1;
            long baseToPow2 = partToSquare.mag[0] & LONG_MASK;

            int workingExponent = exponent;

            // Perform exponentiation using repeated squaring trick
            while (workingExponent != 0) {
                if ((workingExponent & 1) == 1) {
                    result = result * baseToPow2;
                }

                if ((workingExponent >>>= 1) != 0) {
                    baseToPow2 = baseToPow2 * baseToPow2;
                }
            }

            // Multiply back the powers of two (quickly, by shifting left)
            if (powersOfTwo > 0) {
                if (bitsToShift + scaleFactor <= 62) { // Fits in long?
                    return valueOf((result << bitsToShift) * newSign);
                } else {
                    return valueOf(result*newSign).shiftLeft(cast(int) bitsToShift);
                }
            }
            else {
                return valueOf(result*newSign);
            }
        } else {
            // Large number algorithm.  This is basically identical to
            // the algorithm above, but calls multiply() and square()
            // which may use more efficient algorithms for large numbers.
            BigInteger answer = ONE;

            int workingExponent = exponent;
            // Perform exponentiation using repeated squaring trick
            while (workingExponent != 0) {
                if ((workingExponent & 1) == 1) {
                    answer = answer.multiply(partToSquare);
                }

                if ((workingExponent >>>= 1) != 0) {
                    partToSquare = partToSquare.square();
                }
            }
            // Multiply back the (exponentiated) powers of two (quickly,
            // by shifting left)
            if (powersOfTwo > 0) {
                answer = answer.shiftLeft(powersOfTwo*exponent);
            }

            if (signum < 0 && (exponent&1) == 1) {
                return answer.negate();
            } else {
                return answer;
            }
        }
    }

    /**
     * Returns the integer square root of this BigInteger.  The integer square
     * root of the corresponding mathematical integer {@code n} is the largest
     * mathematical integer {@code s} such that {@code s*s <= n}.  It is equal
     * to the value of {@code floor(sqrt(n))}, where {@code sqrt(n)} denotes the
     * real square root of {@code n} treated as a real.  Note that the integer
     * square root will be less than the real square root if the latter is not
     * representable as an integral value.
     *
     * @return the integer square root of {@code this}
     * @throws ArithmeticException if {@code this} is negative.  (The square
     *         root of a negative integer {@code val} is
     *         {@code (i * sqrt(-val))} where <i>i</i> is the
     *         <i>imaginary unit</i> and is equal to
     *         {@code sqrt(-1)}.)
     * @since  9
     */
    BigInteger sqrt() {
        if (this._signum < 0) {
            throw new ArithmeticException("Negative BigInteger");
        }

        return new MutableBigInteger(this.mag).sqrt().toBigInteger();
    }

    /**
     * Returns an array of two BigIntegers containing the integer square root
     * {@code s} of {@code this} and its remainder {@code this - s*s},
     * respectively.
     *
     * @return an array of two BigIntegers with the integer square root at
     *         offset 0 and the remainder at offset 1
     * @throws ArithmeticException if {@code this} is negative.  (The square
     *         root of a negative integer {@code val} is
     *         {@code (i * sqrt(-val))} where <i>i</i> is the
     *         <i>imaginary unit</i> and is equal to
     *         {@code sqrt(-1)}.)
     * @see #sqrt()
     * @since  9
     */
    BigInteger[] sqrtAndRemainder() {
        BigInteger s = sqrt();
        BigInteger r = this.subtract(s.square());
        assert(r.compareTo(BigInteger.ZERO) >= 0);
        return [s, r];
    }

    /**
     * Returns a BigInteger whose value is the greatest common divisor of
     * {@code abs(this)} and {@code abs(val)}.  Returns 0 if
     * {@code this == 0 && val == 0}.
     *
     * @param  val value with which the GCD is to be computed.
     * @return {@code GCD(abs(this), abs(val))}
     */
    BigInteger gcd(BigInteger val) {
        if (val._signum == 0)
            return this.abs();
        else if (this._signum == 0)
            return val.abs();

        MutableBigInteger a = new MutableBigInteger(this);
        MutableBigInteger b = new MutableBigInteger(val);

        MutableBigInteger result = a.hybridGCD(b);

        return result.toBigInteger(1);
    }

    /**
     * Package private method to return bit length for an integer.
     */
    static int bitLengthForInt(int n) {
        return 32 - Integer.numberOfLeadingZeros(n);
    }

    /**
     * Left shift int array a up to len by n bits. Returns the array that
     * results from the shift since space may have to be reallocated.
     */
    private static int[] leftShift(int[] a, int len, int n) {
        int nInts = n >>> 5;
        int nBits = n&0x1F;
        int bitsInHighWord = bitLengthForInt(a[0]);

        // If shift can be done without recopy, do so
        if (n <= (32-bitsInHighWord)) {
            primitiveLeftShift(a, len, nBits);
            return a;
        } else { // Array must be resized
            if (nBits <= (32-bitsInHighWord)) {
                int[] result = new int[nInts+len];
                // System.arraycopy(a, 0, result, 0, len);
                result[0..len] = a[0..len];
                primitiveLeftShift(result, cast(int)result.length, nBits);
                return result;
            } else {
                int[] result = new int[nInts+len+1];
                // System.arraycopy(a, 0, result, 0, len);
                result[0..len] = a[0..len];
                primitiveRightShift(result, cast(int)result.length, 32 - nBits);
                return result;
            }
        }
    }

    // shifts a up to len right n bits assumes no leading zeros, 0<n<32
    static void primitiveRightShift(int[] a, int len, int n) {
        int n2 = 32 - n;
        for (int i=len-1, c=a[i]; i > 0; i--) {
            int b = c;
            c = a[i-1];
            a[i] = (c << n2) | (b >>> n);
        }
        a[0] >>>= n;
    }

    // shifts a up to len left n bits assumes no leading zeros, 0<=n<32
    static void primitiveLeftShift(int[] a, int len, int n) {
        if (len == 0 || n == 0)
            return;

        int n2 = 32 - n;
        for (int i=0, c=a[i], m=i+len-1; i < m; i++) {
            int b = c;
            c = a[i+1];
            a[i] = (b << n) | (c >>> n2);
        }
        a[len-1] <<= n;
    }

    /**
     * Calculate bitlength of contents of the first len elements an int array,
     * assuming there are no leading zero ints.
     */
    private static int bitLength(int[] val, int len) {
        if (len == 0)
            return 0;
        return ((len - 1) << 5) + bitLengthForInt(val[0]);
    }

    /**
     * Returns a BigInteger whose value is the absolute value of this
     * BigInteger.
     *
     * @return {@code abs(this)}
     */
    BigInteger abs() {
        return (signum >= 0 ? this : this.negate());
    }

    /**
     * Returns a BigInteger whose value is {@code (-this)}.
     *
     * @return {@code -this}
     */
    BigInteger negate() {
        return new BigInteger(this.mag, -this._signum);
    }

    /**
     * Returns the signum function of this BigInteger.
     *
     * @return -1, 0 or 1 as the value of this BigInteger is negative, zero or
     *         positive.
     */
    int signum() {
        return this._signum;
    }

    // Modular Arithmetic Operations

    /**
     * Returns a BigInteger whose value is {@code (this mod m}).  This method
     * differs from {@code remainder} in that it always returns a
     * <i>non-negative</i> BigInteger.
     *
     * @param  m the modulus.
     * @return {@code this mod m}
     * @throws ArithmeticException {@code m} &le; 0
     * @see    #remainder
     */
    BigInteger mod(BigInteger m) {
        if (m.signum <= 0)
            throw new ArithmeticException("BigInteger: modulus not positive");

        BigInteger result = this.remainder(m);
        return (result.signum >= 0 ? result : result.add(m));
    }

    /**
     * Returns a BigInteger whose value is
     * <code>(this<sup>exponent</sup> mod m)</code>.  (Unlike {@code pow}, this
     * method permits negative exponents.)
     *
     * @param  exponent the exponent.
     * @param  m the modulus.
     * @return <code>this<sup>exponent</sup> mod m</code>
     * @throws ArithmeticException {@code m} &le; 0 or the exponent is
     *         negative and this BigInteger is not <i>relatively
     *         prime</i> to {@code m}.
     * @see    #modInverse
     */
    BigInteger modPow(BigInteger exponent, BigInteger m) {
        if (m.signum <= 0)
            throw new ArithmeticException("BigInteger: modulus not positive");

        // Trivial cases
        if (exponent._signum == 0)
            return (m.equals(ONE) ? ZERO : ONE);

        if (this.equals(ONE))
            return (m.equals(ONE) ? ZERO : ONE);

        if (this.equals(ZERO) && exponent.signum >= 0)
            return ZERO;

        if (this.equals(negConst[1]) && (!exponent.testBit(0)))
            return (m.equals(ONE) ? ZERO : ONE);

        bool invertResult;
        invertResult = (exponent.signum < 0);
        if (invertResult)
            exponent = exponent.negate();

        BigInteger base = (this._signum < 0 || this.compareTo(m) >= 0
                           ? this.mod(m) : this);
        BigInteger result;
        if (m.testBit(0)) { // odd modulus
            result = base.oddModPow(exponent, m);
        } else {
            /*
             * Even modulus.  Tear it into an "odd part" (m1) and power of two
             * (m2), exponentiate mod m1, manually exponentiate mod m2, and
             * use Chinese Remainder Theorem to combine results.
             */

            // Tear m apart into odd part (m1) and power of 2 (m2)
            int p = m.getLowestSetBit();   // Max pow of 2 that divides m

            BigInteger m1 = m.shiftRight(p);  // m/2**p
            BigInteger m2 = ONE.shiftLeft(p); // 2**p

            // Calculate new base from m1
            BigInteger base2 = (this._signum < 0 || this.compareTo(m1) >= 0
                                ? this.mod(m1) : this);

            // Caculate (base ** exponent) mod m1.
            BigInteger a1 = (m1.equals(ONE) ? ZERO :
                             base2.oddModPow(exponent, m1));

            // Calculate (this ** exponent) mod m2
            BigInteger a2 = base.modPow2(exponent, p);

            // Combine results using Chinese Remainder Theorem
            BigInteger y1 = m2.modInverse(m1);
            BigInteger y2 = m1.modInverse(m2);

            if (m.mag.length < MAX_MAG_LENGTH / 2) {
                result = a1.multiply(m2).multiply(y1).add(a2.multiply(m1).multiply(y2)).mod(m);
            } else {
                MutableBigInteger t1 = new MutableBigInteger();
                new MutableBigInteger(a1.multiply(m2)).multiply(new MutableBigInteger(y1), t1);
                MutableBigInteger t2 = new MutableBigInteger();
                new MutableBigInteger(a2.multiply(m1)).multiply(new MutableBigInteger(y2), t2);
                t1.add(t2);
                MutableBigInteger q = new MutableBigInteger();
                result = t1.divide(new MutableBigInteger(m), q).toBigInteger();
            }
        }

        return (invertResult ? result.modInverse(m) : result);
    }

    // Montgomery multiplication.  These are wrappers for
    // implMontgomeryXX routines which are expected to be replaced by
    // virtual machine intrinsics.  We don't use the intrinsics for
    // very large operands: MONTGOMERY_INTRINSIC_THRESHOLD should be
    // larger than any reasonable crypto key.
    private static int[] montgomeryMultiply(int[] a, int[] b, int[] n, int len, long inv,
                                            int[] product) {
        implMontgomeryMultiplyChecks(a, b, n, len, product);
        if (len > MONTGOMERY_INTRINSIC_THRESHOLD) {
            // Very long argument: do not use an intrinsic
            product = multiplyToLen(a, len, b, len, product);
            return montReduce(product, n, len, cast(int)inv);
        } else {
            return implMontgomeryMultiply(a, b, n, len, inv, materialize(product, len));
        }
    }
    private static int[] montgomerySquare(int[] a, int[] n, int len, long inv,
                                          int[] product) {
        implMontgomeryMultiplyChecks(a, a, n, len, product);
        if (len > MONTGOMERY_INTRINSIC_THRESHOLD) {
            // Very long argument: do not use an intrinsic
            product = squareToLen(a, len, product);
            return montReduce(product, n, len, cast(int)inv);
        } else {
            return implMontgomerySquare(a, n, len, inv, materialize(product, len));
        }
    }

    // Range-check everything.
    private static void implMontgomeryMultiplyChecks
        (int[] a, int[] b, int[] n, int len, int[] product) {
        if (len % 2 != 0) {
            throw new IllegalArgumentException("input array length must be even: " ~ len.to!string());
        }

        if (len < 1) {
            throw new IllegalArgumentException("invalid input length: " ~ len.to!string());
        }

        if (len > a.length ||
            len > b.length ||
            len > n.length ||
            (product !is null && len > product.length)) {
            throw new IllegalArgumentException("input array length out of bound: " ~ len.to!string());
        }
    }

    // Make sure that the int array z (which is expected to contain
    // the result of a Montgomery multiplication) is present and
    // sufficiently large.
    private static int[] materialize(int[] z, int len) {
         if (z is null || z.length < len)
             z = new int[len];
         return z;
    }

    // These methods are intended to be replaced by virtual machine
    // intrinsics.
    
    private static int[] implMontgomeryMultiply(int[] a, int[] b, int[] n, int len,
                                         long inv, int[] product) {
        product = multiplyToLen(a, len, b, len, product);
        return montReduce(product, n, len, cast(int)inv);
    }
    
    private static int[] implMontgomerySquare(int[] a, int[] n, int len,
                                       long inv, int[] product) {
        product = squareToLen(a, len, product);
        return montReduce(product, n, len, cast(int)inv);
    }

    enum int[] bnExpModThreshTable = [7, 25, 81, 241, 673, 1793,
                                                int.max]; // Sentinel

    /**
     * Returns a BigInteger whose value is x to the power of y mod z.
     * Assumes: z is odd && x < z.
     */
    private BigInteger oddModPow(BigInteger y, BigInteger z) {
    /*
     * The algorithm is adapted from Colin Plumb's C library.
     *
     * The window algorithm:
     * The idea is to keep a running product of b1 = n^(high-order bits of exp)
     * and then keep appending exponent bits to it.  The following patterns
     * apply to a 3-bit window (k = 3):
     * To append   0: square
     * To append   1: square, multiply by n^1
     * To append  10: square, multiply by n^1, square
     * To append  11: square, square, multiply by n^3
     * To append 100: square, multiply by n^1, square, square
     * To append 101: square, square, square, multiply by n^5
     * To append 110: square, square, multiply by n^3, square
     * To append 111: square, square, square, multiply by n^7
     *
     * Since each pattern involves only one multiply, the longer the pattern
     * the better, except that a 0 (no multiplies) can be appended directly.
     * We precompute a table of odd powers of n, up to 2^k, and can then
     * multiply k bits of exponent at a time.  Actually, assuming random
     * exponents, there is on average one zero bit between needs to
     * multiply (1/2 of the time there's none, 1/4 of the time there's 1,
     * 1/8 of the time, there's 2, 1/32 of the time, there's 3, etc.), so
     * you have to do one multiply per k+1 bits of exponent.
     *
     * The loop walks down the exponent, squaring the result buffer as
     * it goes.  There is a wbits+1 bit lookahead buffer, buf, that is
     * filled with the upcoming exponent bits.  (What is read after the
     * end of the exponent is unimportant, but it is filled with zero here.)
     * When the most-significant bit of this buffer becomes set, i.e.
     * (buf & tblmask) != 0, we have to decide what pattern to multiply
     * by, and when to do it.  We decide, remember to do it in future
     * after a suitable number of squarings have passed (e.g. a pattern
     * of "100" in the buffer requires that we multiply by n^1 immediately;
     * a pattern of "110" calls for multiplying by n^3 after one more
     * squaring), clear the buffer, and continue.
     *
     * When we start, there is one more optimization: the result buffer
     * is implcitly one, so squaring it or multiplying by it can be
     * optimized away.  Further, if we start with a pattern like "100"
     * in the lookahead window, rather than placing n into the buffer
     * and then starting to square it, we have already computed n^2
     * to compute the odd-powers table, so we can place that into
     * the buffer and save a squaring.
     *
     * This means that if you have a k-bit window, to compute n^z,
     * where z is the high k bits of the exponent, 1/2 of the time
     * it requires no squarings.  1/4 of the time, it requires 1
     * squaring, ... 1/2^(k-1) of the time, it reqires k-2 squarings.
     * And the remaining 1/2^(k-1) of the time, the top k bits are a
     * 1 followed by k-1 0 bits, so it again only requires k-2
     * squarings, not k-1.  The average of these is 1.  Add that
     * to the one squaring we have to do to compute the table,
     * and you'll see that a k-bit window saves k-2 squarings
     * as well as reducing the multiplies.  (It actually doesn't
     * hurt in the case k = 1, either.)
     */
        // Special case for exponent of one
        if (y.equals(ONE))
            return this;

        // Special case for base of zero
        if (_signum == 0)
            return ZERO;

        int[] base = mag.dup;
        int[] exp = y.mag;
        int[] mod = z.mag;
        int modLen = cast(int)mod.length;

        // Make modLen even. It is conventional to use a cryptographic
        // modulus that is 512, 768, 1024, or 2048 bits, so this code
        // will not normally be executed. However, it is necessary for
        // the correct functioning of the HotSpot intrinsics.
        if ((modLen & 1) != 0) {
            int[] x = new int[modLen + 1];
            // System.arraycopy(mod, 0, x, 1, modLen);
            x[1 .. modLen+1] = mod[0 .. modLen];
            mod = x;
            modLen++;
        }

        // Select an appropriate window size
        int wbits = 0;
        int ebits = bitLength(exp, cast(int)exp.length);
        // if exponent is 65537 (0x10001), use minimum window size
        if ((ebits != 17) || (exp[0] != 65537)) {
            while (ebits > bnExpModThreshTable[wbits]) {
                wbits++;
            }
        }

        // Calculate appropriate table size
        int tblmask = 1 << wbits;

        // Allocate table for precomputed odd powers of base in Montgomery form
        int[][] table = new int[][tblmask];
        for (int i=0; i < tblmask; i++)
            table[i] = new int[modLen];

        // Compute the modular inverse of the least significant 64-bit
        // digit of the modulus
        long n0 = (mod[modLen-1] & LONG_MASK) + ((mod[modLen-2] & LONG_MASK) << 32);
        long inv = -MutableBigInteger.inverseMod64(n0);

        // Convert base to Montgomery form
        int[] a = leftShift(base, cast(int)base.length, modLen << 5);

        MutableBigInteger q = new MutableBigInteger(),
                          a2 = new MutableBigInteger(a),
                          b2 = new MutableBigInteger(mod);
        b2.normalize(); // MutableBigInteger.divide() assumes that its
                        // divisor is in normal form.

        MutableBigInteger r= a2.divide(b2, q);
        table[0] = r.toIntArray();

        // Pad table[0] with leading zeros so its length is at least modLen
        if (table[0].length < modLen) {
           size_t len = table[0].length;
           size_t offset = modLen - len;
           int[] t2 = new int[modLen];
           t2[offset .. offset+len] = table[0][0 .. $];
        //    System.arraycopy(table[0], 0, t2, offset, table[0].length);

           table[0] = t2;
        }

        // Set b to the square of the base
        int[] b = montgomerySquare(table[0], mod, modLen, inv, null);

        // Set t to high half of b
        int[] t = b[0..modLen].dup; // Arrays.copyOf(b, modLen);

        // Fill in the table with odd powers of the base
        for (int i=1; i < tblmask; i++) {
            table[i] = montgomeryMultiply(t, table[i-1], mod, modLen, inv, null);
        }

        // Pre load the window that slides over the exponent
        int bitpos = 1 << ((ebits-1) & (32-1));

        int buf = 0;
        int elen = cast(int)exp.length;
        int eIndex = 0;
        for (int i = 0; i <= wbits; i++) {
            buf = (buf << 1) | (((exp[eIndex] & bitpos) != 0)?1:0);
            bitpos >>>= 1;
            if (bitpos == 0) {
                eIndex++;
                bitpos = 1 << (32-1);
                elen--;
            }
        }

        int multpos = ebits;

        // The first iteration, which is hoisted out of the main loop
        ebits--;
        bool isone = true;

        multpos = ebits - wbits;
        while ((buf & 1) == 0) {
            buf >>>= 1;
            multpos++;
        }

        int[] mult = table[buf >>> 1];

        buf = 0;
        if (multpos == ebits)
            isone = false;

        // The main loop
        while (true) {
            ebits--;
            // Advance the window
            buf <<= 1;

            if (elen != 0) {
                buf |= ((exp[eIndex] & bitpos) != 0) ? 1 : 0;
                bitpos >>>= 1;
                if (bitpos == 0) {
                    eIndex++;
                    bitpos = 1 << (32-1);
                    elen--;
                }
            }

            // Examine the window for pending multiplies
            if ((buf & tblmask) != 0) {
                multpos = ebits - wbits;
                while ((buf & 1) == 0) {
                    buf >>>= 1;
                    multpos++;
                }
                mult = table[buf >>> 1];
                buf = 0;
            }

            // Perform multiply
            if (ebits == multpos) {
                if (isone) {
                    b = mult.dup;
                    isone = false;
                } else {
                    t = b;
                    a = montgomeryMultiply(t, mult, mod, modLen, inv, a);
                    t = a; a = b; b = t;
                }
            }

            // Check if done
            if (ebits == 0)
                break;

            // Square the input
            if (!isone) {
                t = b;
                a = montgomerySquare(t, mod, modLen, inv, a);
                t = a; a = b; b = t;
            }
        }

        // Convert result out of Montgomery form and return
        int[] t2 = new int[2*modLen];
        // System.arraycopy(b, 0, t2, modLen, modLen);
        t2[modLen .. modLen+modLen] = b[0 .. modLen];
        b = montReduce(t2, mod, modLen, cast(int)inv);
        // t2 = Arrays.copyOf(b, modLen);
        t2 = b[0 .. modLen].dup;

        return new BigInteger(1, t2);
    }

    /**
     * Montgomery reduce n, modulo mod.  This reduces modulo mod and divides
     * by 2^(32*mlen). Adapted from Colin Plumb's C library.
     */
    private static int[] montReduce(int[] n, int[] mod, int mlen, int inv) {
        int c=0;
        int len = mlen;
        int offset=0;

        do {
            int nEnd = n[n.length-1-offset];
            int carry = mulAdd(n, mod, offset, mlen, inv * nEnd);
            c += addOne(n, offset, mlen, carry);
            offset++;
        } while (--len > 0);

        while (c > 0)
            c += subN(n, mod, mlen);

        while (intArrayCmpToLen(n, mod, mlen) >= 0)
            subN(n, mod, mlen);

        return n;
    }


    /*
     * Returns -1, 0 or +1 as big-endian unsigned int array arg1 is less than,
     * equal to, or greater than arg2 up to length len.
     */
    private static int intArrayCmpToLen(int[] arg1, int[] arg2, int len) {
        for (int i=0; i < len; i++) {
            long b1 = arg1[i] & LONG_MASK;
            long b2 = arg2[i] & LONG_MASK;
            if (b1 < b2)
                return -1;
            if (b1 > b2)
                return 1;
        }
        return 0;
    }

    /**
     * Subtracts two numbers of same length, returning borrow.
     */
    private static int subN(int[] a, int[] b, int len) {
        long sum = 0;

        while (--len >= 0) {
            sum = (a[len] & LONG_MASK) -
                 (b[len] & LONG_MASK) + (sum >> 32);
            a[len] = cast(int)sum;
        }

        return cast(int)(sum >> 32);
    }

    /**
     * Multiply an array by one word k and add to result, return the carry
     */
    static int mulAdd(int[] ot, int[] input, int offset, int len, int k) {
        implMulAddCheck(ot, input, offset, len, k);
        return implMulAdd(ot, input, offset, len, k);
    }

    /**
     * Parameters validation.
     */
    private static void implMulAddCheck(int[] ot, int[] input, int offset, int len, int k) {
        if (len > input.length) {
            throw new IllegalArgumentException("input length is out of bound: " ~ len.to!string() ~ " > " ~ to!string(input.length));
        }
        if (offset < 0) {
            throw new IllegalArgumentException("input offset is invalid: " ~ offset.to!string());
        }
        if (offset > (ot.length - 1)) {
            throw new IllegalArgumentException("input offset is out of bound: " ~ offset.to!string() ~ " > " ~ to!string(ot.length - 1));
        }
        if (len > (ot.length - offset)) {
            throw new IllegalArgumentException("input len is out of bound: " ~ len.to!string() ~ " > " ~ to!string(ot.length - offset));
        }
    }

    /**
     * Java Runtime may use intrinsic for this method.
     */
    
    private static int implMulAdd(int[] output, int[] input, int offset, int len, int k) {
        long kLong = k & LONG_MASK;
        long carry = 0;

        offset = cast(int)output.length-offset - 1;
        for (int j=len-1; j >= 0; j--) {
            long product = (input[j] & LONG_MASK) * kLong +
                           (output[offset] & LONG_MASK) + carry;
            output[offset--] = cast(int)product;
            carry = product >>> 32;
        }
        return cast(int)carry;
    }

    /**
     * Add one word to the number a mlen words into a. Return the resulting
     * carry.
     */
    static int addOne(int[] a, int offset, int mlen, int carry) {
        offset = cast(int)a.length-1-mlen-offset;
        long t = (a[offset] & LONG_MASK) + (carry & LONG_MASK);

        a[offset] = cast(int)t;
        if ((t >>> 32) == 0)
            return 0;
        while (--mlen >= 0) {
            if (--offset < 0) { // Carry out of number
                return 1;
            } else {
                a[offset]++;
                if (a[offset] != 0)
                    return 0;
            }
        }
        return 1;
    }

    /**
     * Returns a BigInteger whose value is (this ** exponent) mod (2**p)
     */
    private BigInteger modPow2(BigInteger exponent, int p) {
        /*
         * Perform exponentiation using repeated squaring trick, chopping off
         * high order bits as indicated by modulus.
         */
        BigInteger result = ONE;
        BigInteger baseToPow2 = this.mod2(p);
        int expOffset = 0;

        int limit = exponent.bitLength();

        if (this.testBit(0))
           limit = (p-1) < limit ? (p-1) : limit;

        while (expOffset < limit) {
            if (exponent.testBit(expOffset))
                result = result.multiply(baseToPow2).mod2(p);
            expOffset++;
            if (expOffset < limit)
                baseToPow2 = baseToPow2.square().mod2(p);
        }

        return result;
    }

    /**
     * Returns a BigInteger whose value is this mod(2**p).
     * Assumes that this {@code BigInteger >= 0} and {@code p > 0}.
     */
    private BigInteger mod2(int p) {
        if (bitLength() <= p)
            return this;

        // Copy remaining ints of mag
        int numInts = (p + 31) >>> 5;
        int[] mag = new int[numInts];
        // System.arraycopy(this.mag, (this.mag.length - numInts), mag, 0, numInts);
        mag[0..numInts] = this.mag[$-numInts .. $].dup;

        // Mask out any excess bits
        int excessBits = (numInts << 5) - p;
        mag[0] &= (1L << (32-excessBits)) - 1;

        return (mag[0] == 0 ? new BigInteger(1, mag) : new BigInteger(mag, 1));
    }

    /**
     * Returns a BigInteger whose value is {@code (this}<sup>-1</sup> {@code mod m)}.
     *
     * @param  m the modulus.
     * @return {@code this}<sup>-1</sup> {@code mod m}.
     * @throws ArithmeticException {@code  m} &le; 0, or this BigInteger
     *         has no multiplicative inverse mod m (that is, this BigInteger
     *         is not <i>relatively prime</i> to m).
     */
    BigInteger modInverse(BigInteger m) {
        if (m.signum != 1)
            throw new ArithmeticException("BigInteger: modulus not positive");

        if (m.equals(ONE))
            return ZERO;

        // Calculate (this mod m)
        BigInteger modVal = this;
        if (signum < 0 || (this.compareMagnitude(m) >= 0))
            modVal = this.mod(m);

        if (modVal.equals(ONE))
            return ONE;

        MutableBigInteger a = new MutableBigInteger(modVal);
        MutableBigInteger b = new MutableBigInteger(m);

        MutableBigInteger result = a.mutableModInverse(b);
        return result.toBigInteger(1);
    }

    // Shift Operations

    /**
     * Returns a BigInteger whose value is {@code (this << n)}.
     * The shift distance, {@code n}, may be negative, in which case
     * this method performs a right shift.
     * (Computes <code>floor(this * 2<sup>n</sup>)</code>.)
     *
     * @param  n shift distance, in bits.
     * @return {@code this << n}
     * @see #shiftRight
     */
    BigInteger shiftLeft(int n) {
        if (_signum == 0)
            return ZERO;
        if (n > 0) {
            return new BigInteger(shiftLeft(mag, n), signum);
        } else if (n == 0) {
            return this;
        } else {
            // Possible int overflow in (-n) is not a trouble,
            // because shiftRightImpl considers its argument unsigned
            return shiftRightImpl(-n);
        }
    }

    /**
     * Returns a magnitude array whose value is {@code (mag << n)}.
     * The shift distance, {@code n}, is considered unnsigned.
     * (Computes <code>this * 2<sup>n</sup></code>.)
     *
     * @param mag magnitude, the most-significant int ({@code mag[0]}) must be non-zero.
     * @param  n unsigned shift distance, in bits.
     * @return {@code mag << n}
     */
    private static int[] shiftLeft(int[] mag, int n) {
        int nInts = n >>> 5;
        int nBits = n & 0x1f;
        int magLen = cast(int)mag.length;
        int[] newMag = null;

        if (nBits == 0) {
            newMag = new int[magLen + nInts];
            // System.arraycopy(mag, 0, newMag, 0, magLen);
            newMag[0..magLen] = mag[0..magLen].dup;
        } else {
            int i = 0;
            int nBits2 = 32 - nBits;
            int highBits = mag[0] >>> nBits2;
            if (highBits != 0) {
                newMag = new int[magLen + nInts + 1];
                newMag[i++] = highBits;
            } else {
                newMag = new int[magLen + nInts];
            }
            int j=0;
            while (j < magLen-1)
                newMag[i++] = mag[j++] << nBits | mag[j] >>> nBits2;
            newMag[i] = mag[j] << nBits;
        }
        return newMag;
    }

    /**
     * Returns a BigInteger whose value is {@code (this >> n)}.  Sign
     * extension is performed.  The shift distance, {@code n}, may be
     * negative, in which case this method performs a left shift.
     * (Computes <code>floor(this / 2<sup>n</sup>)</code>.)
     *
     * @param  n shift distance, in bits.
     * @return {@code this >> n}
     * @see #shiftLeft
     */
    BigInteger shiftRight(int n) {
        if (_signum == 0)
            return ZERO;
        if (n > 0) {
            return shiftRightImpl(n);
        } else if (n == 0) {
            return this;
        } else {
            // Possible int overflow in {@code -n} is not a trouble,
            // because shiftLeft considers its argument unsigned
            return new BigInteger(shiftLeft(mag, -n), signum);
        }
    }

    /**
     * Returns a BigInteger whose value is {@code (this >> n)}. The shift
     * distance, {@code n}, is considered unsigned.
     * (Computes <code>floor(this * 2<sup>-n</sup>)</code>.)
     *
     * @param  n unsigned shift distance, in bits.
     * @return {@code this >> n}
     */
    private BigInteger shiftRightImpl(int n) {
        int nInts = n >>> 5;
        int nBits = n & 0x1f;
        int magLen = cast(int)mag.length;
        int[] newMag = null;

        // Special case: entire contents shifted off the end
        if (nInts >= magLen)
            return (signum >= 0 ? ZERO : negConst[1]);

        if (nBits == 0) {
            int newMagLen = magLen - nInts;
            // newMag = Arrays.copyOf(mag, newMagLen);
            newMag = mag[0..newMagLen].dup;
        } else {
            int i = 0;
            int highBits = mag[0] >>> nBits;
            if (highBits != 0) {
                newMag = new int[magLen - nInts];
                newMag[i++] = highBits;
            } else {
                newMag = new int[magLen - nInts -1];
            }

            int nBits2 = 32 - nBits;
            int j=0;
            while (j < magLen - nInts - 1)
                newMag[i++] = (mag[j++] << nBits2) | (mag[j] >>> nBits);
        }

        if (signum < 0) {
            // Find out whether any one-bits were shifted off the end.
            bool onesLost = false;
            for (int i=magLen-1, j=magLen-nInts; i >= j && !onesLost; i--)
                onesLost = (mag[i] != 0);
            if (!onesLost && nBits != 0)
                onesLost = (mag[magLen - nInts - 1] << (32 - nBits) != 0);

            if (onesLost)
                newMag = javaIncrement(newMag);
        }

        return new BigInteger(newMag, signum);
    }

    int[] javaIncrement(int[] val) {
        int lastSum = 0;
        for (size_t i=val.length-1;  i >= 0 && lastSum == 0; i--)
            lastSum = (val[i] += 1);
        if (lastSum == 0) {
            val = new int[val.length+1];
            val[0] = 1;
        }
        return val;
    }

    // Bitwise Operations

    /**
     * Returns a BigInteger whose value is {@code (this & val)}.  (This
     * method returns a negative BigInteger if and only if this and val are
     * both negative.)
     *
     * @param val value to be AND'ed with this BigInteger.
     * @return {@code this & val}
     */
    BigInteger and(BigInteger val) {
        int[] result = new int[std.algorithm.max(intLength(), val.intLength())];
        for (int i=0; i < cast(int)result.length; i++)
            result[i] = (getInt(cast(int)result.length-i-1)
                         & val.getInt(cast(int)result.length-i-1));

        return valueOf(result);
    }

    /**
     * Returns a BigInteger whose value is {@code (this | val)}.  (This method
     * returns a negative BigInteger if and only if either this or val is
     * negative.)
     *
     * @param val value to be OR'ed with this BigInteger.
     * @return {@code this | val}
     */
    BigInteger or(BigInteger val) {
        int[] result = new int[std.algorithm.max(intLength(), val.intLength())];
        for (int i=0; i < cast(int)result.length; i++)
            result[i] = (getInt(cast(int)result.length-i-1)
                         | val.getInt(cast(int)result.length-i-1));

        return valueOf(result);
    }

    /**
     * Returns a BigInteger whose value is {@code (this ^ val)}.  (This method
     * returns a negative BigInteger if and only if exactly one of this and
     * val are negative.)
     *
     * @param val value to be XOR'ed with this BigInteger.
     * @return {@code this ^ val}
     */
    BigInteger xor(BigInteger val) {
        int[] result = new int[std.algorithm.max(intLength(), val.intLength())];
        for (int i=0; i < cast(int)result.length; i++)
            result[i] = (getInt(cast(int)result.length-i-1)
                         ^ val.getInt(cast(int)result.length-i-1));

        return valueOf(result);
    }

    /**
     * Returns a BigInteger whose value is {@code (~this)}.  (This method
     * returns a negative value if and only if this BigInteger is
     * non-negative.)
     *
     * @return {@code ~this}
     */
    BigInteger not() {
        int[] result = new int[intLength()];
        for (int i=0; i < cast(int)result.length; i++)
            result[i] = ~getInt(cast(int)result.length-i-1);

        return valueOf(result);
    }

    /**
     * Returns a BigInteger whose value is {@code (this & ~val)}.  This
     * method, which is equivalent to {@code and(val.not())}, is provided as
     * a convenience for masking operations.  (This method returns a negative
     * BigInteger if and only if {@code this} is negative and {@code val} is
     * positive.)
     *
     * @param val value to be complemented and AND'ed with this BigInteger.
     * @return {@code this & ~val}
     */
    BigInteger andNot(BigInteger val) {
        int[] result = new int[std.algorithm.max(intLength(), val.intLength())];
        for (int i=0; i < cast(int)result.length; i++)
            result[i] = (getInt(cast(int)result.length-i-1)
                         & ~val.getInt(cast(int)result.length-i-1));

        return valueOf(result);
    }


    // Single Bit Operations

    /**
     * Returns {@code true} if and only if the designated bit is set.
     * (Computes {@code ((this & (1<<n)) != 0)}.)
     *
     * @param  n index of bit to test.
     * @return {@code true} if and only if the designated bit is set.
     * @throws ArithmeticException {@code n} is negative.
     */
    bool testBit(int n) {
        if (n < 0)
            throw new ArithmeticException("Negative bit address");

        return (getInt(n >>> 5) & (1 << (n & 31))) != 0;
    }

    /**
     * Returns a BigInteger whose value is equivalent to this BigInteger
     * with the designated bit set.  (Computes {@code (this | (1<<n))}.)
     *
     * @param  n index of bit to set.
     * @return {@code this | (1<<n)}
     * @throws ArithmeticException {@code n} is negative.
     */
    BigInteger setBit(int n) {
        if (n < 0)
            throw new ArithmeticException("Negative bit address");

        int intNum = n >>> 5;
        int[] result = new int[std.algorithm.max(intLength(), intNum+2)];

        for (int i=0; i < cast(int)result.length; i++)
            result[result.length-i-1] = getInt(i);

        result[result.length-intNum-1] |= (1 << (n & 31));

        return valueOf(result);
    }

    /**
     * Returns a BigInteger whose value is equivalent to this BigInteger
     * with the designated bit cleared.
     * (Computes {@code (this & ~(1<<n))}.)
     *
     * @param  n index of bit to clear.
     * @return {@code this & ~(1<<n)}
     * @throws ArithmeticException {@code n} is negative.
     */
    BigInteger clearBit(int n) {
        if (n < 0)
            throw new ArithmeticException("Negative bit address");

        int intNum = n >>> 5;
        int[] result = new int[std.algorithm.max(intLength(), ((n + 1) >>> 5) + 1)];

        for (int i=0; i < cast(int)result.length; i++)
            result[result.length-i-1] = getInt(i);

        result[result.length-intNum-1] &= ~(1 << (n & 31));

        return valueOf(result);
    }

    /**
     * Returns a BigInteger whose value is equivalent to this BigInteger
     * with the designated bit flipped.
     * (Computes {@code (this ^ (1<<n))}.)
     *
     * @param  n index of bit to flip.
     * @return {@code this ^ (1<<n)}
     * @throws ArithmeticException {@code n} is negative.
     */
    BigInteger flipBit(int n) {
        if (n < 0)
            throw new ArithmeticException("Negative bit address");

        int intNum = n >>> 5;
        int[] result = new int[std.algorithm.max(intLength(), intNum+2)];

        for (int i=0; i < cast(int)result.length; i++)
            result[result.length-i-1] = getInt(i);

        result[result.length-intNum-1] ^= (1 << (n & 31));

        return valueOf(result);
    }

    /**
     * Returns the index of the rightmost (lowest-order) one bit in this
     * BigInteger (the number of zero bits to the right of the rightmost
     * one bit).  Returns -1 if this BigInteger contains no one bits.
     * (Computes {@code (this == 0? -1 : log2(this & -this))}.)
     *
     * @return index of the rightmost one bit in this BigInteger.
     */
    int getLowestSetBit() {
        int lsb = lowestSetBitPlusTwo - 2;
        if (lsb == -2) {  // lowestSetBit not initialized yet
            lsb = 0;
            if (_signum == 0) {
                lsb -= 1;
            } else {
                // Search for lowest order nonzero int
                int i,b;
                for (i=0; (b = getInt(i)) == 0; i++) {}
                lsb += (i << 5) + Integer.numberOfTrailingZeros(b);
            }
            lowestSetBitPlusTwo = lsb + 2;
        }
        return lsb;
    }


    // Miscellaneous Bit Operations

    /**
     * Returns the number of bits in the minimal two's-complement
     * representation of this BigInteger, <em>excluding</em> a sign bit.
     * For positive BigIntegers, this is equivalent to the number of bits in
     * the ordinary binary representation.  (Computes
     * {@code (ceil(log2(this < 0 ? -this : this+1)))}.)
     *
     * @return number of bits in the minimal two's-complement
     *         representation of this BigInteger, <em>excluding</em> a sign bit.
     */
    int bitLength() {
        int n = bitLengthPlusOne - 1;
        if (n == -1) { // bitLength not initialized yet
            int[] m = mag;
            int len = cast(int)m.length;
            if (len == 0) {
                n = 0; // offset by one to initialize
            }  else {
                // Calculate the bit length of the magnitude
                int magBitLength = ((len - 1) << 5) + bitLengthForInt(mag[0]);
                 if (signum < 0) {
                     // Check if magnitude is a power of two
                     bool pow2 = (Integer.bitCount(mag[0]) == 1);
                     for (int i=1; i< len && pow2; i++)
                         pow2 = (mag[i] == 0);

                     n = (pow2 ? magBitLength -1 : magBitLength);
                 } else {
                     n = magBitLength;
                 }
            }
            bitLengthPlusOne = n + 1;
        }
        return n;
    }

    /**
     * Returns the number of bits in the two's complement representation
     * of this BigInteger that differ from its sign bit.  This method is
     * useful when implementing bit-vector style sets atop BigIntegers.
     *
     * @return number of bits in the two's complement representation
     *         of this BigInteger that differ from its sign bit.
     */
    int bitCount() {
        int bc = bitCountPlusOne - 1;
        if (bc == -1) {  // bitCount not initialized yet
            bc = 0;      // offset by one to initialize
            // Count the bits in the magnitude
            for (int i=0; i < mag.length; i++)
                bc += Integer.bitCount(mag[i]);
            if (signum < 0) {
                // Count the trailing zeros in the magnitude
                int magTrailingZeroCount = 0, j;
                for (j=cast(int)mag.length-1; mag[j] == 0; j--)
                    magTrailingZeroCount += 32;
                magTrailingZeroCount += Integer.numberOfTrailingZeros(mag[j]);
                bc += magTrailingZeroCount - 1;
            }
            bitCountPlusOne = bc + 1;
        }
        return bc;
    }

    // Primality Testing

    /**
     * Returns {@code true} if this BigInteger is probably prime,
     * {@code false} if it's definitely composite.  If
     * {@code certainty} is &le; 0, {@code true} is
     * returned.
     *
     * @param  certainty a measure of the uncertainty that the caller is
     *         willing to tolerate: if the call returns {@code true}
     *         the probability that this BigInteger is prime exceeds
     *         (1 - 1/2<sup>{@code certainty}</sup>).  The execution time of
     *         this method is proportional to the value of this parameter.
     * @return {@code true} if this BigInteger is probably prime,
     *         {@code false} if it's definitely composite.
     */
    bool isProbablePrime(int certainty) {
        if (certainty <= 0)
            return true;
        BigInteger w = this.abs();
        if (w.equals(TWO))
            return true;
        if (!w.testBit(0) || w.equals(ONE))
            return false;

        return w.primeToCertainty(certainty, null);
    }

    // Comparison Operations

    /**
     * Compares this BigInteger with the specified BigInteger.  This
     * method is provided in preference to individual methods for each
     * of the six bool comparison operators ({@literal <}, ==,
     * {@literal >}, {@literal >=}, !=, {@literal <=}).  The suggested
     * idiom for performing these comparisons is: {@code
     * (x.compareTo(y)} &lt;<i>op</i>&gt; {@code 0)}, where
     * &lt;<i>op</i>&gt; is one of the six comparison operators.
     *
     * @param  val BigInteger to which this BigInteger is to be compared.
     * @return -1, 0 or 1 as this BigInteger is numerically less than, equal
     *         to, or greater than {@code val}.
     */
    int compareTo(BigInteger val) {
        if (_signum == val.signum) {
            switch (signum) {
            case 1:
                return compareMagnitude(val);
            case -1:
                return val.compareMagnitude(this);
            default:
                return 0;
            }
        }
        return signum > val.signum ? 1 : -1;
    }

    /**
     * Compares the magnitude array of this BigInteger with the specified
     * BigInteger's. This is the version of compareTo ignoring sign.
     *
     * @param val BigInteger whose magnitude array to be compared.
     * @return -1, 0 or 1 as this magnitude array is less than, equal to or
     *         greater than the magnitude aray for the specified BigInteger's.
     */
    final int compareMagnitude(BigInteger val) {
        int[] m1 = mag;
        int len1 = cast(int)m1.length;
        int[] m2 = val.mag;
        int len2 = cast(int)m2.length;
        if (len1 < len2)
            return -1;
        if (len1 > len2)
            return 1;
        for (int i = 0; i < len1; i++) {
            int a = m1[i];
            int b = m2[i];
            if (a != b)
                return ((a & LONG_MASK) < (b & LONG_MASK)) ? -1 : 1;
        }
        return 0;
    }

    /**
     * Version of compareMagnitude that compares magnitude with long value.
     * val can't be long.min.
     */
    final int compareMagnitude(long val) {
        assert(val != long.min);
        int[] m1 = mag;
        int len = cast(int)m1.length;
        if (len > 2) {
            return 1;
        }
        if (val < 0) {
            val = -val;
        }
        int highWord = cast(int)(val >>> 32);
        if (highWord == 0) {
            if (len < 1)
                return -1;
            if (len > 1)
                return 1;
            int a = m1[0];
            int b = cast(int)val;
            if (a != b) {
                return ((a & LONG_MASK) < (b & LONG_MASK))? -1 : 1;
            }
            return 0;
        } else {
            if (len < 2)
                return -1;
            int a = m1[0];
            int b = highWord;
            if (a != b) {
                return ((a & LONG_MASK) < (b & LONG_MASK))? -1 : 1;
            }
            a = m1[1];
            b = cast(int)val;
            if (a != b) {
                return ((a & LONG_MASK) < (b & LONG_MASK))? -1 : 1;
            }
            return 0;
        }
    }

    /**
     * Compares this BigInteger with the specified Object for equality.
     *
     * @param  x Object to which this BigInteger is to be compared.
     * @return {@code true} if and only if the specified Object is a
     *         BigInteger whose value is numerically equal to this BigInteger.
     */
    bool equals(Object x) {
        return opEquals(x);
    }

    override bool opEquals(Object x) {
        // This test is just an optimization, which may or may not help
        if (x is this)
            return true;

        BigInteger xInt = cast(BigInteger) x;
        if(xInt is null)
            return false;
        if (xInt.signum != signum)
            return false;

        int[] m = mag;
        int len = cast(int)m.length;
        int[] xm = xInt.mag;
        if (len != xm.length)
            return false;

        for (int i = 0; i < len; i++)
            if (xm[i] != m[i])
                return false;

        return true;
    }

    /**
     * Returns the minimum of this BigInteger and {@code val}.
     *
     * @param  val value with which the minimum is to be computed.
     * @return the BigInteger whose value is the lesser of this BigInteger and
     *         {@code val}.  If they are equal, either may be returned.
     */
    BigInteger min(BigInteger val) {
        return (compareTo(val) < 0 ? this : val);
    }

    /**
     * Returns the maximum of this BigInteger and {@code val}.
     *
     * @param  val value with which the maximum is to be computed.
     * @return the BigInteger whose value is the greater of this and
     *         {@code val}.  If they are equal, either may be returned.
     */
    BigInteger max(BigInteger val) {
        return (compareTo(val) > 0 ? this : val);
    }


    // Hash Function

    /**
     * Returns the hash code for this BigInteger.
     *
     * @return hash code for this BigInteger.
     */
    size_t hashCode() {
        return toHash();
    }

    override size_t toHash() @trusted nothrow {
        size_t hashCode = 0;

        for (size_t i=0; i < mag.length; i++)
            hashCode = cast(size_t)(31*hashCode + (mag[i] & LONG_MASK));

        return hashCode * _signum;
    }

    /**
     * Returns the string representation of this BigInteger in the
     * given radix.  If the radix is outside the range from {@link
     * Character#MIN_RADIX} to {@link Character#MAX_RADIX} inclusive,
     * it will default to 10 (as is the case for
     * {@code Integer.toString}).  The digit-to-character mapping
     * provided by {@code Character.forDigit} is used, and a minus
     * sign is prepended if appropriate.  (This representation is
     * compatible with the {@link #BigInteger(string, int) (string,
     * int)} constructor.)
     *
     * @param  radix  radix of the string representation.
     * @return string representation of this BigInteger in the given radix.
     * @see    Integer#toString
     * @see    Character#forDigit
     * @see    #BigInteger(java.lang.string, int)
     */
    string toString(int radix) {
        if (_signum == 0)
            return "0";
        if (radix < Character.MIN_RADIX || radix > Character.MAX_RADIX)
            radix = 10;

        // If it's small enough, use smallToString.
        if (mag.length <= SCHOENHAGE_BASE_CONVERSION_THRESHOLD)
           return smallToString(radix);

        // Otherwise use recursive toString, which requires positive arguments.
        // The results will be concatenated into this StringBuilder
        StringBuilder sb = new StringBuilder();
        string r;
        if (signum < 0) {
            toString(this.negate(), sb, radix, 0);
            // sb.insert(0, '-');
            r = "-" ~ sb.toString();
        }
        else {
            toString(this, sb, radix, 0);
            r = sb.toString();
        }

        return r;
    }

    /** This method is used to perform toString when arguments are small. */
    private string smallToString(int radix) {
        if (_signum == 0) {
            return "0";
        }

        // Compute upper bound on number of digit groups and allocate space
        int maxNumDigitGroups = cast(int)(4*mag.length + 6)/7;
        string[] digitGroup = new string[maxNumDigitGroups];

        // Translate number to string, a digit group at a time
        BigInteger tmp = this.abs();
        int numGroups = 0;
        while (tmp.signum != 0) {
            BigInteger d = longRadix[radix];

            MutableBigInteger q = new MutableBigInteger(),
                              a = new MutableBigInteger(tmp.mag),
                              b = new MutableBigInteger(d.mag);
            MutableBigInteger r = a.divide(b, q);
            BigInteger q2 = q.toBigInteger(tmp.signum * d.signum);
            BigInteger r2 = r.toBigInteger(tmp.signum * d.signum);

            digitGroup[numGroups++] = to!string(r2.longValue(), radix);
            tmp = q2;
        }

        // Put sign (if any) and first digit group into result buffer
        StringBuilder buf = new StringBuilder(numGroups*digitsPerLong[radix]+1);
        if (signum < 0) {
            buf.append('-');
        }
        buf.append(digitGroup[numGroups-1]);

        // Append remaining digit groups padded with leading zeros
        for (int i=numGroups-2; i >= 0; i--) {
            // Prepend (any) leading zeros for this digit group
            int numLeadingZeros = digitsPerLong[radix] - cast(int)digitGroup[i].length;
            if (numLeadingZeros != 0) {
                buf.append(zeros[numLeadingZeros]);
            }
            buf.append(digitGroup[i]);
        }
        return buf.toString();
    }

    /**
     * Converts the specified BigInteger to a string and appends to
     * {@code sb}.  This implements the recursive Schoenhage algorithm
     * for base conversions.
     * <p>
     * See Knuth, Donald,  _The Art of Computer Programming_, Vol. 2,
     * Answers to Exercises (4.4) Question 14.
     *
     * @param u      The number to convert to a string.
     * @param sb     The StringBuilder that will be appended to in place.
     * @param radix  The base to convert to.
     * @param digits The minimum number of digits to pad to.
     */
    private static void toString(BigInteger u, StringBuilder sb, int radix,
                                 int digits) {
        // If we're smaller than a certain threshold, use the smallToString
        // method, padding with leading zeroes when necessary.
        if (u.mag.length <= SCHOENHAGE_BASE_CONVERSION_THRESHOLD) {
            string s = u.smallToString(radix);

            // Pad with internal zeros if necessary.
            // Don't pad if we're at the beginning of the string.
            if ((s.length < digits) && (sb.length > 0)) {
                for (size_t i=s.length; i < digits; i++) {
                    sb.append('0');
                }
            }

            sb.append(s);
            return;
        }

        int b, n;
        b = u.bitLength();

        // Calculate a value for n in the equation radix^(2^n) = u
        // and subtract 1 from that value.  This is used to find the
        // cache index that contains the best value to divide u.
        n = cast(int) std.math.round(std.math.log(b * LOG_TWO / logCache[radix]) / LOG_TWO - 1.0);
        BigInteger v = getRadixConversionCache(radix, n);
        BigInteger[] results;
        results = u.divideAndRemainder(v);

        int expectedDigits = 1 << n;

        // Now recursively build the two halves of each number.
        toString(results[0], sb, radix, digits-expectedDigits);
        toString(results[1], sb, radix, expectedDigits);
    }

    /**
     * Returns the value radix^(2^exponent) from the cache.
     * If this value doesn't already exist in the cache, it is added.
     * <p>
     * This could be changed to a more complicated caching method using
     * {@code Future}.
     */
    private static BigInteger getRadixConversionCache(int radix, int exponent) {
        BigInteger[] cacheLine = powerCache[radix]; // read
        if (exponent < cacheLine.length) {
            return cacheLine[exponent];
        }

        int oldLength = cast(int)cacheLine.length;
        BigInteger[] oldCacheLine = cacheLine;
        cacheLine = new BigInteger[exponent + 1];
        cacheLine[0..oldLength] = oldCacheLine[0..$];
        // cacheLine = Arrays.copyOf(cacheLine, exponent + 1);
        for (int i = oldLength; i <= exponent; i++) {
            cacheLine[i] = cacheLine[i - 1].pow(2);
        }

        BigInteger[][] pc = powerCache; // read again
        if (exponent >= pc[radix].length) {
            pc = pc.dup;
            pc[radix] = cacheLine;
            powerCache = pc; // write, publish
        }
        return cacheLine[exponent];
    }

    /* zero[i] is a string of i consecutive zeros. */
    private __gshared static string[] zeros;
    shared static this() {
        zeros = new string[64];
        zeros[63] = "000000000000000000000000000000000000000000000000000000000000000";
        for (int i=0; i < 63; i++)
            zeros[i] = zeros[63][0 .. i];
    }

    /**
     * Returns the decimal string representation of this BigInteger.
     * The digit-to-character mapping provided by
     * {@code Character.forDigit} is used, and a minus sign is
     * prepended if appropriate.  (This representation is compatible
     * with the {@link #BigInteger(string) (string)} constructor, and
     * allows for string concatenation with Java's + operator.)
     *
     * @return decimal string representation of this BigInteger.
     * @see    Character#forDigit
     * @see    #BigInteger(java.lang.string)
     */
    override string toString() {
        return toString(10);
    }

    /**
     * Returns a byte array containing the two's-complement
     * representation of this BigInteger.  The byte array will be in
     * <i>big-endian</i> byte-order: the most significant byte is in
     * the zeroth element.  The array will contain the minimum number
     * of bytes required to represent this BigInteger, including at
     * least one sign bit, which is {@code (ceil((this.bitLength() +
     * 1)/8))}.  (This representation is compatible with the
     * {@link #BigInteger(byte[]) (byte[])} constructor.)
     *
     * @return a byte array containing the two's-complement representation of
     *         this BigInteger.
     * @see    #BigInteger(byte[])
     */
    byte[] toByteArray() {
        int byteLen = bitLength()/8 + 1;
        byte[] byteArray = new byte[byteLen];

        for (int i=byteLen-1, bytesCopied=4, nextInt=0, intIndex=0; i >= 0; i--) {
            if (bytesCopied == 4) {
                nextInt = getInt(intIndex++);
                bytesCopied = 1;
            } else {
                nextInt >>>= 8;
                bytesCopied++;
            }
            byteArray[i] = cast(byte)nextInt;
        }
        return byteArray;
    }

    /**
     * Converts this BigInteger to an {@code int}.  This
     * conversion is analogous to a
     * <i>narrowing primitive conversion</i> from {@code long} to
     * {@code int} as defined in
     * <cite>The Java&trade; Language Specification</cite>:
     * if this BigInteger is too big to fit in an
     * {@code int}, only the low-order 32 bits are returned.
     * Note that this conversion can lose information about the
     * overall magnitude of the BigInteger value as well as return a
     * result with the opposite sign.
     *
     * @return this BigInteger converted to an {@code int}.
     * @see #intValueExact()
     * @jls 5.1.3 Narrowing Primitive Conversion
     */
    int intValue() {
        int result = 0;
        result = getInt(0);
        return result;
    }

    /**
     * Converts this BigInteger to a {@code long}.  This
     * conversion is analogous to a
     * <i>narrowing primitive conversion</i> from {@code long} to
     * {@code int} as defined in
     * <cite>The Java&trade; Language Specification</cite>:
     * if this BigInteger is too big to fit in a
     * {@code long}, only the low-order 64 bits are returned.
     * Note that this conversion can lose information about the
     * overall magnitude of the BigInteger value as well as return a
     * result with the opposite sign.
     *
     * @return this BigInteger converted to a {@code long}.
     * @see #longValueExact()
     * @jls 5.1.3 Narrowing Primitive Conversion
     */
    long longValue() {
        long result = 0;

        for (int i=1; i >= 0; i--)
            result = (result << 32) + (getInt(i) & LONG_MASK);
        return result;
    }

    /**
     * Converts this BigInteger to a {@code float}.  This
     * conversion is similar to the
     * <i>narrowing primitive conversion</i> from {@code double} to
     * {@code float} as defined in
     * <cite>The Java&trade; Language Specification</cite>:
     * if this BigInteger has too great a magnitude
     * to represent as a {@code float}, it will be converted to
     * {@link Float#NEGATIVE_INFINITY} or {@link
     * Float#POSITIVE_INFINITY} as appropriate.  Note that even when
     * the return value is finite, this conversion can lose
     * information about the precision of the BigInteger value.
     *
     * @return this BigInteger converted to a {@code float}.
     * @jls 5.1.3 Narrowing Primitive Conversion
     */
    float floatValue() {
        if (_signum == 0) {
            return 0.0f;
        }

        int exponent =cast(int)(cast(int)(mag.length - 1) << 5) + bitLengthForInt(mag[0]) - 1;

        // exponent == floor(log2(abs(this)))
        if (exponent < Long.SIZE - 1) {
            return longValue();
        } else if (exponent > Float.MAX_EXPONENT) {
            return signum > 0 ? Float.POSITIVE_INFINITY : Float.NEGATIVE_INFINITY;
        }

        /*
         * We need the top SIGNIFICAND_WIDTH bits, including the "implicit"
         * one bit. To make rounding easier, we pick out the top
         * SIGNIFICAND_WIDTH + 1 bits, so we have one to help us round up or
         * down. twiceSignifFloor will contain the top SIGNIFICAND_WIDTH + 1
         * bits, and signifFloor the top SIGNIFICAND_WIDTH.
         *
         * It helps to consider the real number signif = abs(this) *
         * 2^(SIGNIFICAND_WIDTH - 1 - exponent).
         */
        int shift = exponent - FloatConsts.SIGNIFICAND_WIDTH;

        int twiceSignifFloor;
        // twiceSignifFloor will be == abs().shiftRight(shift).intValue()
        // We do the shift into an int directly to improve performance.

        int nBits = shift & 0x1f;
        int nBits2 = 32 - nBits;

        if (nBits == 0) {
            twiceSignifFloor = mag[0];
        } else {
            twiceSignifFloor = mag[0] >>> nBits;
            if (twiceSignifFloor == 0) {
                twiceSignifFloor = (mag[0] << nBits2) | (mag[1] >>> nBits);
            }
        }

        int signifFloor = twiceSignifFloor >> 1;
        signifFloor &= FloatConsts.SIGNIF_BIT_MASK; // remove the implied bit

        /*
         * We round up if either the fractional part of signif is strictly
         * greater than 0.5 (which is true if the 0.5 bit is set and any lower
         * bit is set), or if the fractional part of signif is >= 0.5 and
         * signifFloor is odd (which is true if both the 0.5 bit and the 1 bit
         * are set). This is equivalent to the desired HALF_EVEN rounding.
         */
        bool increment = (twiceSignifFloor & 1) != 0
                && ((signifFloor & 1) != 0 || abs().getLowestSetBit() < shift);
        int signifRounded = increment ? signifFloor + 1 : signifFloor;
        int bits = ((exponent + FloatConsts.EXP_BIAS))
                << (FloatConsts.SIGNIFICAND_WIDTH - 1);
        bits += signifRounded;
        /*
         * If signifRounded == 2^24, we'd need to set all of the significand
         * bits to zero and add 1 to the exponent. This is exactly the behavior
         * we get from just adding signifRounded to bits directly. If the
         * exponent is Float.MAX_EXPONENT, we round up (correctly) to
         * Float.POSITIVE_INFINITY.
         */
        bits |= signum & FloatConsts.SIGN_BIT_MASK;
        return Float.intBitsToFloat(bits);
    }

    /**
     * Converts this BigInteger to a {@code double}.  This
     * conversion is similar to the
     * <i>narrowing primitive conversion</i> from {@code double} to
     * {@code float} as defined in
     * <cite>The Java&trade; Language Specification</cite>:
     * if this BigInteger has too great a magnitude
     * to represent as a {@code double}, it will be converted to
     * {@link Double#NEGATIVE_INFINITY} or {@link
     * Double#POSITIVE_INFINITY} as appropriate.  Note that even when
     * the return value is finite, this conversion can lose
     * information about the precision of the BigInteger value.
     *
     * @return this BigInteger converted to a {@code double}.
     * @jls 5.1.3 Narrowing Primitive Conversion
     */
    double doubleValue() {
        if (_signum == 0) {
            return 0.0;
        }

        int exponent = (cast(int)(mag.length - 1) << 5) + bitLengthForInt(mag[0]) - 1;

        // exponent == floor(log2(abs(this))Double)
        if (exponent < Long.SIZE - 1) {
            return longValue();
        } else if (exponent > Double.MAX_EXPONENT) {
            return signum > 0 ? Double.POSITIVE_INFINITY : Double.NEGATIVE_INFINITY;
        }

        /*
         * We need the top SIGNIFICAND_WIDTH bits, including the "implicit"
         * one bit. To make rounding easier, we pick out the top
         * SIGNIFICAND_WIDTH + 1 bits, so we have one to help us round up or
         * down. twiceSignifFloor will contain the top SIGNIFICAND_WIDTH + 1
         * bits, and signifFloor the top SIGNIFICAND_WIDTH.
         *
         * It helps to consider the real number signif = abs(this) *
         * 2^(SIGNIFICAND_WIDTH - 1 - exponent).
         */
        int shift = exponent - DoubleConsts.SIGNIFICAND_WIDTH;

        long twiceSignifFloor;
        // twiceSignifFloor will be == abs().shiftRight(shift).longValue()
        // We do the shift into a long directly to improve performance.

        int nBits = shift & 0x1f;
        int nBits2 = 32 - nBits;

        int highBits;
        int lowBits;
        if (nBits == 0) {
            highBits = mag[0];
            lowBits = mag[1];
        } else {
            highBits = mag[0] >>> nBits;
            lowBits = (mag[0] << nBits2) | (mag[1] >>> nBits);
            if (highBits == 0) {
                highBits = lowBits;
                lowBits = (mag[1] << nBits2) | (mag[2] >>> nBits);
            }
        }

        twiceSignifFloor = ((highBits & LONG_MASK) << 32)
                | (lowBits & LONG_MASK);

        long signifFloor = twiceSignifFloor >> 1;
        signifFloor &= DoubleConsts.SIGNIF_BIT_MASK; // remove the implied bit

        /*
         * We round up if either the fractional part of signif is strictly
         * greater than 0.5 (which is true if the 0.5 bit is set and any lower
         * bit is set), or if the fractional part of signif is >= 0.5 and
         * signifFloor is odd (which is true if both the 0.5 bit and the 1 bit
         * are set). This is equivalent to the desired HALF_EVEN rounding.
         */
        bool increment = (twiceSignifFloor & 1) != 0
                && ((signifFloor & 1) != 0 || abs().getLowestSetBit() < shift);
        long signifRounded = increment ? signifFloor + 1 : signifFloor;
        long bits = cast(long) ((exponent + DoubleConsts.EXP_BIAS))
                << (DoubleConsts.SIGNIFICAND_WIDTH - 1);
        bits += signifRounded;
        /*
         * If signifRounded == 2^53, we'd need to set all of the significand
         * bits to zero and add 1 to the exponent. This is exactly the behavior
         * we get from just adding signifRounded to bits directly. If the
         * exponent is Double.MAX_EXPONENT, we round up (correctly) to
         * Double.POSITIVE_INFINITY.
         */
        bits |= signum & DoubleConsts.SIGN_BIT_MASK;
        return Double.longBitsToDouble(bits);
    }


    byte byteValue() {
        return cast(byte) intValue();
    }

    short shortValue() {
        return cast(short) intValue();
    }

    /**
     * Returns a copy of the input array stripped of any leading zero bytes.
     */
    private static int[] stripLeadingZeroInts(int[] val) {
        int vlen = cast(int)val.length;
        int keep;

        // Find first nonzero byte
        for (keep = 0; keep < vlen && val[keep] == 0; keep++){}
        return val[keep .. vlen].dup; // java.util.Arrays.copyOfRange(val, keep, vlen);
    }

    /**
     * Returns the input array stripped of any leading zero bytes.
     * Since the source is trusted the copying may be skipped.
     */
    private static int[] trustedStripLeadingZeroInts(int[] val) {
        int vlen = cast(int)val.length;
        int keep;

        // Find first nonzero byte
        for (keep = 0; keep < vlen && val[keep] == 0; keep++){}
        return keep == 0 ? val : val[keep .. vlen].dup; // java.util.Arrays.copyOfRange(val, keep, vlen);
    }

    /**
     * Returns a copy of the input array stripped of any leading zero bytes.
     */
    private static int[] stripLeadingZeroBytes(byte[] a, int off, int len) {
        int indexBound = off + len;
        int keep;

        // Find first nonzero byte
        for (keep = off; keep < indexBound && a[keep] == 0; keep++){}

        // Allocate new array and copy relevant part of input array
        int intLength = ((indexBound - keep) + 3) >>> 2;
        int[] result = new int[intLength];
        int b = indexBound - 1;
        for (int i = intLength-1; i >= 0; i--) {
            result[i] = a[b--] & 0xff;
            int bytesRemaining = b - keep + 1;
            int bytesToTransfer = std.algorithm.min(3, bytesRemaining); 
            for (int j=8; j <= (bytesToTransfer << 3); j += 8)
                result[i] |= ((a[b--] & 0xff) << j);
        }
        return result;
    }

    /**
     * Takes an array a representing a negative 2's-complement number and
     * returns the minimal (no leading zero bytes) unsigned whose value is -a.
     */
    private static int[] makePositive(byte[] a, int off, int len) {
        int keep, k;
        int indexBound = off + len;

        // Find first non-sign (0xff) byte of input
        for (keep=off; keep < indexBound && a[keep] == -1; keep++) {}


        /* Allocate output array.  If all non-sign bytes are 0x00, we must
         * allocate space for one extra output byte. */
        for (k=keep; k < indexBound && a[k] == 0; k++) {}

        int extraByte = (k == indexBound) ? 1 : 0;
        int intLength = ((indexBound - keep + extraByte) + 3) >>> 2;
        int[] result = new int[intLength];

        /* Copy one's complement of input into output, leaving extra
         * byte (if it exists) == 0x00 */
        int b = indexBound - 1;
        for (int i = intLength-1; i >= 0; i--) {
            result[i] = a[b--] & 0xff;
            int numBytesToTransfer = std.algorithm.min(3, b-keep+1);
            if (numBytesToTransfer < 0)
                numBytesToTransfer = 0;
            for (int j=8; j <= 8*numBytesToTransfer; j += 8)
                result[i] |= ((a[b--] & 0xff) << j);

            // Mask indicates which bits must be complemented
            int mask = -1 >>> (8*(3-numBytesToTransfer));
            result[i] = ~result[i] & mask;
        }

        // Add one to one's complement to generate two's complement
        for (size_t i=result.length-1; i >= 0; i--) {
            result[i] = cast(int)((result[i] & LONG_MASK) + 1);
            if (result[i] != 0)
                break;
        }

        return result;
    }

    /**
     * Takes an array a representing a negative 2's-complement number and
     * returns the minimal (no leading zero ints) unsigned whose value is -a.
     */
    private static int[] makePositive(int[] a) {
        int keep, j;

        // Find first non-sign (0xffffffff) int of input
        for (keep=0; keep < a.length && a[keep] == -1; keep++){}

        /* Allocate output array.  If all non-sign ints are 0x00, we must
         * allocate space for one extra output int. */
        for (j=keep; j < a.length && a[j] == 0; j++){}
        int extraInt = (j == a.length ? 1 : 0);
        int[] result = new int[a.length - keep + extraInt];

        /* Copy one's complement of input into output, leaving extra
         * int (if it exists) == 0x00 */
        for (int i = keep; i < a.length; i++)
            result[i - keep + extraInt] = ~a[i];

        // Add one to one's complement to generate two's complement
        for (size_t i=result.length-1; ++result[i] == 0; i--){}

        return result;
    }

    /*
     * The following two arrays are used for fast string conversions.  Both
     * are indexed by radix.  The first is the number of digits of the given
     * radix that can fit in a Java long without "going negative", i.e., the
     * highest integer n such that radix**n < 2**63.  The second is the
     * "long radix" that tears each number into "long digits", each of which
     * consists of the number of digits in the corresponding element in
     * digitsPerLong (longRadix[i] = i**digitPerLong[i]).  Both arrays have
     * nonsense values in their 0 and 1 elements, as radixes 0 and 1 are not
     * used.
     */
    private static int[] digitsPerLong = [0, 0,
        62, 39, 31, 27, 24, 22, 20, 19, 18, 18, 17, 17, 16, 16, 15, 15, 15, 14,
        14, 14, 14, 13, 13, 13, 13, 13, 13, 12, 12, 12, 12, 12, 12, 12, 12];

    private __gshared static BigInteger[] longRadix;

    shared static this() {
        longRadix = [null, null,
        valueOf(0x4000000000000000L), valueOf(0x383d9170b85ff80bL),
        valueOf(0x4000000000000000L), valueOf(0x6765c793fa10079dL),
        valueOf(0x41c21cb8e1000000L), valueOf(0x3642798750226111L),
        valueOf(0x1000000000000000L), valueOf(0x12bf307ae81ffd59L),
        valueOf( 0xde0b6b3a7640000L), valueOf(0x4d28cb56c33fa539L),
        valueOf(0x1eca170c00000000L), valueOf(0x780c7372621bd74dL),
        valueOf(0x1e39a5057d810000L), valueOf(0x5b27ac993df97701L),
        valueOf(0x1000000000000000L), valueOf(0x27b95e997e21d9f1L),
        valueOf(0x5da0e1e53c5c8000L), valueOf( 0xb16a458ef403f19L),
        valueOf(0x16bcc41e90000000L), valueOf(0x2d04b7fdd9c0ef49L),
        valueOf(0x5658597bcaa24000L), valueOf( 0x6feb266931a75b7L),
        valueOf( 0xc29e98000000000L), valueOf(0x14adf4b7320334b9L),
        valueOf(0x226ed36478bfa000L), valueOf(0x383d9170b85ff80bL),
        valueOf(0x5a3c23e39c000000L), valueOf( 0x4e900abb53e6b71L),
        valueOf( 0x7600ec618141000L), valueOf( 0xaee5720ee830681L),
        valueOf(0x1000000000000000L), valueOf(0x172588ad4f5f0981L),
        valueOf(0x211e44f7d02c1000L), valueOf(0x2ee56725f06e5c71L),
        valueOf(0x41c21cb8e1000000L)];
    }

    /*
     * These two arrays are the integer analogue of above.
     */
    private enum int[] digitsPerInt = [0, 0, 30, 19, 15, 13, 11,
        11, 10, 9, 9, 8, 8, 8, 8, 7, 7, 7, 7, 7, 7, 7, 6, 6, 6, 6,
        6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5];

    private enum int[] intRadix =[0, 0,
        0x40000000, 0x4546b3db, 0x40000000, 0x48c27395, 0x159fd800,
        0x75db9c97, 0x40000000, 0x17179149, 0x3b9aca00, 0xcc6db61,
        0x19a10000, 0x309f1021, 0x57f6c100, 0xa2f1b6f,  0x10000000,
        0x18754571, 0x247dbc80, 0x3547667b, 0x4c4b4000, 0x6b5a6e1d,
        0x6c20a40,  0x8d2d931,  0xb640000,  0xe8d4a51,  0x1269ae40,
        0x17179149, 0x1cb91000, 0x23744899, 0x2b73a840, 0x34e63b41,
        0x40000000, 0x4cfa3cc1, 0x5c13d840, 0x6d91b519, 0x39aa400
    ];

    /**
     * These routines provide access to the two's complement representation
     * of BigIntegers.
     */

    /**
     * Returns the length of the two's complement representation in ints,
     * including space for at least one sign bit.
     */
    private int intLength() {
        return (bitLength() >>> 5) + 1;
    }

    /* Returns sign bit */
    private int signBit() {
        return signum < 0 ? 1 : 0;
    }

    /* Returns an int of sign bits */
    private int signInt() {
        return signum < 0 ? -1 : 0;
    }

    /**
     * Returns the specified int of the little-endian two's complement
     * representation (int 0 is the least significant).  The int number can
     * be arbitrarily high (values are logically preceded by infinitely many
     * sign ints).
     */
    private int getInt(int n) {
        if (n < 0)
            return 0;
        if (n >= cast(int)mag.length)
            return signInt();

        int magInt = mag[mag.length-n-1];

        return (signum >= 0 ? magInt :
                (n <= firstNonzeroIntNum() ? -magInt : ~magInt));
    }

    /**
    * Returns the index of the int that contains the first nonzero int in the
    * little-endian binary representation of the magnitude (int 0 is the
    * least significant). If the magnitude is zero, return value is undefined.
    *
    * <p>Note: never used for a BigInteger with a magnitude of zero.
    * @see #getInt.
    */
    private int firstNonzeroIntNum() {
        int fn = firstNonzeroIntNumPlusTwo - 2;
        if (fn == -2) { // firstNonzeroIntNum not initialized yet
            // Search for the first nonzero int
            int i;
            int mlen = cast(int)mag.length;
            for (i = mlen - 1; i >= 0 && mag[i] == 0; i--) {}
            fn = mlen - i - 1;
            firstNonzeroIntNumPlusTwo = fn + 2; // offset by two to initialize
        }
        return fn;
    }

    /** use serialVersionUID from JDK 1.1. for interoperability */
    // private static final long serialVersionUID = -8287574255936472291L;

    /**
     * Serializable fields for BigInteger.
     *
     * @serialField signum  int
     *              signum of this BigInteger
     * @serialField magnitude byte[]
     *              magnitude array of this BigInteger
     * @serialField bitCount  int
     *              appears in the serialized form for backward compatibility
     * @serialField bitLength int
     *              appears in the serialized form for backward compatibility
     * @serialField firstNonzeroByteNum int
     *              appears in the serialized form for backward compatibility
     * @serialField lowestSetBit int
     *              appears in the serialized form for backward compatibility
     */
    // private static final ObjectStreamField[] serialPersistentFields = {
    //     new ObjectStreamField("signum", Integer.TYPE),
    //     new ObjectStreamField("magnitude", byte[].class),
    //     new ObjectStreamField("bitCount", Integer.TYPE),
    //     new ObjectStreamField("bitLength", Integer.TYPE),
    //     new ObjectStreamField("firstNonzeroByteNum", Integer.TYPE),
    //     new ObjectStreamField("lowestSetBit", Integer.TYPE)
    //     };

    /**
     * Reconstitute the {@code BigInteger} instance from a stream (that is,
     * deserialize it). The magnitude is read in as an array of bytes
     * for historical reasons, but it is converted to an array of ints
     * and the byte array is discarded.
     * Note:
     * The current convention is to initialize the cache fields, bitCountPlusOne,
     * bitLengthPlusOne and lowestSetBitPlusTwo, to 0 rather than some other
     * marker value. Therefore, no explicit action to set these fields needs to
     * be taken in readObject because those fields already have a 0 value by
     * default since defaultReadObject is not being used.
     */
    // private void readObject(java.io.ObjectInputStream s)
    //     throws java.io.IOException, ClassNotFoundException {
    //     // prepare to read the alternate persistent fields
    //     ObjectInputStream.GetField fields = s.readFields();

    //     // Read the alternate persistent fields that we care about
    //     int sign = fields.get("signum", -2);
    //     byte[] magnitude = (byte[])fields.get("magnitude", null);

    //     // Validate signum
    //     if (sign < -1 || sign > 1) {
    //         string message = "BigInteger: Invalid signum value";
    //         if (fields.defaulted("signum"))
    //             message = "BigInteger: Signum not present in stream";
    //         throw new java.io.StreamCorruptedException(message);
    //     }
    //     int[] mag = stripLeadingZeroBytes(magnitude, 0, magnitude.length);
    //     if (cast(int)(mag.length == 0) != (sign == 0)) {
    //         string message = "BigInteger: signum-magnitude mismatch";
    //         if (fields.defaulted("magnitude"))
    //             message = "BigInteger: Magnitude not present in stream";
    //         throw new java.io.StreamCorruptedException(message);
    //     }

    //     // Commit final fields via Unsafe
    //     UnsafeHolder.putSign(this, sign);

    //     // Calculate mag field from magnitude and discard magnitude
    //     UnsafeHolder.putMag(this, mag);
    //     if (mag.length >= MAX_MAG_LENGTH) {
    //         try {
    //             checkRange();
    //         } catch (ArithmeticException e) {
    //             throw new java.io.StreamCorruptedException("BigInteger: Out of the supported range");
    //         }
    //     }
    // }

    // // Support for resetting final fields while deserializing
    // private static class UnsafeHolder {
    //     private static final jdk.internal.misc.Unsafe unsafe
    //             = jdk.internal.misc.Unsafe.getUnsafe();
    //     private static final long signumOffset
    //             = unsafe.objectFieldOffset(BigInteger.class, "signum");
    //     private static final long magOffset
    //             = unsafe.objectFieldOffset(BigInteger.class, "mag");

    //     static void putSign(BigInteger bi, int sign) {
    //         unsafe.putInt(bi, signumOffset, sign);
    //     }

    //     static void putMag(BigInteger bi, int[] magnitude) {
    //         unsafe.putObject(bi, magOffset, magnitude);
    //     }
    // }

    /**
     * Save the {@code BigInteger} instance to a stream.  The magnitude of a
     * {@code BigInteger} is serialized as a byte array for historical reasons.
     * To maintain compatibility with older implementations, the integers
     * -1, -1, -2, and -2 are written as the values of the obsolete fields
     * {@code bitCount}, {@code bitLength}, {@code lowestSetBit}, and
     * {@code firstNonzeroByteNum}, respectively.  These values are compatible
     * with older implementations, but will be ignored by current
     * implementations.
     */
    // private void writeObject(ObjectOutputStream s) throws IOException {
    //     // set the values of the Serializable fields
    //     ObjectOutputStream.PutField fields = s.putFields();
    //     fields.put("signum", signum);
    //     fields.put("magnitude", magSerializedForm());
    //     // The values written for cached fields are compatible with older
    //     // versions, but are ignored in readObject so don't otherwise matter.
    //     fields.put("bitCount", -1);
    //     fields.put("bitLength", -1);
    //     fields.put("lowestSetBit", -2);
    //     fields.put("firstNonzeroByteNum", -2);

    //     // save them
    //     s.writeFields();
    // }

    /**
     * Returns the mag array as an array of bytes.
     */
    private byte[] magSerializedForm() {
        int len = cast(int)mag.length;

        int bitLen = (len == 0 ? 0 : ((len - 1) << 5) + bitLengthForInt(mag[0]));
        int byteLen = (bitLen + 7) >>> 3;
        byte[] result = new byte[byteLen];

        for (int i = byteLen - 1, bytesCopied = 4, intIndex = len - 1, nextInt = 0;
             i >= 0; i--) {
            if (bytesCopied == 4) {
                nextInt = mag[intIndex--];
                bytesCopied = 1;
            } else {
                nextInt >>>= 8;
                bytesCopied++;
            }
            result[i] = cast(byte)nextInt;
        }
        return result;
    }

    /**
     * Converts this {@code BigInteger} to a {@code long}, checking
     * for lost information.  If the value of this {@code BigInteger}
     * is out of the range of the {@code long} type, then an
     * {@code ArithmeticException} is thrown.
     *
     * @return this {@code BigInteger} converted to a {@code long}.
     * @throws ArithmeticException if the value of {@code this} will
     * not exactly fit in a {@code long}.
     * @see BigInteger#longValue
     * @since  1.8
     */
    long longValueExact() {
        if (mag.length <= 2 && bitLength() <= 63)
            return longValue();
        else
            throw new ArithmeticException("BigInteger out of long range");
    }

    /**
     * Converts this {@code BigInteger} to an {@code int}, checking
     * for lost information.  If the value of this {@code BigInteger}
     * is out of the range of the {@code int} type, then an
     * {@code ArithmeticException} is thrown.
     *
     * @return this {@code BigInteger} converted to an {@code int}.
     * @throws ArithmeticException if the value of {@code this} will
     * not exactly fit in an {@code int}.
     * @see BigInteger#intValue
     * @since  1.8
     */
    int intValueExact() {
        if (mag.length <= 1 && bitLength() <= 31)
            return intValue();
        else
            throw new ArithmeticException("BigInteger out of int range");
    }

    /**
     * Converts this {@code BigInteger} to a {@code short}, checking
     * for lost information.  If the value of this {@code BigInteger}
     * is out of the range of the {@code short} type, then an
     * {@code ArithmeticException} is thrown.
     *
     * @return this {@code BigInteger} converted to a {@code short}.
     * @throws ArithmeticException if the value of {@code this} will
     * not exactly fit in a {@code short}.
     * @see BigInteger#shortValue
     * @since  1.8
     */
    short shortValueExact() {
        if (mag.length <= 1 && bitLength() <= 31) {
            int value = intValue();
            if (value >= short.min && value <= short.max)
                return shortValue();
        }
        throw new ArithmeticException("BigInteger out of short range");
    }

    /**
     * Converts this {@code BigInteger} to a {@code byte}, checking
     * for lost information.  If the value of this {@code BigInteger}
     * is out of the range of the {@code byte} type, then an
     * {@code ArithmeticException} is thrown.
     *
     * @return this {@code BigInteger} converted to a {@code byte}.
     * @throws ArithmeticException if the value of {@code this} will
     * not exactly fit in a {@code byte}.
     * @see BigInteger#byteValue
     * @since  1.8
     */
    byte byteValueExact() {
        if (mag.length <= 1 && bitLength() <= 31) {
            int value = intValue();
            if (value >= byte.min && value <= byte.max)
                return byteValue();
        }
        throw new ArithmeticException("BigInteger out of byte range");
    }
}



class MutableBigInteger {
    /**
     * Holds the magnitude of this MutableBigInteger in big endian order.
     * The magnitude may start at an offset into the value array, and it may
     * end before the length of the value array.
     */
    int[] value;

    /**
     * The number of ints of the value array that are currently used
     * to hold the magnitude of this MutableBigInteger. The magnitude starts
     * at an offset and offset + intLen may be less than value.length.
     */
    int intLen;

    /**
     * The offset into the value array where the magnitude of this
     * MutableBigInteger begins.
     */
    int offset = 0;

    // Constants
    /**
     * MutableBigInteger with one element value array with the value 1. Used by
     * BigDecimal divideAndRound to increment the quotient. Use this constant
     * only when the method is not going to modify this object.
     */
    __gshared MutableBigInteger ONE;

    /**
     * The minimum {@code intLen} for cancelling powers of two before
     * dividing.
     * If the number of ints is less than this threshold,
     * {@code divideKnuth} does not eliminate common powers of two from
     * the dividend and divisor.
     */
    enum int KNUTH_POW2_THRESH_LEN = 6;

    /**
     * The minimum number of trailing zero ints for cancelling powers of two
     * before dividing.
     * If the dividend and divisor don't share at least this many zero ints
     * at the end, {@code divideKnuth} does not eliminate common powers
     * of two from the dividend and divisor.
     */
    enum int KNUTH_POW2_THRESH_ZEROS = 3;

    private enum long INFLATED = long.min;
    private enum LONG_MASK = BigInteger.LONG_MASK;

    shared static this() {
        ONE = new MutableBigInteger(1);
    }

    // Constructors

    /**
     * The default constructor. An empty MutableBigInteger is created with
     * a one word capacity.
     */
    this() {
        value = new int[1];
        intLen = 0;
    }

    /**
     * Construct a new MutableBigInteger with a magnitude specified by
     * the int val.
     */
    this(int val) {
        value = new int[1];
        intLen = 1;
        value[0] = val;
    }

    /**
     * Construct a new MutableBigInteger with the specified value array
     * up to the length of the array supplied.
     */
    this(int[] val) {
        value = val;
        intLen = cast(int)val.length;
    }

    /**
     * Construct a new MutableBigInteger with a magnitude equal to the
     * specified BigInteger.
     */
    this(BigInteger b) {
        intLen = cast(int)b.mag.length;
        // value = Arrays.copyOf(b.mag, intLen);
        value = b.mag.dup;
    }

    /**
     * Construct a new MutableBigInteger with a magnitude equal to the
     * specified MutableBigInteger.
     */
    this(MutableBigInteger val) {
        intLen = val.intLen;
        // value = Arrays.copyOfRange(val.value, val.offset, val.offset + intLen);
        value = val.cloneValue();
    }

    int[] cloneValue() {
        return value[offset .. offset + intLen].dup;
    }

    /**
     * Makes this number an {@code n}-int number all of whose bits are ones.
     * Used by Burnikel-Ziegler division.
     * @param n number of ints in the {@code value} array
     * @return a number equal to {@code ((1<<(32*n)))-1}
     */
    private void ones(int n) {
        if (n > value.length)
            value = new int[n];
        // Arrays.fill(value, -1);
        value[] = -1;
        offset = 0;
        intLen = n;
    }

    /**
     * Internal helper method to return the magnitude array. The caller is not
     * supposed to modify the returned array.
     */
    private int[] getMagnitudeArray() {
        if (offset > 0 || value.length != intLen)
            // return Arrays.copyOfRange(value, offset, offset + intLen);
            return value[offset .. offset + intLen];
        return value;
    }

    /**
     * Convert this MutableBigInteger to a long value. The caller has to make
     * sure this MutableBigInteger can be fit into long.
     */
    private long toLong() {
        assert (intLen <= 2, "this MutableBigInteger exceeds the range of long");
        if (intLen == 0)
            return 0;
        long d = value[offset] & LONG_MASK;
        return (intLen == 2) ? d << 32 | (value[offset + 1] & LONG_MASK) : d;
    }

    /**
     * Convert this MutableBigInteger to a BigInteger object.
     */
    BigInteger toBigInteger(int sign) {
        if (intLen == 0 || sign == 0)
            return BigInteger.ZERO;
        return new BigInteger(getMagnitudeArray(), sign);
    }

    /**
     * Converts this number to a nonnegative {@code BigInteger}.
     */
    BigInteger toBigInteger() {
        normalize();
        return toBigInteger(isZero() ? 0 : 1);
    }

    /**
     * Convert this MutableBigInteger to BigDecimal object with the specified sign
     * and scale.
     */
    // BigDecimal toBigDecimal(int sign, int scale) {
    //     if (intLen == 0 || sign == 0)
    //         return BigDecimal.zeroValueOf(scale);
    //     int[] mag = getMagnitudeArray();
    //     int len = cast(int)mag.length;
    //     int d = mag[0];
    //     // If this MutableBigInteger can't be fit into long, we need to
    //     // make a BigInteger object for the resultant BigDecimal object.
    //     if (len > 2 || (d < 0 && len == 2))
    //         return new BigDecimal(new BigInteger(mag, sign), INFLATED, scale, 0);
    //     long v = (len == 2) ?
    //         ((mag[1] & LONG_MASK) | (d & LONG_MASK) << 32) :
    //         d & LONG_MASK;
    //     return BigDecimal.valueOf(sign == -1 ? -v : v, scale);
    // }

    /**
     * This is for internal use in converting from a MutableBigInteger
     * object into a long value given a specified sign.
     * returns INFLATED if value is not fit into long
     */
    long toCompactValue(int sign) {
        if (intLen == 0 || sign == 0)
            return 0L;
        int[] mag = getMagnitudeArray();
        int len = cast(int)mag.length;
        int d = mag[0];
        // If this MutableBigInteger can not be fitted into long, we need to
        // make a BigInteger object for the resultant BigDecimal object.
        if (len > 2 || (d < 0 && len == 2))
            return INFLATED;
        long v = (len == 2) ?
            ((mag[1] & LONG_MASK) | (d & LONG_MASK) << 32) :
            d & LONG_MASK;
        return sign == -1 ? -v : v;
    }

    /**
     * Clear out a MutableBigInteger for reuse.
     */
    void clear() {
        offset = intLen = 0;
        for (int index=0, n=cast(int)value.length; index < n; index++)
            value[index] = 0;
    }

    /**
     * Set a MutableBigInteger to zero, removing its offset.
     */
    void reset() {
        offset = intLen = 0;
    }

    /**
     * Compare the magnitude of two MutableBigIntegers. Returns -1, 0 or 1
     * as this MutableBigInteger is numerically less than, equal to, or
     * greater than {@code b}.
     */
    final int compare(MutableBigInteger b) {
        int blen = b.intLen;
        if (intLen < blen)
            return -1;
        if (intLen > blen)
           return 1;

        // Add Integer.MIN_VALUE to make the comparison act as unsigned integer
        // comparison.
        int[] bval = b.value;
        for (int i = offset, j = b.offset; i < intLen + offset; i++, j++) {
            int b1 = value[i] + 0x80000000;
            int b2 = bval[j]  + 0x80000000;
            if (b1 < b2)
                return -1;
            if (b1 > b2)
                return 1;
        }
        return 0;
    }

    /**
     * Returns a value equal to what {@code b.leftShift(32*ints); return compare(b);}
     * would return, but doesn't change the value of {@code b}.
     */
    private int compareShifted(MutableBigInteger b, int ints) {
        int blen = b.intLen;
        int alen = intLen - ints;
        if (alen < blen)
            return -1;
        if (alen > blen)
           return 1;

        // Add Integer.MIN_VALUE to make the comparison act as unsigned integer
        // comparison.
        int[] bval = b.value;
        for (int i = offset, j = b.offset; i < alen + offset; i++, j++) {
            int b1 = value[i] + 0x80000000;
            int b2 = bval[j]  + 0x80000000;
            if (b1 < b2)
                return -1;
            if (b1 > b2)
                return 1;
        }
        return 0;
    }

    /**
     * Compare this against half of a MutableBigInteger object (Needed for
     * remainder tests).
     * Assumes no leading unnecessary zeros, which holds for results
     * from divide().
     */
    final int compareHalf(MutableBigInteger b) {
        int blen = b.intLen;
        int len = intLen;
        if (len <= 0)
            return blen <= 0 ? 0 : -1;
        if (len > blen)
            return 1;
        if (len < blen - 1)
            return -1;
        int[] bval = b.value;
        int bstart = 0;
        int carry = 0;
        // Only 2 cases left:len == blen or len == blen - 1
        if (len != blen) { // len == blen - 1
            if (bval[bstart] == 1) {
                ++bstart;
                carry = 0x80000000;
            } else
                return -1;
        }
        // compare values with right-shifted values of b,
        // carrying shifted-out bits across words
        int[] val = value;
        for (int i = offset, j = bstart; i < len + offset;) {
            int bv = bval[j++];
            long hb = ((bv >>> 1) + carry) & LONG_MASK;
            long v = val[i++] & LONG_MASK;
            if (v != hb)
                return v < hb ? -1 : 1;
            carry = (bv & 1) << 31; // carray will be either 0x80000000 or 0
        }
        return carry == 0 ? 0 : -1;
    }

    /**
     * Return the index of the lowest set bit in this MutableBigInteger. If the
     * magnitude of this MutableBigInteger is zero, -1 is returned.
     */
    private final int getLowestSetBit() {
        if (intLen == 0)
            return -1;
        int j, b;
        for (j=intLen-1; (j > 0) && (value[j+offset] == 0); j--) {}
        b = value[j+offset];
        if (b == 0)
            return -1;
        return ((intLen-1-j)<<5) + Integer.numberOfTrailingZeros(b);
    }

    /**
     * Return the int in use in this MutableBigInteger at the specified
     * index. This method is not used because it is not inlined on all
     * platforms.
     */
    private final int getInt(int index) {
        return value[offset+index];
    }

    /**
     * Return a long which is equal to the unsigned value of the int in
     * use in this MutableBigInteger at the specified index. This method is
     * not used because it is not inlined on all platforms.
     */
    private final long getLong(int index) {
        return value[offset+index] & LONG_MASK;
    }

    /**
     * Ensure that the MutableBigInteger is in normal form, specifically
     * making sure that there are no leading zeros, and that if the
     * magnitude is zero, then intLen is zero.
     */
    final void normalize() {
        if (intLen == 0) {
            offset = 0;
            return;
        }

        int index = offset;
        if (value[index] != 0)
            return;

        int indexBound = index+intLen;
        do {
            index++;
        } while(index < indexBound && value[index] == 0);

        int numZeros = index - offset;
        intLen -= numZeros;
        offset = (intLen == 0 ?  0 : offset+numZeros);
    }

    /**
     * If this MutableBigInteger cannot hold len words, increase the size
     * of the value array to len words.
     */
    private final void ensureCapacity(int len) {
        if (value.length < len) {
            value = new int[len];
            offset = 0;
            intLen = len;
        }
    }

    /**
     * Convert this MutableBigInteger into an int array with no leading
     * zeros, of a length that is equal to this MutableBigInteger's intLen.
     */
    int[] toIntArray() {
        int[] result = new int[intLen];
        for(int i=0; i < intLen; i++)
            result[i] = value[offset+i];
        return result;
    }

    /**
     * Sets the int at index+offset in this MutableBigInteger to val.
     * This does not get inlined on all platforms so it is not used
     * as often as originally intended.
     */
    void setInt(int index, int val) {
        value[offset + index] = val;
    }

    /**
     * Sets this MutableBigInteger's value array to the specified array.
     * The intLen is set to the specified length.
     */
    void setValue(int[] val, int length) {
        value = val;
        intLen = length;
        offset = 0;
    }

    /**
     * Sets this MutableBigInteger's value array to a copy of the specified
     * array. The intLen is set to the length of the new array.
     */
    void copyValue(MutableBigInteger src) {
        int len = src.intLen;
        if (value.length < len)
            value = new int[len];
        //System.arraycopy(src.value, src.offset, value, 0, len);
        value[0 .. len] = src.cloneValue();

        intLen = len;
        offset = 0;
    }

    /**
     * Sets this MutableBigInteger's value array to a copy of the specified
     * array. The intLen is set to the length of the specified array.
     */
    void copyValue(int[] val) {
        int len = cast(int)val.length;
        if (value.length < len)
            value = new int[len];
        // System.arraycopy(val, 0, value, 0, len);
        value[0..len] = val[0 .. len];
        intLen = len;
        offset = 0;
    }

    /**
     * Returns true iff this MutableBigInteger has a value of one.
     */
    bool isOne() {
        return (intLen == 1) && (value[offset] == 1);
    }

    /**
     * Returns true iff this MutableBigInteger has a value of zero.
     */
    bool isZero() {
        return (intLen == 0);
    }

    /**
     * Returns true iff this MutableBigInteger is even.
     */
    bool isEven() {
        return (intLen == 0) || ((value[offset + intLen - 1] & 1) == 0);
    }

    /**
     * Returns true iff this MutableBigInteger is odd.
     */
    bool isOdd() {
        return isZero() ? false : ((value[offset + intLen - 1] & 1) == 1);
    }

    /**
     * Returns true iff this MutableBigInteger is in normal form. A
     * MutableBigInteger is in normal form if it has no leading zeros
     * after the offset, and intLen + offset <= cast(int)value.length.
     */
    bool isNormal() {
        if (intLen + offset > value.length)
            return false;
        if (intLen == 0)
            return true;
        return (value[offset] != 0);
    }

    /**
     * Returns a string representation of this MutableBigInteger in radix 10.
     */
    override string toString() {
        BigInteger b = toBigInteger(1);
        return b.toString();
    }

    /**
     * Like {@link #rightShift(int)} but {@code n} can be greater than the length of the number.
     */
    void safeRightShift(int n) {
        if (n/32 >= intLen) {
            reset();
        } else {
            rightShift(n);
        }
    }

    /**
     * Right shift this MutableBigInteger n bits. The MutableBigInteger is left
     * in normal form.
     */
    void rightShift(int n) {
        if (intLen == 0)
            return;
        int nInts = n >>> 5;
        int nBits = n & 0x1F;
        this.intLen -= nInts;
        if (nBits == 0)
            return;
        int bitsInHighWord = BigInteger.bitLengthForInt(value[offset]);
        if (nBits >= bitsInHighWord) {
            this.primitiveLeftShift(32 - nBits);
            this.intLen--;
        } else {
            primitiveRightShift(nBits);
        }
    }

    /**
     * Like {@link #leftShift(int)} but {@code n} can be zero.
     */
    void safeLeftShift(int n) {
        if (n > 0) {
            leftShift(n);
        }
    }

    /**
     * Left shift this MutableBigInteger n bits.
     */
    void leftShift(int n) {
        /*
         * If there is enough storage space in this MutableBigInteger already
         * the available space will be used. Space to the right of the used
         * ints in the value array is faster to utilize, so the extra space
         * will be taken from the right if possible.
         */
        if (intLen == 0)
           return;
        int nInts = n >>> 5;
        int nBits = n&0x1F;
        int bitsInHighWord = BigInteger.bitLengthForInt(value[offset]);

        // If shift can be done without moving words, do so
        if (n <= (32-bitsInHighWord)) {
            primitiveLeftShift(nBits);
            return;
        }

        int newLen = intLen + nInts +1;
        if (nBits <= (32-bitsInHighWord))
            newLen--;
        if (value.length < newLen) {
            // The array must grow
            int[] result = new int[newLen];
            for (int i=0; i < intLen; i++)
                result[i] = value[offset+i];
            setValue(result, newLen);
        } else if (value.length - offset >= newLen) {
            // Use space on right
            for(int i=0; i < newLen - intLen; i++)
                value[offset+intLen+i] = 0;
        } else {
            // Must use space on left
            for (int i=0; i < intLen; i++)
                value[i] = value[offset+i];
            for (int i=intLen; i < newLen; i++)
                value[i] = 0;
            offset = 0;
        }
        intLen = newLen;
        if (nBits == 0)
            return;
        if (nBits <= (32-bitsInHighWord))
            primitiveLeftShift(nBits);
        else
            primitiveRightShift(32 -nBits);
    }

    /**
     * A primitive used for division. This method adds in one multiple of the
     * divisor a back to the dividend result at a specified offset. It is used
     * when qhat was estimated too large, and must be adjusted.
     */
    private int divadd(int[] a, int[] result, int offset) {
        long carry = 0;

        for (int j=cast(int)a.length-1; j >= 0; j--) {
            long sum = (a[j] & LONG_MASK) +
                       (result[j+offset] & LONG_MASK) + carry;
            result[j+offset] = cast(int)sum;
            carry = sum >>> 32;
        }
        return cast(int)carry;
    }

    /**
     * This method is used for division. It multiplies an n word input a by one
     * word input x, and subtracts the n word product from q. This is needed
     * when subtracting qhat*divisor from dividend.
     */
    private int mulsub(int[] q, int[] a, int x, int len, int offset) {
        long xLong = x & LONG_MASK;
        long carry = 0;
        offset += len;

        for (int j=len-1; j >= 0; j--) {
            long product = (a[j] & LONG_MASK) * xLong + carry;
            long difference = q[offset] - product;
            q[offset--] = cast(int)difference;
            carry = (product >>> 32)
                     + (((difference & LONG_MASK) >
                         (((~cast(int)product) & LONG_MASK))) ? 1:0);
        }
        return cast(int)carry;
    }

    /**
     * The method is the same as mulsun, except the fact that q array is not
     * updated, the only result of the method is borrow flag.
     */
    private int mulsubBorrow(int[] q, int[] a, int x, int len, int offset) {
        long xLong = x & LONG_MASK;
        long carry = 0;
        offset += len;
        for (int j=len-1; j >= 0; j--) {
            long product = (a[j] & LONG_MASK) * xLong + carry;
            long difference = q[offset--] - product;
            carry = (product >>> 32)
                     + (((difference & LONG_MASK) >
                         (((~cast(int)product) & LONG_MASK))) ? 1:0);
        }
        return cast(int)carry;
    }

    /**
     * Right shift this MutableBigInteger n bits, where n is
     * less than 32.
     * Assumes that intLen > 0, n > 0 for speed
     */
    private final void primitiveRightShift(int n) {
        int[] val = value;
        int n2 = 32 - n;
        for (int i=offset+intLen-1, c=val[i]; i > offset; i--) {
            int b = c;
            c = val[i-1];
            val[i] = (c << n2) | (b >>> n);
        }
        val[offset] >>>= n;
    }

    /**
     * Left shift this MutableBigInteger n bits, where n is
     * less than 32.
     * Assumes that intLen > 0, n > 0 for speed
     */
    private final void primitiveLeftShift(int n) {
        int[] val = value;
        int n2 = 32 - n;
        for (int i=offset, c=val[i], m=i+intLen-1; i < m; i++) {
            int b = c;
            c = val[i+1];
            val[i] = (b << n) | (c >>> n2);
        }
        val[offset+intLen-1] <<= n;
    }

    /**
     * Returns a {@code BigInteger} equal to the {@code n}
     * low ints of this number.
     */
    private BigInteger getLower(int n) {
        if (isZero()) {
            return BigInteger.ZERO;
        } else if (intLen < n) {
            return toBigInteger(1);
        } else {
            // strip zeros
            int len = n;
            while (len > 0 && value[offset+intLen-len] == 0)
                len--;
            int sign = len > 0 ? 1 : 0;
            // return new BigInteger(Arrays.copyOfRange(value, offset+intLen-len, offset+intLen), sign);
            return new BigInteger(value[offset+intLen-len .. offset+intLen], sign);
        }
    }

    /**
     * Discards all ints whose index is greater than {@code n}.
     */
    private void keepLower(int n) {
        if (intLen >= n) {
            offset += intLen - n;
            intLen = n;
        }
    }

    /**
     * Adds the contents of two MutableBigInteger objects.The result
     * is placed within this MutableBigInteger.
     * The contents of the addend are not changed.
     */
    void add(MutableBigInteger addend) {
        int x = intLen;
        int y = addend.intLen;
        int resultLen = (intLen > addend.intLen ? intLen : addend.intLen);
        int[] result = (value.length < resultLen ? new int[resultLen] : value);

        int rstart = cast(int)result.length-1;
        long sum;
        long carry = 0;

        // Add common parts of both numbers
        while(x > 0 && y > 0) {
            x--; y--;
            sum = (value[x+offset] & LONG_MASK) +
                (addend.value[y+addend.offset] & LONG_MASK) + carry;
            result[rstart--] = cast(int)sum;
            carry = sum >>> 32;
        }

        // Add remainder of the longer number
        while(x > 0) {
            x--;
            if (carry == 0 && result == value && rstart == (x + offset))
                return;
            sum = (value[x+offset] & LONG_MASK) + carry;
            result[rstart--] = cast(int)sum;
            carry = sum >>> 32;
        }
        while(y > 0) {
            y--;
            sum = (addend.value[y+addend.offset] & LONG_MASK) + carry;
            result[rstart--] = cast(int)sum;
            carry = sum >>> 32;
        }

        if (carry > 0) { // Result must grow in length
            resultLen++;
            size_t len = cast(int)result.length;
            if (len < resultLen) {
                int[] temp = new int[resultLen];
                // Result one word longer from carry-out; copy low-order
                // bits into new result.
                // System.arraycopy(result, 0, temp, 1, result.length);
                temp[1 .. len+1] = result[0..$];
                temp[0] = 1;
                result = temp;
            } else {
                result[rstart--] = 1;
            }
        }

        value = result;
        intLen = resultLen;
        offset = cast(int)result.length - resultLen;
    }

    /**
     * Adds the value of {@code addend} shifted {@code n} ints to the left.
     * Has the same effect as {@code addend.leftShift(32*ints); add(addend);}
     * but doesn't change the value of {@code addend}.
     */
    void addShifted(MutableBigInteger addend, int n) {
        if (addend.isZero()) {
            return;
        }

        int x = intLen;
        int y = addend.intLen + n;
        int resultLen = (intLen > y ? intLen : y);
        int[] result = (value.length < resultLen ? new int[resultLen] : value);

        int rstart = cast(int)result.length-1;
        long sum;
        long carry = 0;

        // Add common parts of both numbers
        while (x > 0 && y > 0) {
            x--; y--;
            int bval = y+addend.offset < addend.value.length ? addend.value[y+addend.offset] : 0;
            sum = (value[x+offset] & LONG_MASK) +
                (bval & LONG_MASK) + carry;
            result[rstart--] = cast(int)sum;
            carry = sum >>> 32;
        }

        // Add remainder of the longer number
        while (x > 0) {
            x--;
            if (carry == 0 && result == value && rstart == (x + offset)) {
                return;
            }
            sum = (value[x+offset] & LONG_MASK) + carry;
            result[rstart--] = cast(int)sum;
            carry = sum >>> 32;
        }
        while (y > 0) {
            y--;
            int bval = y+addend.offset < addend.value.length ? addend.value[y+addend.offset] : 0;
            sum = (bval & LONG_MASK) + carry;
            result[rstart--] = cast(int)sum;
            carry = sum >>> 32;
        }

        if (carry > 0) { // Result must grow in length
            resultLen++;
            size_t len = cast(int)result.length;
            if (len < resultLen) {
                int[] temp = new int[resultLen];
                // Result one word longer from carry-out; copy low-order
                // bits into new result.
                // System.arraycopy(result, 0, temp, 1, result.length);
                temp[1 .. len+1] = result[0..$];
                temp[0] = 1;
                result = temp;
            } else {
                result[rstart--] = 1;
            }
        }

        value = result;
        intLen = resultLen;
        offset = cast(int)result.length - resultLen;
    }

    /**
     * Like {@link #addShifted(MutableBigInteger, int)} but {@code this.intLen} must
     * not be greater than {@code n}. In other words, concatenates {@code this}
     * and {@code addend}.
     */
    void addDisjoint(MutableBigInteger addend, int n) {
        if (addend.isZero())
            return;

        int x = intLen;
        int y = addend.intLen + n;
        int resultLen = (intLen > y ? intLen : y);
        int[] result;
        if (value.length < resultLen)
            result = new int[resultLen];
        else {
            result = value;
            //Arrays.fill(value, offset+intLen, value.length, 0);
            value[offset+intLen .. $] = 0;
        }

        int rstart = cast(int)result.length-1;

        // copy from this if needed
        // System.arraycopy(value, offset, result, rstart+1-x, x);
        result[rstart+1-x .. rstart+1] = value[offset .. x];
        y -= x;
        rstart -= x;

        int len = std.algorithm.min(y, addend.value.length-addend.offset);
        // System.arraycopy(addend.value, addend.offset, result, rstart+1-y, len);
        result[rstart+1-y .. rstart+1] = addend.value[addend.offset .. len];


        // zero the gap
        for (int i=rstart+1-y+len; i < rstart+1; i++)
            result[i] = 0;

        value = result;
        intLen = resultLen;
        offset = cast(int)result.length - resultLen;
    }

    /**
     * Adds the low {@code n} ints of {@code addend}.
     */
    void addLower(MutableBigInteger addend, int n) {
        MutableBigInteger a = new MutableBigInteger(addend);
        if (a.offset + a.intLen >= n) {
            a.offset = a.offset + a.intLen - n;
            a.intLen = n;
        }
        a.normalize();
        add(a);
    }

    /**
     * Subtracts the smaller of this and b from the larger and places the
     * result into this MutableBigInteger.
     */
    int subtract(MutableBigInteger b) {
        MutableBigInteger a = this;

        int[] result = value;
        int sign = a.compare(b);

        if (sign == 0) {
            reset();
            return 0;
        }
        if (sign < 0) {
            MutableBigInteger tmp = a;
            a = b;
            b = tmp;
        }

        int resultLen = a.intLen;
        if (result.length < resultLen)
            result = new int[resultLen];

        long diff = 0;
        int x = a.intLen;
        int y = b.intLen;
        int rstart = cast(int)result.length - 1;

        // Subtract common parts of both numbers
        while (y > 0) {
            x--; y--;

            diff = (a.value[x+a.offset] & LONG_MASK) -
                   (b.value[y+b.offset] & LONG_MASK) - (cast(int)-(diff>>32));
            result[rstart--] = cast(int)diff;
        }
        // Subtract remainder of longer number
        while (x > 0) {
            x--;
            diff = (a.value[x+a.offset] & LONG_MASK) - (cast(int)-(diff>>32));
            result[rstart--] = cast(int)diff;
        }

        value = result;
        intLen = resultLen;
        offset = cast(int)value.length - resultLen;
        normalize();
        return sign;
    }

    /**
     * Subtracts the smaller of a and b from the larger and places the result
     * into the larger. Returns 1 if the answer is in a, -1 if in b, 0 if no
     * operation was performed.
     */
    private int difference(MutableBigInteger b) {
        MutableBigInteger a = this;
        int sign = a.compare(b);
        if (sign == 0)
            return 0;
        if (sign < 0) {
            MutableBigInteger tmp = a;
            a = b;
            b = tmp;
        }

        long diff = 0;
        int x = a.intLen;
        int y = b.intLen;

        // Subtract common parts of both numbers
        while (y > 0) {
            x--; y--;
            diff = (a.value[a.offset+ x] & LONG_MASK) -
                (b.value[b.offset+ y] & LONG_MASK) - (cast(int)-(diff>>32));
            a.value[a.offset+x] = cast(int)diff;
        }
        // Subtract remainder of longer number
        while (x > 0) {
            x--;
            diff = (a.value[a.offset+ x] & LONG_MASK) - (cast(int)-(diff>>32));
            a.value[a.offset+x] = cast(int)diff;
        }

        a.normalize();
        return sign;
    }

    /**
     * Multiply the contents of two MutableBigInteger objects. The result is
     * placed into MutableBigInteger z. The contents of y are not changed.
     */
    void multiply(MutableBigInteger y, MutableBigInteger z) {
        int xLen = intLen;
        int yLen = y.intLen;
        int newLen = xLen + yLen;

        // Put z into an appropriate state to receive product
        if (z.value.length < newLen)
            z.value = new int[newLen];
        z.offset = 0;
        z.intLen = newLen;

        // The first iteration is hoisted out of the loop to avoid extra add
        long carry = 0;
        for (int j=yLen-1, k=yLen+xLen-1; j >= 0; j--, k--) {
                long product = (y.value[j+y.offset] & LONG_MASK) *
                               (value[xLen-1+offset] & LONG_MASK) + carry;
                z.value[k] = cast(int)product;
                carry = product >>> 32;
        }
        z.value[xLen-1] = cast(int)carry;

        // Perform the multiplication word by word
        for (int i = xLen-2; i >= 0; i--) {
            carry = 0;
            for (int j=yLen-1, k=yLen+i; j >= 0; j--, k--) {
                long product = (y.value[j+y.offset] & LONG_MASK) *
                               (value[i+offset] & LONG_MASK) +
                               (z.value[k] & LONG_MASK) + carry;
                z.value[k] = cast(int)product;
                carry = product >>> 32;
            }
            z.value[i] = cast(int)carry;
        }

        // Remove leading zeros from product
        z.normalize();
    }

    /**
     * Multiply the contents of this MutableBigInteger by the word y. The
     * result is placed into z.
     */
    void mul(int y, MutableBigInteger z) {
        if (y == 1) {
            z.copyValue(this);
            return;
        }

        if (y == 0) {
            z.clear();
            return;
        }

        // Perform the multiplication word by word
        long ylong = y & LONG_MASK;
        int[] zval = (z.value.length < intLen+1 ? new int[intLen + 1]
                                              : z.value);
        long carry = 0;
        for (int i = intLen-1; i >= 0; i--) {
            long product = ylong * (value[i+offset] & LONG_MASK) + carry;
            zval[i+1] = cast(int)product;
            carry = product >>> 32;
        }

        if (carry == 0) {
            z.offset = 1;
            z.intLen = intLen;
        } else {
            z.offset = 0;
            z.intLen = intLen + 1;
            zval[0] = cast(int)carry;
        }
        z.value = zval;
    }

     /**
     * This method is used for division of an n word dividend by a one word
     * divisor. The quotient is placed into quotient. The one word divisor is
     * specified by divisor.
     *
     * @return the remainder of the division is returned.
     *
     */
    int divideOneWord(int divisor, MutableBigInteger quotient) {
        long divisorLong = divisor & LONG_MASK;

        // Special case of one word dividend
        if (intLen == 1) {
            long dividendValue = value[offset] & LONG_MASK;
            int q = cast(int) (dividendValue / divisorLong);
            int r = cast(int) (dividendValue - q * divisorLong);
            quotient.value[0] = q;
            quotient.intLen = (q == 0) ? 0 : 1;
            quotient.offset = 0;
            return r;
        }

        if (quotient.value.length < intLen)
            quotient.value = new int[intLen];
        quotient.offset = 0;
        quotient.intLen = intLen;

        // Normalize the divisor
        int shift = Integer.numberOfLeadingZeros(divisor);

        int rem = value[offset];
        long remLong = rem & LONG_MASK;
        if (remLong < divisorLong) {
            quotient.value[0] = 0;
        } else {
            quotient.value[0] = cast(int)(remLong / divisorLong);
            rem = cast(int) (remLong - (quotient.value[0] * divisorLong));
            remLong = rem & LONG_MASK;
        }
        int xlen = intLen;
        while (--xlen > 0) {
            long dividendEstimate = (remLong << 32) |
                    (value[offset + intLen - xlen] & LONG_MASK);
            int q;
            if (dividendEstimate >= 0) {
                q = cast(int) (dividendEstimate / divisorLong);
                rem = cast(int) (dividendEstimate - q * divisorLong);
            } else {
                long tmp = divWord(dividendEstimate, divisor);
                q = cast(int) (tmp & LONG_MASK);
                rem = cast(int) (tmp >>> 32);
            }
            quotient.value[intLen - xlen] = q;
            remLong = rem & LONG_MASK;
        }

        quotient.normalize();
        // Unnormalize
        if (shift > 0)
            return rem % divisor;
        else
            return rem;
    }

    /**
     * Calculates the quotient of this div b and places the quotient in the
     * provided MutableBigInteger objects and the remainder object is returned.
     *
     */
    MutableBigInteger divide(MutableBigInteger b, MutableBigInteger quotient) {
        return divide(b,quotient,true);
    }

    MutableBigInteger divide(MutableBigInteger b, MutableBigInteger quotient, bool needRemainder) {
        if (b.intLen < BigInteger.BURNIKEL_ZIEGLER_THRESHOLD ||
                intLen - b.intLen < BigInteger.BURNIKEL_ZIEGLER_OFFSET) {
            return divideKnuth(b, quotient, needRemainder);
        } else {
            return divideAndRemainderBurnikelZiegler(b, quotient);
        }
    }

    /**
     * @see #divideKnuth(MutableBigInteger, MutableBigInteger, bool)
     */
    MutableBigInteger divideKnuth(MutableBigInteger b, MutableBigInteger quotient) {
        return divideKnuth(b,quotient,true);
    }

    /**
     * Calculates the quotient of this div b and places the quotient in the
     * provided MutableBigInteger objects and the remainder object is returned.
     *
     * Uses Algorithm D in Knuth section 4.3.1.
     * Many optimizations to that algorithm have been adapted from the Colin
     * Plumb C library.
     * It special cases one word divisors for speed. The content of b is not
     * changed.
     *
     */
    MutableBigInteger divideKnuth(MutableBigInteger b, MutableBigInteger quotient, bool needRemainder) {
        if (b.intLen == 0)
            throw new ArithmeticException("BigInteger divide by zero");

        // Dividend is zero
        if (intLen == 0) {
            quotient.intLen = quotient.offset = 0;
            return needRemainder ? new MutableBigInteger() : null;
        }

        int cmp = compare(b);
        // Dividend less than divisor
        if (cmp < 0) {
            quotient.intLen = quotient.offset = 0;
            return needRemainder ? new MutableBigInteger(this) : null;
        }
        // Dividend equal to divisor
        if (cmp == 0) {
            quotient.value[0] = quotient.intLen = 1;
            quotient.offset = 0;
            return needRemainder ? new MutableBigInteger() : null;
        }

        quotient.clear();
        // Special case one word divisor
        if (b.intLen == 1) {
            int r = divideOneWord(b.value[b.offset], quotient);
            if(needRemainder) {
                if (r == 0)
                    return new MutableBigInteger();
                return new MutableBigInteger(r);
            } else {
                return null;
            }
        }

        // Cancel common powers of two if we're above the KNUTH_POW2_* thresholds
        if (intLen >= KNUTH_POW2_THRESH_LEN) {
            int trailingZeroBits = std.algorithm.min(getLowestSetBit(), b.getLowestSetBit());
            if (trailingZeroBits >= KNUTH_POW2_THRESH_ZEROS*32) {
                MutableBigInteger a = new MutableBigInteger(this);
                b = new MutableBigInteger(b);
                a.rightShift(trailingZeroBits);
                b.rightShift(trailingZeroBits);
                MutableBigInteger r = a.divideKnuth(b, quotient);
                r.leftShift(trailingZeroBits);
                return r;
            }
        }

        return divideMagnitude(b, quotient, needRemainder);
    }

    /**
     * Computes {@code this/b} and {@code this%b} using the
     * <a href="http://cr.yp.to/bib/1998/burnikel.ps"> Burnikel-Ziegler algorithm</a>.
     * This method implements algorithm 3 from pg. 9 of the Burnikel-Ziegler paper.
     * The parameter beta was chosen to b 2<sup>32</sup> so almost all shifts are
     * multiples of 32 bits.<br/>
     * {@code this} and {@code b} must be nonnegative.
     * @param b the divisor
     * @param quotient output parameter for {@code this/b}
     * @return the remainder
     */
    MutableBigInteger divideAndRemainderBurnikelZiegler(MutableBigInteger b, MutableBigInteger quotient) {
        int r = intLen;
        int s = b.intLen;

        // Clear the quotient
        quotient.offset = quotient.intLen = 0;

        if (r < s) {
            return this;
        } else {
            // Unlike Knuth division, we don't check for common powers of two here because
            // BZ already runs faster if both numbers contain powers of two and cancelling them has no
            // additional benefit.

            // step 1: let m = min{2^k | (2^k)*BURNIKEL_ZIEGLER_THRESHOLD > s}
            int m = 1 << (32-Integer.numberOfLeadingZeros(s/BigInteger.BURNIKEL_ZIEGLER_THRESHOLD));

            int j = (s+m-1) / m;      // step 2a: j = ceil(s/m)
            int n = j * m;            // step 2b: block length in 32-bit units
            long n32 = 32L * n;         // block length in bits
            int sigma = cast(int) std.algorithm.max(0, n32 - b.bitLength());   // step 3: sigma = max{T | (2^T)*B < beta^n}
            MutableBigInteger bShifted = new MutableBigInteger(b);
            bShifted.safeLeftShift(sigma);   // step 4a: shift b so its length is a multiple of n
            MutableBigInteger aShifted = new MutableBigInteger (this);
            aShifted.safeLeftShift(sigma);     // step 4b: shift a by the same amount

            // step 5: t is the number of blocks needed to accommodate a plus one additional bit
            int t = cast(int) ((aShifted.bitLength()+n32) / n32);
            if (t < 2) {
                t = 2;
            }

            // step 6: conceptually split a into blocks a[t-1], ..., a[0]
            MutableBigInteger a1 = aShifted.getBlock(t-1, t, n);   // the most significant block of a

            // step 7: z[t-2] = [a[t-1], a[t-2]]
            MutableBigInteger z = aShifted.getBlock(t-2, t, n);    // the second to most significant block
            z.addDisjoint(a1, n);   // z[t-2]

            // do schoolbook division on blocks, dividing 2-block numbers by 1-block numbers
            MutableBigInteger qi = new MutableBigInteger();
            MutableBigInteger ri;
            for (int i=t-2; i > 0; i--) {
                // step 8a: compute (qi,ri) such that z=b*qi+ri
                ri = z.divide2n1n(bShifted, qi);

                // step 8b: z = [ri, a[i-1]]
                z = aShifted.getBlock(i-1, t, n);   // a[i-1]
                z.addDisjoint(ri, n);
                quotient.addShifted(qi, i*n);   // update q (part of step 9)
            }
            // final iteration of step 8: do the loop one more time for i=0 but leave z unchanged
            ri = z.divide2n1n(bShifted, qi);
            quotient.add(qi);

            ri.rightShift(sigma);   // step 9: a and b were shifted, so shift back
            return ri;
        }
    }

    /**
     * This method implements algorithm 1 from pg. 4 of the Burnikel-Ziegler paper.
     * It divides a 2n-digit number by a n-digit number.<br/>
     * The parameter beta is 2<sup>32</sup> so all shifts are multiples of 32 bits.
     * <br/>
     * {@code this} must be a nonnegative number such that {@code this.bitLength() <= 2*b.bitLength()}
     * @param b a positive number such that {@code b.bitLength()} is even
     * @param quotient output parameter for {@code this/b}
     * @return {@code this%b}
     */
    private MutableBigInteger divide2n1n(MutableBigInteger b, MutableBigInteger quotient) {
        int n = b.intLen;

        // step 1: base case
        if (n%2 != 0 || n < BigInteger.BURNIKEL_ZIEGLER_THRESHOLD) {
            return divideKnuth(b, quotient);
        }

        // step 2: view this as [a1,a2,a3,a4] where each ai is n/2 ints or less
        MutableBigInteger aUpper = new MutableBigInteger(this);
        aUpper.safeRightShift(32*(n/2));   // aUpper = [a1,a2,a3]
        keepLower(n/2);   // this = a4

        // step 3: q1=aUpper/b, r1=aUpper%b
        MutableBigInteger q1 = new MutableBigInteger();
        MutableBigInteger r1 = aUpper.divide3n2n(b, q1);

        // step 4: quotient=[r1,this]/b, r2=[r1,this]%b
        addDisjoint(r1, n/2);   // this = [r1,this]
        MutableBigInteger r2 = divide3n2n(b, quotient);

        // step 5: let quotient=[q1,quotient] and return r2
        quotient.addDisjoint(q1, n/2);
        return r2;
    }

    /**
     * This method implements algorithm 2 from pg. 5 of the Burnikel-Ziegler paper.
     * It divides a 3n-digit number by a 2n-digit number.<br/>
     * The parameter beta is 2<sup>32</sup> so all shifts are multiples of 32 bits.<br/>
     * <br/>
     * {@code this} must be a nonnegative number such that {@code 2*this.bitLength() <= 3*b.bitLength()}
     * @param quotient output parameter for {@code this/b}
     * @return {@code this%b}
     */
    private MutableBigInteger divide3n2n(MutableBigInteger b, MutableBigInteger quotient) {
        int n = b.intLen / 2;   // half the length of b in ints

        // step 1: view this as [a1,a2,a3] where each ai is n ints or less; let a12=[a1,a2]
        MutableBigInteger a12 = new MutableBigInteger(this);
        a12.safeRightShift(32*n);

        // step 2: view b as [b1,b2] where each bi is n ints or less
        MutableBigInteger b1 = new MutableBigInteger(b);
        b1.safeRightShift(n * 32);
        BigInteger b2 = b.getLower(n);

        MutableBigInteger r;
        MutableBigInteger d;
        if (compareShifted(b, n) < 0) {
            // step 3a: if a1<b1, let quotient=a12/b1 and r=a12%b1
            r = a12.divide2n1n(b1, quotient);

            // step 4: d=quotient*b2
            d = new MutableBigInteger(quotient.toBigInteger().multiply(b2));
        } else {
            // step 3b: if a1>=b1, let quotient=beta^n-1 and r=a12-b1*2^n+b1
            quotient.ones(n);
            a12.add(b1);
            b1.leftShift(32*n);
            a12.subtract(b1);
            r = a12;

            // step 4: d=quotient*b2=(b2 << 32*n) - b2
            d = new MutableBigInteger(b2);
            d.leftShift(32 * n);
            d.subtract(new MutableBigInteger(b2));
        }

        // step 5: r = r*beta^n + a3 - d (paper says a4)
        // However, don't subtract d until after the while loop so r doesn't become negative
        r.leftShift(32 * n);
        r.addLower(this, n);

        // step 6: add b until r>=d
        while (r.compare(d) < 0) {
            r.add(b);
            quotient.subtract(MutableBigInteger.ONE);
        }
        r.subtract(d);

        return r;
    }

    /**
     * Returns a {@code MutableBigInteger} containing {@code blockLength} ints from
     * {@code this} number, starting at {@code index*blockLength}.<br/>
     * Used by Burnikel-Ziegler division.
     * @param index the block index
     * @param numBlocks the total number of blocks in {@code this} number
     * @param blockLength length of one block in units of 32 bits
     * @return
     */
    private MutableBigInteger getBlock(int index, int numBlocks, int blockLength) {
        int blockStart = index * blockLength;
        if (blockStart >= intLen) {
            return new MutableBigInteger();
        }

        int blockEnd;
        if (index == numBlocks-1) {
            blockEnd = intLen;
        } else {
            blockEnd = (index+1) * blockLength;
        }
        if (blockEnd > intLen) {
            return new MutableBigInteger();
        }

        // int[] newVal = Arrays.copyOfRange(value, offset+intLen-blockEnd, offset+intLen-blockStart);
        int[] newVal = value[offset+intLen-blockEnd .. offset+intLen-blockStart];
        return new MutableBigInteger(newVal);
    }

    /** @see BigInteger#bitLength() */
    long bitLength() {
        if (intLen == 0)
            return 0;
        return intLen*32L - Integer.numberOfLeadingZeros(value[offset]);
    }

    /**
     * Internally used  to calculate the quotient of this div v and places the
     * quotient in the provided MutableBigInteger object and the remainder is
     * returned.
     *
     * @return the remainder of the division will be returned.
     */
    long divide(long v, MutableBigInteger quotient) {
        if (v == 0)
            throw new ArithmeticException("BigInteger divide by zero");

        // Dividend is zero
        if (intLen == 0) {
            quotient.intLen = quotient.offset = 0;
            return 0;
        }
        if (v < 0)
            v = -v;

        int d = cast(int)(v >>> 32);
        quotient.clear();
        // Special case on word divisor
        if (d == 0)
            return divideOneWord(cast(int)v, quotient) & LONG_MASK;
        else {
            return divideLongMagnitude(v, quotient).toLong();
        }
    }

    private static void copyAndShift(int[] src, int srcFrom, int srcLen, int[] dst, int dstFrom, int shift) {
        int n2 = 32 - shift;
        int c=src[srcFrom];
        for (int i=0; i < srcLen-1; i++) {
            int b = c;
            c = src[++srcFrom];
            dst[dstFrom+i] = (b << shift) | (c >>> n2);
        }
        dst[dstFrom+srcLen-1] = c << shift;
    }

    /**
     * Divide this MutableBigInteger by the divisor.
     * The quotient will be placed into the provided quotient object &
     * the remainder object is returned.
     */
    private MutableBigInteger divideMagnitude(MutableBigInteger div,
                                              MutableBigInteger quotient,
                                              bool needRemainder ) {
        // assert div.intLen > 1
        // D1 normalize the divisor
        int shift = Integer.numberOfLeadingZeros(div.value[div.offset]);
        // Copy divisor value to protect divisor
        int dlen = div.intLen;
        int[] divisor;
        MutableBigInteger rem; // Remainder starts as dividend with space for a leading zero
        if (shift > 0) {
            divisor = new int[dlen];
            copyAndShift(div.value,div.offset,dlen,divisor,0,shift);
            if (Integer.numberOfLeadingZeros(value[offset]) >= shift) {
                int[] remarr = new int[intLen + 1];
                rem = new MutableBigInteger(remarr);
                rem.intLen = intLen;
                rem.offset = 1;
                copyAndShift(value,offset,intLen,remarr,1,shift);
            } else {
                int[] remarr = new int[intLen + 2];
                rem = new MutableBigInteger(remarr);
                rem.intLen = intLen+1;
                rem.offset = 1;
                int rFrom = offset;
                int c=0;
                int n2 = 32 - shift;
                for (int i=1; i < intLen+1; i++,rFrom++) {
                    int b = c;
                    c = value[rFrom];
                    remarr[i] = (b << shift) | (c >>> n2);
                }
                remarr[intLen+1] = c << shift;
            }
        } else {
            // divisor = Arrays.copyOfRange(div.value, div.offset, div.offset + div.intLen);
            divisor = div.cloneValue();
            rem = new MutableBigInteger(new int[intLen + 1]);
            // System.arraycopy(value, offset, rem.value, 1, intLen);
            rem.value[1 .. 1+intLen] = value[offset .. offset+intLen];
            rem.intLen = intLen;
            rem.offset = 1;
        }

        int nlen = rem.intLen;

        // Set the quotient size
        int limit = nlen - dlen + 1;
        if (quotient.value.length < limit) {
            quotient.value = new int[limit];
            quotient.offset = 0;
        }
        quotient.intLen = limit;
        int[] q = quotient.value;


        // Must insert leading 0 in rem if its length did not change
        if (rem.intLen == nlen) {
            rem.offset = 0;
            rem.value[0] = 0;
            rem.intLen++;
        }

        int dh = divisor[0];
        long dhLong = dh & LONG_MASK;
        int dl = divisor[1];

        // D2 Initialize j
        for (int j=0; j < limit-1; j++) {
            // D3 Calculate qhat
            // estimate qhat
            int qhat = 0;
            int qrem = 0;
            bool skipCorrection = false;
            int nh = rem.value[j+rem.offset];
            int nh2 = nh + 0x80000000;
            int nm = rem.value[j+1+rem.offset];

            if (nh == dh) {
                qhat = ~0;
                qrem = nh + nm;
                skipCorrection = qrem + 0x80000000 < nh2;
            } else {
                long nChunk = ((cast(long)nh) << 32) | (nm & LONG_MASK);
                if (nChunk >= 0) {
                    qhat = cast(int) (nChunk / dhLong);
                    qrem = cast(int) (nChunk - (qhat * dhLong));
                } else {
                    long tmp = divWord(nChunk, dh);
                    qhat = cast(int) (tmp & LONG_MASK);
                    qrem = cast(int) (tmp >>> 32);
                }
            }

            if (qhat == 0)
                continue;

            if (!skipCorrection) { // Correct qhat
                long nl = rem.value[j+2+rem.offset] & LONG_MASK;
                long rs = ((qrem & LONG_MASK) << 32) | nl;
                long estProduct = (dl & LONG_MASK) * (qhat & LONG_MASK);

                if (unsignedLongCompare(estProduct, rs)) {
                    qhat--;
                    qrem = cast(int)((qrem & LONG_MASK) + dhLong);
                    if ((qrem & LONG_MASK) >=  dhLong) {
                        estProduct -= (dl & LONG_MASK);
                        rs = ((qrem & LONG_MASK) << 32) | nl;
                        if (unsignedLongCompare(estProduct, rs))
                            qhat--;
                    }
                }
            }

            // D4 Multiply and subtract
            rem.value[j+rem.offset] = 0;
            int borrow = mulsub(rem.value, divisor, qhat, dlen, j+rem.offset);

            // D5 Test remainder
            if (borrow + 0x80000000 > nh2) {
                // D6 Add back
                divadd(divisor, rem.value, j+1+rem.offset);
                qhat--;
            }

            // Store the quotient digit
            q[j] = qhat;
        } // D7 loop on j
        // D3 Calculate qhat
        // estimate qhat
        int qhat = 0;
        int qrem = 0;
        bool skipCorrection = false;
        int nh = rem.value[limit - 1 + rem.offset];
        int nh2 = nh + 0x80000000;
        int nm = rem.value[limit + rem.offset];

        if (nh == dh) {
            qhat = ~0;
            qrem = nh + nm;
            skipCorrection = qrem + 0x80000000 < nh2;
        } else {
            long nChunk = ((cast(long) nh) << 32) | (nm & LONG_MASK);
            if (nChunk >= 0) {
                qhat = cast(int) (nChunk / dhLong);
                qrem = cast(int) (nChunk - (qhat * dhLong));
            } else {
                long tmp = divWord(nChunk, dh);
                qhat = cast(int) (tmp & LONG_MASK);
                qrem = cast(int) (tmp >>> 32);
            }
        }
        if (qhat != 0) {
            if (!skipCorrection) { // Correct qhat
                long nl = rem.value[limit + 1 + rem.offset] & LONG_MASK;
                long rs = ((qrem & LONG_MASK) << 32) | nl;
                long estProduct = (dl & LONG_MASK) * (qhat & LONG_MASK);

                if (unsignedLongCompare(estProduct, rs)) {
                    qhat--;
                    qrem = cast(int) ((qrem & LONG_MASK) + dhLong);
                    if ((qrem & LONG_MASK) >= dhLong) {
                        estProduct -= (dl & LONG_MASK);
                        rs = ((qrem & LONG_MASK) << 32) | nl;
                        if (unsignedLongCompare(estProduct, rs))
                            qhat--;
                    }
                }
            }


            // D4 Multiply and subtract
            int borrow;
            rem.value[limit - 1 + rem.offset] = 0;
            if(needRemainder)
                borrow = mulsub(rem.value, divisor, qhat, dlen, limit - 1 + rem.offset);
            else
                borrow = mulsubBorrow(rem.value, divisor, qhat, dlen, limit - 1 + rem.offset);

            // D5 Test remainder
            if (borrow + 0x80000000 > nh2) {
                // D6 Add back
                if(needRemainder)
                    divadd(divisor, rem.value, limit - 1 + 1 + rem.offset);
                qhat--;
            }

            // Store the quotient digit
            q[(limit - 1)] = qhat;
        }


        if (needRemainder) {
            // D8 Unnormalize
            if (shift > 0)
                rem.rightShift(shift);
            rem.normalize();
        }
        quotient.normalize();
        return needRemainder ? rem : null;
    }

    /**
     * Divide this MutableBigInteger by the divisor represented by positive long
     * value. The quotient will be placed into the provided quotient object &
     * the remainder object is returned.
     */
    private MutableBigInteger divideLongMagnitude(long ldivisor, MutableBigInteger quotient) {
        // Remainder starts as dividend with space for a leading zero
        MutableBigInteger rem = new MutableBigInteger(new int[intLen + 1]);
        // System.arraycopy(value, offset, rem.value, 1, intLen);
        rem.value[1 .. 1+intLen] = value[offset .. offset+intLen].dup;
        rem.intLen = intLen;
        rem.offset = 1;

        int nlen = rem.intLen;

        int limit = nlen - 2 + 1;
        if (quotient.value.length < limit) {
            quotient.value = new int[limit];
            quotient.offset = 0;
        }
        quotient.intLen = limit;
        int[] q = quotient.value;

        // D1 normalize the divisor
        int shift = Long.numberOfLeadingZeros(ldivisor);
        if (shift > 0) {
            ldivisor<<=shift;
            rem.leftShift(shift);
        }

        // Must insert leading 0 in rem if its length did not change
        if (rem.intLen == nlen) {
            rem.offset = 0;
            rem.value[0] = 0;
            rem.intLen++;
        }

        int dh = cast(int)(ldivisor >>> 32);
        long dhLong = dh & LONG_MASK;
        int dl = cast(int)(ldivisor & LONG_MASK);

        // D2 Initialize j
        for (int j = 0; j < limit; j++) {
            // D3 Calculate qhat
            // estimate qhat
            int qhat = 0;
            int qrem = 0;
            bool skipCorrection = false;
            int nh = rem.value[j + rem.offset];
            int nh2 = nh + 0x80000000;
            int nm = rem.value[j + 1 + rem.offset];

            if (nh == dh) {
                qhat = ~0;
                qrem = nh + nm;
                skipCorrection = qrem + 0x80000000 < nh2;
            } else {
                long nChunk = ((cast(long) nh) << 32) | (nm & LONG_MASK);
                if (nChunk >= 0) {
                    qhat = cast(int) (nChunk / dhLong);
                    qrem = cast(int) (nChunk - (qhat * dhLong));
                } else {
                    long tmp = divWord(nChunk, dh);
                    qhat = cast(int)(tmp & LONG_MASK);
                    qrem = cast(int)(tmp>>>32);
                }
            }

            if (qhat == 0)
                continue;

            if (!skipCorrection) { // Correct qhat
                long nl = rem.value[j + 2 + rem.offset] & LONG_MASK;
                long rs = ((qrem & LONG_MASK) << 32) | nl;
                long estProduct = (dl & LONG_MASK) * (qhat & LONG_MASK);

                if (unsignedLongCompare(estProduct, rs)) {
                    qhat--;
                    qrem = cast(int) ((qrem & LONG_MASK) + dhLong);
                    if ((qrem & LONG_MASK) >= dhLong) {
                        estProduct -= (dl & LONG_MASK);
                        rs = ((qrem & LONG_MASK) << 32) | nl;
                        if (unsignedLongCompare(estProduct, rs))
                            qhat--;
                    }
                }
            }

            // D4 Multiply and subtract
            rem.value[j + rem.offset] = 0;
            int borrow = mulsubLong(rem.value, dh, dl, qhat,  j + rem.offset);

            // D5 Test remainder
            if (borrow + 0x80000000 > nh2) {
                // D6 Add back
                divaddLong(dh,dl, rem.value, j + 1 + rem.offset);
                qhat--;
            }

            // Store the quotient digit
            q[j] = qhat;
        } // D7 loop on j

        // D8 Unnormalize
        if (shift > 0)
            rem.rightShift(shift);

        quotient.normalize();
        rem.normalize();
        return rem;
    }

    /**
     * A primitive used for division by long.
     * Specialized version of the method divadd.
     * dh is a high part of the divisor, dl is a low part
     */
    private int divaddLong(int dh, int dl, int[] result, int offset) {
        long carry = 0;

        long sum = (dl & LONG_MASK) + (result[1+offset] & LONG_MASK);
        result[1+offset] = cast(int)sum;

        sum = (dh & LONG_MASK) + (result[offset] & LONG_MASK) + carry;
        result[offset] = cast(int)sum;
        carry = sum >>> 32;
        return cast(int)carry;
    }

    /**
     * This method is used for division by long.
     * Specialized version of the method sulsub.
     * dh is a high part of the divisor, dl is a low part
     */
    private int mulsubLong(int[] q, int dh, int dl, int x, int offset) {
        long xLong = x & LONG_MASK;
        offset += 2;
        long product = (dl & LONG_MASK) * xLong;
        long difference = q[offset] - product;
        q[offset--] = cast(int)difference;
        long carry = (product >>> 32)
                 + (((difference & LONG_MASK) >
                     (((~cast(int)product) & LONG_MASK))) ? 1:0);
        product = (dh & LONG_MASK) * xLong + carry;
        difference = q[offset] - product;
        q[offset--] = cast(int)difference;
        carry = (product >>> 32)
                 + (((difference & LONG_MASK) >
                     (((~cast(int)product) & LONG_MASK))) ? 1:0);
        return cast(int)carry;
    }

    /**
     * Compare two longs as if they were unsigned.
     * Returns true iff one is bigger than two.
     */
    private bool unsignedLongCompare(long one, long two) {
        return (one+long.min) > (two+long.min);
    }

    /**
     * This method divides a long quantity by an int to estimate
     * qhat for two multi precision numbers. It is used when
     * the signed value of n is less than zero.
     * Returns long value where high 32 bits contain remainder value and
     * low 32 bits contain quotient value.
     */
    static long divWord(long n, int d) {
        long dLong = d & LONG_MASK;
        long r;
        long q;
        if (dLong == 1) {
            q = cast(int)n;
            r = 0;
            return (r << 32) | (q & LONG_MASK);
        }

        // Approximate the quotient and remainder
        q = (n >>> 1) / (dLong >>> 1);
        r = n - q*dLong;

        // Correct the approximation
        while (r < 0) {
            r += dLong;
            q--;
        }
        while (r >= dLong) {
            r -= dLong;
            q++;
        }
        // n - q*dlong == r && 0 <= r <dLong, hence we're done.
        return (r << 32) | (q & LONG_MASK);
    }

    /**
     * Calculate the integer square root {@code floor(sqrt(this))} where
     * {@code sqrt(.)} denotes the mathematical square root. The contents of
     * {@code this} are <b>not</b> changed. The value of {@code this} is assumed
     * to be non-negative.
     *
     * @implNote The implementation is based on the material in Henry S. Warren,
     * Jr., <i>Hacker's Delight (2nd ed.)</i> (Addison Wesley, 2013), 279-282.
     *
     * @throws ArithmeticException if the value returned by {@code bitLength()}
     * overflows the range of {@code int}.
     * @return the integer square root of {@code this}
     * @since 9
     */
    MutableBigInteger sqrt() {
        // Special cases.
        if (this.isZero()) {
            return new MutableBigInteger(0);
        } else if (this.value.length == 1
                && (this.value[0] & LONG_MASK) < 4) { // result is unity
            return ONE;
        }

        if (bitLength() <= 63) {
            // Initial estimate is the square root of the positive long value.
            long v = new BigInteger(this.value, 1).longValueExact();
            long xk = cast(long)std.math.floor(std.math.sqrt(cast(float)v));

            // Refine the estimate.
            do {
                long xk1 = (xk + v/xk)/2;

                // Terminate when non-decreasing.
                if (xk1 >= xk) {
                    return new MutableBigInteger( [cast(int)(xk >>> 32), 
                        cast(int)(xk & LONG_MASK)] );
                }

                xk = xk1;
            } while (true);
        } else {
            // Set up the initial estimate of the iteration.

            // Obtain the bitLength > 63.
            int bitLength = cast(int) this.bitLength();
            if (bitLength != this.bitLength()) {
                throw new ArithmeticException("bitLength() integer overflow");
            }

            // Determine an even valued right shift into positive long range.
            int shift = bitLength - 63;
            if (shift % 2 == 1) {
                shift++;
            }

            // Shift the value into positive long range.
            MutableBigInteger xk = new MutableBigInteger(this);
            xk.rightShift(shift);
            xk.normalize();

            // Use the square root of the shifted value as an approximation.
            double d = new BigInteger(xk.value, 1).doubleValue();
            BigInteger bi = BigInteger.valueOf(cast(long)std.math.ceil(std.math.sqrt(d)));
            xk = new MutableBigInteger(bi.mag);

            // Shift the approximate square root back into the original range.
            xk.leftShift(shift / 2);

            // Refine the estimate.
            MutableBigInteger xk1 = new MutableBigInteger();
            do {
                // xk1 = (xk + n/xk)/2
                this.divide(xk, xk1, false);
                xk1.add(xk);
                xk1.rightShift(1);

                // Terminate when non-decreasing.
                if (xk1.compare(xk) >= 0) {
                    return xk;
                }

                // xk = xk1
                xk.copyValue(xk1);

                xk1.reset();
            } while (true);
        }
    }

    /**
     * Calculate GCD of this and b. This and b are changed by the computation.
     */
    MutableBigInteger hybridGCD(MutableBigInteger b) {
        // Use Euclid's algorithm until the numbers are approximately the
        // same length, then use the binary GCD algorithm to find the GCD.
        MutableBigInteger a = this;
        MutableBigInteger q = new MutableBigInteger();

        while (b.intLen != 0) {
            if (std.math.abs(a.intLen - b.intLen) < 2)
                return a.binaryGCD(b);

            MutableBigInteger r = a.divide(b, q);
            a = b;
            b = r;
        }
        return a;
    }

    /**
     * Calculate GCD of this and v.
     * Assumes that this and v are not zero.
     */
    private MutableBigInteger binaryGCD(MutableBigInteger v) {
        // Algorithm B from Knuth section 4.5.2
        MutableBigInteger u = this;
        MutableBigInteger r = new MutableBigInteger();

        // step B1
        int s1 = u.getLowestSetBit();
        int s2 = v.getLowestSetBit();
        int k = (s1 < s2) ? s1 : s2;
        if (k != 0) {
            u.rightShift(k);
            v.rightShift(k);
        }

        // step B2
        bool uOdd = (k == s1);
        MutableBigInteger t = uOdd ? v: u;
        int tsign = uOdd ? -1 : 1;

        int lb;
        while ((lb = t.getLowestSetBit()) >= 0) {
            // steps B3 and B4
            t.rightShift(lb);
            // step B5
            if (tsign > 0)
                u = t;
            else
                v = t;

            // Special case one word numbers
            if (u.intLen < 2 && v.intLen < 2) {
                int x = u.value[u.offset];
                int y = v.value[v.offset];
                x  = binaryGcd(x, y);
                r.value[0] = x;
                r.intLen = 1;
                r.offset = 0;
                if (k > 0)
                    r.leftShift(k);
                return r;
            }

            // step B6
            if ((tsign = u.difference(v)) == 0)
                break;
            t = (tsign >= 0) ? u : v;
        }

        if (k > 0)
            u.leftShift(k);
        return u;
    }

    /**
     * Calculate GCD of a and b interpreted as unsigned integers.
     */
    static int binaryGcd(int a, int b) {
        if (b == 0)
            return a;
        if (a == 0)
            return b;

        // Right shift a & b till their last bits equal to 1.
        int aZeros = Integer.numberOfTrailingZeros(a);
        int bZeros = Integer.numberOfTrailingZeros(b);
        a >>>= aZeros;
        b >>>= bZeros;

        int t = (aZeros < bZeros ? aZeros : bZeros);

        while (a != b) {
            if ((a+0x80000000) > (b+0x80000000)) {  // a > b as unsigned
                a -= b;
                a >>>= Integer.numberOfTrailingZeros(a);
            } else {
                b -= a;
                b >>>= Integer.numberOfTrailingZeros(b);
            }
        }
        return a<<t;
    }

    /**
     * Returns the modInverse of this mod p. This and p are not affected by
     * the operation.
     */
    MutableBigInteger mutableModInverse(MutableBigInteger p) {
        // Modulus is odd, use Schroeppel's algorithm
        if (p.isOdd())
            return modInverse(p);

        // Base and modulus are even, throw exception
        if (isEven())
            throw new ArithmeticException("BigInteger not invertible.");

        // Get even part of modulus expressed as a power of 2
        int powersOf2 = p.getLowestSetBit();

        // Construct odd part of modulus
        MutableBigInteger oddMod = new MutableBigInteger(p);
        oddMod.rightShift(powersOf2);

        if (oddMod.isOne())
            return modInverseMP2(powersOf2);

        // Calculate 1/a mod oddMod
        MutableBigInteger oddPart = modInverse(oddMod);

        // Calculate 1/a mod evenMod
        MutableBigInteger evenPart = modInverseMP2(powersOf2);

        // Combine the results using Chinese Remainder Theorem
        MutableBigInteger y1 = modInverseBP2(oddMod, powersOf2);
        MutableBigInteger y2 = oddMod.modInverseMP2(powersOf2);

        MutableBigInteger temp1 = new MutableBigInteger();
        MutableBigInteger temp2 = new MutableBigInteger();
        MutableBigInteger result = new MutableBigInteger();

        oddPart.leftShift(powersOf2);
        oddPart.multiply(y1, result);

        evenPart.multiply(oddMod, temp1);
        temp1.multiply(y2, temp2);

        result.add(temp2);
        return result.divide(p, temp1);
    }

    /*
     * Calculate the multiplicative inverse of this mod 2^k.
     */
    MutableBigInteger modInverseMP2(int k) {
        if (isEven())
            throw new ArithmeticException("Non-invertible. (GCD != 1)");

        if (k > 64)
            return euclidModInverse(k);

        int t = inverseMod32(value[offset+intLen-1]);

        if (k < 33) {
            t = (k == 32 ? t : t & ((1 << k) - 1));
            return new MutableBigInteger(t);
        }

        long pLong = (value[offset+intLen-1] & LONG_MASK);
        if (intLen > 1)
            pLong |=  (cast(long)value[offset+intLen-2] << 32);
        long tLong = t & LONG_MASK;
        tLong = tLong * (2 - pLong * tLong);  // 1 more Newton iter step
        tLong = (k == 64 ? tLong : tLong & ((1L << k) - 1));

        MutableBigInteger result = new MutableBigInteger(new int[2]);
        result.value[0] = cast(int)(tLong >>> 32);
        result.value[1] = cast(int)tLong;
        result.intLen = 2;
        result.normalize();
        return result;
    }

    /**
     * Returns the multiplicative inverse of val mod 2^32.  Assumes val is odd.
     */
    static int inverseMod32(int val) {
        // Newton's iteration!
        int t = val;
        t *= 2 - val*t;
        t *= 2 - val*t;
        t *= 2 - val*t;
        t *= 2 - val*t;
        return t;
    }

    /**
     * Returns the multiplicative inverse of val mod 2^64.  Assumes val is odd.
     */
    static long inverseMod64(long val) {
        // Newton's iteration!
        long t = val;
        t *= 2 - val*t;
        t *= 2 - val*t;
        t *= 2 - val*t;
        t *= 2 - val*t;
        t *= 2 - val*t;
        assert(t * val == 1);
        return t;
    }

    /**
     * Calculate the multiplicative inverse of 2^k mod mod, where mod is odd.
     */
    static MutableBigInteger modInverseBP2(MutableBigInteger mod, int k) {
        // Copy the mod to protect original
        return fixup(new MutableBigInteger(1), new MutableBigInteger(mod), k);
    }

    /**
     * Calculate the multiplicative inverse of this mod mod, where mod is odd.
     * This and mod are not changed by the calculation.
     *
     * This method implements an algorithm due to Richard Schroeppel, that uses
     * the same intermediate representation as Montgomery Reduction
     * ("Montgomery Form").  The algorithm is described in an unpublished
     * manuscript entitled "Fast Modular Reciprocals."
     */
    private MutableBigInteger modInverse(MutableBigInteger mod) {
        MutableBigInteger p = new MutableBigInteger(mod);
        MutableBigInteger f = new MutableBigInteger(this);
        MutableBigInteger g = new MutableBigInteger(p);
        SignedMutableBigInteger c = new SignedMutableBigInteger(1);
        SignedMutableBigInteger d = new SignedMutableBigInteger();
        MutableBigInteger temp = null;
        SignedMutableBigInteger sTemp = null;

        int k = 0;
        // Right shift f k times until odd, left shift d k times
        if (f.isEven()) {
            int trailingZeros = f.getLowestSetBit();
            f.rightShift(trailingZeros);
            d.leftShift(trailingZeros);
            k = trailingZeros;
        }

        // The Almost Inverse Algorithm
        while (!f.isOne()) {
            // If gcd(f, g) != 1, number is not invertible modulo mod
            if (f.isZero())
                throw new ArithmeticException("BigInteger not invertible.");

            // If f < g exchange f, g and c, d
            if (f.compare(g) < 0) {
                temp = f; f = g; g = temp;
                sTemp = d; d = c; c = sTemp;
            }

            // If f == g (mod 4)
            if (((f.value[f.offset + f.intLen - 1] ^
                 g.value[g.offset + g.intLen - 1]) & 3) == 0) {
                f.subtract(g);
                c.signedSubtract(d);
            } else { // If f != g (mod 4)
                f.add(g);
                c.signedAdd(d);
            }

            // Right shift f k times until odd, left shift d k times
            int trailingZeros = f.getLowestSetBit();
            f.rightShift(trailingZeros);
            d.leftShift(trailingZeros);
            k += trailingZeros;
        }

        while (c.sign < 0)
           c.signedAdd(p);

        return fixup(c, p, k);
    }

    /**
     * The Fixup Algorithm
     * Calculates X such that X = C * 2^(-k) (mod P)
     * Assumes C<P and P is odd.
     */
    static MutableBigInteger fixup(MutableBigInteger c, MutableBigInteger p,
                                                                      int k) {
        MutableBigInteger temp = new MutableBigInteger();
        // Set r to the multiplicative inverse of p mod 2^32
        int r = -inverseMod32(p.value[p.offset+p.intLen-1]);

        for (int i=0, numWords = k >> 5; i < numWords; i++) {
            // V = R * c (mod 2^j)
            int  v = r * c.value[c.offset + c.intLen-1];
            // c = c + (v * p)
            p.mul(v, temp);
            c.add(temp);
            // c = c / 2^j
            c.intLen--;
        }
        int numBits = k & 0x1f;
        if (numBits != 0) {
            // V = R * c (mod 2^j)
            int v = r * c.value[c.offset + c.intLen-1];
            v &= ((1<<numBits) - 1);
            // c = c + (v * p)
            p.mul(v, temp);
            c.add(temp);
            // c = c / 2^j
            c.rightShift(numBits);
        }

        // In theory, c may be greater than p at this point (Very rare!)
        while (c.compare(p) >= 0)
            c.subtract(p);

        return c;
    }

    /**
     * Uses the extended Euclidean algorithm to compute the modInverse of base
     * mod a modulus that is a power of 2. The modulus is 2^k.
     */
    MutableBigInteger euclidModInverse(int k) {
        MutableBigInteger b = new MutableBigInteger(1);
        b.leftShift(k);
        MutableBigInteger mod = new MutableBigInteger(b);

        MutableBigInteger a = new MutableBigInteger(this);
        MutableBigInteger q = new MutableBigInteger();
        MutableBigInteger r = b.divide(a, q);

        MutableBigInteger swapper = b;
        // swap b & r
        b = r;
        r = swapper;

        MutableBigInteger t1 = new MutableBigInteger(q);
        MutableBigInteger t0 = new MutableBigInteger(1);
        MutableBigInteger temp = new MutableBigInteger();

        while (!b.isOne()) {
            r = a.divide(b, q);

            if (r.intLen == 0)
                throw new ArithmeticException("BigInteger not invertible.");

            swapper = r;
            a = swapper;

            if (q.intLen == 1)
                t1.mul(q.value[q.offset], temp);
            else
                q.multiply(t1, temp);
            swapper = q;
            q = temp;
            temp = swapper;
            t0.add(q);

            if (a.isOne())
                return t0;

            r = b.divide(a, q);

            if (r.intLen == 0)
                throw new ArithmeticException("BigInteger not invertible.");

            swapper = b;
            b =  r;

            if (q.intLen == 1)
                t0.mul(q.value[q.offset], temp);
            else
                q.multiply(t0, temp);
            swapper = q; q = temp; temp = swapper;

            t1.add(q);
        }
        mod.subtract(t1);
        return mod;
    }
}



/**
 * A class used to represent multiprecision integers that makes efficient
 * use of allocated space by allowing a number to occupy only part of
 * an array so that the arrays do not have to be reallocated as often.
 * When performing an operation with many iterations the array used to
 * hold a number is only increased when necessary and does not have to
 * be the same size as the number it represents. A mutable number allows
 * calculations to occur on the same number without having to create
 * a new number for every step of the calculation as occurs with
 * BigIntegers.
 *
 * Note that SignedMutableBigIntegers only support signed addition and
 * subtraction. All other operations occur as with MutableBigIntegers.
 *
 * @see     BigInteger
 * @author  Michael McCloskey
 * @since   1.3
 */

class SignedMutableBigInteger : MutableBigInteger {

   /**
     * The sign of this MutableBigInteger.
     */
    int sign = 1;

    // Constructors

    /**
     * The default constructor. An empty MutableBigInteger is created with
     * a one word capacity.
     */
    this() {
        super();
    }

    /**
     * Construct a new MutableBigInteger with a magnitude specified by
     * the int val.
     */
    this(int val) {
        super(val);
    }

    /**
     * Construct a new MutableBigInteger with a magnitude equal to the
     * specified MutableBigInteger.
     */
    this(MutableBigInteger val) {
        super(val);
    }

   // Arithmetic Operations

   /**
     * Signed addition built upon unsigned add and subtract.
     */
    void signedAdd(SignedMutableBigInteger addend) {
        if (sign == addend.sign)
            add(addend);
        else
            sign = sign * subtract(addend);

    }

   /**
     * Signed addition built upon unsigned add and subtract.
     */
    void signedAdd(MutableBigInteger addend) {
        if (sign == 1)
            add(addend);
        else
            sign = sign * subtract(addend);

    }

   /**
     * Signed subtraction built upon unsigned add and subtract.
     */
    void signedSubtract(SignedMutableBigInteger addend) {
        if (sign == addend.sign)
            sign = sign * subtract(addend);
        else
            add(addend);

    }

   /**
     * Signed subtraction built upon unsigned add and subtract.
     */
    void signedSubtract(MutableBigInteger addend) {
        if (sign == 1)
            sign = sign * subtract(addend);
        else
            add(addend);
        if (intLen == 0)
             sign = 1;
    }

    /**
     * Print out the first intLen ints of this MutableBigInteger's value
     * array starting at offset.
     */
    override string toString() {
        return this.toBigInteger(sign).toString();
    }

}



/**
 * A simple bit sieve used for finding prime number candidates. Allows setting
 * and clearing of bits in a storage array. The size of the sieve is assumed to
 * be constant to reduce overhead. All the bits of a new bitSieve are zero, and
 * bits are removed from it by setting them.
 *
 * To reduce storage space and increase efficiency, no even numbers are
 * represented in the sieve (each bit in the sieve represents an odd number).
 * The relationship between the index of a bit and the number it represents is
 * given by
 * N = offset + (2*index + 1);
 * Where N is the integer represented by a bit in the sieve, offset is some
 * even integer offset indicating where the sieve begins, and index is the
 * index of a bit in the sieve array.
 *
 * @see     BigInteger
 * @author  Michael McCloskey
 * @since   1.3
 */
class BitSieve {
    /**
     * Stores the bits in this bitSieve.
     */
    private long[] bits;

    /**
     * Length is how many bits this sieve holds.
     */
    private int length;

    /**
     * A small sieve used to filter out multiples of small primes in a search
     * sieve.
     */
    private __gshared BitSieve smallSieve;

    shared static this() {
        smallSieve = new BitSieve();
    }

    /**
     * Construct a "small sieve" with a base of 0.  This constructor is
     * used internally to generate the set of "small primes" whose multiples
     * are excluded from sieves generated by the main (package private)
     * constructor, BitSieve(BigInteger base, int searchLen).  The length
     * of the sieve generated by this constructor was chosen for performance;
     * it controls a tradeoff between how much time is spent constructing
     * other sieves, and how much time is wasted testing composite candidates
     * for primality.  The length was chosen experimentally to yield good
     * performance.
     */
    private this() {
        length = 150 * 64;
        bits = new long[(unitIndex(length - 1) + 1)];

        // Mark 1 as composite
        set(0);
        int nextIndex = 1;
        int nextPrime = 3;

        // Find primes and remove their multiples from sieve
        do {
            sieveSingle(length, nextIndex + nextPrime, nextPrime);
            nextIndex = sieveSearch(length, nextIndex + 1);
            nextPrime = 2*nextIndex + 1;
        } while((nextIndex > 0) && (nextPrime < length));
    }

    /**
     * Construct a bit sieve of searchLen bits used for finding prime number
     * candidates. The new sieve begins at the specified base, which must
     * be even.
     */
    this(BigInteger base, int searchLen) {
        /*
         * Candidates are indicated by clear bits in the sieve. As a candidates
         * nonprimality is calculated, a bit is set in the sieve to eliminate
         * it. To reduce storage space and increase efficiency, no even numbers
         * are represented in the sieve (each bit in the sieve represents an
         * odd number).
         */
        bits = new long[(unitIndex(searchLen-1) + 1)];
        length = searchLen;
        int start = 0;

        int step = smallSieve.sieveSearch(smallSieve.length, start);
        int convertedStep = (step *2) + 1;

        // Construct the large sieve at an even offset specified by base
        MutableBigInteger b = new MutableBigInteger(base);
        MutableBigInteger q = new MutableBigInteger();
        do {
            // Calculate base mod convertedStep
            start = b.divideOneWord(convertedStep, q);

            // Take each multiple of step out of sieve
            start = convertedStep - start;
            if (start%2 == 0)
                start += convertedStep;
            sieveSingle(searchLen, (start-1)/2, convertedStep);

            // Find next prime from small sieve
            step = smallSieve.sieveSearch(smallSieve.length, step+1);
            convertedStep = (step *2) + 1;
        } while (step > 0);
    }

    /**
     * Given a bit index return unit index containing it.
     */
    private static int unitIndex(int bitIndex) {
        return bitIndex >>> 6;
    }

    /**
     * Return a unit that masks the specified bit in its unit.
     */
    private static long bit(int bitIndex) {
        return 1L << (bitIndex & ((1<<6) - 1));
    }

    /**
     * Get the value of the bit at the specified index.
     */
    private bool get(int bitIndex) {
        int unitIndex = unitIndex(bitIndex);
        return ((bits[unitIndex] & bit(bitIndex)) != 0);
    }

    /**
     * Set the bit at the specified index.
     */
    private void set(int bitIndex) {
        int unitIndex = unitIndex(bitIndex);
        bits[unitIndex] |= bit(bitIndex);
    }

    /**
     * This method returns the index of the first clear bit in the search
     * array that occurs at or after start. It will not search past the
     * specified limit. It returns -1 if there is no such clear bit.
     */
    private int sieveSearch(int limit, int start) {
        if (start >= limit)
            return -1;

        int index = start;
        do {
            if (!get(index))
                return index;
            index++;
        } while(index < limit-1);
        return -1;
    }

    /**
     * Sieve a single set of multiples out of the sieve. Begin to remove
     * multiples of the specified step starting at the specified start index,
     * up to the specified limit.
     */
    private void sieveSingle(int limit, int start, int step) {
        while(start < limit) {
            set(start);
            start += step;
        }
    }

    /**
     * Test probable primes in the sieve and return successful candidates.
     */
    BigInteger retrieve(BigInteger initValue, int certainty, Random* random) {
        // Examine the sieve one long at a time to find possible primes
        int offset = 1;
        for (int i=0; i<bits.length; i++) {
            long nextLong = ~bits[i];
            for (int j=0; j<64; j++) {
                if ((nextLong & 1) == 1) {
                    BigInteger candidate = initValue.add(
                                           BigInteger.valueOf(offset));
                    if (candidate.primeToCertainty(certainty, random))
                        return candidate;
                }
                nextLong >>>= 1;
                offset+=2;
            }
        }
        return null;
    }

}