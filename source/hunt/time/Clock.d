
module hunt.time.Clock;

import std.conv;
import std.math;
import core.time : convert;
import hunt.lang.exception;
import hunt.lang;
import hunt.time.LocalTime;
import hunt.io.Serializable;
import hunt.time.ZoneId;
import hunt.time.Duration;
import hunt.time.Instant;
import hunt.time.ZoneOffset;
import hunt.time.util.common;
// import hunt.util.TimeZone;
// import jdk.internal.misc.VM;

/**
 * A clock providing access to the current _instant, date and time using a time-zone.
 * !(p)
 * Instances of this class are used to find the current _instant, which can be
 * interpreted using the stored time-zone to find the current date and time.
 * As such, a clock can be used instead of {@link System#currentTimeMillis()}
 * and {@link TimeZone#getDefault()}.
 * !(p)
 * Use of a {@code Clock} is optional. All key date-time classes also have a
 * {@code now()} factory method that uses the system clock _in the default time zone.
 * The primary purpose of this abstraction is to allow alternate clocks to be
 * plugged _in as and when required. Applications use an object to obtain the
 * current time rather than a static method. This can simplify testing.
 * !(p)
 * Best practice for applications is to pass a {@code Clock} into any method
 * that requires the current _instant. A dependency injection framework is one
 * way to achieve this:
 * !(pre)
 *  public class MyBean {
 *    private Clock clock;  // dependency inject
 *    ...
 *    public void process(LocalDate eventDate) {
 *      if (eventDate.isBefore(LocalDate.now(clock)) {
 *        ...
 *      }
 *    }
 *  }
 * </pre>
 * This approach allows an alternate clock, such as {@link #fixed(Instant, ZoneId) fixed}
 * or {@link #_offset(Clock, Duration) _offset} to be used during testing.
 * !(p)
 * The {@code system} factory methods provide clocks based on the best available
 * system clock This may use {@link System#currentTimeMillis()}, or a higher
 * resolution clock if one is available.
 *
 * @implSpec
 * This abstract class must be implemented with care to ensure other classes operate correctly.
 * All implementations that can be instantiated must be final, immutable and thread-safe.
 * !(p)
 * The principal methods are defined to allow the throwing of an exception.
 * In normal use, no exceptions will be thrown, however one possible implementation would be to
 * obtain the time from a central time server across the network. Obviously, _in this case the
 * lookup could fail, and so the method is permitted to throw an exception.
 * !(p)
 * The returned instants from {@code Clock} work on a time-scale that ignores leap seconds,
 * as described _in {@link Instant}. If the implementation wraps a source that provides leap
 * second information, then a mechanism should be used to "smooth" the leap second.
 * The Java Time-Scale mandates the use of UTC-SLS, however clock implementations may choose
 * how accurate they are with the time-scale so long as they document how they work.
 * Implementations are therefore not required to actually perform the UTC-SLS slew or to
 * otherwise be aware of leap seconds.
 * !(p)
 * Implementations should implement {@code Serializable} wherever possible and must
 * document whether or not they do support serialization.
 *
 * @implNote
 * The clock implementation provided here is based on the same underlying clock
 * as {@link System#currentTimeMillis()}, but may have a precision finer than
 * milliseconds if available.
 * However, little to no guarantee is provided about the accuracy of the
 * underlying clock. Applications requiring a more accurate clock must implement
 * this abstract class themselves using a different external clock, such as an
 * NTP server.
 *
 * @since 1.8
 */
public abstract class Clock {

    /**
     * Obtains a clock that returns the current _instant using the best available
     * system clock, converting to date and time using the UTC time-zone.
     * !(p)
     * This clock, rather than {@link #systemDefaultZone()}, should be used when
     * you need the current _instant without the date or time.
     * !(p)
     * This clock is based on the best available system clock.
     * This may use {@link System#currentTimeMillis()}, or a higher resolution
     * clock if one is available.
     * !(p)
     * Conversion from _instant to date or time uses the {@linkplain ZoneOffset#UTC UTC time-zone}.
     * !(p)
     * The returned implementation is immutable, thread-safe and {@code Serializable}.
     * It is equivalent to {@code system(ZoneOffset.UTC)}.
     *
     * @return a clock that uses the best available system clock _in the UTC zone, not null
     */
    public static Clock systemUTC() {
        return SystemClock.UTC;
    }

