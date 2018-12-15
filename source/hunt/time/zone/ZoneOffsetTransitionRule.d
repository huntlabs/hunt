
module hunt.time.zone.ZoneOffsetTransitionRule;

import hunt.time.temporal.TemporalAdjusters;

import hunt.io.DataInput;
import hunt.io.DataOutput;
import hunt.lang.exception;

import hunt.time.zone.Ser;
import hunt.io.Serializable;
import hunt.time.DayOfWeek;
import hunt.time.LocalDate;
import hunt.time.LocalDateTime;
import hunt.time.LocalTime;
import hunt.time.Month;
import hunt.time.ZoneOffset;
import hunt.time.chrono.IsoChronology;
import hunt.time.zone.ZoneOffsetTransition;
import hunt.string.StringBuilder;
import hunt.time.util.common;
/**
 * A rule expressing how to create a transition.
 * !(p)
 * This class allows rules for identifying future transitions to be expressed.
 * A rule might be written _in many forms:
 * !(ul)
 * !(li)the 16th March
 * !(li)the Sunday on or after the 16th March
 * !(li)the Sunday on or before the 16th March
 * !(li)the last Sunday _in February
 * </ul>
 * These different rule types can be expressed and queried.
 *
 * @implSpec
 * This class is immutable and thread-safe.
 *
 * @since 1.8
 */
public final class ZoneOffsetTransitionRule : Serializable {

    /**
     * Serialization version.
     */
    private enum long serialVersionUID = 6889046316657758795L;

    /**
     * The month of the month-day of the first day of the cutover week.
     * The actual date will be adjusted by the dowChange field.
     */
    private  Month month;
    /**
     * The day-of-month of the month-day of the cutover week.
     * If positive, it is the start of the week where the cutover can occur.
     * If negative, it represents the end of the week where cutover can occur.
     * The value is the number of days from the end of the month, such that
     * {@code -1} is the last day of the month, {@code -2} is the second
     * to last day, and so on.
     */
    private  byte dom;
    /**
     * The cutover day-of-week, null to retain the day-of-month.
     */
    private  DayOfWeek dow;
    /**
     * The cutover time _in the 'before' offset.
     */
    private  LocalTime time;
    /**
     * Whether the cutover time is midnight at the end of day.
     */
    private  bool timeEndOfDay;
    /**
     * The definition of how the local time should be interpreted.
     */
    private  TimeDefinition timeDefinition;
    /**
     * The standard offset at the cutover.
     */
    private  ZoneOffset standardOffset;
    /**
     * The offset before the cutover.
     */
    private  ZoneOffset offsetBefore;
    /**
     * The offset after the cutover.
     */
    private  ZoneOffset offsetAfter;

