
module hunt.time.chrono.MinguoDate;

// import hunt.time.chrono.MinguoChronology;
// import hunt.time.temporal.ChronoField;

// import hunt.io.DataInput;
// import hunt.io.DataOutput;
// import hunt.lang.exception;

// //import hunt.io.ObjectInputStream;
// import hunt.io.Serializable;
// import hunt.time.Clock;
// import hunt.time.DateTimeException;
// import hunt.time.LocalDate;
// import hunt.time.LocalTime;
// import hunt.time.Period;
// import hunt.time.ZoneId;
// import hunt.time.temporal.ChronoField;
// import hunt.time.temporal.TemporalAccessor;
// import hunt.time.temporal.TemporalAdjuster;
// import hunt.time.temporal.TemporalAmount;
// import hunt.time.temporal.TemporalField;
// import hunt.time.temporal.TemporalQuery;
// import hunt.time.temporal.TemporalUnit;
// import hunt.time.temporal.UnsupportedTemporalTypeException;
// import hunt.time.temporal.ValueRange;
// import hunt.time.chrono.ChronoLocalDate;
// import hunt.time.chrono.MinguoEra;
// import hunt.time.chrono.ChronoLocalDateImpl;
// import hunt.time.chrono.ChronoLocalDateTime;
// import hunt.time.chrono.ChronoPeriod;

// /**
//  * A date _in the Minguo calendar system.
//  * !(p)
//  * This date operates using the {@linkplain MinguoChronology Minguo calendar}.
//  * This calendar system is primarily used _in the Republic of China, often known as Taiwan.
//  * Dates are aligned such that {@code 0001-01-01 (Minguo)} is {@code 1912-01-01 (ISO)}.
//  *
//  * !(p)
//  * This is a <a href="{@docRoot}/java.base/java/lang/doc-files/ValueBased.html">value-based</a>
//  * class; use of identity-sensitive operations (including reference equality
//  * ({@code ==}), identity hash code, or synchronization) on instances of
//  * {@code MinguoDate} may have unpredictable results and should be avoided.
//  * The {@code equals} method should be used for comparisons.
//  *
//  * @implSpec
//  * This class is immutable and thread-safe.
//  *
//  * @since 1.8
//  */
// public final class MinguoDate
//         : ChronoLocalDateImpl!(MinguoDate)
//         , ChronoLocalDate, Serializable {

//     /**
//      * Serialization version.
//      */
//     private enum long serialVersionUID = 1300372329181994526L;

//     /**
//      * The underlying date.
//      */
//     private  /*transient*/ LocalDate isoDate;

//     //-----------------------------------------------------------------------
//     /**
//      * Obtains the current {@code MinguoDate} from the system clock _in the default time-zone.
//      * !(p)
//      * This will query the {@link Clock#systemDefaultZone() system clock} _in the default
//      * time-zone to obtain the current date.
//      * !(p)
//      * Using this method will prevent the ability to use an alternate clock for testing
//      * because the clock is hard-coded.
//      *
//      * @return the current date using the system clock and default time-zone, not null
//      */
//     public static MinguoDate now() {
//         return now(Clock.systemDefaultZone());
//     }

//     /**
//      * Obtains the current {@code MinguoDate} from the system clock _in the specified time-zone.
//      * !(p)
//      * This will query the {@link Clock#system(ZoneId) system clock} to obtain the current date.
//      * Specifying the time-zone avoids dependence on the default time-zone.
//      * !(p)
//      * Using this method will prevent the ability to use an alternate clock for testing
//      * because the clock is hard-coded.
//      *
//      * @param zone  the zone ID to use, not null
//      * @return the current date using the system clock, not null
//      */
//     public static MinguoDate now(ZoneId zone) {
//         return now(Clock.system(zone));
//     }

//     /**
//      * Obtains the current {@code MinguoDate} from the specified clock.
//      * !(p)
//      * This will query the specified clock to obtain the current date - today.
//      * Using this method allows the use of an alternate clock for testing.
//      * The alternate clock may be introduced using {@linkplain Clock dependency injection}.
//      *
//      * @param clock  the clock to use, not null
//      * @return the current date, not null
//      * @throws DateTimeException if the current date cannot be obtained
//      */
//     public static MinguoDate now(Clock clock) {
//         return new MinguoDate(LocalDate.now(clock));
//     }

