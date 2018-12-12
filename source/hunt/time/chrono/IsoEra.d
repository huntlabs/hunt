
module hunt.time.chrono.IsoEra;

import hunt.time.DateTimeException;
import hunt.time.chrono.Era;
import hunt.time.chrono.IsoEra;
import std.conv;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.ChronoField;
import hunt.time.temporal.UnsupportedTemporalTypeException;
import hunt.time.temporal.ValueRange;
import hunt.time.temporal.Temporal;
import hunt.time.format.TextStyle;
import hunt.time.format.DateTimeFormatterBuilder;
import hunt.time.util.Locale;
/**
 * An era _in the ISO calendar system.
 * !(p)
 * The ISO-8601 standard does not define eras.
 * A definition has therefore been created with two eras - 'Current era' (CE) for
 * years on or after 0001-01-01 (ISO), and 'Before current era' (BCE) for years before that.
 *
 * <table class="striped" style="text-align:left">
 * <caption style="display:none">ISO years and eras</caption>
 * !(thead)
 * !(tr)
 * <th scope="col">year-of-era</th>
 * <th scope="col">era</th>
 * <th scope="col">proleptic-year</th>
 * </tr>
 * </thead>
 * !(tbody)
 * !(tr)
 * !(td)2</td>!(td)CE</td><th scope="row">2</th>
 * </tr>
 * !(tr)
 * !(td)1</td>!(td)CE</td><th scope="row">1</th>
 * </tr>
 * !(tr)
 * !(td)1</td>!(td)BCE</td><th scope="row">0</th>
 * </tr>
 * !(tr)
 * !(td)2</td>!(td)BCE</td><th scope="row">-1</th>
 * </tr>
 * </tbody>
 * </table>
 * !(p)
 * !(b)Do not use {@code ordinal()} to obtain the numeric representation of {@code IsoEra}.
 * Use {@code getValue()} instead.</b>
 *
 * @implSpec
 * This is an immutable and thread-safe enum.
 *
 * @since 1.8
 */
public class IsoEra : Era {

    /**
     * The singleton instance for the era before the current one, 'Before Current Era',
     * which has the numeric value 0.
     */
    static IsoEra BCE;
    /**
     * The singleton instance for the current era, 'Current Era',
     * which has the numeric value 1.
     */
    static IsoEra CE;

    // static this()
    // {
    //     BCE = new  IsoEra(0);
    //     CE = new IsoEra(1);
    // }

    private int _ordinal;

    this(int ordinal)
    {
        _ordinal = ordinal;
    }
    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code IsoEra} from an {@code int} value.
     * !(p)
     * {@code IsoEra} is an enum representing the ISO eras of BCE/CE.
     * This factory allows the enum to be obtained from the {@code int} value.
     *
     * @param isoEra  the BCE/CE value to represent, from 0 (BCE) to 1 (CE)
     * @return the era singleton, not null
     * @throws DateTimeException if the value is invalid
     */
    public static IsoEra of(int isoEra) {
        switch (isoEra) {
            case 0:
                return BCE;
            case 1:
                return CE;
            default:
                throw new DateTimeException("Invalid era: " ~ isoEra.to!string);
        }
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the numeric era {@code int} value.
     * !(p)
     * The era BCE has the value 0, while the era CE has the value 1.
     *
     * @return the era value, from 0 (BCE) to 1 (CE)
     */
    override
    public int getValue() {
        return ordinal();
    }

    int ordinal()
    {
        return _ordinal;
    }

    override
     bool isSupported(TemporalField field) {
        if (cast(ChronoField)(field) !is null) {
            return field == ChronoField.ERA;
        }
        return field !is null && field.isSupportedBy(this);
    }
	
    override  // override for Javadoc
     ValueRange range(TemporalField field) {
        return /* TemporalAccessor. */super_range(field);
    }
	
     ValueRange super_range(TemporalField field)
    {
        if (cast(ChronoField)(field) !is null)
        {
            if (isSupported(field))
            {
                return field.range();
            }
            throw new UnsupportedTemporalTypeException("Unsupported field: " ~ field.toString);
        }
        assert(field, "field");
        return field.rangeRefinedBy(this);
    }

     int super_get(TemporalField field)
    {
        ValueRange range = range(field);
        if (range.isIntValue() == false)
        {
            throw new UnsupportedTemporalTypeException(
                    "Invalid field " ~ field.toString ~ " for get() method, use getLong() instead");
        }
        long value = getLong(field);
        if (range.isValidValue(value) == false)
        {
            throw new DateTimeException(
                    "Invalid value for " ~ field.toString ~ " (valid values "
                    ~ range.toString ~ "): " ~ value.to!string);
        }
        return cast(int) value;
    }

    override  // override for Javadoc and performance
     int get(TemporalField field) {
        if (field == ChronoField.ERA) {
            return getValue();
        }
        return /* TemporalAccessor. */super_get(field);
    }
	
	override
     long getLong(TemporalField field) {
        if (field == ChronoField.ERA) {
            return getValue();
        } else if (cast(ChronoField)(field) !is null) {
            throw new UnsupportedTemporalTypeException("Unsupported field: " ~ field.toString);
        }
        return field.getFrom(this);
    }
	
	override
     Temporal adjustInto(Temporal temporal) {
        return temporal._with(ChronoField.ERA, getValue());
    }
	
    override
	 string getDisplayName(TextStyle style, Locale locale) {
        return new DateTimeFormatterBuilder().appendText(ChronoField.ERA, style).toFormatter(locale).format(this);
    }

    override string toString()
    {
        return super.toString();
    }
}
