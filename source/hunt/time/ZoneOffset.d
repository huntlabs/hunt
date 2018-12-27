module hunt.time.ZoneOffset;

import hunt.time.LocalTime;
import hunt.time.temporal.ChronoField;

import hunt.io.DataInput;
import hunt.io.DataOutput;
import hunt.lang.exception;

//import hunt.io.ObjectInputStream;
import hunt.io.common;
import hunt.time.temporal.ChronoField;
import hunt.time.temporal.Temporal;
import hunt.time.temporal.TemporalAccessor;
import hunt.time.temporal.TemporalAdjuster;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.TemporalQueries;
import hunt.time.temporal.TemporalQuery;
import hunt.time.temporal.UnsupportedTemporalTypeException;
import hunt.time.temporal.ValueRange;
import hunt.time.zone.ZoneRules;
import hunt.time.ZoneId;
import hunt.lang.common;
import hunt.container;
import hunt.lang;
import hunt.string.common;
import hunt.time.DateTimeException;
import std.conv;
import hunt.string.StringBuilder;
import hunt.time.Ser;
import hunt.time.util.QueryHelper;
import hunt.time.util.common;
// import hunt.concurrent.ConcurrentMap;

/**
 * A time-zone offset from Greenwich/UTC, such as {@code +02:00}.
 * !(p)
 * A time-zone offset is the amount of time that a time-zone differs from Greenwich/UTC.
 * This is usually a fixed number of hours and minutes.
 * !(p)
 * Different parts of the world have different time-zone offsets.
 * The rules for how offsets vary by place and time of year are captured _in the
 * {@link ZoneId} class.
 * !(p)
 * For example, Paris is one hour ahead of Greenwich/UTC _in winter and two hours
 * ahead _in summer. The {@code ZoneId} instance for Paris will reference two
 * {@code ZoneOffset} instances - a {@code +01:00} instance for winter,
 * and a {@code +02:00} instance for summer.
 * !(p)
 * In 2008, time-zone offsets around the world extended from -12:00 to +14:00.
 * To prevent any problems with that range being extended, yet still provide
 * validation, the range of offsets is restricted to -18:00 to 18:00 inclusive.
 * !(p)
 * This class is designed for use with the ISO calendar system.
 * The fields of hours, minutes and seconds make assumptions that are valid for the
 * standard ISO definitions of those fields. This class may be used with other
 * calendar systems providing the definition of the time fields matches those
 * of the ISO calendar system.
 * !(p)
 * Instances of {@code ZoneOffset} must be compared using {@link #equals}.
 * Implementations may choose to cache certain common offsets, however
 * applications must not rely on such caching.
 *
 * !(p)
 * This is a <a href="{@docRoot}/java.base/java/lang/doc-files/ValueBased.html">value-based</a>
 * class; use of identity-sensitive operations (including reference equality
 * ({@code ==}), identity hash code, or synchronization) on instances of
 * {@code ZoneOffset} may have unpredictable results and should be avoided.
 * The {@code equals} method should be used for comparisons.
 *
 * @implSpec
 * This class is immutable and thread-safe.
 *
 * @since 1.8
 */
