
module hunt.time.chrono.ChronoLocalDateImpl;

import hunt.time.temporal.ChronoField;
import hunt.lang.exception;
import hunt.io.common;
import hunt.time.DateTimeException;
import hunt.time.temporal.ChronoUnit;
import hunt.time.temporal.Temporal;
import hunt.time.temporal.TemporalAdjuster;
import hunt.time.temporal.TemporalAmount;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.TemporalUnit;
import hunt.time.temporal.UnsupportedTemporalTypeException;
import hunt.time.temporal.ValueRange;
import hunt.time.chrono.ChronoLocalDate;
import hunt.time.chrono.Chronology;
import hunt.lang;
import std.conv;
import hunt.string.StringBuilder;
/**
 * A date expressed _in terms of a standard year-month-day calendar system.
 * !(p)
 * This class is used by applications seeking to handle dates _in non-ISO calendar systems.
 * For example, the Japanese, Minguo, Thai Buddhist and others.
 * !(p)
 * {@code ChronoLocalDate} is built on the generic concepts of year, month and day.
 * The calendar system, represented by a {@link hunt.time.chrono.Chronology}, expresses the relationship between
 * the fields and this class allows the resulting date to be manipulated.
 * !(p)
 * Note that not all calendar systems are suitable for use with this class.
 * For example, the Mayan calendar uses a system that bears no relation to years, months and days.
 * !(p)
 * The API design encourages the use of {@code LocalDate} for the majority of the application.
 * This includes code to read and write from a persistent data store, such as a database,
 * and to send dates and times across a network. The {@code ChronoLocalDate} instance is then used
 * at the user interface level to deal with localized input/output.
 *
 * !(P)Example: </p>
 * !(pre)
 *        System._out.printf("Example()%n");
 *        // Enumerate the list of available calendars and print today for each
 *        Set&lt;Chronology&gt; chronos = Chronology.getAvailableChronologies();
 *        foreach(Chronology chrono ; chronos) {
 *            ChronoLocalDate date = chrono.dateNow();
 *            System._out.printf("   %20s: %s%n", chrono.getID(), date.toString());
 *        }
 *
 *        // Print the Hijrah date and calendar
 *        ChronoLocalDate date = Chronology.of("Hijrah").dateNow();
 *        int day = date.get(ChronoField.DAY_OF_MONTH);
 *        int dow = date.get(ChronoField.DAY_OF_WEEK);
 *        int month = date.get(ChronoField.MONTH_OF_YEAR);
 *        int year = date.get(ChronoField.YEAR);
 *        System._out.printf("  Today is %s %s %d-%s-%d%n", date.getChronology().getID(),
 *                dow, day, month, year);
 *
 *        // Print today's date and the last day of the year
 *        ChronoLocalDate now1 = Chronology.of("Hijrah").dateNow();
 *        ChronoLocalDate first = now1._with(ChronoField.DAY_OF_MONTH, 1)
 *                ._with(ChronoField.MONTH_OF_YEAR, 1);
 *        ChronoLocalDate last = first.plus(1, ChronoUnit.YEARS)
 *                .minus(1, ChronoUnit.DAYS);
 *        System._out.printf("  Today is %s: start: %s; end: %s%n", last.getChronology().getID(),
 *                first, last);
 * </pre>
 *
 * !(h3)Adding Calendars</h3>
 * !(p) The set of calendars is extensible by defining a subclass of {@link ChronoLocalDate}
 * to represent a date instance and an implementation of {@code Chronology}
 * to be the factory for the ChronoLocalDate subclass.
 * </p>
 * !(p) To permit the discovery of the additional calendar types the implementation of
 * {@code Chronology} must be registered as a Service implementing the {@code Chronology} interface
 * _in the {@code META-INF/Services} file as per the specification of {@link java.util.ServiceLoader}.
 * The subclass must function according to the {@code Chronology} class description and must provide its
 * {@link hunt.time.chrono.Chronology#getId() chronlogy ID} and {@link Chronology#getCalendarType() calendar type}. </p>
 *
 * @implSpec
 * This abstract class must be implemented with care to ensure other classes operate correctly.
 * All implementations that can be instantiated must be final, immutable and thread-safe.
 * Subclasses should be Serializable wherever possible.
 *
 * @param !(D) the ChronoLocalDate of this date-time
 * @since 1.8
 */