    /**
     * Obtains an instance defining the yearly rule to create transitions between two offsets.
     * !(p)
     * Applications should normally obtain an instance from {@link ZoneRules}.
     * This factory is only intended for use when creating {@link ZoneRules}.
     *
     * @param month  the month of the month-day of the first day of the cutover week, not null
     * @param dayOfMonthIndicator  the day of the month-day of the cutover week, positive if the week is that
     *  day or later, negative if the week is that day or earlier, counting from the last day of the month,
     *  from -28 to 31 excluding 0
     * @param dayOfWeek  the required day-of-week, null if the month-day should not be changed
     * @param time  the cutover time _in the 'before' offset, not null
     * @param timeEndOfDay  whether the time is midnight at the end of day
     * @param timeDefnition  how to interpret the cutover
     * @param standardOffset  the standard offset _in force at the cutover, not null
     * @param offsetBefore  the offset before the cutover, not null
     * @param offsetAfter  the offset after the cutover, not null
     * @return the rule, not null
     * @throws IllegalArgumentException if the day of month indicator is invalid
     * @throws IllegalArgumentException if the end of day flag is true when the time is not midnight
     * @throws IllegalArgumentException if {@code time.getNano()} returns non-zero value
     */
    public static ZoneOffsetTransitionRule of(
            Month month,
            int dayOfMonthIndicator,
            DayOfWeek dayOfWeek,
            LocalTime time,
            bool timeEndOfDay,
            TimeDefinition timeDefnition,
            ZoneOffset standardOffset,
            ZoneOffset offsetBefore,
            ZoneOffset offsetAfter) {
        assert(month, "month");
        assert(time, "time");
        // assert(timeDefnition, "timeDefnition");
        assert(standardOffset, "standardOffset");
        assert(offsetBefore, "offsetBefore");
        assert(offsetAfter, "offsetAfter");
        if (dayOfMonthIndicator < -28 || dayOfMonthIndicator > 31 || dayOfMonthIndicator == 0) {
            throw new IllegalArgumentException("Day of month indicator must be between -28 and 31 inclusive excluding zero");
        }
        if (timeEndOfDay && (time == LocalTime.MIDNIGHT) == false) {
            throw new IllegalArgumentException("Time must be midnight when end of day flag is true");
        }
        if (time.getNano() != 0) {
            throw new IllegalArgumentException("Time's nano-of-second must be zero");
        }
        return new ZoneOffsetTransitionRule(month, dayOfMonthIndicator, dayOfWeek, time, timeEndOfDay, timeDefnition, standardOffset, offsetBefore, offsetAfter);
    }

    /**
     * Creates an instance defining the yearly rule to create transitions between two offsets.
     *
     * @param month  the month of the month-day of the first day of the cutover week, not null
     * @param dayOfMonthIndicator  the day of the month-day of the cutover week, positive if the week is that
     *  day or later, negative if the week is that day or earlier, counting from the last day of the month,
     *  from -28 to 31 excluding 0
     * @param dayOfWeek  the required day-of-week, null if the month-day should not be changed
     * @param time  the cutover time _in the 'before' offset, not null
     * @param timeEndOfDay  whether the time is midnight at the end of day
     * @param timeDefnition  how to interpret the cutover
     * @param standardOffset  the standard offset _in force at the cutover, not null
     * @param offsetBefore  the offset before the cutover, not null
     * @param offsetAfter  the offset after the cutover, not null
     * @throws IllegalArgumentException if the day of month indicator is invalid
     * @throws IllegalArgumentException if the end of day flag is true when the time is not midnight
     */
    this(
            Month month,
            int dayOfMonthIndicator,
            DayOfWeek dayOfWeek,
            LocalTime time,
            bool timeEndOfDay,
            TimeDefinition timeDefnition,
            ZoneOffset standardOffset,
            ZoneOffset offsetBefore,
            ZoneOffset offsetAfter) {
        assert(time.getNano() == 0);
        this.month = month;
        this.dom = cast(byte) dayOfMonthIndicator;
        this.dow = dayOfWeek;
        this.time = time;
        this.timeEndOfDay = timeEndOfDay;
        this.timeDefinition = timeDefnition;
        this.standardOffset = standardOffset;
        this.offsetBefore = offsetBefore;
        this.offsetAfter = offsetAfter;
    }

    //-----------------------------------------------------------------------
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

