module hunt.time.temporal.ChronoUnit;

import hunt.time.Duration;
import hunt.time.temporal.TemporalUnit;
import hunt.time.temporal.Temporal;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.ValueRange;
import hunt.lang;
import hunt.util.Comparator;

/**
 * A standard set of date periods units.
 * !(p)
 * This set of units provide unit-based access to manipulate a date, time or date-time.
 * The standard set of units can be extended by implementing {@link TemporalUnit}.
 * !(p)
 * These units are intended to be applicable _in multiple calendar systems.
 * For example, most non-ISO calendar systems define units of years, months and days,
 * just with slightly different rules.
 * The documentation of each unit explains how it operates.
 *
 * @implSpec
 * This is a final, immutable and thread-safe enum.
 *
 * @since 1.8
 */
public class ChronoUnit : TemporalUnit
{

    /**
     * Unit that represents the concept of a nanosecond, the smallest supported unit of time.
     * For the ISO calendar system, it is equal to the 1,000,000,000th part of the second unit.
     */
    static ChronoUnit NANOS;
    /**
     * Unit that represents the concept of a microsecond.
     * For the ISO calendar system, it is equal to the 1,000,000th part of the second unit.
     */
    static ChronoUnit MICROS;
    /**
     * Unit that represents the concept of a millisecond.
     * For the ISO calendar system, it is equal to the 1000th part of the second unit.
     */
    static ChronoUnit MILLIS;
    /**
     * Unit that represents the concept of a second.
     * For the ISO calendar system, it is equal to the second _in the SI system
     * of units, except around a leap-second.
     */
    static ChronoUnit SECONDS;
    /**
     * Unit that represents the concept of a minute.
     * For the ISO calendar system, it is equal to 60 seconds.
     */
    static ChronoUnit MINUTES;
    /**
     * Unit that represents the concept of an hour.
     * For the ISO calendar system, it is equal to 60 minutes.
     */
    static ChronoUnit HOURS;
    /**
     * Unit that represents the concept of half a day, as used _in AM/PM.
     * For the ISO calendar system, it is equal to 12 hours.
     */
    static ChronoUnit HALF_DAYS;
    /**
     * Unit that represents the concept of a day.
     * For the ISO calendar system, it is the standard day from midnight to midnight.
     * The estimated duration of a day is {@code 24 Hours}.
     * !(p)
     * When used with other calendar systems it must correspond to the day defined by
     * the rising and setting of the Sun on Earth. It is not required that days begin
     * at midnight - when converting between calendar systems, the date should be
     * equivalent at midday.
     */
    static ChronoUnit DAYS;
    /**
     * Unit that represents the concept of a week.
     * For the ISO calendar system, it is equal to 7 days.
     * !(p)
     * When used with other calendar systems it must correspond to an integral number of days.
     */
    static ChronoUnit WEEKS;
    /**
     * Unit that represents the concept of a month.
     * For the ISO calendar system, the length of the month varies by month-of-year.
     * The estimated duration of a month is one twelfth of {@code 365.2425 Days}.
     * !(p)
     * When used with other calendar systems it must correspond to an integral number of days.
     */
    static ChronoUnit MONTHS;
    /**
     * Unit that represents the concept of a year.
     * For the ISO calendar system, it is equal to 12 months.
     * The estimated duration of a year is {@code 365.2425 Days}.
     * !(p)
     * When used with other calendar systems it must correspond to an integral number of days
     * or months roughly equal to a year defined by the passage of the Earth around the Sun.
     */
    static ChronoUnit YEARS;
    /**
     * Unit that represents the concept of a decade.
     * For the ISO calendar system, it is equal to 10 years.
     * !(p)
     * When used with other calendar systems it must correspond to an integral number of days
     * and is normally an integral number of years.
     */
    static ChronoUnit DECADES;
    /**
     * Unit that represents the concept of a century.
     * For the ISO calendar system, it is equal to 100 years.
     * !(p)
     * When used with other calendar systems it must correspond to an integral number of days
     * and is normally an integral number of years.
     */
    static ChronoUnit CENTURIES;
    /**
     * Unit that represents the concept of a millennium.
     * For the ISO calendar system, it is equal to 1000 years.
     * !(p)
     * When used with other calendar systems it must correspond to an integral number of days
     * and is normally an integral number of years.
     */
    static ChronoUnit MILLENNIA;
    /**
     * Unit that represents the concept of an era.
     * The ISO calendar system doesn't have eras thus it is impossible to add
     * an era to a date or date-time.
     * The estimated duration of the era is artificially defined as {@code 1,000,000,000 Years}.
     * !(p)
     * When used with other calendar systems there are no restrictions on the unit.
     */
    static ChronoUnit ERAS;
    /**
     * Artificial unit that represents the concept of forever.
     * This is primarily used with {@link TemporalField} to represent unbounded fields
     * such as the year or era.
     * The estimated duration of this unit is artificially defined as the largest duration
     * supported by {@link Duration}.
     */
    static ChronoUnit FOREVER;

