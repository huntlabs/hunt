
module hunt.time.chrono.ChronoPeriodImpl;

import hunt.time.temporal.ChronoField;
import hunt.time.temporal.ChronoUnit;

import hunt.io.DataInput;
import hunt.io.DataOutput;
import hunt.lang.exception;
import hunt.container;
//import hunt.io.ObjectInputStream;
// import hunt.io.ObjectStreamException;
import hunt.io.Serializable;
import hunt.time.DateTimeException;
import hunt.time.temporal.ChronoUnit;
import hunt.time.temporal.Temporal;
import hunt.time.temporal.TemporalAccessor;
import hunt.time.temporal.TemporalAmount;
import hunt.time.temporal.TemporalQueries;
import hunt.time.temporal.TemporalUnit;
import hunt.time.temporal.UnsupportedTemporalTypeException;
import hunt.time.temporal.ValueRange;
import hunt.container.List;
import hunt.time.chrono.Chronology;
import hunt.time.chrono.ChronoPeriod;
import hunt.lang;
import hunt.string.StringBuilder;
import hunt.time.chrono.Ser;
import hunt.time.util.QueryHelper;

/**
 * A period expressed _in terms of a standard year-month-day calendar system.
 * !(p)
 * This class is used by applications seeking to handle dates _in non-ISO calendar systems.
 * For example, the Japanese, Minguo, Thai Buddhist and others.
 *
 * @implSpec
 * This class is immutable nad thread-safe.
 *
 * @since 1.8
 */