    /**
     * Obtains a clock that returns the current _instant using the best available
     * system clock, converting to date and time using the default time-zone.
     * !(p)
     * This clock is based on the best available system clock.
     * This may use {@link System#currentTimeMillis()}, or a higher resolution
     * clock if one is available.
     * !(p)
     * Using this method hard codes a dependency to the default time-zone into your application.
     * It is recommended to avoid this and use a specific time-zone whenever possible.
     * The {@link #systemUTC() UTC clock} should be used when you need the current _instant
     * without the date or time.
     * !(p)
     * The returned implementation is immutable, thread-safe and {@code Serializable}.
     * It is equivalent to {@code system(ZoneId.systemDefault())}.
     *
     * @return a clock that uses the best available system clock _in the default zone, not null
     * @see ZoneId#systemDefault()
     */
    public static Clock systemDefaultZone() {
        return new SystemClock(ZoneId.systemDefault());
    }

    /**
     * Obtains a clock that returns the current _instant using the best available
     * system clock.
     * !(p)
     * This clock is based on the best available system clock.
     * This may use {@link System#currentTimeMillis()}, or a higher resolution
     * clock if one is available.
     * !(p)
     * Conversion from _instant to date or time uses the specified time-zone.
     * !(p)
     * The returned implementation is immutable, thread-safe and {@code Serializable}.
     *
     * @param zone  the time-zone to use to convert the _instant to date-time, not null
     * @return a clock that uses the best available system clock _in the specified zone, not null
     */
    public static Clock system(ZoneId zone) {
        assert(zone, "zone");
        if (zone == ZoneOffset.UTC) {
            return SystemClock.UTC;
        }
        return new SystemClock(zone);
    }

    //-------------------------------------------------------------------------
    /**
     * Obtains a clock that returns the current _instant ticking _in whole milliseconds
     * using the best available system clock.
     * !(p)
     * This clock will always have the nano-of-second field truncated to milliseconds.
     * This ensures that the visible time ticks _in whole milliseconds.
     * The underlying clock is the best available system clock, equivalent to
     * using {@link #system(ZoneId)}.
     * !(p)
     * Implementations may use a caching strategy for performance reasons.
     * As such, it is possible that the start of the millisecond observed via this
     * clock will be later than that observed directly via the underlying clock.
     * !(p)
     * The returned implementation is immutable, thread-safe and {@code Serializable}.
     * It is equivalent to {@code tick(system(zone), Duration.ofMillis(1))}.
     *
     * @param zone  the time-zone to use to convert the _instant to date-time, not null
     * @return a clock that ticks _in whole milliseconds using the specified zone, not null
     * @since 9
     */
    public static Clock tickMillis(ZoneId zone) {
        return new TickClock(system(zone), LocalTime.NANOS_PER_MILLI);
    }

    //-------------------------------------------------------------------------
    /**
     * Obtains a clock that returns the current _instant ticking _in whole seconds
     * using the best available system clock.
     * !(p)
     * This clock will always have the nano-of-second field set to zero.
     * This ensures that the visible time ticks _in whole seconds.
     * The underlying clock is the best available system clock, equivalent to
     * using {@link #system(ZoneId)}.
     * !(p)
     * Implementations may use a caching strategy for performance reasons.
     * As such, it is possible that the start of the second observed via this
     * clock will be later than that observed directly via the underlying clock.
     * !(p)
     * The returned implementation is immutable, thread-safe and {@code Serializable}.
     * It is equivalent to {@code tick(system(zone), Duration.ofSeconds(1))}.
     *
     * @param zone  the time-zone to use to convert the _instant to date-time, not null
     * @return a clock that ticks _in whole seconds using the specified zone, not null
     */
    public static Clock tickSeconds(ZoneId zone) {
        return new TickClock(system(zone), LocalTime.NANOS_PER_SECOND);
    }

