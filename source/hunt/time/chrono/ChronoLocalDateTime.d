
module hunt.time.chrono.ChronoLocalDateTime;

import hunt.time.temporal.ChronoField;
import hunt.time.temporal.ChronoUnit;

import hunt.io.Serializable;
import hunt.time.DateTimeException;
import hunt.time.Instant;
import hunt.time.LocalDateTime;
import hunt.time.LocalTime;
import hunt.time.ZoneId;
import hunt.time.ZoneOffset;
import hunt.time.format.DateTimeFormatter;
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
import hunt.time.zone.ZoneRules;
import hunt.util.Comparator;
import hunt.time.chrono.ChronoLocalDate;
import hunt.lang.common;
import hunt.time.chrono.Chronology;
import hunt.time.chrono.ChronoZonedDateTime;
import hunt.util.Comparator;
import hunt.time.util.QueryHelper;

/**
 * A date-time without a time-zone _in an arbitrary chronology, intended
 * for advanced globalization use cases.
 * !(p)
 * !(b)Most applications should declare method signatures, fields and variables
 * as {@link LocalDateTime}, not this interface.</b>
 * !(p)
 * A {@code ChronoLocalDateTime} is the abstract representation of a local date-time
 * where the {@code Chronology chronology}, or calendar system, is pluggable.
 * The date-time is defined _in terms of fields expressed by {@link TemporalField},
 * where most common implementations are defined _in {@link ChronoField}.
 * The chronology defines how the calendar system operates and the meaning of
 * the standard fields.
 *
 * !(h3)When to use this interface</h3>
 * The design of the API encourages the use of {@code LocalDateTime} rather than this
 * interface, even _in the case where the application needs to deal with multiple
 * calendar systems. The rationale for this is explored _in detail _in {@link ChronoLocalDate}.
 * !(p)
 * Ensure that the discussion _in {@code ChronoLocalDate} has been read and understood
 * before using this interface.
 *
 * @implSpec
 * This interface must be implemented with care to ensure other classes operate correctly.
 * All implementations that can be instantiated must be final, immutable and thread-safe.
 * Subclasses should be Serializable wherever possible.
 *
 * @param !(D) the concrete type for the date of this date-time
 * @since 1.8
 */
