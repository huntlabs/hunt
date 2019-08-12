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

module hunt.Char;

import hunt.Nullable;
import hunt.Exceptions;
import hunt.text.Common;
/**
 * The {@code Character} class wraps a value of the primitive
 * type {@code char} in an object. An object of type
 * {@code Character} contains a single field whose type is
 * {@code char}.
 * <p>
 * In addition, this class provides several methods for determining
 * a character's category (lowercase letter, digit, etc.) and for converting
 * characters from uppercase to lowercase and vice versa.
 * <p>
 * Character information is based on the Unicode Standard, version 8.0.0.
 * <p>
 * The methods and data of class {@code Character} are defined by
 * the information in the <i>UnicodeData</i> file that is part of the
 * Unicode Character Database maintained by the Unicode
 * Consortium. This file specifies various properties including name
 * and general category for every defined Unicode code point or
 * character range.
 * <p>
 * The file and its description are available from the Unicode Consortium at:
 * <ul>
 * <li><a href="http://www.unicode.org">http://www.unicode.org</a>
 * </ul>
 *
 * <h3><a id="unicode">Unicode Character Representations</a></h3>
 *
 * <p>The {@code char} data type (and therefore the value that a
 * {@code Character} object encapsulates) are based on the
 * original Unicode specification, which defined characters as
 * fixed-width 16-bit entities. The Unicode Standard has since been
 * changed to allow for characters whose representation requires more
 * than 16 bits.  The range of legal <em>code point</em>s is now
 * U+0000 to U+10FFFF, known as <em>Unicode scalar value</em>.
 * (Refer to the <a
 * href="http://www.unicode.org/reports/tr27/#notation"><i>
 * definition</i></a> of the U+<i>n</i> notation in the Unicode
 * Standard.)
 *
 * <p><a id="BMP">The set of characters from U+0000 to U+FFFF</a> is
 * sometimes referred to as the <em>Basic Multilingual Plane (BMP)</em>.
 * <a id="supplementary">Characters</a> whose code points are greater
 * than U+FFFF are called <em>supplementary character</em>s.  The Java
 * platform uses the UTF-16 representation in {@code char} arrays and
 * in the {@code string} and {@code StringBuffer} classes. In
 * this representation, supplementary characters are represented as a pair
 * of {@code char} values, the first from the <em>high-surrogates</em>
 * range, (&#92;uD800-&#92;uDBFF), the second from the
 * <em>low-surrogates</em> range (&#92;uDC00-&#92;uDFFF).
 *
 * <p>A {@code char} value, therefore, represents Basic
 * Multilingual Plane (BMP) code points, including the surrogate
 * code points, or code units of the UTF-16 encoding. An
 * {@code int} value represents all Unicode code points,
 * including supplementary code points. The lower (least significant)
 * 21 bits of {@code int} are used to represent Unicode code
 * points and the upper (most significant) 11 bits must be zero.
 * Unless otherwise specified, the behavior with respect to
 * supplementary characters and surrogate {@code char} values is
 * as follows:
 *
 * <ul>
 * <li>The methods that only accept a {@code char} value cannot support
 * supplementary characters. They treat {@code char} values from the
 * surrogate ranges as undefined characters. For example,
 * {@code Character.isLetter('\u005CuD840')} returns {@code false}, even though
 * this specific value if followed by any low-surrogate value in a string
 * would represent a letter.
 *
 * <li>The methods that accept an {@code int} value support all
 * Unicode characters, including supplementary characters. For
 * example, {@code Character.isLetter(0x2F81A)} returns
 * {@code true} because the code point value represents a letter
 * (a CJK ideograph).
 * </ul>
 *
 * <p>In the Java SE API documentation, <em>Unicode code point</em> is
 * used for character values in the range between U+0000 and U+10FFFF,
 * and <em>Unicode code unit</em> is used for 16-bit
 * {@code char} values that are code units of the <em>UTF-16</em>
 * encoding. For more information on Unicode terminology, refer to the
 * <a href="http://www.unicode.org/glossary/">Unicode Glossary</a>.
 *
 * @author  Lee Boynton
 * @author  Guy Steele
 * @author  Akira Tanaka
 * @author  Martin Buchholz
 * @author  Ulf Zibis
 * @since   1.0
 */
