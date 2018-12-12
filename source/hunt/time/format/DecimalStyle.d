
module hunt.time.format.DecimalStyle;

// import hunt.text.DecimalFormatSymbols;
import hunt.container.Collections;
import hunt.container.HashSet;
import hunt.time.util.Locale;

import hunt.container.Set;
import hunt.container.HashMap;
import hunt.container.Map;
import hunt.lang.exception;
// import hunt.util.concurrent.ConcurrentMap;

/**
 * Localized decimal style used _in date and time formatting.
 * !(p)
 * A significant part of dealing with dates and times is the localization.
 * This class acts as a central point for accessing the information.
 *
 * @implSpec
 * This class is immutable and thread-safe.
 *
 * @since 1.8
 */
public final class DecimalStyle {

    /**
     * The standard set of non-localized decimal style symbols.
     * !(p)
     * This uses standard ASCII characters for zero, positive, negative and a dot for the decimal point.
     */
    public __gshared DecimalStyle STANDARD;
    /**
     * The cache of DecimalStyle instances.
     */
    __gshared Map!(Locale, DecimalStyle) CACHE;

    /**
     * The zero digit.
     */
    private  char zeroDigit;
    /**
     * The positive sign.
     */
    private  char positiveSign;
    /**
     * The negative sign.
     */
    private  char negativeSign;
    /**
     * The decimal separator.
     */
    private  char decimalSeparator;

    // shared static this()
    // {
    //     STANDARD = new DecimalStyle('0', '+', '-', '.');
    //     CACHE = new HashMap!(Locale, DecimalStyle)(16, 0.75f/* , 2 */);
    // }
    //-----------------------------------------------------------------------
    /**
     * Lists all the locales that are supported.
     * !(p)
     * The locale 'en_US' will always be present.
     *
     * @return a Set of Locales for which localization is supported
     */
     ///@gxc
    // public static Set!(Locale) getAvailableLocales() {
    //     Locale[] l = DecimalFormatSymbols.getAvailableLocales();
    //     Set!(Locale) locales = new HashSet!(Locale)(l.length);
    //     foreach(d ; l) {
    //         locales.add(d);
    //     }
    //     // Collections.addAll(locales, l);
    //     return locales;
    // }

    /**
     * Obtains the DecimalStyle for the default
     * {@link java.util.Locale.Category#FORMAT FORMAT} locale.
     * !(p)
     * This method provides access to locale sensitive decimal style symbols.
     * !(p)
     * This is equivalent to calling
     * {@link #of(Locale)
     *     of(Locale.getDefault(Locale.Category.FORMAT))}.
     *
     * @see java.util.Locale.Category#FORMAT
     * @return the decimal style, not null
     */
     ///@gxc
    // public static DecimalStyle ofDefaultLocale() {
    //     return of(Locale.getDefault(Locale.Category.FORMAT));
    // }

    /**
     * Obtains the DecimalStyle for the specified locale.
     * !(p)
     * This method provides access to locale sensitive decimal style symbols.
     * If the locale contains "nu" (Numbering System) and/or "rg"
     * (Region Override) <a href="../../util/Locale.html#def_locale_extension">
     * Unicode extensions</a>, returned instance will reflect the values specified with
     * those extensions. If both "nu" and "rg" are specified, the value from
     * the "nu" extension supersedes the implicit one from the "rg" extension.
     *
     * @param locale  the locale, not null
     * @return the decimal style, not null
     */
    public static DecimalStyle of(Locale locale) {
        assert(locale, "locale");
        DecimalStyle info = CACHE.get(locale);
        if (info is null) {
            info = create(locale);
            CACHE.putIfAbsent(locale, info);
            info = CACHE.get(locale);
        }
        return info;
    }

    private static DecimalStyle create(Locale locale) {
        // DecimalFormatSymbols oldSymbols = DecimalFormatSymbols.getInstance(locale);
        // char zeroDigit = oldSymbols.getZeroDigit();
        // char positiveSign = '+';
        // char negativeSign = oldSymbols.getMinusSign();
        // char decimalSeparator = oldSymbols.getDecimalSeparator();
        // if (zeroDigit == '0' && negativeSign == '-' && decimalSeparator == '.') {
        //     return STANDARD;
        // }
        // return new DecimalStyle(zeroDigit, positiveSign, negativeSign, decimalSeparator);
        implementationMissing();
        return null;
    }

