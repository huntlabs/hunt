
module hunt.time.format.SignStyle;

/**
 * Enumeration of ways to handle the positive/negative sign.
 * !(p)
 * The formatting engine allows the positive and negative signs of numbers
 * to be controlled using this enum.
 * See {@link DateTimeFormatterBuilder} for usage.
 *
 * @implSpec
 * This is an immutable and thread-safe enum.
 *
 * @since 1.8
 */
public struct SignStyle {

    /**
     * Style to output the sign only if the value is negative.
     * !(p)
     * In strict parsing, the negative sign will be accepted and the positive sign rejected.
     * In lenient parsing, any sign will be accepted.
     */
    static SignStyle NORMAL = SignStyle(0,"NORMAL");
    /**
     * Style to always output the sign, where zero will output '+'.
     * !(p)
     * In strict parsing, the absence of a sign will be rejected.
     * In lenient parsing, any sign will be accepted, with the absence
     * of a sign treated as a positive number.
     */
    static SignStyle ALWAYS= SignStyle(1,"ALWAYS");
    /**
     * Style to never output sign, only outputting the absolute value.
     * !(p)
     * In strict parsing, any sign will be rejected.
     * In lenient parsing, any sign will be accepted unless the width is fixed.
     */
    static SignStyle NEVER= SignStyle(2,"NEVER");
    /**
     * Style to block negative values, throwing an exception on printing.
     * !(p)
     * In strict parsing, any sign will be rejected.
     * In lenient parsing, any sign will be accepted unless the width is fixed.
     */
    static SignStyle NOT_NEGATIVE= SignStyle(3,"NOT_NEGATIVE");
    /**
     * Style to always output the sign if the value exceeds the pad width.
     * A negative value will always output the '-' sign.
     * !(p)
     * In strict parsing, the sign will be rejected unless the pad width is exceeded.
     * In lenient parsing, any sign will be accepted, with the absence
     * of a sign treated as a positive number.
     */
    static SignStyle EXCEEDS_PAD= SignStyle(4,"EXCEEDS_PAD");

    private string _name;
    private int _ordinal;
    public int ordinal()
    {
        return _ordinal;
    }
    public string name()
    {
        return _name;
    }
    this(int ordinal ,string name)
    {
        _ordinal = ordinal;
        _name = name;
    }
    /**
     * Parse helper.
     *
     * @param positive  true if positive sign parsed, false for negative sign
     * @param strict  true if strict, false if lenient
     * @param fixedWidth  true if fixed width, false if not
     * @return
     */
    bool parse(bool positive, bool strict, bool fixedWidth) {
        switch (ordinal()) {
            case 0: // NORMAL
                // valid if negative or (positive and lenient)
                return !positive || !strict;
            case 1: // ALWAYS
            case 4: // EXCEEDS_PAD
                return true;
            default:
                // valid if lenient and not fixed width
                return !strict && !fixedWidth;
        }
    }

}