class Char : Nullable!char {
    /**
     * The minimum radix available for conversion to and from strings.
     * The constant value of this field is the smallest value permitted
     * for the radix argument in radix-conversion methods such as the
     * {@code digit} method, the {@code forDigit} method, and the
     * {@code toString} method of class {@code Integer}.
     *
     * @see     Character#digit(char, int)
     * @see     Character#forDigit(int, int)
     * @see     Integer#toString(int, int)
     * @see     Integer#valueOf(string)
     */
    enum int MIN_RADIX = 2;

    /**
     * The maximum radix available for conversion to and from strings.
     * The constant value of this field is the largest value permitted
     * for the radix argument in radix-conversion methods such as the
     * {@code digit} method, the {@code forDigit} method, and the
     * {@code toString} method of class {@code Integer}.
     *
     * @see     Character#digit(char, int)
     * @see     Character#forDigit(int, int)
     * @see     Integer#toString(int, int)
     * @see     Integer#valueOf(string)
     */
    enum int MAX_RADIX = 36;

    /**
     * The constant value of this field is the smallest value of type
     * {@code char}, {@code '\u005Cu0000'}.
     *
     * @since   1.0.2
     */
    enum char MIN_VALUE = '\u0000';

    /**
     * The constant value of this field is the largest value of type
     * {@code char}, {@code '\u005CuFFFF'}.
     *
     * @since   1.0.2
     */
    // enum char MAX_VALUE = '\uFFFF';

    /**
     * The {@code Class} instance representing the primitive type
     * {@code char}.
     *
     * @since   1.1
     */
    // 
    // enum Class<Character> TYPE = (Class<Character>) Class.getPrimitiveClass("char");

    /*
     * Normative general types
     */

    /*
     * General character types
     */

    /**
     * General category "Cn" in the Unicode specification.
     * @since   1.1
     */
    enum byte UNASSIGNED = 0;

    /**
     * General category "Lu" in the Unicode specification.
     * @since   1.1
     */
    enum byte UPPERCASE_LETTER = 1;

    /**
     * General category "Ll" in the Unicode specification.
     * @since   1.1
     */
    enum byte LOWERCASE_LETTER = 2;

    /**
     * General category "Lt" in the Unicode specification.
     * @since   1.1
     */
    enum byte TITLECASE_LETTER = 3;

    /**
     * General category "Lm" in the Unicode specification.
     * @since   1.1
     */
    enum byte MODIFIER_LETTER = 4;

    /**
     * General category "Lo" in the Unicode specification.
     * @since   1.1
     */
    enum byte OTHER_LETTER = 5;

    /**
     * General category "Mn" in the Unicode specification.
     * @since   1.1
     */
    enum byte NON_SPACING_MARK = 6;

    /**
     * General category "Me" in the Unicode specification.
     * @since   1.1
     */
    enum byte ENCLOSING_MARK = 7;

    /**
     * General category "Mc" in the Unicode specification.
     * @since   1.1
     */
    enum byte COMBINING_SPACING_MARK = 8;

    /**
     * General category "Nd" in the Unicode specification.
     * @since   1.1
     */
    enum byte DECIMAL_DIGIT_NUMBER = 9;

    /**
     * General category "Nl" in the Unicode specification.
     * @since   1.1
     */
    enum byte LETTER_NUMBER = 10;

    /**
     * General category "No" in the Unicode specification.
     * @since   1.1
     */
    enum byte OTHER_NUMBER = 11;

    /**
     * General category "Zs" in the Unicode specification.
     * @since   1.1
     */
    enum byte SPACE_SEPARATOR = 12;

    /**
     * General category "Zl" in the Unicode specification.
     * @since   1.1
     */
    enum byte LINE_SEPARATOR = 13;

    /**
     * General category "Zp" in the Unicode specification.
     * @since   1.1
     */
    enum byte PARAGRAPH_SEPARATOR = 14;

    /**
     * General category "Cc" in the Unicode specification.
     * @since   1.1
     */
    enum byte CONTROL = 15;

    /**
     * General category "Cf" in the Unicode specification.
     * @since   1.1
     */
    enum byte FORMAT = 16;

    /**
     * General category "Co" in the Unicode specification.
     * @since   1.1
     */
    enum byte PRIVATE_USE = 18;

