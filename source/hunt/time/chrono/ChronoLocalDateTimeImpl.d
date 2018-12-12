
module hunt.time.chrono.ChronoLocalDateTimeImpl;

import hunt.time.temporal.ChronoField;

import hunt.lang.exception;
import hunt.io.ObjectInput;
//import hunt.io.ObjectInputStream;
import hunt.io.ObjectOutput;
import hunt.io.Serializable;
import hunt.time.LocalTime;
import hunt.time.ZoneId;
import hunt.time.temporal.ChronoField;
import hunt.time.temporal.ChronoUnit;
import hunt.time.temporal.Temporal;
import hunt.time.temporal.TemporalAdjuster;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.TemporalUnit;
import hunt.time.temporal.ValueRange;
import hunt.time.chrono.ChronoLocalDate;
import hunt.time.chrono.ChronoLocalDateTime;
import hunt.time.chrono.Chronology;
import hunt.time.chrono.ChronoZonedDateTime;
import hunt.time.chrono.ChronoLocalDateImpl;
import hunt.lang;
import hunt.time.chrono.ChronoZonedDateTimeImpl;
import hunt.time.chrono.Ser;
import hunt.time.temporal.TemporalAmount;
import hunt.time.format.DateTimeFormatter;
import hunt.time.Instant;
import hunt.time.ZoneOffset;
/**
 * A date-time without a time-zone for the calendar neutral API.
 * !(p)
 * {@code ChronoLocalDateTime} is an immutable date-time object that represents a date-time, often
 * viewed as year-month-day-hour-minute-second. This object can also access other
 * fields such as day-of-year, day-of-week and week-of-year.
 * !(p)
 * This class stores all date and time fields, to a precision of nanoseconds.
 * It does not store or represent a time-zone. For example, the value
 * "2nd October 2007 at 13:45.30.123456789" can be stored _in an {@code ChronoLocalDateTime}.
 *
 * @implSpec
 * This class is immutable and thread-safe.
 * @serial
 * @param !(D) the concrete type for the date of this date-time
 * @since 1.8
 */
