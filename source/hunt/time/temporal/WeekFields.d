
module hunt.time.temporal.WeekFields;

import hunt.time.temporal.ChronoField;
import hunt.time.temporal.ChronoUnit;

import hunt.lang.exception;

//import hunt.io.ObjectInputStream;
import hunt.io.Serializable;
import hunt.time.DateTimeException;
import hunt.time.DayOfWeek;
import hunt.time.chrono.ChronoLocalDate;
import hunt.time.chrono.Chronology;
import hunt.time.format.ResolverStyle;
import hunt.time.util.Locale;
import hunt.container.Map;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.TemporalUnit;
import hunt.time.temporal.ValueRange;
import hunt.time.temporal.Temporal;
import hunt.time.temporal.TemporalAccessor;
import hunt.lang;
import hunt.time.temporal.IsoFields;
import hunt.container.HashMap;
import std.conv;
import hunt.lang.exception;
import hunt.util.Comparator;

// import sun.util.locale.provider.CalendarDataUtility;
// import sun.util.locale.provider.LocaleProviderAdapter;
// import sun.util.locale.provider.LocaleResources;

/**
 * Localized definitions of the day-of-week, week-of-month and week-of-year fields.
 * !(p)
 * A standard week is seven days long, but cultures have different definitions for some
 * other aspects of a week. This class represents the definition of the week, for the
 * purpose of providing {@link TemporalField} instances.
 * !(p)
 * WeekFields provides five fields,
 * {@link #dayOfWeek()}, {@link #_weekOfMonth()}, {@link #weekOfYear()},
 * {@link #_weekOfWeekBasedYear()}, and {@link #_weekBasedYear()}
 * that provide access to the values from any {@linkplain Temporal temporal object}.
 * !(p)
 * The computations for day-of-week, week-of-month, and week-of-year are based
 * on the  {@linkplain ChronoField#YEAR proleptic-year},
 * {@linkplain ChronoField#MONTH_OF_YEAR month-of-year},
 * {@linkplain ChronoField#DAY_OF_MONTH day-of-month}, and
 * {@linkplain ChronoField#DAY_OF_WEEK ISO day-of-week} which are based on the
 * {@linkplain ChronoField#EPOCH_DAY epoch-day} and the chronology.
 * The values may not be aligned with the {@linkplain ChronoField#YEAR_OF_ERA year-of-Era}
 * depending on the Chronology.
 * !(p)A week is defined by:
 * !(ul)
 * !(li)The first day-of-week.
 * For example, the ISO-8601 standard considers Monday to be the first day-of-week.
 * !(li)The minimal number of days _in the first week.
 * For example, the ISO-8601 standard counts the first week as needing at least 4 days.
 * </ul>
 * Together these two values allow a year or month to be divided into weeks.
 *
 * !(h3)Week of Month</h3>
 * One field is used: week-of-month.
 * The calculation ensures that weeks never overlap a month boundary.
 * The month is divided into periods where each period starts on the defined first day-of-week.
 * The earliest period is referred to as week 0 if it has less than the minimal number of days
 * and week 1 if it has at least the minimal number of days.
 *
 * <table class=striped style="text-align: left">
 * !(caption)Examples of WeekFields</caption>
 * !(thead)
 * !(tr)<th scope="col">Date</th><th scope="col">Day-of-week</th>
 *  <th scope="col">First day: Monday!(br)Minimal days: 4</th><th scope="col">First day: Monday!(br)Minimal days: 5</th></tr>
 * </thead>
 * !(tbody)
 * !(tr)<th scope="row">2008-12-31</th>!(td)Wednesday</td>
 *  !(td)Week 5 of December 2008</td>!(td)Week 5 of December 2008</td></tr>
 * !(tr)<th scope="row">2009-01-01</th>!(td)Thursday</td>
 *  !(td)Week 1 of January 2009</td>!(td)Week 0 of January 2009</td></tr>
 * !(tr)<th scope="row">2009-01-04</th>!(td)Sunday</td>
 *  !(td)Week 1 of January 2009</td>!(td)Week 0 of January 2009</td></tr>
 * !(tr)<th scope="row">2009-01-05</th>!(td)Monday</td>
 *  !(td)Week 2 of January 2009</td>!(td)Week 1 of January 2009</td></tr>
 * </tbody>
 * </table>
 *
 * !(h3)Week of Year</h3>
 * One field is used: week-of-year.
 * The calculation ensures that weeks never overlap a year boundary.
 * The year is divided into periods where each period starts on the defined first day-of-week.
 * The earliest period is referred to as week 0 if it has less than the minimal number of days
 * and week 1 if it has at least the minimal number of days.
 *
 * !(h3)Week Based Year</h3>
 * Two fields are used for week-based-year, one for the
 * {@link #_weekOfWeekBasedYear() week-of-week-based-year} and one for
 * {@link #_weekBasedYear() week-based-year}.  In a week-based-year, each week
 * belongs to only a single year.  Week 1 of a year is the first week that
 * starts on the first day-of-week and has at least the minimum number of days.
 * The first and last weeks of a year may contain days from the
 * previous calendar year or next calendar year respectively.
 *
 * <table class=striped style="text-align: left;">
 * !(caption)Examples of WeekFields for week-based-year</caption>
 * !(thead)
 * !(tr)<th scope="col">Date</th><th scope="col">Day-of-week</th>
 *  <th scope="col">First day: Monday!(br)Minimal days: 4</th><th scope="col">First day: Monday!(br)Minimal days: 5</th></tr>
 * </thead>
 * !(tbody)
 * !(tr)<th scope="row">2008-12-31</th>!(td)Wednesday</td>
 *  !(td)Week 1 of 2009</td>!(td)Week 53 of 2008</td></tr>
 * !(tr)<th scope="row">2009-01-01</th>!(td)Thursday</td>
 *  !(td)Week 1 of 2009</td>!(td)Week 53 of 2008</td></tr>
 * !(tr)<th scope="row">2009-01-04</th>!(td)Sunday</td>
 *  !(td)Week 1 of 2009</td>!(td)Week 53 of 2008</td></tr>
 * !(tr)<th scope="row">2009-01-05</th>!(td)Monday</td>
 *  !(td)Week 2 of 2009</td>!(td)Week 1 of 2009</td></tr>
 * </tbody>
 * </table>
 *
 * @implSpec
 * This class is immutable and thread-safe.
 *
 * @since 1.8
 */