//     /**
//      * Obtains a {@code MinguoDate} representing a date _in the Minguo calendar
//      * system from the proleptic-year, month-of-year and day-of-month fields.
//      * !(p)
//      * This returns a {@code MinguoDate} with the specified fields.
//      * The day must be valid for the year and month, otherwise an exception will be thrown.
//      *
//      * @param prolepticYear  the Minguo proleptic-year
//      * @param month  the Minguo month-of-year, from 1 to 12
//      * @param dayOfMonth  the Minguo day-of-month, from 1 to 31
//      * @return the date _in Minguo calendar system, not null
//      * @throws DateTimeException if the value of any field is _out of range,
//      *  or if the day-of-month is invalid for the month-year
//      */
//     public static MinguoDate of(int prolepticYear, int month, int dayOfMonth) {
//         return new MinguoDate(LocalDate.of(prolepticYear + YEARS_DIFFERENCE, month, dayOfMonth));
//     }

//     /**
//      * Obtains a {@code MinguoDate} from a temporal object.
//      * !(p)
//      * This obtains a date _in the Minguo calendar system based on the specified temporal.
//      * A {@code TemporalAccessor} represents an arbitrary set of date and time information,
//      * which this factory converts to an instance of {@code MinguoDate}.
//      * !(p)
//      * The conversion typically uses the {@link ChronoField#EPOCH_DAY EPOCH_DAY}
//      * field, which is standardized across calendar systems.
//      * !(p)
//      * This method matches the signature of the functional interface {@link TemporalQuery}
//      * allowing it to be used as a query via method reference, {@code MinguoDate::from}.
//      *
//      * @param temporal  the temporal object to convert, not null
//      * @return the date _in Minguo calendar system, not null
//      * @throws DateTimeException if unable to convert to a {@code MinguoDate}
//      */
//     public static MinguoDate from(TemporalAccessor temporal) {
//         return MinguoChronology.INSTANCE.date(temporal);
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Creates an instance from an ISO date.
//      *
//      * @param isoDate  the standard local date, validated not null
//      */
//     this(LocalDate isoDate) {
//         assert(isoDate, "isoDate");
//         this.isoDate = isoDate;
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Gets the chronology of this date, which is the Minguo calendar system.
//      * !(p)
//      * The {@code Chronology} represents the calendar system _in use.
//      * The era and other fields _in {@link ChronoField} are defined by the chronology.
//      *
//      * @return the Minguo chronology, not null
//      */
//     override
//     public MinguoChronology getChronology() {
//         return MinguoChronology.INSTANCE;
//     }

//     /**
//      * Gets the era applicable at this date.
//      * !(p)
//      * The Minguo calendar system has two eras, 'ROC' and 'BEFORE_ROC',
//      * defined by {@link MinguoEra}.
//      *
//      * @return the era applicable at this date, not null
//      */
//     override
//     public MinguoEra getEra() {
//         return (getProlepticYear() >= 1 ? MinguoEra.ROC : MinguoEra.BEFORE_ROC);
//     }

//     /**
//      * Returns the length of the month represented by this date.
//      * !(p)
//      * This returns the length of the month _in days.
//      * Month lengths match those of the ISO calendar system.
//      *
//      * @return the length of the month _in days
//      */
//     override
//     public int lengthOfMonth() {
//         return isoDate.lengthOfMonth();
//     }

//     //-----------------------------------------------------------------------
//     override
//     public ValueRange range(TemporalField field) {
//         if (cast(ChronoField)(field) !is null) {
//             if (isSupported(field)) {
//                 ChronoField f = cast(ChronoField) field;
//                 switch (f) {
//                     case DAY_OF_MONTH:
//                     case DAY_OF_YEAR:
//                     case ALIGNED_WEEK_OF_MONTH:
//                         return isoDate.range(field);
//                     case YEAR_OF_ERA: {
//                         ValueRange range = YEAR.range();
//                         long max = (getProlepticYear() <= 0 ? -range.getMinimum() + 1 + YEARS_DIFFERENCE : range.getMaximum() - YEARS_DIFFERENCE);
//                         return ValueRange.of(1, max);
//                     }
//                 }
//                 return getChronology().range(f);
//             }
//             throw new UnsupportedTemporalTypeException("Unsupported field: " ~ field);
//         }
//         return field.rangeRefinedBy(this);
//     }

