
module hunt.time.temporal.IsoFields;

import hunt.time.DayOfWeek;
import hunt.time.temporal.ChronoField;
import hunt.time.temporal.ChronoUnit;

import hunt.time.DateTimeException;
import hunt.time.Duration;
import hunt.time.LocalDate;
import hunt.time.chrono.ChronoLocalDate;
import hunt.time.chrono.Chronology;
import hunt.time.chrono.IsoChronology;
import hunt.time.format.ResolverStyle;
import hunt.time.util.Locale;
import hunt.container.Map;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.ValueRange;
import hunt.time.temporal.TemporalAccessor;
import hunt.time.temporal.TemporalUnit;
import hunt.time.temporal.Temporal;
import hunt.lang;
import hunt.util.Assert;
import hunt.lang.exception;
import hunt.util.Comparator;
import hunt.time.util.common;
// import hunt.util.ResourceBundle;

// import sun.util.locale.provider.CalendarDataUtility;
// import sun.util.locale.provider.LocaleProviderAdapter;
// import sun.util.locale.provider.LocaleResources;

/**
 * Fields and units specific to the ISO-8601 calendar system,
 * including quarter-of-year and week-based-year.
 * !(p)
 * This class defines fields and units that are specific to the ISO calendar system.
 *
 * !(h3)Quarter of year</h3>
 * The ISO-8601 standard is based on the standard civic 12 month year.
 * This is commonly divided into four quarters, often abbreviated as Q1, Q2, Q3 and Q4.
 * !(p)
 * January, February and March are _in Q1.
 * April, May and June are _in Q2.
 * July, August and September are _in Q3.
 * October, November and December are _in Q4.
 * !(p)
 * The complete date is expressed using three fields:
 * !(ul)
 * !(li){@link #DAY_OF_QUARTER DAY_OF_QUARTER} - the day within the quarter, from 1 to 90, 91 or 92
 * !(li){@link #QUARTER_OF_YEAR QUARTER_OF_YEAR} - the quarter within the year, from 1 to 4
 * !(li){@link ChronoField#YEAR YEAR} - the standard ISO year
 * </ul>
 *
 * !(h3)Week based years</h3>
 * The ISO-8601 standard was originally intended as a data interchange format,
 * defining a string format for dates and times. However, it also defines an
 * alternate way of expressing the date, based on the concept of week-based-year.
 * !(p)
 * The date is expressed using three fields:
 * !(ul)
 * !(li){@link ChronoField#DAY_OF_WEEK DAY_OF_WEEK} - the standard field defining the
 *  day-of-week from Monday (1) to Sunday (7)
 * !(li){@link #WEEK_OF_WEEK_BASED_YEAR} - the week within the week-based-year
 * !(li){@link #WEEK_BASED_YEAR WEEK_BASED_YEAR} - the week-based-year
 * </ul>
 * The week-based-year itself is defined relative to the standard ISO proleptic year.
 * It differs from the standard year _in that it always starts on a Monday.
 * !(p)
 * The first week of a week-based-year is the first Monday-based week of the standard
 * ISO year that has at least 4 days _in the new year.
 * !(ul)
 * !(li)If January 1st is Monday then week 1 starts on January 1st
 * !(li)If January 1st is Tuesday then week 1 starts on December 31st of the previous standard year
 * !(li)If January 1st is Wednesday then week 1 starts on December 30th of the previous standard year
 * !(li)If January 1st is Thursday then week 1 starts on December 29th of the previous standard year
 * !(li)If January 1st is Friday then week 1 starts on January 4th
 * !(li)If January 1st is Saturday then week 1 starts on January 3rd
 * !(li)If January 1st is Sunday then week 1 starts on January 2nd
 * </ul>
 * There are 52 weeks _in most week-based years, however on occasion there are 53 weeks.
 * !(p)
 * For example:
 *
 * <table class=striped style="text-align: left">
 * !(caption)Examples of Week based Years</caption>
 * !(thead)
 * !(tr)<th scope="col">Date</th><th scope="col">Day-of-week</th><th scope="col">Field values</th></tr>
 * </thead>
 * !(tbody)
 * !(tr)<th scope="row">2008-12-28</th>!(td)Sunday</td>!(td)Week 52 of week-based-year 2008</td></tr>
 * !(tr)<th scope="row">2008-12-29</th>!(td)Monday</td>!(td)Week 1 of week-based-year 2009</td></tr>
 * !(tr)<th scope="row">2008-12-31</th>!(td)Wednesday</td>!(td)Week 1 of week-based-year 2009</td></tr>
 * !(tr)<th scope="row">2009-01-01</th>!(td)Thursday</td>!(td)Week 1 of week-based-year 2009</td></tr>
 * !(tr)<th scope="row">2009-01-04</th>!(td)Sunday</td>!(td)Week 1 of week-based-year 2009</td></tr>
 * !(tr)<th scope="row">2009-01-05</th>!(td)Monday</td>!(td)Week 2 of week-based-year 2009</td></tr>
 * </tbody>
 * </table>
 *
 * @implSpec
 * !(p)
 * This class is immutable and thread-safe.
 *
 * @since 1.8
 */
public final class IsoFields
{

