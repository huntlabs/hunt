
module hunt.time.chrono.IsoChronology;

import hunt.time.temporal.ChronoField;


import std.conv;
import hunt.io.common;
import hunt.time.Clock;
import hunt.time.DateTimeException;
import hunt.time.Instant;
import hunt.time.LocalDate;
import hunt.time.LocalDateTime;
import hunt.time.Month;
import hunt.time.Period;
import hunt.time.Year;
import hunt.time.ZonedDateTime;
import hunt.time.ZoneId;
import hunt.time.ZoneOffset;
import hunt.time.format.ResolverStyle;
import hunt.time.format.TextStyle;
import hunt.time.format.DateTimeFormatterBuilder;
import hunt.time.temporal.ChronoField;
import hunt.time.temporal.TemporalAccessor;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.ValueRange;
import hunt.time.temporal.TemporalQuery;
import hunt.time.temporal.UnsupportedTemporalTypeException;
import hunt.container.List;
import hunt.time.util.Locale;
import hunt.container.Map;
import hunt.time.chrono.AbstractChronology;
import hunt.time.chrono.Era;
import hunt.time.chrono.IsoEra;
import hunt.time.chrono.Chronology;
import hunt.time.chrono.ChronoLocalDateTime;
import hunt.time.chrono.ChronoLocalDateTimeImpl;
import hunt.time.chrono.ChronoZonedDateTime;
import hunt.time.chrono.ChronoZonedDateTimeImpl;
import hunt.time.chrono.ChronoLocalDate;
import hunt.lang;
import hunt.lang.exception;
import hunt.container;
import hunt.util.Comparator;
import hunt.time.LocalTime;
import hunt.time.util.QueryHelper;
import hunt.time.util.common;
/**
 * The ISO calendar system.
 * !(p)
 * This chronology defines the rules of the ISO calendar system.
 * This calendar system is based on the ISO-8601 standard, which is the
 * !(i)de facto</i> world calendar.
 * !(p)
 * The fields are defined as follows:
 * !(ul)
 * !(li)era - There are two eras, 'Current Era' (CE) and 'Before Current Era' (BCE).
 * !(li)year-of-era - The year-of-era is the same as the proleptic-year for the current CE era.
 *  For the BCE era before the ISO epoch the year increases from 1 upwards as time goes backwards.
 * !(li)proleptic-year - The proleptic year is the same as the year-of-era for the
 *  current era. For the previous era, years have zero, then negative values.
 * !(li)month-of-year - There are 12 months _in an ISO year, numbered from 1 to 12.
 * !(li)day-of-month - There are between 28 and 31 days _in each of the ISO month, numbered from 1 to 31.
 *  Months 4, 6, 9 and 11 have 30 days, Months 1, 3, 5, 7, 8, 10 and 12 have 31 days.
 *  Month 2 has 28 days, or 29 _in a leap year.
 * !(li)day-of-year - There are 365 days _in a standard ISO year and 366 _in a leap year.
 *  The days are numbered from 1 to 365 or 1 to 366.
 * !(li)leap-year - Leap years occur every 4 years, except where the year is divisble by 100 and not divisble by 400.
 * </ul>
 *
 * @implSpec
 * This class is immutable and thread-safe.
 *
 * @since 1.8
 */
public final class IsoChronology : AbstractChronology , Serializable {

    /**
     * Singleton instance of the ISO chronology.
     */
    // public __gshared IsoChronology INSTANCE;

    /**
     * Serialization version.
     */
    private enum long serialVersionUID = -1440403870442975015L;

    private enum long DAYS_0000_TO_1970 = (146097 * 5L) - (30L * 365L + 7L); // taken from LocalDate

