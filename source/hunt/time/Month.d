module hunt.time.Month;

import hunt.time.temporal.ChronoField;
import hunt.time.temporal.ChronoUnit;

import hunt.time.chrono.Chronology;
import hunt.time.chrono.IsoChronology;
import hunt.time.format.DateTimeFormatterBuilder;
import hunt.time.format.TextStyle;
import hunt.time.temporal.ChronoField;
import hunt.time.temporal.Temporal;
import hunt.time.temporal.TemporalAccessor;
import hunt.time.temporal.TemporalAdjuster;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.TemporalQueries;
import hunt.time.temporal.TemporalQuery;
import hunt.time.temporal.UnsupportedTemporalTypeException;
import hunt.time.temporal.ValueRange;
import hunt.time.util.Locale;
import hunt.time.DateTimeException;
import hunt.time.LocalDate;
import hunt.lang;
import std.conv;
import hunt.time.util.common;

/**
 * A month-of-year, such as 'July'.
 * !(p)
 * {@code Month} is an enum representing the 12 months of the year -
 * January, February, March, April, May, June, July, August, September, October,
 * November and December.
 * !(p)
 * In addition to the textual enum name, each month-of-year has an {@code int} value.
 * The {@code int} value follows normal usage and the ISO-8601 standard,
 * from 1 (January) to 12 (December). It is recommended that applications use the enum
 * rather than the {@code int} value to ensure code clarity.
 * !(p)
 * !(b)Do not use {@code ordinal()} to obtain the numeric representation of {@code Month}.
 * Use {@code getValue()} instead.</b>
 * !(p)
 * This enum represents a common concept that is found _in many calendar systems.
 * As such, this enum may be used by any calendar system that has the month-of-year
 * concept defined exactly equivalent to the ISO-8601 calendar system.
 *
 * @implSpec
 * This is an immutable and thread-safe enum.
 *
 * @since 1.8
 */
public class Month : TemporalAccessor, TemporalAdjuster
{

    /**
     * The singleton instance for the month of January with 31 days.
     * This has the numeric value of {@code 1}.
     */
    //static Month JANUARY;
    /**
     * The singleton instance for the month of February with 28 days, or 29 _in a leap year.
     * This has the numeric value of {@code 2}.
     */
    //static Month FEBRUARY;
    /**
     * The singleton instance for the month of March with 31 days.
     * This has the numeric value of {@code 3}.
     */
    //static Month MARCH;
    /**
     * The singleton instance for the month of April with 30 days.
     * This has the numeric value of {@code 4}.
     */
    //static Month APRIL;
    /**
     * The singleton instance for the month of May with 31 days.
     * This has the numeric value of {@code 5}.
     */
    //static Month MAY;
    /**
     * The singleton instance for the month of June with 30 days.
     * This has the numeric value of {@code 6}.
     */
    //static Month JUNE;
    /**
     * The singleton instance for the month of July with 31 days.
     * This has the numeric value of {@code 7}.
     */
    //static Month JULY;
    /**
     * The singleton instance for the month of August with 31 days.
     * This has the numeric value of {@code 8}.
     */
    //static Month AUGUST;
    /**
     * The singleton instance for the month of September with 30 days.
     * This has the numeric value of {@code 9}.
     */
    //static Month SEPTEMBER;
    /**
     * The singleton instance for the month of October with 31 days.
     * This has the numeric value of {@code 10}.
     */
    //static Month OCTOBER;
    /**
     * The singleton instance for the month of November with 30 days.
     * This has the numeric value of {@code 11}.
     */
    //static Month NOVEMBER;
    /**
     * The singleton instance for the month of December with 31 days.
     * This has the numeric value of {@code 12}.
     */
    //static Month DECEMBER;
    /**
     * Private cache of all the constants.
     */
    static Month[] _ENUMS;

    private int _ordinal = 0;
    private string _name;

    public string name()
    {
        return _name;
    }

    public int ordinal()
    {
        return _ordinal;
    }

    this(int ord, string name)
    {
        _ordinal = ord;
        _name = name;
    }