    /**
     * The field that represents the day-of-quarter.
     * !(p)
     * This field allows the day-of-quarter value to be queried and set.
     * The day-of-quarter has values from 1 to 90 _in Q1 of a standard year, from 1 to 91
     * _in Q1 of a leap year, from 1 to 91 _in Q2 and from 1 to 92 _in Q3 and Q4.
     * !(p)
     * The day-of-quarter can only be calculated if the day-of-year, month-of-year and year
     * are available.
     * !(p)
     * When setting this field, the value is allowed to be partially lenient, taking any
     * value from 1 to 92. If the quarter has less than 92 days, then day 92, and
     * potentially day 91, is _in the following quarter.
     * !(p)
     * In the resolving phase of parsing, a date can be created from a year,
     * quarter-of-year and day-of-quarter.
     * !(p)
     * In {@linkplain ResolverStyle#STRICT strict mode}, all three fields are
     * validated against their range of valid values. The day-of-quarter field
     * is validated from 1 to 90, 91 or 92 depending on the year and quarter.
     * !(p)
     * In {@linkplain ResolverStyle#SMART smart mode}, all three fields are
     * validated against their range of valid values. The day-of-quarter field is
     * validated between 1 and 92, ignoring the actual range based on the year and quarter.
     * If the day-of-quarter exceeds the actual range by one day, then the resulting date
     * is one day later. If the day-of-quarter exceeds the actual range by two days,
     * then the resulting date is two days later.
     * !(p)
     * In {@linkplain ResolverStyle#LENIENT lenient mode}, only the year is validated
     * against the range of valid values. The resulting date is calculated equivalent to
     * the following three stage approach. First, create a date on the first of January
     * _in the requested year. Then take the quarter-of-year, subtract one, and add the
     * amount _in quarters to the date. Finally, take the day-of-quarter, subtract one,
     * and add the amount _in days to the date.
     * !(p)
     * This unit is an immutable and thread-safe singleton.
     */
    //public __gshared TemporalField DAY_OF_QUARTER;
    /**
     * The field that represents the quarter-of-year.
     * !(p)
     * This field allows the quarter-of-year value to be queried and set.
     * The quarter-of-year has values from 1 to 4.
     * !(p)
     * The quarter-of-year can only be calculated if the month-of-year is available.
     * !(p)
     * In the resolving phase of parsing, a date can be created from a year,
     * quarter-of-year and day-of-quarter.
     * See {@link #DAY_OF_QUARTER} for details.
     * !(p)
     * This unit is an immutable and thread-safe singleton.
     */
    //public __gshared TemporalField QUARTER_OF_YEAR;
    /**
     * The field that represents the week-of-week-based-year.
     * !(p)
     * This field allows the week of the week-based-year value to be queried and set.
     * The week-of-week-based-year has values from 1 to 52, or 53 if the
     * week-based-year has 53 weeks.
     * !(p)
     * In the resolving phase of parsing, a date can be created from a
     * week-based-year, week-of-week-based-year and day-of-week.
     * !(p)
     * In {@linkplain ResolverStyle#STRICT strict mode}, all three fields are
     * validated against their range of valid values. The week-of-week-based-year
     * field is validated from 1 to 52 or 53 depending on the week-based-year.
     * !(p)
     * In {@linkplain ResolverStyle#SMART smart mode}, all three fields are
     * validated against their range of valid values. The week-of-week-based-year
     * field is validated between 1 and 53, ignoring the week-based-year.
     * If the week-of-week-based-year is 53, but the week-based-year only has
     * 52 weeks, then the resulting date is _in week 1 of the following week-based-year.
     * !(p)
     * In {@linkplain ResolverStyle#LENIENT lenient mode}, only the week-based-year
     * is validated against the range of valid values. If the day-of-week is outside
     * the range 1 to 7, then the resulting date is adjusted by a suitable number of
     * weeks to reduce the day-of-week to the range 1 to 7. If the week-of-week-based-year
     * value is outside the range 1 to 52, then any excess weeks are added or subtracted
     * from the resulting date.
     * !(p)
     * This unit is an immutable and thread-safe singleton.
     */
    //public __gshared TemporalField WEEK_OF_WEEK_BASED_YEAR;
    /**
     * The field that represents the week-based-year.
     * !(p)
     * This field allows the week-based-year value to be queried and set.
     * !(p)
     * The field has a range that matches {@link LocalDate#MAX} and {@link LocalDate#MIN}.
     * !(p)
     * In the resolving phase of parsing, a date can be created from a
     * week-based-year, week-of-week-based-year and day-of-week.
     * See {@link #WEEK_OF_WEEK_BASED_YEAR} for details.
     * !(p)
     * This unit is an immutable and thread-safe singleton.
     */
    //public __gshared TemporalField WEEK_BASED_YEAR;
    /**
     * The unit that represents week-based-years for the purpose of addition and subtraction.
     * !(p)
     * This allows a number of week-based-years to be added to, or subtracted from, a date.
     * The unit is equal to either 52 or 53 weeks.
     * The estimated duration of a week-based-year is the same as that of a standard ISO
     * year at {@code 365.2425 Days}.
     * !(p)
     * The rules for addition add the number of week-based-years to the existing value
     * for the week-based-year field. If the resulting week-based-year only has 52 weeks,
     * then the date will be _in week 1 of the following week-based-year.
     * !(p)
     * This unit is an immutable and thread-safe singleton.
     */
    //public __gshared TemporalUnit WEEK_BASED_YEARS;
    /**
     * Unit that represents the concept of a quarter-year.
     * For the ISO calendar system, it is equal to 3 months.
     * The estimated duration of a quarter-year is one quarter of {@code 365.2425 Days}.
     * !(p)
     * This unit is an immutable and thread-safe singleton.
     */
    //public __gshared TemporalUnit QUARTER_YEARS;

