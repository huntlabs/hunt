
module hunt.time.Period;

import hunt.time.temporal.ChronoUnit;

import hunt.io.DataInput;
import hunt.io.DataOutput;
import hunt.lang.exception;

//import hunt.io.ObjectInputStream;
import hunt.io.common;
import hunt.time.chrono.ChronoLocalDate;
import hunt.time.chrono.ChronoPeriod;
import hunt.time.chrono.Chronology;
import hunt.time.chrono.IsoChronology;
import hunt.time.format.DateTimeParseException;
import hunt.time.temporal.ChronoUnit;
import hunt.time.temporal.Temporal;
import hunt.time.temporal.TemporalAccessor;
import hunt.time.temporal.TemporalAmount;
import hunt.time.temporal.TemporalQueries;
import hunt.time.temporal.TemporalUnit;
import hunt.time.temporal.UnsupportedTemporalTypeException;
import hunt.container.List;
import hunt.time.LocalDate;
import hunt.util.Comparator;
import hunt.time.DateTimeException;
import hunt.lang;
import hunt.container;
import hunt.time.Ser;
import hunt.string.common;
import std.conv;
import std.regex;
import hunt.string.StringBuilder;
import hunt.time.util.QueryHelper;
import hunt.time.util.common;
// import hunt.util.regex.Matcher;
// import hunt.util.regex.Pattern;

/**
 * A date-based amount of time _in the ISO-8601 calendar system,
 * such as '2 years, 3 months and 4 days'.
 * !(p)
 * This class models a quantity or amount of time _in terms of years, months and days.
 * See {@link Duration} for the time-based equivalent to this class.
 * !(p)
 * Durations and periods differ _in their treatment of daylight savings time
 * when added to {@link ZonedDateTime}. A {@code Duration} will add an exact
 * number of seconds, thus a duration of one day is always exactly 24 hours.
 * By contrast, a {@code Period} will add a conceptual day, trying to maintain
 * the local time.
 * !(p)
 * For example, consider adding a period of one day and a duration of one day to
 * 18:00 on the evening before a daylight savings gap. The {@code Period} will add
 * the conceptual day and result _in a {@code ZonedDateTime} at 18:00 the following day.
 * By contrast, the {@code Duration} will add exactly 24 hours, resulting _in a
 * {@code ZonedDateTime} at 19:00 the following day (assuming a one hour DST gap).
 * !(p)
 * The supported units of a period are {@link ChronoUnit#YEARS YEARS},
 * {@link ChronoUnit#MONTHS MONTHS} and {@link ChronoUnit#DAYS DAYS}.
 * All three fields are always present, but may be set to zero.
 * !(p)
 * The ISO-8601 calendar system is the modern civil calendar system used today
 * _in most of the world. It is equivalent to the proleptic Gregorian calendar
 * system, _in which today's rules for leap years are applied for all time.
 * !(p)
 * The period is modeled as a directed amount of time, meaning that individual parts of the
 * period may be negative.
 *
 * !(p)
 * This is a <a href="{@docRoot}/java.base/java/lang/doc-files/ValueBased.html">value-based</a>
 * class; use of identity-sensitive operations (including reference equality
 * ({@code ==}), identity hash code, or synchronization) on instances of
 * {@code Period} may have unpredictable results and should be avoided.
 * The {@code equals} method should be used for comparisons.
 *
 * @implSpec
 * This class is immutable and thread-safe.
 *
 * @since 1.8
 */