final class ChronoPeriodImpl
        : ChronoPeriod, Serializable {
    // this class is only used by JDK chronology implementations and makes assumptions based on that fact

    /**
     * Serialization version.
     */
    private enum long serialVersionUID = 57387258289L;

    /**
     * The set of supported units.
     */
    __gshared List!(TemporalUnit) SUPPORTED_UNITS;

    // shared static this()
    // {
    //     SUPPORTED_UNITS = new ArrayList!TemporalUnit();
    //     SUPPORTED_UNITS.add(ChronoUnit.YEARS);
    //     SUPPORTED_UNITS.add(ChronoUnit.MONTHS);
    //     SUPPORTED_UNITS.add(ChronoUnit.DAYS);
    // }
    /**
     * The chronology.
     */
    private  Chronology chrono;
    /**
     * The number of years.
     */
     int years;
    /**
     * The number of months.
     */
     int months;
    /**
     * The number of days.
     */
     int days;

    /**
     * Creates an instance.
     */
    this(Chronology chrono, int years, int months, int days) {
        assert(chrono, "chrono");
        this.chrono = chrono;
        this.years = years;
        this.months = months;
        this.days = days;
    }

    //-----------------------------------------------------------------------
    override
    public long get(TemporalUnit unit) {
        if (unit == ChronoUnit.YEARS) {
            return years;
        } else if (unit == ChronoUnit.MONTHS) {
            return months;
        } else if (unit == ChronoUnit.DAYS) {
            return days;
        } else {
            throw new UnsupportedTemporalTypeException("Unsupported unit: " ~ typeid(unit).name);
        }
    }

    override
    public List!(TemporalUnit) getUnits() {
        return ChronoPeriodImpl.SUPPORTED_UNITS;
    }

    override
    public Chronology getChronology() {
        return chrono;
    }

    //-----------------------------------------------------------------------
    override
    public bool isZero() {
        return years == 0 && months == 0 && days == 0;
    }

    override
    public bool isNegative() {
        return years < 0 || months < 0 || days < 0;
    }

    //-----------------------------------------------------------------------
    override
    public ChronoPeriod plus(TemporalAmount amountToAdd) {
        ChronoPeriodImpl amount = validateAmount(amountToAdd);
        return new ChronoPeriodImpl(
                chrono,
                Math.addExact(years, amount.years),
                Math.addExact(months, amount.months),
                Math.addExact(days, amount.days));
    }

    override
    public ChronoPeriod minus(TemporalAmount amountToSubtract) {
        ChronoPeriodImpl amount = validateAmount(amountToSubtract);
        return new ChronoPeriodImpl(
                chrono,
                Math.subtractExact(years, amount.years),
                Math.subtractExact(months, amount.months),
                Math.subtractExact(days, amount.days));
    }

    /**
     * Obtains an instance of {@code ChronoPeriodImpl} from a temporal amount.
     *
     * @param amount  the temporal amount to convert, not null
     * @return the period, not null
     */
    private ChronoPeriodImpl validateAmount(TemporalAmount amount) {
        assert(amount, "amount");
        if ((cast(ChronoPeriodImpl)(amount) !is null) == false) {
            throw new DateTimeException("Unable to obtain ChronoPeriod from TemporalAmount: " ~ typeid(amount).stringof);
        }
        ChronoPeriodImpl period = cast(ChronoPeriodImpl) amount;
        if ((chrono == period.getChronology()) == false) {
            throw new ClassCastException("Chronology mismatch, expected: " ~ chrono.getId() ~ ", actual: " ~ period.getChronology().getId());
        }
        return period;
    }

    //-----------------------------------------------------------------------
    override
    public ChronoPeriod multipliedBy(int scalar) {
        if (this.isZero() || scalar == 1) {
            return this;
        }
        return new ChronoPeriodImpl(
                chrono,
                Math.multiplyExact(years, scalar),
                Math.multiplyExact(months, scalar),
                Math.multiplyExact(days, scalar));
    }

    //-----------------------------------------------------------------------
    override
    public ChronoPeriod normalized() {
        long monthRange = monthRange();
        if (monthRange > 0) {
            long totalMonths = years * monthRange + months;
            long splitYears = totalMonths / monthRange;
            int splitMonths = cast(int) (totalMonths % monthRange);  // no overflow
            if (splitYears == years && splitMonths == months) {
                return this;
            }
            return new ChronoPeriodImpl(chrono, Math.toIntExact(splitYears), splitMonths, days);

        }
        return this;
    }

    override
     ChronoPeriod negated() {
        return multipliedBy(-1);
    }
    /**
     * Calculates the range of months.
     *
     * @return the month range, -1 if not fixed range
     */
    private long monthRange() {
        ValueRange startRange = chrono.range(ChronoField.MONTH_OF_YEAR);
        if (startRange.isFixed() && startRange.isIntValue()) {
            return startRange.getMaximum() - startRange.getMinimum() + 1;
        }
        return -1;
    }

    //-------------------------------------------------------------------------
    override
    public Temporal addTo(Temporal temporal) {
        validateChrono(temporal);
        if (months == 0) {
            if (years != 0) {
                temporal = temporal.plus(years, ChronoUnit.YEARS);
            }
        } else {
            long monthRange = monthRange();
            if (monthRange > 0) {
                temporal = temporal.plus(years * monthRange + months, ChronoUnit.MONTHS);
            } else {
                if (years != 0) {
                    temporal = temporal.plus(years, ChronoUnit.YEARS);
                }
                temporal = temporal.plus(months, ChronoUnit.MONTHS);
            }
        }
        if (days != 0) {
            temporal = temporal.plus(days, ChronoUnit.DAYS);
        }
        return temporal;
    }



    override
    public Temporal subtractFrom(Temporal temporal) {
        validateChrono(temporal);
        if (months == 0) {
            if (years != 0) {
                temporal = temporal.minus(years, ChronoUnit.YEARS);
            }
        } else {
            long monthRange = monthRange();
            if (monthRange > 0) {
                temporal = temporal.minus(years * monthRange + months, ChronoUnit.MONTHS);
            } else {
                if (years != 0) {
                    temporal = temporal.minus(years, ChronoUnit.YEARS);
                }
                temporal = temporal.minus(months, ChronoUnit.MONTHS);
            }
        }
        if (days != 0) {
            temporal = temporal.minus(days, ChronoUnit.DAYS);
        }
        return temporal;
    }

    /**
     * Validates that the temporal has the correct chronology.
     */
    private void validateChrono(TemporalAccessor temporal) {
        assert(temporal, "temporal");
        Chronology temporalChrono = QueryHelper.query!Chronology(temporal , TemporalQueries.chronology());
        if (temporalChrono !is null && (chrono == temporalChrono) == false) {
            throw new DateTimeException("Chronology mismatch, expected: " ~ chrono.getId() ~ ", actual: " ~ temporalChrono.getId());
        }
    }

    //-----------------------------------------------------------------------
    override
    public bool opEquals(Object obj) {
        if (this is obj) {
            return true;
        }
        if (cast(ChronoPeriodImpl)(obj) !is null) {
            ChronoPeriodImpl other = cast(ChronoPeriodImpl) obj;
            return years == other.years && months == other.months &&
                    days == other.days && chrono == (other.chrono);
        }
        return false;
    }

    override
    public size_t toHash() @trusted nothrow {
        try{
            return (years + Integer.rotateLeft(months, 8) + Integer.rotateLeft(days, 16)) ^ chrono.toHash();
        }
        catch(Exception e){}
        return int.init;
    }

    //-----------------------------------------------------------------------
    override
    public string toString() {
        if (isZero()) {
            return getChronology().toString() ~ " P0D";
        } else {
            StringBuilder buf = new StringBuilder();
            buf.append(getChronology().toString()).append(' ').append('P');
            if (years != 0) {
                buf.append(years).append('Y');
            }
            if (months != 0) {
                buf.append(months).append('M');
            }
            if (days != 0) {
                buf.append(days).append('D');
            }
            return buf.toString();
        }
    }

    //-----------------------------------------------------------------------
    /**
     * Writes the Chronology using a
     * <a href="{@docRoot}/serialized-form.html#hunt.time.chrono.Ser">dedicated serialized form</a>.
     * !(pre)
     *  _out.writeByte(12);  // identifies this as a ChronoPeriodImpl
     *  _out.writeUTF(getId());  // the chronology
     *  _out.writeInt(years);
     *  _out.writeInt(months);
     *  _out.writeInt(days);
     * </pre>
     *
     * @return the instance of {@code Ser}, not null
     */
    protected Object writeReplace() {
        return new Ser(Ser.CHRONO_PERIOD_TYPE, this);
    }

    /**
     * Defend against malicious streams.
     *
     * @param s the stream to read
     * @throws InvalidObjectException always
     */
     ///@gxc
    // private void readObject(ObjectInputStream s) /*throws ObjectStreamException*/ {
    //     throw new InvalidObjectException("Deserialization via serialization delegate");
    // }

    void writeExternal(DataOutput _out) /*throws IOException*/ {
        _out.writeUTF(chrono.getId());
        _out.writeInt(years);
        _out.writeInt(months);
        _out.writeInt(days);
    }

    static ChronoPeriodImpl readExternal(DataInput _in) /*throws IOException*/ {
        Chronology chrono = Chronology.of(_in.readUTF());
        int years = _in.readInt();
        int months = _in.readInt();
        int days = _in.readInt();
        return new ChronoPeriodImpl(chrono, years, months, days);
    }

}