    // shared static this()
    // {
        // DAY_OF_QUARTER = Field.DAY_OF_QUARTER;
        mixin(MakeGlobalVar!(TemporalField)("DAY_OF_QUARTER",`Field.DAY_OF_QUARTER`));
        // QUARTER_OF_YEAR = Field.QUARTER_OF_YEAR;
        mixin(MakeGlobalVar!(TemporalField)("QUARTER_OF_YEAR",`Field.QUARTER_OF_YEAR`));

        // WEEK_OF_WEEK_BASED_YEAR = Field.WEEK_OF_WEEK_BASED_YEAR;
        mixin(MakeGlobalVar!(TemporalField)("WEEK_OF_WEEK_BASED_YEAR",`Field.WEEK_OF_WEEK_BASED_YEAR`));

        mixin(MakeGlobalVar!(TemporalField)("WEEK_BASED_YEAR",`Field.WEEK_BASED_YEAR`));


        // WEEK_BASED_YEARS = Unit.WEEK_BASED_YEARS;
        mixin(MakeGlobalVar!(TemporalUnit)("WEEK_BASED_YEARS",`Unit.WEEK_BASED_YEARS`));

        // QUARTER_YEARS = Unit.QUARTER_YEARS;
        mixin(MakeGlobalVar!(TemporalUnit)("QUARTER_YEARS",` Unit.QUARTER_YEARS`));


    // }

    /**
     * Restricted constructor.
     */
    private this()
    {
        throw new AssertionError("Not instantiable");
    }

    //-----------------------------------------------------------------------
    /**
     * Implementation of the field.
     */
    static class Field : TemporalField
    {
        // static Field DAY_OF_QUARTER;
        // static Field QUARTER_OF_YEAR;
        // static Field WEEK_OF_WEEK_BASED_YEAR;
        // static Field WEEK_BASED_YEAR;
        string getDisplayName(Locale locale){ return null;}

        TemporalUnit getBaseUnit(){ return null;}

        TemporalUnit getRangeUnit(){ return null;}

        ValueRange range(){ return null;}

        // bool isDateBased(){ return false;}

        // bool isTimeBased(){ return false;}

        bool isSupportedBy(TemporalAccessor temporal){ return false;}

        // ValueRange rangeRefinedBy(TemporalAccessor temporal){ return null;}

        long getFrom(TemporalAccessor temporal){ return long.init;}

        Temporal adjustInto(Temporal temporal, long newValue){ return null;}

        TemporalAccessor resolve(Map!(TemporalField, Long) fieldValues,
                TemporalAccessor partialTemporal, ResolverStyle resolverStyle){ return null;}

        override string toString(){return super.toString();}

        // int opCmp(Object o){return 0;}

        int opCmp(TemporalField o){return 0;}
        // shared static this()
        // {
        //     DAY_OF_QUARTER = new class Field
        //     {
        //         override
        //         public TemporalUnit getBaseUnit()
        //         {
        //             return ChronoUnit.DAYS;
        //         }
        //         override
        //         public TemporalUnit getRangeUnit()
        //         {
        //             return QUARTER_YEARS;
        //         }
        //         override
        //         public ValueRange range()
        //         {
        //             return ValueRange.of(1, 90, 92);
        //         }
        //         override
        //         public bool isSupportedBy(TemporalAccessor temporal)
        //         {
        //             return temporal.isSupported(ChronoField.DAY_OF_YEAR)
        //                 && temporal.isSupported(ChronoField.MONTH_OF_YEAR)
        //                 && temporal.isSupported(ChronoField.YEAR) && isIso(temporal);
        //         }