//     override
//     public long getLong(TemporalField field) {
//         if (cast(ChronoField)(field) !is null) {
//             switch (cast(ChronoField) field) {
//                 case PROLEPTIC_MONTH:
//                     return getProlepticMonth();
//                 case YEAR_OF_ERA: {
//                     int prolepticYear = getProlepticYear();
//                     return (prolepticYear >= 1 ? prolepticYear : 1 - prolepticYear);
//                 }
//                 case YEAR:
//                     return getProlepticYear();
//                 case ERA:
//                     return (getProlepticYear() >= 1 ? 1 : 0);
//             }
//             return isoDate.getLong(field);
//         }
//         return field.getFrom(this);
//     }

//     private long getProlepticMonth() {
//         return getProlepticYear() * 12L + isoDate.getMonthValue() - 1;
//     }

//     private int getProlepticYear() {
//         return isoDate.getYear() - YEARS_DIFFERENCE;
//     }

//     //-----------------------------------------------------------------------
//     override
//     public MinguoDate _with(TemporalField field, long newValue) {
//         if (cast(ChronoField)(field) !is null) {
//             ChronoField f = cast(ChronoField) field;
//             if (getLong(f) == newValue) {
//                 return this;
//             }
//             switch (f) {
//                 case PROLEPTIC_MONTH:
//                     getChronology().range(f).checkValidValue(newValue, f);
//                     return plusMonths(newValue - getProlepticMonth());
//                 case YEAR_OF_ERA:
//                 case YEAR:
//                 case ERA: {
//                     int nvalue = getChronology().range(f).checkValidIntValue(newValue, f);
//                     switch (f) {
//                         case YEAR_OF_ERA:
//                             return _with(isoDate.withYear(getProlepticYear() >= 1 ? nvalue + YEARS_DIFFERENCE : (1 - nvalue)  + YEARS_DIFFERENCE));
//                         case YEAR:
//                             return _with(isoDate.withYear(nvalue + YEARS_DIFFERENCE));
//                         case ERA:
//                             return _with(isoDate.withYear((1 - getProlepticYear()) + YEARS_DIFFERENCE));
//                     }
//                 }
//             }
//             return _with(isoDate._with(field, newValue));
//         }
//         return super._with(field, newValue);
//     }

//     /**
//      * {@inheritDoc}
//      * @throws DateTimeException {@inheritDoc}
//      * @throws ArithmeticException {@inheritDoc}
//      */
//     override
//     public  MinguoDate _with(TemporalAdjuster adjuster) {
//         return super._with(adjuster);
//     }

//     /**
//      * {@inheritDoc}
//      * @throws DateTimeException {@inheritDoc}
//      * @throws ArithmeticException {@inheritDoc}
//      */
//     override
//     public MinguoDate plus(TemporalAmount amount) {
//         return super.plus(amount);
//     }

//     /**
//      * {@inheritDoc}
//      * @throws DateTimeException {@inheritDoc}
//      * @throws ArithmeticException {@inheritDoc}
//      */
//     override
//     public MinguoDate minus(TemporalAmount amount) {
//         return super.minus(amount);
//     }

//     //-----------------------------------------------------------------------
//     // override
//     MinguoDate plusYears(long years) {
//         return _with(isoDate.plusYears(years));
//     }

//     // override
//     MinguoDate plusMonths(long months) {
//         return _with(isoDate.plusMonths(months));
//     }

//     // override
//     MinguoDate plusWeeks(long weeksToAdd) {
//         return super.plusWeeks(weeksToAdd);
//     }

//     // override
//     MinguoDate plusDays(long days) {
//         return _with(isoDate.plusDays(days));
//     }

//     // override
//     public MinguoDate plus(long amountToAdd, TemporalUnit unit) {
//         return super.plus(amountToAdd, unit);
//     }

//     // override
//     public MinguoDate minus(long amountToAdd, TemporalUnit unit) {
//         return super.minus(amountToAdd, unit);
//     }