    // shared static this()
    // {
    //     INSTANCE = new IsoChronology();
        mixin(MakeGlobalVar!(IsoChronology)("INSTANCE",`new IsoChronology()`));
    // }
    /**
     * Restricted constructor.
     */
     this() {
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the ID of the chronology - 'ISO'.
     * !(p)
     * The ID uniquely identifies the {@code Chronology}.
     * It can be used to lookup the {@code Chronology} using {@link Chronology#of(string)}.
     *
     * @return the chronology ID - 'ISO'
     * @see #getCalendarType()
     */
    // override
    public string getId() {
        return "ISO";
    }

    /**
     * Gets the calendar type of the underlying calendar system - 'iso8601'.
     * !(p)
     * The calendar type is an identifier defined by the
     * !(em)Unicode Locale Data Markup Language (LDML)</em> specification.
     * It can be used to lookup the {@code Chronology} using {@link Chronology#of(string)}.
     * It can also be used as part of a locale, accessible via
     * {@link Locale#getUnicodeLocaleType(string)} with the key 'ca'.
     *
     * @return the calendar system type - 'iso8601'
     * @see #getId()
     */
    // override
    public string getCalendarType() {
        return "iso8601";
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an ISO local date from the era, year-of-era, month-of-year
     * and day-of-month fields.
     *
     * @param era  the ISO era, not null
     * @param yearOfEra  the ISO year-of-era
     * @param month  the ISO month-of-year
     * @param dayOfMonth  the ISO day-of-month
     * @return the ISO local date, not null
     * @throws DateTimeException if unable to create the date
     * @throws ClassCastException if the type of {@code era} is not {@code IsoEra}
     */
    // override  // override with covariant return type
    public LocalDate date(Era era, int yearOfEra, int month, int dayOfMonth) {
        return date(prolepticYear(era, yearOfEra), month, dayOfMonth);
    }

    /**
     * Obtains an ISO local date from the proleptic-year, month-of-year
     * and day-of-month fields.
     * !(p)
     * This is equivalent to {@link LocalDate#of(int, int, int)}.
     *
     * @param prolepticYear  the ISO proleptic-year
     * @param month  the ISO month-of-year
     * @param dayOfMonth  the ISO day-of-month
     * @return the ISO local date, not null
     * @throws DateTimeException if unable to create the date
     */
    // override  // override with covariant return type
    public LocalDate date(int prolepticYear, int month, int dayOfMonth) {
        return LocalDate.of(prolepticYear, month, dayOfMonth);
    }

    /**
     * Obtains an ISO local date from the era, year-of-era and day-of-year fields.
     *
     * @param era  the ISO era, not null
     * @param yearOfEra  the ISO year-of-era
     * @param dayOfYear  the ISO day-of-year
     * @return the ISO local date, not null
     * @throws DateTimeException if unable to create the date
     */
    // override  // override with covariant return type
    public LocalDate dateYearDay(Era era, int yearOfEra, int dayOfYear) {
        return dateYearDay(prolepticYear(era, yearOfEra), dayOfYear);
    }

    /**
     * Obtains an ISO local date from the proleptic-year and day-of-year fields.
     * !(p)
     * This is equivalent to {@link LocalDate#ofYearDay(int, int)}.
     *
     * @param prolepticYear  the ISO proleptic-year
     * @param dayOfYear  the ISO day-of-year
     * @return the ISO local date, not null
     * @throws DateTimeException if unable to create the date
     */
    // override  // override with covariant return type
    public LocalDate dateYearDay(int prolepticYear, int dayOfYear) {
        return LocalDate.ofYearDay(prolepticYear, dayOfYear);
    }

    /**
     * Obtains an ISO local date from the epoch-day.
     * !(p)
     * This is equivalent to {@link LocalDate#ofEpochDay(long)}.
     *
     * @param epochDay  the epoch day
     * @return the ISO local date, not null
     * @throws DateTimeException if unable to create the date
     */
    // override  // override with covariant return type
    public LocalDate dateEpochDay(long epochDay) {
        return LocalDate.ofEpochDay(epochDay);
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an ISO local date from another date-time object.
     * !(p)
     * This is equivalent to {@link LocalDate#from(TemporalAccessor)}.
     *
     * @param temporal  the date-time object to convert, not null
     * @return the ISO local date, not null
     * @throws DateTimeException if unable to create the date
     */
    // override  // override with covariant return type
    public LocalDate date(TemporalAccessor temporal) {
        return LocalDate.from(temporal);
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the number of seconds from the epoch of 1970-01-01T00:00:00Z.
     * !(p)
     * The number of seconds is calculated using the year,
     * month, day-of-month, hour, minute, second, and zoneOffset.
     *
     * @param prolepticYear  the year, from MIN_YEAR to MAX_YEAR
     * @param month  the month-of-year, from 1 to 12
     * @param dayOfMonth  the day-of-month, from 1 to 31
     * @param hour  the hour-of-day, from 0 to 23
     * @param minute  the minute-of-hour, from 0 to 59
     * @param second  the second-of-minute, from 0 to 59
     * @param zoneOffset the zone offset, not null
     * @return the number of seconds relative to 1970-01-01T00:00:00Z, may be negative
     * @throws DateTimeException if the value of any argument is _out of range,
     *         or if the day-of-month is invalid for the month-of-year
     * @since 9
     */
    // override
    public long epochSecond(int prolepticYear, int month, int dayOfMonth,
                            int hour, int minute, int second, ZoneOffset zoneOffset) {
        ChronoField.YEAR.checkValidValue(prolepticYear);
        ChronoField.MONTH_OF_YEAR.checkValidValue(month);
        ChronoField.DAY_OF_MONTH.checkValidValue(dayOfMonth);
        ChronoField.HOUR_OF_DAY.checkValidValue(hour);
        ChronoField.MINUTE_OF_HOUR.checkValidValue(minute);
        ChronoField.SECOND_OF_MINUTE.checkValidValue(second);
        assert(zoneOffset, "zoneOffset");
        if (dayOfMonth > 28) {
            int dom = numberOfDaysOfMonth(prolepticYear, month);
            if (dayOfMonth > dom) {
                if (dayOfMonth == 29) {
                    throw new DateTimeException("Invalid date 'February 29' as '" ~ prolepticYear.to!string ~ "' is not a leap year");
                } else {
                    throw new DateTimeException("Invalid date '" ~ Month.of(month).name() ~ " " ~ dayOfMonth.to!string ~ "'");
                }
            }
        }

        long totalDays = 0;
        int timeinSec = 0;
        totalDays += 365L * prolepticYear;
        if (prolepticYear >= 0) {
            totalDays += (prolepticYear + 3L) / 4 - (prolepticYear + 99L) / 100 + (prolepticYear + 399L) / 400;
        } else {
            totalDays -= prolepticYear / -4 - prolepticYear / -100 + prolepticYear / -400;
        }
        totalDays += (367 * month - 362) / 12;
        totalDays += dayOfMonth - 1;
        if (month > 2) {
            totalDays--;
            if (IsoChronology.INSTANCE.isLeapYear(prolepticYear) == false) {
                totalDays--;
            }
        }
        totalDays -= DAYS_0000_TO_1970;
        timeinSec = (hour * 60 + minute ) * 60 + second;
        return Math.addExact(Math.multiplyExact(totalDays, 86400L), timeinSec - zoneOffset.getTotalSeconds());
     }

     long epochSecond(Era era, int yearOfEra, int month, int dayOfMonth,
                                    int hour, int minute, int second, ZoneOffset zoneOffset) {
        assert(era, "era");
        return epochSecond(prolepticYear(era, yearOfEra), month, dayOfMonth, hour, minute, second, zoneOffset);
    }

    /**
     * Gets the number of days for the given month _in the given year.
     *
     * @param year the year to represent, from MIN_YEAR to MAX_YEAR
     * @param month the month-of-year to represent, from 1 to 12
     * @return the number of days for the given month _in the given year
     */
    private int numberOfDaysOfMonth(int year, int month) {
        int dom;
        switch (month) {
            case 2:
                dom = (IsoChronology.INSTANCE.isLeapYear(year) ? 29 : 28);
                break;
            case 4:
            case 6:
            case 9:
            case 11:
                dom = 30;
                break;
            default:
                dom = 31;
                break;
        }
        return dom;
    }


    /**
     * Obtains an ISO local date-time from another date-time object.
     * !(p)
     * This is equivalent to {@link LocalDateTime#from(TemporalAccessor)}.
     *
     * @param temporal  the date-time object to convert, not null
     * @return the ISO local date-time, not null
     * @throws DateTimeException if unable to create the date-time
     */
    // override  // override with covariant return type
    public ChronoLocalDateTime!(ChronoLocalDate) localDateTime(TemporalAccessor temporal) {
        return cast(ChronoLocalDateTime!(ChronoLocalDate))(LocalDateTime.from(temporal));
    }

    /**
     * Obtains an ISO zoned date-time from another date-time object.
     * !(p)
     * This is equivalent to {@link ZonedDateTime#from(TemporalAccessor)}.
     *
     * @param temporal  the date-time object to convert, not null
     * @return the ISO zoned date-time, not null
     * @throws DateTimeException if unable to create the date-time
     */
    // override  // override with covariant return type
    public ChronoZonedDateTime!(ChronoLocalDate) zonedDateTime(TemporalAccessor temporal) {
        return cast(ChronoZonedDateTime!(ChronoLocalDate))(ZonedDateTime.from(temporal));
    }

    /**
     * Obtains an ISO zoned date-time _in this chronology from an {@code Instant}.
     * !(p)
     * This is equivalent to {@link ZonedDateTime#ofInstant(Instant, ZoneId)}.
     *
     * @param instant  the instant to create the date-time from, not null
     * @param zone  the time-zone, not null
     * @return the zoned date-time, not null
     * @throws DateTimeException if the result exceeds the supported range
     */
    // override
    public ChronoZonedDateTime!(ChronoLocalDate) zonedDateTime(Instant instant, ZoneId zone) {
        return cast(ChronoZonedDateTime!(ChronoLocalDate))(ZonedDateTime.ofInstant(instant, zone));
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains the current ISO local date from the system clock _in the default time-zone.
     * !(p)
     * This will query the {@link Clock#systemDefaultZone() system clock} _in the default
     * time-zone to obtain the current date.
     * !(p)
     * Using this method will prevent the ability to use an alternate clock for testing
     * because the clock is hard-coded.
     *
     * @return the current ISO local date using the system clock and default time-zone, not null
     * @throws DateTimeException if unable to create the date
     */
    // override  // override with covariant return type
    public LocalDate dateNow() {
        return dateNow(Clock.systemDefaultZone());
    }

    /**
     * Obtains the current ISO local date from the system clock _in the specified time-zone.
     * !(p)
     * This will query the {@link Clock#system(ZoneId) system clock} to obtain the current date.
     * Specifying the time-zone avoids dependence on the default time-zone.
     * !(p)
     * Using this method will prevent the ability to use an alternate clock for testing
     * because the clock is hard-coded.
     *
     * @return the current ISO local date using the system clock, not null
     * @throws DateTimeException if unable to create the date
     */
    // override  // override with covariant return type
    public LocalDate dateNow(ZoneId zone) {
        return dateNow(Clock.system(zone));
    }

    /**
     * Obtains the current ISO local date from the specified clock.
     * !(p)
     * This will query the specified clock to obtain the current date - today.
     * Using this method allows the use of an alternate clock for testing.
     * The alternate clock may be introduced using {@link Clock dependency injection}.
     *
     * @param clock  the clock to use, not null
     * @return the current ISO local date, not null
     * @throws DateTimeException if unable to create the date
     */
    // override  // override with covariant return type
    public LocalDate dateNow(Clock clock) {
        assert(clock, "clock");
        return date(LocalDate.now(clock));
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
     * @param prolepticYear  the ISO proleptic year to check
     * @return true if the year is leap, false otherwise
     */
    // override
    public bool isLeapYear(long prolepticYear) {
        return ((prolepticYear & 3) == 0) && ((prolepticYear % 100) != 0 || (prolepticYear % 400) == 0);
    }

    // override
    public int prolepticYear(Era era, int yearOfEra) {
        if ((cast(IsoEra)(era) !is null) == false) {
            throw new ClassCastException("Era must be IsoEra");
        }
        return (era == IsoEra.CE ? yearOfEra : 1 - yearOfEra);
    }

    // override
    public IsoEra eraOf(int eraValue) {
        return IsoEra.of(eraValue);
    }

    // override
    public List!(Era) eras() {
        auto li = new ArrayList!Era();
        li.add(IsoEra.BCE);
        li.add(IsoEra.CE);
        return li;
    }

    //-----------------------------------------------------------------------
    /**
     * Resolves parsed {@code ChronoField} values into a date during parsing.
     * !(p)
     * Most {@code TemporalField} implementations are resolved using the
     * resolve method on the field. By contrast, the {@code ChronoField} class
     * defines fields that only have meaning relative to the chronology.
     * As such, {@code ChronoField} date fields are resolved here _in the
     * context of a specific chronology.
     * !(p)
     * {@code ChronoField} instances on the ISO calendar system are resolved
     * as follows.
     * !(ul)
     * !(li){@code EPOCH_DAY} - If present, this is converted to a {@code LocalDate}
     *  and all other date fields are then cross-checked against the date.
     * !(li){@code PROLEPTIC_MONTH} - If present, then it is split into the
     *  {@code YEAR} and {@code MONTH_OF_YEAR}. If the mode is strict or smart
     *  then the field is validated.
     * !(li){@code YEAR_OF_ERA} and {@code ERA} - If both are present, then they
     *  are combined to form a {@code YEAR}. In lenient mode, the {@code YEAR_OF_ERA}
     *  range is not validated, _in smart and strict mode it is. The {@code ERA} is
     *  validated for range _in all three modes. If only the {@code YEAR_OF_ERA} is
     *  present, and the mode is smart or lenient, then the current era (CE/AD)
     *  is assumed. In strict mode, no era is assumed and the {@code YEAR_OF_ERA} is
     *  left untouched. If only the {@code ERA} is present, then it is left untouched.
     * !(li){@code YEAR}, {@code MONTH_OF_YEAR} and {@code DAY_OF_MONTH} -
     *  If all three are present, then they are combined to form a {@code LocalDate}.
     *  In all three modes, the {@code YEAR} is validated. If the mode is smart or strict,
     *  then the month and day are validated, with the day validated from 1 to 31.
     *  If the mode is lenient, then the date is combined _in a manner equivalent to
     *  creating a date on the first of January _in the requested year, then adding
     *  the difference _in months, then the difference _in days.
     *  If the mode is smart, and the day-of-month is greater than the maximum for
     *  the year-month, then the day-of-month is adjusted to the last day-of-month.
     *  If the mode is strict, then the three fields must form a valid date.
     * !(li){@code YEAR} and {@code DAY_OF_YEAR} -
     *  If both are present, then they are combined to form a {@code LocalDate}.
     *  In all three modes, the {@code YEAR} is validated.
     *  If the mode is lenient, then the date is combined _in a manner equivalent to
     *  creating a date on the first of January _in the requested year, then adding
     *  the difference _in days.
     *  If the mode is smart or strict, then the two fields must form a valid date.
     * !(li){@code YEAR}, {@code MONTH_OF_YEAR}, {@code ALIGNED_WEEK_OF_MONTH} and
     *  {@code ALIGNED_DAY_OF_WEEK_IN_MONTH} -
     *  If all four are present, then they are combined to form a {@code LocalDate}.
     *  In all three modes, the {@code YEAR} is validated.
     *  If the mode is lenient, then the date is combined _in a manner equivalent to
     *  creating a date on the first of January _in the requested year, then adding
     *  the difference _in months, then the difference _in weeks, then _in days.
     *  If the mode is smart or strict, then the all four fields are validated to
     *  their outer ranges. The date is then combined _in a manner equivalent to
     *  creating a date on the first day of the requested year and month, then adding
     *  the amount _in weeks and days to reach their values. If the mode is strict,
     *  the date is additionally validated to check that the day and week adjustment
     *  did not change the month.
     * !(li){@code YEAR}, {@code MONTH_OF_YEAR}, {@code ALIGNED_WEEK_OF_MONTH} and
     *  {@code DAY_OF_WEEK} - If all four are present, then they are combined to
     *  form a {@code LocalDate}. The approach is the same as described above for
     *  years, months and weeks _in {@code ALIGNED_DAY_OF_WEEK_IN_MONTH}.
     *  The day-of-week is adjusted as the next or same matching day-of-week once
     *  the years, months and weeks have been handled.
     * !(li){@code YEAR}, {@code ALIGNED_WEEK_OF_YEAR} and {@code ALIGNED_DAY_OF_WEEK_IN_YEAR} -
     *  If all three are present, then they are combined to form a {@code LocalDate}.
     *  In all three modes, the {@code YEAR} is validated.
     *  If the mode is lenient, then the date is combined _in a manner equivalent to
     *  creating a date on the first of January _in the requested year, then adding
     *  the difference _in weeks, then _in days.
     *  If the mode is smart or strict, then the all three fields are validated to
     *  their outer ranges. The date is then combined _in a manner equivalent to
     *  creating a date on the first day of the requested year, then adding
     *  the amount _in weeks and days to reach their values. If the mode is strict,
     *  the date is additionally validated to check that the day and week adjustment
     *  did not change the year.
     * !(li){@code YEAR}, {@code ALIGNED_WEEK_OF_YEAR} and {@code DAY_OF_WEEK} -
     *  If all three are present, then they are combined to form a {@code LocalDate}.
     *  The approach is the same as described above for years and weeks _in
     *  {@code ALIGNED_DAY_OF_WEEK_IN_YEAR}. The day-of-week is adjusted as the
     *  next or same matching day-of-week once the years and weeks have been handled.
     * </ul>
     *
     * @param fieldValues  the map of fields to values, which can be updated, not null
     * @param resolverStyle  the requested type of resolve, not null
     * @return the resolved date, null if insufficient information to create a date
     * @throws DateTimeException if the date cannot be resolved, typically
     *  because of a conflict _in the input data
     */
    override  // override for performance
    public LocalDate resolveDate(Map!(TemporalField, Long) fieldValues, ResolverStyle resolverStyle) {
        return cast(LocalDate) super.resolveDate(fieldValues, resolverStyle);
    }

    override  // override for better proleptic algorithm
    void resolveProlepticMonth(Map!(TemporalField, Long) fieldValues, ResolverStyle resolverStyle) {
        Long pMonth = fieldValues.remove(ChronoField.PROLEPTIC_MONTH);
        if (pMonth !is null) {
            if (resolverStyle != ResolverStyle.LENIENT) {
                ChronoField.PROLEPTIC_MONTH.checkValidValue(pMonth.longValue());
            }
            addFieldValue(fieldValues, ChronoField.MONTH_OF_YEAR, Math.floorMod(pMonth.longValue(), 12) + 1);
            addFieldValue(fieldValues, ChronoField.YEAR, Math.floorDiv(pMonth.longValue(), 12));
        }
    }

    override  // override for enhanced behaviour
    LocalDate resolveYearOfEra(Map!(TemporalField, Long) fieldValues, ResolverStyle resolverStyle) {
        Long yoeLong = fieldValues.remove(ChronoField.YEAR_OF_ERA);
        if (yoeLong !is null) {
            if (resolverStyle != ResolverStyle.LENIENT) {
                ChronoField.YEAR_OF_ERA.checkValidValue(yoeLong.longValue());
            }
            Long era = fieldValues.remove(ChronoField.ERA);
            if (era is null) {
                Long year = fieldValues.get(ChronoField.YEAR);
                if (resolverStyle == ResolverStyle.STRICT) {
                    // do not invent era if strict, but do cross-check with year
                    if (year !is null) {
                        addFieldValue(fieldValues, ChronoField.YEAR, (year > 0 ? yoeLong.longValue(): Math.subtractExact(1, yoeLong.longValue())));
                    } else {
                        // reinstate the field removed earlier, no cross-check issues
                        fieldValues.put(ChronoField.YEAR_OF_ERA, yoeLong);
                    }
                } else {
                    // invent era
                    addFieldValue(fieldValues, ChronoField.YEAR, (year is null || year > 0 ? yoeLong.longValue(): Math.subtractExact(1, yoeLong.longValue())));
                }
            } else if (era.longValue() == 1L) {
                addFieldValue(fieldValues, ChronoField.YEAR, yoeLong.longValue());
            } else if (era.longValue() == 0L) {
                addFieldValue(fieldValues, ChronoField.YEAR, Math.subtractExact(1, yoeLong.longValue()));
            } else {
                throw new DateTimeException("Invalid value for era: " ~ era.longValue().to!string);
            }
        } else if (fieldValues.containsKey(ChronoField.ERA)) {
            ChronoField.ERA.checkValidValue(fieldValues.get(ChronoField.ERA).longValue());  // always validated
        }
        return null;
    }

    override  // override for performance
    LocalDate resolveYMD(Map !(TemporalField, Long) fieldValues, ResolverStyle resolverStyle) {
        int y = ChronoField.YEAR.checkValidIntValue(fieldValues.remove(ChronoField.YEAR).longValue());
        if (resolverStyle == ResolverStyle.LENIENT) {
            long months = Math.subtractExact(fieldValues.remove(ChronoField.MONTH_OF_YEAR).longValue(), 1);
            long days = Math.subtractExact(fieldValues.remove(ChronoField.DAY_OF_MONTH).longValue(), 1);
            return LocalDate.of(y, 1, 1).plusMonths(months).plusDays(days);
        }
        int moy = ChronoField.MONTH_OF_YEAR.checkValidIntValue(fieldValues.remove(ChronoField.MONTH_OF_YEAR).longValue());
        int dom = ChronoField.DAY_OF_MONTH.checkValidIntValue(fieldValues.remove(ChronoField.DAY_OF_MONTH).longValue());
        if (resolverStyle == ResolverStyle.SMART) {  // previous valid
            if (moy == 4 || moy == 6 || moy == 9 || moy == 11) {
                dom = Math.min(dom, 30);
            } else if (moy == 2) {
                dom = Math.min(dom, Month.FEBRUARY.length(Year.isLeap(y)));

            }
        }
        return LocalDate.of(y, moy, dom);
    }

    //-----------------------------------------------------------------------
    // override
    public ValueRange range(ChronoField field) {
        return field.range();
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains a period for this chronology based on years, months and days.
     * !(p)
     * This returns a period tied to the ISO chronology using the specified
     * years, months and days. See {@link Period} for further details.
     *
     * @param years  the number of years, may be negative
     * @param months  the number of years, may be negative
     * @param days  the number of years, may be negative
     * @return the ISO period, not null
     */
    // override  // override with covariant return type
    public Period period(int years, int months, int days) {
        return Period.of(years, months, days);
    }

    //-----------------------------------------------------------------------
    /**
     * Writes the Chronology using a
     * <a href="{@docRoot}/serialized-form.html#hunt.time.chrono.Ser">dedicated serialized form</a>.
     * @serialData
     * !(pre)
     *  _out.writeByte(1);     // identifies a Chronology
     *  _out.writeUTF(getId());
     * </pre>
     *
     * @return the instance of {@code Ser}, not null
     */
    override
    Object writeReplace() {
        return super.writeReplace();
    }

    /**
     * Defend against malicious streams.
     *
     * @param s the stream to read
     * @throws InvalidObjectException always
     */
     ///@gxc
    // private void readObject(ObjectInputStream s) /*throws InvalidObjectException*/ {
    //     throw new InvalidObjectException("Deserialization via serialization delegate");
    // }

    override
    public bool opEquals(Object obj) {
        if (this is obj) {
           return true;
        }
        if (cast(AbstractChronology)(obj) !is null) {
            return compareTo(cast(AbstractChronology) obj) == 0;
        }
        return false;
    }

    override
    public int compareTo(Chronology other) {
        return getId().compare(other.getId());
    }

    // override
    public int opCmp(Chronology other) {
        return getId().compare(other.getId());
    }
    
    // override
	//  ChronoLocalDateTime!(ChronoLocalDate) localDateTime(TemporalAccessor temporal) {
    //     try {
    //         return date(temporal).atTime(LocalTime.from(temporal));
    //     } catch (DateTimeException ex) {
    //         throw new DateTimeException("Unable to obtain ChronoLocalDateTime from TemporalAccessor: " ~ typeid(temporal).stringof, ex);
    //     }
    // }
	
    // override
	//  ChronoZonedDateTime!(ChronoLocalDate) zonedDateTime(TemporalAccessor temporal) {
    //     try {
    //         ZoneId zone = ZoneId.from(temporal);
    //         try {
    //             Instant instant = Instant.from(temporal);
    //             return zonedDateTime(instant, zone);

    //         } catch (DateTimeException ex1) {
    //             ChronoLocalDateTimeImpl!(ChronoLocalDate) cldt = ChronoLocalDateTimeImpl!ChronoLocalDate.ensureValid!ChronoLocalDate(this, localDateTime(temporal));
    //             return ChronoZonedDateTimeImpl!ChronoLocalDate.ofBest!ChronoLocalDate(cldt, zone, null);
    //         }
    //     } catch (DateTimeException ex) {
    //         throw new DateTimeException("Unable to obtain ChronoZonedDateTime from TemporalAccessor: " ~ typeid(temporal).stringof, ex);
    //     }
    // }
	
    // override
	//  ChronoZonedDateTime!(ChronoLocalDate) zonedDateTime(Instant instant, ZoneId zone) {
    //     return ChronoZonedDateTimeImpl.ofInstant(this, instant, zone);
    // }
	
    // override
	 string getDisplayName(TextStyle style, Locale locale) {
        TemporalAccessor temporal = new AnonymousClass1();
        return new DateTimeFormatterBuilder().appendChronologyText(style).toFormatter(locale).format(temporal);
    }
	
    // // override
	// public  long epochSecond(int prolepticYear, int month, int dayOfMonth,
    //                                 int hour, int minute, int second, ZoneOffset zoneOffset) {
    //     assert(zoneOffset, "zoneOffset");
    //     ChronoField.HOUR_OF_DAY.checkValidValue(hour);
    //     ChronoField.MINUTE_OF_HOUR.checkValidValue(minute);
    //     ChronoField.SECOND_OF_MINUTE.checkValidValue(second);
    //     long daysInSec = Math.multiplyExact(date(prolepticYear, month, dayOfMonth).toEpochDay(), 86400);
    //     long timeinSec = (hour * 60 + minute) * 60 + second;
    //     return Math.addExact(daysInSec, timeinSec - zoneOffset.getTotalSeconds());
    // }
}
