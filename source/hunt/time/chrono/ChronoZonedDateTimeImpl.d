
module hunt.time.chrono.ChronoZonedDateTimeImpl;

import hunt.time.temporal.ChronoUnit;

import hunt.lang.exception;
import hunt.lang;
import hunt.io.ObjectInput;
import hunt.util.Comparator;
import hunt.io.ObjectOutput;
import hunt.io.common;
import hunt.time.Instant;
import hunt.time.LocalDateTime;
import hunt.time.ZoneId;
import hunt.time.ZoneOffset;
import hunt.time.temporal.ChronoField;
import hunt.time.temporal.ChronoUnit;
import hunt.time.temporal.Temporal;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.TemporalUnit;
import hunt.time.zone.ZoneOffsetTransition;
import hunt.time.zone.ZoneRules;
import hunt.container.List;
import hunt.time.chrono.ChronoLocalDate;
import hunt.time.chrono.ChronoZonedDateTime;
import hunt.time.chrono.ChronoLocalDateTimeImpl;
import hunt.time.chrono.Chronology;
import hunt.time.chrono.ChronoLocalDateTime;
import hunt.time.temporal.TemporalAdjuster;
import hunt.time.chrono.Ser;
import hunt.time.temporal.ValueRange;
import hunt.time.temporal.TemporalAmount;
import std.conv;
import hunt.time.temporal.UnsupportedTemporalTypeException;
import hunt.time.DateTimeException;
import hunt.time.format.DateTimeFormatter;
import hunt.time.LocalTime;
/**
 * A date-time with a time-zone _in the calendar neutral API.
 * !(p)
 * {@code ZoneChronoDateTime} is an immutable representation of a date-time with a time-zone.
 * This class stores all date and time fields, to a precision of nanoseconds,
 * as well as a time-zone and zone offset.
 * !(p)
 * The purpose of storing the time-zone is to distinguish the ambiguous case where
 * the local time-line overlaps, typically as a result of the end of daylight time.
 * Information about the local-time can be obtained using methods on the time-zone.
 *
 * @implSpec
 * This class is immutable and thread-safe.
 *
 * @serial Document the delegation of this class _in the serialized-form specification.
 * @param !(D) the concrete type for the date of this date-time
 * @since 1.8
 */
