module hunt.time.Init;

import hunt.time.chrono.AbstractChronology;
import hunt.time.chrono.ChronoPeriodImpl;
import hunt.time.chrono.IsoChronology;
import hunt.time.Clock;
import hunt.time.DayOfWeek;
import hunt.time.Duration;
import hunt.time.format.DateTimeFormatter;
import hunt.time.format.DateTimeFormatterBuilder;
import hunt.time.format.DateTimeTextProvider;
import hunt.time.format.DecimalStyle;
import hunt.time.Instant;
import hunt.time.LocalDate;
import hunt.time.LocalDateTime;
import hunt.time.LocalTime;
import hunt.time.MonthDay;
import hunt.time.OffsetDateTime;
import hunt.time.OffsetTime;
import hunt.time.Period;
import hunt.time.temporal.IsoFields;
import hunt.time.temporal.TemporalQueries;
import hunt.time.temporal.WeekFields;
import hunt.time.util.Calendar;
import hunt.time.util.Locale;
import hunt.time.Year;
import hunt.time.YearMonth;
import hunt.time.zone.ZoneRules;
import hunt.time.zone.ZoneRulesProvider;
import hunt.time.ZoneId;
import hunt.time.ZoneOffset;
import hunt.time.chrono.Chronology;
import hunt.time.temporal.TemporalUnit;
import hunt.time.temporal.ChronoUnit;
import hunt.time.temporal.ChronoField;
import hunt.time.util.common;
import hunt.time.temporal.TemporalAccessor;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.TemporalQuery;
import hunt.time.temporal.ValueRange;
import hunt.time.temporal.Temporal;
import hunt.time.format.ResolverStyle;
import hunt.time.chrono.ChronoLocalDate;
import hunt.time.format.SignStyle;
import hunt.time.format.Parsed;
import hunt.math.BigInteger;
import hunt.container;
import hunt.lang;
import hunt.time.util.QueryHelper;
import hunt.util.Comparator;
import hunt.lang.exception;
import hunt.time.zone.ZoneOffsetTransitionRule;
import hunt.time.chrono.IsoEra;
import hunt.time.format.FormatStyle;
import hunt.time.format.TextStyle;
import hunt.time.Month;
import hunt.time.util.ServiceLoader;
import hunt.time.zone.TzdbZoneRulesProvider;