    /**
     * General category "Cs" in the Unicode specification.
     * @since   1.1
     */
    enum byte SURROGATE = 19;

    /**
     * General category "Pd" in the Unicode specification.
     * @since   1.1
     */
    enum byte DASH_PUNCTUATION = 20;

    /**
     * General category "Ps" in the Unicode specification.
     * @since   1.1
     */
    enum byte START_PUNCTUATION = 21;

    /**
     * General category "Pe" in the Unicode specification.
     * @since   1.1
     */
    enum byte END_PUNCTUATION = 22;

    /**
     * General category "Pc" in the Unicode specification.
     * @since   1.1
     */
    enum byte CONNECTOR_PUNCTUATION = 23;

    /**
     * General category "Po" in the Unicode specification.
     * @since   1.1
     */
    enum byte OTHER_PUNCTUATION = 24;

    /**
     * General category "Sm" in the Unicode specification.
     * @since   1.1
     */
    enum byte MATH_SYMBOL = 25;

    /**
     * General category "Sc" in the Unicode specification.
     * @since   1.1
     */
    enum byte CURRENCY_SYMBOL = 26;

    /**
     * General category "Sk" in the Unicode specification.
     * @since   1.1
     */
    enum byte MODIFIER_SYMBOL = 27;

    /**
     * General category "So" in the Unicode specification.
     * @since   1.1
     */
    enum byte OTHER_SYMBOL = 28;

    /**
     * General category "Pi" in the Unicode specification.
     * @since   1.4
     */
    enum byte INITIAL_QUOTE_PUNCTUATION = 29;

    /**
     * General category "Pf" in the Unicode specification.
     * @since   1.4
     */
    enum byte FINAL_QUOTE_PUNCTUATION = 30;

    /**
     * Error flag. Use int (code point) to avoid confusion with U+FFFF.
     */
    enum int ERROR = 0xFFFFFFFF;

    /**
     * Undefined bidirectional character type. Undefined {@code char}
     * values have undefined directionality in the Unicode specification.
     */
    enum byte DIRECTIONALITY_UNDEFINED = -1;

    /**
     * Strong bidirectional character type "L" in the Unicode specification.
     */
    enum byte DIRECTIONALITY_LEFT_TO_RIGHT = 0;

    /**
     * Strong bidirectional character type "R" in the Unicode specification.
     */
    enum byte DIRECTIONALITY_RIGHT_TO_LEFT = 1;

    /**
    * Strong bidirectional character type "AL" in the Unicode specification.
     */
    enum byte DIRECTIONALITY_RIGHT_TO_LEFT_ARABIC = 2;

    /**
     * Weak bidirectional character type "EN" in the Unicode specification.
     */
    enum byte DIRECTIONALITY_EUROPEAN_NUMBER = 3;

    /**
     * Weak bidirectional character type "ES" in the Unicode specification.
     */
    enum byte DIRECTIONALITY_EUROPEAN_NUMBER_SEPARATOR = 4;

    /**
     * Weak bidirectional character type "ET" in the Unicode specification.
     */
    enum byte DIRECTIONALITY_EUROPEAN_NUMBER_TERMINATOR = 5;

    /**
     * Weak bidirectional character type "AN" in the Unicode specification.
     */
    enum byte DIRECTIONALITY_ARABIC_NUMBER = 6;

    /**
     * Weak bidirectional character type "CS" in the Unicode specification.
     */
    enum byte DIRECTIONALITY_COMMON_NUMBER_SEPARATOR = 7;

    /**
     * Weak bidirectional character type "NSM" in the Unicode specification.
     */
    enum byte DIRECTIONALITY_NONSPACING_MARK = 8;

    /**
     * Weak bidirectional character type "BN" in the Unicode specification.
     */
    enum byte DIRECTIONALITY_BOUNDARY_NEUTRAL = 9;

    /**
     * Neutral bidirectional character type "B" in the Unicode specification.
     */
    enum byte DIRECTIONALITY_PARAGRAPH_SEPARATOR = 10;

    /**
     * Neutral bidirectional character type "S" in the Unicode specification.
     */
    enum byte DIRECTIONALITY_SEGMENT_SEPARATOR = 11;