final class ChronoZonedDateTimeImpl(D = ChronoLocalDate) if(is(D : ChronoLocalDate))
        : ChronoZonedDateTime!(D), Serializable {

    /**
     * Serialization version.
     */
    private enum long serialVersionUID = -5261813987200935591L;

    /**
     * The local date-time.
     */
    private  /*transient*/ ChronoLocalDateTimeImpl!(D) dateTime;
    /**
     * The zone offset.
     */
    private  /*transient*/ ZoneOffset offset;
    /**
     * The zone ID.
     */
    private  /*transient*/ ZoneId zone;

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance from a local date-time using the preferred offset if possible.
     *
     * @param localDateTime  the local date-time, not null
     * @param zone  the zone identifier, not null
     * @param preferredOffset  the zone offset, null if no preference
     * @return the zoned date-time, not null
     */
    static ChronoZonedDateTime!(R) ofBest(R)(
            ChronoLocalDateTimeImpl!(R) localDateTime, ZoneId zone, ZoneOffset preferredOffset) /* if(is(R : ChronoLocalDate)) */ {
        assert(localDateTime, "localDateTime");
        assert(zone, "zone");
        if (cast(ZoneOffset)(zone) !is null) {
            return new ChronoZonedDateTimeImpl!()(localDateTime, cast(ZoneOffset) zone, zone);
        }
        ZoneRules rules = zone.getRules();
        LocalDateTime isoLDT = LocalDateTime.from(localDateTime);
        List!(ZoneOffset) validOffsets = rules.getValidOffsets(isoLDT);
        ZoneOffset offset;
        if (validOffsets.size() == 1) {
            offset = validOffsets.get(0);
        } else if (validOffsets.size() == 0) {
            ZoneOffsetTransition trans = rules.getTransition(isoLDT);
            localDateTime = localDateTime.plusSeconds(trans.getDuration().getSeconds());
            offset = trans.getOffsetAfter();
        } else {
            if (preferredOffset !is null && validOffsets.contains(preferredOffset)) {
                offset = preferredOffset;
            } else {
                offset = validOffsets.get(0);
            }
        }
        assert(offset, "offset");  // protect against bad ZoneRules
        return new ChronoZonedDateTimeImpl!()(localDateTime, offset, zone);
    }

    /**
     * Obtains an instance from an instant using the specified time-zone.
     *
     * @param chrono  the chronology, not null
     * @param instant  the instant, not null
     * @param zone  the zone identifier, not null
     * @return the zoned date-time, not null
     */
    static ChronoZonedDateTimeImpl!(ChronoLocalDate) ofInstant(Chronology chrono, Instant instant, ZoneId zone) {
        ZoneRules rules = zone.getRules();
        ZoneOffset offset = rules.getOffset(instant);
        assert(offset, "offset");  // protect against bad ZoneRules
        LocalDateTime ldt = LocalDateTime.ofEpochSecond(instant.getEpochSecond(), instant.getNano(), offset);
        ChronoLocalDateTimeImpl!(ChronoLocalDate) cldt = cast(ChronoLocalDateTimeImpl!(ChronoLocalDate))chrono.localDateTime(ldt);
        return new ChronoZonedDateTimeImpl!(ChronoLocalDate)(cldt, offset, zone);
    }

    /**
     * Obtains an instance from an {@code Instant}.
     *
     * @param instant  the instant to create the date-time from, not null
     * @param zone  the time-zone to use, validated not null
     * @return the zoned date-time, validated not null
     */
    /*@SuppressWarnings("unchecked")*/
    private ChronoZonedDateTimeImpl!(D) create(Instant instant, ZoneId zone) {
        return cast(ChronoZonedDateTimeImpl!(D))ofInstant(getChronology(), instant, zone);
    }

    /**
     * Casts the {@code Temporal} to {@code ChronoZonedDateTimeImpl} ensuring it bas the specified chronology.
     *
     * @param chrono  the chronology to check for, not null
     * @param temporal  a date-time to cast, not null
     * @return the date-time checked and cast to {@code ChronoZonedDateTimeImpl}, not null
     * @throws ClassCastException if the date-time cannot be cast to ChronoZonedDateTimeImpl
     *  or the chronology is not equal this Chronology
     */
    static  ChronoZonedDateTimeImpl!(R) ensureValid(R)(Chronology chrono, Temporal temporal) {
        /*@SuppressWarnings("unchecked")*/
        ChronoZonedDateTimeImpl!(R) other = cast(ChronoZonedDateTimeImpl!(R))temporal;
        if ((chrono == other.getChronology()) == false) {
            throw new ClassCastException("Chronology mismatch, required: " ~ chrono.getId()
                    ~ ", actual: " ~ other.getChronology().getId());
        }
        return other;
    }

    //-----------------------------------------------------------------------
    /**
     * Constructor.
     *
     * @param dateTime  the date-time, not null
     * @param offset  the zone offset, not null
     * @param zone  the zone ID, not null
     */
    private this(ChronoLocalDateTimeImpl!(D) dateTime, ZoneOffset offset, ZoneId zone) {
        this.dateTime = dateTime;
        this.offset = offset;
        this.zone = zone;
    }

    //-----------------------------------------------------------------------
    override
    public ZoneOffset getOffset() {
        return offset;
    }

    override
    public ChronoZonedDateTime!(D) withEarlierOffsetAtOverlap() {
        ZoneOffsetTransition trans = getZone().getRules().getTransition(LocalDateTime.from(this));
        if (trans !is null && trans.isOverlap()) {
            ZoneOffset earlierOffset = trans.getOffsetBefore();
            if ((earlierOffset  == offset) == false) {
                return new ChronoZonedDateTimeImpl!()(dateTime, earlierOffset, zone);
            }
        }
        return this;
    }

    override
    public ChronoZonedDateTime!(D) withLaterOffsetAtOverlap() {
        ZoneOffsetTransition trans = getZone().getRules().getTransition(LocalDateTime.from(this));
        if (trans !is null) {
            ZoneOffset offset = trans.getOffsetAfter();
            if ((offset == getOffset()) == false) {
                return new ChronoZonedDateTimeImpl!(D)(dateTime, offset, zone);
            }
        }
        return this;
    }

    //-----------------------------------------------------------------------
    override
    public ChronoLocalDateTime!(D) toLocalDateTime() {
        return dateTime;
    }

    override
    public ZoneId getZone() {
        return zone;
    }

    override
    public ChronoZonedDateTime!(D) withZoneSameLocal(ZoneId zone) {
        return ofBest(dateTime, zone, offset);
    }

    override
    public ChronoZonedDateTime!(D) withZoneSameInstant(ZoneId zone) {
        assert(zone, "zone");
        return this.zone == (zone) ? this : create(dateTime.toInstant(offset), zone);
    }

    //-----------------------------------------------------------------------
    override
    public bool isSupported(TemporalField field) {
        return cast(ChronoField)(field) !is null || (field !is null && field.isSupportedBy(this));
    }

    //-----------------------------------------------------------------------
    override
    public ChronoZonedDateTime!(D) _with(TemporalField field, long newValue) {
        if (cast(ChronoField)(field) !is null) {
            ChronoField f = cast(ChronoField) field;
            {
                if( f == ChronoField.INSTANT_SECONDS) return plus(newValue - toEpochSecond(), ChronoUnit.SECONDS);
                if( f == ChronoField.OFFSET_SECONDS) {
                    ZoneOffset offset = ZoneOffset.ofTotalSeconds(f.checkValidIntValue(newValue));
                    return create(dateTime.toInstant(offset), zone);
                }
            }
            return ofBest(dateTime._with(field, newValue), zone, offset);
        }
        return ChronoZonedDateTimeImpl!D.ensureValid!D(getChronology(), field.adjustInto(this, newValue));
    }

    //-----------------------------------------------------------------------
    override
    public ChronoZonedDateTime!(D) plus(long amountToAdd, TemporalUnit unit) {
        if (cast(ChronoUnit)(unit) !is null) {
            return super_with(dateTime.plus(amountToAdd, unit));
        }
        return ChronoZonedDateTimeImpl!D.ensureValid!D(getChronology(), unit.addTo(this, amountToAdd));   /// TODO: Generics replacement Risk!
    }
     ChronoZonedDateTime!(D) super_with(TemporalAdjuster adjuster) {
        return ChronoZonedDateTimeImpl!D.ensureValid!D(getChronology(), adjuster.adjustInto(this));
    }

    //-----------------------------------------------------------------------
    override
    public long until(Temporal endExclusive, TemporalUnit unit) {
        assert(endExclusive, "endExclusive");
        /*@SuppressWarnings("unchecked")*/
        ChronoZonedDateTime!(D) end = cast(ChronoZonedDateTime!(D)) getChronology().zonedDateTime(endExclusive);
        if (cast(ChronoUnit)(unit) !is null) {
            end = end.withZoneSameInstant(offset);
            return dateTime.until(end.toLocalDateTime(), unit);
        }
        assert(unit, "unit");
        return unit.between(this, end);
    }

    //-----------------------------------------------------------------------
    /**
     * Writes the ChronoZonedDateTime using a
     * <a href="{@docRoot}/serialized-form.html#hunt.time.chrono.Ser">dedicated serialized form</a>.
     * @serialData
     * !(pre)
     *  _out.writeByte(3);                  // identifies a ChronoZonedDateTime
     *  _out.writeObject(toLocalDateTime());
     *  _out.writeObject(getOffset());
     *  _out.writeObject(getZone());
     * </pre>
     *
     * @return the instance of {@code Ser}, not null
     */
    private Object writeReplace() {
        return new Ser(Ser.CHRONO_ZONE_DATE_TIME_TYPE, this);
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
        _out.writeObject(dateTime);
        _out.writeObject(offset);
        _out.writeObject(zone);
    }

    static ChronoZonedDateTime!(ChronoLocalDate) readExternal(ObjectInput _in) /*throws IOException, ClassNotFoundException */{
        ChronoLocalDateTime!(ChronoLocalDate) dateTime = cast(ChronoLocalDateTime!(ChronoLocalDate)) _in.readObject();
        ZoneOffset offset = cast(ZoneOffset) _in.readObject();
        ZoneId zone = cast(ZoneId) _in.readObject();
        return dateTime.atZone(offset).withZoneSameLocal(zone);
        // TODO: ZDT uses ofLenient()
    }

    //-------------------------------------------------------------------------
    override
    public bool opEquals(Object obj) {
        if (this is obj) {
            return true;
        }
        if (cast(ChronoZonedDateTime!D)(obj) !is null) {
            return compareTo(cast(ChronoZonedDateTime!(D)) obj) == 0;
        }
        return false;
    }

    override
    public size_t toHash() @trusted nothrow {
        try{
            return toLocalDateTime().toHash() ^ getOffset().toHash() ^ Integer.rotateLeft(cast(int)(getZone().toHash()), 3);
        }catch(Exception e){
            return int.init;
        }
    }

    override
    public string toString() {
        string str = toLocalDateTime().toString() ~ getOffset().toString();
        if (getOffset() != getZone()) {
            str ~= '[' ~ getZone().toString() ~ ']';
        }
        return str;
    }

    override
     ValueRange range(TemporalField field) {
        if (cast(ChronoField)(field) !is null) {
            if (field == ChronoField.INSTANT_SECONDS || field == ChronoField.OFFSET_SECONDS) {
                return field.range();
            }
            return toLocalDateTime().range(field);
        }
        return field.rangeRefinedBy(this);
    }
	
	override
     int get(TemporalField field) {
        if (cast(ChronoField)(field) !is null) {
            auto f = cast(ChronoField) field;
            {
                if( f == ChronoField.INSTANT_SECONDS)
                    throw new UnsupportedTemporalTypeException("Invalid field 'InstantSeconds' for get() method, use getLong() instead");
                if( f == ChronoField.OFFSET_SECONDS)
                    return getOffset().getTotalSeconds();
            }
            return toLocalDateTime().get(field);
        }
        return /* Temporal. */super_get(field);
    }

     int super_get(TemporalField field) {
        ValueRange range = range(field);
        if (range.isIntValue() == false) {
            throw new UnsupportedTemporalTypeException("Invalid field " ~ field.toString ~ " for get() method, use getLong() instead");
        }
        long value = getLong(field);
        if (range.isValidValue(value) == false) {
            throw new DateTimeException("Invalid value for " ~ field.toString ~ " (valid values " ~ range.toString ~ "): " ~ value.to!string);
        }
        return cast(int) value;
    }
	
	override
     long getLong(TemporalField field) {
        if (cast(ChronoField)(field) !is null) {
            auto f = cast(ChronoField) field;
            {
                if ( f == ChronoField.INSTANT_SECONDS) return toEpochSecond();
                if ( f == ChronoField.OFFSET_SECONDS)return getOffset().getTotalSeconds();
            }
            return toLocalDateTime().getLong(field);
        }
        return field.getFrom(this);
    }
	 override
     bool isSupported(TemporalUnit unit) {
        if (cast(ChronoUnit)(unit) !is null) {
            return unit != ChronoUnit.FOREVER;
        }
        return unit !is null && unit.isSupportedBy(this);
    }
	
	override
     ChronoZonedDateTime!(D) _with(TemporalAdjuster adjuster) {
        return ChronoZonedDateTimeImpl!D.ensureValid!D(getChronology(), /* Temporal. */adjuster.adjustInto(this));
    }
	
	override
     ChronoZonedDateTime!(D) plus(TemporalAmount amount) {
        return ChronoZonedDateTimeImpl!D.ensureValid!D(getChronology(), /* Temporal. */amount.addTo(this));
    }
	override
     ChronoZonedDateTime!(D) minus(TemporalAmount amount) {
        return ChronoZonedDateTimeImpl!D.ensureValid!D(getChronology(), /* Temporal. */amount.subtractFrom(this));
    }

	 override
     ChronoZonedDateTime!(D) minus(long amountToSubtract, TemporalUnit unit) {
        return ChronoZonedDateTimeImpl!D.ensureValid!D(getChronology(), /* Temporal. */(amountToSubtract == Long.MIN_VALUE ? plus(Long.MAX_VALUE, unit).plus(1, unit) : plus(-amountToSubtract, unit)));
    }

    override
     int compareTo(ChronoZonedDateTime!(ChronoLocalDate) other) {
        int cmp = compare(toEpochSecond(), other.toEpochSecond());
        if (cmp == 0) {
            cmp = toLocalTime().getNano() - other.toLocalTime().getNano();
            if (cmp == 0) {
                cmp = toLocalDateTime().compareTo(other.toLocalDateTime());
                if (cmp == 0) {
                    cmp = getZone().getId().compare(other.getZone().getId());
                    if (cmp == 0) {
                        cmp = getChronology().compareTo(other.getChronology());
                    }
                }
            }
        }
        return cmp;
    }

    override
     int opCmp(ChronoZonedDateTime!(ChronoLocalDate) other) {
        int cmp = compare(toEpochSecond(), other.toEpochSecond());
        if (cmp == 0) {
            cmp = toLocalTime().getNano() - other.toLocalTime().getNano();
            if (cmp == 0) {
                cmp = toLocalDateTime().compareTo(other.toLocalDateTime());
                if (cmp == 0) {
                    cmp = getZone().getId().compare(other.getZone().getId());
                    if (cmp == 0) {
                        cmp = getChronology().compareTo(other.getChronology());
                    }
                }
            }
        }
        return cmp;
    }
    
    override
	 bool isBefore(ChronoZonedDateTime!(ChronoLocalDate) other) {
        long thisEpochSec = toEpochSecond();
        long otherEpochSec = other.toEpochSecond();
        return thisEpochSec < otherEpochSec ||
            (thisEpochSec == otherEpochSec && toLocalTime().getNano() < other.toLocalTime().getNano());
    }
	
    override
	 bool isAfter(ChronoZonedDateTime!(ChronoLocalDate) other) {
        long thisEpochSec = toEpochSecond();
        long otherEpochSec = other.toEpochSecond();
        return thisEpochSec > otherEpochSec ||
            (thisEpochSec == otherEpochSec && toLocalTime().getNano() > other.toLocalTime().getNano());
    }
	
    override
	 bool isEqual(ChronoZonedDateTime!(ChronoLocalDate) other) {
        return toEpochSecond() == other.toEpochSecond() &&
                toLocalTime().getNano() == other.toLocalTime().getNano();
    }
	
    override
	 long toEpochSecond() {
        long epochDay = toLocalDate().toEpochDay();
        long secs = epochDay * 86400 + toLocalTime().toSecondOfDay();
        secs -= getOffset().getTotalSeconds();
        return secs;
    }
	
    override
	 Instant toInstant() {
        return Instant.ofEpochSecond(toEpochSecond(), toLocalTime().getNano());
    }
	
    override
	 string format(DateTimeFormatter formatter) {
        assert(formatter, "formatter");
        return formatter.format(this);
    }
	
    override
	 LocalTime toLocalTime() {
        return toLocalDateTime().toLocalTime();
    }
	
    override
	 D toLocalDate() {
        return toLocalDateTime().toLocalDate();
    }

    override
     Chronology getChronology() {
        return toLocalDate().getChronology();
    }
}
