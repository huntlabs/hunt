
module hunt.time.zone.ZoneOffsetTransition;

import hunt.io.DataInput;
import hunt.io.DataOutput;
import hunt.lang.exception;

//import hunt.io.ObjectInputStream;
import hunt.io.Serializable;
import hunt.time.Duration;
import hunt.time.Instant;
import hunt.time.LocalDateTime;
import hunt.time.ZoneOffset;
import hunt.time.zone.Ser;
import hunt.container.Collections;
import hunt.container;
import hunt.lang.common;
import hunt.util.Comparator;
import hunt.lang;
import hunt.string.StringBuilder;
/**
 * A transition between two offsets caused by a discontinuity _in the local time-line.
 * !(p)
 * A transition between two offsets is normally the result of a daylight savings cutover.
 * The discontinuity is normally a gap _in spring and an overlap _in autumn.
 * {@code ZoneOffsetTransition} models the transition between the two offsets.
 * !(p)
 * Gaps occur where there are local date-times that simply do not exist.
 * An example would be when the offset changes from {@code +03:00} to {@code +04:00}.
 * This might be described as 'the clocks will move forward one hour tonight at 1am'.
 * !(p)
 * Overlaps occur where there are local date-times that exist twice.
 * An example would be when the offset changes from {@code +04:00} to {@code +03:00}.
 * This might be described as 'the clocks will move back one hour tonight at 2am'.
 *
 * @implSpec
 * This class is immutable and thread-safe.
 *
 * @since 1.8
 */