    /**
     * Neutral bidirectional character type "WS" in the Unicode specification.
     */
    enum byte DIRECTIONALITY_WHITESPACE = 12;

    /**
     * Neutral bidirectional character type "ON" in the Unicode specification.
     */
    enum byte DIRECTIONALITY_OTHER_NEUTRALS = 13;

    /**
     * Strong bidirectional character type "LRE" in the Unicode specification.
     */
    enum byte DIRECTIONALITY_LEFT_TO_RIGHT_EMBEDDING = 14;

    /**
     * Strong bidirectional character type "LRO" in the Unicode specification.
     */
    enum byte DIRECTIONALITY_LEFT_TO_RIGHT_OVERRIDE = 15;

    /**
     * Strong bidirectional character type "RLE" in the Unicode specification.
     */
    enum byte DIRECTIONALITY_RIGHT_TO_LEFT_EMBEDDING = 16;

    /**
     * Strong bidirectional character type "RLO" in the Unicode specification.
     */
    enum byte DIRECTIONALITY_RIGHT_TO_LEFT_OVERRIDE = 17;

    /**
     * Weak bidirectional character type "PDF" in the Unicode specification.
     */
    enum byte DIRECTIONALITY_POP_DIRECTIONAL_FORMAT = 18;

    /**
     * The minimum value of a
     * <a href="http://www.unicode.org/glossary/#high_surrogate_code_unit">
     * Unicode high-surrogate code unit</a>
     * in the UTF-16 encoding, constant {@code '\u005CuD800'}.
     * A high-surrogate is also known as a <i>leading-surrogate</i>.
     *
     */
    enum wchar MIN_HIGH_SURROGATE = 0xD800;

    /**
     * The maximum value of a
     * <a href="http://www.unicode.org/glossary/#high_surrogate_code_unit">
     * Unicode high-surrogate code unit</a>
     * in the UTF-16 encoding, constant {@code '\u005CuDBFF'}.
     * A high-surrogate is also known as a <i>leading-surrogate</i>.
     *
     */
    enum wchar MAX_HIGH_SURROGATE = 0xDBFF;

    /**
     * The minimum value of a
     * <a href="http://www.unicode.org/glossary/#low_surrogate_code_unit">
     * Unicode low-surrogate code unit</a>
     * in the UTF-16 encoding, constant {@code '\u005CuDC00'}.
     * A low-surrogate is also known as a <i>trailing-surrogate</i>.
     *
     */
    enum wchar MIN_LOW_SURROGATE  = 0xDC00;

    /**
     * The maximum value of a
     * <a href="http://www.unicode.org/glossary/#low_surrogate_code_unit">
     * Unicode low-surrogate code unit</a>
     * in the UTF-16 encoding, constant {@code '\u005CuDFFF'}.
     * A low-surrogate is also known as a <i>trailing-surrogate</i>.
     *
     */
    enum wchar MAX_LOW_SURROGATE  = 0xDFFF;

    /**
     * The minimum value of a Unicode surrogate code unit in the
     * UTF-16 encoding, constant {@code '\u005CuD800'}.
     *
     */
    enum wchar MIN_SURROGATE = MIN_HIGH_SURROGATE;

    /**
     * The maximum value of a Unicode surrogate code unit in the
     * UTF-16 encoding, constant {@code '\u005CuDFFF'}.
     *
     */
    enum wchar MAX_SURROGATE = MAX_LOW_SURROGATE;

    /**
     * The maximum value of a Unicode surrogate code unit in the
     * UTF-16 encoding, constant {@code '\u005CuDFFF'}.
     *
     */
    // enum wchar MAX_SURROGATE = MAX_LOW_SURROGATE;

    /**
     * The minimum value of a
     * <a href="http://www.unicode.org/glossary/#supplementary_code_point">
     * Unicode supplementary code point</a>, constant {@code U+10000}.
     *
     */
    enum int MIN_SUPPLEMENTARY_CODE_POINT = 0x010000;

    /**
     * The minimum value of a
     * <a href="http://www.unicode.org/glossary/#code_point">
     * Unicode code point</a>, constant {@code U+0000}.
     *
     */
    enum int MIN_CODE_POINT = 0x000000;