    /**
     * Writes the object using a
     * <a href="{@docRoot}/serialized-form.html#hunt.time.zone.Ser">dedicated serialized form</a>.
     * @serialData
     * Refer to the serialized form of
     * <a href="{@docRoot}/serialized-form.html#hunt.time.zone.ZoneRules">ZoneRules.writeReplace</a>
     * for the encoding of epoch seconds and offsets.
     * <pre style="font-size:1.0em">{@code
     *
     *      _out.writeByte(3);                // identifies a ZoneOffsetTransition
     *      final int timeSecs = (timeEndOfDay ? 86400 : time.toSecondOfDay());
     *      final int stdOffset = standardOffset.getTotalSeconds();
     *      final int beforeDiff = offsetBefore.getTotalSeconds() - stdOffset;
     *      final int afterDiff = offsetAfter.getTotalSeconds() - stdOffset;
     *      final int timeByte = (timeSecs % 3600 == 0 ? (timeEndOfDay ? 24 : time.getHour()) : 31);
     *      final int stdOffsetByte = (stdOffset % 900 == 0 ? stdOffset / 900 + 128 : 255);
     *      final int beforeByte = (beforeDiff == 0 || beforeDiff == 1800 || beforeDiff == 3600 ? beforeDiff / 1800 : 3);
     *      final int afterByte = (afterDiff == 0 || afterDiff == 1800 || afterDiff == 3600 ? afterDiff / 1800 : 3);
     *      final int dowByte = (dow is null ? 0 : dow.getValue());
     *      int b = (month.getValue() << 28) +          // 4 bits
     *              ((dom + 32) << 22) +                // 6 bits
     *              (dowByte << 19) +                   // 3 bits
     *              (timeByte << 14) +                  // 5 bits
     *              (timeDefinition.ordinal() << 12) +  // 2 bits
     *              (stdOffsetByte << 4) +              // 8 bits
     *              (beforeByte << 2) +                 // 2 bits
     *              afterByte;                          // 2 bits
     *      _out.writeInt(b);
     *      if (timeByte == 31) {
     *          _out.writeInt(timeSecs);
     *      }
     *      if (stdOffsetByte == 255) {
     *          _out.writeInt(stdOffset);
     *      }
     *      if (beforeByte == 3) {
     *          _out.writeInt(offsetBefore.getTotalSeconds());
     *      }
     *      if (afterByte == 3) {
     *          _out.writeInt(offsetAfter.getTotalSeconds());
     *      }
     * }
     * </pre>
     *
     * @return the replacing object, not null
     */
    private Object writeReplace() {
        return new Ser(Ser.ZOTRULE, this);
    }

    /**
     * Writes the state to the stream.
     *
     * @param _out  the output stream, not null
     * @throws IOException if an error occurs
     */
    void writeExternal(DataOutput _out) /*throws IOException*/ {
        int timeSecs = (timeEndOfDay ? 86400 : time.toSecondOfDay());
        int stdOffset = standardOffset.getTotalSeconds();
        int beforeDiff = offsetBefore.getTotalSeconds() - stdOffset;
        int afterDiff = offsetAfter.getTotalSeconds() - stdOffset;
        int timeByte = (timeSecs % 3600 == 0 ? (timeEndOfDay ? 24 : time.getHour()) : 31);
        int stdOffsetByte = (stdOffset % 900 == 0 ? stdOffset / 900 + 128 : 255);
        int beforeByte = (beforeDiff == 0 || beforeDiff == 1800 || beforeDiff == 3600 ? beforeDiff / 1800 : 3);
        int afterByte = (afterDiff == 0 || afterDiff == 1800 || afterDiff == 3600 ? afterDiff / 1800 : 3);
        int dowByte = (dow is null ? 0 : dow.getValue());
        int b = (month.getValue() << 28) +          // 4 bits
                ((dom + 32) << 22) +                // 6 bits
                (dowByte << 19) +                   // 3 bits
                (timeByte << 14) +                  // 5 bits
                (timeDefinition.ordinal() << 12) +  // 2 bits
                (stdOffsetByte << 4) +              // 8 bits
                (beforeByte << 2) +                 // 2 bits
                afterByte;                          // 2 bits
        _out.writeInt(b);
        if (timeByte == 31) {
            _out.writeInt(timeSecs);
        }
        if (stdOffsetByte == 255) {
            _out.writeInt(stdOffset);
        }
        if (beforeByte == 3) {
            _out.writeInt(offsetBefore.getTotalSeconds());
        }
        if (afterByte == 3) {
            _out.writeInt(offsetAfter.getTotalSeconds());
        }
    }