public final class ZoneOffsetTransition
        : Comparable!(ZoneOffsetTransition), Serializable {

    /**
     * Serialization version.
     */
    private enum long serialVersionUID = -6946044323557704546L;
    /**
     * The transition epoch-second.
     */
    private  long epochSecond;
    /**
     * The local transition date-time at the transition.
     */
    private  LocalDateTime transition;
    /**
     * The offset before transition.
     */
    private  ZoneOffset offsetBefore;
    /**
     * The offset after transition.
     */
    private  ZoneOffset offsetAfter;

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance defining a transition between two offsets.
     * !(p)
     * Applications should normally obtain an instance from {@link ZoneRules}.
     * This factory is only intended for use when creating {@link ZoneRules}.
     *
     * @param transition  the transition date-time at the transition, which never
     *  actually occurs, expressed local to the before offset, not null
     * @param offsetBefore  the offset before the transition, not null
     * @param offsetAfter  the offset at and after the transition, not null
     * @return the transition, not null
     * @throws IllegalArgumentException if {@code offsetBefore} and {@code offsetAfter}
     *         are equal, or {@code transition.getNano()} returns non-zero value
     */
    public static ZoneOffsetTransition of(LocalDateTime transition, ZoneOffset offsetBefore, ZoneOffset offsetAfter) {
        assert(transition, "transition");
        assert(offsetBefore, "offsetBefore");
        assert(offsetAfter, "offsetAfter");
        if (offsetBefore == offsetAfter) {
            throw new IllegalArgumentException("Offsets must not be equal");
        }
        if (transition.getNano() != 0) {
            throw new IllegalArgumentException("Nano-of-second must be zero");
        }
        return new ZoneOffsetTransition(transition, offsetBefore, offsetAfter);
    }

    /**
     * Creates an instance defining a transition between two offsets.
     *
     * @param transition  the transition date-time with the offset before the transition, not null
     * @param offsetBefore  the offset before the transition, not null
     * @param offsetAfter  the offset at and after the transition, not null
     */
    this(LocalDateTime transition, ZoneOffset offsetBefore, ZoneOffset offsetAfter) {
        assert(transition.getNano() == 0);
        this.epochSecond = transition.toEpochSecond(offsetBefore);
        this.transition = transition;
        this.offsetBefore = offsetBefore;
        this.offsetAfter = offsetAfter;
    }

    /**
     * Creates an instance from epoch-second and offsets.
     *
     * @param epochSecond  the transition epoch-second
     * @param offsetBefore  the offset before the transition, not null
     * @param offsetAfter  the offset at and after the transition, not null
     */
    this(long epochSecond, ZoneOffset offsetBefore, ZoneOffset offsetAfter) {
        this.epochSecond = epochSecond;
        this.transition = LocalDateTime.ofEpochSecond(epochSecond, 0, offsetBefore);
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
     *   _out.writeByte(2);                // identifies a ZoneOffsetTransition
     *   _out.writeEpochSec(toEpochSecond);
     *   _out.writeOffset(offsetBefore);
     *   _out.writeOffset(offsetAfter);
     * }
     * </pre>
     * @return the replacing object, not null
     */
    private Object writeReplace() {
        return new Ser(Ser.ZOT, this);
    }

    /**
     * Writes the state to the stream.
     *
     * @param _out  the output stream, not null
     * @throws IOException if an error occurs
     */
    void writeExternal(DataOutput _out) /*throws IOException*/ {
        Ser.writeEpochSec(epochSecond, _out);
        Ser.writeOffset(offsetBefore, _out);
        Ser.writeOffset(offsetAfter, _out);
    }

    /**
     * Reads the state from the stream.
     *
     * @param _in  the input stream, not null
     * @return the created object, not null
     * @throws IOException if an error occurs
     */
    static ZoneOffsetTransition readExternal(DataInput _in) /*throws IOException*/ {
        long epochSecond = Ser.readEpochSec(_in);
        ZoneOffset before = Ser.readOffset(_in);
        ZoneOffset after = Ser.readOffset(_in);
        if (before == after) {
            throw new IllegalArgumentException("Offsets must not be equal");
        }
        return new ZoneOffsetTransition(epochSecond, before, after);
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the transition instant.
     * !(p)
     * This is the instant of the discontinuity, which is defined as the first
     * instant that the 'after' offset applies.
     * !(p)
     * The methods {@link #getInstant()}, {@link #getDateTimeBefore()} and {@link #getDateTimeAfter()}
     * all represent the same instant.
     *
     * @return the transition instant, not null
     */
    public Instant getInstant() {
        return Instant.ofEpochSecond(epochSecond);
    }

    /**
     * Gets the transition instant as an epoch second.
     *
     * @return the transition epoch second
     */
    public long toEpochSecond() {
        return epochSecond;
    }

    //-------------------------------------------------------------------------
    /**
     * Gets the local transition date-time, as would be expressed with the 'before' offset.
     * !(p)
     * This is the date-time where the discontinuity begins expressed with the 'before' offset.
     * At this instant, the 'after' offset is actually used, therefore the combination of this
     * date-time and the 'before' offset will never occur.
     * !(p)
     * The combination of the 'before' date-time and offset represents the same instant
     * as the 'after' date-time and offset.
     *
     * @return the transition date-time expressed with the before offset, not null
     */
    public LocalDateTime getDateTimeBefore() {
        return transition;
    }

    /**
     * Gets the local transition date-time, as would be expressed with the 'after' offset.
     * !(p)
     * This is the first date-time after the discontinuity, when the new offset applies.
     * !(p)
     * The combination of the 'before' date-time and offset represents the same instant
     * as the 'after' date-time and offset.
     *
     * @return the transition date-time expressed with the after offset, not null
     */
    public LocalDateTime getDateTimeAfter() {
        return transition.plusSeconds(getDurationSeconds());
    }

    /**
     * Gets the offset before the transition.
     * !(p)
     * This is the offset _in use before the instant of the transition.
     *
     * @return the offset before the transition, not null
     */
    public ZoneOffset getOffsetBefore() {
        return offsetBefore;
    }

    /**
     * Gets the offset after the transition.
     * !(p)
     * This is the offset _in use on and after the instant of the transition.
     *
     * @return the offset after the transition, not null
     */
    public ZoneOffset getOffsetAfter() {
        return offsetAfter;
    }

    /**
     * Gets the duration of the transition.
     * !(p)
     * In most cases, the transition duration is one hour, however this is not always the case.
     * The duration will be positive for a gap and negative for an overlap.
     * Time-zones are second-based, so the nanosecond part of the duration will be zero.
     *
     * @return the duration of the transition, positive for gaps, negative for overlaps
     */
    public Duration getDuration() {
        return Duration.ofSeconds(getDurationSeconds());
    }

    /**
     * Gets the duration of the transition _in seconds.
     *
     * @return the duration _in seconds
     */
    private int getDurationSeconds() {
        return getOffsetAfter().getTotalSeconds() - getOffsetBefore().getTotalSeconds();
    }

    /**
     * Does this transition represent a gap _in the local time-line.
     * !(p)
     * Gaps occur where there are local date-times that simply do not exist.
     * An example would be when the offset changes from {@code +01:00} to {@code +02:00}.
     * This might be described as 'the clocks will move forward one hour tonight at 1am'.
     *
     * @return true if this transition is a gap, false if it is an overlap
     */
    public bool isGap() {
        return getOffsetAfter().getTotalSeconds() > getOffsetBefore().getTotalSeconds();
    }

    /**
     * Does this transition represent an overlap _in the local time-line.
     * !(p)
     * Overlaps occur where there are local date-times that exist twice.
     * An example would be when the offset changes from {@code +02:00} to {@code +01:00}.
     * This might be described as 'the clocks will move back one hour tonight at 2am'.
     *
     * @return true if this transition is an overlap, false if it is a gap
     */
    public bool isOverlap() {
        return getOffsetAfter().getTotalSeconds() < getOffsetBefore().getTotalSeconds();
    }

    /**
     * Checks if the specified offset is valid during this transition.
     * !(p)
     * This checks to see if the given offset will be valid at some point _in the transition.
     * A gap will always return false.
     * An overlap will return true if the offset is either the before or after offset.
     *
     * @param offset  the offset to check, null returns false
     * @return true if the offset is valid during the transition
     */
    public bool isValidOffset(ZoneOffset offset) {
        return isGap() ? false : (getOffsetBefore() == offset) || (getOffsetAfter()== offset);
    }

    /**
     * Gets the valid offsets during this transition.
     * !(p)
     * A gap will return an empty list, while an overlap will return both offsets.
     *
     * @return the list of valid offsets
     */
    List!(ZoneOffset) getValidOffsets() {
        if (isGap()) {
            return new ArrayList!(ZoneOffset)();
        }
        auto l = new ArrayList!(ZoneOffset)();
        l.add(getOffsetBefore());
        l.add(getOffsetAfter());
        return l;
    }

    //-----------------------------------------------------------------------
    /**
     * Compares this transition to another based on the transition instant.
     * !(p)
     * This compares the instants of each transition.
     * The offsets are ignored, making this order inconsistent with equals.
     *
     * @param transition  the transition to compare to, not null
     * @return the comparator value, negative if less, positive if greater
     */
    // override
    public int compareTo(ZoneOffsetTransition transition) {
        return compare(epochSecond, transition.epochSecond);
    }

    override
    public int opCmp(ZoneOffsetTransition transition) {
        return compare(epochSecond, transition.epochSecond);
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if this object equals another.
     * !(p)
     * The entire state of the object is compared.
     *
     * @param other  the other object to compare to, null returns false
     * @return true if equal
     */
    override
    public bool opEquals(Object other) {
        if (other == this) {
            return true;
        }
        if (cast(ZoneOffsetTransition)(other) !is null) {
            ZoneOffsetTransition d = cast(ZoneOffsetTransition) other;
            return epochSecond == d.epochSecond &&
                (offsetBefore == d.offsetBefore) && (offsetAfter == d.offsetAfter);
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
            return transition.toHash() ^ offsetBefore.toHash() ^ Integer.rotateLeft(cast(int)(offsetAfter.toHash()), 16);
        }catch(Exception e){
        return int.init;
        }
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
        buf.append("Transition[")
            .append(isGap() ? "Gap" : "Overlap")
            .append(" at ")
            .append(transition.toString)
            .append(offsetBefore.toString)
            .append(" to ")
            .append(offsetAfter.toString)
            .append(']');
        return buf.toString();
    }

}