    /**
     * The maximum value of a
     * <a href="http://www.unicode.org/glossary/#code_point">
     * Unicode code point</a>, constant {@code U+10FFFF}.
     *
     */
    enum int MAX_CODE_POINT = 0X10FFFF;

    this(char value) {
        super(value);
    }

    /**
     * Returns a {@code Character} instance representing the specified
     * {@code char} value.
     * If a new {@code Character} instance is not required, this method
     * should generally be used in preference to the constructor
     * {@link #Character(char)}, as this method is likely to yield
     * significantly better space and time performance by caching
     * frequently requested values.
     *
     * This method will always cache values in the range {@code
     * '\u005Cu0000'} to {@code '\u005Cu007F'}, inclusive, and may
     * cache other values outside of this range.
     *
     * @param  c a char value.
     * @return a {@code Character} instance representing {@code c}.
     * @since  1.5
     */
    static Char valueOf(char c) {
        if (c <= 127) { // must cache
            return CharacterCache.cache[cast(int)c];
        }
        return new Char(c);
    }

    /**
     * Returns the value of this {@code Character} object.
     * @return  the primitive {@code char} value represented by
     *          this object.
     */
    char charValue() {
        return _value;
    }

    override size_t toHash() @trusted nothrow {
        return _value;
    }

    /**
     * Determines the number of {@code char} values needed to
     * represent the specified character (Unicode code point). If the
     * specified character is equal to or greater than 0x10000, then
     * the method returns 2. Otherwise, the method returns 1.
     *
     * <p>This method doesn't validate the specified character to be a
     * valid Unicode code point. The caller must validate the
     * character value using {@link #isValidCodePoint(int) isValidCodePoint}
     * if necessary.
     *
     * @param   codePoint the character (Unicode code point) to be tested.
     * @return  2 if the character is a valid supplementary character; 1 otherwise.
     * @see     Character#isSupplementaryCodePoint(int)
     * @since   1.5
     */
    static int charCount(int codePoint) {
        return codePoint >= MIN_SUPPLEMENTARY_CODE_POINT ? 2 : 1;
    }

    /**
     * Converts the specified surrogate pair to its supplementary code
     * point value. This method does not validate the specified
     * surrogate pair. The caller must validate it using {@link
     * #isSurrogatePair(char, char) isSurrogatePair} if necessary.
     *
     * @param  high the high-surrogate code unit
     * @param  low the low-surrogate code unit
     * @return the supplementary code point composed from the
     *         specified surrogate pair.
     * @since  1.5
     */
    static int toCodePoint(char high, char low) {
        // Optimized form of:
        // return ((high - MIN_HIGH_SURROGATE) << 10)
        //         + (low - MIN_LOW_SURROGATE)
        //         + MIN_SUPPLEMENTARY_CODE_POINT;
        return ((high << 10) + low) + (MIN_SUPPLEMENTARY_CODE_POINT
                                       - (MIN_HIGH_SURROGATE << 10)
                                       - MIN_LOW_SURROGATE);
    }

     /**
     * Determines if the specified character is an ISO control
     * character.  A character is considered to be an ISO control
     * character if its code is in the range {@code '\u005Cu0000'}
     * through {@code '\u005Cu001F'} or in the range
     * {@code '\u005Cu007F'} through {@code '\u005Cu009F'}.
     *
     * <p><b>Note:</b> This method cannot handle <a
     * href="#supplementary"> supplementary characters</a>. To support
     * all Unicode characters, including supplementary characters, use
     * the {@link #isISOControl(int)} method.
     *
     * @param   ch      the character to be tested.
     * @return  {@code true} if the character is an ISO control character;
     *          {@code false} otherwise.
     *
     * @see     Character#isSpaceChar(char)
     * @see     Character#isWhitespace(char)
     * @since   1.1
     */
    public static bool isISOControl(char ch) {
        return isISOControl(cast(int)ch);
    }