shared static this()
{
    import hunt.logging;
        /* version(HUNT_DEBUG) */ trace("Init shared static this start");
    {
        Locale.ENGLISH = Locale.createConstant("en", "");

        /** Useful constant for language.
     */
        Locale.FRENCH = Locale.createConstant("fr", "");

        /** Useful constant for language.
     */
        Locale.GERMAN = Locale.createConstant("de", "");

        /** Useful constant for language.
     */
        Locale.ITALIAN = Locale.createConstant("it", "");

        /** Useful constant for language.
     */
        Locale.JAPANESE = Locale.createConstant("ja", "");

        /** Useful constant for language.
     */
        Locale.KOREAN = Locale.createConstant("ko", "");

        /** Useful constant for language.
     */
        Locale.CHINESE = Locale.createConstant("zh", "");

        /** Useful constant for language.
     */
        Locale.SIMPLIFIED_CHINESE = Locale.createConstant("zh", "CN");

        /** Useful constant for language.
     */
        Locale.TRADITIONAL_CHINESE = Locale.createConstant("zh", "TW");

        /** Useful constant for country.
     */
        Locale.FRANCE = Locale.createConstant("fr", "FR");

        /** Useful constant for country.
     */
        Locale.GERMANY = Locale.createConstant("de", "DE");

        /** Useful constant for country.
     */
        Locale.ITALY = Locale.createConstant("it", "IT");

        /** Useful constant for country.
     */
        Locale.JAPAN = Locale.createConstant("ja", "JP");

        /** Useful constant for country.
     */
        Locale.KOREA = Locale.createConstant("ko", "KR");

        /** Useful constant for country.
     */
        Locale.CHINA = Locale.SIMPLIFIED_CHINESE;

        /** Useful constant for country.
     */
        Locale.PRC = Locale.SIMPLIFIED_CHINESE;

        /** Useful constant for country.
     */
        Locale.TAIWAN = Locale.TRADITIONAL_CHINESE;

        /** Useful constant for country.
     */
        Locale.UK = Locale.createConstant("en", "GB");

        /** Useful constant for country.
     */
        Locale.US = Locale.createConstant("en", "US");

        /** Useful constant for country.
     */
        Locale.CANADA = Locale.createConstant("en", "CA");

        /** Useful constant for country.
     */
        Locale.CANADA_FRENCH = Locale.createConstant("fr", "CA");

        /**
     * Useful constant for the root locale.  The root locale is the locale whose
     * language, country, and variant are empty ("") strings.  This is regarded
     * as the base locale of all locales, and is used as the language/country
     * neutral locale for the locale sensitive operations.
     *
     * @since 1.6
     */
        Locale.ROOT = Locale.createConstant("", "");

        Locale.CHINA = Locale.SIMPLIFIED_CHINESE;
        Locale.PRC = Locale.SIMPLIFIED_CHINESE;
        Locale.TAIWAN = Locale.TRADITIONAL_CHINESE;
    }

    {
        AbstractChronology.CHRONOS_BY_ID = new HashMap!(string, Chronology)();
        AbstractChronology.CHRONOS_BY_TYPE = new HashMap!(string, Chronology)();
    }

    {
        ChronoPeriodImpl.SUPPORTED_UNITS = new ArrayList!TemporalUnit();
        ChronoPeriodImpl.SUPPORTED_UNITS.add(ChronoUnit.YEARS);
        ChronoPeriodImpl.SUPPORTED_UNITS.add(ChronoUnit.MONTHS);
        ChronoPeriodImpl.SUPPORTED_UNITS.add(ChronoUnit.DAYS);
    }

    {
        IsoChronology.INSTANCE = new IsoChronology();
    }

    {
        DecimalStyle.STANDARD = new DecimalStyle('0', '+', '-', '.');
        DecimalStyle.CACHE = new HashMap!(Locale, DecimalStyle)(16, 0.75f /* , 2 */ );
    }

    {
        Clock.SystemClock.OFFSET_SEED = System.currentTimeMillis() / 1000 /* - 1024 */; // initial offest
        Clock.SystemClock.UTC = new Clock.SystemClock(ZoneOffset.UTC);
    }

    {
        DayOfWeek.MONDAY = new DayOfWeek(0, "MONDAY");
        /**
     * The singleton instance for the day-of-week of Tuesday.
     * This has the numeric value of {@code 2}.
     */
        DayOfWeek.TUESDAY = new DayOfWeek(1, "TUESDAY");
        /**
     * The singleton instance for the day-of-week of Wednesday.
     * This has the numeric value of {@code 3}.
     */
        DayOfWeek.WEDNESDAY = new DayOfWeek(2, "WEDNESDAY");
        /**
     * The singleton instance for the day-of-week of Thursday.
     * This has the numeric value of {@code 4}.
     */
        DayOfWeek.THURSDAY = new DayOfWeek(3, "THURSDAY");
        /**
     * The singleton instance for the day-of-week of Friday.
     * This has the numeric value of {@code 5}.
     */
        DayOfWeek.FRIDAY = new DayOfWeek(4, "FRIDAY");
        /**
     * The singleton instance for the day-of-week of Saturday.
     * This has the numeric value of {@code 6}.
     */
        DayOfWeek.SATURDAY = new DayOfWeek(5, "SATURDAY");
        /**
     * The singleton instance for the day-of-week of Sunday.
     * This has the numeric value of {@code 7}.
     */
        DayOfWeek.SUNDAY = new DayOfWeek(6, "SUNDAY");

        DayOfWeek.ENUMS ~= DayOfWeek.MONDAY;
        DayOfWeek.ENUMS ~= DayOfWeek.TUESDAY;

        DayOfWeek.ENUMS ~= DayOfWeek.WEDNESDAY;
        DayOfWeek.ENUMS ~= DayOfWeek.THURSDAY;
        DayOfWeek.ENUMS ~= DayOfWeek.FRIDAY;
        DayOfWeek.ENUMS ~= DayOfWeek.SATURDAY;
        DayOfWeek.ENUMS ~= DayOfWeek.SUNDAY;
    }

    {
        Duration.ZERO = new Duration(0, 0);
        Duration.BI_NANOS_PER_SECOND = BigInteger.valueOf(LocalTime.NANOS_PER_SECOND);

        {
            Duration.DurationUnits.UNITS = new ArrayList!(TemporalUnit)();

            Duration.DurationUnits.UNITS.add(ChronoUnit.SECONDS);
            Duration.DurationUnits.UNITS.add(ChronoUnit.NANOS);
        }
    }

    {
        ChronoUnit.NANOS = new ChronoUnit("Nanos", Duration.ofNanos(1));

        ChronoUnit.MICROS = new ChronoUnit("Micros", Duration.ofNanos(1000));

        ChronoUnit.MILLIS = new ChronoUnit("Millis", Duration.ofNanos(1000_000));

        ChronoUnit.SECONDS = new ChronoUnit("Seconds", Duration.ofSeconds(1));

        ChronoUnit.MINUTES = new ChronoUnit("Minutes", Duration.ofSeconds(60));

        ChronoUnit.HOURS = new ChronoUnit("Hours", Duration.ofSeconds(3600));

        ChronoUnit.HALF_DAYS = new ChronoUnit("HalfDays", Duration.ofSeconds(43200));

        ChronoUnit.DAYS = new ChronoUnit("Days", Duration.ofSeconds(86400));

        ChronoUnit.WEEKS = new ChronoUnit("Weeks", Duration.ofSeconds(7 * 86400L));

        ChronoUnit.MONTHS = new ChronoUnit("Months", Duration.ofSeconds(31556952L / 12));

        ChronoUnit.YEARS = new ChronoUnit("Years", Duration.ofSeconds(31556952L));

        ChronoUnit.DECADES = new ChronoUnit("Decades", Duration.ofSeconds(31556952L * 10L));

        ChronoUnit.CENTURIES = new ChronoUnit("Centuries", Duration.ofSeconds(31556952L * 100L));

        ChronoUnit.MILLENNIA = new ChronoUnit("Millennia", Duration.ofSeconds(31556952L * 1000L));

        ChronoUnit.ERAS = new ChronoUnit("Eras", Duration.ofSeconds(31556952L * 1000_000_000L));

        ChronoUnit.FOREVER = new ChronoUnit("Forever",
                Duration.ofSeconds(Long.MAX_VALUE, 999_999_999));
    }

    {

        ChronoField.NANO_OF_SECOND = new ChronoField(0, "NanoOfSecond",
                ChronoUnit.NANOS, ChronoUnit.SECONDS, ValueRange.of(0, 999_999_999));

        ChronoField.NANO_OF_DAY = new ChronoField(1, "NanoOfDay", ChronoUnit.NANOS,
                ChronoUnit.DAYS, ValueRange.of(0, 86400L * 1000_000_000L - 1));

        ChronoField.MICRO_OF_SECOND = new ChronoField(2, "MicroOfSecond",
                ChronoUnit.MICROS, ChronoUnit.SECONDS, ValueRange.of(0, 999_999));

        ChronoField.MICRO_OF_DAY = new ChronoField(3, "MicroOfDay", ChronoUnit.MICROS,
                ChronoUnit.DAYS, ValueRange.of(0, 86400L * 1000_000L - 1));

        ChronoField.MILLI_OF_SECOND = new ChronoField(4, "MilliOfSecond",
                ChronoUnit.MILLIS, ChronoUnit.SECONDS, ValueRange.of(0, 999));

        ChronoField.MILLI_OF_DAY = new ChronoField(5, "MilliOfDay",
                ChronoUnit.MILLIS, ChronoUnit.DAYS, ValueRange.of(0, 86400L * 1000L - 1));

        ChronoField.SECOND_OF_MINUTE = new ChronoField(6, "SecondOfMinute",
                ChronoUnit.SECONDS, ChronoUnit.MINUTES, ValueRange.of(0, 59), "second");

        ChronoField.SECOND_OF_DAY = new ChronoField(7, "SecondOfDay",
                ChronoUnit.SECONDS, ChronoUnit.DAYS, ValueRange.of(0, 86400L - 1));

        ChronoField.MINUTE_OF_HOUR = new ChronoField(8, "MinuteOfHour",
                ChronoUnit.MINUTES, ChronoUnit.HOURS, ValueRange.of(0, 59), "minute");

        ChronoField.MINUTE_OF_DAY = new ChronoField(9, "MinuteOfDay",
                ChronoUnit.MINUTES, ChronoUnit.DAYS, ValueRange.of(0, (24 * 60) - 1));

        ChronoField.HOUR_OF_AMPM = new ChronoField(10, "HourOfAmPm",
                ChronoUnit.HOURS, ChronoUnit.HALF_DAYS, ValueRange.of(0, 11));

        ChronoField.CLOCK_HOUR_OF_AMPM = new ChronoField(11, "ClockHourOfAmPm",
                ChronoUnit.HOURS, ChronoUnit.HALF_DAYS, ValueRange.of(1, 12));

        ChronoField.HOUR_OF_DAY = new ChronoField(12, "HourOfDay",
                ChronoUnit.HOURS, ChronoUnit.DAYS, ValueRange.of(0, 23), "hour");

        ChronoField.CLOCK_HOUR_OF_DAY = new ChronoField(13, "ClockHourOfDay",
                ChronoUnit.HOURS, ChronoUnit.DAYS, ValueRange.of(1, 24));

        ChronoField.AMPM_OF_DAY = new ChronoField(14, "AmPmOfDay",
                ChronoUnit.HALF_DAYS, ChronoUnit.DAYS, ValueRange.of(0, 1), "dayperiod");

        ChronoField.DAY_OF_WEEK = new ChronoField(15, "DayOfWeek",
                ChronoUnit.DAYS, ChronoUnit.WEEKS, ValueRange.of(1, 7), "weekday");

        ChronoField.ALIGNED_DAY_OF_WEEK_IN_MONTH = new ChronoField(16,
                "AlignedDayOfWeekInMonth", ChronoUnit.DAYS, ChronoUnit.WEEKS, ValueRange.of(1, 7));

        ChronoField.ALIGNED_DAY_OF_WEEK_IN_YEAR = new ChronoField(17,
                "AlignedDayOfWeekInYear", ChronoUnit.DAYS, ChronoUnit.WEEKS, ValueRange.of(1, 7));

        ChronoField.DAY_OF_MONTH = new ChronoField(18, "DayOfMonth",
                ChronoUnit.DAYS, ChronoUnit.MONTHS, ValueRange.of(1, 28, 31), "day");

        ChronoField.DAY_OF_YEAR = new ChronoField(19, "DayOfYear",
                ChronoUnit.DAYS, ChronoUnit.YEARS, ValueRange.of(1, 365, 366));

        ChronoField.EPOCH_DAY = new ChronoField(20, "EpochDay", ChronoUnit.DAYS,
                ChronoUnit.FOREVER, ValueRange.of(-365243219162L, 365241780471L));

        ChronoField.ALIGNED_WEEK_OF_MONTH = new ChronoField(21, "AlignedWeekOfMonth",
                ChronoUnit.WEEKS, ChronoUnit.MONTHS, ValueRange.of(1, 4, 5));

        ChronoField.ALIGNED_WEEK_OF_YEAR = new ChronoField(22, "AlignedWeekOfYear",
                ChronoUnit.WEEKS, ChronoUnit.YEARS, ValueRange.of(1, 53));

        ChronoField.MONTH_OF_YEAR = new ChronoField(23, "MonthOfYear",
                ChronoUnit.MONTHS, ChronoUnit.YEARS, ValueRange.of(1, 12), "month");

        ChronoField.PROLEPTIC_MONTH = new ChronoField(24, "ProlepticMonth", ChronoUnit.MONTHS,
                ChronoUnit.FOREVER, ValueRange.of(Year.MIN_VALUE * 12L, Year.MAX_VALUE * 12L + 11));

        ChronoField.YEAR_OF_ERA = new ChronoField(25, "YearOfEra", ChronoUnit.YEARS,
                ChronoUnit.FOREVER, ValueRange.of(1, Year.MAX_VALUE, Year.MAX_VALUE + 1));

        ChronoField.YEAR = new ChronoField(26, "Year", ChronoUnit.YEARS,
                ChronoUnit.FOREVER, ValueRange.of(Year.MIN_VALUE, Year.MAX_VALUE), "year");

        ChronoField.ERA = new ChronoField(27, "Era", ChronoUnit.ERAS,
                ChronoUnit.FOREVER, ValueRange.of(0, 1), "era");

        ChronoField.INSTANT_SECONDS = new ChronoField(28, "InstantSeconds", ChronoUnit.SECONDS,
                ChronoUnit.FOREVER, ValueRange.of(Long.MIN_VALUE, Long.MAX_VALUE));

        ChronoField.OFFSET_SECONDS = new ChronoField(29, "OffsetSeconds",
                ChronoUnit.SECONDS, ChronoUnit.FOREVER, ValueRange.of(-18 * 3600, 18 * 3600));
        ChronoField._values ~= ChronoField.NANO_OF_SECOND;
        ChronoField._values ~= ChronoField.NANO_OF_DAY;
        ChronoField._values ~= ChronoField.MICRO_OF_SECOND;
        ChronoField._values ~= ChronoField.MICRO_OF_DAY;
        ChronoField._values ~= ChronoField.MILLI_OF_SECOND;
        ChronoField._values ~= ChronoField.MILLI_OF_DAY;
        ChronoField._values ~= ChronoField.SECOND_OF_MINUTE;
        ChronoField._values ~= ChronoField.SECOND_OF_DAY;
        ChronoField._values ~= ChronoField.MINUTE_OF_HOUR;
        ChronoField._values ~= ChronoField.MINUTE_OF_DAY;
        ChronoField._values ~= ChronoField.HOUR_OF_AMPM;
        ChronoField._values ~= ChronoField.CLOCK_HOUR_OF_AMPM;
        ChronoField._values ~= ChronoField.HOUR_OF_DAY;
        ChronoField._values ~= ChronoField.CLOCK_HOUR_OF_DAY;
        ChronoField._values ~= ChronoField.AMPM_OF_DAY;
        ChronoField._values ~= ChronoField.DAY_OF_WEEK;
        ChronoField._values ~= ChronoField.ALIGNED_DAY_OF_WEEK_IN_MONTH;
        ChronoField._values ~= ChronoField.ALIGNED_DAY_OF_WEEK_IN_YEAR;
        ChronoField._values ~= ChronoField.DAY_OF_MONTH;
        ChronoField._values ~= ChronoField.DAY_OF_YEAR;
        ChronoField._values ~= ChronoField.EPOCH_DAY;
        ChronoField._values ~= ChronoField.ALIGNED_WEEK_OF_MONTH;
        ChronoField._values ~= ChronoField.ALIGNED_WEEK_OF_YEAR;
        ChronoField._values ~= ChronoField.MONTH_OF_YEAR;
        ChronoField._values ~= ChronoField.PROLEPTIC_MONTH;
        ChronoField._values ~= ChronoField.YEAR_OF_ERA;
        ChronoField._values ~= ChronoField.YEAR;
        ChronoField._values ~= ChronoField.ERA;
        ChronoField._values ~= ChronoField.INSTANT_SECONDS;
        ChronoField._values ~= ChronoField.OFFSET_SECONDS;
    }

    {
        {
            IsoFields.Field.DAY_OF_QUARTER = new class IsoFields.Field
            {
                override public TemporalUnit getBaseUnit()
                {
                    return ChronoUnit.DAYS;
                }

                override public TemporalUnit getRangeUnit()
                {
                    return IsoFields.QUARTER_YEARS;
                }

                override public ValueRange range()
                {
                    return ValueRange.of(1, 90, 92);
                }

                override public bool isSupportedBy(TemporalAccessor temporal)
                {
                    return temporal.isSupported(ChronoField.DAY_OF_YEAR)
                        && temporal.isSupported(ChronoField.MONTH_OF_YEAR)
                        && temporal.isSupported(ChronoField.YEAR) && IsoFields.isIso(temporal);
                }

                override public ValueRange rangeRefinedBy(TemporalAccessor temporal)
                {
                    if (isSupportedBy(temporal) == false)
                    {
                        throw new Exception("Unsupported field: DayOfQuarter");
                    }
                    long qoy = temporal.getLong(QUARTER_OF_YEAR);
                    if (qoy == 1)
                    {
                        long year = temporal.getLong(ChronoField.YEAR);
                        return (IsoChronology.INSTANCE.isLeapYear(year)
                                ? ValueRange.of(1, 91) : ValueRange.of(1, 90));
                    }
                    else if (qoy == 2)
                    {
                        return ValueRange.of(1, 91);
                    }
                    else if (qoy == 3 || qoy == 4)
                    {
                        return ValueRange.of(1, 92);
                    } // else value not from 1 to 4, so drop through
                    return range();
                }

                override public long getFrom(TemporalAccessor temporal)
                {
                    if (isSupportedBy(temporal) == false)
                    {
                        throw new Exception("Unsupported field: DayOfQuarter");
                    }
                    int doy = temporal.get(ChronoField.DAY_OF_YEAR);
                    int moy = temporal.get(ChronoField.MONTH_OF_YEAR);
                    long year = temporal.getLong(ChronoField.YEAR);
                    return doy - QUARTER_DAYS[((moy - 1) / 3) + (IsoChronology.INSTANCE.isLeapYear(year)
                            ? 4 : 0)];
                }
                /*@SuppressWarnings("unchecked")*/
                override public Temporal adjustInto(Temporal temporal, long newValue) /* if (is(R : Temporal)) */
                {
                    // calls getFrom() to check if supported
                    long curValue = getFrom(temporal);
                    range().checkValidValue(newValue, this); // leniently check from 1 to 92 TODO: check
                    return cast(Temporal) temporal._with(ChronoField.DAY_OF_YEAR,
                            temporal.getLong(ChronoField.DAY_OF_YEAR) + (newValue - curValue));
                }

                override public ChronoLocalDate resolve(Map!(TemporalField, Long) fieldValues,
                        TemporalAccessor partialTemporal, ResolverStyle resolverStyle)
                {
                    Long yearLong = fieldValues.get(ChronoField.YEAR);
                    Long qoyLong = fieldValues.get(QUARTER_OF_YEAR);
                    if (yearLong is null || qoyLong is null)
                    {
                        return null;
                    }
                    int y = ChronoField.YEAR.checkValidIntValue(yearLong.longValue()); // always validate
                    long doq = fieldValues.get(DAY_OF_QUARTER).longValue();
                    ensureIso(partialTemporal);
                    LocalDate date;
                    if (resolverStyle == ResolverStyle.LENIENT)
                    {
                        date = LocalDate.of(y, 1, 1)
                            .plusMonths(Math.multiplyExact(Math.subtractExact(cast(int)(qoyLong.longValue()),
                                    1), 3));
                        doq = Math.subtractExact(doq, 1);
                    }
                    else
                    {
                        int qoy = QUARTER_OF_YEAR.range()
                            .checkValidIntValue(qoyLong.longValue(), QUARTER_OF_YEAR); // validated
                        date = LocalDate.of(y, ((qoy - 1) * 3) + 1, 1);
                        if (doq < 1 || doq > 90)
                        {
                            if (resolverStyle == ResolverStyle.STRICT)
                            {
                                rangeRefinedBy(date).checkValidValue(doq, this); // only allow exact range
                            }
                            else
                            { // SMART
                                range().checkValidValue(doq, this); // allow 1-92 rolling into next quarter
                            }
                        }
                        doq--;
                    }
                    fieldValues.remove(this);
                    fieldValues.remove(ChronoField.YEAR);
                    fieldValues.remove(QUARTER_OF_YEAR);
                    return date.plusDays(doq);
                }

                override string getDisplayName(Locale locale)
                {
                    assert(locale, "locale");
                    return toString();
                }

                override public string toString()
                {
                    return "DayOfQuarter";
                }

                override int opCmp(TemporalField obj)
                {
                    if (cast(IsoFields.Field)(obj) !is null)
                    {
                        IsoFields.Field other = cast(IsoFields.Field) obj;
                        return compare(toString(), other.toString());
                    }
                    return 0;
                }
            };
            IsoFields.Field.QUARTER_OF_YEAR = new class IsoFields.Field
            {
                override public TemporalUnit getBaseUnit()
                {
                    return IsoFields.QUARTER_YEARS;
                }

                override public TemporalUnit getRangeUnit()
                {
                    return ChronoUnit.YEARS;
                }

                override public ValueRange range()
                {
                    return ValueRange.of(1, 4);
                }

                override public bool isSupportedBy(TemporalAccessor temporal)
                {
                    return temporal.isSupported(ChronoField.MONTH_OF_YEAR)
                        && IsoFields.isIso(temporal);
                }

                override public long getFrom(TemporalAccessor temporal)
                {
                    if (isSupportedBy(temporal) == false)
                    {
                        throw new Exception("Unsupported field: QuarterOfYear");
                    }
                    long moy = temporal.getLong(ChronoField.MONTH_OF_YEAR);
                    return ((moy + 2) / 3);
                }

                override public ValueRange rangeRefinedBy(TemporalAccessor temporal)
                {
                    if (isSupportedBy(temporal) == false)
                    {
                        throw new Exception("Unsupported field: QuarterOfYear");
                    }
                    return range() /* super.rangeRefinedBy(temporal) */ ;
                }
                /*@SuppressWarnings("unchecked")*/
                override public Temporal adjustInto(Temporal temporal, long newValue) /* if (is(R : Temporal)) */
                {
                    // calls getFrom() to check if supported
                    long curValue = getFrom(temporal);
                    range().checkValidValue(newValue, this); // strictly check from 1 to 4
                    return cast(Temporal) temporal._with(ChronoField.MONTH_OF_YEAR,
                            temporal.getLong(ChronoField.MONTH_OF_YEAR) + (newValue - curValue) * 3);
                }

                override string getDisplayName(Locale locale)
                {
                    assert(locale, "locale");
                    return toString();
                }

                override public string toString()
                {
                    return "QuarterOfYear";
                }

                override TemporalAccessor resolve(Map!(TemporalField, Long) fieldValues,
                        TemporalAccessor partialTemporal, ResolverStyle resolverStyle)
                {
                    return null;
                }

                override int opCmp(TemporalField obj)
                {
                    if (cast(IsoFields.Field)(obj) !is null)
                    {
                        IsoFields.Field other = cast(IsoFields.Field) obj;
                        return compare(toString(), other.toString());
                    }
                    return 0;
                }
            };

            IsoFields.Field.WEEK_OF_WEEK_BASED_YEAR = new class IsoFields.Field
            {
                override public string getDisplayName(Locale locale)
                {
                    ///@gxc
                    // assert(locale, "locale");
                    // LocaleResources lr = LocaleProviderAdapter.getResourceBundleBased()
                    //                             .getLocaleResources(
                    //                                 CalendarDataUtility
                    //                                     .findRegionOverride(locale));
                    // ResourceBundle rb = lr.getJavaTimeFormatData();
                    // return rb.containsKey("field.week") ? rb.getString("field.week") : toString();
                    implementationMissing();
                    return null;
                }

                override public TemporalUnit getBaseUnit()
                {
                    return ChronoUnit.WEEKS;
                }

                override public TemporalUnit getRangeUnit()
                {
                    return IsoFields.WEEK_BASED_YEARS;
                }

                override public ValueRange range()
                {
                    return ValueRange.of(1, 52, 53);
                }

                override public bool isSupportedBy(TemporalAccessor temporal)
                {
                    return temporal.isSupported(ChronoField.EPOCH_DAY) && IsoFields.isIso(temporal);
                }

                override public ValueRange rangeRefinedBy(TemporalAccessor temporal)
                {
                    if (isSupportedBy(temporal) == false)
                    {
                        throw new Exception("Unsupported field: WeekOfWeekBasedYear");
                    }
                    return IsoFields.Field.getWeekRange(LocalDate.from(temporal));
                }

                override public long getFrom(TemporalAccessor temporal)
                {
                    if (isSupportedBy(temporal) == false)
                    {
                        throw new Exception("Unsupported field: WeekOfWeekBasedYear");
                    }
                    return IsoFields.Field.getWeek(LocalDate.from(temporal));
                }
                /*@SuppressWarnings("unchecked")*/
                override public Temporal adjustInto(Temporal temporal, long newValue) /* if (is(R : Temporal)) */
                {
                    // calls getFrom() to check if supported
                    range().checkValidValue(newValue, this); // lenient range
                    return cast(Temporal) temporal.plus(Math.subtractExact(newValue,
                            getFrom(temporal)), ChronoUnit.WEEKS);
                }

                override public ChronoLocalDate resolve(Map!(TemporalField, Long) fieldValues,
                        TemporalAccessor partialTemporal, ResolverStyle resolverStyle)
                {
                    Long wbyLong = fieldValues.get(WEEK_BASED_YEAR);
                    Long dowLong = fieldValues.get(ChronoField.DAY_OF_WEEK);
                    if (wbyLong is null || dowLong is null)
                    {
                        return null;
                    }
                    int wby = WEEK_BASED_YEAR.range()
                        .checkValidIntValue(wbyLong.longValue(), WEEK_BASED_YEAR); // always validate
                    long wowby = fieldValues.get(WEEK_OF_WEEK_BASED_YEAR).longValue();
                    ensureIso(partialTemporal);
                    LocalDate date = LocalDate.of(wby, 1, 4);
                    if (resolverStyle == ResolverStyle.LENIENT)
                    {
                        long dow = dowLong.longValue(); // unvalidated
                        if (dow > 7)
                        {
                            date = date.plusWeeks((dow - 1) / 7);
                            dow = ((dow - 1) % 7) + 1;
                        }
                        else if (dow < 1)
                        {
                            date = date.plusWeeks(Math.subtractExact(dow, 7) / 7);
                            dow = ((dow + 6) % 7) + 1;
                        }
                        date = date.plusWeeks(Math.subtractExact(wowby, 1))
                            ._with(ChronoField.DAY_OF_WEEK, dow);
                    }
                    else
                    {
                        int dow = ChronoField.DAY_OF_WEEK.checkValidIntValue(dowLong.longValue()); // validated
                        if (wowby < 1 || wowby > 52)
                        {
                            if (resolverStyle == ResolverStyle.STRICT)
                            {
                                getWeekRange(date).checkValidValue(wowby, this); // only allow exact range
                            }
                            else
                            { // SMART
                                range().checkValidValue(wowby, this); // allow 1-53 rolling into next year
                            }
                        }
                        date = date.plusWeeks(wowby - 1)._with(ChronoField.DAY_OF_WEEK, dow);
                    }
                    fieldValues.remove(this);
                    fieldValues.remove(WEEK_BASED_YEAR);
                    fieldValues.remove(ChronoField.DAY_OF_WEEK);
                    return date;
                }

                /* override */
                // string getDisplayName(Locale locale)
                // {
                //     assert(locale, "locale");
                //     return toString();
                // }

                override public string toString()
                {
                    return "WeekOfWeekBasedYear";
                }

                override int opCmp(TemporalField obj)
                {
                    if (cast(IsoFields.Field)(obj) !is null)
                    {
                        IsoFields.Field other = cast(IsoFields.Field) obj;
                        return compare(toString(), other.toString());
                    }
                    return 0;
                }
            };

            IsoFields.Field.WEEK_BASED_YEAR = new class IsoFields.Field
            {
                override public TemporalUnit getBaseUnit()
                {
                    return IsoFields.WEEK_BASED_YEARS;
                }

                override public TemporalUnit getRangeUnit()
                {
                    return ChronoUnit.FOREVER;
                }

                override public ValueRange range()
                {
                    return ChronoField.YEAR.range();
                }

                override public bool isSupportedBy(TemporalAccessor temporal)
                {
                    return temporal.isSupported(ChronoField.EPOCH_DAY) && IsoFields.isIso(temporal);
                }

                override public long getFrom(TemporalAccessor temporal)
                {
                    if (isSupportedBy(temporal) == false)
                    {
                        throw new Exception("Unsupported field: WeekBasedYear");
                    }
                    return IsoFields.Field.getWeekBasedYear(LocalDate.from(temporal));
                }

                override public ValueRange rangeRefinedBy(TemporalAccessor temporal)
                {
                    if (isSupportedBy(temporal) == false)
                    {
                        throw new Exception("Unsupported field: WeekBasedYear");
                    }
                    return range() /* super.rangeRefinedBy(temporal) */ ;
                }
                /*@SuppressWarnings("unchecked")*/
                override public Temporal adjustInto(Temporal temporal, long newValue) /* if (is(R : Temporal)) */
                {
                    if (isSupportedBy(temporal) == false)
                    {
                        throw new Exception("Unsupported field: WeekBasedYear");
                    }
                    int newWby = range().checkValidIntValue(newValue, WEEK_BASED_YEAR); // strict check
                    LocalDate date = LocalDate.from(temporal);
                    int dow = date.get(ChronoField.DAY_OF_WEEK);
                    int week = getWeek(date);
                    if (week == 53 && getWeekRange(newWby) == 52)
                    {
                        week = 52;
                    }
                    LocalDate resolved = LocalDate.of(newWby, 1, 4); // 4th is guaranteed to be _in week one
                    int days = (dow - resolved.get(ChronoField.DAY_OF_WEEK)) + ((week - 1) * 7);
                    resolved = resolved.plusDays(days);
                    return cast(Temporal) temporal._with(resolved);
                }

                override string getDisplayName(Locale locale)
                {
                    assert(locale, "locale");
                    return toString();
                }

                override public string toString()
                {
                    return "WeekBasedYear";
                }

                override TemporalAccessor resolve(Map!(TemporalField, Long) fieldValues,
                        TemporalAccessor partialTemporal, ResolverStyle resolverStyle)
                {
                    return null;
                }

                override int opCmp(TemporalField obj)
                {
                    if (cast(IsoFields.Field)(obj) !is null)
                    {
                        IsoFields.Field other = cast(IsoFields.Field) obj;
                        return compare(toString(), other.toString());
                    }
                    return 0;
                }
            };

        }

        {
            IsoFields.Unit.WEEK_BASED_YEARS = new IsoFields.Unit("WeekBasedYears",
                    Duration.ofSeconds(31556952L));
            IsoFields.Unit.QUARTER_YEARS = new IsoFields.Unit("QuarterYears",
                    Duration.ofSeconds(31556952L / 4));
        }

        IsoFields.DAY_OF_QUARTER = IsoFields.Field.DAY_OF_QUARTER;
        IsoFields.QUARTER_OF_YEAR = IsoFields.Field.QUARTER_OF_YEAR;
        IsoFields.WEEK_OF_WEEK_BASED_YEAR = IsoFields.Field.WEEK_OF_WEEK_BASED_YEAR;
        IsoFields.WEEK_BASED_YEAR = IsoFields.Field.WEEK_BASED_YEAR;
        IsoFields.QUARTER_YEARS = IsoFields.Unit.QUARTER_YEARS;
    }

    {
        DateTimeFormatterBuilder.QUERY_REGION_ONLY = new class TemporalQuery!(ZoneId)
        {
            ZoneId queryFrom(TemporalAccessor temporal)
            {
                ZoneId zone = QueryHelper.query!ZoneId(temporal, TemporalQueries.zoneId());
                return (zone !is null && (cast(ZoneOffset)(zone) !is null) == false ? zone : null);
            }
        };

        DateTimeFormatterBuilder.FIELD_MAP = new HashMap!(char, TemporalField)();

        {
            DateTimeFormatterBuilder.ReducedPrinterParser.BASE_DATE = LocalDate.of(2000, 1, 1);
        }

        {
            DateTimeFormatterBuilder.OffsetIdPrinterParser.INSTANCE_ID_Z
                = new DateTimeFormatterBuilder.OffsetIdPrinterParser("+HH:MM:ss", "Z");
            DateTimeFormatterBuilder.OffsetIdPrinterParser.INSTANCE_ID_ZERO
                = new DateTimeFormatterBuilder.OffsetIdPrinterParser("+HH:MM:ss", "0");
        }

        {
            DateTimeFormatterBuilder.ZoneTextPrinterParser.cache = new HashMap!(string,
                    Map!(Locale, string[]))();
        }

        {
            DateTimeFormatterBuilder.LocalizedPrinterParser.FORMATTER_CACHE = new HashMap!(string,
                    DateTimeFormatter)(16, 0.75f /* , 2 */ );
        }

        DateTimeFormatterBuilder.LENGTH_SORT = new class Comparator!(string)
        {
            override public int compare(string str1, string str2)
            {
                return str1.length == str2.length ? str1.compare(str2)
                    : cast(int)(str1.length - str2.length);
            }
        };
        // SDF = SimpleDateFormat
        DateTimeFormatterBuilder.FIELD_MAP.put('G', ChronoField.ERA); // SDF, LDML (different to both for 1/2 chars)
        DateTimeFormatterBuilder.FIELD_MAP.put('y', ChronoField.YEAR_OF_ERA); // SDF, LDML
        DateTimeFormatterBuilder.FIELD_MAP.put('u', ChronoField.YEAR); // LDML (different _in SDF)
        DateTimeFormatterBuilder.FIELD_MAP.put('Q', IsoFields.QUARTER_OF_YEAR); // LDML (removed quarter from 310)
        DateTimeFormatterBuilder.FIELD_MAP.put('q', IsoFields.QUARTER_OF_YEAR); // LDML (stand-alone)
        DateTimeFormatterBuilder.FIELD_MAP.put('M', ChronoField.MONTH_OF_YEAR); // SDF, LDML
        DateTimeFormatterBuilder.FIELD_MAP.put('L', ChronoField.MONTH_OF_YEAR); // SDF, LDML (stand-alone)
        DateTimeFormatterBuilder.FIELD_MAP.put('D', ChronoField.DAY_OF_YEAR); // SDF, LDML
        DateTimeFormatterBuilder.FIELD_MAP.put('d', ChronoField.DAY_OF_MONTH); // SDF, LDML
        DateTimeFormatterBuilder.FIELD_MAP.put('F', ChronoField.ALIGNED_DAY_OF_WEEK_IN_MONTH); // SDF, LDML
        DateTimeFormatterBuilder.FIELD_MAP.put('E', ChronoField.DAY_OF_WEEK); // SDF, LDML (different to both for 1/2 chars)
        DateTimeFormatterBuilder.FIELD_MAP.put('c', ChronoField.DAY_OF_WEEK); // LDML (stand-alone)
        DateTimeFormatterBuilder.FIELD_MAP.put('e', ChronoField.DAY_OF_WEEK); // LDML (needs localized week number)
        DateTimeFormatterBuilder.FIELD_MAP.put('a', ChronoField.AMPM_OF_DAY); // SDF, LDML
        DateTimeFormatterBuilder.FIELD_MAP.put('H', ChronoField.HOUR_OF_DAY); // SDF, LDML
        DateTimeFormatterBuilder.FIELD_MAP.put('k', ChronoField.CLOCK_HOUR_OF_DAY); // SDF, LDML
        DateTimeFormatterBuilder.FIELD_MAP.put('K', ChronoField.HOUR_OF_AMPM); // SDF, LDML
        DateTimeFormatterBuilder.FIELD_MAP.put('h', ChronoField.CLOCK_HOUR_OF_AMPM); // SDF, LDML
        DateTimeFormatterBuilder.FIELD_MAP.put('m', ChronoField.MINUTE_OF_HOUR); // SDF, LDML
        DateTimeFormatterBuilder.FIELD_MAP.put('s', ChronoField.SECOND_OF_MINUTE); // SDF, LDML
        DateTimeFormatterBuilder.FIELD_MAP.put('S', ChronoField.NANO_OF_SECOND); // LDML (SDF uses milli-of-second number)
        DateTimeFormatterBuilder.FIELD_MAP.put('A', ChronoField.MILLI_OF_DAY); // LDML
        DateTimeFormatterBuilder.FIELD_MAP.put('n', ChronoField.NANO_OF_SECOND); // 310 (proposed for LDML)
        DateTimeFormatterBuilder.FIELD_MAP.put('N', ChronoField.NANO_OF_DAY); // 310 (proposed for LDML)
        // FIELD_MAP.put('g', JulianFields.MODIFIED_JULIAN_DAY);

        {
            DateTimeFormatterBuilder.SettingsParser.SENSITIVE = new DateTimeFormatterBuilder.SettingsParser(
                    0);
            DateTimeFormatterBuilder.SettingsParser.INSENSITIVE = new DateTimeFormatterBuilder.SettingsParser(
                    1);
            DateTimeFormatterBuilder.SettingsParser.STRICT = new DateTimeFormatterBuilder.SettingsParser(
                    2);
            DateTimeFormatterBuilder.SettingsParser.LENIENT = new DateTimeFormatterBuilder.SettingsParser(
                    3);
        }

    }

    {
        DateTimeFormatter.PARSED_EXCESS_DAYS = new class TemporalQuery!(Period)
        {
            Period queryFrom(TemporalAccessor t)
            {
                if (cast(Parsed)(t) !is null)
                {
                    return (cast(Parsed) t).excessDays;
                }
                else
                {
                    return Period.ZERO;
                }
            }
        };

        DateTimeFormatter.PARSED_LEAP_SECOND = new class TemporalQuery!(Boolean)
        {
            Boolean queryFrom(TemporalAccessor t)
            {
                if (cast(Parsed)(t) !is null)
                {
                    return new Boolean((cast(Parsed) t).leapSecond);
                }
                else
                {
                    return Boolean.FALSE;
                }
            }
        };

        DateTimeFormatter.BASIC_ISO_DATE = new DateTimeFormatterBuilder().parseCaseInsensitive()
            .appendValue(ChronoField.YEAR, 4).appendValue(ChronoField.MONTH_OF_YEAR, 2)
            .appendValue(ChronoField.DAY_OF_MONTH, 2).optionalStart().parseLenient().appendOffset("+HHMMss", "Z")
            .parseStrict().toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);

        DateTimeFormatter.ISO_INSTANT = new DateTimeFormatterBuilder()
            .parseCaseInsensitive().appendInstant().toFormatter(ResolverStyle.STRICT, null);

        DateTimeFormatter.ISO_WEEK_DATE = new DateTimeFormatterBuilder().parseCaseInsensitive()
            .appendValue(IsoFields.WEEK_BASED_YEAR, 4, 10, SignStyle.EXCEEDS_PAD).appendLiteral("-W")
            .appendValue(IsoFields.WEEK_OF_WEEK_BASED_YEAR,
                    2).appendLiteral('-').appendValue(ChronoField.DAY_OF_WEEK, 1).optionalStart().appendOffsetId()
            .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);

        DateTimeFormatter.ISO_ORDINAL_DATE = new DateTimeFormatterBuilder().parseCaseInsensitive()
            .appendValue(ChronoField.YEAR, 4, 10, SignStyle.EXCEEDS_PAD).appendLiteral('-')
            .appendValue(ChronoField.DAY_OF_YEAR, 3)
            .optionalStart().appendOffsetId().toFormatter(ResolverStyle.STRICT,
                    IsoChronology.INSTANCE);

        DateTimeFormatter.ISO_LOCAL_TIME = new DateTimeFormatterBuilder().appendValue(ChronoField.HOUR_OF_DAY, 2)
            .appendLiteral(':').appendValue(ChronoField.MINUTE_OF_HOUR, 2).optionalStart()
            .appendLiteral(':').appendValue(ChronoField.SECOND_OF_MINUTE, 2).optionalStart()
            .appendFraction(ChronoField.NANO_OF_SECOND, 0, 9, true).toFormatter(
                    ResolverStyle.STRICT, null);

        DateTimeFormatter.ISO_LOCAL_DATE = new DateTimeFormatterBuilder().appendValue(ChronoField.YEAR, 4,
                10, SignStyle.EXCEEDS_PAD).appendLiteral('-')
            .appendValue(ChronoField.MONTH_OF_YEAR, 2).appendLiteral('-')
            .appendValue(ChronoField.DAY_OF_MONTH, 2).toFormatter(ResolverStyle.STRICT,
                    IsoChronology.INSTANCE);

        DateTimeFormatter.ISO_LOCAL_DATE_TIME = new DateTimeFormatterBuilder()
            .parseCaseInsensitive().append(DateTimeFormatter.ISO_LOCAL_DATE)
            .appendLiteral('T').append(DateTimeFormatter.ISO_LOCAL_TIME)
            .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);

        DateTimeFormatter.ISO_OFFSET_DATE_TIME = new DateTimeFormatterBuilder().parseCaseInsensitive()
            .append(DateTimeFormatter.ISO_LOCAL_DATE_TIME).parseLenient().appendOffsetId()
            .parseStrict().toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);

        DateTimeFormatter.ISO_DATE_TIME = new DateTimeFormatterBuilder().append(DateTimeFormatter.ISO_LOCAL_DATE_TIME)
            .optionalStart().appendOffsetId().optionalStart().appendLiteral('[').parseCaseSensitive()
            .appendZoneRegionId().appendLiteral(']')
            .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);

        DateTimeFormatter.ISO_ZONED_DATE_TIME = new DateTimeFormatterBuilder()
            .append(DateTimeFormatter.ISO_OFFSET_DATE_TIME)
            .optionalStart().appendLiteral('[').parseCaseSensitive().appendZoneRegionId()
            .appendLiteral(']').toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);

        DateTimeFormatter.ISO_LOCAL_DATE_TIME = new DateTimeFormatterBuilder()
            .parseCaseInsensitive().append(DateTimeFormatter.ISO_LOCAL_DATE)
            .appendLiteral('T').append(DateTimeFormatter.ISO_LOCAL_TIME)
            .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);

        DateTimeFormatter.ISO_TIME = new DateTimeFormatterBuilder().parseCaseInsensitive()
            .append(DateTimeFormatter.ISO_LOCAL_TIME).optionalStart()
            .appendOffsetId().toFormatter(ResolverStyle.STRICT, null);

        DateTimeFormatter.ISO_OFFSET_TIME = new DateTimeFormatterBuilder().parseCaseInsensitive()
            .append(DateTimeFormatter.ISO_LOCAL_TIME).appendOffsetId()
            .toFormatter(ResolverStyle.STRICT, null);

        DateTimeFormatter.ISO_DATE = new DateTimeFormatterBuilder().parseCaseInsensitive()
            .append(DateTimeFormatter.ISO_LOCAL_DATE).optionalStart().appendOffsetId()
            .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);

        DateTimeFormatter.ISO_OFFSET_DATE = new DateTimeFormatterBuilder()
            .parseCaseInsensitive().append(DateTimeFormatter.ISO_LOCAL_DATE)
            .appendOffsetId().toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);

        // manually code maps to ensure correct data always used
        // (locale data can be changed by application code)
        Map!(Long, string) dow = new HashMap!(Long, string)();
        dow.put(new Long(1L), "Mon");
        dow.put(new Long(2L), "Tue");
        dow.put(new Long(3L), "Wed");
        dow.put(new Long(4L), "Thu");
        dow.put(new Long(5L), "Fri");
        dow.put(new Long(6L), "Sat");
        dow.put(new Long(7L), "Sun");
        Map!(Long, string) moy = new HashMap!(Long, string)();
        moy.put(new Long(1L), "Jan");
        moy.put(new Long(2L), "Feb");
        moy.put(new Long(3L), "Mar");
        moy.put(new Long(4L), "Apr");
        moy.put(new Long(5L), "May");
        moy.put(new Long(6L), "Jun");
        moy.put(new Long(7L), "Jul");
        moy.put(new Long(8L), "Aug");
        moy.put(new Long(9L), "Sep");
        moy.put(new Long(10L), "Oct");
        moy.put(new Long(11L), "Nov");
        moy.put(new Long(12L), "Dec");
        DateTimeFormatter.RFC_1123_DATE_TIME = new DateTimeFormatterBuilder().parseCaseInsensitive().parseLenient()
            .optionalStart().appendText(ChronoField.DAY_OF_WEEK, dow).appendLiteral(", ").optionalEnd()
            .appendValue(ChronoField.DAY_OF_MONTH, 1, 2, SignStyle.NOT_NEGATIVE).appendLiteral(' ')
            .appendText(ChronoField.MONTH_OF_YEAR,
                    moy).appendLiteral(' ').appendValue(ChronoField.YEAR, 4) // 2 digit year not handled
            .appendLiteral(' ')
            .appendValue(ChronoField.HOUR_OF_DAY, 2).appendLiteral(':').appendValue(ChronoField.MINUTE_OF_HOUR, 2)
            .optionalStart().appendLiteral(':').appendValue(ChronoField.SECOND_OF_MINUTE,
                    2).optionalEnd().appendLiteral(' ').appendOffset("+HHMM",
                    "GMT") // should handle UT/Z/EST/EDT/CST/CDT/MST/MDT/PST/MDT
            .toFormatter(ResolverStyle.SMART, IsoChronology.INSTANCE);
    }

    {
        // CACHE = new HashMap!(MapEntry!(TemporalField, Locale), Object)(16, 0.75f/* , 2 */);
        DateTimeTextProvider.COMPARATOR = new class Comparator!(MapEntry!(string, Long))
        {
            override public int compare(MapEntry!(string, Long) obj1, MapEntry!(string, Long) obj2)
            {
                return cast(int)(obj2.getKey().length - obj1.getKey().length); // longest to shortest
            }
        };

        DateTimeTextProvider.INSTANCE = new DateTimeTextProvider();
    }

    

    {
        Instant.EPOCH = new Instant(0, 0);
        Instant.MIN = Instant.ofEpochSecond(Instant.MIN_SECOND, 0);
        Instant.MAX = Instant.ofEpochSecond(Instant.MAX_SECOND, 999_999_999);
    }

    {
        for (int i = 0; i < LocalTime.HOURS.length; i++)
        {
            LocalTime.HOURS[i] = new LocalTime(i, 0, 0, 0);
        }
        LocalTime.MIDNIGHT = LocalTime.HOURS[0];
        LocalTime.NOON = LocalTime.HOURS[12];
        LocalTime.MIN = LocalTime.HOURS[0];
        LocalTime.MAX = new LocalTime(23, 59, 59, 999_999_999);
    }

    {
        LocalDate.MIN = LocalDate.of(Year.MIN_VALUE, 1, 1);
        LocalDate.MAX = LocalDate.of(Year.MAX_VALUE, 12, 31);
        LocalDate.EPOCH = LocalDate.of(1970, 1, 1);
    }

    {
        LocalDateTime.MIN = LocalDateTime.of(LocalDate.MIN, LocalTime.MIN);
        LocalDateTime.MAX = LocalDateTime.of(LocalDate.MAX, LocalTime.MAX);
    }

    {
        MonthDay.PARSER = new DateTimeFormatterBuilder().appendLiteral("--")
            .appendValue(ChronoField.MONTH_OF_YEAR, 2).appendLiteral('-')
            .appendValue(ChronoField.DAY_OF_MONTH, 2).toFormatter();
    }

    {
        OffsetDateTime.MIN = LocalDateTime.MIN.atOffset(ZoneOffset.MAX);
        OffsetDateTime.MAX = LocalDateTime.MAX.atOffset(ZoneOffset.MIN);
    }

    {
        OffsetTime.MIN = LocalTime.MIN.atOffset(ZoneOffset.MAX);
        OffsetTime.MAX = LocalTime.MAX.atOffset(ZoneOffset.MIN);
    }

    {
        Period.ZERO = new Period(0, 0, 0);
        Period.SUPPORTED_UNITS = new ArrayList!TemporalUnit();
        Period.SUPPORTED_UNITS.add(ChronoUnit.YEARS);
        Period.SUPPORTED_UNITS.add(ChronoUnit.MONTHS);
        Period.SUPPORTED_UNITS.add(ChronoUnit.DAYS);
    }

    {
        TemporalQueries.ZONE_ID = new class TemporalQuery!(ZoneId)
        {
            override public ZoneId queryFrom(TemporalAccessor temporal)
            {
                return QueryHelper.query!ZoneId(temporal, TemporalQueries.ZONE_ID);
            }

            override public string toString()
            {
                return "ZoneId";
            }
        };

        /**
     * A query for the {@code Chronology}.
     */
        TemporalQueries.CHRONO = new class TemporalQuery!(Chronology)
        {
            override public Chronology queryFrom(TemporalAccessor temporal)
            {
                return QueryHelper.query!Chronology(temporal, TemporalQueries.CHRONO);
            }

            override public string toString()
            {
                return "Chronology";
            }
        };

        /**
     * A query for the smallest supported unit.
     */
        TemporalQueries.PRECISION = new class TemporalQuery!(TemporalUnit)
        {
            override public TemporalUnit queryFrom(TemporalAccessor temporal)
            {
                return QueryHelper.query!TemporalUnit(temporal, TemporalQueries.PRECISION);
            }

            override public string toString()
            {
                return "Precision";
            }
        };

        //-----------------------------------------------------------------------
        /**
     * A query for {@code ZoneOffset} returning null if not found.
     */
        TemporalQueries.OFFSET = new class TemporalQuery!(ZoneOffset)
        {
            override public ZoneOffset queryFrom(TemporalAccessor temporal)
            {
                if (temporal.isSupported(ChronoField.OFFSET_SECONDS))
                {
                    return ZoneOffset.ofTotalSeconds(temporal.get(ChronoField.OFFSET_SECONDS));
                }
                return null;
            }

            override public string toString()
            {
                return "ZoneOffset";
            }
        };

        /**
     * A lenient query for the {@code ZoneId}, falling back to the {@code ZoneOffset}.
     */
        TemporalQueries.ZONE = new class TemporalQuery!(ZoneId)
        {
            override public ZoneId queryFrom(TemporalAccessor temporal)
            {
                ZoneId zone = QueryHelper.query!ZoneId(temporal, TemporalQueries.ZONE_ID);
                return (zone !is null ? zone
                        : QueryHelper.query!ZoneOffset(temporal, TemporalQueries.OFFSET));
            }

            override public string toString()
            {
                return "Zone";
            }
        };

        /**
     * A query for {@code LocalDate} returning null if not found.
     */
        TemporalQueries.LOCAL_DATE = new class TemporalQuery!(LocalDate)
        {
            override public LocalDate queryFrom(TemporalAccessor temporal)
            {
                if (temporal.isSupported(ChronoField.EPOCH_DAY))
                {
                    return LocalDate.ofEpochDay(temporal.getLong(ChronoField.EPOCH_DAY));
                }
                return null;
            }

            override public string toString()
            {
                return "LocalDate";
            }
        };

        /**
     * A query for {@code LocalTime} returning null if not found.
     */
        TemporalQueries.LOCAL_TIME = new class TemporalQuery!(LocalTime)
        {
            override public LocalTime queryFrom(TemporalAccessor temporal)
            {
                if (temporal.isSupported(ChronoField.NANO_OF_DAY))
                {
                    return LocalTime.ofNanoOfDay(temporal.getLong(ChronoField.NANO_OF_DAY));
                }
                return null;
            }

            override public string toString()
            {
                return "LocalTime";
            }
        };
    }

    {
        WeekFields.CACHE = new HashMap!(string, WeekFields)(4, 0.75f /* , 2 */ );
        WeekFields.ISO = new WeekFields(DayOfWeek.MONDAY, 4);
        WeekFields.ISO.do_init();
        WeekFields.SUNDAY_START = WeekFields.of(DayOfWeek.SUNDAY, 1);
        WeekFields.WEEK_BASED_YEARS = IsoFields.WEEK_BASED_YEARS;

        {
            WeekFields.ComputedDayOfField.DAY_OF_WEEK_RANGE = ValueRange.of(1, 7);
            WeekFields.ComputedDayOfField.WEEK_OF_MONTH_RANGE = ValueRange.of(0, 1, 4, 6);
            WeekFields.ComputedDayOfField.WEEK_OF_YEAR_RANGE = ValueRange.of(0, 1, 52, 54);
            WeekFields.ComputedDayOfField.WEEK_OF_WEEK_BASED_YEAR_RANGE = ValueRange.of(1, 52, 53);
        }
    }

    {
        Calendar.cachedLocaleData = new HashMap!(Locale, int[])(3);
    }

    {
        Year.PARSER = new DateTimeFormatterBuilder().appendValue(ChronoField.YEAR,
                4, 10, SignStyle.EXCEEDS_PAD).toFormatter();
    }

    {
        YearMonth.PARSER = new DateTimeFormatterBuilder().appendValue(ChronoField.YEAR, 4,
                10, SignStyle.EXCEEDS_PAD).appendLiteral('-')
            .appendValue(ChronoField.MONTH_OF_YEAR, 2).toFormatter();
    }

    {
        ZoneRules.EMPTY_LONG_ARRAY = new long[0];
        ZoneRules.EMPTY_LASTRULES = new ZoneOffsetTransitionRule[0];
        ZoneRules.EMPTY_LDT_ARRAY = new LocalDateTime[0];
    }

    {
        ZoneRulesProvider.ZONE_IDS = new HashSet!string();
        ZoneRulesProvider.PROVIDERS = new ArrayList!(ZoneRulesProvider)();
        ZoneRulesProvider.ZONES = new HashMap!(string, ZoneRulesProvider)(512, 0.75f /* , 2 */ );
        ZoneRulesProvider.registerProvider(new TzdbZoneRulesProvider());
        List!(ZoneRulesProvider) loaded = new ArrayList!(ZoneRulesProvider)();
        ServiceLoader!(ZoneRulesProvider) sl;
        foreach( obj ; sl.objs)
        {
            ZoneRulesProvider provider = obj.ctor();
            // try {
            //     provider = it.next();
            // } catch (ServiceConfigurationError ex) {
            //     if (ex.getCause(cast(SecurityException)()) !is null) {
            //         continue;  // ignore the security exception, try the next provider
            //     }
            //     throw ex;
            // }
            bool found = false;
            foreach(ZoneRulesProvider p ; loaded) {
                if (typeid(p) == typeid(provider)) {
                    found = true;
                }
            }
            if (!found) {
                ZoneRulesProvider.registerProvider0(provider);
                loaded.add(provider);
            }
        }
        // CopyOnWriteList could be slow if lots of providers and each added individually
        ZoneRulesProvider.PROVIDERS.addAll(loaded);
    }

    {
        ZoneId.SHORT_IDS = new HashMap!(string, string);
        ZoneId.SHORT_IDS.put("ACT", "Australia/Darwin");
        ZoneId.SHORT_IDS.put("AET", "Australia/Sydney");
        ZoneId.SHORT_IDS.put("AGT", "America/Argentina/Buenos_Aires");
        ZoneId.SHORT_IDS.put("ART", "Africa/Cairo");
        ZoneId.SHORT_IDS.put("AST", "America/Anchorage");
        ZoneId.SHORT_IDS.put("BET", "America/Sao_Paulo");
        ZoneId.SHORT_IDS.put("BST", "Asia/Dhaka");
        ZoneId.SHORT_IDS.put("CAT", "Africa/Harare");
        ZoneId.SHORT_IDS.put("CNT", "America/St_Johns");
        ZoneId.SHORT_IDS.put("CST", "America/Chicago");
        ZoneId.SHORT_IDS.put("CTT", "Asia/Shanghai");
        ZoneId.SHORT_IDS.put("EAT", "Africa/Addis_Ababa");
        ZoneId.SHORT_IDS.put("ECT", "Europe/Paris");
        ZoneId.SHORT_IDS.put("IET", "America/Indiana/Indianapolis");
        ZoneId.SHORT_IDS.put("IST", "Asia/Kolkata");
        ZoneId.SHORT_IDS.put("JST", "Asia/Tokyo");
        ZoneId.SHORT_IDS.put("MIT", "Pacific/Apia");
        ZoneId.SHORT_IDS.put("NET", "Asia/Yerevan");
        ZoneId.SHORT_IDS.put("NST", "Pacific/Auckland");
        ZoneId.SHORT_IDS.put("PLT", "Asia/Karachi");
        ZoneId.SHORT_IDS.put("PNT", "America/Phoenix");
        ZoneId.SHORT_IDS.put("PRT", "America/Puerto_Rico");
        ZoneId.SHORT_IDS.put("PST", "America/Los_Angeles");
        ZoneId.SHORT_IDS.put("SST", "Pacific/Guadalcanal");
        ZoneId.SHORT_IDS.put("VST", "Asia/Ho_Chi_Minh");
        ZoneId.SHORT_IDS.put("EST", "-05:00");
        ZoneId.SHORT_IDS.put("MST", "-07:00");
        ZoneId.SHORT_IDS.put("HST", "-10:00");

    }

    {
        ZoneOffset.SECONDS_CACHE = new HashMap!(Integer, ZoneOffset)(16, 0.75f /* , 4 */ );
        ZoneOffset.ID_CACHE = new HashMap!(string, ZoneOffset)(16, 0.75f /* , 4 */ );
        ZoneOffset.UTC = ZoneOffset.ofTotalSeconds(0);
        ZoneOffset.MIN = ZoneOffset.ofTotalSeconds(-ZoneOffset.MAX_SECONDS);
        ZoneOffset.MAX = ZoneOffset.ofTotalSeconds(ZoneOffset.MAX_SECONDS);
    }

    {
        IsoEra.BCE = new IsoEra(0);
        IsoEra.CE = new IsoEra(1);
    }

    {
        FormatStyle.FULL = new FormatStyle(0, "FULL");
        FormatStyle.LONG = new FormatStyle(1, "LONG");
        FormatStyle.MEDIUM = new FormatStyle(2, "MEDIUM");
        FormatStyle.SHORT = new FormatStyle(3, "SHORT");
    }

    {
        TextStyle.FULL = new TextStyle(0, Calendar.LONG_FORMAT, 0);
        TextStyle.FULL_STANDALONE = new TextStyle(1, Calendar.LONG_STANDALONE, 0);
        TextStyle.SHORT = new TextStyle(2, Calendar.SHORT_FORMAT, 1);
        TextStyle.SHORT_STANDALONE = new TextStyle(3, Calendar.SHORT_STANDALONE, 1);
        TextStyle.NARROW = new TextStyle(4, Calendar.NARROW_FORMAT, 1);
        TextStyle.NARROW_STANDALONE = new TextStyle(5, Calendar.NARROW_STANDALONE, 1);
        TextStyle._values ~= TextStyle.FULL;
        TextStyle._values ~= TextStyle.FULL_STANDALONE;
        TextStyle._values ~= TextStyle.SHORT;
        TextStyle._values ~= TextStyle.SHORT_STANDALONE;
        TextStyle._values ~= TextStyle.NARROW;
        TextStyle._values ~= TextStyle.NARROW_STANDALONE;
    }

    {
        /**
     * The singleton instance for the month of January with 31 days.
     * This has the numeric value of {@code 1}.
     */
        Month.JANUARY = new Month(0, "JANUARY");
        Month.ENUMS ~= Month.JANUARY;
        /**
     * The singleton instance for the month of February with 28 days, or 29 _in a leap year.
     * This has the numeric value of {@code 2}.
     */
        Month.FEBRUARY = new Month(1, "FEBRUARY");
        Month.ENUMS ~= Month.FEBRUARY;
        /**
     * The singleton instance for the month of March with 31 days.
     * This has the numeric value of {@code 3}.
     */
        Month.MARCH = new Month(2, "MARCH");
        Month.ENUMS ~= Month.MARCH;
        /**
     * The singleton instance for the month of April with 30 days.
     * This has the numeric value of {@code 4}.
     */
        Month.APRIL = new Month(3, "APRIL");
        Month.ENUMS ~= Month.APRIL;
        /**
     * The singleton instance for the month of May with 31 days.
     * This has the numeric value of {@code 5}.
     */
        Month.MAY = new Month(4, "MAY");
        Month.ENUMS ~= Month.MAY;
        /**
     * The singleton instance for the month of June with 30 days.
     * This has the numeric value of {@code 6}.
     */
        Month.JUNE = new Month(5, "JUNE");
        Month.ENUMS ~= Month.JUNE;
        /**
     * The singleton instance for the month of July with 31 days.
     * This has the numeric value of {@code 7}.
     */
        Month.JULY = new Month(6, "JULY");
        Month.ENUMS ~= Month.JULY;
        /**
     * The singleton instance for the month of August with 31 days.
     * This has the numeric value of {@code 8}.
     */
        Month.AUGUST = new Month(7, "AUGUST");
        Month.ENUMS ~= Month.AUGUST;
        /**
     * The singleton instance for the month of September with 30 days.
     * This has the numeric value of {@code 9}.
     */
        Month.SEPTEMBER = new Month(8, "SEPTEMBER");
        Month.ENUMS ~= Month.SEPTEMBER;
        /**
     * The singleton instance for the month of October with 31 days.
     * This has the numeric value of {@code 10}.
     */
        Month.OCTOBER = new Month(9, "OCTOBER");
        Month.ENUMS ~= Month.OCTOBER;
        /**
     * The singleton instance for the month of November with 30 days.
     * This has the numeric value of {@code 11}.
     */
        Month.NOVEMBER = new Month(10, "NOVEMBER");
        Month.ENUMS ~= Month.NOVEMBER;

        /**
     * The singleton instance for the month of December with 31 days.
     * This has the numeric value of {@code 12}.
     */
        Month.DECEMBER = new Month(11, "DECEMBER");

        Month.ENUMS ~= Month.DECEMBER;
    }

    {
        ZoneOffsetTransitionRule.TimeDefinition.UTC = new ZoneOffsetTransitionRule.TimeDefinition(0,
                "UTC");
        ZoneOffsetTransitionRule.TimeDefinition.WALL = new ZoneOffsetTransitionRule.TimeDefinition(1,
                "WALL");
        ZoneOffsetTransitionRule.TimeDefinition.STANDARD = new ZoneOffsetTransitionRule.TimeDefinition(2,
                "STANDARD");
        ZoneOffsetTransitionRule.TimeDefinition._values
            ~= ZoneOffsetTransitionRule.TimeDefinition.UTC;
        ZoneOffsetTransitionRule.TimeDefinition._values
            ~= ZoneOffsetTransitionRule.TimeDefinition.WALL;
        ZoneOffsetTransitionRule.TimeDefinition._values
            ~= ZoneOffsetTransitionRule.TimeDefinition.STANDARD;
    }

        /* version(HUNT_DEBUG) */ trace("Init shared static this end");
}