    // static this()
    // {
    //     NANOS = new ChronoUnit("Nanos", Duration.ofNanos(1));

    //     MICROS = new ChronoUnit("Micros", Duration.ofNanos(1000));

    //     MILLIS = new ChronoUnit("Millis", Duration.ofNanos(1000_000));

    //     SECONDS = new ChronoUnit("Seconds", Duration.ofSeconds(1));

    //     MINUTES = new ChronoUnit("Minutes", Duration.ofSeconds(60));

    //     HOURS = new ChronoUnit("Hours", Duration.ofSeconds(3600));

    //     HALF_DAYS = new ChronoUnit("HalfDays", Duration.ofSeconds(43200));

    //     DAYS = new ChronoUnit("Days", Duration.ofSeconds(86400));

    //     WEEKS = new ChronoUnit("Weeks", Duration.ofSeconds(7 * 86400L));

    //     MONTHS = new ChronoUnit("Months", Duration.ofSeconds(31556952L / 12));

    //     YEARS = new ChronoUnit("Years", Duration.ofSeconds(31556952L));

    //     DECADES = new ChronoUnit("Decades", Duration.ofSeconds(31556952L * 10L));

    //     CENTURIES = new ChronoUnit("Centuries", Duration.ofSeconds(31556952L * 100L));

    //     MILLENNIA = new ChronoUnit("Millennia", Duration.ofSeconds(31556952L * 1000L));

    //     ERAS = new ChronoUnit("Eras", Duration.ofSeconds(31556952L * 1000_000_000L));

    //     FOREVER = new ChronoUnit("Forever", Duration.ofSeconds(Long.MAX_VALUE, 999_999_999));
    // }

    private string name;
    private Duration duration;

    this(string name, Duration estimatedDuration)
    {
        this.name = name;
        this.duration = estimatedDuration;
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the estimated duration of this unit _in the ISO calendar system.
     * !(p)
     * All of the units _in this class have an estimated duration.
     * Days vary due to daylight saving time, while months have different lengths.
     *
     * @return the estimated duration of this unit, not null
     */
    override public Duration getDuration()
    {
        return duration;
    }

    /**
     * Checks if the duration of the unit is an estimate.
     * !(p)
     * All time units _in this class are considered to be accurate, while all date
     * units _in this class are considered to be estimated.
     * !(p)
     * This definition ignores leap seconds, but considers that Days vary due to
     * daylight saving time and months have different lengths.
     *
     * @return true if the duration is estimated, false if accurate
     */
    override public bool isDurationEstimated()
    {
        return this.compareTo(DAYS) >= 0;
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if this unit is a date unit.
     * !(p)
     * All units from days to eras inclusive are date-based.
     * Time-based units and {@code FOREVER} return false.
     *
     * @return true if a date unit, false if a time unit
     */
    override public bool isDateBased()
    {
        return this.compareTo(DAYS) >= 0 && this != FOREVER;
    }

    /**
     * Checks if this unit is a time unit.
     * !(p)
     * All units from nanos to half-days inclusive are time-based.
     * Date-based units and {@code FOREVER} return false.
     *
     * @return true if a time unit, false if a date unit
     */
    override public bool isTimeBased()
    {
        return this.compareTo(DAYS) < 0;
    }

    //-----------------------------------------------------------------------
    override public bool isSupportedBy(Temporal temporal)
    {
        return temporal.isSupported(this);
    }

    /*@SuppressWarnings("unchecked")*/
    override public Temporal addTo(Temporal temporal, long amount) /* if(is(R : Temporal)) */
    {
        return cast(Temporal) temporal.plus(amount, this);
    }

    //-----------------------------------------------------------------------
    override public long between(Temporal temporal1Inclusive, Temporal temporal2Exclusive)
    {
        return temporal1Inclusive.until(temporal2Exclusive, this);
    }

    //-----------------------------------------------------------------------
    override public string toString()
    {
        return name;
    }

    bool opEquals(ref const ChronoUnit h) nothrow
    {
        return name == h.name;
    }

    override public bool opEquals(Object obj)
    {
        if (this is obj)
        {
            return true;
        }
        if (cast(ChronoUnit)(obj) !is null)
        {
            ChronoUnit other = cast(ChronoUnit) obj;
            return name == other.name;
        }
        return false;
    }

    int compareTo(ChronoUnit obj)
    {
        return compare(this.name, obj.name);
    }
}