    /**
     * Determines if the referenced character (Unicode code point) is an ISO control
     * character.  A character is considered to be an ISO control
     * character if its code is in the range {@code '\u005Cu0000'}
     * through {@code '\u005Cu001F'} or in the range
     * {@code '\u005Cu007F'} through {@code '\u005Cu009F'}.
     *
     * @param   codePoint the character (Unicode code point) to be tested.
     * @return  {@code true} if the character is an ISO control character;
     *          {@code false} otherwise.
     * @see     Character#isSpaceChar(int)
     * @see     Character#isWhitespace(int)
     * @since   1.5
     */
    public static bool isISOControl(int codePoint) {
        // Optimized form of:
        //     (codePoint >= 0x00 && codePoint <= 0x1F) ||
        //     (codePoint >= 0x7F && codePoint <= 0x9F);
        return codePoint <= 0x9F &&
            (codePoint >= 0x7F || (codePoint >>> 5 == 0));
    }

    /**
     * Converts the specified character (Unicode code point) to its
     * UTF-16 representation stored in a {@code char} array. If
     * the specified code point is a BMP (Basic Multilingual Plane or
     * Plane 0) value, the resulting {@code char} array has
     * the same value as {@code codePoint}. If the specified code
     * point is a supplementary code point, the resulting
     * {@code char} array has the corresponding surrogate pair.
     *
     * @param  codePoint a Unicode code point
     * @return a {@code char} array having
     *         {@code codePoint}'s UTF-16 representation.
     * @throws IllegalArgumentException if the specified
     * {@code codePoint} is not a valid Unicode code point.
     * @since  1.5
     */
    public static char[] toChars(int codePoint) {
        if (isBmpCodePoint(codePoint)) {
            return [ cast(char) codePoint ];
        } else if (isValidCodePoint(codePoint)) {
            char[] result = new char[2];
            toSurrogates(codePoint, result, 0);
            return result;
        } else {
            import std.string;
            throw new IllegalArgumentException(
                format("Not a valid Unicode code point: 0x%X", codePoint));
        }
    }

    /**
     * Determines whether the specified character (Unicode code point)
     * is in the <a href="#BMP">Basic Multilingual Plane (BMP)</a>.
     * Such code points can be represented using a single {@code char}.
     *
     * @param  codePoint the character (Unicode code point) to be tested
     * @return {@code true} if the specified code point is between
     *         {@link #MIN_VALUE} and {@link #MAX_VALUE} inclusive;
     *         {@code false} otherwise.
     * @since  1.7
     */
    public static bool isBmpCodePoint(int codePoint) {
        return codePoint >>> 16 == 0;
        // Optimized form of:
        //     codePoint >= MIN_VALUE && codePoint <= MAX_VALUE
        // We consistently use logical shift (>>>) to facilitate
        // additional runtime optimizations.
    }

    /**
     * Determines whether the specified code point is a valid
     * <a href="http://www.unicode.org/glossary/#code_point">
     * Unicode code point value</a>.
     *
     * @param  codePoint the Unicode code point to be tested
     * @return {@code true} if the specified code point value is between
     *         {@link #MIN_CODE_POINT} and
     *         {@link #MAX_CODE_POINT} inclusive;
     *         {@code false} otherwise.
     * @since  1.5
     */
    public static bool isValidCodePoint(int codePoint) {
        // Optimized form of:
        //     codePoint >= MIN_CODE_POINT && codePoint <= MAX_CODE_POINT
        int plane = codePoint >>> 16;
        return plane < ((MAX_CODE_POINT + 1) >>> 16);
    }

    static void toSurrogates(int codePoint, char[] dst, int index) {
        // We write elements "backwards" to guarantee all-or-nothing
        dst[index+1] = lowSurrogate(codePoint);
        dst[index] = highSurrogate(codePoint);
    }

    /**
     * Returns the trailing surrogate (a
     * <a href="http://www.unicode.org/glossary/#low_surrogate_code_unit">
     * low surrogate code unit</a>) of the
     * <a href="http://www.unicode.org/glossary/#surrogate_pair">
     * surrogate pair</a>
     * representing the specified supplementary character (Unicode
     * code point) in the UTF-16 encoding.  If the specified character
     * is not a
     * <a href="Character.html#supplementary">supplementary character</a>,
     * an unspecified {@code char} is returned.
     *
     * <p>If
     * {@link #isSupplementaryCodePoint isSupplementaryCodePoint(x)}
     * is {@code true}, then
     * {@link #isLowSurrogate isLowSurrogate}{@code (lowSurrogate(x))} and
     * {@link #toCodePoint toCodePoint}{@code (}{@link #highSurrogate highSurrogate}{@code (x), lowSurrogate(x)) == x}
     * are also always {@code true}.
     *
     * @param   codePoint a supplementary character (Unicode code point)
     * @return  the trailing surrogate code unit used to represent the
     *          character in the UTF-16 encoding
     * @since   1.7
     */
    public static char lowSurrogate(int codePoint) {
        return cast(char) ((codePoint & 0x3ff) + MIN_LOW_SURROGATE);
    }