    public static ref Month[] ENUMS()
    {
        if(_ENUMS.length == 0)
        {
             /**
        * The singleton instance for the month of January with 31 days.
        * This has the numeric value of {@code 1}.
        */
            _ENUMS ~= JANUARY;
            /**
        * The singleton instance for the month of February with 28 days, or 29 _in a leap year.
        * This has the numeric value of {@code 2}.
        */
            _ENUMS ~= FEBRUARY;
            /**
        * The singleton instance for the month of March with 31 days.
        * This has the numeric value of {@code 3}.
        */
            _ENUMS ~= MARCH;
            /**
        * The singleton instance for the month of April with 30 days.
        * This has the numeric value of {@code 4}.
        */
            _ENUMS ~= APRIL;
            /**
        * The singleton instance for the month of May with 31 days.
        * This has the numeric value of {@code 5}.
        */
            MAY = new Month(4, "MAY");
            _ENUMS ~= MAY;
            /**
        * The singleton instance for the month of June with 30 days.
        * This has the numeric value of {@code 6}.
        */
            _ENUMS ~= JUNE;
            /**
        * The singleton instance for the month of July with 31 days.
        * This has the numeric value of {@code 7}.
        */
            _ENUMS ~= JULY;
            /**
        * The singleton instance for the month of August with 31 days.
        * This has the numeric value of {@code 8}.
        */
            _ENUMS ~= AUGUST;
            /**
        * The singleton instance for the month of September with 30 days.
        * This has the numeric value of {@code 9}.
        */
            _ENUMS ~= SEPTEMBER;
            /**
        * The singleton instance for the month of October with 31 days.
        * This has the numeric value of {@code 10}.
        */
            _ENUMS ~= OCTOBER;
            /**
        * The singleton instance for the month of November with 30 days.
        * This has the numeric value of {@code 11}.
        */
            _ENUMS ~= NOVEMBER;

            /**
        * The singleton instance for the month of December with 31 days.
        * This has the numeric value of {@code 12}.
        */
            _ENUMS ~= DECEMBER;
        }
        return _ENUMS;
    }

    // shared static this()
    // {
        /**
     * The singleton instance for the month of January with 31 days.
     * This has the numeric value of {@code 1}.
     */
        // JANUARY = new Month(0, "JANUARY");
        mixin(MakeGlobalVar!(Month)("JANUARY",`new Month(0, "JANUARY")`));
        // ENUMS ~= JANUARY;
        /**
     * The singleton instance for the month of February with 28 days, or 29 _in a leap year.
     * This has the numeric value of {@code 2}.
     */
        // FEBRUARY = new Month(1, "FEBRUARY");
        mixin(MakeGlobalVar!(Month)("FEBRUARY",`new Month(1, "FEBRUARY")`));

        // ENUMS ~= FEBRUARY;
        /**
     * The singleton instance for the month of March with 31 days.
     * This has the numeric value of {@code 3}.
     */
        // MARCH = new Month(2, "MARCH");
        mixin(MakeGlobalVar!(Month)("MARCH",`new Month(2, "MARCH")`));

        // ENUMS ~= MARCH;
        /**
     * The singleton instance for the month of April with 30 days.
     * This has the numeric value of {@code 4}.
     */
        // APRIL = new Month(3, "APRIL");
        mixin(MakeGlobalVar!(Month)("APRIL",`new Month(3, "APRIL")`));

        // ENUMS ~= APRIL;
        /**
     * The singleton instance for the month of May with 31 days.
     * This has the numeric value of {@code 5}.
     */
        // MAY = new Month(4, "MAY");
        mixin(MakeGlobalVar!(Month)("MAY",`new Month(4, "MAY")`));

        // ENUMS ~= MAY;
        /**
     * The singleton instance for the month of June with 30 days.
     * This has the numeric value of {@code 6}.
     */
        // JUNE = new Month(5, "JUNE");
        mixin(MakeGlobalVar!(Month)("JUNE",`new Month(5, "JUNE")`));