public final class WeekFields : Serializable
{
    // implementation notes
    // querying week-of-month or week-of-year should return the week value bound within the month/year
    // however, setting the week value should be lenient (use plus/minus weeks)
    // allow week-of-month outer _range [0 to 6]
    // allow week-of-year outer _range [0 to 54]
    // this is because callers shouldn't be expected to know the details of validity

    /**
     * The cache of rules by firstDayOfWeek plus minimalDays.
     * Initialized first to be available for definition of ISO, etc.
     */
    // private static final ConcurrentMap!(string, WeekFields) CACHE = new ConcurrentHashMap!()(4, 0.75f, 2);
    __gshared HashMap!(string, WeekFields) CACHE;

    /**
     * The ISO-8601 definition, where a week starts on Monday and the first week
     * has a minimum of 4 days.
     * !(p)
     * The ISO-8601 standard defines a calendar system based on weeks.
     * It uses the week-based-year and week-of-week-based-year concepts to split
     * up the passage of days instead of the standard year/month/day.
     * !(p)
     * Note that the first week may start _in the previous calendar year.
     * Note also that the first few days of a calendar year may be _in the
     * week-based-year corresponding to the previous calendar year.
     */
    __gshared WeekFields ISO;

    /**
     * The common definition of a week that starts on Sunday and the first week
     * has a minimum of 1 day.
     * !(p)
     * Defined as starting on Sunday and with a minimum of 1 day _in the month.
     * This week definition is _in use _in the US and other European countries.
     */
    __gshared WeekFields SUNDAY_START;

    /**
     * The unit that represents week-based-years for the purpose of addition and subtraction.
     * !(p)
     * This allows a number of week-based-years to be added to, or subtracted from, a date.
     * The unit is equal to either 52 or 53 weeks.
     * The estimated duration of a week-based-year is the same as that of a standard ISO
     * year at {@code 365.2425 Days}.
     * !(p)
     * The rules for addition add the number of week-based-years to the existing value
     * for the week-based-year field retaining the week-of-week-based-year
     * and day-of-week, unless the week number it too large for the target year.
     * In that case, the week is set to the last week of the year
     * with the same day-of-week.
     * !(p)
     * This unit is an immutable and thread-safe singleton.
     */
    __gshared TemporalUnit WEEK_BASED_YEARS;

    /**
     * Serialization version.
     */
    private enum long serialVersionUID = -1177360819670808121L;

    /**
     * The first day-of-week.
     */
    private DayOfWeek firstDayOfWeek;
    /**
     * The minimal number of days _in the first week.
     */
    private int minimalDays;
    /**
     * The field used to access the computed DayOfWeek.
     */
    private  /*transient*/ TemporalField _dayOfWeek;
    /**
     * The field used to access the computed WeekOfMonth.
     */
    private  /*transient*/ TemporalField _weekOfMonth;
    /**
     * The field used to access the computed WeekOfYear.
     */
    private  /*transient*/ TemporalField _weekOfYear;
    /**
     * The field that represents the week-of-week-based-year.
     * !(p)
     * This field allows the week of the week-based-year value to be queried and set.
     * !(p)
     * This unit is an immutable and thread-safe singleton.
     */
    private  /*transient*/ TemporalField _weekOfWeekBasedYear;
    /**
     * The field that represents the week-based-year.
     * !(p)
     * This field allows the week-based-year value to be queried and set.
     * !(p)
     * This unit is an immutable and thread-safe singleton.
     */
    private  /*transient*/ TemporalField _weekBasedYear;

    public void do_init()
    {
        _dayOfWeek = ComputedDayOfField.ofDayOfWeekField(this);
        _weekOfMonth = ComputedDayOfField.ofWeekOfMonthField(this);
        _weekOfYear = ComputedDayOfField.ofWeekOfYearField(this);
        _weekOfWeekBasedYear = ComputedDayOfField.ofWeekOfWeekBasedYearField(this);
        _weekBasedYear = ComputedDayOfField.ofWeekBasedYearField(this);
    }