        //         override public ValueRange rangeRefinedBy(TemporalAccessor temporal)
        //         {
        //             if (isSupportedBy(temporal) == false)
        //             {
        //                 throw new Exception("Unsupported field: DayOfQuarter");
        //             }
        //             long qoy = temporal.getLong(QUARTER_OF_YEAR);
        //             if (qoy == 1)
        //             {
        //                 long year = temporal.getLong(ChronoField.YEAR);
        //                 return (IsoChronology.INSTANCE.isLeapYear(year)
        //                         ? ValueRange.of(1, 91) : ValueRange.of(1, 90));
        //             }
        //             else if (qoy == 2)
        //             {
        //                 return ValueRange.of(1, 91);
        //             }
        //             else if (qoy == 3 || qoy == 4)
        //             {
        //                 return ValueRange.of(1, 92);
        //             } // else value not from 1 to 4, so drop through
        //             return range();
        //         }
        //         override
        //         public long getFrom(TemporalAccessor temporal)
        //         {
        //             if (isSupportedBy(temporal) == false)
        //             {
        //                 throw new Exception("Unsupported field: DayOfQuarter");
        //             }
        //             int doy = temporal.get(ChronoField.DAY_OF_YEAR);
        //             int moy = temporal.get(ChronoField.MONTH_OF_YEAR);
        //             long year = temporal.getLong(ChronoField.YEAR);
        //             return doy - QUARTER_DAYS[((moy - 1) / 3) + (IsoChronology.INSTANCE.isLeapYear(year)
        //                     ? 4 : 0)];
        //         }
        //         /*@SuppressWarnings("unchecked")*/
        //         override
        //         public Temporal adjustInto(Temporal temporal, long newValue)
        //                 /* if (is(R : Temporal)) */
        //         {
        //             // calls getFrom() to check if supported
        //             long curValue = getFrom(temporal);
        //             range().checkValidValue(newValue, this); // leniently check from 1 to 92 TODO: check
        //             return cast(Temporal) temporal._with(ChronoField.DAY_OF_YEAR,
        //                     temporal.getLong(ChronoField.DAY_OF_YEAR) + (newValue - curValue));
        //         }
        //         override
        //         public ChronoLocalDate resolve(Map!(TemporalField, Long) fieldValues,
        //                 TemporalAccessor partialTemporal, ResolverStyle resolverStyle)
        //         {
        //             Long yearLong = fieldValues.get(ChronoField.YEAR);
        //             Long qoyLong = fieldValues.get(QUARTER_OF_YEAR);
        //             if (yearLong is null || qoyLong is null)
        //             {
        //                 return null;
        //             }
        //             int y = ChronoField.YEAR.checkValidIntValue(yearLong.longValue()); // always validate
        //             long doq = fieldValues.get(DAY_OF_QUARTER).longValue();
        //             ensureIso(partialTemporal);
        //             LocalDate date;
        //             if (resolverStyle == ResolverStyle.LENIENT)
        //             {
        //                 date = LocalDate.of(y, 1, 1)
        //                     .plusMonths(Math.multiplyExact(Math.subtractExact(cast(int)(qoyLong.longValue()),
        //                             1), 3));
        //                 doq = Math.subtractExact(doq, 1);
        //             }
        //             else
        //             {
        //                 int qoy = QUARTER_OF_YEAR.range()
        //                     .checkValidIntValue(qoyLong.longValue(), QUARTER_OF_YEAR); // validated
        //                 date = LocalDate.of(y, ((qoy - 1) * 3) + 1, 1);
        //                 if (doq < 1 || doq > 90)
        //                 {
        //                     if (resolverStyle == ResolverStyle.STRICT)
        //                     {
        //                         rangeRefinedBy(date).checkValidValue(doq, this); // only allow exact range
        //                     }
        //                     else
        //                     { // SMART
        //                         range().checkValidValue(doq, this); // allow 1-92 rolling into next quarter
        //                     }
        //                 }
        //                 doq--;
        //             }
        //             fieldValues.remove(this);
        //             fieldValues.remove(ChronoField.YEAR);
        //             fieldValues.remove(QUARTER_OF_YEAR);
        //             return date.plusDays(doq);
        //         }

        //         override
        //         string getDisplayName(Locale locale)
        //         {
        //             assert(locale, "locale");
        //             return toString();
        //         }

        //         override public string toString()
        //         {
        //             return "DayOfQuarter";
        //         }

        //         override
        //         int opCmp(TemporalField obj)
        //         {
        //             if (cast(Field)(obj) !is null)
        //             {
        //                 Field other = cast(Field) obj;
        //                 return compare(toString(), other.toString());
        //             }
        //             return 0;
        //         }
        //     };

            mixin(MakeGlobalVar!(Field)("DAY_OF_QUARTER",`new class Field
            {
                override
                public TemporalUnit getBaseUnit()
                {
                    return ChronoUnit.DAYS;
                }
                override
                public TemporalUnit getRangeUnit()
                {
                    return QUARTER_YEARS;
                }
                override
                public ValueRange range()
                {
                    return ValueRange.of(1, 90, 92);
                }
                override
                public bool isSupportedBy(TemporalAccessor temporal)
                {
                    return temporal.isSupported(ChronoField.DAY_OF_YEAR)
                        && temporal.isSupported(ChronoField.MONTH_OF_YEAR)
                        && temporal.isSupported(ChronoField.YEAR) && isIso(temporal);
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
                override
                public long getFrom(TemporalAccessor temporal)
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
                override
                public Temporal adjustInto(Temporal temporal, long newValue)
                        /* if (is(R : Temporal)) */
                {
                    // calls getFrom() to check if supported
                    long curValue = getFrom(temporal);
                    range().checkValidValue(newValue, this); // leniently check from 1 to 92 TODO: check
                    return cast(Temporal) temporal._with(ChronoField.DAY_OF_YEAR,
                            temporal.getLong(ChronoField.DAY_OF_YEAR) + (newValue - curValue));
                }
                override
                public ChronoLocalDate resolve(Map!(TemporalField, Long) fieldValues,
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

                override
                string getDisplayName(Locale locale)
                {
                    assert(locale, "locale");
                    return toString();
                }

                override public string toString()
                {
                    return "DayOfQuarter";
                }

                override
                int opCmp(TemporalField obj)
                {
                    if (cast(Field)(obj) !is null)
                    {
                        Field other = cast(Field) obj;
                        return compare(toString(), other.toString());
                    }
                    return 0;
                }
            }`));
            // QUARTER_OF_YEAR = new class Field
            // {
            //     override
            //     public TemporalUnit getBaseUnit()
            //     {
            //         return QUARTER_YEARS;
            //     }
            //     override
            //     public TemporalUnit getRangeUnit()
            //     {
            //         return ChronoUnit.YEARS;
            //     }
            //     override
            //     public ValueRange range()
            //     {
            //         return ValueRange.of(1, 4);
            //     }
            //     override
            //     public bool isSupportedBy(TemporalAccessor temporal)
            //     {
            //         return temporal.isSupported(ChronoField.MONTH_OF_YEAR) && isIso(temporal);
            //     }
            //     override
            //     public long getFrom(TemporalAccessor temporal)
            //     {
            //         if (isSupportedBy(temporal) == false)
            //         {
            //             throw new Exception("Unsupported field: QuarterOfYear");
            //         }
            //         long moy = temporal.getLong(ChronoField.MONTH_OF_YEAR);
            //         return ((moy + 2) / 3);
            //     }