        // ENUMS ~= JUNE;
        /**
     * The singleton instance for the month of July with 31 days.
     * This has the numeric value of {@code 7}.
     */
        // JULY = new Month(6, "JULY");
        mixin(MakeGlobalVar!(Month)("JULY",`new Month(6, "JULY")`));

        // ENUMS ~= JULY;
        /**
     * The singleton instance for the month of August with 31 days.
     * This has the numeric value of {@code 8}.
     */
        // AUGUST = new Month(7, "AUGUST");
        mixin(MakeGlobalVar!(Month)("AUGUST",` new Month(7, "AUGUST")`));

        // ENUMS ~= AUGUST;
        /**
     * The singleton instance for the month of September with 30 days.
     * This has the numeric value of {@code 9}.
     */
        // SEPTEMBER = new Month(8, "SEPTEMBER");
        mixin(MakeGlobalVar!(Month)("SEPTEMBER",` new Month(8, "SEPTEMBER")`));

        // ENUMS ~= SEPTEMBER;
        /**
     * The singleton instance for the month of October with 31 days.
     * This has the numeric value of {@code 10}.
     */
        // OCTOBER = new Month(9, "OCTOBER");
        mixin(MakeGlobalVar!(Month)("OCTOBER",` new Month(9, "OCTOBER")`));

        // ENUMS ~= OCTOBER;
        /**
     * The singleton instance for the month of November with 30 days.
     * This has the numeric value of {@code 11}.
     */
        // NOVEMBER = new Month(10, "NOVEMBER");
        mixin(MakeGlobalVar!(Month)("NOVEMBER",` new Month(10, "NOVEMBER")`));

        // ENUMS ~= NOVEMBER;

        /**
     * The singleton instance for the month of December with 31 days.
     * This has the numeric value of {@code 12}.
     */
        // DECEMBER = new Month(11, "DECEMBER");
        mixin(MakeGlobalVar!(Month)("DECEMBER",` new Month(11, "DECEMBER")`));


