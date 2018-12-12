
module hunt.time.format.FormatStyle;

/**
 * Enumeration of the style of a localized date, time or date-time formatter.
 * !(p)
 * These styles are used when obtaining a date-time style from configuration.
 * See {@link DateTimeFormatter} and {@link DateTimeFormatterBuilder} for usage.
 *
 * @implSpec
 * This is an immutable and thread-safe enum.
 *
 * @since 1.8
 */
public class FormatStyle {
    // ordered from large to small
    /**
     * Full text style, with the most detail.
     * For example, the format might be 'Tuesday, April 12, 1952 AD' or '3:30:42pm PST'.
     */
    static FormatStyle FULL;
    /**
     * Long text style, with lots of detail.
     * For example, the format might be 'January 12, 1952'.
     */
    static FormatStyle LONG;
    /**
     * Medium text style, with some detail.
     * For example, the format might be 'Jan 12, 1952'.
     */
    static FormatStyle MEDIUM;
    /**
     * Short text style, typically numeric.
     * For example, the format might be '12.13.52' or '3:30pm'.
     */
    static FormatStyle SHORT;

    // static this()
    // {
    //     FULL = new FormatStyle(0,"FULL");
    //     LONG = new FormatStyle(1,"LONG");
    //     MEDIUM = new FormatStyle(2,"MEDIUM");
    //     SHORT = new FormatStyle(3,"SHORT");
    // }

    private int _ordinal;
    private string _name;

    this(int ord,string name)
    {
        _ordinal = ord;
        _name = name;
    }

    public int ordinal()
    {
        return _ordinal;
    }

    public string name()
    {
        return _name;
    }

    bool opEquals(const FormatStyle h) nothrow {
        return _name == h._name ;
    } 

    bool opEquals(ref const FormatStyle h) nothrow {
        return _name == h._name ;
    }

    override 
    bool opEquals(Object obj)  {
        if (this is obj) {
            return true;
        }
        if (cast(FormatStyle)(obj) !is null) {
            FormatStyle other = cast(FormatStyle) obj;
            return _name == other._name;
        }
        return false;
    }
}