    /**
     * Returns the leading surrogate (a
     * <a href="http://www.unicode.org/glossary/#high_surrogate_code_unit">
     * high surrogate code unit</a>) of the
     * <a href="http://www.unicode.org/glossary/#surrogate_pair">
     * surrogate pair</a>
     * representing the specified supplementary character (Unicode
     * code point) in the UTF-16 encoding.  If the specified character
     * is not a
     * <a href="Character.html#supplementary">supplementary character</a>,
     * an unspecified {@code char} is returned.
     *
     * <p>If
     * {@link #isSupplementaryCodePoint isSupplementaryCodePoint(x)}
     * is {@code true}, then
     * {@link #isHighSurrogate isHighSurrogate}{@code (highSurrogate(x))} and
     * {@link #toCodePoint toCodePoint}{@code (highSurrogate(x), }{@link #lowSurrogate lowSurrogate}{@code (x)) == x}
     * are also always {@code true}.
     *
     * @param   codePoint a supplementary character (Unicode code point)
     * @return  the leading surrogate code unit used to represent the
     *          character in the UTF-16 encoding
     * @since   1.7
     */
    public static char highSurrogate(int codePoint) {
        return cast(char) ((codePoint >>> 10)
            + (MIN_HIGH_SURROGATE - (MIN_SUPPLEMENTARY_CODE_POINT >>> 10)));
    }

    /**
     * Returns the code point at the given index of the
     * {@code CharSequence}. If the {@code char} value at
     * the given index in the {@code CharSequence} is in the
     * high-surrogate range, the following index is less than the
     * length of the {@code CharSequence}, and the
     * {@code char} value at the following index is in the
     * low-surrogate range, then the supplementary code point
     * corresponding to this surrogate pair is returned. Otherwise,
     * the {@code char} value at the given index is returned.
     *
     * @param seq a sequence of {@code char} values (Unicode code
     * units)
     * @param index the index to the {@code char} values (Unicode
     * code units) in {@code seq} to be converted
     * @return the Unicode code point at the given index
     * @throws NullPointerException if {@code seq} is null.
     * @throws IndexOutOfBoundsException if the value
     * {@code index} is negative or not less than
     * {@link CharSequence#length() seq.length()}.
     * @since  1.5
     */
    public static int codePointAt(string seq, int index) {
        char c1 = seq.charAt(index);
        if (isHighSurrogate(c1) && ++index < seq.length) {
            char c2 = seq.charAt(index);
            if (isLowSurrogate(c2)) {
                return toCodePoint(c1, c2);
            }
        }
        return c1;
    }

    /**
     * Determines if the given {@code char} value is a
     * <a href="http://www.unicode.org/glossary/#high_surrogate_code_unit">
     * Unicode high-surrogate code unit</a>
     * (also known as <i>leading-surrogate code unit</i>).
     *
     * <p>Such values do not represent characters by themselves,
     * but are used in the representation of
     * <a href="#supplementary">supplementary characters</a>
     * in the UTF-16 encoding.
     *
     * @param  ch the {@code char} value to be tested.
     * @return {@code true} if the {@code char} value is between
     *         {@link #MIN_HIGH_SURROGATE} and
     *         {@link #MAX_HIGH_SURROGATE} inclusive;
     *         {@code false} otherwise.
     * @see    Character#isLowSurrogate(char)
     * @see    Character.UnicodeBlock#of(int)
     * @since  1.5
     */
    public static bool isHighSurrogate(char ch) {
        // Help VM constant-fold; MAX_HIGH_SURROGATE + 1 == MIN_LOW_SURROGATE
        return ch >= MIN_HIGH_SURROGATE && ch < (MAX_HIGH_SURROGATE + 1);
    }