public final class Period
        : ChronoPeriod, Serializable {

    /**
     * A constant for a period of zero.
     */
    // public __gshared Period ZERO;
    /**
     * Serialization version.
     */
    private enum long serialVersionUID = -3587258372562876L;
    /**
     * The pattern for parsing.
     */
    private enum  PATTERN =
            "([-+]?)P(?:([-+]?[0-9]+)Y)?(?:([-+]?[0-9]+)M)?(?:([-+]?[0-9]+)W)?(?:([-+]?[0-9]+)D)?";

    /**
     * The set of supported units.
     */
    __gshared List!(TemporalUnit) _SUPPORTED_UNITS;

    /**
     * The number of years.
     */
    private  int years;
    /**
     * The number of months.
     */
    private  int months;
    /**
     * The number of days.
     */
    private  int days;

    public static ref List!(TemporalUnit) SUPPORTED_UNITS()
    {
        if(_SUPPORTED_UNITS is null)
        {
            _SUPPORTED_UNITS = new ArrayList!TemporalUnit();
            _SUPPORTED_UNITS.add(ChronoUnit.YEARS);
            _SUPPORTED_UNITS.add(ChronoUnit.MONTHS);
            _SUPPORTED_UNITS.add(ChronoUnit.DAYS);
        }
        return _SUPPORTED_UNITS;
    }
    // shared static this()
    // {
        // ZERO = new Period(0, 0, 0);
        mixin(MakeGlobalVar!(Period)("ZERO",`new Period(0, 0, 0)`));
        
    // }

    //-----------------------------------------------------------------------
    /**
     * Obtains a {@code Period} representing a number of years.
     * !(p)
     * The resulting period will have the specified years.
     * The months and days units will be zero.
     *
     * @param years  the number of years, positive or negative
     * @return the period of years, not null
     */
    public static Period ofYears(int years) {
        return create(years, 0, 0);
    }

    /**
     * Obtains a {@code Period} representing a number of months.
     * !(p)
     * The resulting period will have the specified months.
     * The years and days units will be zero.
     *
     * @param months  the number of months, positive or negative
     * @return the period of months, not null
     */
    public static Period ofMonths(int months) {
        return create(0, months, 0);
    }

    /**
     * Obtains a {@code Period} representing a number of weeks.
     * !(p)
     * The resulting period will be day-based, with the amount of days
     * equal to the number of weeks multiplied by 7.
     * The years and months units will be zero.
     *
     * @param weeks  the number of weeks, positive or negative
     * @return the period, with the input weeks converted to days, not null
     */
    public static Period ofWeeks(int weeks) {
        return create(0, 0, Math.multiplyExact(weeks, 7));
    }

    /**
     * Obtains a {@code Period} representing a number of days.
     * !(p)
     * The resulting period will have the specified days.
     * The years and months units will be zero.
     *
     * @param days  the number of days, positive or negative
     * @return the period of days, not null
     */
    public static Period ofDays(int days) {
        return create(0, 0, days);
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains a {@code Period} representing a number of years, months and days.
     * !(p)
     * This creates an instance based on years, months and days.
     *
     * @param years  the amount of years, may be negative
     * @param months  the amount of months, may be negative
     * @param days  the amount of days, may be negative
     * @return the period of years, months and days, not null
     */
    public static Period of(int years, int months, int days) {
        return create(years, months, days);
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code Period} from a temporal amount.
     * !(p)
     * This obtains a period based on the specified amount.
     * A {@code TemporalAmount} represents an  amount of time, which may be
     * date-based or time-based, which this factory extracts to a {@code Period}.
     * !(p)
     * The conversion loops around the set of units from the amount and uses
     * the {@link ChronoUnit#YEARS YEARS}, {@link ChronoUnit#MONTHS MONTHS}
     * and {@link ChronoUnit#DAYS DAYS} units to create a period.
     * If any other units are found then an exception is thrown.
     * !(p)
     * If the amount is a {@code ChronoPeriod} then it must use the ISO chronology.
     *
     * @param amount  the temporal amount to convert, not null
     * @return the equivalent period, not null
     * @throws DateTimeException if unable to convert to a {@code Period}
     * @throws ArithmeticException if the amount of years, months or days exceeds an int
     */
    public static Period from(TemporalAmount amount) {
        if (cast(Period)(amount) !is null) {
            return cast(Period) amount;
        }
        if (cast(ChronoPeriod)(amount) !is null) {
            if ((IsoChronology.INSTANCE == (cast(ChronoPeriod) amount).getChronology()) == false) {
                throw new DateTimeException("Period requires ISO chronology: " ~ typeid(amount).name);
            }
        }
        assert(amount, "amount");
        int years = 0;
        int months = 0;
        int days = 0;
        foreach(TemporalUnit unit ; amount.getUnits()) {
            long unitAmount = amount.get(unit);
            if (unit == ChronoUnit.YEARS) {
                years = Math.toIntExact(unitAmount);
            } else if (unit == ChronoUnit.MONTHS) {
                months = Math.toIntExact(unitAmount);
            } else if (unit == ChronoUnit.DAYS) {
                days = Math.toIntExact(unitAmount);
            } else {
                throw new DateTimeException("Unit must be Years, Months or Days, but was " ~ typeid(unit).name);
            }
        }
        return create(years, months, days);
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains a {@code Period} from a text string such as {@code PnYnMnD}.
     * !(p)
     * This will parse the string produced by {@code toString()} which is
     * based on the ISO-8601 period formats {@code PnYnMnD} and {@code PnW}.
     * !(p)
     * The string starts with an optional sign, denoted by the ASCII negative
     * or positive symbol. If negative, the whole period is negated.
     * The ASCII letter "P" is next _in upper or lower case.
     * There are then four sections, each consisting of a number and a suffix.
     * At least one of the four sections must be present.
     * The sections have suffixes _in ASCII of "Y", "M", "W" and "D" for
     * years, months, weeks and days, accepted _in upper or lower case.
     * The suffixes must occur _in order.
     * The number part of each section must consist of ASCII digits.
     * The number may be prefixed by the ASCII negative or positive symbol.
     * The number must parse to an {@code int}.
     * !(p)
     * The leading plus/minus sign, and negative values for other units are
     * not part of the ISO-8601 standard. In addition, ISO-8601 does not
     * permit mixing between the {@code PnYnMnD} and {@code PnW} formats.
     * Any week-based input is multiplied by 7 and treated as a number of days.
     * !(p)
     * For example, the following are valid inputs:
     * !(pre)
     *   "P2Y"             -- Period.ofYears(2)
     *   "P3M"             -- Period.ofMonths(3)
     *   "P4W"             -- Period.ofWeeks(4)
     *   "P5D"             -- Period.ofDays(5)
     *   "P1Y2M3D"         -- Period.of(1, 2, 3)
     *   "P1Y2M3W4D"       -- Period.of(1, 2, 25)
     *   "P-1Y2M"          -- Period.of(-1, 2, 0)
     *   "-P1Y2M"          -- Period.of(-1, -2, 0)
     * </pre>
     *
     * @param text  the text to parse, not null
     * @return the parsed period, not null
     * @throws DateTimeParseException if the text cannot be parsed to a period
     */
    public static Period parse(string text) {
        assert(text, "text");
        auto matchers = matchAll(text,PATTERN);
        if (!matchers.empty()) {
            auto matcher = matchers.front();

            int negate = (charMatch(text, matcher.captures[0], '-') ? -1 : 1);
            string yearStart = matcher.captures[1];
            string monthStart = matcher.captures[2];
            string weekStart = matcher.captures[3];
            string dayStart = matcher.captures[4];
            if (yearStart.length >= 0 || monthStart.length >= 0 || weekStart.length >= 0 || dayStart.length >= 0) {
                try {
                    int years = parseNumber(text, yearStart, negate);
                    int months = parseNumber(text, monthStart, negate);
                    int weeks = parseNumber(text, weekStart, negate);
                    int days = parseNumber(text, dayStart, negate);
                    days = Math.addExact(days, Math.multiplyExact(weeks, 7));
                    return create(years, months, days);
                } catch (NumberFormatException ex) {
                    throw new DateTimeParseException("Text cannot be parsed to a Period", text, 0, ex);
                }
            }
        }
        throw new DateTimeParseException("Text cannot be parsed to a Period", text, 0);
    }

    private static bool charMatch(string text, string data, char c) {
        return (data.length == 1 && data[0] == c);
    }

    private static int parseNumber(string text, string data ,int negate) {
        import std.string : isNumeric;
        if (!isNumeric(data) || data.length == 0) {
            return 0;
        }
        int val = to!int(data);
        try {
            return Math.multiplyExact(val, negate);
        } catch (ArithmeticException ex) {
            throw new DateTimeParseException("Text cannot be parsed to a Period", text, 0, ex);
        }
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains a {@code Period} consisting of the number of years, months,
     * and days between two dates.
     * !(p)
     * The start date is included, but the end date is not.
     * The period is calculated by removing complete months, then calculating
     * the remaining number of days, adjusting to ensure that both have the same sign.
     * The number of months is then split into years and months based on a 12 month year.
     * A month is considered if the end day-of-month is greater than or equal to the start day-of-month.
     * For example, from {@code 2010-01-15} to {@code 2011-03-18} is one year, two months and three days.
     * !(p)
     * The result of this method can be a negative period if the end is before the start.
     * The negative sign will be the same _in each of year, month and day.
     *
     * @param startDateInclusive  the start date, inclusive, not null
     * @param endDateExclusive  the end date, exclusive, not null
     * @return the period between this date and the end date, not null
     * @see ChronoLocalDate#until(ChronoLocalDate)
     */
    public static Period between(LocalDate startDateInclusive, LocalDate endDateExclusive) {
        return startDateInclusive.until(endDateExclusive);
    }

    //-----------------------------------------------------------------------
    /**
     * Creates an instance.
     *
     * @param years  the amount
     * @param months  the amount
     * @param days  the amount
     */
    private static Period create(int years, int months, int days) {
        if ((years | months | days) == 0) {
            return ZERO;
        }
        return new Period(years, months, days);
    }

    /**
     * Constructor.
     *
     * @param years  the amount
     * @param months  the amount
     * @param days  the amount
     */
    this(int years, int months, int days) {
        this.years = years;
        this.months = months;
        this.days = days;
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the value of the requested unit.
     * !(p)
     * This returns a value for each of the three supported units,
     * {@link ChronoUnit#YEARS YEARS}, {@link ChronoUnit#MONTHS MONTHS} and
     * {@link ChronoUnit#DAYS DAYS}.
     * All other units throw an exception.
     *
     * @param unit the {@code TemporalUnit} for which to return the value
     * @return the long value of the unit
     * @throws DateTimeException if the unit is not supported
     * @throws UnsupportedTemporalTypeException if the unit is not supported
     */
    override
    public long get(TemporalUnit unit) {
        if (unit == ChronoUnit.YEARS) {
            return getYears();
        } else if (unit == ChronoUnit.MONTHS) {
            return getMonths();
        } else if (unit == ChronoUnit.DAYS) {
            return getDays();
        } else {
            throw new UnsupportedTemporalTypeException("Unsupported unit: " ~ typeid(unit).name);
        }
    }

    /**
     * Gets the set of units supported by this period.
     * !(p)
     * The supported units are {@link ChronoUnit#YEARS YEARS},
     * {@link ChronoUnit#MONTHS MONTHS} and {@link ChronoUnit#DAYS DAYS}.
     * They are returned _in the order years, months, days.
     * !(p)
     * This set can be used _in conjunction with {@link #get(TemporalUnit)}
     * to access the entire state of the period.
     *
     * @return a list containing the years, months and days units, not null
     */
    override
    public List!(TemporalUnit) getUnits() {
        return SUPPORTED_UNITS;
    }

    /**
     * Gets the chronology of this period, which is the ISO calendar system.
     * !(p)
     * The {@code Chronology} represents the calendar system _in use.
     * The ISO-8601 calendar system is the modern civil calendar system used today
     * _in most of the world. It is equivalent to the proleptic Gregorian calendar
     * system, _in which today's rules for leap years are applied for all time.
     *
     * @return the ISO chronology, not null
     */
    override
    public IsoChronology getChronology() {
        return IsoChronology.INSTANCE;
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if all three units of this period are zero.
     * !(p)
     * A zero period has the value zero for the years, months and days units.
     *
     * @return true if this period is zero-length
     */
    public bool isZero() {
        return (this == ZERO);
    }

    /**
     * Checks if any of the three units of this period are negative.
     * !(p)
     * This checks whether the years, months or days units are less than zero.
     *
     * @return true if any unit of this period is negative
     */
    public bool isNegative() {
        return years < 0 || months < 0 || days < 0;
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the amount of years of this period.
     * !(p)
     * This returns the years unit.
     * !(p)
     * The months unit is not automatically normalized with the years unit.
     * This means that a period of "15 months" is different to a period
     * of "1 year and 3 months".
     *
     * @return the amount of years of this period, may be negative
     */
    public int getYears() {
        return years;
    }

    /**
     * Gets the amount of months of this period.
     * !(p)
     * This returns the months unit.
     * !(p)
     * The months unit is not automatically normalized with the years unit.
     * This means that a period of "15 months" is different to a period
     * of "1 year and 3 months".
     *
     * @return the amount of months of this period, may be negative
     */
    public int getMonths() {
        return months;
    }

    /**
     * Gets the amount of days of this period.
     * !(p)
     * This returns the days unit.
     *
     * @return the amount of days of this period, may be negative
     */
    public int getDays() {
        return days;
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this period with the specified amount of years.
     * !(p)
     * This sets the amount of the years unit _in a copy of this period.
     * The months and days units are unaffected.
     * !(p)
     * The months unit is not automatically normalized with the years unit.
     * This means that a period of "15 months" is different to a period
     * of "1 year and 3 months".
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param years  the years to represent, may be negative
     * @return a {@code Period} based on this period with the requested years, not null
     */
    public Period withYears(int years) {
        if (years == this.years) {
            return this;
        }
        return create(years, months, days);
    }

    /**
     * Returns a copy of this period with the specified amount of months.
     * !(p)
     * This sets the amount of the months unit _in a copy of this period.
     * The years and days units are unaffected.
     * !(p)
     * The months unit is not automatically normalized with the years unit.
     * This means that a period of "15 months" is different to a period
     * of "1 year and 3 months".
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param months  the months to represent, may be negative
     * @return a {@code Period} based on this period with the requested months, not null
     */
    public Period withMonths(int months) {
        if (months == this.months) {
            return this;
        }
        return create(years, months, days);
    }

    /**
     * Returns a copy of this period with the specified amount of days.
     * !(p)
     * This sets the amount of the days unit _in a copy of this period.
     * The years and months units are unaffected.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param days  the days to represent, may be negative
     * @return a {@code Period} based on this period with the requested days, not null
     */
    public Period withDays(int days) {
        if (days == this.days) {
            return this;
        }
        return create(years, months, days);
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this period with the specified period added.
     * !(p)
     * This operates separately on the years, months and days.
     * No normalization is performed.
     * !(p)
     * For example, "1 year, 6 months and 3 days" plus "2 years, 2 months and 2 days"
     * returns "3 years, 8 months and 5 days".
     * !(p)
     * The specified amount is typically an instance of {@code Period}.
     * Other types are interpreted using {@link Period#from(TemporalAmount)}.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param amountToAdd  the amount to add, not null
     * @return a {@code Period} based on this period with the requested period added, not null
     * @throws DateTimeException if the specified amount has a non-ISO chronology or
     *  contains an invalid unit
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Period plus(TemporalAmount amountToAdd) {
        Period isoAmount = Period.from(amountToAdd);
        return create(
                Math.addExact(years, isoAmount.years),
                Math.addExact(months, isoAmount.months),
                Math.addExact(days, isoAmount.days));
    }

    /**
     * Returns a copy of this period with the specified years added.
     * !(p)
     * This adds the amount to the years unit _in a copy of this period.
     * The months and days units are unaffected.
     * For example, "1 year, 6 months and 3 days" plus 2 years returns "3 years, 6 months and 3 days".
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param yearsToAdd  the years to add, positive or negative
     * @return a {@code Period} based on this period with the specified years added, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Period plusYears(long yearsToAdd) {
        if (yearsToAdd == 0) {
            return this;
        }
        return create(Math.toIntExact(Math.addExact(years, yearsToAdd)), months, days);
    }

    /**
     * Returns a copy of this period with the specified months added.
     * !(p)
     * This adds the amount to the months unit _in a copy of this period.
     * The years and days units are unaffected.
     * For example, "1 year, 6 months and 3 days" plus 2 months returns "1 year, 8 months and 3 days".
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param monthsToAdd  the months to add, positive or negative
     * @return a {@code Period} based on this period with the specified months added, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Period plusMonths(long monthsToAdd) {
        if (monthsToAdd == 0) {
            return this;
        }
        return create(years, Math.toIntExact(Math.addExact(months, monthsToAdd)), days);
    }

    /**
     * Returns a copy of this period with the specified days added.
     * !(p)
     * This adds the amount to the days unit _in a copy of this period.
     * The years and months units are unaffected.
     * For example, "1 year, 6 months and 3 days" plus 2 days returns "1 year, 6 months and 5 days".
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param daysToAdd  the days to add, positive or negative
     * @return a {@code Period} based on this period with the specified days added, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Period plusDays(long daysToAdd) {
        if (daysToAdd == 0) {
            return this;
        }
        return create(years, months, Math.toIntExact(Math.addExact(days, daysToAdd)));
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this period with the specified period subtracted.
     * !(p)
     * This operates separately on the years, months and days.
     * No normalization is performed.
     * !(p)
     * For example, "1 year, 6 months and 3 days" minus "2 years, 2 months and 2 days"
     * returns "-1 years, 4 months and 1 day".
     * !(p)
     * The specified amount is typically an instance of {@code Period}.
     * Other types are interpreted using {@link Period#from(TemporalAmount)}.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param amountToSubtract  the amount to subtract, not null
     * @return a {@code Period} based on this period with the requested period subtracted, not null
     * @throws DateTimeException if the specified amount has a non-ISO chronology or
     *  contains an invalid unit
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Period minus(TemporalAmount amountToSubtract) {
        Period isoAmount = Period.from(amountToSubtract);
        return create(
                Math.subtractExact(years, isoAmount.years),
                Math.subtractExact(months, isoAmount.months),
                Math.subtractExact(days, isoAmount.days));
    }

    /**
     * Returns a copy of this period with the specified years subtracted.
     * !(p)
     * This subtracts the amount from the years unit _in a copy of this period.
     * The months and days units are unaffected.
     * For example, "1 year, 6 months and 3 days" minus 2 years returns "-1 years, 6 months and 3 days".
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param yearsToSubtract  the years to subtract, positive or negative
     * @return a {@code Period} based on this period with the specified years subtracted, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Period minusYears(long yearsToSubtract) {
        return (yearsToSubtract == Long.MIN_VALUE ? plusYears(Long.MAX_VALUE).plusYears(1) : plusYears(-yearsToSubtract));
    }

    /**
     * Returns a copy of this period with the specified months subtracted.
     * !(p)
     * This subtracts the amount from the months unit _in a copy of this period.
     * The years and days units are unaffected.
     * For example, "1 year, 6 months and 3 days" minus 2 months returns "1 year, 4 months and 3 days".
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param monthsToSubtract  the years to subtract, positive or negative
     * @return a {@code Period} based on this period with the specified months subtracted, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Period minusMonths(long monthsToSubtract) {
        return (monthsToSubtract == Long.MIN_VALUE ? plusMonths(Long.MAX_VALUE).plusMonths(1) : plusMonths(-monthsToSubtract));
    }

    /**
     * Returns a copy of this period with the specified days subtracted.
     * !(p)
     * This subtracts the amount from the days unit _in a copy of this period.
     * The years and months units are unaffected.
     * For example, "1 year, 6 months and 3 days" minus 2 days returns "1 year, 6 months and 1 day".
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param daysToSubtract  the months to subtract, positive or negative
     * @return a {@code Period} based on this period with the specified days subtracted, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Period minusDays(long daysToSubtract) {
        return (daysToSubtract == Long.MIN_VALUE ? plusDays(Long.MAX_VALUE).plusDays(1) : plusDays(-daysToSubtract));
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a new instance with each element _in this period multiplied
     * by the specified scalar.
     * !(p)
     * This returns a period with each of the years, months and days units
     * individually multiplied.
     * For example, a period of "2 years, -3 months and 4 days" multiplied by
     * 3 will return "6 years, -9 months and 12 days".
     * No normalization is performed.
     *
     * @param scalar  the scalar to multiply by, not null
     * @return a {@code Period} based on this period with the amounts multiplied by the scalar, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Period multipliedBy(int scalar) {
        if (this == ZERO || scalar == 1) {
            return this;
        }
        return create(
                Math.multiplyExact(years, scalar),
                Math.multiplyExact(months, scalar),
                Math.multiplyExact(days, scalar));
    }

    /**
     * Returns a new instance with each amount _in this period negated.
     * !(p)
     * This returns a period with each of the years, months and days units
     * individually negated.
     * For example, a period of "2 years, -3 months and 4 days" will be
     * negated to "-2 years, 3 months and -4 days".
     * No normalization is performed.
     *
     * @return a {@code Period} based on this period with the amounts negated, not null
     * @throws ArithmeticException if numeric overflow occurs, which only happens if
     *  one of the units has the value {@code Long.MIN_VALUE}
     */
    public Period negated() {
        return multipliedBy(-1);
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this period with the years and months normalized.
     * !(p)
     * This normalizes the years and months units, leaving the days unit unchanged.
     * The months unit is adjusted to have an absolute value less than 12,
     * with the years unit being adjusted to compensate. For example, a period of
     * "1 Year and 15 months" will be normalized to "2 years and 3 months".
     * !(p)
     * The sign of the years and months units will be the same after normalization.
     * For example, a period of "1 year and -25 months" will be normalized to
     * "-1 year and -1 month".
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @return a {@code Period} based on this period with excess months normalized to years, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Period normalized() {
        long totalMonths = toTotalMonths();
        long splitYears = totalMonths / 12;
        int splitMonths = cast(int) (totalMonths % 12);  // no overflow
        if (splitYears == years && splitMonths == months) {
            return this;
        }
        return create(Math.toIntExact(splitYears), splitMonths, days);
    }

    /**
     * Gets the total number of months _in this period.
     * !(p)
     * This returns the total number of months _in the period by multiplying the
     * number of years by 12 and adding the number of months.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @return the total number of months _in the period, may be negative
     */
    public long toTotalMonths() {
        return years * 12L + months;  // no overflow
    }

    //-------------------------------------------------------------------------
    /**
     * Adds this period to the specified temporal object.
     * !(p)
     * This returns a temporal object of the same observable type as the input
     * with this period added.
     * If the temporal has a chronology, it must be the ISO chronology.
     * !(p)
     * In most cases, it is clearer to reverse the calling pattern by using
     * {@link Temporal#plus(TemporalAmount)}.
     * !(pre)
     *   // these two lines are equivalent, but the second approach is recommended
     *   dateTime = thisPeriod.addTo(dateTime);
     *   dateTime = dateTime.plus(thisPeriod);
     * </pre>
     * !(p)
     * The calculation operates as follows.
     * First, the chronology of the temporal is checked to ensure it is ISO chronology or null.
     * Second, if the months are zero, the years are added if non-zero, otherwise
     * the combination of years and months is added if non-zero.
     * Finally, any days are added.
     * !(p)
     * This approach ensures that a partial period can be added to a partial date.
     * For example, a period of years and/or months can be added to a {@code YearMonth},
     * but a period including days cannot.
     * The approach also adds years and months together when necessary, which ensures
     * correct behaviour at the end of the month.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param temporal  the temporal object to adjust, not null
     * @return an object of the same type with the adjustment made, not null
     * @throws DateTimeException if unable to add
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    public Temporal addTo(Temporal temporal) {
        validateChrono(temporal);
        if (months == 0) {
            if (years != 0) {
                temporal = temporal.plus(years, ChronoUnit.YEARS);
            }
        } else {
            long totalMonths = toTotalMonths();
            if (totalMonths != 0) {
                temporal = temporal.plus(totalMonths, ChronoUnit.MONTHS);
            }
        }
        if (days != 0) {
            temporal = temporal.plus(days, ChronoUnit.DAYS);
        }
        return temporal;
    }

    /**
     * Subtracts this period from the specified temporal object.
     * !(p)
     * This returns a temporal object of the same observable type as the input
     * with this period subtracted.
     * If the temporal has a chronology, it must be the ISO chronology.
     * !(p)
     * In most cases, it is clearer to reverse the calling pattern by using
     * {@link Temporal#minus(TemporalAmount)}.
     * !(pre)
     *   // these two lines are equivalent, but the second approach is recommended
     *   dateTime = thisPeriod.subtractFrom(dateTime);
     *   dateTime = dateTime.minus(thisPeriod);
     * </pre>
     * !(p)
     * The calculation operates as follows.
     * First, the chronology of the temporal is checked to ensure it is ISO chronology or null.
     * Second, if the months are zero, the years are subtracted if non-zero, otherwise
     * the combination of years and months is subtracted if non-zero.
     * Finally, any days are subtracted.
     * !(p)
     * This approach ensures that a partial period can be subtracted from a partial date.
     * For example, a period of years and/or months can be subtracted from a {@code YearMonth},
     * but a period including days cannot.
     * The approach also subtracts years and months together when necessary, which ensures
     * correct behaviour at the end of the month.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param temporal  the temporal object to adjust, not null
     * @return an object of the same type with the adjustment made, not null
     * @throws DateTimeException if unable to subtract
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    public Temporal subtractFrom(Temporal temporal) {
        validateChrono(temporal);
        if (months == 0) {
            if (years != 0) {
                temporal = temporal.minus(years, ChronoUnit.YEARS);
            }
        } else {
            long totalMonths = toTotalMonths();
            if (totalMonths != 0) {
                temporal = temporal.minus(totalMonths, ChronoUnit.MONTHS);
            }
        }
        if (days != 0) {
            temporal = temporal.minus(days, ChronoUnit.DAYS);
        }
        return temporal;
    }

    /**
     * Validates that the temporal has the correct chronology.
     */
    private void validateChrono(TemporalAccessor temporal) {
        assert(temporal, "temporal");
        Chronology temporalChrono = QueryHelper.query!Chronology(temporal ,TemporalQueries.chronology());
        if (temporalChrono !is null && (IsoChronology.INSTANCE == temporalChrono) == false) {
            throw new DateTimeException("Chronology mismatch, expected: ISO, actual: " ~ temporalChrono.getId());
        }
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if this period is equal to another period.
     * !(p)
     * The comparison is based on the type {@code Period} and each of the three amounts.
     * To be equal, the years, months and days units must be individually equal.
     * Note that this means that a period of "15 Months" is not equal to a period
     * of "1 Year and 3 Months".
     *
     * @param obj  the object to check, null returns false
     * @return true if this is equal to the other period
     */
    override
    public bool opEquals(Object obj) {
        if (this is obj) {
            return true;
        }
        if (cast(Period)(obj) !is null) {
            Period other = cast(Period) obj;
            return years == other.years &&
                    months == other.months &&
                    days == other.days;
        }
        return false;
    }

    /**
     * A hash code for this period.
     *
     * @return a suitable hash code
     */
    override
    public size_t toHash() @trusted nothrow {
        try
        {
            return years + Integer.rotateLeft(months, 8) + Integer.rotateLeft(days, 16);
        }
        catch(Exception e){}
        return int.init;
    }

    //-----------------------------------------------------------------------
    /**
     * Outputs this period as a {@code string}, such as {@code P6Y3M1D}.
     * !(p)
     * The output will be _in the ISO-8601 period format.
     * A zero period will be represented as zero days, 'P0D'.
     *
     * @return a string representation of this period, not null
     */
    override
    public string toString() {
        if (this == ZERO) {
            return "P0D";
        } else {
            StringBuilder buf = new StringBuilder();
            buf.append('P');
            if (years != 0) {
                buf.append(years).append('Y');
            }
            if (months != 0) {
                buf.append(months).append('M');
            }
            if (days != 0) {
                buf.append(days).append('D');
            }
            return buf.toString();
        }
    }

    //-----------------------------------------------------------------------
    /**
     * Writes the object using a
     * <a href="{@docRoot}/serialized-form.html#hunt.time.Ser">dedicated serialized form</a>.
     * @serialData
     * !(pre)
     *  _out.writeByte(14);  // identifies a Period
     *  _out.writeInt(years);
     *  _out.writeInt(months);
     *  _out.writeInt(days);
     * </pre>
     *
     * @return the instance of {@code Ser}, not null
     */
    private Object writeReplace() {
        return new Ser(Ser.PERIOD_TYPE, this);
    }

    /**
     * Defend against malicious streams.
     *
     * @param s the stream to read
     * @throws java.io.InvalidObjectException always
     */
     ///@gxc
    // private void readObject(ObjectInputStream s) /*throws InvalidObjectException*/ {
    //     throw new InvalidObjectException("Deserialization via serialization delegate");
    // }

    void writeExternal(DataOutput _out) /*throws IOException*/ {
        _out.writeInt(years);
        _out.writeInt(months);
        _out.writeInt(days);
    }

    static Period readExternal(DataInput _in) /*throws IOException*/ {
        int years = _in.readInt();
        int months = _in.readInt();
        int days = _in.readInt();
        return Period.of(years, months, days);
    }

}