            //     override public ValueRange rangeRefinedBy(TemporalAccessor temporal)
            //     {
            //         if (isSupportedBy(temporal) == false)
            //         {
            //             throw new Exception("Unsupported field: QuarterOfYear");
            //         }
            //         return range()/* super.rangeRefinedBy(temporal) */;
            //     }
            //     /*@SuppressWarnings("unchecked")*/
            //     override public Temporal adjustInto(Temporal temporal, long newValue)
            //             /* if (is(R : Temporal)) */
            //     {
            //         // calls getFrom() to check if supported
            //         long curValue = getFrom(temporal);
            //         range().checkValidValue(newValue, this); // strictly check from 1 to 4
            //         return cast(Temporal) temporal._with(ChronoField.MONTH_OF_YEAR,
            //                 temporal.getLong(ChronoField.MONTH_OF_YEAR) + (newValue - curValue) * 3);
            //     }

            //     override
            //     string getDisplayName(Locale locale)
            //     {
            //         assert(locale, "locale");
            //         return toString();
            //     }

            //     override public string toString()
            //     {
            //         return "QuarterOfYear";
            //     }

            //     override TemporalAccessor resolve(Map!(TemporalField, Long) fieldValues,
            //             TemporalAccessor partialTemporal, ResolverStyle resolverStyle)
            //     {
            //         return null;
            //     }
            //     override
            //     int opCmp(TemporalField obj)
            //     {
            //         if (cast(Field)(obj) !is null)
            //         {
            //             Field other = cast(Field) obj;
            //             return compare(toString(), other.toString());
            //         }
            //         return 0;
            //     }
            // };
            mixin(MakeGlobalVar!(Field)("QUARTER_OF_YEAR",`new class Field
            {
                override
                public TemporalUnit getBaseUnit()
                {
                    return QUARTER_YEARS;
                }
                override
                public TemporalUnit getRangeUnit()
                {
                    return ChronoUnit.YEARS;
                }
                override
                public ValueRange range()
                {
                    return ValueRange.of(1, 4);
                }
                override
                public bool isSupportedBy(TemporalAccessor temporal)
                {
                    return temporal.isSupported(ChronoField.MONTH_OF_YEAR) && isIso(temporal);
                }
                override
                public long getFrom(TemporalAccessor temporal)
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
                    return range()/* super.rangeRefinedBy(temporal) */;
                }
                /*@SuppressWarnings("unchecked")*/
                override public Temporal adjustInto(Temporal temporal, long newValue)
                        /* if (is(R : Temporal)) */
                {
                    // calls getFrom() to check if supported
                    long curValue = getFrom(temporal);
                    range().checkValidValue(newValue, this); // strictly check from 1 to 4
                    return cast(Temporal) temporal._with(ChronoField.MONTH_OF_YEAR,
                            temporal.getLong(ChronoField.MONTH_OF_YEAR) + (newValue - curValue) * 3);
                }

                override
                string getDisplayName(Locale locale)
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
                override
                int opCmp(TemporalField obj)
                {
                    if (cast(Field)(obj) !is null)
                    {
                        Field other = cast(Field) obj;
                        return compare(toString(), other.toString());
                    }
                    return 0;
                }
            }`));

            // WEEK_OF_WEEK_BASED_YEAR = new class Field
            // {
            //     override
            //     public string getDisplayName(Locale locale)
            //     {
            //         ///@gxc
            //         // assert(locale, "locale");
            //         // LocaleResources lr = LocaleProviderAdapter.getResourceBundleBased()
            //         //                             .getLocaleResources(
            //         //                                 CalendarDataUtility
            //         //                                     .findRegionOverride(locale));
            //         // ResourceBundle rb = lr.getJavaTimeFormatData();
            //         // return rb.containsKey("field.week") ? rb.getString("field.week") : toString();
            //         implementationMissing();
            //         return null;
            //     }

            //     override
            //     public TemporalUnit getBaseUnit()
            //     {
            //         return ChronoUnit.WEEKS;
            //     }
            //     override
            //     public TemporalUnit getRangeUnit()
            //     {
            //         return WEEK_BASED_YEARS;
            //     }
            //     override
            //     public ValueRange range()
            //     {
            //         return ValueRange.of(1, 52, 53);
            //     }
            //     override
            //     public bool isSupportedBy(TemporalAccessor temporal)
            //     {
            //         return temporal.isSupported(ChronoField.EPOCH_DAY) && isIso(temporal);
            //     }