final class ChronoLocalDateTimeImpl(D = ChronoLocalDate) if(is(D : ChronoLocalDate))
        :  ChronoLocalDateTime!(D), Temporal, TemporalAdjuster, Serializable {

    /**
     * Serialization version.
     */
    private enum long serialVersionUID = 4556003607393004514L;
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
     * Nanos per second.
     */
    enum long NANOS_PER_SECOND = 1000_000_000L;
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
     * The date part.
     */
    private  /*transient*/ D date;
    /**
     * The time part.
     */
    private  /*transient*/ LocalTime time;

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code ChronoLocalDateTime} from a date and time.
     *
     * @param date  the local date, not null
     * @param time  the local time, not null
     * @return the local date-time, not null
     */
    static ChronoLocalDateTimeImpl!(R) of(R)(R date, LocalTime time) {
        return new ChronoLocalDateTimeImpl!(R)(date, time);
    }

    /**
     * Casts the {@code Temporal} to {@code ChronoLocalDateTime} ensuring it bas the specified chronology.
     *
     * @param chrono  the chronology to check for, not null
     * @param temporal   a date-time to cast, not null
     * @return the date-time checked and cast to {@code ChronoLocalDateTime}, not null
     * @throws ClassCastException if the date-time cannot be cast to ChronoLocalDateTimeImpl
     *  or the chronology is not equal this Chronology
     */
    static ChronoLocalDateTimeImpl!(R) ensureValid(R)(Chronology chrono, Temporal temporal) {
        /*@SuppressWarnings("unchecked")*/
        ChronoLocalDateTimeImpl!(R) other = cast(ChronoLocalDateTimeImpl!(R))temporal;
        if ((chrono == other.getChronology()) == false) {
            throw new ClassCastException("Chronology mismatch, required: " ~ chrono.getId()
                    ~ ", actual: " ~ other.getChronology().getId());
        }
        return other;
    }

    /**
     * Constructor.
     *
     * @param date  the date part of the date-time, not null
     * @param time  the time part of the date-time, not null
     */
    private this(D date, LocalTime time) {
        assert(date, "date");
        assert(time, "time");
        this.date = date;
        this.time = time;
    }

    /**
     * Returns a copy of this date-time with the new date and time, checking
     * to see if a new object is _in fact required.
     *
     * @param newDate  the date of the new date-time, not null
     * @param newTime  the time of the new date-time, not null
     * @return the date-time, not null
     */
    private ChronoLocalDateTimeImpl!(D) _with(Temporal newDate, LocalTime newTime) {
        if (date == newDate && time == newTime) {
            return this;
        }
        // Validate that the new Temporal is a ChronoLocalDate (and not something else)
        D cd = ChronoLocalDateImpl!(D).ensureValid!D(date.getChronology(), newDate);
        return new ChronoLocalDateTimeImpl!(D)(cd, newTime);
    }

    //-----------------------------------------------------------------------
    override
    public D toLocalDate() {
        return date;
    }

    override
    public LocalTime toLocalTime() {
        return time;
    }

    //-----------------------------------------------------------------------
    override
    public bool isSupported(TemporalField field) {
        if (cast(ChronoField)(field) !is null) {
            ChronoField f = cast(ChronoField) field;
            return f.isDateBased() || f.isTimeBased();
        }
        return field !is null && field.isSupportedBy(this);
    }

    override
     bool isSupported(TemporalUnit unit) {
        if (cast(ChronoUnit)(unit) !is null) {
            return unit != ChronoUnit.FOREVER;
        }
        return unit !is null && unit.isSupportedBy(this);
    }

    override
     ChronoLocalDateTime!(D) plus(TemporalAmount amount) {
        return ChronoLocalDateTimeImpl!D.ensureValid!D(getChronology(), /* Temporal. */amount.addTo(this));
    }

    override
     ChronoLocalDateTime!(D) minus(TemporalAmount amount) {
        return ChronoLocalDateTimeImpl!D.ensureValid!D(getChronology(), /* Temporal. */amount.subtractFrom(this));
    }

    override
     ChronoLocalDateTime!(D) minus(long amountToSubtract, TemporalUnit unit) {
        return ChronoLocalDateTimeImpl!D.ensureValid!D(getChronology(), /* Temporal. */(amountToSubtract == Long.MIN_VALUE ? plus(Long.MAX_VALUE, unit).plus(1, unit) : plus(-amountToSubtract, unit)));
    }
    override
     Chronology getChronology() {
        return toLocalDate().getChronology();
    }

    override
     Temporal adjustInto(Temporal temporal) {
        return temporal
                ._with(ChronoField.EPOCH_DAY, toLocalDate().toEpochDay())
                ._with(ChronoField.NANO_OF_DAY, toLocalTime().toNanoOfDay());
    }
    override
     string format(DateTimeFormatter formatter) {
        assert(formatter, "formatter");
        return formatter.format(this);
    }
    override
     Instant toInstant(ZoneOffset offset) {
        return Instant.ofEpochSecond(toEpochSecond(offset), toLocalTime().getNano());
    }
    override
     long toEpochSecond(ZoneOffset offset) {
        assert(offset, "offset");
        long epochDay = toLocalDate().toEpochDay();
        long secs = epochDay * 86400 + toLocalTime().toSecondOfDay();
        secs -= offset.getTotalSeconds();
        return secs;
    }

    override
     int compareTo(ChronoLocalDateTime!(ChronoLocalDate) other) {
        int cmp = toLocalDate().compareTo(other.toLocalDate());
        if (cmp == 0) {
            cmp = toLocalTime().compareTo(other.toLocalTime());
            if (cmp == 0) {
                cmp = getChronology().compareTo(other.getChronology());
            }
        }
        return cmp;
    }
    override
     int opCmp(ChronoLocalDateTime!(ChronoLocalDate) other) {
        int cmp = toLocalDate().compareTo(other.toLocalDate());
        if (cmp == 0) {
            cmp = toLocalTime().compareTo(other.toLocalTime());
            if (cmp == 0) {
                cmp = getChronology().compareTo(other.getChronology());
            }
        }
        return cmp;
    }
    override
     bool isAfter(ChronoLocalDateTime!(ChronoLocalDate) other) {
        long thisEpDay = this.toLocalDate().toEpochDay();
        long otherEpDay = other.toLocalDate().toEpochDay();
        return thisEpDay > otherEpDay ||
            (thisEpDay == otherEpDay && this.toLocalTime().toNanoOfDay() > other.toLocalTime().toNanoOfDay());
    }
    override
     bool isBefore(ChronoLocalDateTime!(ChronoLocalDate) other) {
        long thisEpDay = this.toLocalDate().toEpochDay();
        long otherEpDay = other.toLocalDate().toEpochDay();
        return thisEpDay < otherEpDay ||
            (thisEpDay == otherEpDay && this.toLocalTime().toNanoOfDay() < other.toLocalTime().toNanoOfDay());
    }
    override
     bool isEqual(ChronoLocalDateTime!(ChronoLocalDate) other) {
        // Do the time check first, it is cheaper than computing EPOCH day.
        return this.toLocalTime().toNanoOfDay() == other.toLocalTime().toNanoOfDay() &&
               this.toLocalDate().toEpochDay() == other.toLocalDate().toEpochDay();
    }

    override
    public ValueRange range(TemporalField field) {
        if (cast(ChronoField)(field) !is null) {
            ChronoField f = cast(ChronoField) field;
            return (f.isTimeBased() ? time.range(field) : date.range(field));
        }
        return field.rangeRefinedBy(this);
    }

    override
    public int get(TemporalField field) {
        if (cast(ChronoField)(field) !is null) {
            ChronoField f = cast(ChronoField) field;
            return (f.isTimeBased() ? time.get(field) : date.get(field));
        }
        return range(field).checkValidIntValue(getLong(field), field);
    }

    override
    public long getLong(TemporalField field) {
        if (cast(ChronoField)(field) !is null) {
            ChronoField f = cast(ChronoField) field;
            return (f.isTimeBased() ? time.getLong(field) : date.getLong(field));
        }
        return field.getFrom(this);
    }

    //-----------------------------------------------------------------------
    /*@SuppressWarnings("unchecked")*/
    override
    public ChronoLocalDateTimeImpl!(D) _with(TemporalAdjuster adjuster) {
        if (cast(ChronoLocalDate)(adjuster) !is null) {
            // The Chronology is checked _in _with(date,time)
            return _with(cast(ChronoLocalDate) adjuster, time);
        } else if (cast(LocalTime)(adjuster) !is null) {
            return _with(date, cast(LocalTime) adjuster);
        } else if (cast(ChronoLocalDateTimeImpl!D)(adjuster) !is null) {
            return ChronoLocalDateTimeImpl!D.ensureValid!D(date.getChronology(), cast(ChronoLocalDateTimeImpl!(ChronoLocalDate)) adjuster);
        }
        return ChronoLocalDateTimeImpl!D.ensureValid!D(date.getChronology(), cast(ChronoLocalDateTimeImpl!(ChronoLocalDate)) adjuster.adjustInto(this));
    }

    override
    public ChronoLocalDateTimeImpl!(D) _with(TemporalField field, long newValue) {
        if (cast(ChronoField)(field) !is null) {
            ChronoField f = cast(ChronoField) field;
            if (f.isTimeBased()) {
                return _with(date, time._with(field, newValue));
            } else {
                return _with(date._with(field, newValue), time);
            }
        }
        return ChronoLocalDateTimeImpl!D.ensureValid!D(date.getChronology(), field.adjustInto(this, newValue));
    }

    //-----------------------------------------------------------------------
    override
    public ChronoLocalDateTimeImpl!(D) plus(long amountToAdd, TemporalUnit unit) {
        if (cast(ChronoUnit)(unit) !is null) {
            ChronoUnit f = cast(ChronoUnit) unit;
            {
                if( f == ChronoUnit.NANOS) return plusNanos(amountToAdd);
                if( f == ChronoUnit.MICROS) return plusDays(amountToAdd / LocalTime.MICROS_PER_DAY).plusNanos((amountToAdd % LocalTime.MICROS_PER_DAY) * 1000);
                if( f == ChronoUnit.MILLIS) return plusDays(amountToAdd / LocalTime.MILLIS_PER_DAY).plusNanos((amountToAdd % LocalTime.MILLIS_PER_DAY) * 1000000);
                if( f == ChronoUnit.SECONDS) return plusSeconds(amountToAdd);
                if( f == ChronoUnit.MINUTES) return plusMinutes(amountToAdd);
                if( f == ChronoUnit.HOURS) return plusHours(amountToAdd);
                if( f == ChronoUnit.HALF_DAYS) return plusDays(amountToAdd / 256).plusHours((amountToAdd % 256) * 12);  // no overflow (256 is multiple of 2)
            }
            return _with(date.plus(amountToAdd, unit), time);
        }
        return ChronoLocalDateTimeImpl!D.ensureValid!D(date.getChronology(), unit.addTo(this, amountToAdd));
    }

    private ChronoLocalDateTimeImpl!(D) plusDays(long days) {
        return _with(date.plus(days, ChronoUnit.DAYS), time);
    }

    private ChronoLocalDateTimeImpl!(D) plusHours(long hours) {
        return plusWithOverflow(date, hours, 0, 0, 0);
    }

    private ChronoLocalDateTimeImpl!(D) plusMinutes(long minutes) {
        return plusWithOverflow(date, 0, minutes, 0, 0);
    }

    ChronoLocalDateTimeImpl!(D) plusSeconds(long seconds) {
        return plusWithOverflow(date, 0, 0, seconds, 0);
    }

    private ChronoLocalDateTimeImpl!(D) plusNanos(long nanos) {
        return plusWithOverflow(date, 0, 0, 0, nanos);
    }

    //-----------------------------------------------------------------------
    private ChronoLocalDateTimeImpl!(D) plusWithOverflow(D newDate, long hours, long minutes, long seconds, long nanos) {
        // 9223372036854775808 long, 2147483648 int
        if ((hours | minutes | seconds | nanos) == 0) {
            return _with(newDate, time);
        }
        long totDays = nanos / NANOS_PER_DAY +             //   max/24*60*60*1B
                seconds / SECONDS_PER_DAY +                //   max/24*60*60
                minutes / MINUTES_PER_DAY +                //   max/24*60
                hours / HOURS_PER_DAY;                     //   max/24
        long totNanos = nanos % NANOS_PER_DAY +                    //   max  86400000000000
                (seconds % SECONDS_PER_DAY) * NANOS_PER_SECOND +   //   max  86400000000000
                (minutes % MINUTES_PER_DAY) * NANOS_PER_MINUTE +   //   max  86400000000000
                (hours % HOURS_PER_DAY) * NANOS_PER_HOUR;          //   max  86400000000000
        long curNoD = time.toNanoOfDay();                          //   max  86400000000000
        totNanos = totNanos + curNoD;                              // total 432000000000000
        totDays += Math.floorDiv(totNanos, NANOS_PER_DAY);
        long newNoD = Math.floorMod(totNanos, NANOS_PER_DAY);
        LocalTime newTime = (newNoD == curNoD ? time : LocalTime.ofNanoOfDay(newNoD));
        return _with(newDate.plus(totDays, ChronoUnit.DAYS), newTime);
    }

    //-----------------------------------------------------------------------
    override
    public ChronoZonedDateTime!(D) atZone(ZoneId zone) {
        return ChronoZonedDateTimeImpl!(D).ofBest!(D)(this, zone, null);
    }

    //-----------------------------------------------------------------------
    override
    public long until(Temporal endExclusive, TemporalUnit unit) {
        assert(endExclusive, "endExclusive");
        /*@SuppressWarnings("unchecked")*/
        ChronoLocalDateTime!(D) end = cast(ChronoLocalDateTime!(D)) getChronology().localDateTime(endExclusive);
        if (cast(ChronoUnit)(unit) !is null) {
            if (unit.isTimeBased()) {
                long amount = end.getLong(ChronoField.EPOCH_DAY) - date.getLong(ChronoField.EPOCH_DAY);
                auto f = cast(ChronoUnit) unit;
                {
                    if( f == ChronoUnit.NANOS) amount = Math.multiplyExact(amount, NANOS_PER_DAY); 
                    if( f == ChronoUnit.MICROS) amount = Math.multiplyExact(amount, MICROS_PER_DAY); 
                    if( f == ChronoUnit.MILLIS) amount = Math.multiplyExact(amount, MILLIS_PER_DAY); 
                    if( f == ChronoUnit.SECONDS) amount = Math.multiplyExact(amount, SECONDS_PER_DAY); 
                    if( f == ChronoUnit.MINUTES) amount = Math.multiplyExact(amount, MINUTES_PER_DAY); 
                    if( f == ChronoUnit.HOURS) amount = Math.multiplyExact(amount, HOURS_PER_DAY); 
                    if( f == ChronoUnit.HALF_DAYS) amount = Math.multiplyExact(amount, 2); 
                }
                return Math.addExact(amount, time.until(end.toLocalTime(), unit));
            }
            ChronoLocalDate endDate = end.toLocalDate();
            if (end.toLocalTime().isBefore(time)) {
                endDate = endDate.minus(1, ChronoUnit.DAYS);
            }
            return date.until(endDate, unit);
        }
        assert(unit, "unit");
        return unit.between(this, end);
    }

    //-----------------------------------------------------------------------
    /**
     * Writes the ChronoLocalDateTime using a
     * <a href="{@docRoot}/serialized-form.html#hunt.time.chrono.Ser">dedicated serialized form</a>.
     * @serialData
     * !(pre)
     *  _out.writeByte(2);              // identifies a ChronoLocalDateTime
     *  _out.writeObject(toLocalDate());
     *  _out.witeObject(toLocalTime());
     * </pre>
     *
     * @return the instance of {@code Ser}, not null
     */
    private Object writeReplace() {
        return new Ser(Ser.CHRONO_LOCAL_DATE_TIME_TYPE, this);
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

    void writeExternal(ObjectOutput _out) /*throws IOException*/ {
        _out.writeObject(cast(Object)date);
        _out.writeObject(time);
    }

    static ChronoLocalDateTime!(ChronoLocalDate) readExternal(ObjectInput _in) /*throws IOException, ClassNotFoundException*/ {
        ChronoLocalDate date = cast(ChronoLocalDate) _in.readObject();
        LocalTime time = cast(LocalTime) _in.readObject();
        return date.atTime(time);
    }

    //-----------------------------------------------------------------------
    override
    public bool opEquals(Object obj) {
        if (this is obj) {
            return true;
        }
        if (cast(ChronoLocalDateTime!D)(obj) !is null) {
            return compareTo(cast(ChronoLocalDateTime!(D)) obj) == 0;
        }
        return false;
    }

    override
    public size_t toHash() @trusted nothrow {
        try{
            return toLocalDate().toHash() ^ toLocalTime().toHash();
        }catch(Exception e){}
        return int.init;
    }

    override
    public string toString() {
        return toLocalDate().toString() ~ 'T' ~ toLocalTime().toString();
    }

}
