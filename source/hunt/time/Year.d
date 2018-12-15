
module hunt.time.Year;

import hunt.time.temporal.ChronoField;
import hunt.time.temporal.ChronoUnit;

import hunt.io.DataInput;
import hunt.io.DataOutput;
import hunt.lang.exception;

//import hunt.io.ObjectInputStream;
import hunt.io.Serializable;
import hunt.time.chrono.Chronology;
import hunt.time.chrono.IsoChronology;
import hunt.time.format.DateTimeFormatter;
import hunt.time.format.DateTimeFormatterBuilder;
import hunt.time.format.DateTimeParseException;
import hunt.time.format.SignStyle;
import hunt.time.temporal.ChronoField;
import hunt.time.temporal.ChronoUnit;
import hunt.time.temporal.Temporal;
import hunt.time.temporal.TemporalAccessor;
import hunt.time.temporal.TemporalAdjuster;
import hunt.time.temporal.TemporalAmount;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.TemporalQueries;
import hunt.time.temporal.TemporalQuery;
import hunt.time.temporal.TemporalUnit;
import hunt.time.temporal.UnsupportedTemporalTypeException;
import hunt.time.temporal.ValueRange;
import hunt.lang.common;
import hunt.time.ZoneId;
import hunt.time.Clock;
import hunt.time.Month;
import hunt.time.MonthDay;
import hunt.time.LocalDate;
import hunt.time.YearMonth;
import hunt.time.DateTimeException;
import hunt.lang;
import hunt.time.Ser;
import std.conv;
import hunt.time.util.common;
/**
 * A year _in the ISO-8601 calendar system, such as {@code 2007}.
 * !(p)
 * {@code Year} is an immutable date-time object that represents a year.
 * Any field that can be derived from a year can be obtained.
 * !(p)
 * !(b)Note that years _in the ISO chronology only align with years _in the
 * Gregorian-Julian system for modern years. Parts of Russia did not switch to the
 * modern Gregorian/ISO rules until 1920.
 * As such, historical years must be treated with caution.</b>
 * !(p)
 * This class does not store or represent a month, day, time or time-zone.
 * For example, the value "2007" can be stored _in a {@code Year}.
 * !(p)
 * Years represented by this class follow the ISO-8601 standard and use
 * the proleptic numbering system. Year 1 is preceded by year 0, then by year -1.
 * !(p)
 * The ISO-8601 calendar system is the modern civil calendar system used today
 * _in most of the world. It is equivalent to the proleptic Gregorian calendar
 * system, _in which today's rules for leap years are applied for all time.
 * For most applications written today, the ISO-8601 rules are entirely suitable.
 * However, any application that makes use of historical dates, and requires them
 * to be accurate will find the ISO-8601 approach unsuitable.
 *
 * !(p)
 * This is a <a href="{@docRoot}/java.base/java/lang/doc-files/ValueBased.html">value-based</a>
 * class; use of identity-sensitive operations (including reference equality
 * ({@code ==}), identity hash code, or synchronization) on instances of
 * {@code Year} may have unpredictable results and should be avoided.
 * The {@code equals} method should be used for comparisons.
 *
 * @implSpec
 * This class is immutable and thread-safe.
 *
 * @since 1.8
 */