    //-----------------------------------------------------------------------
    /**
     * Restricted constructor.
     *
     * @param zeroChar  the character to use for the digit of zero
     * @param positiveSignChar  the character to use for the positive sign
     * @param negativeSignChar  the character to use for the negative sign
     * @param decimalPointChar  the character to use for the decimal point
     */
     this(char zeroChar, char positiveSignChar, char negativeSignChar, char decimalPointChar) {
        this.zeroDigit = zeroChar;
        this.positiveSign = positiveSignChar;
        this.negativeSign = negativeSignChar;
        this.decimalSeparator = decimalPointChar;
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the character that represents zero.
     * !(p)
     * The character used to represent digits may vary by culture.
     * This method specifies the zero character to use, which implies the characters for one to nine.
     *
     * @return the character for zero
     */
    public char getZeroDigit() {
        return zeroDigit;
    }

    /**
     * Returns a copy of the info with a new character that represents zero.
     * !(p)
     * The character used to represent digits may vary by culture.
     * This method specifies the zero character to use, which implies the characters for one to nine.
     *
     * @param zeroDigit  the character for zero
     * @return  a copy with a new character that represents zero, not null
     */
    public DecimalStyle withZeroDigit(char zeroDigit) {
        if (zeroDigit == this.zeroDigit) {
            return this;
        }
        return new DecimalStyle(zeroDigit, positiveSign, negativeSign, decimalSeparator);
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the character that represents the positive sign.
     * !(p)
     * The character used to represent a positive number may vary by culture.
     * This method specifies the character to use.
     *
     * @return the character for the positive sign
     */
    public char getPositiveSign() {
        return positiveSign;
    }

    /**
     * Returns a copy of the info with a new character that represents the positive sign.
     * !(p)
     * The character used to represent a positive number may vary by culture.
     * This method specifies the character to use.
     *
     * @param positiveSign  the character for the positive sign
     * @return  a copy with a new character that represents the positive sign, not null
     */
    public DecimalStyle withPositiveSign(char positiveSign) {
        if (positiveSign == this.positiveSign) {
            return this;
        }
        return new DecimalStyle(zeroDigit, positiveSign, negativeSign, decimalSeparator);
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the character that represents the negative sign.
     * !(p)
     * The character used to represent a negative number may vary by culture.
     * This method specifies the character to use.
     *
     * @return the character for the negative sign
     */
    public char getNegativeSign() {
        return negativeSign;
    }

    /**
     * Returns a copy of the info with a new character that represents the negative sign.
     * !(p)
     * The character used to represent a negative number may vary by culture.
     * This method specifies the character to use.
     *
     * @param negativeSign  the character for the negative sign
     * @return  a copy with a new character that represents the negative sign, not null
     */
    public DecimalStyle withNegativeSign(char negativeSign) {
        if (negativeSign == this.negativeSign) {
            return this;
        }
        return new DecimalStyle(zeroDigit, positiveSign, negativeSign, decimalSeparator);
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the character that represents the decimal point.
     * !(p)
     * The character used to represent a decimal point may vary by culture.
     * This method specifies the character to use.
     *
     * @return the character for the decimal point
     */
    public char getDecimalSeparator() {
        return decimalSeparator;
    }

    /**
     * Returns a copy of the info with a new character that represents the decimal point.
     * !(p)
     * The character used to represent a decimal point may vary by culture.
     * This method specifies the character to use.
     *
     * @param decimalSeparator  the character for the decimal point
     * @return  a copy with a new character that represents the decimal point, not null
     */
    public DecimalStyle withDecimalSeparator(char decimalSeparator) {
        if (decimalSeparator == this.decimalSeparator) {
            return this;
        }
        return new DecimalStyle(zeroDigit, positiveSign, negativeSign, decimalSeparator);
    }

    //-----------------------------------------------------------------------
    /**
     * Checks whether the character is a digit, based on the currently set zero character.
     *
     * @param ch  the character to check
     * @return the value, 0 to 9, of the character, or -1 if not a digit
     */
    int convertToDigit(char ch) {
        int val = ch - zeroDigit;
        return (val >= 0 && val <= 9) ? val : -1;
    }

    /**
     * Converts the input numeric text to the internationalized form using the zero character.
     *
     * @param numericText  the text, consisting of digits 0 to 9, to convert, not null
     * @return the internationalized text, not null
     */
    string convertNumberToI18N(string numericText) {
        if (zeroDigit == '0') {
            return numericText;
        }
        int diff = zeroDigit - '0';
        char[] array = cast(char[])numericText/* .toCharArray() */;
        for (int i = 0; i < array.length; i++) {
            array[i] = cast(char) (array[i] + diff);
        }
        return cast(string)(array);
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if this DecimalStyle is equal to another DecimalStyle.
     *
     * @param obj  the object to check, null returns false
     * @return true if this is equal to the other date
     */
    override
    public bool opEquals(Object obj) {
        if (this is obj) {
            return true;
        }
        if (cast(DecimalStyle)(obj) !is null) {
            DecimalStyle other = cast(DecimalStyle) obj;
            return (zeroDigit == other.zeroDigit && positiveSign == other.positiveSign &&
                    negativeSign == other.negativeSign && decimalSeparator == other.decimalSeparator);
        }
        return false;
    }

    /**
     * A hash code for this DecimalStyle.
     *
     * @return a suitable hash code
     */
    override
    public size_t toHash() @trusted nothrow {
        return zeroDigit + positiveSign + negativeSign + decimalSeparator;
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a string describing this DecimalStyle.
     *
     * @return a string description, not null
     */
    override
    public string toString() {
        return "DecimalStyle[" ~ zeroDigit ~ positiveSign ~ negativeSign ~ decimalSeparator ~ "]";
    }

}
