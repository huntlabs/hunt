
module hunt.time.format.TextStyle;

import hunt.time.util.Calendar;

/**
 * Enumeration of the style of text formatting and parsing.
 * !(p)
 * Text styles define three sizes for the formatted text - 'full', 'short' and 'narrow'.
 * Each of these three sizes is available _in both 'standard' and 'stand-alone' variations.
 * !(p)
 * The difference between the three sizes is obvious _in most languages.
 * For example, _in English the 'full' month is 'January', the 'short' month is 'Jan'
 * and the 'narrow' month is 'J'. Note that the narrow size is often not unique.
 * For example, 'January', 'June' and 'July' all have the 'narrow' text 'J'.
 * !(p)
 * The difference between the 'standard' and 'stand-alone' forms is trickier to describe
 * as there is no difference _in English. However, _in other languages there is a difference
 * _in the word used when the text is used alone, as opposed to _in a complete date.
 * For example, the word used for a month when used alone _in a date picker is different
 * to the word used for month _in association with a day and year _in a date.
 *
 * @implSpec
 * This is immutable and thread-safe enum.
 *
 * @since 1.8
 */
public class TextStyle {
    // ordered from large to small
    // ordered so that bit 0 of the ordinal indicates stand-alone.

    /**
     * Full text, typically the full description.
     * For example, day-of-week Monday might output "Monday".
     */
    static TextStyle FULL;
    /**
     * Full text for stand-alone use, typically the full description.
     * For example, day-of-week Monday might output "Monday".
     */
    static TextStyle  FULL_STANDALONE ;
    /**
     * Short text, typically an abbreviation.
     * For example, day-of-week Monday might output "Mon".
     */
    static TextStyle  SHORT ;
    /**
     * Short text for stand-alone use, typically an abbreviation.
     * For example, day-of-week Monday might output "Mon".
     */
    static TextStyle  SHORT_STANDALONE;
    /**
     * Narrow text, typically a single letter.
     * For example, day-of-week Monday might output "M".
     */
    static TextStyle  NARROW ;
    /**
     * Narrow text for stand-alone use, typically a single letter.
     * For example, day-of-week Monday might output "M".
     */
    static TextStyle  NARROW_STANDALONE;

    // static this()
    // {
    //     FULL = new TextStyle(0 , Calendar.LONG_FORMAT, 0);
    //     FULL_STANDALONE = new  TextStyle(1 ,Calendar.LONG_STANDALONE, 0);
    //     SHORT = new  TextStyle(2 ,Calendar.SHORT_FORMAT, 1);
    //     SHORT_STANDALONE = new TextStyle(3, Calendar.SHORT_STANDALONE, 1);
    //     NARROW = new TextStyle(4 ,Calendar.NARROW_FORMAT, 1);
    //     NARROW_STANDALONE = new TextStyle(5 ,Calendar.NARROW_STANDALONE, 1);
    //     _values ~= FULL;
    //     _values ~= FULL_STANDALONE;
    //     _values ~= SHORT;
    //     _values ~= SHORT_STANDALONE;
    //     _values ~= NARROW;
    //     _values ~= NARROW_STANDALONE;
    // }

    private  int _ordinal;
    private  int calendarStyle;
    private  int _zoneNameStyleIndex;
    static  TextStyle[] _values;

    this(int ord,int calendarStyle, int _zoneNameStyleIndex) {
        this._ordinal = ord;
        this.calendarStyle = calendarStyle;
        this._zoneNameStyleIndex = _zoneNameStyleIndex;
    }

    public int ordinal()
    {
        return _ordinal;
    }

    static public TextStyle[] values()
    {
        return TextStyle._values;
    }
    /**
     * Returns true if the Style is a stand-alone style.
     * @return true if the style is a stand-alone style.
     */
    public bool isStandalone() {
        return (ordinal() & 1) == 1;
    }

    /**
     * Returns the stand-alone style with the same size.
     * @return the stand-alone style with the same size
     */
    public TextStyle asStandalone() {
        return TextStyle.values()[ordinal()  | 1];
    }

    /**
     * Returns the normal style with the same size.
     *
     * @return the normal style with the same size
     */
    public TextStyle asNormal() {
        return TextStyle.values()[ordinal() & ~1];
    }

    /**
     * Returns the {@code Calendar} style corresponding to this {@code TextStyle}.
     *
     * @return the corresponding {@code Calendar} style
     */
    int toCalendarStyle() {
        return calendarStyle;
    }

    /**
     * Returns the relative index value to an element of the {@link
     * java.text.DateFormatSymbols#getZoneStrings() DateFormatSymbols.getZoneStrings()}
     * value, 0 for long names and 1 for short names (abbreviations). Note that these values
     * do !(em)not</em> correspond to the {@link java.util.TimeZone#LONG} and {@link
     * java.util.TimeZone#SHORT} values.
     *
     * @return the relative index value to time zone names array
     */
    int zoneNameStyleIndex() {
        return _zoneNameStyleIndex;
    }
}
