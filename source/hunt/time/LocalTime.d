
module hunt.time.LocalTime;

import hunt.time.temporal.ChronoField;
import hunt.time.temporal.ChronoUnit;

import hunt.io.DataInput;
import hunt.io.DataOutput;
import hunt.lang.exception;
import hunt.io.common;
import hunt.time.format.DateTimeFormatter;
import hunt.time.format.DateTimeParseException;
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
import hunt.time.Instant;
import hunt.time.LocalDateTime;
import hunt.time.LocalDate;
import hunt.time.OffsetTime;
import hunt.time.ZoneOffset;
import hunt.time.DateTimeException;
import hunt.lang;
import hunt.util.Comparator;
import hunt.string.StringBuilder;
import hunt.time.Ser;
import hunt.time.Duration;
import std.conv;
import hunt.string.common;
import hunt.time.util.QueryHelper;
import hunt.time.util.common;
/**
 * A time without a time-zone _in the ISO-8601 calendar system,
 * such as {@code 10:15:30}.
 * !(p)
 * {@code LocalTime} is an immutable date-time object that represents a time,
 * often viewed as hour-minute-second.
 * Time is represented to nanosecond precision.
 * For example, the value "13:45.30.123456789" can be stored _in a {@code LocalTime}.
 * !(p)
 * This class does not store or represent a date or time-zone.
 * Instead, it is a description of the local time as seen on a wall clock.
 * It cannot represent an instant on the time-line without additional information
 * such as an offset or time-zone.
 * !(p)
 * The ISO-8601 calendar system is the modern civil calendar system used today
 * _in most of the world. This API assumes that all calendar systems use the same
 * representation, this class, for time-of-day.
 *
 * !(p)
 * This is a <a href="{@docRoot}/java.base/java/lang/doc-files/ValueBased.html">value-based</a>
 * class; use of identity-sensitive operations (including reference equality
 * ({@code ==}), identity hash code, or synchronization) on instances of
 * {@code LocalTime} may have unpredictable results and should be avoided.
 * The {@code equals} method should be used for comparisons.
 *
 * @implSpec
 * This class is immutable and thread-safe.
 *
 * @since 1.8
 */
