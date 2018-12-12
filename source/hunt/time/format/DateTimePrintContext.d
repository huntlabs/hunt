
module hunt.time.format.DateTimePrintContext;

import hunt.time.temporal.ChronoField;

import hunt.time.DateTimeException;
import hunt.time.Instant;
import hunt.time.ZoneId;
import hunt.time.ZoneOffset;
import hunt.time.chrono.ChronoLocalDate;
import hunt.time.chrono.Chronology;
import hunt.time.chrono.IsoChronology;
import hunt.time.temporal.ChronoField;
import hunt.time.temporal.TemporalAccessor;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.TemporalQueries;
import hunt.time.temporal.TemporalQuery;
import hunt.time.temporal.UnsupportedTemporalTypeException;
import hunt.time.util.QueryHelper;

import hunt.time.temporal.ValueRange;
import hunt.time.util.Locale;
import hunt.time.format.DateTimeFormatter;
import hunt.time.format.DecimalStyle;
import hunt.lang;
import std.conv;

/**
 * Context object used during date and time printing.
 * !(p)
 * This class provides a single wrapper to items used _in the format.
 *
 * @implSpec
 * This class is a mutable context intended for use from a single thread.
 * Usage of the class is thread-safe within standard printing as the framework creates
 * a new instance of the class for each format and printing is single-threaded.
 *
 * @since 1.8
 */
final class DateTimePrintContext
{

    /**
     * The temporal being output.
     */
    private TemporalAccessor temporal;
    /**
     * The formatter, not null.
     */
    private DateTimeFormatter formatter;
    /**
     * Whether the current formatter is optional.
     */
    private int optional;

    /**
     * Creates a new instance of the context.
     *
     * @param temporal  the temporal object being output, not null
     * @param formatter  the formatter controlling the format, not null
     */
    this(TemporalAccessor temporal, DateTimeFormatter formatter)
    {
        // super();
        this.temporal = adjust(temporal, formatter);
        this.formatter = formatter;
    }

    private static TemporalAccessor adjust(TemporalAccessor temporal, DateTimeFormatter formatter)
    {
        // normal case first (early return is an optimization)
        Chronology overrideChrono = formatter.getChronology();
        ZoneId overrideZone = formatter.getZone();
        if (overrideChrono is null && overrideZone is null)
        {
            return temporal;
        }

        // ensure minimal change (early return is an optimization)
        Chronology temporalChrono = QueryHelper.query!Chronology(temporal,TemporalQueries.chronology());
        ZoneId temporalZone = QueryHelper.query!ZoneId(temporal,TemporalQueries.zoneId());
        if (overrideChrono == temporalChrono)
        {
            overrideChrono = null;
        }
        if ((overrideZone == temporalZone))
        {
            overrideZone = null;
        }
        if (overrideChrono is null && overrideZone is null)
        {
            return temporal;
        }

        // make adjustment
        Chronology effectiveChrono = (overrideChrono !is null ? overrideChrono : temporalChrono);
        if (overrideZone !is null)
        {
            // if have zone and instant, calculation is simple, defaulting chrono if necessary
            if (temporal.isSupported(ChronoField.INSTANT_SECONDS))
            {
                Chronology chrono = effectiveChrono !is null ? effectiveChrono
                    : IsoChronology.INSTANCE;
                return chrono.zonedDateTime(Instant.from(temporal), overrideZone);
            }
            // block changing zone on OffsetTime, and similar problem cases
            if ((cast(ZoneOffset)(overrideZone.normalized)) !is null
                    && temporal.isSupported(ChronoField.OFFSET_SECONDS)
                    && temporal.get(ChronoField.OFFSET_SECONDS) != overrideZone.getRules()
                    .getOffset(Instant.EPOCH).getTotalSeconds())
            {
                throw new DateTimeException("Unable to apply override zone '" ~ typeid(overrideZone)
                        .name ~ "' because the temporal object being formatted has a different offset but"
                        ~ " does not represent an instant: " ~ typeid(temporal).name);
            }
        }
        ZoneId effectiveZone = (overrideZone !is null ? overrideZone : temporalZone);
        ChronoLocalDate effectiveDate;
        if (overrideChrono !is null)
        {
            if (temporal.isSupported(ChronoField.EPOCH_DAY))
            {
                effectiveDate = effectiveChrono.date(temporal);
            }
            else
            {
                // check for date fields other than epoch-day, ignoring case of converting null to ISO
                if (!(overrideChrono == IsoChronology.INSTANCE && temporalChrono is null))
                {
                    foreach (ChronoField f; ChronoField.values())
                    {
                        if (f.isDateBased() && temporal.isSupported(f))
                        {
                            throw new DateTimeException("Unable to apply override chronology '" ~ typeid(overrideChrono)
                                    .name ~ "' because the temporal object being formatted contains date fields but"
                                    ~ " does not represent a whole date: " ~ typeid(temporal).name);
                        }
                    }
                }
                effectiveDate = null;
            }
        }
        else
        {
            effectiveDate = null;
        }

        // combine available data
        // this is a non-standard temporal that is almost a pure delegate
        // this better handles map-like underlying temporal instances
        return new AnonymousClass2(effectiveDate,temporal,effectiveChrono,effectiveZone);
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the temporal object being output.
     *
     * @return the temporal object, not null
     */
    TemporalAccessor getTemporal()
    {
        return temporal;
    }

    /**
     * Gets the locale.
     * !(p)
     * This locale is used to control localization _in the format output except
     * where localization is controlled by the DecimalStyle.
     *
     * @return the locale, not null
     */
    Locale getLocale()
    {
        return formatter.getLocale();
    }

    /**
     * Gets the DecimalStyle.
     * !(p)
     * The DecimalStyle controls the localization of numeric output.
     *
     * @return the DecimalStyle, not null
     */
    DecimalStyle getDecimalStyle()
    {
        return formatter.getDecimalStyle();
    }

    //-----------------------------------------------------------------------
    /**
     * Starts the printing of an optional segment of the input.
     */
    void startOptional()
    {
        this.optional++;
    }

    /**
     * Ends the printing of an optional segment of the input.
     */
    void endOptional()
    {
        this.optional--;
    }

    /**
     * Gets a value using a query.
     *
     * @param query  the query to use, not null
     * @return the result, null if not found and optional is true
     * @throws DateTimeException if the type is not available and the section is not optional
     */
    R getValue(R)(TemporalQuery!(R) query)
    {
        R result = QueryHelper.query!R(temporal , query);
        if (result is null && optional == 0)
        {
            throw new DateTimeException("Unable to extract " ~ typeid(query)
                    .name ~ " from temporal " ~ typeid(temporal).name);
        }
        return result;
    }

    /**
     * Gets the value of the specified field.
     * !(p)
     * This will return the value for the specified field.
     *
     * @param field  the field to find, not null
     * @return the value, null if not found and optional is true
     * @throws DateTimeException if the field is not available and the section is not optional
     */
    Long getValue(TemporalField field)
    {
        if (optional > 0 && !temporal.isSupported(field))
        {
            return null;
        }
        return new Long(temporal.getLong(field));
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a string version of the context for debugging.
     *
     * @return a string representation of the context, not null
     */
    override public string toString()
    {
        return temporal.toString();
    }

}