            //     override public ValueRange rangeRefinedBy(TemporalAccessor temporal)
            //     {
            //         if (isSupportedBy(temporal) == false)
            //         {
            //             throw new Exception("Unsupported field: WeekOfWeekBasedYear");
            //         }
            //         return getWeekRange(LocalDate.from(temporal));
            //     }
            //     override
            //     public long getFrom(TemporalAccessor temporal)
            //     {
            //         if (isSupportedBy(temporal) == false)
            //         {
            //             throw new Exception("Unsupported field: WeekOfWeekBasedYear");
            //         }
            //         return getWeek(LocalDate.from(temporal));
            //     }
            //     /*@SuppressWarnings("unchecked")*/
            //     override public Temporal adjustInto(Temporal temporal, long newValue)
            //             /* if (is(R : Temporal)) */
            //     {
            //         // calls getFrom() to check if supported
            //         range().checkValidValue(newValue, this); // lenient range
            //         return cast(Temporal) temporal.plus(Math.subtractExact(newValue,
            //                 getFrom(temporal)), ChronoUnit.WEEKS);
            //     }
            //     override
            //     public ChronoLocalDate resolve(Map!(TemporalField, Long) fieldValues,
            //             TemporalAccessor partialTemporal, ResolverStyle resolverStyle)
            //     {
            //         Long wbyLong = fieldValues.get(WEEK_BASED_YEAR);
            //         Long dowLong = fieldValues.get(ChronoField.DAY_OF_WEEK);
            //         if (wbyLong is null || dowLong is null)
            //         {
            //             return null;
            //         }
            //         int wby = WEEK_BASED_YEAR.range()
            //             .checkValidIntValue(wbyLong.longValue(), WEEK_BASED_YEAR); // always validate
            //         long wowby = fieldValues.get(WEEK_OF_WEEK_BASED_YEAR).longValue();
            //         ensureIso(partialTemporal);
            //         LocalDate date = LocalDate.of(wby, 1, 4);
            //         if (resolverStyle == ResolverStyle.LENIENT)
            //         {
            //             long dow = dowLong.longValue(); // unvalidated
            //             if (dow > 7)
            //             {
            //                 date = date.plusWeeks((dow - 1) / 7);
            //                 dow = ((dow - 1) % 7) + 1;
            //             }
            //             else if (dow < 1)
            //             {
            //                 date = date.plusWeeks(Math.subtractExact(dow, 7) / 7);
            //                 dow = ((dow + 6) % 7) + 1;
            //             }
            //             date = date.plusWeeks(Math.subtractExact(wowby, 1))
            //                 ._with(ChronoField.DAY_OF_WEEK, dow);
            //         }
            //         else
            //         {
            //             int dow = ChronoField.DAY_OF_WEEK.checkValidIntValue(dowLong.longValue()); // validated
            //             if (wowby < 1 || wowby > 52)
            //             {
            //                 if (resolverStyle == ResolverStyle.STRICT)
            //                 {
            //                     getWeekRange(date).checkValidValue(wowby, this); // only allow exact range
            //                 }
            //                 else
            //                 { // SMART
            //                     range().checkValidValue(wowby, this); // allow 1-53 rolling into next year
            //                 }
            //             }
            //             date = date.plusWeeks(wowby - 1)._with(ChronoField.DAY_OF_WEEK, dow);
            //         }
            //         fieldValues.remove(this);
            //         fieldValues.remove(WEEK_BASED_YEAR);
            //         fieldValues.remove(ChronoField.DAY_OF_WEEK);
            //         return date;
            //     }

            //     /* override */
            //     // string getDisplayName(Locale locale)
            //     // {
            //     //     assert(locale, "locale");
            //     //     return toString();
            //     // }

            //     override public string toString()
            //     {
            //         return "WeekOfWeekBasedYear";
            //     }

            //     override int opCmp(TemporalField obj)
            //     {
            //         if (cast(Field)(obj) !is null)
            //         {
            //             Field other = cast(Field) obj;
            //             return compare(toString(), other.toString());
            //         }
            //         return 0;
            //     }
            // };

            mixin(MakeGlobalVar!(Field)("WEEK_OF_WEEK_BASED_YEAR",`new class Field
            {
                override
                public string getDisplayName(Locale locale)
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

                override
                public TemporalUnit getBaseUnit()
                {
                    return ChronoUnit.WEEKS;
                }
                override
                public TemporalUnit getRangeUnit()
                {
                    return IsoFields.WEEK_BASED_YEARS;
                }
                override
                public ValueRange range()
                {
                    return ValueRange.of(1, 52, 53);
                }
                override
                public bool isSupportedBy(TemporalAccessor temporal)
                {
                    return temporal.isSupported(ChronoField.EPOCH_DAY) && isIso(temporal);
                }

                override public ValueRange rangeRefinedBy(TemporalAccessor temporal)
                {
                    if (isSupportedBy(temporal) == false)
                    {
                        throw new Exception("Unsupported field: WeekOfWeekBasedYear");
                    }
                    return getWeekRange(LocalDate.from(temporal));
                }
                override
                public long getFrom(TemporalAccessor temporal)
                {
                    if (isSupportedBy(temporal) == false)
                    {
                        throw new Exception("Unsupported field: WeekOfWeekBasedYear");
                    }
                    return getWeek(LocalDate.from(temporal));
                }
                /*@SuppressWarnings("unchecked")*/
                override public Temporal adjustInto(Temporal temporal, long newValue)
                        /* if (is(R : Temporal)) */
                {
                    // calls getFrom() to check if supported
                    range().checkValidValue(newValue, this); // lenient range
                    return cast(Temporal) temporal.plus(Math.subtractExact(newValue,
                            getFrom(temporal)), ChronoUnit.WEEKS);
                }
                override
                public ChronoLocalDate resolve(Map!(TemporalField, Long) fieldValues,
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
                    if (cast(Field)(obj) !is null)
                    {
                        Field other = cast(Field) obj;
                        return compare(toString(), other.toString());
                    }
                    return 0;
                }
            }`));