public final class LocalTime
        : Temporal, TemporalAdjuster, Comparable!(LocalTime), Serializable {

    /**
     * The minimum supported {@code LocalTime}, '00:00'.
     * This is the time of midnight at the start of the day.
     */
    //public __gshared LocalTime MIN;
    /**
     * The maximum supported {@code LocalTime}, '23:59:59.999999999'.
     * This is the time just before midnight at the end of the day.
     */
    //public __gshared LocalTime MAX;
    /**
     * The time of midnight at the start of the day, '00:00'.
     */
    //public __gshared LocalTime MIDNIGHT;
    /**
     * The time of noon _in the middle of the day, '12:00'.
     */
    //public __gshared LocalTime NOON;
    /**
     * Constants for the local time of each hour.
     */
    __gshared LocalTime[] _HOURS;
    public static LocalTime[] HOURS()
    {
        if(_HOURS.length != 24)
        {
            _HOURS = new LocalTime[24];
            for(int i = 0; i < HOURS.length; i++) {
                HOURS[i] = new LocalTime(i, 0, 0, 0);
            }   
        }
        return _HOURS;
    }
    // shared static this(){
        // for(int i = 0; i < HOURS.length; i++) {
        //     HOURS[i] = new LocalTime(i, 0, 0, 0);
        // }
        // MIDNIGHT = HOURS[0];
        mixin(MakeGlobalVar!(LocalTime)("MIDNIGHT",`HOURS[0]`));
        // NOON = HOURS[12];
        mixin(MakeGlobalVar!(LocalTime)("NOON",`HOURS[12]`));

        // MIN = HOURS[0];
        mixin(MakeGlobalVar!(LocalTime)("MIN",`HOURS[0]`));

        // MAX = new LocalTime(23, 59, 59, 999_999_999);
        mixin(MakeGlobalVar!(LocalTime)("MAX",`new LocalTime(23, 59, 59, 999_999_999)`));

    // }

    /**
     * Hours per day.
     */
    enum int HOURS_PER_DAY = 24;
    /**
     * Minutes per hour.
     */
    enum int MINUTES_PER_HOUR = 60;
    /**
     * Minutes per day.
     */
    enum int MINUTES_PER_DAY = MINUTES_PER_HOUR * HOURS_PER_DAY;
    /**
     * Seconds per minute.
     */
    enum int SECONDS_PER_MINUTE = 60;
    /**
     * Seconds per hour.
     */
    enum int SECONDS_PER_HOUR = SECONDS_PER_MINUTE * MINUTES_PER_HOUR;
    /**
     * Seconds per day.
     */
    enum int SECONDS_PER_DAY = SECONDS_PER_HOUR * HOURS_PER_DAY;
    /**
     * Milliseconds per day.
     */
    enum long MILLIS_PER_DAY = SECONDS_PER_DAY * 1000L;
    /**
     * Microseconds per day.
     */
    enum long MICROS_PER_DAY = SECONDS_PER_DAY * 1000_000L;
    /**
     * Nanos per millisecond.
     */
    enum long NANOS_PER_MILLI = 1000_000L;
    /**
     * Nanos per second.
     */
    enum long NANOS_PER_SECOND =  1000_000_000L;
    /**
     * Nanos per minute.
     */
    enum long NANOS_PER_MINUTE = NANOS_PER_SECOND * SECONDS_PER_MINUTE;
    /**
     * Nanos per hour.
     */
    enum long NANOS_PER_HOUR = NANOS_PER_MINUTE * MINUTES_PER_HOUR;
    /**
     * Nanos per day.
     */
    enum long NANOS_PER_DAY = NANOS_PER_HOUR * HOURS_PER_DAY;

    /**
     * The hour.
     */
    private  byte hour;
    /**
     * The minute.
     */
    private  byte minute;
    /**
     * The second.
     */
    private  byte second;
    /**
     * The nanosecond.
     */
    private  int nano;

    //-----------------------------------------------------------------------
    /**
     * Obtains the current time from the system clock _in the default time-zone.
     * !(p)
     * This will query the {@link Clock#systemDefaultZone() system clock} _in the default
     * time-zone to obtain the current time.
     * !(p)
     * Using this method will prevent the ability to use an alternate clock for testing
     * because the clock is hard-coded.
     *
     * @return the current time using the system clock and default time-zone, not null
     */
    public static LocalTime now() {
        return now(Clock.systemDefaultZone());
    }

    /**
     * Obtains the current time from the system clock _in the specified time-zone.
     * !(p)
     * This will query the {@link Clock#system(ZoneId) system clock} to obtain the current time.
     * Specifying the time-zone avoids dependence on the default time-zone.
     * !(p)
     * Using this method will prevent the ability to use an alternate clock for testing
     * because the clock is hard-coded.
     *
     * @param zone  the zone ID to use, not null
     * @return the current time using the system clock, not null
     */
    public static LocalTime now(ZoneId zone) {
        return now(Clock.system(zone));
    }

    /**
     * Obtains the current time from the specified clock.
     * !(p)
     * This will query the specified clock to obtain the current time.
     * Using this method allows the use of an alternate clock for testing.
     * The alternate clock may be introduced using {@link Clock dependency injection}.
     *
     * @param clock  the clock to use, not null
     * @return the current time, not null
     */
    public static LocalTime now(Clock clock) {
        assert(clock, "clock");
        Instant now = clock.instant();  // called once
        return ofInstant(now, clock.getZone());
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code LocalTime} from an hour and minute.
     * !(p)
     * This returns a {@code LocalTime} with the specified hour and minute.
     * The second and nanosecond fields will be set to zero.
     *
     * @param hour  the hour-of-day to represent, from 0 to 23
     * @param minute  the minute-of-hour to represent, from 0 to 59
     * @return the local time, not null
     * @throws DateTimeException if the value of any field is _out of range
     */
    public static LocalTime of(int hour, int minute) {
        ChronoField.HOUR_OF_DAY.checkValidValue(hour);
        if (minute == 0) {
            return HOURS[hour];  // for performance
        }
        ChronoField.MINUTE_OF_HOUR.checkValidValue(minute);
        return new LocalTime(hour, minute, 0, 0);
    }

    /**
     * Obtains an instance of {@code LocalTime} from an hour, minute and second.
     * !(p)
     * This returns a {@code LocalTime} with the specified hour, minute and second.
     * The nanosecond field will be set to zero.
     *
     * @param hour  the hour-of-day to represent, from 0 to 23
     * @param minute  the minute-of-hour to represent, from 0 to 59
     * @param second  the second-of-minute to represent, from 0 to 59
     * @return the local time, not null
     * @throws DateTimeException if the value of any field is _out of range
     */
    public static LocalTime of(int hour, int minute, int second) {
        ChronoField.HOUR_OF_DAY.checkValidValue(hour);
        if ((minute | second) == 0) {
            return HOURS[hour];  // for performance
        }
        ChronoField.MINUTE_OF_HOUR.checkValidValue(minute);
        ChronoField.SECOND_OF_MINUTE.checkValidValue(second);
        return new LocalTime(hour, minute, second, 0);
    }

    /**
     * Obtains an instance of {@code LocalTime} from an hour, minute, second and nanosecond.
     * !(p)
     * This returns a {@code LocalTime} with the specified hour, minute, second and nanosecond.
     *
     * @param hour  the hour-of-day to represent, from 0 to 23
     * @param minute  the minute-of-hour to represent, from 0 to 59
     * @param second  the second-of-minute to represent, from 0 to 59
     * @param nanoOfSecond  the nano-of-second to represent, from 0 to 999,999,999
     * @return the local time, not null
     * @throws DateTimeException if the value of any field is _out of range
     */
    public static LocalTime of(int hour, int minute, int second, int nanoOfSecond) {
        ChronoField.HOUR_OF_DAY.checkValidValue(hour);
        ChronoField.MINUTE_OF_HOUR.checkValidValue(minute);
        ChronoField.SECOND_OF_MINUTE.checkValidValue(second);
        ChronoField.NANO_OF_SECOND.checkValidValue(nanoOfSecond);
        return create(hour, minute, second, nanoOfSecond);
    }

    /**
     * Obtains an instance of {@code LocalTime} from an {@code Instant} and zone ID.
     * !(p)
     * This creates a local time based on the specified instant.
     * First, the offset from UTC/Greenwich is obtained using the zone ID and instant,
     * which is simple as there is only one valid offset for each instant.
     * Then, the instant and offset are used to calculate the local time.
     *
     * @param instant  the instant to create the time from, not null
     * @param zone  the time-zone, which may be an offset, not null
     * @return the local time, not null
     * @since 9
     */
    public static LocalTime ofInstant(Instant instant, ZoneId zone) {
        assert(instant, "instant");
        assert(zone, "zone");
        ZoneOffset offset = zone.getRules().getOffset(instant);
        long localSecond = instant.getEpochSecond() + offset.getTotalSeconds();
        int secsOfDay = Math.floorMod(localSecond, SECONDS_PER_DAY);
        import hunt.logging;
        import std.string;
        version(HUNT_DEBUG) trace("--- > (%s , %s , %s)".format(localSecond,secsOfDay,offset.getId()));
        return ofNanoOfDay(secsOfDay * NANOS_PER_SECOND + instant.getNano());
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code LocalTime} from a second-of-day value.
     * !(p)
     * This returns a {@code LocalTime} with the specified second-of-day.
     * The nanosecond field will be set to zero.
     *
     * @param secondOfDay  the second-of-day, from {@code 0} to {@code 24 * 60 * 60 - 1}
     * @return the local time, not null
     * @throws DateTimeException if the second-of-day value is invalid
     */
    public static LocalTime ofSecondOfDay(long secondOfDay) {
        ChronoField.SECOND_OF_DAY.checkValidValue(secondOfDay);
        int hours = cast(int) (secondOfDay / LocalTime.SECONDS_PER_HOUR);
        secondOfDay -= hours * LocalTime.SECONDS_PER_HOUR;
        int minutes = cast(int) (secondOfDay / LocalTime.SECONDS_PER_MINUTE);
        secondOfDay -= minutes * LocalTime.SECONDS_PER_MINUTE;
        return create(hours, minutes, cast(int) secondOfDay, 0);
    }

    /**
     * Obtains an instance of {@code LocalTime} from a nanos-of-day value.
     * !(p)
     * This returns a {@code LocalTime} with the specified nanosecond-of-day.
     *
     * @param nanoOfDay  the nano of day, from {@code 0} to {@code 24 * 60 * 60 * 1,000,000,000 - 1}
     * @return the local time, not null
     * @throws DateTimeException if the nanos of day value is invalid
     */
    public static LocalTime ofNanoOfDay(long nanoOfDay) {
        ChronoField.NANO_OF_DAY.checkValidValue(nanoOfDay);
        int hours = cast(int) (nanoOfDay / LocalTime.NANOS_PER_HOUR);
        nanoOfDay -= hours * LocalTime.NANOS_PER_HOUR;
        int minutes = cast(int) (nanoOfDay / LocalTime.NANOS_PER_MINUTE);
        nanoOfDay -= minutes * LocalTime.NANOS_PER_MINUTE;
        int seconds = cast(int) (nanoOfDay / LocalTime.NANOS_PER_SECOND);
        nanoOfDay -= seconds * LocalTime.NANOS_PER_SECOND;
        import hunt.logging;
        import std.string;
        // version(HUNT_DEBUG) logDebug("--- > (%s ,%s , %s , %s , %s)".format(nanoOfDay,hours,minutes,seconds,nanoOfDay));
        return create(hours, minutes, seconds, cast(int) nanoOfDay);
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code LocalTime} from a temporal object.
     * !(p)
     * This obtains a local time based on the specified temporal.
     * A {@code TemporalAccessor} represents an arbitrary set of date and time information,
     * which this factory converts to an instance of {@code LocalTime}.
     * !(p)
     * The conversion uses the {@link TemporalQueries#localTime()} query, which relies
     * on extracting the {@link ChronoField#NANO_OF_DAY NANO_OF_DAY} field.
     * !(p)
     * This method matches the signature of the functional interface {@link TemporalQuery}
     * allowing it to be used as a query via method reference, {@code LocalTime.from}.
     *
     * @param temporal  the temporal object to convert, not null
     * @return the local time, not null
     * @throws DateTimeException if unable to convert to a {@code LocalTime}
     */
    public static LocalTime from(TemporalAccessor temporal) {
        assert(temporal, "temporal");
        LocalTime time = QueryHelper.query!LocalTime(temporal , TemporalQueries.localTime());
        if (time is null) {
            throw new DateTimeException("Unable to obtain LocalTime from TemporalAccessor: " ~
                    typeid(temporal).name ~ " of type " ~ typeid(temporal).stringof);
        }
        return time;
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code LocalTime} from a text string such as {@code 10:15}.
     * !(p)
     * The string must represent a valid time and is parsed using
     * {@link hunt.time.format.DateTimeFormatter#ISO_LOCAL_TIME}.
     *
     * @param text  the text to parse such as "10:15:30", not null
     * @return the parsed local time, not null
     * @throws DateTimeParseException if the text cannot be parsed
     */
    public static LocalTime parse(string text) {
        return parse(text, DateTimeFormatter.ISO_LOCAL_TIME);
    }

    /**
     * Obtains an instance of {@code LocalTime} from a text string using a specific formatter.
     * !(p)
     * The text is parsed using the formatter, returning a time.
     *
     * @param text  the text to parse, not null
     * @param formatter  the formatter to use, not null
     * @return the parsed local time, not null
     * @throws DateTimeParseException if the text cannot be parsed
     */
    public static LocalTime parse(string text, DateTimeFormatter formatter) {
        assert(formatter, "formatter");
        return formatter.parse(text, new class TemporalQuery!LocalTime{
            LocalTime queryFrom(TemporalAccessor temporal)
            {
                assert(temporal, "temporal");
                LocalTime time =QueryHelper.query!LocalTime(temporal , TemporalQueries.localTime());
                if (time is null) {
                    throw new DateTimeException("Unable to obtain LocalTime from TemporalAccessor: " ~
                            typeid(temporal).name ~ " of type " ~ typeid(temporal).stringof);
                }
                return time;
            }
        });
    }

    //-----------------------------------------------------------------------
    /**
     * Creates a local time from the hour, minute, second and nanosecond fields.
     * !(p)
     * This factory may return a cached value, but applications must not rely on this.
     *
     * @param hour  the hour-of-day to represent, validated from 0 to 23
     * @param minute  the minute-of-hour to represent, validated from 0 to 59
     * @param second  the second-of-minute to represent, validated from 0 to 59
     * @param nanoOfSecond  the nano-of-second to represent, validated from 0 to 999,999,999
     * @return the local time, not null
     */
    private static LocalTime create(int hour, int minute, int second, int nanoOfSecond) {
        if ((minute | second | nanoOfSecond) == 0) {
            return HOURS[hour];
        }
        return new LocalTime(hour, minute, second, nanoOfSecond);
    }

    /**
     * Constructor, previously validated.
     *
     * @param hour  the hour-of-day to represent, validated from 0 to 23
     * @param minute  the minute-of-hour to represent, validated from 0 to 59
     * @param second  the second-of-minute to represent, validated from 0 to 59
     * @param nanoOfSecond  the nano-of-second to represent, validated from 0 to 999,999,999
     */
    this(int hour, int minute, int second, int nanoOfSecond) {
        this.hour = cast(byte) hour;
        this.minute = cast(byte) minute;
        this.second = cast(byte) second;
        this.nano = nanoOfSecond;
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if the specified field is supported.
     * !(p)
     * This checks if this time can be queried for the specified field.
     * If false, then calling the {@link #range(TemporalField) range},
     * {@link #get(TemporalField) get} and {@link #_with(TemporalField, long)}
     * methods will throw an exception.
     * !(p)
     * If the field is a {@link ChronoField} then the query is implemented here.
     * The supported fields are:
     * !(ul)
     * !(li){@code NANO_OF_SECOND}
     * !(li){@code NANO_OF_DAY}
     * !(li){@code MICRO_OF_SECOND}
     * !(li){@code MICRO_OF_DAY}
     * !(li){@code MILLI_OF_SECOND}
     * !(li){@code MILLI_OF_DAY}
     * !(li){@code SECOND_OF_MINUTE}
     * !(li){@code SECOND_OF_DAY}
     * !(li){@code MINUTE_OF_HOUR}
     * !(li){@code MINUTE_OF_DAY}
     * !(li){@code HOUR_OF_AMPM}
     * !(li){@code CLOCK_HOUR_OF_AMPM}
     * !(li){@code HOUR_OF_DAY}
     * !(li){@code CLOCK_HOUR_OF_DAY}
     * !(li){@code AMPM_OF_DAY}
     * </ul>
     * All other {@code ChronoField} instances will return false.
     * !(p)
     * If the field is not a {@code ChronoField}, then the result of this method
     * is obtained by invoking {@code TemporalField.isSupportedBy(TemporalAccessor)}
     * passing {@code this} as the argument.
     * Whether the field is supported is determined by the field.
     *
     * @param field  the field to check, null returns false
     * @return true if the field is supported on this time, false if not
     */
    override
    public bool isSupported(TemporalField field) {
        if (cast(ChronoField)(field) !is null) {
            return field.isTimeBased();
        }
        return field !is null && field.isSupportedBy(this);
    }

    /**
     * Checks if the specified unit is supported.
     * !(p)
     * This checks if the specified unit can be added to, or subtracted from, this time.
     * If false, then calling the {@link #plus(long, TemporalUnit)} and
     * {@link #minus(long, TemporalUnit) minus} methods will throw an exception.
     * !(p)
     * If the unit is a {@link ChronoUnit} then the query is implemented here.
     * The supported units are:
     * !(ul)
     * !(li){@code NANOS}
     * !(li){@code MICROS}
     * !(li){@code MILLIS}
     * !(li){@code SECONDS}
     * !(li){@code MINUTES}
     * !(li){@code HOURS}
     * !(li){@code HALF_DAYS}
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
    override  // override for Javadoc
    public bool isSupported(TemporalUnit unit) {
        if (cast(ChronoUnit)(unit) !is null) {
            return unit.isTimeBased();
        }
        return unit !is null && unit.isSupportedBy(this);
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the range of valid values for the specified field.
     * !(p)
     * The range object expresses the minimum and maximum valid values for a field.
     * This time is used to enhance the accuracy of the returned range.
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
    public ValueRange range(TemporalField field) {
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
     * Gets the value of the specified field from this time as an {@code int}.
     * !(p)
     * This queries this time for the value of the specified field.
     * The returned value will always be within the valid range of values for the field.
     * If it is not possible to return the value, because the field is not supported
     * or for some other reason, an exception is thrown.
     * !(p)
     * If the field is a {@link ChronoField} then the query is implemented here.
     * The {@link #isSupported(TemporalField) supported fields} will return valid
     * values based on this time, except {@code NANO_OF_DAY} and {@code MICRO_OF_DAY}
     * which are too large to fit _in an {@code int} and throw an {@code UnsupportedTemporalTypeException}.
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
    public int get(TemporalField field) {
        if (cast(ChronoField)(field) !is null) {
            return get0(field);
        }
        return /* Temporal. super.*/super_get(field);
    }
     int super_get(TemporalField field) {
        ValueRange range = range(field);
        if (range.isIntValue() == false) {
            throw new UnsupportedTemporalTypeException("Invalid field " ~ typeid(field).name ~ " for get() method, use getLong() instead");
        }
        long value = getLong(field);
        if (range.isValidValue(value) == false) {
            throw new DateTimeException("Invalid value for " ~ typeid(field).name ~ " (valid values " ~ range.toString ~ "): " ~ value.to!string);
        }
        return cast(int) value;
    }
    /**
     * Gets the value of the specified field from this time as a {@code long}.
     * !(p)
     * This queries this time for the value of the specified field.
     * If it is not possible to return the value, because the field is not supported
     * or for some other reason, an exception is thrown.
     * !(p)
     * If the field is a {@link ChronoField} then the query is implemented here.
     * The {@link #isSupported(TemporalField) supported fields} will return valid
     * values based on this time.
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
            if (field == ChronoField.NANO_OF_DAY) {
                return toNanoOfDay();
            }
            if (field == ChronoField.MICRO_OF_DAY) {
                return toNanoOfDay() / 1000;
            }
            return get0(field);
        }
        return field.getFrom(this);
    }

    private int get0(TemporalField field) {
        auto f = cast(ChronoField) field;
        {
            if(f == ChronoField.NANO_OF_SECOND) return nano;
            if(f == ChronoField.NANO_OF_DAY) throw new UnsupportedTemporalTypeException("Invalid field 'NanoOfDay' for get() method, use getLong() instead");
            if(f == ChronoField.MICRO_OF_SECOND) return nano / 1000;
            if(f == ChronoField.MICRO_OF_DAY) throw new UnsupportedTemporalTypeException("Invalid field 'MicroOfDay' for get() method, use getLong() instead");
            if(f == ChronoField.MILLI_OF_SECOND) return nano / 1000_000;
            if(f == ChronoField.MILLI_OF_DAY) return cast(int) (toNanoOfDay() / 1000_000);
            if(f == ChronoField.SECOND_OF_MINUTE) return second;
            if(f == ChronoField.SECOND_OF_DAY) return toSecondOfDay();
            if(f == ChronoField.MINUTE_OF_HOUR) return minute;
            if(f == ChronoField.MINUTE_OF_DAY) return hour * 60 + minute;
            if(f == ChronoField.HOUR_OF_AMPM) return hour % 12;
            if(f == ChronoField.CLOCK_HOUR_OF_AMPM) {int ham = hour % 12; return (ham % 12 == 0 ? 12 : ham);}
            if(f == ChronoField.HOUR_OF_DAY) return hour;
            if(f == ChronoField.CLOCK_HOUR_OF_DAY) return (hour == 0 ? 24 : hour);
            if(f == ChronoField.AMPM_OF_DAY) return hour / 12;
        }
        throw new UnsupportedTemporalTypeException("Unsupported field: " ~ typeid(field).name);
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the hour-of-day field.
     *
     * @return the hour-of-day, from 0 to 23
     */
    public int getHour() {
        return hour;
    }

    /**
     * Gets the minute-of-hour field.
     *
     * @return the minute-of-hour, from 0 to 59
     */
    public int getMinute() {
        return minute;
    }

    /**
     * Gets the second-of-minute field.
     *
     * @return the second-of-minute, from 0 to 59
     */
    public int getSecond() {
        return second;
    }

    int getMillisecond() {
        return cast(int)nano/NANOS_PER_MILLI;
    }

    /**
     * Gets the nano-of-second field.
     *
     * @return the nano-of-second, from 0 to 999,999,999
     */
    public int getNano() {
        return nano;
    }

    //-----------------------------------------------------------------------
    /**
     * Returns an adjusted copy of this time.
     * !(p)
     * This returns a {@code LocalTime}, based on this one, with the time adjusted.
     * The adjustment takes place using the specified adjuster strategy object.
     * Read the documentation of the adjuster to understand what adjustment will be made.
     * !(p)
     * A simple adjuster might simply set the one of the fields, such as the hour field.
     * A more complex adjuster might set the time to the last hour of the day.
     * !(p)
     * The result of this method is obtained by invoking the
     * {@link TemporalAdjuster#adjustInto(Temporal)} method on the
     * specified adjuster passing {@code this} as the argument.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param adjuster the adjuster to use, not null
     * @return a {@code LocalTime} based on {@code this} with the adjustment made, not null
     * @throws DateTimeException if the adjustment cannot be made
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    public LocalTime _with(TemporalAdjuster adjuster) {
        // optimizations
        if (cast(LocalTime)(adjuster) !is null) {
            return cast(LocalTime) adjuster;
        }
        return cast(LocalTime) adjuster.adjustInto(this);
    }

    /**
     * Returns a copy of this time with the specified field set to a new value.
     * !(p)
     * This returns a {@code LocalTime}, based on this one, with the value
     * for the specified field changed.
     * This can be used to change any supported field, such as the hour, minute or second.
     * If it is not possible to set the value, because the field is not supported or for
     * some other reason, an exception is thrown.
     * !(p)
     * If the field is a {@link ChronoField} then the adjustment is implemented here.
     * The supported fields behave as follows:
     * !(ul)
     * !(li){@code NANO_OF_SECOND} -
     *  Returns a {@code LocalTime} with the specified nano-of-second.
     *  The hour, minute and second will be unchanged.
     * !(li){@code NANO_OF_DAY} -
     *  Returns a {@code LocalTime} with the specified nano-of-day.
     *  This completely replaces the time and is equivalent to {@link #ofNanoOfDay(long)}.
     * !(li){@code MICRO_OF_SECOND} -
     *  Returns a {@code LocalTime} with the nano-of-second replaced by the specified
     *  micro-of-second multiplied by 1,000.
     *  The hour, minute and second will be unchanged.
     * !(li){@code MICRO_OF_DAY} -
     *  Returns a {@code LocalTime} with the specified micro-of-day.
     *  This completely replaces the time and is equivalent to using {@link #ofNanoOfDay(long)}
     *  with the micro-of-day multiplied by 1,000.
     * !(li){@code MILLI_OF_SECOND} -
     *  Returns a {@code LocalTime} with the nano-of-second replaced by the specified
     *  milli-of-second multiplied by 1,000,000.
     *  The hour, minute and second will be unchanged.
     * !(li){@code MILLI_OF_DAY} -
     *  Returns a {@code LocalTime} with the specified milli-of-day.
     *  This completely replaces the time and is equivalent to using {@link #ofNanoOfDay(long)}
     *  with the milli-of-day multiplied by 1,000,000.
     * !(li){@code SECOND_OF_MINUTE} -
     *  Returns a {@code LocalTime} with the specified second-of-minute.
     *  The hour, minute and nano-of-second will be unchanged.
     * !(li){@code SECOND_OF_DAY} -
     *  Returns a {@code LocalTime} with the specified second-of-day.
     *  The nano-of-second will be unchanged.
     * !(li){@code MINUTE_OF_HOUR} -
     *  Returns a {@code LocalTime} with the specified minute-of-hour.
     *  The hour, second-of-minute and nano-of-second will be unchanged.
     * !(li){@code MINUTE_OF_DAY} -
     *  Returns a {@code LocalTime} with the specified minute-of-day.
     *  The second-of-minute and nano-of-second will be unchanged.
     * !(li){@code HOUR_OF_AMPM} -
     *  Returns a {@code LocalTime} with the specified hour-of-am-pm.
     *  The AM/PM, minute-of-hour, second-of-minute and nano-of-second will be unchanged.
     * !(li){@code CLOCK_HOUR_OF_AMPM} -
     *  Returns a {@code LocalTime} with the specified clock-hour-of-am-pm.
     *  The AM/PM, minute-of-hour, second-of-minute and nano-of-second will be unchanged.
     * !(li){@code HOUR_OF_DAY} -
     *  Returns a {@code LocalTime} with the specified hour-of-day.
     *  The minute-of-hour, second-of-minute and nano-of-second will be unchanged.
     * !(li){@code CLOCK_HOUR_OF_DAY} -
     *  Returns a {@code LocalTime} with the specified clock-hour-of-day.
     *  The minute-of-hour, second-of-minute and nano-of-second will be unchanged.
     * !(li){@code AMPM_OF_DAY} -
     *  Returns a {@code LocalTime} with the specified AM/PM.
     *  The hour-of-am-pm, minute-of-hour, second-of-minute and nano-of-second will be unchanged.
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
     * @return a {@code LocalTime} based on {@code this} with the specified field set, not null
     * @throws DateTimeException if the field cannot be set
     * @throws UnsupportedTemporalTypeException if the field is not supported
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    public LocalTime _with(TemporalField field, long newValue) {
        if (cast(ChronoField)(field) !is null) {
            ChronoField f = cast(ChronoField) field;
            f.checkValidValue(newValue);
            {
                if(f == ChronoField.NANO_OF_SECOND) return withNano(cast(int) newValue);
                if(f == ChronoField.NANO_OF_DAY) return LocalTime.ofNanoOfDay(newValue);
                if(f == ChronoField.MICRO_OF_SECOND) return withNano(cast(int) newValue * 1000);
                if(f == ChronoField.MICRO_OF_DAY) return LocalTime.ofNanoOfDay(newValue * 1000);
                if(f == ChronoField.MILLI_OF_SECOND) return withNano(cast(int) newValue * 1000_000);
                if(f == ChronoField.MILLI_OF_DAY) return LocalTime.ofNanoOfDay(newValue * 1000_000);
                if(f == ChronoField.SECOND_OF_MINUTE) return withSecond(cast(int) newValue);
                if(f == ChronoField.SECOND_OF_DAY) return plusSeconds(newValue - toSecondOfDay());
                if(f == ChronoField.MINUTE_OF_HOUR) return withMinute(cast(int) newValue);
                if(f == ChronoField.MINUTE_OF_DAY) return plusMinutes(newValue - (hour * 60 + minute));
                if(f == ChronoField.HOUR_OF_AMPM) return plusHours(newValue - (hour % 12));
                if(f == ChronoField.CLOCK_HOUR_OF_AMPM) return plusHours((newValue == 12 ? 0 : newValue) - (hour % 12));
                if(f == ChronoField.HOUR_OF_DAY) return withHour(cast(int) newValue);
                if(f == ChronoField.CLOCK_HOUR_OF_DAY) return withHour(cast(int) (newValue == 24 ? 0 : newValue));
                if(f == ChronoField.AMPM_OF_DAY) return plusHours((newValue - (hour / 12)) * 12);
            }
            throw new UnsupportedTemporalTypeException("Unsupported field: " ~ f.toString);
        }
        return cast(LocalTime)(field.adjustInto(this, newValue));
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this {@code LocalTime} with the hour-of-day altered.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param hour  the hour-of-day to set _in the result, from 0 to 23
     * @return a {@code LocalTime} based on this time with the requested hour, not null
     * @throws DateTimeException if the hour value is invalid
     */
    public LocalTime withHour(int hour) {
        if (this.hour == hour) {
            return this;
        }
        ChronoField.HOUR_OF_DAY.checkValidValue(hour);
        return create(hour, minute, second, nano);
    }

    /**
     * Returns a copy of this {@code LocalTime} with the minute-of-hour altered.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param minute  the minute-of-hour to set _in the result, from 0 to 59
     * @return a {@code LocalTime} based on this time with the requested minute, not null
     * @throws DateTimeException if the minute value is invalid
     */
    public LocalTime withMinute(int minute) {
        if (this.minute == minute) {
            return this;
        }
        ChronoField.MINUTE_OF_HOUR.checkValidValue(minute);
        return create(hour, minute, second, nano);
    }

    /**
     * Returns a copy of this {@code LocalTime} with the second-of-minute altered.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param second  the second-of-minute to set _in the result, from 0 to 59
     * @return a {@code LocalTime} based on this time with the requested second, not null
     * @throws DateTimeException if the second value is invalid
     */
    public LocalTime withSecond(int second) {
        if (this.second == second) {
            return this;
        }
        ChronoField.SECOND_OF_MINUTE.checkValidValue(second);
        return create(hour, minute, second, nano);
    }

    /**
     * Returns a copy of this {@code LocalTime} with the nano-of-second altered.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param nanoOfSecond  the nano-of-second to set _in the result, from 0 to 999,999,999
     * @return a {@code LocalTime} based on this time with the requested nanosecond, not null
     * @throws DateTimeException if the nanos value is invalid
     */
    public LocalTime withNano(int nanoOfSecond) {
        if (this.nano == nanoOfSecond) {
            return this;
        }
        ChronoField.NANO_OF_SECOND.checkValidValue(nanoOfSecond);
        return create(hour, minute, second, nanoOfSecond);
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this {@code LocalTime} with the time truncated.
     * !(p)
     * Truncation returns a copy of the original time with fields
     * smaller than the specified unit set to zero.
     * For example, truncating with the {@link ChronoUnit#MINUTES minutes} unit
     * will set the second-of-minute and nano-of-second field to zero.
     * !(p)
     * The unit must have a {@linkplain TemporalUnit#getDuration() duration}
     * that divides into the length of a standard day without remainder.
     * This includes all supplied time units on {@link ChronoUnit} and
     * {@link ChronoUnit#DAYS DAYS}. Other units throw an exception.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param unit  the unit to truncate to, not null
     * @return a {@code LocalTime} based on this time with the time truncated, not null
     * @throws DateTimeException if unable to truncate
     * @throws UnsupportedTemporalTypeException if the unit is not supported
     */
    public LocalTime truncatedTo(TemporalUnit unit) {
        if (unit == ChronoUnit.NANOS) {
            return this;
        }
        Duration unitDur = unit.getDuration();
        if (unitDur.getSeconds() > SECONDS_PER_DAY) {
            throw new UnsupportedTemporalTypeException("Unit is too large to be used for truncation");
        }
        long dur = unitDur.toNanos();
        if ((NANOS_PER_DAY % dur) != 0) {
            throw new UnsupportedTemporalTypeException("Unit must divide into a standard day without remainder");
        }
        long nod = toNanoOfDay();
        return ofNanoOfDay((nod / dur) * dur);
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this time with the specified amount added.
     * !(p)
     * This returns a {@code LocalTime}, based on this one, with the specified amount added.
     * The amount is typically {@link Duration} but may be any other type implementing
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
     * @return a {@code LocalTime} based on this time with the addition made, not null
     * @throws DateTimeException if the addition cannot be made
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    public LocalTime plus(TemporalAmount amountToAdd) {
        return cast(LocalTime) amountToAdd.addTo(this);
    }

    /**
     * Returns a copy of this time with the specified amount added.
     * !(p)
     * This returns a {@code LocalTime}, based on this one, with the amount
     * _in terms of the unit added. If it is not possible to add the amount, because the
     * unit is not supported or for some other reason, an exception is thrown.
     * !(p)
     * If the field is a {@link ChronoUnit} then the addition is implemented here.
     * The supported fields behave as follows:
     * !(ul)
     * !(li){@code NANOS} -
     *  Returns a {@code LocalTime} with the specified number of nanoseconds added.
     *  This is equivalent to {@link #plusNanos(long)}.
     * !(li){@code MICROS} -
     *  Returns a {@code LocalTime} with the specified number of microseconds added.
     *  This is equivalent to {@link #plusNanos(long)} with the amount
     *  multiplied by 1,000.
     * !(li){@code MILLIS} -
     *  Returns a {@code LocalTime} with the specified number of milliseconds added.
     *  This is equivalent to {@link #plusNanos(long)} with the amount
     *  multiplied by 1,000,000.
     * !(li){@code SECONDS} -
     *  Returns a {@code LocalTime} with the specified number of seconds added.
     *  This is equivalent to {@link #plusSeconds(long)}.
     * !(li){@code MINUTES} -
     *  Returns a {@code LocalTime} with the specified number of minutes added.
     *  This is equivalent to {@link #plusMinutes(long)}.
     * !(li){@code HOURS} -
     *  Returns a {@code LocalTime} with the specified number of hours added.
     *  This is equivalent to {@link #plusHours(long)}.
     * !(li){@code HALF_DAYS} -
     *  Returns a {@code LocalTime} with the specified number of half-days added.
     *  This is equivalent to {@link #plusHours(long)} with the amount
     *  multiplied by 12.
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
     * @return a {@code LocalTime} based on this time with the specified amount added, not null
     * @throws DateTimeException if the addition cannot be made
     * @throws UnsupportedTemporalTypeException if the unit is not supported
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    public LocalTime plus(long amountToAdd, TemporalUnit unit) {
        if (cast(ChronoUnit)(unit) !is null) {
            auto f = cast(ChronoUnit) unit;
            {
                if( f == ChronoUnit.NANOS) return plusNanos(amountToAdd);
                if( f == ChronoUnit.MICROS) return plusNanos((amountToAdd % LocalTime.MICROS_PER_DAY) * 1000);
                if( f == ChronoUnit.MILLIS) return plusNanos((amountToAdd % LocalTime.MILLIS_PER_DAY) * 1000_000);
                if( f == ChronoUnit.SECONDS) return plusSeconds(amountToAdd);
                if( f == ChronoUnit.MINUTES) return plusMinutes(amountToAdd);
                if( f == ChronoUnit.HOURS) return plusHours(amountToAdd);
                if( f == ChronoUnit.HALF_DAYS) return plusHours((amountToAdd % 2) * 12);
            }
            throw new UnsupportedTemporalTypeException("Unsupported unit: " ~ f.toString);
        }
        return cast(LocalTime)(unit.addTo(this, amountToAdd));
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this {@code LocalTime} with the specified number of hours added.
     * !(p)
     * This adds the specified number of hours to this time, returning a new time.
     * The calculation wraps around midnight.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param hoursToAdd  the hours to add, may be negative
     * @return a {@code LocalTime} based on this time with the hours added, not null
     */
    public LocalTime plusHours(long hoursToAdd) {
        if (hoursToAdd == 0) {
            return this;
        }
        int newHour = (cast(int) (hoursToAdd % HOURS_PER_DAY) + hour + HOURS_PER_DAY) % HOURS_PER_DAY;
        return create(newHour, minute, second, nano);
    }

    /**
     * Returns a copy of this {@code LocalTime} with the specified number of minutes added.
     * !(p)
     * This adds the specified number of minutes to this time, returning a new time.
     * The calculation wraps around midnight.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param minutesToAdd  the minutes to add, may be negative
     * @return a {@code LocalTime} based on this time with the minutes added, not null
     */
    public LocalTime plusMinutes(long minutesToAdd) {
        if (minutesToAdd == 0) {
            return this;
        }
        int mofd = hour * MINUTES_PER_HOUR + minute;
        int newMofd = (cast(int) (minutesToAdd % MINUTES_PER_DAY) + mofd + MINUTES_PER_DAY) % MINUTES_PER_DAY;
        if (mofd == newMofd) {
            return this;
        }
        int newHour = newMofd / MINUTES_PER_HOUR;
        int newMinute = newMofd % MINUTES_PER_HOUR;
        return create(newHour, newMinute, second, nano);
    }

    /**
     * Returns a copy of this {@code LocalTime} with the specified number of seconds added.
     * !(p)
     * This adds the specified number of seconds to this time, returning a new time.
     * The calculation wraps around midnight.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param secondstoAdd  the seconds to add, may be negative
     * @return a {@code LocalTime} based on this time with the seconds added, not null
     */
    public LocalTime plusSeconds(long secondstoAdd) {
        if (secondstoAdd == 0) {
            return this;
        }
        int sofd = hour * SECONDS_PER_HOUR +
                    minute * SECONDS_PER_MINUTE + second;
        int newSofd = (cast(int) (secondstoAdd % SECONDS_PER_DAY) + sofd + SECONDS_PER_DAY) % SECONDS_PER_DAY;
        if (sofd == newSofd) {
            return this;
        }
        int newHour = newSofd / SECONDS_PER_HOUR;
        int newMinute = (newSofd / SECONDS_PER_MINUTE) % MINUTES_PER_HOUR;
        int newSecond = newSofd % SECONDS_PER_MINUTE;
        return create(newHour, newMinute, newSecond, nano);
    }

    /**
     * Returns a copy of this {@code LocalTime} with the specified number of nanoseconds added.
     * !(p)
     * This adds the specified number of nanoseconds to this time, returning a new time.
     * The calculation wraps around midnight.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param nanosToAdd  the nanos to add, may be negative
     * @return a {@code LocalTime} based on this time with the nanoseconds added, not null
     */
    public LocalTime plusNanos(long nanosToAdd) {
        if (nanosToAdd == 0) {
            return this;
        }
        long nofd = toNanoOfDay();
        long newNofd = ((nanosToAdd % NANOS_PER_DAY) + nofd + NANOS_PER_DAY) % NANOS_PER_DAY;
        if (nofd == newNofd) {
            return this;
        }
        int newHour = cast(int) (newNofd / NANOS_PER_HOUR);
        int newMinute = cast(int) ((newNofd / NANOS_PER_MINUTE) % MINUTES_PER_HOUR);
        int newSecond = cast(int) ((newNofd / NANOS_PER_SECOND) % SECONDS_PER_MINUTE);
        int newNano = cast(int) (newNofd % NANOS_PER_SECOND);
        return create(newHour, newMinute, newSecond, newNano);
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this time with the specified amount subtracted.
     * !(p)
     * This returns a {@code LocalTime}, based on this one, with the specified amount subtracted.
     * The amount is typically {@link Duration} but may be any other type implementing
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
     * @return a {@code LocalTime} based on this time with the subtraction made, not null
     * @throws DateTimeException if the subtraction cannot be made
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    public LocalTime minus(TemporalAmount amountToSubtract) {
        return cast(LocalTime) amountToSubtract.subtractFrom(this);
    }

    /**
     * Returns a copy of this time with the specified amount subtracted.
     * !(p)
     * This returns a {@code LocalTime}, based on this one, with the amount
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
     * @return a {@code LocalTime} based on this time with the specified amount subtracted, not null
     * @throws DateTimeException if the subtraction cannot be made
     * @throws UnsupportedTemporalTypeException if the unit is not supported
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    public LocalTime minus(long amountToSubtract, TemporalUnit unit) {
        return (amountToSubtract == Long.MIN_VALUE ? plus(Long.MAX_VALUE, unit).plus(1, unit) : plus(-amountToSubtract, unit));
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this {@code LocalTime} with the specified number of hours subtracted.
     * !(p)
     * This subtracts the specified number of hours from this time, returning a new time.
     * The calculation wraps around midnight.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param hoursToSubtract  the hours to subtract, may be negative
     * @return a {@code LocalTime} based on this time with the hours subtracted, not null
     */
    public LocalTime minusHours(long hoursToSubtract) {
        return plusHours(-(hoursToSubtract % HOURS_PER_DAY));
    }

    /**
     * Returns a copy of this {@code LocalTime} with the specified number of minutes subtracted.
     * !(p)
     * This subtracts the specified number of minutes from this time, returning a new time.
     * The calculation wraps around midnight.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param minutesToSubtract  the minutes to subtract, may be negative
     * @return a {@code LocalTime} based on this time with the minutes subtracted, not null
     */
    public LocalTime minusMinutes(long minutesToSubtract) {
        return plusMinutes(-(minutesToSubtract % MINUTES_PER_DAY));
    }

    /**
     * Returns a copy of this {@code LocalTime} with the specified number of seconds subtracted.
     * !(p)
     * This subtracts the specified number of seconds from this time, returning a new time.
     * The calculation wraps around midnight.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param secondsToSubtract  the seconds to subtract, may be negative
     * @return a {@code LocalTime} based on this time with the seconds subtracted, not null
     */
    public LocalTime minusSeconds(long secondsToSubtract) {
        return plusSeconds(-(secondsToSubtract % SECONDS_PER_DAY));
    }

    /**
     * Returns a copy of this {@code LocalTime} with the specified number of nanoseconds subtracted.
     * !(p)
     * This subtracts the specified number of nanoseconds from this time, returning a new time.
     * The calculation wraps around midnight.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param nanosToSubtract  the nanos to subtract, may be negative
     * @return a {@code LocalTime} based on this time with the nanoseconds subtracted, not null
     */
    public LocalTime minusNanos(long nanosToSubtract) {
        return plusNanos(-(nanosToSubtract % NANOS_PER_DAY));
    }

    //-----------------------------------------------------------------------
    /**
     * Queries this time using the specified query.
     * !(p)
     * This queries this time using the specified query strategy object.
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
        if (query == TemporalQueries.chronology() || query == TemporalQueries.zoneId() ||
                query == TemporalQueries.zone() || query == TemporalQueries.offset()) {
            return null;
        } else if (query == TemporalQueries.localTime()) {
            return cast(R) this;
        } else if (query == TemporalQueries.localDate()) {
            return null;
        } else if (query == TemporalQueries.precision()) {
            return cast(R) (ChronoUnit.NANOS);
        }
        // inline TemporalAccessor.super.query(query) as an optimization
        // non-JDK classes are not permitted to make this optimization
        return query.queryFrom(this);
    }

    /**
     * Adjusts the specified temporal object to have the same time as this object.
     * !(p)
     * This returns a temporal object of the same observable type as the input
     * with the time changed to be the same as this.
     * !(p)
     * The adjustment is equivalent to using {@link Temporal#_with(TemporalField, long)}
     * passing {@link ChronoField#NANO_OF_DAY} as the field.
     * !(p)
     * In most cases, it is clearer to reverse the calling pattern by using
     * {@link Temporal#_with(TemporalAdjuster)}:
     * !(pre)
     *   // these two lines are equivalent, but the second approach is recommended
     *   temporal = thisLocalTime.adjustInto(temporal);
     *   temporal = temporal._with(thisLocalTime);
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
        return temporal._with(ChronoField.NANO_OF_DAY, toNanoOfDay());
    }

    /**
     * Calculates the amount of time until another time _in terms of the specified unit.
     * !(p)
     * This calculates the amount of time between two {@code LocalTime}
     * objects _in terms of a single {@code TemporalUnit}.
     * The start and end points are {@code this} and the specified time.
     * The result will be negative if the end is before the start.
     * The {@code Temporal} passed to this method is converted to a
     * {@code LocalTime} using {@link #from(TemporalAccessor)}.
     * For example, the amount _in hours between two times can be calculated
     * using {@code startTime.until(endTime, HOURS)}.
     * !(p)
     * The calculation returns a whole number, representing the number of
     * complete units between the two times.
     * For example, the amount _in hours between 11:30 and 13:29 will only
     * be one hour as it is one minute short of two hours.
     * !(p)
     * There are two equivalent ways of using this method.
     * The first is to invoke this method.
     * The second is to use {@link TemporalUnit#between(Temporal, Temporal)}:
     * !(pre)
     *   // these two lines are equivalent
     *   amount = start.until(end, MINUTES);
     *   amount = MINUTES.between(start, end);
     * </pre>
     * The choice should be made based on which makes the code more readable.
     * !(p)
     * The calculation is implemented _in this method for {@link ChronoUnit}.
     * The units {@code NANOS}, {@code MICROS}, {@code MILLIS}, {@code SECONDS},
     * {@code MINUTES}, {@code HOURS} and {@code HALF_DAYS} are supported.
     * Other {@code ChronoUnit} values will throw an exception.
     * !(p)
     * If the unit is not a {@code ChronoUnit}, then the result of this method
     * is obtained by invoking {@code TemporalUnit.between(Temporal, Temporal)}
     * passing {@code this} as the first argument and the converted input temporal
     * as the second argument.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param endExclusive  the end time, exclusive, which is converted to a {@code LocalTime}, not null
     * @param unit  the unit to measure the amount _in, not null
     * @return the amount of time between this time and the end time
     * @throws DateTimeException if the amount cannot be calculated, or the end
     *  temporal cannot be converted to a {@code LocalTime}
     * @throws UnsupportedTemporalTypeException if the unit is not supported
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    public long until(Temporal endExclusive, TemporalUnit unit) {
        LocalTime end = LocalTime.from(endExclusive);
        if (cast(ChronoUnit)(unit) !is null) {
            long nanosUntil = end.toNanoOfDay() - toNanoOfDay();  // no overflow
            auto f = cast(ChronoUnit) unit;
            {
                if( f == ChronoUnit.NANOS) return nanosUntil;
                if( f == ChronoUnit.MICROS) return nanosUntil / 1000;
                if( f == ChronoUnit.MILLIS) return nanosUntil / 1000_000;
                if( f == ChronoUnit.SECONDS) return nanosUntil / NANOS_PER_SECOND;
                if( f == ChronoUnit.MINUTES) return nanosUntil / NANOS_PER_MINUTE;
                if( f == ChronoUnit.HOURS) return nanosUntil / NANOS_PER_HOUR;
                if( f == ChronoUnit.HALF_DAYS) return nanosUntil / (12 * NANOS_PER_HOUR);
            }
            throw new UnsupportedTemporalTypeException("Unsupported unit: " ~ f.toString);
        }
        return unit.between(this, end);
    }

    /**
     * Formats this time using the specified formatter.
     * !(p)
     * This time will be passed to the formatter to produce a string.
     *
     * @param formatter  the formatter to use, not null
     * @return the formatted time string, not null
     * @throws DateTimeException if an error occurs during printing
     */
    public string format(DateTimeFormatter formatter) {
        assert(formatter, "formatter");
        return formatter.format(this);
    }

    //-----------------------------------------------------------------------
    /**
     * Combines this time with a date to create a {@code LocalDateTime}.
     * !(p)
     * This returns a {@code LocalDateTime} formed from this time at the specified date.
     * All possible combinations of date and time are valid.
     *
     * @param date  the date to combine with, not null
     * @return the local date-time formed from this time and the specified date, not null
     */
    public LocalDateTime atDate(LocalDate date) {
        return LocalDateTime.of(date, this);
    }

    /**
     * Combines this time with an offset to create an {@code OffsetTime}.
     * !(p)
     * This returns an {@code OffsetTime} formed from this time at the specified offset.
     * All possible combinations of time and offset are valid.
     *
     * @param offset  the offset to combine with, not null
     * @return the offset time formed from this time and the specified offset, not null
     */
    public OffsetTime atOffset(ZoneOffset offset) {
        return OffsetTime.of(this, offset);
    }

    //-----------------------------------------------------------------------
    /**
     * Extracts the time as seconds of day,
     * from {@code 0} to {@code 24 * 60 * 60 - 1}.
     *
     * @return the second-of-day equivalent to this time
     */
    public int toSecondOfDay() {
        int total = hour * SECONDS_PER_HOUR;
        total += minute * SECONDS_PER_MINUTE;
        total += second;
        return total;
    }

    /**
     * Extracts the time as nanos of day,
     * from {@code 0} to {@code 24 * 60 * 60 * 1,000,000,000 - 1}.
     *
     * @return the nano of day equivalent to this time
     */
    public long toNanoOfDay() {
        long total = hour * NANOS_PER_HOUR;
        total += minute * NANOS_PER_MINUTE;
        total += second * NANOS_PER_SECOND;
        total += nano;
        return total;
    }

    /**
     * Converts this {@code LocalTime} to the number of seconds since the epoch
     * of 1970-01-01T00:00:00Z.
     * !(p)
     * This combines this local time with the specified date and
     * offset to calculate the epoch-second value, which is the
     * number of elapsed seconds from 1970-01-01T00:00:00Z.
     * Instants on the time-line after the epoch are positive, earlier
     * are negative.
     *
     * @param date the local date, not null
     * @param offset the zone offset, not null
     * @return the number of seconds since the epoch of 1970-01-01T00:00:00Z, may be negative
     * @since 9
     */
    public long toEpochSecond(LocalDate date, ZoneOffset offset) {
        assert(date, "date");
        assert(offset, "offset");
        long epochDay = date.toEpochDay();
        long secs = epochDay * 86400 + toSecondOfDay();
        secs -= offset.getTotalSeconds();
        return secs;
    }

    //-----------------------------------------------------------------------
    /**
     * Compares this time to another time.
     * !(p)
     * The comparison is based on the time-line position of the local times within a day.
     * It is "consistent with equals", as defined by {@link Comparable}.
     *
     * @param other  the other time to compare to, not null
     * @return the comparator value, negative if less, positive if greater
     */
    // override
    public int compareTo(LocalTime other) {
        int cmp = compare(hour, other.hour);
        if (cmp == 0) {
            cmp = compare(minute, other.minute);
            if (cmp == 0) {
                cmp = compare(second, other.second);
                if (cmp == 0) {
                    cmp = compare(nano, other.nano);
                }
            }
        }
        return cmp;
    }

    override
    public int opCmp(LocalTime other) {
        int cmp = compare(hour, other.hour);
        if (cmp == 0) {
            cmp = compare(minute, other.minute);
            if (cmp == 0) {
                cmp = compare(second, other.second);
                if (cmp == 0) {
                    cmp = compare(nano, other.nano);
                }
            }
        }
        return cmp;
    }

    /**
     * Checks if this time is after the specified time.
     * !(p)
     * The comparison is based on the time-line position of the time within a day.
     *
     * @param other  the other time to compare to, not null
     * @return true if this is after the specified time
     */
    public bool isAfter(LocalTime other) {
        return compareTo(other) > 0;
    }

    /**
     * Checks if this time is before the specified time.
     * !(p)
     * The comparison is based on the time-line position of the time within a day.
     *
     * @param other  the other time to compare to, not null
     * @return true if this point is before the specified time
     */
    public bool isBefore(LocalTime other) {
        return compareTo(other) < 0;
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if this time is equal to another time.
     * !(p)
     * The comparison is based on the time-line position of the time within a day.
     * !(p)
     * Only objects of type {@code LocalTime} are compared, other types return false.
     * To compare the date of two {@code TemporalAccessor} instances, use
     * {@link ChronoField#NANO_OF_DAY} as a comparator.
     *
     * @param obj  the object to check, null returns false
     * @return true if this is equal to the other time
     */
    override
    public bool opEquals(Object obj) {
        if (this is obj) {
            return true;
        }
        if (cast(LocalTime)(obj) !is null) {
            LocalTime other = cast(LocalTime) obj;
            return hour == other.hour && minute == other.minute &&
                    second == other.second && nano == other.nano;
        }
        return false;
    }

    /**
     * A hash code for this time.
     *
     * @return a suitable hash code
     */
    override
    public size_t toHash() @trusted nothrow {
        try
        {
            long nod = toNanoOfDay();
            return cast(int) (nod ^ (nod >>> 32));
        }
        catch(Exception e)
        {}
        return int.init;
    }

    //-----------------------------------------------------------------------
    /**
     * Outputs this time as a {@code string}, such as {@code 10:15}.
     * !(p)
     * The output will be one of the following ISO-8601 formats:
     * !(ul)
     * !(li){@code HH:mm}</li>
     * !(li){@code HH:mm:ss}</li>
     * !(li){@code HH:mm:ss.SSS}</li>
     * !(li){@code HH:mm:ss.SSSSSS}</li>
     * !(li){@code HH:mm:ss.SSSSSSSSS}</li>
     * </ul>
     * The format used will be the shortest that outputs the full value of
     * the time where the omitted parts are implied to be zero.
     *
     * @return a string representation of this time, not null
     */
    override
    public string toString() {
        StringBuilder buf = new StringBuilder(18);
        int hourValue = hour;
        int minuteValue = minute;
        int secondValue = second;
        int nanoValue = nano;
        buf.append(hourValue < 10 ? "0" : "").append(hourValue)
            .append(minuteValue < 10 ? ":0" : ":").append(minuteValue);
        if (secondValue > 0 || nanoValue > 0) {
            buf.append(secondValue < 10 ? ":0" : ":").append(secondValue);
            if (nanoValue > 0) {
                buf.append('.');
                if (nanoValue % 1000_000 == 0) {
                    buf.append(to!string((nanoValue / 1000_000) + 1000).substring(1));
                } else if (nanoValue % 1000 == 0) {
                    buf.append(to!string((nanoValue / 1000) + 1000_000).substring(1));
                } else {
                    buf.append(to!string((nanoValue) + 1000_000_000).substring(1));
                }
            }
        }
        return buf.toString();
    }

    //-----------------------------------------------------------------------
    /**
     * Writes the object using a
     * <a href="{@docRoot}/serialized-form.html#hunt.time.Ser">dedicated serialized form</a>.
     * @serialData
     * A twos-complement value indicates the remaining values are not _in the stream
     * and should be set to zero.
     * !(pre)
     *  _out.writeByte(4);  // identifies a LocalTime
     *  if (nano == 0) {
     *    if (second == 0) {
     *      if (minute == 0) {
     *        _out.writeByte(~hour);
     *      } else {
     *        _out.writeByte(hour);
     *        _out.writeByte(~minute);
     *      }
     *    } else {
     *      _out.writeByte(hour);
     *      _out.writeByte(minute);
     *      _out.writeByte(~second);
     *    }
     *  } else {
     *    _out.writeByte(hour);
     *    _out.writeByte(minute);
     *    _out.writeByte(second);
     *    _out.writeInt(nano);
     *  }
     * </pre>
     *
     * @return the instance of {@code Ser}, not null
     */
    private Object writeReplace() {
        return new Ser(Ser.LOCAL_TIME_TYPE, this);
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

    void writeExternal(DataOutput _out) /*throws IOException*/ {
        if (nano == 0) {
            if (second == 0) {
                if (minute == 0) {
                    _out.writeByte(cast(int)hour);
                } else {
                    _out.writeByte(cast(int)hour);
                    _out.writeByte(cast(int)minute);
                }
            } else {
                _out.writeByte(cast(int)hour);
                _out.writeByte(cast(int)minute);
                _out.writeByte(cast(int)second);
            }
        } else {
            _out.writeByte(cast(int)hour);
            _out.writeByte(cast(int)minute);
            _out.writeByte(cast(int)second);
            _out.writeInt(nano);
        }
    }

    static LocalTime readExternal(DataInput _in) /*throws IOException*/ {
        int hour = _in.readByte();
        int minute = 0;
        int second = 0;
        int nano = 0;
        if (hour < 0) {
            hour = ~hour;
        } else {
            minute = _in.readByte();
            if (minute < 0) {
                minute = ~minute;
            } else {
                second = _in.readByte();
                if (second < 0) {
                    second = ~second;
                } else {
                    nano = _in.readInt();
                }
            }
        }
        return LocalTime.of(hour, minute, second, nano);
    }

}