        // ENUMS ~= DECEMBER;
    // }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code Month} from an {@code int} value.
     * !(p)
     * {@code Month} is an enum representing the 12 months of the year.
     * This factory allows the enum to be obtained from the {@code int} value.
     * The {@code int} value follows the ISO-8601 standard, from 1 (January) to 12 (December).
     *
     * @param month  the month-of-year to represent, from 1 (January) to 12 (December)
     * @return the month-of-year, not null
     * @throws DateTimeException if the month-of-year is invalid
     */
    public static Month of(int month)
    {
        if (month < 1 || month > 12)
        {
            throw new DateTimeException("Invalid value for MonthOfYear: " ~ month.to!string);
        }
        return ENUMS[month - 1];
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code Month} from a temporal object.
     * !(p)
     * This obtains a month based on the specified temporal.
     * A {@code TemporalAccessor} represents an arbitrary set of date and time information,
     * which this factory converts to an instance of {@code Month}.
     * !(p)
     * The conversion extracts the {@link ChronoField#MONTH_OF_YEAR MONTH_OF_YEAR} field.
     * The extraction is only permitted if the temporal object has an ISO
     * chronology, or can be converted to a {@code LocalDate}.
     * !(p)
     * This method matches the signature of the functional interface {@link TemporalQuery}
     * allowing it to be used as a query via method reference, {@code Month::from}.
     *
     * @param temporal  the temporal object to convert, not null
     * @return the month-of-year, not null
     * @throws DateTimeException if unable to convert to a {@code Month}
     */
    public static Month from(TemporalAccessor temporal)
    {
        if (cast(Month)(temporal) !is null)
        {
            return cast(Month) temporal;
        }
        try
        {
            if ((IsoChronology.INSTANCE == Chronology.from(temporal)) == false)
            {
                temporal = LocalDate.from(temporal);
            }
            return of(temporal.get(ChronoField.MONTH_OF_YEAR));
        }
        catch (DateTimeException ex)
        {
            throw new DateTimeException("Unable to obtain Month from TemporalAccessor: " ~ typeid(temporal)
                    .name ~ " of type " ~ typeid(temporal).stringof, ex);
        }
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the month-of-year {@code int} value.
     * !(p)
     * The values are numbered following the ISO-8601 standard,
     * from 1 (January) to 12 (December).
     *
     * @return the month-of-year, from 1 (January) to 12 (December)
     */
    public int getValue()
    {
        return ordinal() + 1;
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the textual representation, such as 'Jan' or 'December'.
     * !(p)
     * This returns the textual name used to identify the month-of-year,
     * suitable for presentation to the user.
     * The parameters control the style of the returned text and the locale.
     * !(p)
     * If no textual mapping is found then the {@link #getValue() numeric value} is returned.
     *
     * @param style  the length of the text required, not null
     * @param locale  the locale to use, not null
     * @return the text value of the month-of-year, not null
     */
    public string getDisplayName(TextStyle style, Locale locale)
    {
        return new DateTimeFormatterBuilder().appendText(ChronoField.MONTH_OF_YEAR,
                style).toFormatter(locale).format(this);
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if the specified field is supported.
     * !(p)
     * This checks if this month-of-year can be queried for the specified field.
     * If false, then calling the {@link #range(TemporalField) range} and
     * {@link #get(TemporalField) get} methods will throw an exception.
     * !(p)
     * If the field is {@link ChronoField#MONTH_OF_YEAR MONTH_OF_YEAR} then
     * this method returns true.
     * All other {@code ChronoField} instances will return false.
     * !(p)
     * If the field is not a {@code ChronoField}, then the result of this method
     * is obtained by invoking {@code TemporalField.isSupportedBy(TemporalAccessor)}
     * passing {@code this} as the argument.
     * Whether the field is supported is determined by the field.
     *
     * @param field  the field to check, null returns false
     * @return true if the field is supported on this month-of-year, false if not
     */
    override public bool isSupported(TemporalField field)
    {
        if (cast(ChronoField)(field) !is null)
        {
            return field == ChronoField.MONTH_OF_YEAR;
        }
        return field !is null && field.isSupportedBy(this);
    }

    /**
     * Gets the range of valid values for the specified field.
     * !(p)
     * The range object expresses the minimum and maximum valid values for a field.
     * This month is used to enhance the accuracy of the returned range.
     * If it is not possible to return the range, because the field is not supported
     * or for some other reason, an exception is thrown.
     * !(p)
     * If the field is {@link ChronoField#MONTH_OF_YEAR MONTH_OF_YEAR} then the
     * range of the month-of-year, from 1 to 12, will be returned.
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
    override public ValueRange range(TemporalField field)
    {
        if (field == ChronoField.MONTH_OF_YEAR)
        {
            return field.range();
        }
        return  /* TemporalAccessor. super.*/ super_range(field);
    }

    ValueRange super_range(TemporalField field)
    {
        if (cast(ChronoField)(field) !is null)
        {
            if (isSupported(field))
            {
                return field.range();
            }
            throw new UnsupportedTemporalTypeException("Unsupported field: " ~ typeid(field).name);
        }
        assert(field, "field");
        return field.rangeRefinedBy(this);
    }
    /**
     * Gets the value of the specified field from this month-of-year as an {@code int}.
     * !(p)
     * This queries this month for the value of the specified field.
     * The returned value will always be within the valid range of values for the field.
     * If it is not possible to return the value, because the field is not supported
     * or for some other reason, an exception is thrown.
     * !(p)
     * If the field is {@link ChronoField#MONTH_OF_YEAR MONTH_OF_YEAR} then the
     * value of the month-of-year, from 1 to 12, will be returned.
     * All other {@code ChronoField} instances will throw an {@code UnsupportedTemporalTypeException}.
     * !(p)
     * If the field is not a {@code ChronoField}, then the result of this method
     * is obtained by invoking {@code TemporalField.getFrom(TemporalAccessor)}
     * passing {@code this} as the argument. Whether the value can be obtained,
     * and what the value represents, is determined by the field.
     *
     * @param field  the field to get, not null
     * @return the value for the field, within the valid range of values
     * @throws DateTimeException if a value for the field cannot be obtained or
     *         the value is outside the range of valid values for the field
     * @throws UnsupportedTemporalTypeException if the field is not supported or
     *         the range of values exceeds an {@code int}
     * @throws ArithmeticException if numeric overflow occurs
     */
    override public int get(TemporalField field)
    {
        if (field == ChronoField.MONTH_OF_YEAR)
        {
            return getValue();
        }
        return  /* TemporalAccessor. super.*/ super_get(field);
    }

    int super_get(TemporalField field)
    {
        ValueRange range = range(field);
        if (range.isIntValue() == false)
        {
            throw new UnsupportedTemporalTypeException("Invalid field " ~ typeid(field)
                    .name ~ " for get() method, use getLong() instead");
        }
        long value = getLong(field);
        if (range.isValidValue(value) == false)
        {
            throw new DateTimeException("Invalid value for " ~ typeid(field)
                    .name ~ " (valid values " ~ range.toString ~ "): " ~ value.to!string);
        }
        return cast(int) value;
    }

    /**
     * Gets the value of the specified field from this month-of-year as a {@code long}.
     * !(p)
     * This queries this month for the value of the specified field.
     * If it is not possible to return the value, because the field is not supported
     * or for some other reason, an exception is thrown.
     * !(p)
     * If the field is {@link ChronoField#MONTH_OF_YEAR MONTH_OF_YEAR} then the
     * value of the month-of-year, from 1 to 12, will be returned.
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
    override public long getLong(TemporalField field)
    {
        if (field == ChronoField.MONTH_OF_YEAR)
        {
            return getValue();
        }
        else if (cast(ChronoField)(field) !is null)
        {
            throw new UnsupportedTemporalTypeException("Unsupported field: " ~ typeid(field).name);
        }
        return field.getFrom(this);
    }

    //-----------------------------------------------------------------------
    /**
     * Returns the month-of-year that is the specified number of months after this one.
     * !(p)
     * The calculation rolls around the end of the year from December to January.
     * The specified period may be negative.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param months  the months to add, positive or negative
     * @return the resulting month, not null
     */
    public Month plus(long months)
    {
        int amount = cast(int)(months % 12);
        return ENUMS[(ordinal() + (amount + 12)) % 12];
    }

    /**
     * Returns the month-of-year that is the specified number of months before this one.
     * !(p)
     * The calculation rolls around the start of the year from January to December.
     * The specified period may be negative.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param months  the months to subtract, positive or negative
     * @return the resulting month, not null
     */
    public Month minus(long months)
    {
        return plus(-(months % 12));
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the length of this month _in days.
     * !(p)
     * This takes a flag to determine whether to return the length for a leap year or not.
     * !(p)
     * February has 28 days _in a standard year and 29 days _in a leap year.
     * April, June, September and November have 30 days.
     * All other months have 31 days.
     *
     * @param leapYear  true if the length is required for a leap year
     * @return the length of this month _in days, from 28 to 31
     */
    public int length(bool leapYear)
    {
        switch (_ordinal)
        {
        case 1:
            return (leapYear ? 29 : 28);
        case 3:
        case 5:
        case 8:
        case 10:
            return 30;
        default:
            return 31;
        }
    }

    /**
     * Gets the minimum length of this month _in days.
     * !(p)
     * February has a minimum length of 28 days.
     * April, June, September and November have 30 days.
     * All other months have 31 days.
     *
     * @return the minimum length of this month _in days, from 28 to 31
     */
    public int minLength()
    {
        switch (_ordinal)
        {
        case 1:
            return 28;
        case 3:
        case 5:
        case 8:
        case 10:
            return 30;
        default:
            return 31;
        }
    }

    /**
     * Gets the maximum length of this month _in days.
     * !(p)
     * February has a maximum length of 29 days.
     * April, June, September and November have 30 days.
     * All other months have 31 days.
     *
     * @return the maximum length of this month _in days, from 29 to 31
     */
    public int maxLength()
    {
        switch (_ordinal)
        {
        case 1:
            return 29;
        case 3:
        case 5:
        case 8:
        case 10:
            return 30;
        default:
            return 31;
        }
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the day-of-year corresponding to the first day of this month.
     * !(p)
     * This returns the day-of-year that this month begins on, using the leap
     * year flag to determine the length of February.
     *
     * @param leapYear  true if the length is required for a leap year
     * @return the day of year corresponding to the first day of this month, from 1 to 336
     */
    public int firstDayOfYear(bool leapYear)
    {
        int leap = leapYear ? 1 : 0;
        switch (_name)
        {
        case "JANUARY":
            return 1;
        case "FEBRUARY":
            return 32;
        case "MARCH":
            return 60 + leap;
        case "APRIL":
            return 91 + leap;
        case "MAY":
            return 121 + leap;
        case "JUNE":
            return 152 + leap;
        case "JULY":
            return 182 + leap;
        case "AUGUST":
            return 213 + leap;
        case "SEPTEMBER":
            return 244 + leap;
        case "OCTOBER":
            return 274 + leap;
        case "NOVEMBER":
            return 305 + leap;
        case "DECEMBER":
        default:
            return 335 + leap;
        }
    }

    /**
     * Gets the month corresponding to the first month of this quarter.
     * !(p)
     * The year can be divided into four quarters.
     * This method returns the first month of the quarter for the base month.
     * January, February and March return January.
     * April, May and June return April.
     * July, August and September return July.
     * October, November and December return October.
     *
     * @return the first month of the quarter corresponding to this month, not null
     */
    public Month firstMonthOfQuarter()
    {
        return ENUMS[(ordinal() / 3) * 3];
    }

    //-----------------------------------------------------------------------
    /**
     * Queries this month-of-year using the specified query.
     * !(p)
     * This queries this month-of-year using the specified query strategy object.
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
    public R query(R)(TemporalQuery!(R) query)
    {
        if (query == TemporalQueries.chronology())
        {
            return cast(R) IsoChronology.INSTANCE;
        }
        else if (query == TemporalQueries.precision())
        {
            return cast(R)(ChronoUnit.MONTHS);
        }
        return  /* TemporalAccessor. */ super_query(query);
    }

    R super_query(R)(TemporalQuery!(R) query)
    {
        if (query == TemporalQueries.zoneId() || query == TemporalQueries.chronology()
                || query == TemporalQueries.precision())
        {
            return null;
        }
        return query.queryFrom(this);
    }

    /**
     * Adjusts the specified temporal object to have this month-of-year.
     * !(p)
     * This returns a temporal object of the same observable type as the input
     * with the month-of-year changed to be the same as this.
     * !(p)
     * The adjustment is equivalent to using {@link Temporal#_with(TemporalField, long)}
     * passing {@link ChronoField#MONTH_OF_YEAR} as the field.
     * If the specified temporal object does not use the ISO calendar system then
     * a {@code DateTimeException} is thrown.
     * !(p)
     * In most cases, it is clearer to reverse the calling pattern by using
     * {@link Temporal#_with(TemporalAdjuster)}:
     * !(pre)
     *   // these two lines are equivalent, but the second approach is recommended
     *   temporal = thisMonth.adjustInto(temporal);
     *   temporal = temporal._with(thisMonth);
     * </pre>
     * !(p)
     * For example, given a date _in May, the following are output:
     * !(pre)
     *   dateInMay._with(JANUARY);    // four months earlier
     *   dateInMay._with(APRIL);      // one months earlier
     *   dateInMay._with(MAY);        // same date
     *   dateInMay._with(JUNE);       // one month later
     *   dateInMay._with(DECEMBER);   // seven months later
     * </pre>
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param temporal  the target object to be adjusted, not null
     * @return the adjusted object, not null
     * @throws DateTimeException if unable to make the adjustment
     * @throws ArithmeticException if numeric overflow occurs
     */
    override public Temporal adjustInto(Temporal temporal)
    {
        if ((Chronology.from(temporal) == IsoChronology.INSTANCE) == false)
        {
            throw new DateTimeException("Adjustment only supported on ISO date-time");
        }
        return temporal._with(ChronoField.MONTH_OF_YEAR, getValue());
    }

    override string toString()
    {
        return this._name;
    }

}