    /**
     * Obtains a clock that returns the current _instant ticking _in whole minutes
     * using the best available system clock.
     * !(p)
     * This clock will always have the nano-of-second and second-of-minute fields set to zero.
     * This ensures that the visible time ticks _in whole minutes.
     * The underlying clock is the best available system clock, equivalent to
     * using {@link #system(ZoneId)}.
     * !(p)
     * Implementations may use a caching strategy for performance reasons.
     * As such, it is possible that the start of the minute observed via this
     * clock will be later than that observed directly via the underlying clock.
     * !(p)
     * The returned implementation is immutable, thread-safe and {@code Serializable}.
     * It is equivalent to {@code tick(system(zone), Duration.ofMinutes(1))}.
     *
     * @param zone  the time-zone to use to convert the _instant to date-time, not null
     * @return a clock that ticks _in whole minutes using the specified zone, not null
     */
    public static Clock tickMinutes(ZoneId zone) {
        return new TickClock(system(zone), LocalTime.NANOS_PER_MINUTE);
    }

    /**
     * Obtains a clock that returns instants from the specified clock truncated
     * to the nearest occurrence of the specified duration.
     * !(p)
     * This clock will only tick as per the specified duration. Thus, if the duration
     * is half a second, the clock will return instants truncated to the half second.
     * !(p)
     * The tick duration must be positive. If it has a part smaller than a whole
     * millisecond, then the whole duration must divide into one second without
     * leaving a remainder. All normal tick durations will match these criteria,
     * including any multiple of hours, minutes, seconds and milliseconds, and
     * sensible nanosecond durations, such as 20ns, 250,000ns and 500,000ns.
     * !(p)
     * A duration of zero or one nanosecond would have no truncation effect.
     * Passing one of these will return the underlying clock.
     * !(p)
     * Implementations may use a caching strategy for performance reasons.
     * As such, it is possible that the start of the requested duration observed
     * via this clock will be later than that observed directly via the underlying clock.
     * !(p)
     * The returned implementation is immutable, thread-safe and {@code Serializable}
     * providing that the base clock is.
     *
     * @param baseClock  the base clock to base the ticking clock on, not null
     * @param tickDuration  the duration of each visible tick, not negative, not null
     * @return a clock that ticks _in whole units of the duration, not null
     * @throws IllegalArgumentException if the duration is negative, or has a
     *  part smaller than a whole millisecond such that the whole duration is not
     *  divisible into one second
     * @throws ArithmeticException if the duration is too large to be represented as nanos
     */
    public static Clock tick(Clock baseClock, Duration tickDuration) {
        assert(baseClock, "baseClock");
        assert(tickDuration, "tickDuration");
        if (tickDuration.isNegative()) {
            throw new IllegalArgumentException("Tick duration must not be negative");
        }
        long tickNanos = tickDuration.toNanos();
        if (tickNanos % 1000_000 == 0) {
            // ok, no fraction of millisecond
        } else if (1000_000_000 % tickNanos == 0) {
            // ok, divides into one second without remainder
        } else {
            throw new IllegalArgumentException("Invalid tick duration");
        }
        if (tickNanos <= 1) {
            return baseClock;
        }
        return new TickClock(baseClock, tickNanos);
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains a clock that always returns the same _instant.
     * !(p)
     * This clock simply returns the specified _instant.
     * As such, it is not a clock _in the conventional sense.
     * The main use case for this is _in testing, where the fixed clock ensures
     * tests are not dependent on the current clock.
     * !(p)
     * The returned implementation is immutable, thread-safe and {@code Serializable}.
     *
     * @param fixedInstant  the _instant to use as the clock, not null
     * @param zone  the time-zone to use to convert the _instant to date-time, not null
     * @return a clock that always returns the same _instant, not null
     */
    public static Clock fixed(Instant fixedInstant, ZoneId zone) {
        assert(fixedInstant, "fixedInstant");
        assert(zone, "zone");
        return new FixedClock(fixedInstant, zone);
    }

    //-------------------------------------------------------------------------
    /**
     * Obtains a clock that returns instants from the specified clock with the
     * specified duration added
     * !(p)
     * This clock wraps another clock, returning instants that are later by the
     * specified duration. If the duration is negative, the instants will be
     * earlier than the current date and time.
     * The main use case for this is to simulate running _in the future or _in the past.
     * !(p)
     * A duration of zero would have no offsetting effect.
     * Passing zero will return the underlying clock.
     * !(p)
     * The returned implementation is immutable, thread-safe and {@code Serializable}
     * providing that the base clock is.
     *
     * @param baseClock  the base clock to add the duration to, not null
     * @param offsetDuration  the duration to add, not null
     * @return a clock based on the base clock with the duration added, not null
     */
    public static Clock _offset(Clock baseClock, Duration offsetDuration) {
        assert(baseClock, "baseClock");
        assert(offsetDuration, "offsetDuration");
        if (offsetDuration.opEquals(Duration.ZERO)) {
            return baseClock;
        }
        return new OffsetClock(baseClock, offsetDuration);
    }

    //-----------------------------------------------------------------------
    /**
     * Constructor accessible by subclasses.
     */
    protected this() {
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the time-zone being used to create dates and times.
     * !(p)
     * A clock will typically obtain the current _instant and then convert that
     * to a date or time using a time-zone. This method returns the time-zone used.
     *
     * @return the time-zone being used to interpret instants, not null
     */
    public abstract ZoneId getZone();

    /**
     * Returns a copy of this clock with a different time-zone.
     * !(p)
     * A clock will typically obtain the current _instant and then convert that
     * to a date or time using a time-zone. This method returns a clock with
     * similar properties but using a different time-zone.
     *
     * @param zone  the time-zone to change to, not null
     * @return a clock based on this clock with the specified time-zone, not null
     */
    public abstract Clock withZone(ZoneId zone);

    //-------------------------------------------------------------------------
    /**
     * Gets the current millisecond _instant of the clock.
     * !(p)
     * This returns the millisecond-based _instant, measured from 1970-01-01T00:00Z (UTC).
     * This is equivalent to the definition of {@link System#currentTimeMillis()}.
     * !(p)
     * Most applications should avoid this method and use {@link Instant} to represent
     * an _instant on the time-line rather than a raw millisecond value.
     * This method is provided to allow the use of the clock _in high performance use cases
     * where the creation of an object would be unacceptable.
     * !(p)
     * The default implementation currently calls {@link #_instant}.
     *
     * @return the current millisecond _instant from this clock, measured from
     *  the Java epoch of 1970-01-01T00:00Z (UTC), not null
     * @throws DateTimeException if the _instant cannot be obtained, not thrown by most implementations
     */
    public long millis() {
        return instant().toEpochMilli();
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the current _instant of the clock.
     * !(p)
     * This returns an _instant representing the current _instant as defined by the clock.
     *
     * @return the current _instant from this clock, not null
     * @throws DateTimeException if the _instant cannot be obtained, not thrown by most implementations
     */
    public abstract Instant instant();

    //-----------------------------------------------------------------------
    /**
     * Checks if this clock is equal to another clock.
     * !(p)
     * Clocks should override this method to compare equals based on
     * their state and to meet the contract of {@link Object#equals}.
     * If not overridden, the behavior is defined by {@link Object#equals}
     *
     * @param obj  the object to check, null returns false
     * @return true if this is equal to the other clock
     */
    override
    public bool opEquals(Object obj) {
        return super.opEquals(obj);
    }

    /**
     * A hash code for this clock.
     * !(p)
     * Clocks should override this method based on
     * their state and to meet the contract of {@link Object#hashCode}.
     * If not overridden, the behavior is defined by {@link Object#hashCode}
     *
     * @return a suitable hash code
     */
    override
    public  size_t toHash() @trusted nothrow {
        return super.toHash();
    }

    //-----------------------------------------------------------------------
    /**
     * Implementation of a clock that always returns the latest time from
     * {@link System#currentTimeMillis()}.
     */
    static final class SystemClock : Clock , Serializable {
         enum long serialVersionUID = 6740630888130243051L;
         __gshared long OFFSET_SEED ; // initial offest
        __gshared SystemClock UTC;

        // shared static this()
        // {
        //     OFFSET_SEED =
        //         System.currentTimeMillis()/1000 - 1024; // initial offest
        //     UTC = new SystemClock(ZoneOffset.UTC);
        // }

        private  ZoneId zone;
        // We don't actually need a volatile here.
        // We don't care if _offset is set or read concurrently by multiple
        // threads - we just need a value which is 'recent enough' - _in other
        // words something that has been updated at least once _in the last
        // 2^32 secs (~136 years). And even if we by chance see an invalid
        // _offset, the worst that can happen is that we will get a -1 value
        // from getNanoTimeAdjustment, forcing us to update the _offset
        // once again.
        private /*transient*/ long _offset;

        this(ZoneId zone) {
            this.zone = zone;
            this._offset = OFFSET_SEED;
        }
        override
        public ZoneId getZone() {
            return zone;
        }
        override
        public Clock withZone(ZoneId zone) {
            if (zone.opEquals(this.zone)) {  // intentional NPE
                return this;
            }
            return new SystemClock(zone);
        }
        override
        public long millis() {
            // System.currentTimeMillis() and VM.getNanoTimeAdjustment(_offset)
            // use the same time source - System.currentTimeMillis() simply
            // limits the resolution to milliseconds.
            // So we take the faster path and call System.currentTimeMillis()
            // directly - _in order to avoid the performance penalty of
            // VM.getNanoTimeAdjustment(_offset) which is less efficient.
            return System.currentTimeMillis();
        }
        override
        public Instant instant() {
            // Take a local copy of _offset. _offset can be updated concurrently
            // by other threads (even if we haven't made it volatile) so we will
            // work with a local copy.
            // long localOffset = _offset;
            // long adjustment = VM.getNanoTimeAdjustment(localOffset);

            // if (adjustment == -1) {
            //     // -1 is a sentinel value returned by VM.getNanoTimeAdjustment
            //     // when the _offset it is given is too far off the current UTC
            //     // time. In principle, this should not happen unless the
            //     // JVM has run for more than ~136 years (not likely) or
            //     // someone is fiddling with the system time, or the _offset is
            //     // by chance at 1ns _in the future (very unlikely).
            //     // We can easily recover from all these conditions by bringing
            //     // back the _offset _in range and retry.

            //     // bring back the _offset _in range. We use -1024 to make
            //     // it more unlikely to hit the 1ns _in the future condition.
            //     localOffset = System.currentTimeMillis()/1000 - 1024;

            //     // retry
            //     // adjustment = VM.getNanoTimeAdjustment(localOffset);

            //     if (adjustment == -1) {
            //         // Should not happen: we just recomputed a new _offset.
            //         // It should have fixed the issue.
            //         throw new InternalError("Offset " ~ localOffset.to!string ~ " is not _in range");
            //     } else {
            //         // OK - recovery succeeded. Update the _offset for the
            //         // next call...
            //         _offset = localOffset;
            //     }
            // }
            long nsecs = System.currentTimeNsecs();
            long localOffset = convert!("nsecs", "seconds")(nsecs);
            long adjustment = nsecs - localOffset * 1000_000_000L;
            // import hunt.logging;
            // import std.string;
            // version(HUNT_DEBUG) logDebug("(nsecs : %s , msecs : %s , offset: %s )".format(nsecs,localOffset,adjustment));
            return Instant.ofEpochSecond(localOffset, adjustment);
        }
        override
        public bool opEquals(Object obj) {
            if (cast(SystemClock)(obj) !is null) {
                return zone.opEquals((cast(SystemClock) obj).zone);
            }
            return false;
        }
        override
        public size_t toHash() @trusted nothrow {
            return zone.toHash() + 1;
        }
        override
        public string toString() {
            return "SystemClock[" ~ zone.to!string ~ "]";
        }
        ///@gxc
        // private void readObject(ObjectInputStream _is) {
        //     // ensure that _offset is initialized
        //     _is.defaultReadObject();
        //     _offset = OFFSET_SEED;
        // }
    }

    //-----------------------------------------------------------------------
    /**
     * Implementation of a clock that always returns the same _instant.
     * This is typically used for testing.
     */
    static final class FixedClock : Clock , Serializable {
        private enum long serialVersionUID = 7430389292664866958L;
        private  Instant _instant;
        private  ZoneId zone;

        this(Instant fixedInstant, ZoneId zone) {
            this._instant = fixedInstant;
            this.zone = zone;
        }
        override
        public ZoneId getZone() {
            return zone;
        }
        override
        public Clock withZone(ZoneId zone) {
            if (zone.opEquals(this.zone)) {  // intentional NPE
                return this;
            }
            return new FixedClock(_instant, zone);
        }
        override
        public long millis() {
            return _instant.toEpochMilli();
        }
        override
        public Instant instant() {
            return _instant;
        }
        override
        public bool opEquals(Object obj) {
            if (cast(FixedClock)(obj) !is null) {
                FixedClock other = cast(FixedClock) obj;
                return _instant.opEquals(other._instant) && zone.opEquals(other.zone);
            }
            return false;
        }
        override
        public size_t toHash() @trusted nothrow {
            return _instant.toHash() ^ zone.toHash();
        }
        override
        public string toString() {
            return "FixedClock[" ~ _instant.toString ~ "," ~ zone.toString ~ "]";
        }
    }

    //-----------------------------------------------------------------------
    /**
     * Implementation of a clock that adds an _offset to an underlying clock.
     */
    static final class OffsetClock : Clock , Serializable {
        private enum long serialVersionUID = 2007484719125426256L;
        private  Clock baseClock;
        private  Duration _offset;

        this(Clock baseClock, Duration _offset) {
            this.baseClock = baseClock;
            this._offset = _offset;
        }
        override
        public ZoneId getZone() {
            return baseClock.getZone();
        }
        override
        public Clock withZone(ZoneId zone) {
            if (zone.opEquals(baseClock.getZone())) {  // intentional NPE
                return this;
            }
            return new OffsetClock(baseClock.withZone(zone), _offset);
        }
        override
        public long millis() {
            return Math.addExact(baseClock.millis(), _offset.toMillis());
        }
        override
        public Instant instant() {
            return baseClock.instant().plus(_offset);
        }
        override
        public bool opEquals(Object obj) {
            if (cast(OffsetClock)(obj) !is null) {
                OffsetClock other = cast(OffsetClock) obj;
                return baseClock.opEquals(other.baseClock) && _offset.opEquals(other._offset);
            }
            return false;
        }
        override
        public size_t toHash() @trusted nothrow {
            return baseClock.toHash() ^ _offset.toHash();
        }
        override
        public string toString() {
            return "OffsetClock[" ~ baseClock.toString ~ "," ~ _offset.toString ~ "]";
        }
    }

    //-----------------------------------------------------------------------
    /**
     * Implementation of a clock that adds an _offset to an underlying clock.
     */
    static final class TickClock : Clock , Serializable {
        private enum long serialVersionUID = 6504659149906368850L;
        private  Clock baseClock;
        private  long tickNanos;

        this(Clock baseClock, long tickNanos) {
            this.baseClock = baseClock;
            this.tickNanos = tickNanos;
        }
        override
        public ZoneId getZone() {
            return baseClock.getZone();
        }
        override
        public Clock withZone(ZoneId zone) {
            if (zone.opEquals(baseClock.getZone())) {  // intentional NPE
                return this;
            }
            return new TickClock(baseClock.withZone(zone), tickNanos);
        }
        override
        public long millis() {
            long millis = baseClock.millis();
            return millis - Math.floorMod(millis, (tickNanos / 1000_000L));
        }
        override
        public Instant instant() {
            if ((tickNanos % 1000_000) == 0) {
                long millis = baseClock.millis();
                return Instant.ofEpochMilli(millis - Math.floorMod(millis , (tickNanos / 1000_000L)));
            }
            Instant _instant = baseClock.instant();
            long nanos = _instant.getNano();
            long adjust = Math.floorMod(nanos , tickNanos);
            return _instant.minusNanos(adjust);
        }
        override
        public bool opEquals(Object obj) {
            if (cast(TickClock)(obj) !is null) {
                TickClock other = cast(TickClock) obj;
                return baseClock.opEquals(other.baseClock) && tickNanos == other.tickNanos;
            }
            return false;
        }
        override
        public size_t toHash() @trusted nothrow {
            return baseClock.toHash() ^ (cast(int) (tickNanos ^ (tickNanos >>> 32)));
        }
        override
        public string toString() {
            return "TickClock[" ~ baseClock.toString ~ "," ~ Duration.ofNanos(tickNanos).toString ~ "]";
        }
    }

}