    // shared static this()
    // {
    //     CACHE = new HashMap!(string, WeekFields)(4, 0.75f /* , 2 */ );
    //     ISO = new WeekFields(DayOfWeek.MONDAY, 4);
    //     ISO.do_init();
    //     SUNDAY_START = WeekFields.of(DayOfWeek.SUNDAY, 1);
    //     WEEK_BASED_YEARS = IsoFields.WEEK_BASED_YEARS;
    // }
    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code WeekFields} appropriate for a locale.
     * !(p)
     * This will look up appropriate values from the provider of localization data.
     * If the locale contains "fw" (First day of week) and/or "rg"
     * (Region Override) <a href="../../util/Locale.html#def_locale_extension">
     * Unicode extensions</a>, returned instance will reflect the values specified with
     * those extensions. If both "fw" and "rg" are specified, the value from
     * the "fw" extension supersedes the implicit one from the "rg" extension.
     *
     * @param locale  the locale to use, not null
     * @return the week-definition, not null
     */
    public static WeekFields of(Locale locale)
    {
        assert(locale, "locale");

        ///@gxc
        // int calDow = CalendarDataUtility.retrieveFirstDayOfWeek(locale);
        // DayOfWeek dow = DayOfWeek.SUNDAY.plus(calDow - 1);
        // int minDays = CalendarDataUtility.retrieveMinimalDaysInFirstWeek(locale);
        DayOfWeek dow = DayOfWeek.SUNDAY.plus(2 - 1);
        int minDays = 7;
        return WeekFields.of(dow, minDays);
    }

    /**
     * Obtains an instance of {@code WeekFields} from the first day-of-week and minimal days.
     * !(p)
     * The first day-of-week defines the ISO {@code DayOfWeek} that is day 1 of the week.
     * The minimal number of days _in the first week defines how many days must be present
     * _in a month or year, starting from the first day-of-week, before the week is counted
     * as the first week. A value of 1 will count the first day of the month or year as part
     * of the first week, whereas a value of 7 will require the whole seven days to be _in
     * the new month or year.
     * !(p)
     * WeekFields instances are singletons; for each unique combination
     * of {@code firstDayOfWeek} and {@code minimalDaysInFirstWeek}
     * the same instance will be returned.
     *
     * @param firstDayOfWeek  the first day of the week, not null
     * @param minimalDaysInFirstWeek  the minimal number of days _in the first week, from 1 to 7
     * @return the week-definition, not null
     * @throws IllegalArgumentException if the minimal days value is less than one
     *      or greater than 7
     */
    public static WeekFields of(DayOfWeek firstDayOfWeek, int minimalDaysInFirstWeek)
    {
        string key = firstDayOfWeek.toString() ~ minimalDaysInFirstWeek.to!string;
        WeekFields rules = CACHE.get(key);
        if (rules is null)
        {
            rules = new WeekFields(firstDayOfWeek, minimalDaysInFirstWeek);
            rules.do_init();
            CACHE.putIfAbsent(key, rules);
            rules = CACHE.get(key);
        }
        return rules;
    }

    //-----------------------------------------------------------------------
    /**
     * Creates an instance of the definition.
     *
     * @param firstDayOfWeek  the first day of the week, not null
     * @param minimalDaysInFirstWeek  the minimal number of days _in the first week, from 1 to 7
     * @throws IllegalArgumentException if the minimal days value is invalid
     */
    this(DayOfWeek firstDayOfWeek, int minimalDaysInFirstWeek)
    {
        assert(firstDayOfWeek, "firstDayOfWeek");
        if (minimalDaysInFirstWeek < 1 || minimalDaysInFirstWeek > 7)
        {
            throw new IllegalArgumentException("Minimal number of days is invalid");
        }
        this.firstDayOfWeek = firstDayOfWeek;
        this.minimalDays = minimalDaysInFirstWeek;
    }

    //-----------------------------------------------------------------------
    /**
     * Restore the state of a WeekFields from the stream.
     * Check that the values are valid.
     *
     * @param s the stream to read
     * @throws InvalidObjectException if the serialized object has an invalid
     *     value for firstDayOfWeek or minimalDays.
     * @throws ClassNotFoundException if a class cannot be resolved
     */
    ///@gxc
    // private void readObject(ObjectInputStream s)
    //      /*throws IOException, ClassNotFoundException, InvalidObjectException*/
    // {
    //     s.defaultReadObject();
    //     if (firstDayOfWeek is null) {
    //         throw new InvalidObjectException("firstDayOfWeek is null");
    //     }

    //     if (minimalDays < 1 || minimalDays > 7) {
    //         throw new InvalidObjectException("Minimal number of days is invalid");
    //     }
    // }

    /**
     * Return the singleton WeekFields associated with the
     * {@code firstDayOfWeek} and {@code minimalDays}.
     * @return the singleton WeekFields for the firstDayOfWeek and minimalDays.
     * @throws InvalidObjectException if the serialized object has invalid
     *     values for firstDayOfWeek or minimalDays.
     */
    private Object readResolve() /*throws InvalidObjectException*/
    {
        try
        {
            return WeekFields.of(firstDayOfWeek, minimalDays);
        }
        catch (IllegalArgumentException iae)
        {
            throw new InvalidObjectException("Invalid serialized WeekFields: " ~ iae.msg);
        }
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the first day-of-week.
     * !(p)
     * The first day-of-week varies by culture.
     * For example, the US uses Sunday, while France and the ISO-8601 standard use Monday.
     * This method returns the first day using the standard {@code DayOfWeek} enum.
     *
     * @return the first day-of-week, not null
     */
    public DayOfWeek getFirstDayOfWeek()
    {
        return firstDayOfWeek;
    }

    /**
     * Gets the minimal number of days _in the first week.
     * !(p)
     * The number of days considered to define the first week of a month or year
     * varies by culture.
     * For example, the ISO-8601 requires 4 days (more than half a week) to
     * be present before counting the first week.
     *
     * @return the minimal number of days _in the first week of a month or year, from 1 to 7
     */
    public int getMinimalDaysInFirstWeek()
    {
        return minimalDays;
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a field to access the day of week based on this {@code WeekFields}.
     * !(p)
     * This is similar to {@link ChronoField#DAY_OF_WEEK} but uses values for
     * the day-of-week based on this {@code WeekFields}.
     * The days are numbered from 1 to 7 where the
     * {@link #getFirstDayOfWeek() first day-of-week} is assigned the value 1.
     * !(p)
     * For example, if the first day-of-week is Sunday, then that will have the
     * value 1, with other days ranging from Monday as 2 to Saturday as 7.
     * !(p)
     * In the resolving phase of parsing, a localized day-of-week will be converted
     * to a standardized {@code ChronoField} day-of-week.
     * The day-of-week must be _in the valid _range 1 to 7.
     * Other fields _in this class build dates using the standardized day-of-week.
     *
     * @return a field providing access to the day-of-week with localized numbering, not null
     */
    public TemporalField dayOfWeek()
    {
        return _dayOfWeek;
    }

    /**
     * Returns a field to access the week of month based on this {@code WeekFields}.
     * !(p)
     * This represents the concept of the count of weeks within the month where weeks
     * start on a fixed day-of-week, such as Monday.
     * This field is typically used with {@link WeekFields#dayOfWeek()}.
     * !(p)
     * Week one (1) is the week starting on the {@link WeekFields#getFirstDayOfWeek}
     * where there are at least {@link WeekFields#getMinimalDaysInFirstWeek()} days _in the month.
     * Thus, week one may start up to {@code minDays} days before the start of the month.
     * If the first week starts after the start of the month then the period before is week zero (0).
     * !(p)
     * For example:!(br)
     * - if the 1st day of the month is a Monday, week one starts on the 1st and there is no week zero!(br)
     * - if the 2nd day of the month is a Monday, week one starts on the 2nd and the 1st is _in week zero!(br)
     * - if the 4th day of the month is a Monday, week one starts on the 4th and the 1st to 3rd is _in week zero!(br)
     * - if the 5th day of the month is a Monday, week two starts on the 5th and the 1st to 4th is _in week one!(br)
     * !(p)
     * This field can be used with any calendar system.
     * !(p)
     * In the resolving phase of parsing, a date can be created from a year,
     * week-of-month, month-of-year and day-of-week.
     * !(p)
     * In {@linkplain ResolverStyle#STRICT strict mode}, all four fields are
     * validated against their _range of valid values. The week-of-month field
     * is validated to ensure that the resulting month is the month requested.
     * !(p)
     * In {@linkplain ResolverStyle#SMART smart mode}, all four fields are
     * validated against their _range of valid values. The week-of-month field
     * is validated from 0 to 6, meaning that the resulting date can be _in a
     * different month to that specified.
     * !(p)
     * In {@linkplain ResolverStyle#LENIENT lenient mode}, the year and day-of-week
     * are validated against the _range of valid values. The resulting date is calculated
     * equivalent to the following four stage approach.
     * First, create a date on the first day of the first week of January _in the requested year.
     * Then take the month-of-year, subtract one, and add the amount _in months to the date.
     * Then take the week-of-month, subtract one, and add the amount _in weeks to the date.
     * Finally, adjust to the correct day-of-week within the localized week.
     *
     * @return a field providing access to the week-of-month, not null
     */
    public TemporalField weekOfMonth()
    {
        return _weekOfMonth;
    }

    /**
     * Returns a field to access the week of year based on this {@code WeekFields}.
     * !(p)
     * This represents the concept of the count of weeks within the year where weeks
     * start on a fixed day-of-week, such as Monday.
     * This field is typically used with {@link WeekFields#dayOfWeek()}.
     * !(p)
     * Week one(1) is the week starting on the {@link WeekFields#getFirstDayOfWeek}
     * where there are at least {@link WeekFields#getMinimalDaysInFirstWeek()} days _in the year.
     * Thus, week one may start up to {@code minDays} days before the start of the year.
     * If the first week starts after the start of the year then the period before is week zero (0).
     * !(p)
     * For example:!(br)
     * - if the 1st day of the year is a Monday, week one starts on the 1st and there is no week zero!(br)
     * - if the 2nd day of the year is a Monday, week one starts on the 2nd and the 1st is _in week zero!(br)
     * - if the 4th day of the year is a Monday, week one starts on the 4th and the 1st to 3rd is _in week zero!(br)
     * - if the 5th day of the year is a Monday, week two starts on the 5th and the 1st to 4th is _in week one!(br)
     * !(p)
     * This field can be used with any calendar system.
     * !(p)
     * In the resolving phase of parsing, a date can be created from a year,
     * week-of-year and day-of-week.
     * !(p)
     * In {@linkplain ResolverStyle#STRICT strict mode}, all three fields are
     * validated against their _range of valid values. The week-of-year field
     * is validated to ensure that the resulting year is the year requested.
     * !(p)
     * In {@linkplain ResolverStyle#SMART smart mode}, all three fields are
     * validated against their _range of valid values. The week-of-year field
     * is validated from 0 to 54, meaning that the resulting date can be _in a
     * different year to that specified.
     * !(p)
     * In {@linkplain ResolverStyle#LENIENT lenient mode}, the year and day-of-week
     * are validated against the _range of valid values. The resulting date is calculated
     * equivalent to the following three stage approach.
     * First, create a date on the first day of the first week _in the requested year.
     * Then take the week-of-year, subtract one, and add the amount _in weeks to the date.
     * Finally, adjust to the correct day-of-week within the localized week.
     *
     * @return a field providing access to the week-of-year, not null
     */
    public TemporalField weekOfYear()
    {
        return _weekOfYear;
    }

    /**
     * Returns a field to access the week of a week-based-year based on this {@code WeekFields}.
     * !(p)
     * This represents the concept of the count of weeks within the year where weeks
     * start on a fixed day-of-week, such as Monday and each week belongs to exactly one year.
     * This field is typically used with {@link WeekFields#dayOfWeek()} and
     * {@link WeekFields#_weekBasedYear()}.
     * !(p)
     * Week one(1) is the week starting on the {@link WeekFields#getFirstDayOfWeek}
     * where there are at least {@link WeekFields#getMinimalDaysInFirstWeek()} days _in the year.
     * If the first week starts after the start of the year then the period before
     * is _in the last week of the previous year.
     * !(p)
     * For example:!(br)
     * - if the 1st day of the year is a Monday, week one starts on the 1st!(br)
     * - if the 2nd day of the year is a Monday, week one starts on the 2nd and
     *   the 1st is _in the last week of the previous year!(br)
     * - if the 4th day of the year is a Monday, week one starts on the 4th and
     *   the 1st to 3rd is _in the last week of the previous year!(br)
     * - if the 5th day of the year is a Monday, week two starts on the 5th and
     *   the 1st to 4th is _in week one!(br)
     * !(p)
     * This field can be used with any calendar system.
     * !(p)
     * In the resolving phase of parsing, a date can be created from a week-based-year,
     * week-of-year and day-of-week.
     * !(p)
     * In {@linkplain ResolverStyle#STRICT strict mode}, all three fields are
     * validated against their _range of valid values. The week-of-year field
     * is validated to ensure that the resulting week-based-year is the
     * week-based-year requested.
     * !(p)
     * In {@linkplain ResolverStyle#SMART smart mode}, all three fields are
     * validated against their _range of valid values. The week-of-week-based-year field
     * is validated from 1 to 53, meaning that the resulting date can be _in the
     * following week-based-year to that specified.
     * !(p)
     * In {@linkplain ResolverStyle#LENIENT lenient mode}, the year and day-of-week
     * are validated against the _range of valid values. The resulting date is calculated
     * equivalent to the following three stage approach.
     * First, create a date on the first day of the first week _in the requested week-based-year.
     * Then take the week-of-week-based-year, subtract one, and add the amount _in weeks to the date.
     * Finally, adjust to the correct day-of-week within the localized week.
     *
     * @return a field providing access to the week-of-week-based-year, not null
     */
    public TemporalField weekOfWeekBasedYear()
    {
        return _weekOfWeekBasedYear;
    }

    /**
     * Returns a field to access the year of a week-based-year based on this {@code WeekFields}.
     * !(p)
     * This represents the concept of the year where weeks start on a fixed day-of-week,
     * such as Monday and each week belongs to exactly one year.
     * This field is typically used with {@link WeekFields#dayOfWeek()} and
     * {@link WeekFields#_weekOfWeekBasedYear()}.
     * !(p)
     * Week one(1) is the week starting on the {@link WeekFields#getFirstDayOfWeek}
     * where there are at least {@link WeekFields#getMinimalDaysInFirstWeek()} days _in the year.
     * Thus, week one may start before the start of the year.
     * If the first week starts after the start of the year then the period before
     * is _in the last week of the previous year.
     * !(p)
     * This field can be used with any calendar system.
     * !(p)
     * In the resolving phase of parsing, a date can be created from a week-based-year,
     * week-of-year and day-of-week.
     * !(p)
     * In {@linkplain ResolverStyle#STRICT strict mode}, all three fields are
     * validated against their _range of valid values. The week-of-year field
     * is validated to ensure that the resulting week-based-year is the
     * week-based-year requested.
     * !(p)
     * In {@linkplain ResolverStyle#SMART smart mode}, all three fields are
     * validated against their _range of valid values. The week-of-week-based-year field
     * is validated from 1 to 53, meaning that the resulting date can be _in the
     * following week-based-year to that specified.
     * !(p)
     * In {@linkplain ResolverStyle#LENIENT lenient mode}, the year and day-of-week
     * are validated against the _range of valid values. The resulting date is calculated
     * equivalent to the following three stage approach.
     * First, create a date on the first day of the first week _in the requested week-based-year.
     * Then take the week-of-week-based-year, subtract one, and add the amount _in weeks to the date.
     * Finally, adjust to the correct day-of-week within the localized week.
     *
     * @return a field providing access to the week-based-year, not null
     */
    public TemporalField weekBasedYear()
    {
        return _weekBasedYear;
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if this {@code WeekFields} is equal to the specified object.
     * !(p)
     * The comparison is based on the entire state of the rules, which is
     * the first day-of-week and minimal days.
     *
     * @param object  the other rules to compare to, null returns false
     * @return true if this is equal to the specified rules
     */
    override public bool opEquals(Object object)
    {
        if (this is object)
        {
            return true;
        }
        if (cast(WeekFields)(object) !is null)
        {
            return toHash() == object.toHash();
        }
        return false;
    }

    /**
     * A hash code for this {@code WeekFields}.
     *
     * @return a suitable hash code
     */
    override public size_t toHash() @trusted nothrow
    {
        try
        {
            return firstDayOfWeek.ordinal() * 7 + minimalDays;
        }
        catch (Exception e)
        {
        }
        return int.init;
    }

    //-----------------------------------------------------------------------
    /**
     * A string representation of this {@code WeekFields} instance.
     *
     * @return the string representation, not null
     */
    override public string toString()
    {
        return "WeekFields[" ~ firstDayOfWeek.toString ~ ',' ~ minimalDays.to!string ~ ']';
    }

    //-----------------------------------------------------------------------
    /**
     * Field type that computes DayOfWeek, WeekOfMonth, and WeekOfYear
     * based on a WeekFields.
     * A separate Field instance is required for each different WeekFields;
     * combination of start of week and minimum number of days.
     * Constructors are provided to create fields for DayOfWeek, WeekOfMonth,
     * and WeekOfYear.
     */
    static class ComputedDayOfField : TemporalField
    {

        /**
         * Returns a field to access the day of week,
         * computed based on a WeekFields.
         * !(p)
         * The WeekDefintion of the first day of the week is used with
         * the ISO DAY_OF_WEEK field to compute week boundaries.
         */
        static ComputedDayOfField ofDayOfWeekField(WeekFields weekDef)
        {
            return new ComputedDayOfField("DayOfWeek", weekDef,
                    ChronoUnit.DAYS, ChronoUnit.WEEKS, DAY_OF_WEEK_RANGE);
        }

        /**
         * Returns a field to access the week of month,
         * computed based on a WeekFields.
         * @see WeekFields#_weekOfMonth()
         */
        static ComputedDayOfField ofWeekOfMonthField(WeekFields weekDef)
        {
            return new ComputedDayOfField("WeekOfMonth", weekDef,
                    ChronoUnit.WEEKS, ChronoUnit.MONTHS, WEEK_OF_MONTH_RANGE);
        }

        /**
         * Returns a field to access the week of year,
         * computed based on a WeekFields.
         * @see WeekFields#weekOfYear()
         */
        static ComputedDayOfField ofWeekOfYearField(WeekFields weekDef)
        {
            return new ComputedDayOfField("WeekOfYear", weekDef,
                    ChronoUnit.WEEKS, ChronoUnit.YEARS, WEEK_OF_YEAR_RANGE);
        }

        /**
         * Returns a field to access the week of week-based-year,
         * computed based on a WeekFields.
         * @see WeekFields#_weekOfWeekBasedYear()
         */
        static ComputedDayOfField ofWeekOfWeekBasedYearField(WeekFields weekDef)
        {
            return new ComputedDayOfField("WeekOfWeekBasedYear", weekDef,
                    ChronoUnit.WEEKS, IsoFields.WEEK_BASED_YEARS, WEEK_OF_WEEK_BASED_YEAR_RANGE);
        }

        /**
         * Returns a field to access the week of week-based-year,
         * computed based on a WeekFields.
         * @see WeekFields#_weekBasedYear()
         */
        static ComputedDayOfField ofWeekBasedYearField(WeekFields weekDef)
        {
            return new ComputedDayOfField("WeekBasedYear", weekDef,
                    IsoFields.WEEK_BASED_YEARS, ChronoUnit.FOREVER, ChronoField.YEAR.range());
        }

        /**
         * Return a new week-based-year date of the Chronology, year, week-of-year,
         * and dow of week.
         * @param chrono The chronology of the new date
         * @param yowby the year of the week-based-year
         * @param wowby the week of the week-based-year
         * @param dow the day of the week
         * @return a ChronoLocalDate for the requested year, week of year, and day of week
         */
        private ChronoLocalDate ofWeekBasedYear(Chronology chrono, int yowby, int wowby, int dow)
        {
            ChronoLocalDate date = chrono.date(yowby, 1, 1);
            int ldow = localizedDayOfWeek(date);
            int offset = startOfWeekOffset(1, ldow);

            // Clamp the week of year to keep it _in the same year
            int yearLen = date.lengthOfYear();
            int newYearWeek = computeWeek(offset, yearLen + weekDef.getMinimalDaysInFirstWeek());
            wowby = Math.min(wowby, newYearWeek - 1);

            int days = -offset + (dow - 1) + (wowby - 1) * 7;
            return date.plus(days, ChronoUnit.DAYS);
        }

        private string name;
        private WeekFields weekDef;
        private TemporalUnit baseUnit;
        private TemporalUnit rangeUnit;
        private ValueRange _range;

        this(string name, WeekFields weekDef, TemporalUnit baseUnit,
                TemporalUnit rangeUnit, ValueRange _range)
        {
            this.name = name;
            this.weekDef = weekDef;
            this.baseUnit = baseUnit;
            this.rangeUnit = rangeUnit;
            this._range = _range;
        }

         __gshared ValueRange DAY_OF_WEEK_RANGE;
         __gshared ValueRange WEEK_OF_MONTH_RANGE;
         __gshared ValueRange WEEK_OF_YEAR_RANGE;
         __gshared ValueRange WEEK_OF_WEEK_BASED_YEAR_RANGE;

        // shared static this()
        // {
        //     DAY_OF_WEEK_RANGE = ValueRange.of(1, 7);
        //     WEEK_OF_MONTH_RANGE = ValueRange.of(0, 1, 4, 6);
        //     WEEK_OF_YEAR_RANGE = ValueRange.of(0, 1, 52, 54);
        //     WEEK_OF_WEEK_BASED_YEAR_RANGE = ValueRange.of(1, 52, 53);
        // }

        override public long getFrom(TemporalAccessor temporal)
        {
            if (rangeUnit == ChronoUnit.WEEKS)
            { // day-of-week
                return localizedDayOfWeek(temporal);
            }
            else if (rangeUnit == ChronoUnit.MONTHS)
            { // week-of-month
                return localizedWeekOfMonth(temporal);
            }
            else if (rangeUnit == ChronoUnit.YEARS)
            { // week-of-year
                return localizedWeekOfYear(temporal);
            }
            else if (rangeUnit == WEEK_BASED_YEARS)
            {
                return localizedWeekOfWeekBasedYear(temporal);
            }
            else if (rangeUnit == ChronoUnit.FOREVER)
            {
                return localizedWeekBasedYear(temporal);
            }
            else
            {
                throw new IllegalStateException(
                        "unreachable, rangeUnit: " ~ rangeUnit.toString ~ ", this: " ~ this
                        .toString);
            }
        }

        private int localizedDayOfWeek(TemporalAccessor temporal)
        {
            int sow = weekDef.getFirstDayOfWeek().getValue();
            int isoDow = temporal.get(ChronoField.DAY_OF_WEEK);
            return Math.floorMod(isoDow - sow, 7) + 1;
        }

        private int localizedDayOfWeek(int isoDow)
        {
            int sow = weekDef.getFirstDayOfWeek().getValue();
            return Math.floorMod(isoDow - sow, 7) + 1;
        }

        private long localizedWeekOfMonth(TemporalAccessor temporal)
        {
            int dow = localizedDayOfWeek(temporal);
            int dom = temporal.get(ChronoField.DAY_OF_MONTH);
            int offset = startOfWeekOffset(dom, dow);
            return computeWeek(offset, dom);
        }

        private long localizedWeekOfYear(TemporalAccessor temporal)
        {
            int dow = localizedDayOfWeek(temporal);
            int doy = temporal.get(ChronoField.DAY_OF_YEAR);
            int offset = startOfWeekOffset(doy, dow);
            return computeWeek(offset, doy);
        }

        /**
         * Returns the year of week-based-year for the temporal.
         * The year can be the previous year, the current year, or the next year.
         * @param temporal a date of any chronology, not null
         * @return the year of week-based-year for the date
         */
        private int localizedWeekBasedYear(TemporalAccessor temporal)
        {
            int dow = localizedDayOfWeek(temporal);
            int year = temporal.get(ChronoField.YEAR);
            int doy = temporal.get(ChronoField.DAY_OF_YEAR);
            int offset = startOfWeekOffset(doy, dow);
            int week = computeWeek(offset, doy);
            if (week == 0)
            {
                // Day is _in end of week of previous year; return the previous year
                return year - 1;
            }
            else
            {
                // If getting close to end of year, use higher precision logic
                // Check if date of year is _in partial week associated with next year
                ValueRange dayRange = temporal.range(ChronoField.DAY_OF_YEAR);
                int yearLen = cast(int) dayRange.getMaximum();
                int newYearWeek = computeWeek(offset, yearLen + weekDef.getMinimalDaysInFirstWeek());
                if (week >= newYearWeek)
                {
                    return year + 1;
                }
            }
            return year;
        }

        /**
         * Returns the week of week-based-year for the temporal.
         * The week can be part of the previous year, the current year,
         * or the next year depending on the week start and minimum number
         * of days.
         * @param temporal  a date of any chronology
         * @return the week of the year
         * @see #localizedWeekBasedYear(hunt.time.temporal.TemporalAccessor)
         */
        private int localizedWeekOfWeekBasedYear(TemporalAccessor temporal)
        {
            int dow = localizedDayOfWeek(temporal);
            int doy = temporal.get(ChronoField.DAY_OF_YEAR);
            int offset = startOfWeekOffset(doy, dow);
            int week = computeWeek(offset, doy);
            if (week == 0)
            {
                // Day is _in end of week of previous year
                // Recompute from the last day of the previous year
                ChronoLocalDate date = Chronology.from(temporal).date(temporal);
                date = date.minus(doy, ChronoUnit.DAYS); // Back down into previous year
                return localizedWeekOfWeekBasedYear(date);
            }
            else if (week > 50)
            {
                // If getting close to end of year, use higher precision logic
                // Check if date of year is _in partial week associated with next year
                ValueRange dayRange = temporal.range(ChronoField.DAY_OF_YEAR);
                int yearLen = cast(int) dayRange.getMaximum();
                int newYearWeek = computeWeek(offset, yearLen + weekDef.getMinimalDaysInFirstWeek());
                if (week >= newYearWeek)
                {
                    // Overlaps with week of following year; reduce to week _in following year
                    week = week - newYearWeek + 1;
                }
            }
            return week;
        }

        /**
         * Returns an offset to align week start with a day of month or day of year.
         *
         * @param day  the day; 1 through infinity
         * @param dow  the day of the week of that day; 1 through 7
         * @return  an offset _in days to align a day with the start of the first 'full' week
         */
        private int startOfWeekOffset(int day, int dow)
        {
            // offset of first day corresponding to the day of week _in first 7 days (zero origin)
            int weekStart = Math.floorMod(day - dow, 7);
            int offset = -weekStart;
            if (weekStart + 1 > weekDef.getMinimalDaysInFirstWeek())
            {
                // The previous week has the minimum days _in the current month to be a 'week'
                offset = 7 - weekStart;
            }
            return offset;
        }

        /**
         * Returns the week number computed from the reference day and reference dayOfWeek.
         *
         * @param offset the offset to align a date with the start of week
         *     from {@link #startOfWeekOffset}.
         * @param day  the day for which to compute the week number
         * @return the week number where zero is used for a partial week and 1 for the first full week
         */
        private int computeWeek(int offset, int day)
        {
            return ((7 + offset + (day - 1)) / 7);
        }

        /*@SuppressWarnings("unchecked")*/
        override public Temporal adjustInto(Temporal temporal, long newValue)
                /* if (is(R : Temporal)) */
        {
            // Check the new value and get the old value of the field
            int newVal = _range.checkValidIntValue(newValue, this); // lenient check _range
            int currentVal = temporal.get(this);
            if (newVal == currentVal)
            {
                return temporal;
            }

            if (rangeUnit == ChronoUnit.FOREVER)
            { // replace year of WeekBasedYear
                // Create a new date object with the same chronology,
                // the desired year and the same week and dow.
                int idow = temporal.get(weekDef.dayOfWeek);
                int wowby = temporal.get(weekDef._weekOfWeekBasedYear);
                return cast(Temporal) ofWeekBasedYear(Chronology.from(temporal),
                        cast(int) newValue, wowby, idow);
            }
            else
            {
                // Compute the difference and add that using the base unit of the field
                return cast(Temporal) temporal.plus(newVal - currentVal, baseUnit);
            }
        }

        override public ChronoLocalDate resolve(Map!(TemporalField, Long) fieldValues,
                TemporalAccessor partialTemporal, ResolverStyle resolverStyle)
        {
            long value = fieldValues.get(this).longValue();
            int newValue = Math.toIntExact(value); // broad limit makes overflow checking lighter
            // first convert localized day-of-week to ISO day-of-week
            // doing this first handles case where both ISO and localized were parsed and might mismatch
            // day-of-week is always strict as two different day-of-week values makes lenient complex
            if (rangeUnit == ChronoUnit.WEEKS)
            { // day-of-week
                int checkedValue = _range.checkValidIntValue(value, this); // no leniency as too complex
                int startDow = weekDef.getFirstDayOfWeek().getValue();
                long isoDow = Math.floorMod((startDow - 1) + (checkedValue - 1), 7) + 1;
                fieldValues.remove(this);
                fieldValues.put(ChronoField.DAY_OF_WEEK, new Long(isoDow));
                return null;
            }

            // can only build date if ISO day-of-week is present
            if (fieldValues.containsKey(ChronoField.DAY_OF_WEEK) == false)
            {
                return null;
            }
            int isoDow = ChronoField.DAY_OF_WEEK.checkValidIntValue(
                    fieldValues.get(ChronoField.DAY_OF_WEEK).longValue());
            int dow = localizedDayOfWeek(isoDow);

            // build date
            Chronology chrono = Chronology.from(partialTemporal);
            if (fieldValues.containsKey(ChronoField.YEAR))
            {
                int year = ChronoField.YEAR.checkValidIntValue(fieldValues.get(ChronoField.YEAR)
                        .longValue()); // validate
                if (rangeUnit == ChronoUnit.MONTHS
                        && fieldValues.containsKey(ChronoField.MONTH_OF_YEAR))
                { // week-of-month
                    long month = fieldValues.get(ChronoField.MONTH_OF_YEAR).longValue(); // not validated yet
                    return resolveWoM(fieldValues, chrono, year, month,
                            newValue, dow, resolverStyle);
                }
                if (rangeUnit == ChronoUnit.YEARS)
                { // week-of-year
                    return resolveWoY(fieldValues, chrono, year, newValue, dow, resolverStyle);
                }
            }
            else if ((rangeUnit == WEEK_BASED_YEARS || rangeUnit == ChronoUnit.FOREVER)
                    && fieldValues.containsKey(weekDef._weekBasedYear)
                    && fieldValues.containsKey(weekDef._weekOfWeekBasedYear))
            { // week-of-week-based-year and year-of-week-based-year
                return resolveWBY(fieldValues, chrono, dow, resolverStyle);
            }
            return null;
        }

        private ChronoLocalDate resolveWoM(Map!(TemporalField, Long) fieldValues, Chronology chrono,
                int year, long month, long wom, int localDow, ResolverStyle resolverStyle)
        {
            ChronoLocalDate date;
            if (resolverStyle == ResolverStyle.LENIENT)
            {
                date = chrono.date(year, 1, 1).plus(Math.subtractExact(month,
                        1), ChronoUnit.MONTHS);
                long weeks = Math.subtractExact(wom, localizedWeekOfMonth(date));
                int days = localDow - localizedDayOfWeek(date); // safe from overflow
                date = date.plus(Math.addExact(Math.multiplyExact(weeks, 7),
                        days), ChronoUnit.DAYS);
            }
            else
            {
                int monthValid = ChronoField.MONTH_OF_YEAR.checkValidIntValue(month); // validate
                date = chrono.date(year, monthValid, 1);
                int womInt = _range.checkValidIntValue(wom, this); // validate
                int weeks = cast(int)(womInt - localizedWeekOfMonth(date)); // safe from overflow
                int days = localDow - localizedDayOfWeek(date); // safe from overflow
                date = date.plus(weeks * 7 + days, ChronoUnit.DAYS);
                if (resolverStyle == ResolverStyle.STRICT
                        && date.getLong(ChronoField.MONTH_OF_YEAR) != month)
                {
                    throw new DateTimeException(
                            "Strict mode rejected resolved date as it is _in a different month");
                }
            }
            fieldValues.remove(this);
            fieldValues.remove(ChronoField.YEAR);
            fieldValues.remove(ChronoField.MONTH_OF_YEAR);
            fieldValues.remove(ChronoField.DAY_OF_WEEK);
            return date;
        }

        private ChronoLocalDate resolveWoY(Map!(TemporalField, Long) fieldValues,
                Chronology chrono, int year, long woy, int localDow, ResolverStyle resolverStyle)
        {
            ChronoLocalDate date = chrono.date(year, 1, 1);
            if (resolverStyle == ResolverStyle.LENIENT)
            {
                long weeks = Math.subtractExact(woy, localizedWeekOfYear(date));
                int days = localDow - localizedDayOfWeek(date); // safe from overflow
                date = date.plus(Math.addExact(Math.multiplyExact(weeks, 7),
                        days), ChronoUnit.DAYS);
            }
            else
            {
                int womInt = _range.checkValidIntValue(woy, this); // validate
                int weeks = cast(int)(womInt - localizedWeekOfYear(date)); // safe from overflow
                int days = localDow - localizedDayOfWeek(date); // safe from overflow
                date = date.plus(weeks * 7 + days, ChronoUnit.DAYS);
                if (resolverStyle == ResolverStyle.STRICT && date.getLong(ChronoField.YEAR) != year)
                {
                    throw new DateTimeException(
                            "Strict mode rejected resolved date as it is _in a different year");
                }
            }
            fieldValues.remove(this);
            fieldValues.remove(ChronoField.YEAR);
            fieldValues.remove(ChronoField.DAY_OF_WEEK);
            return date;
        }

        private ChronoLocalDate resolveWBY(Map!(TemporalField, Long) fieldValues,
                Chronology chrono, int localDow, ResolverStyle resolverStyle)
        {
            int yowby = weekDef._weekBasedYear.range()
                .checkValidIntValue(fieldValues.get(weekDef._weekBasedYear)
                        .longValue(), weekDef._weekBasedYear);
            ChronoLocalDate date;
            if (resolverStyle == ResolverStyle.LENIENT)
            {
                date = ofWeekBasedYear(chrono, yowby, 1, localDow);
                long wowby = fieldValues.get(weekDef._weekOfWeekBasedYear).longValue();
                long weeks = Math.subtractExact(wowby, 1);
                date = date.plus(weeks, ChronoUnit.WEEKS);
            }
            else
            {
                int wowby = weekDef._weekOfWeekBasedYear.range()
                    .checkValidIntValue(fieldValues.get(weekDef._weekOfWeekBasedYear)
                            .longValue(), weekDef._weekOfWeekBasedYear); // validate
                date = ofWeekBasedYear(chrono, yowby, wowby, localDow);
                if (resolverStyle == ResolverStyle.STRICT && localizedWeekBasedYear(date) != yowby)
                {
                    throw new DateTimeException(
                            "Strict mode rejected resolved date as it is _in a different week-based-year");
                }
            }
            fieldValues.remove(this);
            fieldValues.remove(weekDef._weekBasedYear);
            fieldValues.remove(weekDef._weekOfWeekBasedYear);
            fieldValues.remove(ChronoField.DAY_OF_WEEK);
            return date;
        }

        //-----------------------------------------------------------------------
        override public string getDisplayName(Locale locale)
        {
            assert(locale, "locale");
            if (rangeUnit == ChronoUnit.YEARS)
            { // only have values for week-of-year
                ///@gxc
                // LocaleResources lr = LocaleProviderAdapter.getResourceBundleBased()
                //         .getLocaleResources(
                //             CalendarDataUtility.findRegionOverride(locale));
                // ResourceBundle rb = lr.getJavaTimeFormatData();
                // return rb.containsKey("field.week") ? rb.getString("field.week") : name;
                implementationMissing();
                return null;
            }
            return name;
        }

        override public TemporalUnit getBaseUnit()
        {
            return baseUnit;
        }

        override public TemporalUnit getRangeUnit()
        {
            return rangeUnit;
        }

        override public bool isDateBased()
        {
            return true;
        }

        override public bool isTimeBased()
        {
            return false;
        }

        override public ValueRange range()
        {
            return _range;
        }

        //-----------------------------------------------------------------------
        override public bool isSupportedBy(TemporalAccessor temporal)
        {
            if (temporal.isSupported(ChronoField.DAY_OF_WEEK))
            {
                if (rangeUnit == ChronoUnit.WEEKS)
                { // day-of-week
                    return true;
                }
                else if (rangeUnit == ChronoUnit.MONTHS)
                { // week-of-month
                    return temporal.isSupported(ChronoField.DAY_OF_MONTH);
                }
                else if (rangeUnit == ChronoUnit.YEARS)
                { // week-of-year
                    return temporal.isSupported(ChronoField.DAY_OF_YEAR);
                }
                else if (rangeUnit == WEEK_BASED_YEARS)
                {
                    return temporal.isSupported(ChronoField.DAY_OF_YEAR);
                }
                else if (rangeUnit == ChronoUnit.FOREVER)
                {
                    return temporal.isSupported(ChronoField.YEAR);
                }
            }
            return false;
        }

        override public ValueRange rangeRefinedBy(TemporalAccessor temporal)
        {
            if (rangeUnit == ChronoUnit.WEEKS)
            { // day-of-week
                return _range;
            }
            else if (rangeUnit == ChronoUnit.MONTHS)
            { // week-of-month
                return rangeByWeek(temporal, ChronoField.DAY_OF_MONTH);
            }
            else if (rangeUnit == ChronoUnit.YEARS)
            { // week-of-year
                return rangeByWeek(temporal, ChronoField.DAY_OF_YEAR);
            }
            else if (rangeUnit == WEEK_BASED_YEARS)
            {
                return rangeWeekOfWeekBasedYear(temporal);
            }
            else if (rangeUnit == ChronoUnit.FOREVER)
            {
                return ChronoField.YEAR.range();
            }
            else
            {
                throw new IllegalStateException(
                        "unreachable, rangeUnit: " ~ rangeUnit.toString ~ ", this: " ~ this
                        .toString);
            }
        }

        /**
         * Map the field _range to a week _range
         * @param temporal the temporal
         * @param field the field to get the _range of
         * @return the ValueRange with the _range adjusted to weeks.
         */
        private ValueRange rangeByWeek(TemporalAccessor temporal, TemporalField field)
        {
            int dow = localizedDayOfWeek(temporal);
            int offset = startOfWeekOffset(temporal.get(field), dow);
            ValueRange fieldRange = temporal.range(field);
            return ValueRange.of(computeWeek(offset, cast(int) fieldRange.getMinimum()),
                    computeWeek(offset, cast(int) fieldRange.getMaximum()));
        }

        /**
         * Map the field _range to a week _range of a week year.
         * @param temporal  the temporal
         * @return the ValueRange with the _range adjusted to weeks.
         */
        private ValueRange rangeWeekOfWeekBasedYear(TemporalAccessor temporal)
        {
            if (!temporal.isSupported(ChronoField.DAY_OF_YEAR))
            {
                return WEEK_OF_YEAR_RANGE;
            }
            int dow = localizedDayOfWeek(temporal);
            int doy = temporal.get(ChronoField.DAY_OF_YEAR);
            int offset = startOfWeekOffset(doy, dow);
            int week = computeWeek(offset, doy);
            if (week == 0)
            {
                // Day is _in end of week of previous year
                // Recompute from the last day of the previous year
                ChronoLocalDate date = Chronology.from(temporal).date(temporal);
                date = date.minus(doy + 7, ChronoUnit.DAYS); // Back down into previous year
                return rangeWeekOfWeekBasedYear(date);
            }
            // Check if day of year is _in partial week associated with next year
            ValueRange dayRange = temporal.range(ChronoField.DAY_OF_YEAR);
            int yearLen = cast(int) dayRange.getMaximum();
            int newYearWeek = computeWeek(offset, yearLen + weekDef.getMinimalDaysInFirstWeek());

            if (week >= newYearWeek)
            {
                // Overlaps with weeks of following year; recompute from a week _in following year
                ChronoLocalDate date = Chronology.from(temporal).date(temporal);
                date = date.plus(yearLen - doy + 1 + 7, ChronoUnit.DAYS);
                return rangeWeekOfWeekBasedYear(date);
            }
            return ValueRange.of(1, newYearWeek - 1);
        }

        //-----------------------------------------------------------------------
        override public string toString()
        {
            return name ~ "[" ~ weekDef.toString() ~ "]";
        }

        override int opCmp(TemporalField o)
        {
            if(cast(ComputedDayOfField)o !is null)
            {
                auto obj = cast(ComputedDayOfField)o;
                return compare(this.toString,obj.toString);
            }
            return 0;
        }
    }
}