//     // override
//     MinguoDate minusYears(long yearsToSubtract) {
//         return super.minusYears(yearsToSubtract);
//     }

//     // override
//     MinguoDate minusMonths(long monthsToSubtract) {
//         return super.minusMonths(monthsToSubtract);
//     }

//     // override
//     MinguoDate minusWeeks(long weeksToSubtract) {
//         return super.minusWeeks(weeksToSubtract);
//     }

//     // override
//     MinguoDate minusDays(long daysToSubtract) {
//         return super.minusDays(daysToSubtract);
//     }

//     private MinguoDate _with(LocalDate newDate) {
//         return (newDate.equals(isoDate) ? this : new MinguoDate(newDate));
//     }

//     // override        // for javadoc and covariant return type
//     /*@SuppressWarnings("unchecked")*/
//     public final ChronoLocalDateTime!(MinguoDate) atTime(LocalTime localTime) {
//         return cast(ChronoLocalDateTime!(MinguoDate))super.atTime(localTime);
//     }

//     override
//     public ChronoPeriod until(ChronoLocalDate endDate) {
//         Period period = isoDate.until(endDate);
//         return getChronology().period(period.getYears(), period.getMonths(), period.getDays());
//     }

//     override  // override for performance
//     public long toEpochDay() {
//         return isoDate.toEpochDay();
//     }

//     //-------------------------------------------------------------------------
//     /**
//      * Compares this date to another date, including the chronology.
//      * !(p)
//      * Compares this {@code MinguoDate} with another ensuring that the date is the same.
//      * !(p)
//      * Only objects of type {@code MinguoDate} are compared, other types return false.
//      * To compare the dates of two {@code TemporalAccessor} instances, including dates
//      * _in two different chronologies, use {@link ChronoField#EPOCH_DAY} as a comparator.
//      *
//      * @param obj  the object to check, null returns false
//      * @return true if this is equal to the other date
//      */
//     override  // override for performance
//     public bool opEquals(Object obj) {
//         if (this is obj) {
//             return true;
//         }
//         if (cast(MinguoDate)(obj) !is null) {
//             MinguoDate otherDate = cast(MinguoDate) obj;
//             return this.isoDate.equals(otherDate.isoDate);
//         }
//         return false;
//     }

//     /**
//      * A hash code for this date.
//      *
//      * @return a suitable hash code based only on the Chronology and the date
//      */
//     override  // override for performance
//     public size_t toHash() @trusted nothrow {
//         return getChronology().getId().toHash() ^ isoDate.toHash();
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Defend against malicious streams.
//      *
//      * @param s the stream to read
//      * @throws InvalidObjectException always
//      */
//     ///@gxc
//     // private void readObject(ObjectInputStream s) /*throws InvalidObjectException*/ {
//     //     throw new InvalidObjectException("Deserialization via serialization delegate");
//     // }

//     /**
//      * Writes the object using a
//      * <a href="{@docRoot}/serialized-form.html#hunt.time.chrono.Ser">dedicated serialized form</a>.
//      * @serialData
//      * !(pre)
//      *  _out.writeByte(8);                 // identifies a MinguoDate
//      *  _out.writeInt(get(YEAR));
//      *  _out.writeByte(get(MONTH_OF_YEAR));
//      *  _out.writeByte(get(DAY_OF_MONTH));
//      * </pre>
//      *
//      * @return the instance of {@code Ser}, not null
//      */
//     private Object writeReplace() {
//         return new Ser(Ser.MINGUO_DATE_TYPE, this);
//     }

//     void writeExternal(DataOutput _out) /*throws IOException*/ {
//         // MinguoChronology is implicit _in the MINGUO_DATE_TYPE
//         _out.writeInt(get(YEAR));
//         _out.writeByte(get(MONTH_OF_YEAR));
//         _out.writeByte(get(DAY_OF_MONTH));
//     }

//     static MinguoDate readExternal(DataInput _in) /*throws IOException*/ {
//         int year = _in.readInt();
//         int month = _in.readByte();
//         int dayOfMonth = _in.readByte();
//         return MinguoChronology.INSTANCE.date(year, month, dayOfMonth);
//     }

// }