    /**
     * Determines if the given {@code char} value is a
     * <a href="http://www.unicode.org/glossary/#low_surrogate_code_unit">
     * Unicode low-surrogate code unit</a>
     * (also known as <i>trailing-surrogate code unit</i>).
     *
     * <p>Such values do not represent characters by themselves,
     * but are used in the representation of
     * <a href="#supplementary">supplementary characters</a>
     * in the UTF-16 encoding.
     *
     * @param  ch the {@code char} value to be tested.
     * @return {@code true} if the {@code char} value is between
     *         {@link #MIN_LOW_SURROGATE} and
     *         {@link #MAX_LOW_SURROGATE} inclusive;
     *         {@code false} otherwise.
     * @see    Character#isHighSurrogate(char)
     * @since  1.5
     */
    public static bool isLowSurrogate(char ch) {
        return ch >= MIN_LOW_SURROGATE && ch < (MAX_LOW_SURROGATE + 1);
    }

     /**
     * Determines if the specified character is a letter.
     * <p>
     * A character is considered to be a letter if its general
     * category type, provided by {@code Character.getType(ch)},
     * is any of the following:
     * <ul>
     * <li> {@code UPPERCASE_LETTER}
     * <li> {@code LOWERCASE_LETTER}
     * <li> {@code TITLECASE_LETTER}
     * <li> {@code MODIFIER_LETTER}
     * <li> {@code OTHER_LETTER}
     * </ul>
     *
     * Not all letters have case. Many characters are
     * letters but are neither uppercase nor lowercase nor titlecase.
     *
     * <p><b>Note:</b> This method cannot handle <a
     * href="#supplementary"> supplementary characters</a>. To support
     * all Unicode characters, including supplementary characters, use
     * the {@link #isLetter(int)} method.
     *
     * @param   ch   the character to be tested.
     * @return  {@code true} if the character is a letter;
     *          {@code false} otherwise.
     * @see     Character#isDigit(char)
     * @see     Character#isJavaIdentifierStart(char)
     * @see     Character#isJavaLetter(char)
     * @see     Character#isJavaLetterOrDigit(char)
     * @see     Character#isLetterOrDigit(char)
     * @see     Character#isLowerCase(char)
     * @see     Character#isTitleCase(char)
     * @see     Character#isUnicodeIdentifierStart(char)
     * @see     Character#isUpperCase(char)
     */
    public static bool isLetter(char ch) {
        return isLetter(cast(int)ch);
    }

    /**
     * Determines if the specified character (Unicode code point) is a letter.
     * <p>
     * A character is considered to be a letter if its general
     * category type, provided by {@link Character#getType(int) getType(codePoint)},
     * is any of the following:
     * <ul>
     * <li> {@code UPPERCASE_LETTER}
     * <li> {@code LOWERCASE_LETTER}
     * <li> {@code TITLECASE_LETTER}
     * <li> {@code MODIFIER_LETTER}
     * <li> {@code OTHER_LETTER}
     * </ul>
     *
     * Not all letters have case. Many characters are
     * letters but are neither uppercase nor lowercase nor titlecase.
     *
     * @param   codePoint the character (Unicode code point) to be tested.
     * @return  {@code true} if the character is a letter;
     *          {@code false} otherwise.
     * @see     Character#isDigit(int)
     * @see     Character#isJavaIdentifierStart(int)
     * @see     Character#isLetterOrDigit(int)
     * @see     Character#isLowerCase(int)
     * @see     Character#isTitleCase(int)
     * @see     Character#isUnicodeIdentifierStart(int)
     * @see     Character#isUpperCase(int)
     * @since   1.5
     */
    // public static bool isLetter(int codePoint) {
    //     return ((((1 << Char.UPPERCASE_LETTER) |
    //         (1 << Char.LOWERCASE_LETTER) |
    //         (1 << Char.TITLECASE_LETTER) |
    //         (1 << Char.MODIFIER_LETTER) |
    //         (1 << Char.OTHER_LETTER)) >> getType(codePoint)) & 1)
    //         != 0;
    // }
}

private class CharacterCache {
    private this() {
    }

    __gshared Char[] cache;

    shared static this() {
        cache = new Char[127 + 1];
        for (int i = 0; i < cast(int)cache.length; i++) {
            cache[i] = new Char(cast(char) i);
        }
    }
}