public final class Year
        : Temporal, TemporalAdjuster, Comparable!(Year), Serializable {

    /**
     * The minimum supported year, '-999,999,999'.
     */
    public enum int MIN_VALUE = -999_999_999;
    /**
     * The maximum supported year, '+999,999,999'.
     */
    public enum int MAX_VALUE = 999_999_999;

    /**
     * Serialization version.
     */
    private enum long serialVersionUID = -23038383694477807L;
    /**
     * Parser.
     */
     __gshared DateTimeFormatter _PARSER ;

     public static ref  DateTimeFormatter PARSER()
     {
         if(_PARSER is null)
         {
             _PARSER = new DateTimeFormatterBuilder()
            .appendValue(ChronoField.YEAR, 4, 10, SignStyle.EXCEEDS_PAD)
            .toFormatter();
         }
         return _PARSER;
     }

    // shared static this()
    // {
    //     PARSER = new DateTimeFormatterBuilder()
    //     .appendValue(ChronoField.YEAR, 4, 10, SignStyle.EXCEEDS_PAD)
    //     .toFormatter();
        // mixin(MakeGlobalVar!(DateTimeFormatter)("PARSER",`new DateTimeFormatterBuilder()
        // .appendValue(ChronoField.YEAR, 4, 10, SignStyle.EXCEEDS_PAD)
        // .toFormatter()`));
    // }

    /**
     * The year being represented.
     */
    private int year;

    //-----------------------------------------------------------------------
    /**
     * Obtains the current year from the system clock _in the default time-zone.
     * !(p)
     * This will query the {@link Clock#systemDefaultZone() system clock} _in the default
     * time-zone to obtain the current year.
     * !(p)
     * Using this method will prevent the ability to use an alternate clock for testing
     * because the clock is hard-coded.
     *
     * @return the current year using the system clock and default time-zone, not null
     */
    public static Year now() {
        return now(Clock.systemDefaultZone());
    }

    /**
     * Obtains the current year from the system clock _in the specified time-zone.
     * !(p)
     * This will query the {@link Clock#system(ZoneId) system clock} to obtain the current year.
     * Specifying the time-zone avoids dependence on the default time-zone.
     * !(p)
     * Using this method will prevent the ability to use an alternate clock for testing
     * because the clock is hard-coded.
     *
     * @param zone  the zone ID to use, not null
     * @return the current year using the system clock, not null
     */
    public static Year now(ZoneId zone) {
        return now(Clock.system(zone));
    }

    /**
     * Obtains the current year from the specified clock.
     * !(p)
     * This will query the specified clock to obtain the current year.
     * Using this method allows the use of an alternate clock for testing.
     * The alternate clock may be introduced using {@link Clock dependency injection}.
     *
     * @param clock  the clock to use, not null
     * @return the current year, not null
     */
    public static Year now(Clock clock) {
         LocalDate now = LocalDate.now(clock);  // called once
        return Year.of(now.getYear());
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code Year}.
     * !(p)
     * This method accepts a year value from the proleptic ISO calendar system.
     * !(p)
     * The year 2AD/CE is represented by 2.!(br)
     * The year 1AD/CE is represented by 1.!(br)
     * The year 1BC/BCE is represented by 0.!(br)
     * The year 2BC/BCE is represented by -1.!(br)
     *
     * @param isoYear  the ISO proleptic year to represent, from {@code MIN_VALUE} to {@code MAX_VALUE}
     * @return the year, not null
     * @throws DateTimeException if the field is invalid
     */
    public static Year of(int isoYear) {
        ChronoField.YEAR.checkValidValue(isoYear);
        return new Year(isoYear);
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code Year} from a temporal object.
     * !(p)
     * This obtains a year based on the specified temporal.
     * A {@code TemporalAccessor} represents an arbitrary set of date and time information,
     * which this factory converts to an instance of {@code Year}.
     * !(p)
     * The conversion extracts the {@link ChronoField#YEAR year} field.
     * The extraction is only permitted if the temporal object has an ISO
     * chronology, or can be converted to a {@code LocalDate}.
     * !(p)
     * This method matches the signature of the functional interface {@link TemporalQuery}
     * allowing it to be used as a query via method reference, {@code Year.from}.
     *
     * @param temporal  the temporal object to convert, not null
     * @return the year, not null
     * @throws DateTimeException if unable to convert to a {@code Year}
     */
    public static Year from(TemporalAccessor temporal) {
        if (cast(Year)(temporal) !is null) {
            return cast(Year) temporal;
        }
        assert(temporal, "temporal");
        try {
            if ((IsoChronology.INSTANCE == Chronology.from(temporal)) == false) {
                temporal = LocalDate.from(temporal);
            }
            return of(temporal.get(ChronoField.YEAR));
        } catch (DateTimeException ex) {
            throw new DateTimeException("Unable to obtain Year from TemporalAccessor: " ~
                    typeid(temporal).name ~ " of type " ~ typeid(temporal).stringof, ex);
        }
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code Year} from a text string such as {@code 2007}.
     * !(p)
     * The string must represent a valid year.
     * Years outside the range 0000 to 9999 must be prefixed by the plus or minus symbol.
     *
     * @param text  the text to parse such as "2007", not null
     * @return the parsed year, not null
     * @throws DateTimeParseException if the text cannot be parsed
     */
    public static Year parse(string text) {
        return parse(text, PARSER);
    }

    /**
     * Obtains an instance of {@code Year} from a text string using a specific formatter.
     * !(p)
     * The text is parsed using the formatter, returning a year.
     *
     * @param text  the text to parse, not null
     * @param formatter  the formatter to use, not null
     * @return the parsed year, not null
     * @throws DateTimeParseException if the text cannot be parsed
     */
    public static Year parse(string text, DateTimeFormatter formatter) {
        assert(formatter, "formatter");
        return formatter.parse(text, new class TemporalQuery!Year{
            Year queryFrom(TemporalAccessor temporal)
            {
                if (cast(Year)(temporal) !is null) {
                    return cast(Year) temporal;
                }
                assert(temporal, "temporal");
                try {
                    if ((IsoChronology.INSTANCE == Chronology.from(temporal)) == false) {
                        temporal = LocalDate.from(temporal);
                    }
                    return of(temporal.get(ChronoField.YEAR));
                } catch (DateTimeException ex) {
                    throw new DateTimeException("Unable to obtain Year from TemporalAccessor: " ~
                            typeid(temporal).name ~ " of type " ~ typeid(temporal).stringof, ex);
                }
            }
        });
    }

    //-------------------------------------------------------------------------
    /**
     * Checks if the year is a leap year, according to the ISO proleptic
     * calendar system rules.
     * !(p)
     * This method applies the current rules for leap years across the whole time-line.
     * In general, a year is a leap year if it is divisible by four without
     * remainder. However, years divisible by 100, are not leap years, with
     * the exception of years divisible by 400 which are.
     * !(p)
     * For example, 1904 is a leap year it is divisible by 4.
     * 1900 was not a leap year as it is divisible by 100, however 2000 was a
     * leap year as it is divisible by 400.
     * !(p)
     * The calculation is proleptic - applying the same rules into the far future and far past.
     * This is historically inaccurate, but is correct for the ISO-8601 standard.
     *
     * @param year  the year to check
     * @return true if the year is leap, false otherwise
     */
    public static bool isLeap(long year) {
        return ((year & 3) == 0) && ((year % 100) != 0 || (year % 400) == 0);
    }

    //-----------------------------------------------------------------------
    /**
     * Constructor.
     *
     * @param year  the year to represent
     */
    this(int year) {
        this.year = year;
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the year value.
     * !(p)
     * The year returned by this method is proleptic as per {@code get(YEAR)}.
     *
     * @return the year, {@code MIN_VALUE} to {@code MAX_VALUE}
     */
    public int getValue() {
        return year;
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if the specified field is supported.
     * !(p)
     * This checks if this year can be queried for the specified field.
     * If false, then calling the {@link #range(TemporalField) range},
     * {@link #get(TemporalField) get} and {@link #_with(TemporalField, long)}
     * methods will throw an exception.
     * !(p)
     * If the field is a {@link ChronoField} then the query is implemented here.
     * The supported fields are:
     * !(ul)
     * !(li){@code YEAR_OF_ERA}
     * !(li){@code YEAR}
     * !(li){@code ERA}
     * </ul>
     * All other {@code ChronoField} instances will return false.
     * !(p)
     * If the field is not a {@code ChronoField}, then the result of this method
     * is obtained by invoking {@code TemporalField.isSupportedBy(TemporalAccessor)}
     * passing {@code this} as the argument.
     * Whether the field is supported is determined by the field.
     *
     * @param field  the field to check, null returns false
     * @return true if the field is supported on this year, false if not
     */
    override
    public bool isSupported(TemporalField field) {
        if (cast(ChronoField)(field) !is null) {
            return field == ChronoField.YEAR || field == ChronoField.YEAR_OF_ERA || field == ChronoField.ERA;
        }
        return field !is null && field.isSupportedBy(this);
    }

    /**
     * Checks if the specified unit is supported.
     * !(p)
     * This checks if the specified unit can be added to, or subtracted from, this year.
     * If false, then calling the {@link #plus(long, TemporalUnit)} and
     * {@link #minus(long, TemporalUnit) minus} methods will throw an exception.
     * !(p)
     * If the unit is a {@link ChronoUnit} then the query is implemented here.
     * The supported units are:
     * !(ul)
     * !(li){@code YEARS}
     * !(li){@code DECADES}
     * !(li){@code CENTURIES}
     * !(li){@code MILLENNIA}
     * !(li){@code ERAS}
     * </ul>
     * All other {@code ChronoUnit} instances will return false.
     * !(p)
     * If the unit is not a {@code ChronoUnit}, then the result of this method
     * is obtained by invoking {@code TemporalUnit.isSupportedBy(Temporal)}
     * passing {@code this} as the argument.
     * Whether the unit is supported is determined by the unit.
     *
     * @param unit  the unit to check, null returns false
     * @return true if the unit can be added/subtracted, false if not
     */
    override
    public bool isSupported(TemporalUnit unit) {
        if (cast(ChronoUnit)(unit) !is null) {
            return unit == ChronoUnit.YEARS || unit == ChronoUnit.DECADES || unit == ChronoUnit.CENTURIES || unit == ChronoUnit.MILLENNIA || unit == ChronoUnit.ERAS;
        }
        return unit !is null && unit.isSupportedBy(this);
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the range of valid values for the specified field.
     * !(p)
     * The range object expresses the minimum and maximum valid values for a field.
     * This year is used to enhance the accuracy of the returned range.
     * If it is not possible to return the range, because the field is not supported
     * or for some other reason, an exception is thrown.
     * !(p)
     * If the field is a {@link ChronoField} then the query is implemented here.
     * The {@link #isSupported(TemporalField) supported fields} will return
     * appropriate range instances.
     * All other {@code ChronoField} instances will throw an {@code UnsupportedTemporalTypeException}.
     * !(p)
     * If the field is not a {@code ChronoField}, then the result of this method
     * is obtained by invoking {@code TemporalField.rangeRefinedBy(TemporalAccessor)}
     * passing {@code this} as the argument.
     * Whether the range can be obtained is determined by the field.
     *
     * @param field  the field to query the range for, not null
     * @return the range of valid values for the field, not null
     * @throws DateTimeException if the range for the field cannot be obtained
     * @throws UnsupportedTemporalTypeException if the field is not supported
     */
    override
    public ValueRange range(TemporalField field) {
        if (field == ChronoField.YEAR_OF_ERA) {
            return (year <= 0 ? ValueRange.of(1, MAX_VALUE + 1) : ValueRange.of(1, MAX_VALUE));
        }
        return /* Temporal. super.*/super_range(field);
        
    }
    ValueRange super_range(TemporalField field) {
        if (cast(ChronoField)(field) !is null) {
            if (isSupported(field)) {
                return field.range();
            }
            throw new UnsupportedTemporalTypeException("Unsupported field: " ~ typeid(field).name);
        }
        assert(field, "field");
        return field.rangeRefinedBy(this);
    }
    /**
     * Gets the value of the specified field from this year as an {@code int}.
     * !(p)
     * This queries this year for the value of the specified field.
     * The returned value will always be within the valid range of values for the field.
     * If it is not possible to return the value, because the field is not supported
     * or for some other reason, an exception is thrown.
     * !(p)
     * If the field is a {@link ChronoField} then the query is implemented here.
     * The {@link #isSupported(TemporalField) supported fields} will return valid
     * values based on this year.
     * All other {@code ChronoField} instances will throw an {@code UnsupportedTemporalTypeException}.
     * !(p)
     * If the field is not a {@code ChronoField}, then the result of this method
     * is obtained by invoking {@code TemporalField.getFrom(TemporalAccessor)}
     * passing {@code this} as the argument. Whether the value can be obtained,
     * and what the value represents, is determined by the field.
     *
     * @param field  the field to get, not null
     * @return the value for the field
     * @throws DateTimeException if a value for the field cannot be obtained or
     *         the value is outside the range of valid values for the field
     * @throws UnsupportedTemporalTypeException if the field is not supported or
     *         the range of values exceeds an {@code int}
     * @throws ArithmeticException if numeric overflow occurs
     */
    override  // override for Javadoc
    public int get(TemporalField field) {
        return range(field).checkValidIntValue(getLong(field), field);
    }

    /**
     * Gets the value of the specified field from this year as a {@code long}.
     * !(p)
     * This queries this year for the value of the specified field.
     * If it is not possible to return the value, because the field is not supported
     * or for some other reason, an exception is thrown.
     * !(p)
     * If the field is a {@link ChronoField} then the query is implemented here.
     * The {@link #isSupported(TemporalField) supported fields} will return valid
     * values based on this year.
     * All other {@code ChronoField} instances will throw an {@code UnsupportedTemporalTypeException}.
     * !(p)
     * If the field is not a {@code ChronoField}, then the result of this method
     * is obtained by invoking {@code TemporalField.getFrom(TemporalAccessor)}
     * passing {@code this} as the argument. Whether the value can be obtained,
     * and what the value represents, is determined by the field.
     *
     * @param field  the field to get, not null
     * @return the value for the field
     * @throws DateTimeException if a value for the field cannot be obtained
     * @throws UnsupportedTemporalTypeException if the field is not supported
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    public long getLong(TemporalField field) {
        if (cast(ChronoField)(field) !is null) {
            auto f = cast(ChronoField) field;
            {
                if ( f ==  ChronoField.YEAR_OF_ERA) return (year < 1 ? 1 - year : year);
                if ( f ==  ChronoField.YEAR) return year;
                if ( f ==  ChronoField.ERA) return (year < 1 ? 0 : 1);
            }
            throw new UnsupportedTemporalTypeException("Unsupported field: " ~ f.toString);
        }
        return field.getFrom(this);
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if the year is a leap year, according to the ISO proleptic
     * calendar system rules.
     * !(p)
     * This method applies the current rules for leap years across the whole time-line.
     * In general, a year is a leap year if it is divisible by four without
     * remainder. However, years divisible by 100, are not leap years, with
     * the exception of years divisible by 400 which are.
     * !(p)
     * For example, 1904 is a leap year it is divisible by 4.
     * 1900 was not a leap year as it is divisible by 100, however 2000 was a
     * leap year as it is divisible by 400.
     * !(p)
     * The calculation is proleptic - applying the same rules into the far future and far past.
     * This is historically inaccurate, but is correct for the ISO-8601 standard.
     *
     * @return true if the year is leap, false otherwise
     */
    public bool isLeap() {
        return Year.isLeap(year);
    }

    /**
     * Checks if the month-day is valid for this year.
     * !(p)
     * This method checks whether this year and the input month and day form
     * a valid date.
     *
     * @param monthDay  the month-day to validate, null returns false
     * @return true if the month and day are valid for this year
     */
    public bool isValidMonthDay(MonthDay monthDay) {
        return monthDay !is null && monthDay.isValidYear(year);
    }

    /**
     * Gets the length of this year _in days.
     *
     * @return the length of this year _in days, 365 or 366
     */
    public int length() {
        return isLeap() ? 366 : 365;
    }

    //-----------------------------------------------------------------------
    /**
     * Returns an adjusted copy of this year.
     * !(p)
     * This returns a {@code Year}, based on this one, with the year adjusted.
     * The adjustment takes place using the specified adjuster strategy object.
     * Read the documentation of the adjuster to understand what adjustment will be made.
     * !(p)
     * The result of this method is obtained by invoking the
     * {@link TemporalAdjuster#adjustInto(Temporal)} method on the
     * specified adjuster passing {@code this} as the argument.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param adjuster the adjuster to use, not null
     * @return a {@code Year} based on {@code this} with the adjustment made, not null
     * @throws DateTimeException if the adjustment cannot be made
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    public Year _with(TemporalAdjuster adjuster) {
        return cast(Year) adjuster.adjustInto(this);
    }

    /**
     * Returns a copy of this year with the specified field set to a new value.
     * !(p)
     * This returns a {@code Year}, based on this one, with the value
     * for the specified field changed.
     * If it is not possible to set the value, because the field is not supported or for
     * some other reason, an exception is thrown.
     * !(p)
     * If the field is a {@link ChronoField} then the adjustment is implemented here.
     * The supported fields behave as follows:
     * !(ul)
     * !(li){@code YEAR_OF_ERA} -
     *  Returns a {@code Year} with the specified year-of-era
     *  The era will be unchanged.
     * !(li){@code YEAR} -
     *  Returns a {@code Year} with the specified year.
     *  This completely replaces the date and is equivalent to {@link #of(int)}.
     * !(li){@code ERA} -
     *  Returns a {@code Year} with the specified era.
     *  The year-of-era will be unchanged.
     * </ul>
     * !(p)
     * In all cases, if the new value is outside the valid range of values for the field
     * then a {@code DateTimeException} will be thrown.
     * !(p)
     * All other {@code ChronoField} instances will throw an {@code UnsupportedTemporalTypeException}.
     * !(p)
     * If the field is not a {@code ChronoField}, then the result of this method
     * is obtained by invoking {@code TemporalField.adjustInto(Temporal, long)}
     * passing {@code this} as the argument. In this case, the field determines
     * whether and how to adjust the instant.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param field  the field to set _in the result, not null
     * @param newValue  the new value of the field _in the result
     * @return a {@code Year} based on {@code this} with the specified field set, not null
     * @throws DateTimeException if the field cannot be set
     * @throws UnsupportedTemporalTypeException if the field is not supported
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    public Year _with(TemporalField field, long newValue) {
        if (cast(ChronoField)(field) !is null) {
            ChronoField f = cast(ChronoField) field;
            f.checkValidValue(newValue);
            {
                if( f == ChronoField.YEAR_OF_ERA) return Year.of(cast(int) (year < 1 ? 1 - newValue : newValue));
                if( f == ChronoField.YEAR) return Year.of(cast(int) newValue);
                if( f == ChronoField.ERA) return (getLong(ChronoField.ERA) == newValue ? this : Year.of(1 - year));
            }
            throw new UnsupportedTemporalTypeException("Unsupported field: " ~ f.toString);
        }
        return cast(Year)(field.adjustInto(this, newValue));
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this year with the specified amount added.
     * !(p)
     * This returns a {@code Year}, based on this one, with the specified amount added.
     * The amount is typically {@link Period} but may be any other type implementing
     * the {@link TemporalAmount} interface.
     * !(p)
     * The calculation is delegated to the amount object by calling
     * {@link TemporalAmount#addTo(Temporal)}. The amount implementation is free
     * to implement the addition _in any way it wishes, however it typically
     * calls back to {@link #plus(long, TemporalUnit)}. Consult the documentation
     * of the amount implementation to determine if it can be successfully added.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param amountToAdd  the amount to add, not null
     * @return a {@code Year} based on this year with the addition made, not null
     * @throws DateTimeException if the addition cannot be made
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    public Year plus(TemporalAmount amountToAdd) {
        return cast(Year) amountToAdd.addTo(this);
    }

    /**
     * Returns a copy of this year with the specified amount added.
     * !(p)
     * This returns a {@code Year}, based on this one, with the amount
     * _in terms of the unit added. If it is not possible to add the amount, because the
     * unit is not supported or for some other reason, an exception is thrown.
     * !(p)
     * If the field is a {@link ChronoUnit} then the addition is implemented here.
     * The supported fields behave as follows:
     * !(ul)
     * !(li){@code YEARS} -
     *  Returns a {@code Year} with the specified number of years added.
     *  This is equivalent to {@link #plusYears(long)}.
     * !(li){@code DECADES} -
     *  Returns a {@code Year} with the specified number of decades added.
     *  This is equivalent to calling {@link #plusYears(long)} with the amount
     *  multiplied by 10.
     * !(li){@code CENTURIES} -
     *  Returns a {@code Year} with the specified number of centuries added.
     *  This is equivalent to calling {@link #plusYears(long)} with the amount
     *  multiplied by 100.
     * !(li){@code MILLENNIA} -
     *  Returns a {@code Year} with the specified number of millennia added.
     *  This is equivalent to calling {@link #plusYears(long)} with the amount
     *  multiplied by 1,000.
     * !(li){@code ERAS} -
     *  Returns a {@code Year} with the specified number of eras added.
     *  Only two eras are supported so the amount must be one, zero or minus one.
     *  If the amount is non-zero then the year is changed such that the year-of-era
     *  is unchanged.
     * </ul>
     * !(p)
     * All other {@code ChronoUnit} instances will throw an {@code UnsupportedTemporalTypeException}.
     * !(p)
     * If the field is not a {@code ChronoUnit}, then the result of this method
     * is obtained by invoking {@code TemporalUnit.addTo(Temporal, long)}
     * passing {@code this} as the argument. In this case, the unit determines
     * whether and how to perform the addition.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param amountToAdd  the amount of the unit to add to the result, may be negative
     * @param unit  the unit of the amount to add, not null
     * @return a {@code Year} based on this year with the specified amount added, not null
     * @throws DateTimeException if the addition cannot be made
     * @throws UnsupportedTemporalTypeException if the unit is not supported
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    public Year plus(long amountToAdd, TemporalUnit unit) {
        if (cast(ChronoUnit)(unit) !is null) {
            auto f = cast(ChronoUnit) unit;
            {
                if( f == ChronoUnit.YEARS) return plusYears(amountToAdd);
                if( f == ChronoUnit.DECADES) return plusYears(Math.multiplyExact(amountToAdd, 10));
                if( f == ChronoUnit.CENTURIES) return plusYears(Math.multiplyExact(amountToAdd, 100));
                if( f == ChronoUnit.MILLENNIA) return plusYears(Math.multiplyExact(amountToAdd, 1000));
                if( f == ChronoUnit.ERAS) return _with(ChronoField.ERA, Math.addExact(getLong(ChronoField.ERA), amountToAdd));
            }
            throw new UnsupportedTemporalTypeException("Unsupported unit: " ~ f.toString);
        }
        return cast(Year)(unit.addTo(this, amountToAdd));
    }

    /**
     * Returns a copy of this {@code Year} with the specified number of years added.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param yearsToAdd  the years to add, may be negative
     * @return a {@code Year} based on this year with the years added, not null
     * @throws DateTimeException if the result exceeds the supported range
     */
    public Year plusYears(long yearsToAdd) {
        if (yearsToAdd == 0) {
            return this;
        }
        return of(ChronoField.YEAR.checkValidIntValue(year + yearsToAdd));  // overflow safe
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this year with the specified amount subtracted.
     * !(p)
     * This returns a {@code Year}, based on this one, with the specified amount subtracted.
     * The amount is typically {@link Period} but may be any other type implementing
     * the {@link TemporalAmount} interface.
     * !(p)
     * The calculation is delegated to the amount object by calling
     * {@link TemporalAmount#subtractFrom(Temporal)}. The amount implementation is free
     * to implement the subtraction _in any way it wishes, however it typically
     * calls back to {@link #minus(long, TemporalUnit)}. Consult the documentation
     * of the amount implementation to determine if it can be successfully subtracted.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param amountToSubtract  the amount to subtract, not null
     * @return a {@code Year} based on this year with the subtraction made, not null
     * @throws DateTimeException if the subtraction cannot be made
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    public Year minus(TemporalAmount amountToSubtract) {
        return cast(Year) amountToSubtract.subtractFrom(this);
    }

    /**
     * Returns a copy of this year with the specified amount subtracted.
     * !(p)
     * This returns a {@code Year}, based on this one, with the amount
     * _in terms of the unit subtracted. If it is not possible to subtract the amount,
     * because the unit is not supported or for some other reason, an exception is thrown.
     * !(p)
     * This method is equivalent to {@link #plus(long, TemporalUnit)} with the amount negated.
     * See that method for a full description of how addition, and thus subtraction, works.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param amountToSubtract  the amount of the unit to subtract from the result, may be negative
     * @param unit  the unit of the amount to subtract, not null
     * @return a {@code Year} based on this year with the specified amount subtracted, not null
     * @throws DateTimeException if the subtraction cannot be made
     * @throws UnsupportedTemporalTypeException if the unit is not supported
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    public Year minus(long amountToSubtract, TemporalUnit unit) {
        return (amountToSubtract == Long.MIN_VALUE ? plus(Long.MAX_VALUE, unit).plus(1, unit) : plus(-amountToSubtract, unit));
    }

    /**
     * Returns a copy of this {@code Year} with the specified number of years subtracted.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param yearsToSubtract  the years to subtract, may be negative
     * @return a {@code Year} based on this year with the year subtracted, not null
     * @throws DateTimeException if the result exceeds the supported range
     */
    public Year minusYears(long yearsToSubtract) {
        return (yearsToSubtract == Long.MIN_VALUE ? plusYears(Long.MAX_VALUE).plusYears(1) : plusYears(-yearsToSubtract));
    }

    //-----------------------------------------------------------------------
    /**
     * Queries this year using the specified query.
     * !(p)
     * This queries this year using the specified query strategy object.
     * The {@code TemporalQuery} object defines the logic to be used to
     * obtain the result. Read the documentation of the query to understand
     * what the result of this method will be.
     * !(p)
     * The result of this method is obtained by invoking the
     * {@link TemporalQuery#queryFrom(TemporalAccessor)} method on the
     * specified query passing {@code this} as the argument.
     *
     * @param !(R) the type of the result
     * @param query  the query to invoke, not null
     * @return the query result, null may be returned (defined by the query)
     * @throws DateTimeException if unable to query (defined by the query)
     * @throws ArithmeticException if numeric overflow occurs (defined by the query)
     */
    /*@SuppressWarnings("unchecked")*/
    // override
    public R query(R)(TemporalQuery!(R) query) {
        if (query == TemporalQueries.chronology()) {
            return cast(R) IsoChronology.INSTANCE;
        } else if (query == TemporalQueries.precision()) {
            return cast(R) (ChronoUnit.YEARS);
        }
        return /* Temporal. */super_query(query);
    }
    R super_query(R)(TemporalQuery!(R) query) {
         if (query == TemporalQueries.zoneId()
                 || query == TemporalQueries.chronology()
                 || query == TemporalQueries.precision()) {
             return null;
         }
         return query.queryFrom(this);
     }

    /**
     * Adjusts the specified temporal object to have this year.
     * !(p)
     * This returns a temporal object of the same observable type as the input
     * with the year changed to be the same as this.
     * !(p)
     * The adjustment is equivalent to using {@link Temporal#_with(TemporalField, long)}
     * passing {@link ChronoField#YEAR} as the field.
     * If the specified temporal object does not use the ISO calendar system then
     * a {@code DateTimeException} is thrown.
     * !(p)
     * In most cases, it is clearer to reverse the calling pattern by using
     * {@link Temporal#_with(TemporalAdjuster)}:
     * !(pre)
     *   // these two lines are equivalent, but the second approach is recommended
     *   temporal = thisYear.adjustInto(temporal);
     *   temporal = temporal._with(thisYear);
     * </pre>
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param temporal  the target object to be adjusted, not null
     * @return the adjusted object, not null
     * @throws DateTimeException if unable to make the adjustment
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    public Temporal adjustInto(Temporal temporal) {
        if ((Chronology.from(temporal) == IsoChronology.INSTANCE) == false) {
            throw new DateTimeException("Adjustment only supported on ISO date-time");
        }
        return temporal._with(ChronoField.YEAR, year);
    }

    /**
     * Calculates the amount of time until another year _in terms of the specified unit.
     * !(p)
     * This calculates the amount of time between two {@code Year}
     * objects _in terms of a single {@code TemporalUnit}.
     * The start and end points are {@code this} and the specified year.
     * The result will be negative if the end is before the start.
     * The {@code Temporal} passed to this method is converted to a
     * {@code Year} using {@link #from(TemporalAccessor)}.
     * For example, the amount _in decades between two year can be calculated
     * using {@code startYear.until(endYear, DECADES)}.
     * !(p)
     * The calculation returns a whole number, representing the number of
     * complete units between the two years.
     * For example, the amount _in decades between 2012 and 2031
     * will only be one decade as it is one year short of two decades.
     * !(p)
     * There are two equivalent ways of using this method.
     * The first is to invoke this method.
     * The second is to use {@link TemporalUnit#between(Temporal, Temporal)}:
     * !(pre)
     *   // these two lines are equivalent
     *   amount = start.until(end, YEARS);
     *   amount = YEARS.between(start, end);
     * </pre>
     * The choice should be made based on which makes the code more readable.
     * !(p)
     * The calculation is implemented _in this method for {@link ChronoUnit}.
     * The units {@code YEARS}, {@code DECADES}, {@code CENTURIES},
     * {@code MILLENNIA} and {@code ERAS} are supported.
     * Other {@code ChronoUnit} values will throw an exception.
     * !(p)
     * If the unit is not a {@code ChronoUnit}, then the result of this method
     * is obtained by invoking {@code TemporalUnit.between(Temporal, Temporal)}
     * passing {@code this} as the first argument and the converted input temporal
     * as the second argument.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param endExclusive  the end date, exclusive, which is converted to a {@code Year}, not null
     * @param unit  the unit to measure the amount _in, not null
     * @return the amount of time between this year and the end year
     * @throws DateTimeException if the amount cannot be calculated, or the end
     *  temporal cannot be converted to a {@code Year}
     * @throws UnsupportedTemporalTypeException if the unit is not supported
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    public long until(Temporal endExclusive, TemporalUnit unit) {
        Year end = Year.from(endExclusive);
        if (cast(ChronoUnit)(unit) !is null) {
            long yearsUntil = (cast(long) end.year) - year;  // no overflow
            auto f = cast(ChronoUnit) unit;
            {
                if ( f == ChronoUnit.YEARS) return yearsUntil;
                if ( f == ChronoUnit.DECADES) return yearsUntil / 10;
                if ( f == ChronoUnit.CENTURIES) return yearsUntil / 100;
                if ( f == ChronoUnit.MILLENNIA) return yearsUntil / 1000;
                if ( f == ChronoUnit.ERAS) return end.getLong(ChronoField.ERA) - getLong(ChronoField.ERA);
            }
            throw new UnsupportedTemporalTypeException("Unsupported unit: " ~ f.toString);
        }
        return unit.between(this, end);
    }

    /**
     * Formats this year using the specified formatter.
     * !(p)
     * This year will be passed to the formatter to produce a string.
     *
     * @param formatter  the formatter to use, not null
     * @return the formatted year string, not null
     * @throws DateTimeException if an error occurs during printing
     */
    public string format(DateTimeFormatter formatter) {
        assert(formatter, "formatter");
        return formatter.format(this);
    }

    //-----------------------------------------------------------------------
    /**
     * Combines this year with a day-of-year to create a {@code LocalDate}.
     * !(p)
     * This returns a {@code LocalDate} formed from this year and the specified day-of-year.
     * !(p)
     * The day-of-year value 366 is only valid _in a leap year.
     *
     * @param dayOfYear  the day-of-year to use, from 1 to 365-366
     * @return the local date formed from this year and the specified date of year, not null
     * @throws DateTimeException if the day of year is zero or less, 366 or greater or equal
     *  to 366 and this is not a leap year
     */
    public LocalDate atDay(int dayOfYear) {
        return LocalDate.ofYearDay(year, dayOfYear);
    }

    /**
     * Combines this year with a month to create a {@code YearMonth}.
     * !(p)
     * This returns a {@code YearMonth} formed from this year and the specified month.
     * All possible combinations of year and month are valid.
     * !(p)
     * This method can be used as part of a chain to produce a date:
     * !(pre)
     *  LocalDate date = year.atMonth(month).atDay(day);
     * </pre>
     *
     * @param month  the month-of-year to use, not null
     * @return the year-month formed from this year and the specified month, not null
     */
    public YearMonth atMonth(Month month) {
        return YearMonth.of(year, month);
    }

    /**
     * Combines this year with a month to create a {@code YearMonth}.
     * !(p)
     * This returns a {@code YearMonth} formed from this year and the specified month.
     * All possible combinations of year and month are valid.
     * !(p)
     * This method can be used as part of a chain to produce a date:
     * !(pre)
     *  LocalDate date = year.atMonth(month).atDay(day);
     * </pre>
     *
     * @param month  the month-of-year to use, from 1 (January) to 12 (December)
     * @return the year-month formed from this year and the specified month, not null
     * @throws DateTimeException if the month is invalid
     */
    public YearMonth atMonth(int month) {
        return YearMonth.of(year, month);
    }

    /**
     * Combines this year with a month-day to create a {@code LocalDate}.
     * !(p)
     * This returns a {@code LocalDate} formed from this year and the specified month-day.
     * !(p)
     * A month-day of February 29th will be adjusted to February 28th _in the resulting
     * date if the year is not a leap year.
     *
     * @param monthDay  the month-day to use, not null
     * @return the local date formed from this year and the specified month-day, not null
     */
    public LocalDate atMonthDay(MonthDay monthDay) {
        return monthDay.atYear(year);
    }

    //-----------------------------------------------------------------------
    /**
     * Compares this year to another year.
     * !(p)
     * The comparison is based on the value of the year.
     * It is "consistent with equals", as defined by {@link Comparable}.
     *
     * @param other  the other year to compare to, not null
     * @return the comparator value, negative if less, positive if greater
     */
    // override
    public int compareTo(Year other) {
        return year - other.year;
    }

    /**
     * Checks if this year is after the specified year.
     *
     * @param other  the other year to compare to, not null
     * @return true if this is after the specified year
     */
    public bool isAfter(Year other) {
        return year > other.year;
    }

    /**
     * Checks if this year is before the specified year.
     *
     * @param other  the other year to compare to, not null
     * @return true if this point is before the specified year
     */
    public bool isBefore(Year other) {
        return year < other.year;
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if this year is equal to another year.
     * !(p)
     * The comparison is based on the time-line position of the years.
     *
     * @param obj  the object to check, null returns false
     * @return true if this is equal to the other year
     */
    override
    public bool opEquals(Object obj) {
        if (this is obj) {
            return true;
        }
        if (cast(Year)(obj) !is null) {
            return year == (cast(Year) obj).year;
        }
        return false;
    }

    /**
     * A hash code for this year.
     *
     * @return a suitable hash code
     */
    override
    public size_t toHash() @trusted nothrow {
        return year;
    }

    //-----------------------------------------------------------------------
    /**
     * Outputs this year as a {@code string}.
     *
     * @return a string representation of this year, not null
     */
    override
    public string toString() {
        return to!string(year);
    }

    //-----------------------------------------------------------------------
    /**
     * Writes the object using a
     * <a href="{@docRoot}/serialized-form.html#hunt.time.Ser">dedicated serialized form</a>.
     * @serialData
     * !(pre)
     *  _out.writeByte(11);  // identifies a Year
     *  _out.writeInt(year);
     * </pre>
     *
     * @return the instance of {@code Ser}, not null
     */
    private Object writeReplace() {
        return new Ser(Ser.YEAR_TYPE, this);
    }

    /**
     * Defend against malicious streams.
     *
     * @param s the stream to read
     * @throws InvalidObjectException= always
     */
     ///@gxc
    // private void readObject(ObjectInputStream s) /*throws InvalidObjectException*/ {
    //     throw new InvalidObjectException("Deserialization via serialization delegate");
    // }

    void writeExternal(DataOutput _out) /*throws IOException*/ {
        _out.writeInt(year);
    }

    static Year readExternal(DataInput _in) /*throws IOException*/ {
        return Year.of(_in.readInt());
    }

    override 
    int opCmp(Year o)
    {
        return compareTo(o);
    }
}