            // WEEK_BASED_YEAR = new class Field
            // {
            //     override
            //     public TemporalUnit getBaseUnit()
            //     {
            //         return IsoFields.WEEK_BASED_YEARS;
            //     }
            //     override
            //     public TemporalUnit getRangeUnit()
            //     {
            //         return ChronoUnit.FOREVER;
            //     }
            //     override
            //     public ValueRange range()
            //     {
            //         return ChronoField.YEAR.range();
            //     }
            //     override
            //     public bool isSupportedBy(TemporalAccessor temporal)
            //     {
            //         return temporal.isSupported(ChronoField.EPOCH_DAY) && isIso(temporal);
            //     }
            //     override
            //     public long getFrom(TemporalAccessor temporal)
            //     {
            //         if (isSupportedBy(temporal) == false)
            //         {
            //             throw new Exception("Unsupported field: WeekBasedYear");
            //         }
            //         return getWeekBasedYear(LocalDate.from(temporal));
            //     }

            //     override public ValueRange rangeRefinedBy(TemporalAccessor temporal)
            //     {
            //         if (isSupportedBy(temporal) == false)
            //         {
            //             throw new Exception("Unsupported field: WeekBasedYear");
            //         }
            //         return range()/* super.rangeRefinedBy(temporal) */;
            //     }
            //     /*@SuppressWarnings("unchecked")*/
            //     override public Temporal adjustInto(Temporal temporal, long newValue)
            //             /* if (is(R : Temporal)) */
            //     {
            //         if (isSupportedBy(temporal) == false)
            //         {
            //             throw new Exception("Unsupported field: WeekBasedYear");
            //         }
            //         int newWby = range().checkValidIntValue(newValue, WEEK_BASED_YEAR); // strict check
            //         LocalDate date = LocalDate.from(temporal);
            //         int dow = date.get(ChronoField.DAY_OF_WEEK);
            //         int week = getWeek(date);
            //         if (week == 53 && getWeekRange(newWby) == 52)
            //         {
            //             week = 52;
            //         }
            //         LocalDate resolved = LocalDate.of(newWby, 1, 4); // 4th is guaranteed to be _in week one
            //         int days = (dow - resolved.get(ChronoField.DAY_OF_WEEK)) + ((week - 1) * 7);
            //         resolved = resolved.plusDays(days);
            //         return cast(Temporal) temporal._with(resolved);
            //     }

            //     override
            //     string getDisplayName(Locale locale)
            //     {
            //         assert(locale, "locale");
            //         return toString();
            //     }

            //     override public string toString()
            //     {
            //         return "WeekBasedYear";
            //     }

            //     override TemporalAccessor resolve(Map!(TemporalField, Long) fieldValues,
            //             TemporalAccessor partialTemporal, ResolverStyle resolverStyle)
            //     {
            //         return null;
            //     }

            //     override int opCmp(TemporalField obj)
            //     {
            //         if (cast(Field)(obj) !is null)
            //         {
            //             Field other = cast(Field) obj;
            //             return compare(toString(), other.toString());
            //         }
            //         return 0;
            //     }
            // };
            mixin(MakeGlobalVar!(Field)("WEEK_BASED_YEAR",`new class Field
            {
                override
                public TemporalUnit getBaseUnit()
                {
                    return IsoFields.WEEK_BASED_YEARS;
                }
                override
                public TemporalUnit getRangeUnit()
                {
                    return ChronoUnit.FOREVER;
                }
                override
                public ValueRange range()
                {
                    return ChronoField.YEAR.range();
                }
                override
                public bool isSupportedBy(TemporalAccessor temporal)
                {
                    return temporal.isSupported(ChronoField.EPOCH_DAY) && isIso(temporal);
                }
                override
                public long getFrom(TemporalAccessor temporal)
                {
                    if (isSupportedBy(temporal) == false)
                    {
                        throw new Exception("Unsupported field: WeekBasedYear");
                    }
                    return getWeekBasedYear(LocalDate.from(temporal));
                }

                override public ValueRange rangeRefinedBy(TemporalAccessor temporal)
                {
                    if (isSupportedBy(temporal) == false)
                    {
                        throw new Exception("Unsupported field: WeekBasedYear");
                    }
                    return range()/* super.rangeRefinedBy(temporal) */;
                }
                /*@SuppressWarnings("unchecked")*/
                override public Temporal adjustInto(Temporal temporal, long newValue)
                        /* if (is(R : Temporal)) */
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

                override
                string getDisplayName(Locale locale)
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
                    if (cast(Field)(obj) !is null)
                    {
                        Field other = cast(Field) obj;
                        return compare(toString(), other.toString());
                    }
                    return 0;
                }
            }`));
        // }

        override public bool isDateBased()
        {
            return true;
        }

        override public bool isTimeBased()
        {
            return false;
        }

        override public ValueRange rangeRefinedBy(TemporalAccessor temporal)
        {
            return range();
        }

        //-------------------------------------------------------------------------
        enum int[] QUARTER_DAYS = [0, 90, 181, 273, 0, 91, 182, 274];

         static void ensureIso(TemporalAccessor temporal)
        {
            if (isIso(temporal) == false)
            {
                throw new DateTimeException("Resolve requires IsoChronology");
            }
        }