public interface ChronoLocalDateTime(D) if(is(D : ChronoLocalDate))
        : Temporal, TemporalAdjuster, Comparable!(ChronoLocalDateTime!(ChronoLocalDate)) {

    /**
     * Gets a comparator that compares {@code ChronoLocalDateTime} _in
     * time-line order ignoring the chronology.
     * !(p)
     * This comparator differs from the comparison _in {@link #compareTo} _in that it
     * only compares the underlying date-time and not the chronology.
     * This allows dates _in different calendar systems to be compared based
     * on the position of the date-time on the local time-line.
     * The underlying comparison is equivalent to comparing the epoch-day and nano-of-day.
     *
     * @return a comparator that compares _in time-line order ignoring the chronology
     * @see #isAfter
     * @see #isBefore
     * @see #isEqual
     */
    static Comparator!(ChronoLocalDateTime!(ChronoLocalDate)) timeLineOrder() {
        return new class Comparator!(ChronoLocalDateTime!(ChronoLocalDate)) 
        {
            int compare(ChronoLocalDateTime!(ChronoLocalDate) dateTime1, ChronoLocalDateTime!(ChronoLocalDate) dateTime2){
                int cmp = hunt.util.Comparator.compare(dateTime1.toLocalDate().toEpochDay(), dateTime2.toLocalDate().toEpochDay());
                if (cmp == 0) {
                    cmp = hunt.util.Comparator.compare(dateTime1.toLocalTime().toNanoOfDay(), dateTime2.toLocalTime().toNanoOfDay());
                }
                return cmp;
            }
        };
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code ChronoLocalDateTime} from a temporal object.
     * !(p)
     * This obtains a local date-time based on the specified temporal.
     * A {@code TemporalAccessor} represents an arbitrary set of date and time information,
     * which this factory converts to an instance of {@code ChronoLocalDateTime}.
     * !(p)
     * The conversion extracts and combines the chronology and the date-time
     * from the temporal object. The behavior is equivalent to using
     * {@link Chronology#localDateTime(TemporalAccessor)} with the extracted chronology.
     * Implementations are permitted to perform optimizations such as accessing
     * those fields that are equivalent to the relevant objects.
     * !(p)
     * This method matches the signature of the functional interface {@link TemporalQuery}
     * allowing it to be used as a query via method reference, {@code ChronoLocalDateTime::from}.
     *
     * @param temporal  the temporal object to convert, not null
     * @return the date-time, not null
     * @throws DateTimeException if unable to convert to a {@code ChronoLocalDateTime}
     * @see Chronology#localDateTime(TemporalAccessor)
     */
    static ChronoLocalDateTime!(ChronoLocalDate) from(TemporalAccessor temporal) {
        if (cast(ChronoLocalDateTime)(temporal) !is null) {
            return cast(ChronoLocalDateTime!(ChronoLocalDate)) temporal;
        }
        assert(temporal, "temporal");
        Chronology chrono = QueryHelper.query!Chronology(temporal,TemporalQueries.chronology());
        if (chrono is null) {
            throw new DateTimeException("Unable to obtain ChronoLocalDateTime from TemporalAccessor: " ~ typeid(temporal).stringof);
        }
        return chrono.localDateTime(temporal);
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the chronology of this date-time.
     * !(p)
     * The {@code Chronology} represents the calendar system _in use.
     * The era and other fields _in {@link ChronoField} are defined by the chronology.
     *
     * @return the chronology, not null
     */
     Chronology getChronology();
    //  Chronology getChronology() {
    //     return toLocalDate().getChronology();
    // }

    /**
     * Gets the local date part of this date-time.
     * !(p)
     * This returns a local date with the same year, month and day
     * as this date-time.
     *
     * @return the date part of this date-time, not null
     */
    D toLocalDate();

    /**
     * Gets the local time part of this date-time.
     * !(p)
     * This returns a local time with the same hour, minute, second and
     * nanosecond as this date-time.
     *
     * @return the time part of this date-time, not null
     */
    LocalTime toLocalTime();

    /**
     * Checks if the specified field is supported.
     * !(p)
     * This checks if the specified field can be queried on this date-time.
     * If false, then calling the {@link #range(TemporalField) range},
     * {@link #get(TemporalField) get} and {@link #_with(TemporalField, long)}
     * methods will throw an exception.
     * !(p)
     * The set of supported fields is defined by the chronology and normally includes
     * all {@code ChronoField} date and time fields.
     * !(p)
     * If the field is not a {@code ChronoField}, then the result of this method
     * is obtained by invoking {@code TemporalField.isSupportedBy(TemporalAccessor)}
     * passing {@code this} as the argument.
     * Whether the field is supported is determined by the field.
     *
     * @param field  the field to check, null returns false
     * @return true if the field can be queried, false if not
     */
    override
    bool isSupported(TemporalField field);

    /**
     * Checks if the specified unit is supported.
     * !(p)
     * This checks if the specified unit can be added to or subtracted from this date-time.
     * If false, then calling the {@link #plus(long, TemporalUnit)} and
     * {@link #minus(long, TemporalUnit) minus} methods will throw an exception.
     * !(p)
     * The set of supported units is defined by the chronology and normally includes
     * all {@code ChronoUnit} units except {@code FOREVER}.
     * !(p)
     * If the unit is not a {@code ChronoUnit}, then the result of this method
     * is obtained by invoking {@code TemporalUnit.isSupportedBy(Temporal)}
     * passing {@code this} as the argument.
     * Whether the unit is supported is determined by the unit.
     *
     * @param unit  the unit to check, null returns false
     * @return true if the unit can be added/subtracted, false if not
     */
      bool isSupported(TemporalUnit unit);
    // override
    //  bool isSupported(TemporalUnit unit) {
    //     if (cast(ChronoUnit)(unit) !is null) {
    //         return unit != FOREVER;
    //     }
    //     return unit !is null && unit.isSupportedBy(this);
    // }

    //-----------------------------------------------------------------------
    // override for covariant return type
    /**
     * {@inheritDoc}
     * @throws DateTimeException {@inheritDoc}
     * @throws ArithmeticException {@inheritDoc}
     */
     ChronoLocalDateTime!(D) _with(TemporalAdjuster adjuster);
    // override
    //  ChronoLocalDateTime!(D) _with(TemporalAdjuster adjuster) {
    //     return ChronoLocalDateTimeImpl.ensureValid(getChronology(), /* Temporal. */super._with(adjuster));
    // }

    /**
     * {@inheritDoc}
     * @throws DateTimeException {@inheritDoc}
     * @throws ArithmeticException {@inheritDoc}
     */
    override
    ChronoLocalDateTime!(D) _with(TemporalField field, long newValue);

    /**
     * {@inheritDoc}
     * @throws DateTimeException {@inheritDoc}
     * @throws ArithmeticException {@inheritDoc}
     */
     ChronoLocalDateTime!(D) plus(TemporalAmount amount);
    // override
    //  ChronoLocalDateTime!(D) plus(TemporalAmount amount) {
    //     return ChronoLocalDateTimeImpl.ensureValid(getChronology(), /* Temporal. */super.plus(amount));
    // }

    /**
     * {@inheritDoc}
     * @throws DateTimeException {@inheritDoc}
     * @throws ArithmeticException {@inheritDoc}
     */
    override
    ChronoLocalDateTime!(D) plus(long amountToAdd, TemporalUnit unit);

    /**
     * {@inheritDoc}
     * @throws DateTimeException {@inheritDoc}
     * @throws ArithmeticException {@inheritDoc}
     */
     ChronoLocalDateTime!(D) minus(TemporalAmount amount);
    // override
    //  ChronoLocalDateTime!(D) minus(TemporalAmount amount) {
    //     return ChronoLocalDateTimeImpl.ensureValid(getChronology(), /* Temporal. */super.minus(amount));
    // }

    /**
     * {@inheritDoc}
     * @throws DateTimeException {@inheritDoc}
     * @throws ArithmeticException {@inheritDoc}
     */
     ChronoLocalDateTime!(D) minus(long amountToSubtract, TemporalUnit unit);
    // override
    //  ChronoLocalDateTime!(D) minus(long amountToSubtract, TemporalUnit unit) {
    //     return ChronoLocalDateTimeImpl.ensureValid(getChronology(), /* Temporal. */super.minus(amountToSubtract, unit));
    // }

    //-----------------------------------------------------------------------
    /**
     * Queries this date-time using the specified query.
     * !(p)
     * This queries this date-time using the specified query strategy object.
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
    R query(R)(TemporalQuery!(R) query);
    // override
    //   R query(TemporalQuery!(R) query) {
    //     if (query == TemporalQueries.zoneId() || query == TemporalQueries.zone() || query == TemporalQueries.offset()) {
    //         return null;
    //     } else if (query == TemporalQueries.localTime()) {
    //         return cast(R) toLocalTime();
    //     } else if (query == TemporalQueries.chronology()) {
    //         return cast(R) getChronology();
    //     } else if (query == TemporalQueries.precision()) {
    //         return cast(R) NANOS;
    //     }
    //     // inline TemporalAccessor.super.query(query) as an optimization
    //     // non-JDK classes are not permitted to make this optimization
    //     return query.queryFrom(this);
    // }

    /**
     * Adjusts the specified temporal object to have the same date and time as this object.
     * !(p)
     * This returns a temporal object of the same observable type as the input
     * with the date and time changed to be the same as this.
     * !(p)
     * The adjustment is equivalent to using {@link Temporal#_with(TemporalField, long)}
     * twice, passing {@link ChronoField#EPOCH_DAY} and
     * {@link ChronoField#NANO_OF_DAY} as the fields.
     * !(p)
     * In most cases, it is clearer to reverse the calling pattern by using
     * {@link Temporal#_with(TemporalAdjuster)}:
     * !(pre)
     *   // these two lines are equivalent, but the second approach is recommended
     *   temporal = thisLocalDateTime.adjustInto(temporal);
     *   temporal = temporal._with(thisLocalDateTime);
     * </pre>
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param temporal  the target object to be adjusted, not null
     * @return the adjusted object, not null
     * @throws DateTimeException if unable to make the adjustment
     * @throws ArithmeticException if numeric overflow occurs
     */
     Temporal adjustInto(Temporal temporal);
    // override
    //  Temporal adjustInto(Temporal temporal) {
    //     return temporal
    //             ._with(EPOCH_DAY, toLocalDate().toEpochDay())
    //             ._with(NANO_OF_DAY, toLocalTime().toNanoOfDay());
    // }

    /**
     * Formats this date-time using the specified formatter.
     * !(p)
     * This date-time will be passed to the formatter to produce a string.
     * !(p)
     * The  implementation must behave as follows:
     * !(pre)
     *  return formatter.format(this);
     * </pre>
     *
     * @param formatter  the formatter to use, not null
     * @return the formatted date-time string, not null
     * @throws DateTimeException if an error occurs during printing
     */
     string format(DateTimeFormatter formatter);
    //  string format(DateTimeFormatter formatter) {
    //     assert(formatter, "formatter");
    //     return formatter.format(this);
    // }

    //-----------------------------------------------------------------------
    /**
     * Combines this time with a time-zone to create a {@code ChronoZonedDateTime}.
     * !(p)
     * This returns a {@code ChronoZonedDateTime} formed from this date-time at the
     * specified time-zone. The result will match this date-time as closely as possible.
     * Time-zone rules, such as daylight savings, mean that not every local date-time
     * is valid for the specified zone, thus the local date-time may be adjusted.
     * !(p)
     * The local date-time is resolved to a single instant on the time-line.
     * This is achieved by finding a valid offset from UTC/Greenwich for the local
     * date-time as defined by the {@link ZoneRules rules} of the zone ID.
     *!(p)
     * In most cases, there is only one valid offset for a local date-time.
     * In the case of an overlap, where clocks are set back, there are two valid offsets.
     * This method uses the earlier offset typically corresponding to "summer".
     * !(p)
     * In the case of a gap, where clocks jump forward, there is no valid offset.
     * Instead, the local date-time is adjusted to be later by the length of the gap.
     * For a typical one hour daylight savings change, the local date-time will be
     * moved one hour later into the offset typically corresponding to "summer".
     * !(p)
     * To obtain the later offset during an overlap, call
     * {@link ChronoZonedDateTime#withLaterOffsetAtOverlap()} on the result of this method.
     *
     * @param zone  the time-zone to use, not null
     * @return the zoned date-time formed from this date-time, not null
     */
    ChronoZonedDateTime!(D) atZone(ZoneId zone);

    //-----------------------------------------------------------------------
    /**
     * Converts this date-time to an {@code Instant}.
     * !(p)
     * This combines this local date-time and the specified offset to form
     * an {@code Instant}.
     * !(p)
     * This  implementation calculates from the epoch-day of the date and the
     * second-of-day of the time.
     *
     * @param offset  the offset to use for the conversion, not null
     * @return an {@code Instant} representing the same instant, not null
     */
     Instant toInstant(ZoneOffset offset);
    //  Instant toInstant(ZoneOffset offset) {
    //     return Instant.ofEpochSecond(toEpochSecond(offset), toLocalTime().getNano());
    // }

    /**
     * Converts this date-time to the number of seconds from the epoch
     * of 1970-01-01T00:00:00Z.
     * !(p)
     * This combines this local date-time and the specified offset to calculate the
     * epoch-second value, which is the number of elapsed seconds from 1970-01-01T00:00:00Z.
     * Instants on the time-line after the epoch are positive, earlier are negative.
     * !(p)
     * This  implementation calculates from the epoch-day of the date and the
     * second-of-day of the time.
     *
     * @param offset  the offset to use for the conversion, not null
     * @return the number of seconds from the epoch of 1970-01-01T00:00:00Z
     */
     long toEpochSecond(ZoneOffset offset);
    //  long toEpochSecond(ZoneOffset offset) {
    //     assert(offset, "offset");
    //     long epochDay = toLocalDate().toEpochDay();
    //     long secs = epochDay * 86400 + toLocalTime().toSecondOfDay();
    //     secs -= offset.getTotalSeconds();
    //     return secs;
    // }

    //-----------------------------------------------------------------------
    /**
     * Compares this date-time to another date-time, including the chronology.
     * !(p)
     * The comparison is based first on the underlying time-line date-time, then
     * on the chronology.
     * It is "consistent with equals", as defined by {@link Comparable}.
     * !(p)
     * For example, the following is the comparator order:
     * !(ol)
     * !(li){@code 2012-12-03T12:00 (ISO)}</li>
     * !(li){@code 2012-12-04T12:00 (ISO)}</li>
     * !(li){@code 2555-12-04T12:00 (ThaiBuddhist)}</li>
     * !(li){@code 2012-12-05T12:00 (ISO)}</li>
     * </ol>
     * Values #2 and #3 represent the same date-time on the time-line.
     * When two values represent the same date-time, the chronology ID is compared to distinguish them.
     * This step is needed to make the ordering "consistent with equals".
     * !(p)
     * If all the date-time objects being compared are _in the same chronology, then the
     * additional chronology stage is not required and only the local date-time is used.
     * !(p)
     * This  implementation performs the comparison defined above.
     *
     * @param other  the other date-time to compare to, not null
     * @return the comparator value, negative if less, positive if greater
     */
    //  override
     int compareTo(ChronoLocalDateTime!(ChronoLocalDate) other);
    // override
    //  int compareTo(ChronoLocalDateTime!(ChronoLocalDate) other) {
    //     int cmp = toLocalDate().compareTo(other.toLocalDate());
    //     if (cmp == 0) {
    //         cmp = toLocalTime().compareTo(other.toLocalTime());
    //         if (cmp == 0) {
    //             cmp = getChronology().compareTo(other.getChronology());
    //         }
    //     }
    //     return cmp;
    // }

    /**
     * Checks if this date-time is after the specified date-time ignoring the chronology.
     * !(p)
     * This method differs from the comparison _in {@link #compareTo} _in that it
     * only compares the underlying date-time and not the chronology.
     * This allows dates _in different calendar systems to be compared based
     * on the time-line position.
     * !(p)
     * This  implementation performs the comparison based on the epoch-day
     * and nano-of-day.
     *
     * @param other  the other date-time to compare to, not null
     * @return true if this is after the specified date-time
     */
     bool isAfter(ChronoLocalDateTime!(ChronoLocalDate) other);
    //  bool isAfter(ChronoLocalDateTime!(ChronoLocalDate) other) {
    //     long thisEpDay = this.toLocalDate().toEpochDay();
    //     long otherEpDay = other.toLocalDate().toEpochDay();
    //     return thisEpDay > otherEpDay ||
    //         (thisEpDay == otherEpDay && this.toLocalTime().toNanoOfDay() > other.toLocalTime().toNanoOfDay());
    // }

    /**
     * Checks if this date-time is before the specified date-time ignoring the chronology.
     * !(p)
     * This method differs from the comparison _in {@link #compareTo} _in that it
     * only compares the underlying date-time and not the chronology.
     * This allows dates _in different calendar systems to be compared based
     * on the time-line position.
     * !(p)
     * This  implementation performs the comparison based on the epoch-day
     * and nano-of-day.
     *
     * @param other  the other date-time to compare to, not null
     * @return true if this is before the specified date-time
     */
     bool isBefore(ChronoLocalDateTime!(ChronoLocalDate) other);
    //  bool isBefore(ChronoLocalDateTime!(ChronoLocalDate) other) {
    //     long thisEpDay = this.toLocalDate().toEpochDay();
    //     long otherEpDay = other.toLocalDate().toEpochDay();
    //     return thisEpDay < otherEpDay ||
    //         (thisEpDay == otherEpDay && this.toLocalTime().toNanoOfDay() < other.toLocalTime().toNanoOfDay());
    // }

    /**
     * Checks if this date-time is equal to the specified date-time ignoring the chronology.
     * !(p)
     * This method differs from the comparison _in {@link #compareTo} _in that it
     * only compares the underlying date and time and not the chronology.
     * This allows date-times _in different calendar systems to be compared based
     * on the time-line position.
     * !(p)
     * This  implementation performs the comparison based on the epoch-day
     * and nano-of-day.
     *
     * @param other  the other date-time to compare to, not null
     * @return true if the underlying date-time is equal to the specified date-time on the timeline
     */
     bool isEqual(ChronoLocalDateTime!(ChronoLocalDate) other);
    //  bool isEqual(ChronoLocalDateTime!(ChronoLocalDate) other) {
    //     // Do the time check first, it is cheaper than computing EPOCH day.
    //     return this.toLocalTime().toNanoOfDay() == other.toLocalTime().toNanoOfDay() &&
    //            this.toLocalDate().toEpochDay() == other.toLocalDate().toEpochDay();
    // }

    /**
     * Checks if this date-time is equal to another date-time, including the chronology.
     * !(p)
     * Compares this date-time with another ensuring that the date-time and chronology are the same.
     *
     * @param obj  the object to check, null returns false
     * @return true if this is equal to the other date
     */
    // override
    bool opEquals(Object obj);

    /**
     * A hash code for this date-time.
     *
     * @return a suitable hash code
     */
    // override
    size_t toHash() @trusted nothrow;

    //-----------------------------------------------------------------------
    /**
     * Outputs this date-time as a {@code string}.
     * !(p)
     * The output will include the full local date-time.
     *
     * @return a string representation of this date-time, not null
     */
    // override
    string toString();

}