abstract class ChronoLocalDateImpl(D = ChronoLocalDate) if(is(D : ChronoLocalDate))
        : ChronoLocalDate, Temporal, TemporalAdjuster, Serializable {

    /**
     * Serialization version.
     */
    private enum long serialVersionUID = 6282433883239719096L;

    /**
     * Casts the {@code Temporal} to {@code ChronoLocalDate} ensuring it bas the specified chronology.
     *
     * @param chrono  the chronology to check for, not null
     * @param temporal  a date-time to cast, not null
     * @return the date-time checked and cast to {@code ChronoLocalDate}, not null
     * @throws ClassCastException if the date-time cannot be cast to ChronoLocalDate
     *  or the chronology is not equal this Chronology
     */
    static  D ensureValid(D)(Chronology chrono, Temporal temporal) {
        /*@SuppressWarnings("unchecked")*/
        D other =  cast(D)temporal;
        if ((chrono == other.getChronology()) == false) {
            throw new ClassCastException("Chronology mismatch, expected: " ~ chrono.getId() ~ ", actual: " ~ other.getChronology().getId());
        }
        return other;
    }

    //-----------------------------------------------------------------------
    /**
     * Creates an instance.
     */
    this() {
    }

    override
    /*@SuppressWarnings("unchecked")*/
    public D _with(TemporalAdjuster adjuster) {
        return cast(D) /* ChronoLocalDate. super.*/super_with(adjuster);
    }
     ChronoLocalDate super_with(TemporalAdjuster adjuster) {
        return ChronoLocalDateImpl!D.ensureValid!D(getChronology(), adjuster.adjustInto(this));
    }

    override
    /*@SuppressWarnings("unchecked")*/
    public D _with(TemporalField field, long value) {
        return cast(D) /* ChronoLocalDate. super.*/super_with(field, value);
    }
     ChronoLocalDate super_with(TemporalField field, long newValue) {
        if (cast(ChronoField)(field) !is null) {
            throw new UnsupportedTemporalTypeException("Unsupported field: " ~ typeid(field).name);
        }
        return ChronoLocalDateImpl!D.ensureValid!D(getChronology(), field.adjustInto(this, newValue));
    }

    //-----------------------------------------------------------------------
    override
    /*@SuppressWarnings("unchecked")*/
    public D plus(TemporalAmount amount) {
        return cast(D) /* ChronoLocalDate.super. */super_plus(amount);
    }
     ChronoLocalDate super_plus(TemporalAmount amount) {
        return ChronoLocalDateImpl!D.ensureValid!D(getChronology(),amount.addTo(this));
    }
    //-----------------------------------------------------------------------
    override
    /*@SuppressWarnings("unchecked")*/
    public D plus(long amountToAdd, TemporalUnit unit) {
        if (cast(ChronoUnit)(unit) !is null) {
            ChronoUnit f = cast(ChronoUnit) unit;
            {
                if( f == ChronoUnit.DAYS) return plusDays(amountToAdd);
                if( f == ChronoUnit.WEEKS) return plusDays(Math.multiplyExact(amountToAdd, 7));
                if( f == ChronoUnit.MONTHS) return plusMonths(amountToAdd);
                if( f == ChronoUnit.YEARS) return plusYears(amountToAdd);
                if( f == ChronoUnit.DECADES) return plusYears(Math.multiplyExact(amountToAdd, 10));
                if( f == ChronoUnit.CENTURIES) return plusYears(Math.multiplyExact(amountToAdd, 100));
                if( f == ChronoUnit.MILLENNIA) return plusYears(Math.multiplyExact(amountToAdd, 1000));
                if( f == ChronoUnit.ERAS) return _with(ChronoField.ERA, Math.addExact(getLong(ChronoField.ERA), amountToAdd));
            }
            throw new UnsupportedTemporalTypeException("Unsupported unit: " ~ f.toString);
        }
        return cast(D) /* ChronoLocalDate. super.*/super_plus(amountToAdd, unit);
    }
     ChronoLocalDate super_plus(long amountToAdd, TemporalUnit unit) {
        if (cast(ChronoUnit)(unit) !is null) {
            throw new UnsupportedTemporalTypeException("Unsupported unit: " ~ typeid(unit).name);
        }
        return ChronoLocalDateImpl!D.ensureValid!D(getChronology(), unit.addTo(this, amountToAdd));
    }

    override
    /*@SuppressWarnings("unchecked")*/
    public D minus(TemporalAmount amount) {
        return cast(D) /* ChronoLocalDate. */super_minus(amount);
    }

     ChronoLocalDate super_minus(TemporalAmount amount) {
        return ChronoLocalDateImpl!D.ensureValid!D(getChronology(), amount.subtractFrom(this));
    }

    override
    /*@SuppressWarnings("unchecked")*/
    public D minus(long amountToSubtract, TemporalUnit unit) {
        return cast(D) /* ChronoLocalDate. */super_minus(amountToSubtract, unit);
    }
     ChronoLocalDate super_minus(long amountToSubtract, TemporalUnit unit) {
        return ChronoLocalDateImpl!D.ensureValid!D(getChronology(), (amountToSubtract == Long.MIN_VALUE ? plus(Long.MAX_VALUE, unit).plus(1, unit) : plus(-amountToSubtract, unit)));
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this date with the specified number of years added.
     * !(p)
     * This adds the specified period _in years to the date.
     * In some cases, adding years can cause the resulting date to become invalid.
     * If this occurs, then other fields, typically the day-of-month, will be adjusted to ensure
     * that the result is valid. Typically this will select the last valid day of the month.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param yearsToAdd  the years to add, may be negative
     * @return a date based on this one with the years added, not null
     * @throws DateTimeException if the result exceeds the supported date range
     */
    abstract D plusYears(long yearsToAdd);

    /**
     * Returns a copy of this date with the specified number of months added.
     * !(p)
     * This adds the specified period _in months to the date.
     * In some cases, adding months can cause the resulting date to become invalid.
     * If this occurs, then other fields, typically the day-of-month, will be adjusted to ensure
     * that the result is valid. Typically this will select the last valid day of the month.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param monthsToAdd  the months to add, may be negative
     * @return a date based on this one with the months added, not null
     * @throws DateTimeException if the result exceeds the supported date range
     */
    abstract D plusMonths(long monthsToAdd);

    /**
     * Returns a copy of this date with the specified number of weeks added.
     * !(p)
     * This adds the specified period _in weeks to the date.
     * In some cases, adding weeks can cause the resulting date to become invalid.
     * If this occurs, then other fields will be adjusted to ensure that the result is valid.
     * !(p)
     * The default implementation uses {@link #plusDays(long)} using a 7 day week.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param weeksToAdd  the weeks to add, may be negative
     * @return a date based on this one with the weeks added, not null
     * @throws DateTimeException if the result exceeds the supported date range
     */
    D plusWeeks(long weeksToAdd) {
        return plusDays(Math.multiplyExact(weeksToAdd, 7));
    }

    /**
     * Returns a copy of this date with the specified number of days added.
     * !(p)
     * This adds the specified period _in days to the date.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param daysToAdd  the days to add, may be negative
     * @return a date based on this one with the days added, not null
     * @throws DateTimeException if the result exceeds the supported date range
     */
    abstract D plusDays(long daysToAdd);

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this date with the specified number of years subtracted.
     * !(p)
     * This subtracts the specified period _in years to the date.
     * In some cases, subtracting years can cause the resulting date to become invalid.
     * If this occurs, then other fields, typically the day-of-month, will be adjusted to ensure
     * that the result is valid. Typically this will select the last valid day of the month.
     * !(p)
     * The default implementation uses {@link #plusYears(long)}.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param yearsToSubtract  the years to subtract, may be negative
     * @return a date based on this one with the years subtracted, not null
     * @throws DateTimeException if the result exceeds the supported date range
     */
    /*@SuppressWarnings("unchecked")*/
    D minusYears(long yearsToSubtract) {
        return (yearsToSubtract == Long.MIN_VALUE ? (cast(ChronoLocalDateImpl!(D))plusYears(Long.MAX_VALUE)).plusYears(1) : plusYears(-yearsToSubtract));
    }

    /**
     * Returns a copy of this date with the specified number of months subtracted.
     * !(p)
     * This subtracts the specified period _in months to the date.
     * In some cases, subtracting months can cause the resulting date to become invalid.
     * If this occurs, then other fields, typically the day-of-month, will be adjusted to ensure
     * that the result is valid. Typically this will select the last valid day of the month.
     * !(p)
     * The default implementation uses {@link #plusMonths(long)}.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param monthsToSubtract  the months to subtract, may be negative
     * @return a date based on this one with the months subtracted, not null
     * @throws DateTimeException if the result exceeds the supported date range
     */
    /*@SuppressWarnings("unchecked")*/
    D minusMonths(long monthsToSubtract) {
        return (monthsToSubtract == Long.MIN_VALUE ? (cast(ChronoLocalDateImpl!(D))plusMonths(Long.MAX_VALUE)).plusMonths(1) : plusMonths(-monthsToSubtract));
    }

    /**
     * Returns a copy of this date with the specified number of weeks subtracted.
     * !(p)
     * This subtracts the specified period _in weeks to the date.
     * In some cases, subtracting weeks can cause the resulting date to become invalid.
     * If this occurs, then other fields will be adjusted to ensure that the result is valid.
     * !(p)
     * The default implementation uses {@link #plusWeeks(long)}.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param weeksToSubtract  the weeks to subtract, may be negative
     * @return a date based on this one with the weeks subtracted, not null
     * @throws DateTimeException if the result exceeds the supported date range
     */
    /*@SuppressWarnings("unchecked")*/
    D minusWeeks(long weeksToSubtract) {
        return (weeksToSubtract == Long.MIN_VALUE ? (cast(ChronoLocalDateImpl!(D))plusWeeks(Long.MAX_VALUE)).plusWeeks(1) : plusWeeks(-weeksToSubtract));
    }

    /**
     * Returns a copy of this date with the specified number of days subtracted.
     * !(p)
     * This subtracts the specified period _in days to the date.
     * !(p)
     * The default implementation uses {@link #plusDays(long)}.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param daysToSubtract  the days to subtract, may be negative
     * @return a date based on this one with the days subtracted, not null
     * @throws DateTimeException if the result exceeds the supported date range
     */
    /*@SuppressWarnings("unchecked")*/
    D minusDays(long daysToSubtract) {
        return (daysToSubtract == Long.MIN_VALUE ? (cast(ChronoLocalDateImpl!(D))plusDays(Long.MAX_VALUE)).plusDays(1) : plusDays(-daysToSubtract));
    }

    //-----------------------------------------------------------------------
    override
    public long until(Temporal endExclusive, TemporalUnit unit) {
        assert(endExclusive, "endExclusive");
        ChronoLocalDate end = getChronology().date(endExclusive);
        if (cast(ChronoUnit)(unit) !is null) {
            auto f = cast(ChronoUnit) unit;
            {
                if( f == ChronoUnit.DAYS) return daysUntil(end);
                if( f == ChronoUnit.WEEKS) return daysUntil(end) / 7;
                if( f == ChronoUnit.MONTHS) return monthsUntil(end);
                if( f == ChronoUnit.YEARS) return monthsUntil(end) / 12;
                if( f == ChronoUnit.DECADES) return monthsUntil(end) / 120;
                if( f == ChronoUnit.CENTURIES) return monthsUntil(end) / 1200;
                if( f == ChronoUnit.MILLENNIA) return monthsUntil(end) / 12000;
                if( f == ChronoUnit.ERAS) return end.getLong(ChronoField.ERA) - getLong(ChronoField.ERA);
            }
            throw new UnsupportedTemporalTypeException("Unsupported unit: " ~ f.toString);
        }
        assert(unit, "unit");
        return unit.between(this, end);
    }

    private long daysUntil(ChronoLocalDate end) {
        return end.toEpochDay() - toEpochDay();  // no overflow
    }

    private long monthsUntil(ChronoLocalDate end) {
        ValueRange range = getChronology().range(ChronoField.MONTH_OF_YEAR);
        if (range.getMaximum() != 12) {
            throw new IllegalStateException("ChronoLocalDateImpl only supports Chronologies with 12 months per year");
        }
        long packed1 = getLong(ChronoField.PROLEPTIC_MONTH) * 32L + get(ChronoField.DAY_OF_MONTH);  // no overflow
        long packed2 = end.getLong(ChronoField.PROLEPTIC_MONTH) * 32L + end.get(ChronoField.DAY_OF_MONTH);  // no overflow
        return (packed2 - packed1) / 32;
    }

    override
    public bool opEquals(Object obj) {
        if (this is obj) {
            return true;
        }
        if (cast(ChronoLocalDate)(obj) !is null) {
            return compareTo(cast(ChronoLocalDate) obj) == 0;
        }
        return false;
    }

    override
    public size_t toHash() @trusted nothrow {
        try{
            long epDay = toEpochDay();
            return getChronology().toHash() ^ (cast(int) (epDay ^ (epDay >>> 32)));
        }catch(Exception e){}
        return int.init;
    }

    override
    public string toString() {
        // getLong() reduces chances of exceptions _in toString()
        long yoe = getLong(ChronoField.YEAR_OF_ERA);
        long moy = getLong(ChronoField.MONTH_OF_YEAR);
        long dom = getLong(ChronoField.DAY_OF_MONTH);
        StringBuilder buf = new StringBuilder(30);
        buf.append(getChronology().toString())
                .append(" ")
                .append(typeid(getEra()).name) ///@gxc
                .append(" ")
                .append(yoe)
                .append(moy < 10 ? "-0" : "-").append(moy)
                .append(dom < 10 ? "-0" : "-").append(dom);
        return buf.toString();
    }

}