         static ValueRange getWeekRange(LocalDate date)
        {
            int wby = getWeekBasedYear(date);
            return ValueRange.of(1, getWeekRange(wby));
        }

         static int getWeekRange(int wby)
        {
            LocalDate date = LocalDate.of(wby, 1, 1);
            // 53 weeks if standard year starts on Thursday, or Wed _in a leap year
            if (date.getDayOfWeek() == DayOfWeek.THURSDAY
                    || (date.getDayOfWeek() == DayOfWeek.WEDNESDAY && date.isLeapYear()))
            {
                return 53;
            }
            return 52;
        }

         static int getWeek(LocalDate date)
        {
            int dow0 = date.getDayOfWeek().ordinal();
            int doy0 = date.getDayOfYear() - 1;
            int doyThu0 = doy0 + (3 - dow0); // adjust to mid-week Thursday (which is 3 indexed from zero)
            int alignedWeek = doyThu0 / 7;
            int firstThuDoy0 = doyThu0 - (alignedWeek * 7);
            int firstMonDoy0 = firstThuDoy0 - 3;
            if (firstMonDoy0 < -3)
            {
                firstMonDoy0 += 7;
            }
            if (doy0 < firstMonDoy0)
            {
                return cast(int) getWeekRange(date.withDayOfYear(180).minusYears(1)).getMaximum();
            }
            int week = ((doy0 - firstMonDoy0) / 7) + 1;
            if (week == 53)
            {
                if ((firstMonDoy0 == -3 || (firstMonDoy0 == -2 && date.isLeapYear())) == false)
                {
                    week = 1;
                }
            }
            return week;
        }

        static int getWeekBasedYear(LocalDate date)
        {
            int year = date.getYear();
            int doy = date.getDayOfYear();
            if (doy <= 3)
            {
                int dow = date.getDayOfWeek().ordinal();
                if (doy - dow < -2)
                {
                    year--;
                }
            }
            else if (doy >= 363)
            {
                int dow = date.getDayOfWeek().ordinal();
                doy = doy - 363 - (date.isLeapYear() ? 1 : 0);
                if (doy - dow >= 0)
                {
                    year++;
                }
            }
            return year;
        }
    }

    //-----------------------------------------------------------------------
    /**
     * Implementation of the unit.
     */
    static class Unit : TemporalUnit
    {

        /**
         * Unit that represents the concept of a week-based-year.
         */
        // static Unit WEEK_BASED_YEARS;
        /**
         * Unit that represents the concept of a quarter-year.
         */
        // static Unit QUARTER_YEARS;

        // shared static this()
        // {
            // WEEK_BASED_YEARS = new Unit("WeekBasedYears", Duration.ofSeconds(31556952L));
            mixin(MakeGlobalVar!(Unit)("WEEK_BASED_YEARS",`new Unit("WeekBasedYears", Duration.ofSeconds(31556952L))`));
            // QUARTER_YEARS = new Unit("QuarterYears", Duration.ofSeconds(31556952L / 4));
            mixin(MakeGlobalVar!(Unit)("QUARTER_YEARS",`new Unit("QuarterYears", Duration.ofSeconds(31556952L / 4))`));

        // }

        private string name;
        private Duration duration;

        this(string name, Duration estimatedDuration)
        {
            this.name = name;
            this.duration = estimatedDuration;
        }

        override public Duration getDuration()
        {
            return duration;
        }

        override public bool isDurationEstimated()
        {
            return true;
        }

        override public bool isDateBased()
        {
            return true;
        }

        override public bool isTimeBased()
        {
            return false;
        }

        override public bool isSupportedBy(Temporal temporal)
        {
            return temporal.isSupported((ChronoField.EPOCH_DAY)) && isIso(temporal);
        }

        /*@SuppressWarnings("unchecked")*/
        override public Temporal addTo(Temporal temporal, long amount) /* if (is(R : Temporal)) */
        {
            auto name = this.toString();
            {
            if(name ==Unit.WEEK_BASED_YEARS.toString)
                return cast(Temporal) temporal._with(WEEK_BASED_YEAR,
                        Math.addExact(temporal.get(WEEK_BASED_YEAR), amount));
            if(name ==Unit.QUARTER_YEARS.toString)
                return cast(Temporal) temporal.plus(amount / 4, ChronoUnit.YEARS)
                    .plus((amount % 4) * 3, ChronoUnit.MONTHS);
            throw new IllegalStateException("Unreachable");
            }
        }

        override public long between(Temporal temporal1Inclusive, Temporal temporal2Exclusive)
        {
            if (typeid(temporal1Inclusive) != typeid(temporal2Exclusive))
            {
                return temporal1Inclusive.until(temporal2Exclusive, this);
            }
            auto name = this.toString();
            {
                if (name == WEEK_BASED_YEARS.toString)
                    return Math.subtractExact(temporal2Exclusive.getLong(WEEK_BASED_YEAR),
                            temporal1Inclusive.getLong(WEEK_BASED_YEAR));
                if (name == QUARTER_YEARS.toString)
                    return temporal1Inclusive.until(temporal2Exclusive, ChronoUnit.MONTHS) / 3;

                throw new IllegalStateException("Unreachable");
            }
        }

        override public string toString()
        {
            return name;
        }

    }

    static bool isIso(TemporalAccessor temporal)
    {
        return Chronology.from(temporal) == (IsoChronology.INSTANCE);
    }
}