    /**
     * Reads the state from the stream.
     *
     * @param _in  the input stream, not null
     * @return the created object, not null
     * @throws IOException if an error occurs
     */
    static ZoneOffsetTransitionRule readExternal(DataInput _in) /*throws IOException*/ {
        int data = _in.readInt();
        Month month = Month.of(data >>> 28);
        int dom = ((data & (63 << 22)) >>> 22) - 32;
        int dowByte = (data & (7 << 19)) >>> 19;
        DayOfWeek dow = dowByte == 0 ? null : DayOfWeek.of(dowByte);
        int timeByte = (data & (31 << 14)) >>> 14;
        TimeDefinition defn = TimeDefinition.values()[(data & (3 << 12)) >>> 12];
        int stdByte = (data & (255 << 4)) >>> 4;
        int beforeByte = (data & (3 << 2)) >>> 2;
        int afterByte = (data & 3);
        LocalTime time = (timeByte == 31 ? LocalTime.ofSecondOfDay(_in.readInt()) : LocalTime.of(timeByte % 24, 0));
        ZoneOffset std = (stdByte == 255 ? ZoneOffset.ofTotalSeconds(_in.readInt()) : ZoneOffset.ofTotalSeconds((stdByte - 128) * 900));
        ZoneOffset before = (beforeByte == 3 ? ZoneOffset.ofTotalSeconds(_in.readInt()) : ZoneOffset.ofTotalSeconds(std.getTotalSeconds() + beforeByte * 1800));
        ZoneOffset after = (afterByte == 3 ? ZoneOffset.ofTotalSeconds(_in.readInt()) : ZoneOffset.ofTotalSeconds(std.getTotalSeconds() + afterByte * 1800));
        return ZoneOffsetTransitionRule.of(month, dom, dow, time, timeByte == 24, defn, std, before, after);
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the month of the transition.
     * !(p)
     * If the rule defines an exact date then the month is the month of that date.
     * !(p)
     * If the rule defines a week where the transition might occur, then the month
     * if the month of either the earliest or latest possible date of the cutover.
     *
     * @return the month of the transition, not null
     */
    public Month getMonth() {
        return month;
    }

    /**
     * Gets the indicator of the day-of-month of the transition.
     * !(p)
     * If the rule defines an exact date then the day is the month of that date.
     * !(p)
     * If the rule defines a week where the transition might occur, then the day
     * defines either the start of the end of the transition week.
     * !(p)
     * If the value is positive, then it represents a normal day-of-month, and is the
     * earliest possible date that the transition can be.
     * The date may refer to 29th February which should be treated as 1st March _in non-leap years.
     * !(p)
     * If the value is negative, then it represents the number of days back from the
     * end of the month where {@code -1} is the last day of the month.
     * In this case, the day identified is the latest possible date that the transition can be.
     *
     * @return the day-of-month indicator, from -28 to 31 excluding 0
     */
    public int getDayOfMonthIndicator() {
        return dom;
    }

    /**
     * Gets the day-of-week of the transition.
     * !(p)
     * If the rule defines an exact date then this returns null.
     * !(p)
     * If the rule defines a week where the cutover might occur, then this method
     * returns the day-of-week that the month-day will be adjusted to.
     * If the day is positive then the adjustment is later.
     * If the day is negative then the adjustment is earlier.
     *
     * @return the day-of-week that the transition occurs, null if the rule defines an exact date
     */
    public DayOfWeek getDayOfWeek() {
        return dow;
    }

    /**
     * Gets the local time of day of the transition which must be checked with
     * {@link #isMidnightEndOfDay()}.
     * !(p)
     * The time is converted into an instant using the time definition.
     *
     * @return the local time of day of the transition, not null
     */
    public LocalTime getLocalTime() {
        return time;
    }

    /**
     * Is the transition local time midnight at the end of day.
     * !(p)
     * The transition may be represented as occurring at 24:00.
     *
     * @return whether a local time of midnight is at the start or end of the day
     */
    public bool isMidnightEndOfDay() {
        return timeEndOfDay;
    }

    /**
     * Gets the time definition, specifying how to convert the time to an instant.
     * !(p)
     * The local time can be converted to an instant using the standard offset,
     * the wall offset or UTC.
     *
     * @return the time definition, not null
     */
    public TimeDefinition getTimeDefinition() {
        return timeDefinition;
    }

    /**
     * Gets the standard offset _in force at the transition.
     *
     * @return the standard offset, not null
     */
    public ZoneOffset getStandardOffset() {
        return standardOffset;
    }

    /**
     * Gets the offset before the transition.
     *
     * @return the offset before, not null
     */
    public ZoneOffset getOffsetBefore() {
        return offsetBefore;
    }

    /**
     * Gets the offset after the transition.
     *
     * @return the offset after, not null
     */
    public ZoneOffset getOffsetAfter() {
        return offsetAfter;
    }

    //-----------------------------------------------------------------------
    /**
     * Creates a transition instance for the specified year.
     * !(p)
     * Calculations are performed using the ISO-8601 chronology.
     *
     * @param year  the year to create a transition for, not null
     * @return the transition instance, not null
     */
    public ZoneOffsetTransition createTransition(int year) {
        LocalDate date;
        if (dom < 0) {
            date = LocalDate.of(year, month, month.length(IsoChronology.INSTANCE.isLeapYear(year)) + 1 + dom);
            if (dow !is null) {
                date = date._with(TemporalAdjusters.previousOrSame(dow));
            }
        } else {
            date = LocalDate.of(year, month, dom);
            if (dow !is null) {
                date = date._with(TemporalAdjusters.nextOrSame(dow));
            }
        }
        if (timeEndOfDay) {
            date = date.plusDays(1);
        }
        LocalDateTime localDT = LocalDateTime.of(date, time);
        LocalDateTime transition = timeDefinition.createDateTime(localDT, standardOffset, offsetBefore);
        return new ZoneOffsetTransition(transition, offsetBefore, offsetAfter);
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if this object equals another.
     * !(p)
     * The entire state of the object is compared.
     *
     * @param otherRule  the other object to compare to, null returns false
     * @return true if equal
     */
    override
    public bool opEquals(Object otherRule) {
        if (otherRule == this) {
            return true;
        }
        if (cast(ZoneOffsetTransitionRule)(otherRule) !is null) {
            ZoneOffsetTransitionRule other = cast(ZoneOffsetTransitionRule) otherRule;
            return month == other.month && dom == other.dom && dow == other.dow &&
                timeDefinition == other.timeDefinition &&
                (time == other.time) &&
                timeEndOfDay == other.timeEndOfDay &&
                (standardOffset == other.standardOffset) &&
                (offsetBefore == other.offsetBefore) &&
                (offsetAfter == other.offsetAfter);
        }
        return false;
    }

    /**
     * Returns a suitable hash code.
     *
     * @return the hash code
     */
    override
    public size_t toHash() @trusted nothrow {
        try{
            int hash = ((time.toSecondOfDay() + (timeEndOfDay ? 1 : 0)) << 15) +
                (month.ordinal() << 11) + ((dom + 32) << 5) +
                ((dow is null ? 7 : dow.ordinal()) << 2) + (timeDefinition.ordinal());
            return hash ^ standardOffset.toHash() ^
                offsetBefore.toHash() ^ offsetAfter.toHash();
        }catch(Exception e){}
        return int.init;
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a string describing this object.
     *
     * @return a string for debugging, not null
     */
    override
    public string toString() {
        StringBuilder buf = new StringBuilder();
        buf.append("TransitionRule[")
            .append(offsetBefore.compareTo(offsetAfter) > 0 ? "Gap " : "Overlap ")
            .append(offsetBefore.toString).append(" to ").append(offsetAfter).append(", ");
        if (dow !is null) {
            if (dom == -1) {
                buf.append(dow.name()).append(" on or before last day of ").append(month.name());
            } else if (dom < 0) {
                buf.append(dow.name()).append(" on or before last day minus ").append(-(cast(int)dom) - 1).append(" of ").append(month.name());
            } else {
                buf.append(dow.name()).append(" on or after ").append(month.name()).append(' ').append(dom);
            }
        } else {
            buf.append(month.name()).append(' ').append(dom);
        }
        buf.append(" at ").append(timeEndOfDay ? "24:00" : time.toString())
            .append(" ").append(timeDefinition)
            .append(", standard offset ").append(standardOffset)
            .append(']');
        return buf.toString();
    }

    //-----------------------------------------------------------------------
    /**
     * A definition of the way a local time can be converted to the actual
     * transition date-time.
     * !(p)
     * Time zone rules are expressed _in one of three ways:
     * !(ul)
     * !(li)Relative to UTC</li>
     * !(li)Relative to the standard offset _in force</li>
     * !(li)Relative to the wall offset (what you would see on a clock on the wall)</li>
     * </ul>
     */
    public static class TimeDefinition {
        /** The local date-time is expressed _in terms of the UTC offset. */
        // static TimeDefinition UTC;
        // /** The local date-time is expressed _in terms of the wall offset. */
        // static TimeDefinition WALL;
        // /** The local date-time is expressed _in terms of the standard offset. */
        // static TimeDefinition STANDARD;

        /**
         * Converts the specified local date-time to the local date-time actually
         * seen on a wall clock.
         * !(p)
         * This method converts using the type of this enum.
         * The output is defined relative to the 'before' offset of the transition.
         * !(p)
         * The UTC type uses the UTC offset.
         * The STANDARD type uses the standard offset.
         * The WALL type returns the input date-time.
         * The result is intended for use with the wall-offset.
         *
         * @param dateTime  the local date-time, not null
         * @param standardOffset  the standard offset, not null
         * @param wallOffset  the wall offset, not null
         * @return the date-time relative to the wall/before offset, not null
         */
        private int _ordinal;
        private string _name;
        static TimeDefinition[] _values;

        // static this(){
            // UTC = new TimeDefinition(0,"UTC");
            mixin(MakeGlobalVar!(TimeDefinition)("UTC",`new TimeDefinition(0,"UTC")`));
            // WALL = new TimeDefinition(1,"WALL");
            mixin(MakeGlobalVar!(TimeDefinition)("WALL",`new TimeDefinition(1,"WALL")`));

            // STANDARD = new TimeDefinition(2,"STANDARD");
            mixin(MakeGlobalVar!(TimeDefinition)("STANDARD",`new TimeDefinition(2,"STANDARD")`));

           
        // }

        static ref  TimeDefinition[] values()
        {
            if(_values.length == 0)
            {
                 _values ~= UTC;
                _values ~= WALL;
                _values ~= STANDARD;
            }
            return _values;
        }

        public int ordinal()
        {
            return _ordinal;
        }
        public string name()
        {
            return _name;
        }
        this(int ordinal , string name)
        {
            _ordinal = ordinal;
            _name = name;
        }
        public LocalDateTime createDateTime(LocalDateTime dateTime, ZoneOffset standardOffset, ZoneOffset wallOffset) {
            auto name = this.name();
            switch (name) {
                case "UTC": {
                    int difference = wallOffset.getTotalSeconds() - ZoneOffset.UTC.getTotalSeconds();
                    return dateTime.plusSeconds(difference);
                }
                case "STANDARD": {
                    int difference = wallOffset.getTotalSeconds() - standardOffset.getTotalSeconds();
                    return dateTime.plusSeconds(difference);
                }
                default:  // WALL
                    return dateTime;
            }
        }
    }

}
