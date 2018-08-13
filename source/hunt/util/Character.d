module hunt.util.Character;

class Character
{
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
    enum byte DECIMAL_DIGIT_NUMBER        = 9;

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
     * @since 1.4
     */
    enum byte DIRECTIONALITY_UNDEFINED = -1;

    /**
     * Strong bidirectional character type "L" in the Unicode specification.
     * @since 1.4
     */
    enum byte DIRECTIONALITY_LEFT_TO_RIGHT = 0;

    /**
     * Strong bidirectional character type "R" in the Unicode specification.
     * @since 1.4
     */
    enum byte DIRECTIONALITY_RIGHT_TO_LEFT = 1;

    /**
    * Strong bidirectional character type "AL" in the Unicode specification.
     * @since 1.4
     */
    enum byte DIRECTIONALITY_RIGHT_TO_LEFT_ARABIC = 2;

    /**
     * Weak bidirectional character type "EN" in the Unicode specification.
     * @since 1.4
     */
    enum byte DIRECTIONALITY_EUROPEAN_NUMBER = 3;

    /**
     * Weak bidirectional character type "ES" in the Unicode specification.
     * @since 1.4
     */
    enum byte DIRECTIONALITY_EUROPEAN_NUMBER_SEPARATOR = 4;

    /**
     * Weak bidirectional character type "ET" in the Unicode specification.
     * @since 1.4
     */
    enum byte DIRECTIONALITY_EUROPEAN_NUMBER_TERMINATOR = 5;

    /**
     * Weak bidirectional character type "AN" in the Unicode specification.
     * @since 1.4
     */
    enum byte DIRECTIONALITY_ARABIC_NUMBER = 6;

    /**
     * Weak bidirectional character type "CS" in the Unicode specification.
     * @since 1.4
     */
    enum byte DIRECTIONALITY_COMMON_NUMBER_SEPARATOR = 7;

    /**
     * Weak bidirectional character type "NSM" in the Unicode specification.
     * @since 1.4
     */
    enum byte DIRECTIONALITY_NONSPACING_MARK = 8;

    /**
     * Weak bidirectional character type "BN" in the Unicode specification.
     * @since 1.4
     */
    enum byte DIRECTIONALITY_BOUNDARY_NEUTRAL = 9;

    /**
     * Neutral bidirectional character type "B" in the Unicode specification.
     * @since 1.4
     */
    enum byte DIRECTIONALITY_PARAGRAPH_SEPARATOR = 10;

    /**
     * Neutral bidirectional character type "S" in the Unicode specification.
     * @since 1.4
     */
    enum byte DIRECTIONALITY_SEGMENT_SEPARATOR = 11;

    /**
     * Neutral bidirectional character type "WS" in the Unicode specification.
     * @since 1.4
     */
    enum byte DIRECTIONALITY_WHITESPACE = 12;

    /**
     * Neutral bidirectional character type "ON" in the Unicode specification.
     * @since 1.4
     */
    enum byte DIRECTIONALITY_OTHER_NEUTRALS = 13;

    /**
     * Strong bidirectional character type "LRE" in the Unicode specification.
     * @since 1.4
     */
    enum byte DIRECTIONALITY_LEFT_TO_RIGHT_EMBEDDING = 14;

    /**
     * Strong bidirectional character type "LRO" in the Unicode specification.
     * @since 1.4
     */
    enum byte DIRECTIONALITY_LEFT_TO_RIGHT_OVERRIDE = 15;

    /**
     * Strong bidirectional character type "RLE" in the Unicode specification.
     * @since 1.4
     */
    enum byte DIRECTIONALITY_RIGHT_TO_LEFT_EMBEDDING = 16;

    /**
     * Strong bidirectional character type "RLO" in the Unicode specification.
     * @since 1.4
     */
    enum byte DIRECTIONALITY_RIGHT_TO_LEFT_OVERRIDE = 17;