public final class ZoneOffset : ZoneId, TemporalAccessor, TemporalAdjuster,
    Comparable!(ZoneOffset), Serializable
{

    /** Cache of time-zone offset by offset _in seconds. */
    // private static final ConcurrentMap!(Integer, ZoneOffset) SECONDS_CACHE = new ConcurrentHashMap!()(16, 0.75f, 4);
     //__gshared HashMap!(Integer, ZoneOffset) SECONDS_CACHE;

    /** Cache of time-zone offset by ID. */
    //  static final ConcurrentMap!(string, ZoneOffset) ID_CACHE = new ConcurrentHashMap!()(16, 0.75f, 4);
     //__gshared HashMap!(string, ZoneOffset) ID_CACHE;

    /**
     * The abs maximum seconds.
     */
     enum int MAX_SECONDS = 18 * LocalTime.SECONDS_PER_HOUR;
     
     
    /**
     * The time-zone offset for UTC, with an ID of 'Z'.
     */
    //public __gshared ZoneOffset UTC;
    /**
     * Constant for the minimum supported offset.
     */
    //public __gshared ZoneOffset MIN;
    /**
     * Constant for the maximum supported offset.
     */
    //public __gshared ZoneOffset MAX;

    /**
     * The total offset _in seconds.
     */
    private int _totalSeconds;
    /**
     * The string form of the time-zone offset.
     */
    private  /*transient*/ string id;

    // shared static this()
    // {
    //     // SECONDS_CACHE = new HashMap!(Integer, ZoneOffset)(16, 0.75f /* , 4 */ );
        mixin(MakeGlobalVar!(HashMap!(Integer, ZoneOffset))("SECONDS_CACHE",`new HashMap!(Integer, ZoneOffset)(16, 0.75f /* , 4 */ )`));
        // ID_CACHE = new HashMap!(string, ZoneOffset)(16, 0.75f /* , 4 */ );
        mixin(MakeGlobalVar!(HashMap!(string, ZoneOffset))("ID_CACHE",`new HashMap!(string, ZoneOffset)(16, 0.75f /* , 4 */ )`));

        // UTC = ZoneOffset.ofTotalSeconds(0);
        mixin(MakeGlobalVar!(ZoneOffset)("UTC",`ZoneOffset.ofTotalSeconds(0)`));

        // MIN = ZoneOffset.ofTotalSeconds(-MAX_SECONDS);
        mixin(MakeGlobalVar!(ZoneOffset)("MIN",`ZoneOffset.ofTotalSeconds(-MAX_SECONDS)`));

        // MAX = ZoneOffset.ofTotalSeconds(MAX_SECONDS);
        mixin(MakeGlobalVar!(ZoneOffset)("MAX",`ZoneOffset.ofTotalSeconds(MAX_SECONDS)`));

    // }
    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code ZoneOffset} using the ID.
     * !(p)
     * This method parses the string ID of a {@code ZoneOffset} to
     * return an instance. The parsing accepts all the formats generated by
     * {@link #getId()}, plus some additional formats:
     * !(ul)
     * !(li){@code Z} - for UTC
     * !(li){@code +h}
     * !(li){@code +hh}
     * !(li){@code +hh:mm}
     * !(li){@code -hh:mm}
     * !(li){@code +hhmm}
     * !(li){@code -hhmm}
     * !(li){@code +hh:mm:ss}
     * !(li){@code -hh:mm:ss}
     * !(li){@code +hhmmss}
     * !(li){@code -hhmmss}
     * </ul>
     * Note that &plusmn; means either the plus or minus symbol.
     * !(p)
     * The ID of the returned offset will be normalized to one of the formats
     * described by {@link #getId()}.
     * !(p)
     * The maximum supported range is from +18:00 to -18:00 inclusive.
     *
     * @param offsetId  the offset ID, not null
     * @return the zone-offset, not null
     * @throws DateTimeException if the offset ID is invalid
     */
    // @SuppressWarnings("fallthrough")
    public static ZoneOffset of(string offsetId)
    {
        assert(offsetId, "offsetId");
        // "Z" is always _in the cache
        ZoneOffset offset = ID_CACHE.get(offsetId);
        if (offset !is null)
        {
            return offset;
        }

        // parse - +h, +hh, +hhmm, +hh:mm, +hhmmss, +hh:mm:ss
        int hours, minutes, seconds;
        switch (offsetId.length)
        {
        case 2:
            offsetId = offsetId.charAt(0) ~ "0" ~ offsetId.charAt(1); // fallthru
            goto case 3;
        case 3:
            hours = parseNumber(offsetId, 1, false);
            minutes = 0;
            seconds = 0;
            break;
        case 5:
            hours = parseNumber(offsetId, 1, false);
            minutes = parseNumber(offsetId, 3, false);
            seconds = 0;
            break;
        case 6:
            hours = parseNumber(offsetId, 1, false);
            minutes = parseNumber(offsetId, 4, true);
            seconds = 0;
            break;
        case 7:
            hours = parseNumber(offsetId, 1, false);
            minutes = parseNumber(offsetId, 3, false);
            seconds = parseNumber(offsetId, 5, false);
            break;
        case 9:
            hours = parseNumber(offsetId, 1, false);
            minutes = parseNumber(offsetId, 4, true);
            seconds = parseNumber(offsetId, 7, true);
            break;
        default:
            throw new DateTimeException("Invalid ID for ZoneOffset, invalid format: " ~ offsetId);
        }
        char first = offsetId.charAt(0);
        if (first != '+' && first != '-')
        {
            throw new DateTimeException(
                    "Invalid ID for ZoneOffset, plus/minus not found when expected: " ~ offsetId);
        }
        if (first == '-')
        {
            return ofHoursMinutesSeconds(-hours, -minutes, -seconds);
        }
        else
        {
            return ofHoursMinutesSeconds(hours, minutes, seconds);
        }
    }

    /**
     * Parse a two digit zero-prefixed number.
     *
     * @param offsetId  the offset ID, not null
     * @param pos  the position to parse, valid
     * @param precededByColon  should this number be prefixed by a precededByColon
     * @return the parsed number, from 0 to 99
     */
    private static int parseNumber(string offsetId, int pos, bool precededByColon)
    {
        if (precededByColon && offsetId.charAt(pos - 1) != ':')
        {
            throw new DateTimeException(
                    "Invalid ID for ZoneOffset, colon not found when expected: " ~ offsetId);
        }
        char ch1 = offsetId.charAt(pos);
        char ch2 = offsetId.charAt(pos + 1);
        if (ch1 < '0' || ch1 > '9' || ch2 < '0' || ch2 > '9')
        {
            throw new DateTimeException(
                    "Invalid ID for ZoneOffset, non numeric characters found: " ~ offsetId);
        }
        return (ch1 - 48) * 10 + (ch2 - 48);
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code ZoneOffset} using an offset _in hours.
     *
     * @param hours  the time-zone offset _in hours, from -18 to +18
     * @return the zone-offset, not null
     * @throws DateTimeException if the offset is not _in the required range
     */
    public static ZoneOffset ofHours(int hours)
    {
        return ofHoursMinutesSeconds(hours, 0, 0);
    }

    /**
     * Obtains an instance of {@code ZoneOffset} using an offset _in
     * hours and minutes.
     * !(p)
     * The sign of the hours and minutes components must match.
     * Thus, if the hours is negative, the minutes must be negative or zero.
     * If the hours is zero, the minutes may be positive, negative or zero.
     *
     * @param hours  the time-zone offset _in hours, from -18 to +18
     * @param minutes  the time-zone offset _in minutes, from 0 to &plusmn;59, sign matches hours
     * @return the zone-offset, not null
     * @throws DateTimeException if the offset is not _in the required range
     */
    public static ZoneOffset ofHoursMinutes(int hours, int minutes)
    {
        return ofHoursMinutesSeconds(hours, minutes, 0);
    }

    /**
     * Obtains an instance of {@code ZoneOffset} using an offset _in
     * hours, minutes and seconds.
     * !(p)
     * The sign of the hours, minutes and seconds components must match.
     * Thus, if the hours is negative, the minutes and seconds must be negative or zero.
     *
     * @param hours  the time-zone offset _in hours, from -18 to +18
     * @param minutes  the time-zone offset _in minutes, from 0 to &plusmn;59, sign matches hours and seconds
     * @param seconds  the time-zone offset _in seconds, from 0 to &plusmn;59, sign matches hours and minutes
     * @return the zone-offset, not null
     * @throws DateTimeException if the offset is not _in the required range
     */
    public static ZoneOffset ofHoursMinutesSeconds(int hours, int minutes, int seconds)
    {
        validate(hours, minutes, seconds);
        int _totalSeconds = totalSeconds(hours, minutes, seconds);
        return ofTotalSeconds(_totalSeconds);
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code ZoneOffset} from a temporal object.
     * !(p)
     * This obtains an offset based on the specified temporal.
     * A {@code TemporalAccessor} represents an arbitrary set of date and time information,
     * which this factory converts to an instance of {@code ZoneOffset}.
     * !(p)
     * A {@code TemporalAccessor} represents some form of date and time information.
     * This factory converts the arbitrary temporal object to an instance of {@code ZoneOffset}.
     * !(p)
     * The conversion uses the {@link TemporalQueries#offset()} query, which relies
     * on extracting the {@link ChronoField#OFFSET_SECONDS OFFSET_SECONDS} field.
     * !(p)
     * This method matches the signature of the functional interface {@link TemporalQuery}
     * allowing it to be used as a query via method reference, {@code ZoneOffset::from}.
     *
     * @param temporal  the temporal object to convert, not null
     * @return the zone-offset, not null
     * @throws DateTimeException if unable to convert to an {@code ZoneOffset}
     */
    public static ZoneOffset from(TemporalAccessor temporal)
    {
        assert(temporal, "temporal");
        ZoneOffset offset = QueryHelper.query!ZoneOffset(temporal, TemporalQueries.offset());
        if (offset is null)
        {
            throw new DateTimeException("Unable to obtain ZoneOffset from TemporalAccessor: " ~ typeid(temporal)
                    .name ~ " of type " ~ typeid(temporal).stringof);
        }
        return offset;
    }

    //-----------------------------------------------------------------------
    /**
     * Validates the offset fields.
     *
     * @param hours  the time-zone offset _in hours, from -18 to +18
     * @param minutes  the time-zone offset _in minutes, from 0 to &plusmn;59
     * @param seconds  the time-zone offset _in seconds, from 0 to &plusmn;59
     * @throws DateTimeException if the offset is not _in the required range
     */
    private static void validate(int hours, int minutes, int seconds)
    {
        if (hours < -18 || hours > 18)
        {
            throw new DateTimeException(
                    "Zone offset hours not _in valid range: value "
                    ~ hours.to!string ~ " is not _in the range -18 to 18");
        }
        if (hours > 0)
        {
            if (minutes < 0 || seconds < 0)
            {
                throw new DateTimeException(
                        "Zone offset minutes and seconds must be positive because hours is positive");
            }
        }
        else if (hours < 0)
        {
            if (minutes > 0 || seconds > 0)
            {
                throw new DateTimeException(
                        "Zone offset minutes and seconds must be negative because hours is negative");
            }
        }
        else if ((minutes > 0 && seconds < 0) || (minutes < 0 && seconds > 0))
        {
            throw new DateTimeException("Zone offset minutes and seconds must have the same sign");
        }
        if (minutes < -59 || minutes > 59)
        {
            throw new DateTimeException(
                    "Zone offset minutes not _in valid range: value "
                    ~ minutes.to!string ~ " is not _in the range -59 to 59");
        }
        if (seconds < -59 || seconds > 59)
        {
            throw new DateTimeException(
                    "Zone offset seconds not _in valid range: value "
                    ~ seconds.to!string ~ " is not _in the range -59 to 59");
        }
        if (Math.abs(hours) == 18 && (minutes | seconds) != 0)
        {
            throw new DateTimeException("Zone offset not _in valid range: -18:00 to +18:00");
        }
    }

    /**
     * Calculates the total offset _in seconds.
     *
     * @param hours  the time-zone offset _in hours, from -18 to +18
     * @param minutes  the time-zone offset _in minutes, from 0 to &plusmn;59, sign matches hours and seconds
     * @param seconds  the time-zone offset _in seconds, from 0 to &plusmn;59, sign matches hours and minutes
     * @return the total _in seconds
     */
    private static int totalSeconds(int hours, int minutes, int seconds)
    {
        return hours * LocalTime.SECONDS_PER_HOUR + minutes * LocalTime.SECONDS_PER_MINUTE + seconds;
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code ZoneOffset} specifying the total offset _in seconds
     * !(p)
     * The offset must be _in the range {@code -18:00} to {@code +18:00}, which corresponds to -64800 to +64800.
     *
     * @param _totalSeconds  the total time-zone offset _in seconds, from -64800 to +64800
     * @return the ZoneOffset, not null
     * @throws DateTimeException if the offset is not _in the required range
     */
    public static ZoneOffset ofTotalSeconds(int _totalSeconds)
    {
        if (_totalSeconds < -MAX_SECONDS || _totalSeconds > MAX_SECONDS)
        {
            throw new DateTimeException("Zone offset not _in valid range: -18:00 to +18:00");
        }
        if (_totalSeconds % (15 * LocalTime.SECONDS_PER_MINUTE) == 0)
        {
            Integer totalSecs = new Integer(_totalSeconds);
            ZoneOffset result = SECONDS_CACHE.get(totalSecs);
            if (result is null)
            {
                result = new ZoneOffset(_totalSeconds);
                SECONDS_CACHE.putIfAbsent(totalSecs, result);
                result = SECONDS_CACHE.get(totalSecs);
                ID_CACHE.putIfAbsent(result.getId(), result);
            }
            return result;
        }
        else
        {
            return new ZoneOffset(_totalSeconds);
        }
    }

    //-----------------------------------------------------------------------
    /**
     * Constructor.
     *
     * @param _totalSeconds  the total time-zone offset _in seconds, from -64800 to +64800
     */
    private this(int _totalSeconds)
    {
        super();
        this._totalSeconds = _totalSeconds;
        id = buildId(_totalSeconds);
    }

    private static string buildId(int _totalSeconds)
    {
        if (_totalSeconds == 0)
        {
            return "Z";
        }
        else
        {
            int absTotalSeconds = Math.abs(_totalSeconds);
            StringBuilder buf = new StringBuilder();
            int absHours = absTotalSeconds / LocalTime.SECONDS_PER_HOUR;
            int absMinutes = (absTotalSeconds / LocalTime.SECONDS_PER_MINUTE) % LocalTime
                .MINUTES_PER_HOUR;
            buf.append(_totalSeconds < 0 ? "-" : "+").append(absHours < 10 ? "0"
                    : "").append(absHours).append(absMinutes < 10 ? ":0" : ":").append(absMinutes);
            int absSeconds = absTotalSeconds % LocalTime.SECONDS_PER_MINUTE;
            if (absSeconds != 0)
            {
                buf.append(absSeconds < 10 ? ":0" : ":").append(absSeconds);
            }
            return buf.toString();
        }
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the total zone offset _in seconds.
     * !(p)
     * This is the primary way to access the offset amount.
     * It returns the total of the hours, minutes and seconds fields as a
     * single offset that can be added to a time.
     *
     * @return the total zone offset amount _in seconds
     */
    public int getTotalSeconds()
    {
        return _totalSeconds;
    }

    /**
     * Gets the normalized zone offset ID.
     * !(p)
     * The ID is minor variation to the standard ISO-8601 formatted string
     * for the offset. There are three formats:
     * !(ul)
     * !(li){@code Z} - for UTC (ISO-8601)
     * !(li){@code +hh:mm} or {@code -hh:mm} - if the seconds are zero (ISO-8601)
     * !(li){@code +hh:mm:ss} or {@code -hh:mm:ss} - if the seconds are non-zero (not ISO-8601)
     * </ul>
     *
     * @return the zone offset ID, not null
     */
    override public string getId()
    {
        return id;
    }

    /**
     * Gets the associated time-zone rules.
     * !(p)
     * The rules will always return this offset when queried.
     * The implementation class is immutable, thread-safe and serializable.
     *
     * @return the rules, not null
     */
    override public ZoneRules getRules()
    {
        return ZoneRules.of(this);
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if the specified field is supported.
     * !(p)
     * This checks if this offset can be queried for the specified field.
     * If false, then calling the {@link #range(TemporalField) range} and
     * {@link #get(TemporalField) get} methods will throw an exception.
     * !(p)
     * If the field is a {@link ChronoField} then the query is implemented here.
     * The {@code OFFSET_SECONDS} field returns true.
     * All other {@code ChronoField} instances will return false.
     * !(p)
     * If the field is not a {@code ChronoField}, then the result of this method
     * is obtained by invoking {@code TemporalField.isSupportedBy(TemporalAccessor)}
     * passing {@code this} as the argument.
     * Whether the field is supported is determined by the field.
     *
     * @param field  the field to check, null returns false
     * @return true if the field is supported on this offset, false if not
     */
    override public bool isSupported(TemporalField field)
    {
        if (cast(ChronoField)(field) !is null)
        {
            return field == ChronoField.OFFSET_SECONDS;
        }
        return field !is null && field.isSupportedBy(this);
    }

    /**
     * Gets the range of valid values for the specified field.
     * !(p)
     * The range object expresses the minimum and maximum valid values for a field.
     * This offset is used to enhance the accuracy of the returned range.
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
    override  // override for Javadoc
    public ValueRange range(TemporalField field)
    {
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
     * Gets the value of the specified field from this offset as an {@code int}.
     * !(p)
     * This queries this offset for the value of the specified field.
     * The returned value will always be within the valid range of values for the field.
     * If it is not possible to return the value, because the field is not supported
     * or for some other reason, an exception is thrown.
     * !(p)
     * If the field is a {@link ChronoField} then the query is implemented here.
     * The {@code OFFSET_SECONDS} field returns the value of the offset.
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
    override  // override for Javadoc and performance
    public int get(TemporalField field)
    {
        if (field == ChronoField.OFFSET_SECONDS)
        {
            return _totalSeconds;
        }
        else if (cast(ChronoField)(field) !is null)
        {
            throw new UnsupportedTemporalTypeException("Unsupported field: " ~ typeid(field).name);
        }
        return range(field).checkValidIntValue(getLong(field), field);
    }

    /**
     * Gets the value of the specified field from this offset as a {@code long}.
     * !(p)
     * This queries this offset for the value of the specified field.
     * If it is not possible to return the value, because the field is not supported
     * or for some other reason, an exception is thrown.
     * !(p)
     * If the field is a {@link ChronoField} then the query is implemented here.
     * The {@code OFFSET_SECONDS} field returns the value of the offset.
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
        if (field == ChronoField.OFFSET_SECONDS)
        {
            return _totalSeconds;
        }
        else if (cast(ChronoField)(field) !is null)
        {
            throw new UnsupportedTemporalTypeException("Unsupported field: " ~ typeid(field).name);
        }
        return field.getFrom(this);
    }

    //-----------------------------------------------------------------------
    /**
     * Queries this offset using the specified query.
     * !(p)
     * This queries this offset using the specified query strategy object.
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
    /* override */ public R query(R)(TemporalQuery!(R) query)
    {
        if (query == TemporalQueries.offset() || query == TemporalQueries.zone())
        {
            return cast(R) this;
        }
        return  /* TemporalAccessor. */ super_query(query);
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
     * Adjusts the specified temporal object to have the same offset as this object.
     * !(p)
     * This returns a temporal object of the same observable type as the input
     * with the offset changed to be the same as this.
     * !(p)
     * The adjustment is equivalent to using {@link Temporal#_with(TemporalField, long)}
     * passing {@link ChronoField#OFFSET_SECONDS} as the field.
     * !(p)
     * In most cases, it is clearer to reverse the calling pattern by using
     * {@link Temporal#_with(TemporalAdjuster)}:
     * !(pre)
     *   // these two lines are equivalent, but the second approach is recommended
     *   temporal = thisOffset.adjustInto(temporal);
     *   temporal = temporal._with(thisOffset);
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
        return temporal._with(ChronoField.OFFSET_SECONDS, _totalSeconds);
    }

    //-----------------------------------------------------------------------
    /**
     * Compares this offset to another offset _in descending order.
     * !(p)
     * The offsets are compared _in the order that they occur for the same time
     * of day around the world. Thus, an offset of {@code +10:00} comes before an
     * offset of {@code +09:00} and so on down to {@code -18:00}.
     * !(p)
     * The comparison is "consistent with equals", as defined by {@link Comparable}.
     *
     * @param other  the other date to compare to, not null
     * @return the comparator value, negative if less, positive if greater
     * @throws NullPointerException if {@code other} is null
     */
    // override
    public int compareTo(ZoneOffset other)
    {
        // abs(_totalSeconds) <= MAX_SECONDS, so no overflow can happen here
        return other._totalSeconds - _totalSeconds;
    }

    override public int opCmp(ZoneOffset other)
    {
        // abs(_totalSeconds) <= MAX_SECONDS, so no overflow can happen here
        return other._totalSeconds - _totalSeconds;
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if this offset is equal to another offset.
     * !(p)
     * The comparison is based on the amount of the offset _in seconds.
     * This is equivalent to a comparison by ID.
     *
     * @param obj  the object to check, null returns false
     * @return true if this is equal to the other offset
     */
    override public bool opEquals(Object obj)
    {
        if (this is obj)
        {
            return true;
        }
        if (cast(ZoneOffset)(obj) !is null)
        {
            return _totalSeconds == (cast(ZoneOffset) obj)._totalSeconds;
        }
        return false;
    }

    /**
     * A hash code for this offset.
     *
     * @return a suitable hash code
     */
    override public size_t toHash() @trusted nothrow
    {
        return _totalSeconds;
    }

    //-----------------------------------------------------------------------
    /**
     * Outputs this offset as a {@code string}, using the normalized ID.
     *
     * @return a string representation of this offset, not null
     */
    override public string toString()
    {
        return id;
    }

    // -----------------------------------------------------------------------
    /**
     * Writes the object using a
     * <a href="{@docRoot}/serialized-form.html#hunt.time.Ser">dedicated serialized form</a>.
     * @serialData
     * !(pre)
     *  _out.writeByte(8);                  // identifies a ZoneOffset
     *  int offsetByte = _totalSeconds % 900 == 0 ? _totalSeconds / 900 : 127;
     *  _out.writeByte(offsetByte);
     *  if (offsetByte == 127) {
     *      _out.writeInt(_totalSeconds);
     *  }
     * </pre>
     *
     * @return the instance of {@code Ser}, not null
     */
    // private Object writeReplace()
    // {
    //     return new Ser(Ser.ZONE_OFFSET_TYPE, this);
    // }

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

    // override void write(DataOutput _out) /*throws IOException*/
    // {
    //     _out.writeByte(Ser.ZONE_OFFSET_TYPE);
    //     writeExternal(_out);
    // }

    // void writeExternal(DataOutput _out) /*throws IOException*/
    // {
    //     int offsetSecs = _totalSeconds;
    //     int offsetByte = offsetSecs % 900 == 0 ? offsetSecs / 900 : 127; // compress to -72 to +72
    //     _out.writeByte(offsetByte);
    //     if (offsetByte == 127)
    //     {
    //         _out.writeInt(offsetSecs);
    //     }
    // }

    // static ZoneOffset readExternal(DataInput _in) /*throws IOException*/
    // {
    //     int offsetByte = _in.readByte();
    //     return (offsetByte == 127 ? ZoneOffset.ofTotalSeconds(_in.readInt())
    //             : ZoneOffset.ofTotalSeconds(offsetByte * 900));
    // }

}