    /**
     * Weak bidirectional character type "PDF" in the Unicode specification.
     * @since 1.4
     */
    enum byte DIRECTIONALITY_POP_DIRECTIONAL_FORMAT = 18;

    /**
     * The minimum value of a
     * <a href="http://www.unicode.org/glossary/#high_surrogate_code_unit">
     * Unicode high-surrogate code unit</a>
     * in the UTF-16 encoding, constant {@code '\u005CuD800'}.
     * A high-surrogate is also known as a <i>leading-surrogate</i>.
     *
     * @since 1.5
     */
    // enum wchar MIN_HIGH_SURROGATE = '\uD800';

    /**
     * The maximum value of a
     * <a href="http://www.unicode.org/glossary/#high_surrogate_code_unit">
     * Unicode high-surrogate code unit</a>
     * in the UTF-16 encoding, constant {@code '\u005CuDBFF'}.
     * A high-surrogate is also known as a <i>leading-surrogate</i>.
     *
     * @since 1.5
     */
    // enum wchar MAX_HIGH_SURROGATE = '\uDBFF';

    /**
     * The minimum value of a
     * <a href="http://www.unicode.org/glossary/#low_surrogate_code_unit">
     * Unicode low-surrogate code unit</a>
     * in the UTF-16 encoding, constant {@code '\u005CuDC00'}.
     * A low-surrogate is also known as a <i>trailing-surrogate</i>.
     *
     * @since 1.5
     */
    // enum wchar MIN_LOW_SURROGATE  = '\uDC00';

    /**
     * The maximum value of a
     * <a href="http://www.unicode.org/glossary/#low_surrogate_code_unit">
     * Unicode low-surrogate code unit</a>
     * in the UTF-16 encoding, constant {@code '\u005CuDFFF'}.
     * A low-surrogate is also known as a <i>trailing-surrogate</i>.
     *
     * @since 1.5
     */
    // enum wchar MAX_LOW_SURROGATE  = '\uDFFF';

    /**
     * The minimum value of a Unicode surrogate code unit in the
     * UTF-16 encoding, constant {@code '\u005CuD800'}.
     *
     * @since 1.5
     */
    // enum wchar MIN_SURROGATE = MIN_HIGH_SURROGATE;

    /**
     * The maximum value of a Unicode surrogate code unit in the
     * UTF-16 encoding, constant {@code '\u005CuDFFF'}.
     *
     * @since 1.5
     */
    // enum wchar MAX_SURROGATE = MAX_LOW_SURROGATE;

    /**
     * The minimum value of a
     * <a href="http://www.unicode.org/glossary/#supplementary_code_point">
     * Unicode supplementary code point</a>, constant {@code U+10000}.
     *
     * @since 1.5
     */
    enum int MIN_SUPPLEMENTARY_CODE_POINT = 0x010000;

    /**
     * The minimum value of a
     * <a href="http://www.unicode.org/glossary/#code_point">
     * Unicode code point</a>, constant {@code U+0000}.
     *
     * @since 1.5
     */
    enum int MIN_CODE_POINT = 0x000000;

    /**
     * The maximum value of a
     * <a href="http://www.unicode.org/glossary/#code_point">
     * Unicode code point</a>, constant {@code U+10FFFF}.
     *
     * @since 1.5
     */
    enum int MAX_CODE_POINT = 0X10FFFF;


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
    public static int charCount(int codePoint) {
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
    // public static int toCodePoint(char high, char low) {
    //     // Optimized form of:
    //     // return ((high - MIN_HIGH_SURROGATE) << 10)
    //     //         + (low - MIN_LOW_SURROGATE)
    //     //         + MIN_SUPPLEMENTARY_CODE_POINT;
    //     return ((high << 10) + low) + (MIN_SUPPLEMENTARY_CODE_POINT
    //                                    - (MIN_HIGH_SURROGATE << 10)
    //                                    - MIN_LOW_SURROGATE);
    // }

}