
 module hunt.time.chrono.HijrahDate;

// import hunt.time.temporal.ChronoField;

// import hunt.lang.exception;

// import hunt.io.ObjectInput;
// //import hunt.io.ObjectInputStream;
// import hunt.io.ObjectOutput;
// import hunt.io.common;
// import hunt.time.Clock;
// import hunt.time.DateTimeException;
// import hunt.time.LocalDate;
// import hunt.time.LocalTime;
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

// /**
//  * A date _in the Hijrah calendar system.
//  * !(p)
//  * This date operates using one of several variants of the
//  * {@linkplain HijrahChronology Hijrah calendar}.
//  * !(p)
//  * The Hijrah calendar has a different total of days _in a year than
//  * Gregorian calendar, and the length of each month is based on the period
//  * of a complete revolution of the moon around the earth
//  * (as between successive new moons).
//  * Refer to the {@link HijrahChronology} for details of supported variants.
//  * !(p)
//  * Each HijrahDate is created bound to a particular HijrahChronology,
//  * The same chronology is propagated to each HijrahDate computed from the date.
//  * To use a different Hijrah variant, its HijrahChronology can be used
//  * to create new HijrahDate instances.
//  * Alternatively, the {@link #withVariant} method can be used to convert
//  * to a new HijrahChronology.
//  *
//  * !(p)
//  * This is a <a href="{@docRoot}/java.base/java/lang/doc-files/ValueBased.html">value-based</a>
//  * class; use of identity-sensitive operations (including reference equality
//  * ({@code ==}), identity hash code, or synchronization) on instances of
//  * {@code HijrahDate} may have unpredictable results and should be avoided.
//  * The {@code equals} method should be used for comparisons.
//  *
//  * @implSpec
//  * This class is immutable and thread-safe.
//  *
//  * @since 1.8
//  */
// public final class HijrahDate
//         : ChronoLocalDateImpl!(HijrahDate)
//         , ChronoLocalDate, Serializable {

//     /**
//      * Serialization version.
//      */
//     private static final long serialVersionUID = -5207853542612002020L;
//     /**
//      * The Chronology of this HijrahDate.
//      */
//     private final /*transient*/ HijrahChronology chrono;
//     /**
//      * The proleptic year.
//      */
//     private final /*transient*/ int prolepticYear;
//     /**
//      * The month-of-year.
//      */
//     private final /*transient*/ int monthOfYear;
//     /**
//      * The day-of-month.
//      */
//     private final /*transient*/ int dayOfMonth;

//     //-------------------------------------------------------------------------
//     /**
//      * Obtains an instance of {@code HijrahDate} from the Hijrah proleptic year,
//      * month-of-year and day-of-month.
//      *
//      * @param prolepticYear  the proleptic year to represent _in the Hijrah calendar
//      * @param monthOfYear  the month-of-year to represent, from 1 to 12
//      * @param dayOfMonth  the day-of-month to represent, from 1 to 30
//      * @return the Hijrah date, never null
//      * @throws DateTimeException if the value of any field is _out of range
//      */
//     static HijrahDate of(HijrahChronology chrono, int prolepticYear, int monthOfYear, int dayOfMonth) {
//         return new HijrahDate(chrono, prolepticYear, monthOfYear, dayOfMonth);
//     }

//     /**
//      * Returns a HijrahDate for the chronology and epochDay.
//      * @param chrono The Hijrah chronology
//      * @param epochDay the epoch day
//      * @return a HijrahDate for the epoch day; non-null
//      */
//     static HijrahDate ofEpochDay(HijrahChronology chrono, long epochDay) {
//         return new HijrahDate(chrono, epochDay);
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Obtains the current {@code HijrahDate} of the Islamic Umm Al-Qura calendar
//      * _in the default time-zone.
//      * !(p)
//      * This will query the {@link Clock#systemDefaultZone() system clock} _in the default
//      * time-zone to obtain the current date.
//      * !(p)
//      * Using this method will prevent the ability to use an alternate clock for testing
//      * because the clock is hard-coded.
//      *
//      * @return the current date using the system clock and default time-zone, not null
//      */
//     public static HijrahDate now() {
//         return now(Clock.systemDefaultZone());
//     }

//     /**
//      * Obtains the current {@code HijrahDate} of the Islamic Umm Al-Qura calendar
//      * _in the specified time-zone.
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
//     public static HijrahDate now(ZoneId zone) {
//         return now(Clock.system(zone));
//     }

//     /**
//      * Obtains the current {@code HijrahDate} of the Islamic Umm Al-Qura calendar
//      * from the specified clock.
//      * !(p)
//      * This will query the specified clock to obtain the current date - today.
//      * Using this method allows the use of an alternate clock for testing.
//      * The alternate clock may be introduced using {@linkplain Clock dependency injection}.
//      *
//      * @param clock  the clock to use, not null
//      * @return the current date, not null
//      * @throws DateTimeException if the current date cannot be obtained
//      */
//     public static HijrahDate now(Clock clock) {
//         return HijrahDate.ofEpochDay(HijrahChronology.INSTANCE, LocalDate.now(clock).toEpochDay());
//     }

//     /**
//      * Obtains a {@code HijrahDate} of the Islamic Umm Al-Qura calendar
//      * from the proleptic-year, month-of-year and day-of-month fields.
//      * !(p)
//      * This returns a {@code HijrahDate} with the specified fields.
//      * The day must be valid for the year and month, otherwise an exception will be thrown.
//      *
//      * @param prolepticYear  the Hijrah proleptic-year
//      * @param month  the Hijrah month-of-year, from 1 to 12
//      * @param dayOfMonth  the Hijrah day-of-month, from 1 to 30
//      * @return the date _in Hijrah calendar system, not null
//      * @throws DateTimeException if the value of any field is _out of range,
//      *  or if the day-of-month is invalid for the month-year
//      */
//     public static HijrahDate of(int prolepticYear, int month, int dayOfMonth) {
//         return HijrahChronology.INSTANCE.date(prolepticYear, month, dayOfMonth);
//     }

//     /**
//      * Obtains a {@code HijrahDate} of the Islamic Umm Al-Qura calendar from a temporal object.
//      * !(p)
//      * This obtains a date _in the Hijrah calendar system based on the specified temporal.
//      * A {@code TemporalAccessor} represents an arbitrary set of date and time information,
//      * which this factory converts to an instance of {@code HijrahDate}.
//      * !(p)
//      * The conversion typically uses the {@link ChronoField#EPOCH_DAY EPOCH_DAY}
//      * field, which is standardized across calendar systems.
//      * !(p)
//      * This method matches the signature of the functional interface {@link TemporalQuery}
//      * allowing it to be used as a query via method reference, {@code HijrahDate::from}.
//      *
//      * @param temporal  the temporal object to convert, not null
//      * @return the date _in Hijrah calendar system, not null
//      * @throws DateTimeException if unable to convert to a {@code HijrahDate}
//      */
//     public static HijrahDate from(TemporalAccessor temporal) {
//         return HijrahChronology.INSTANCE.date(temporal);
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Constructs an {@code HijrahDate} with the proleptic-year, month-of-year and
//      * day-of-month fields.
//      *
//      * @param chrono The chronology to create the date with
//      * @param prolepticYear the proleptic year
//      * @param monthOfYear the month of year
//      * @param dayOfMonth the day of month
//      */
//     private this(HijrahChronology chrono, int prolepticYear, int monthOfYear, int dayOfMonth) {
//         // Computing the Gregorian day checks the valid ranges
//         chrono.getEpochDay(prolepticYear, monthOfYear, dayOfMonth);

//         this.chrono = chrono;
//         this.prolepticYear = prolepticYear;
//         this.monthOfYear = monthOfYear;
//         this.dayOfMonth = dayOfMonth;
//     }

//     /**
//      * Constructs an instance with the Epoch Day.
//      *
//      * @param epochDay  the epochDay
//      */
//     private this(HijrahChronology chrono, long epochDay) {
//         int[] dateInfo = chrono.getHijrahDateInfo(cast(int)epochDay);

//         this.chrono = chrono;
//         this.prolepticYear = dateInfo[0];
//         this.monthOfYear = dateInfo[1];
//         this.dayOfMonth = dateInfo[2];
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Gets the chronology of this date, which is the Hijrah calendar system.
//      * !(p)
//      * The {@code Chronology} represents the calendar system _in use.
//      * The era and other fields _in {@link ChronoField} are defined by the chronology.
//      *
//      * @return the Hijrah chronology, not null
//      */
//     override
//     public HijrahChronology getChronology() {
//         return chrono;
//     }

//     /**
//      * Gets the era applicable at this date.
//      * !(p)
//      * The Hijrah calendar system has one era, 'AH',
//      * defined by {@link HijrahEra}.
//      *
//      * @return the era applicable at this date, not null
//      */
//     override
//     public HijrahEra getEra() {
//         return HijrahEra.AH;
//     }

//     /**
//      * Returns the length of the month represented by this date.
//      * !(p)
//      * This returns the length of the month _in days.
//      * Month lengths _in the Hijrah calendar system vary between 29 and 30 days.
//      *
//      * @return the length of the month _in days
//      */
//     override
//     public int lengthOfMonth() {
//         return chrono.getMonthLength(prolepticYear, monthOfYear);
//     }

//     /**
//      * Returns the length of the year represented by this date.
//      * !(p)
//      * This returns the length of the year _in days.
//      * A Hijrah calendar system year is typically shorter than
//      * that of the ISO calendar system.
//      *
//      * @return the length of the year _in days
//      */
//     override
//     public int lengthOfYear() {
//         return chrono.getYearLength(prolepticYear);
//     }

//     //-----------------------------------------------------------------------
//     override
//     public ValueRange range(TemporalField field) {
//         if (cast(ChronoField)(field) !is null) {
//             if (isSupported(field)) {
//                 ChronoField f = cast(ChronoField) field;
//                 switch (f) {
//                     case DAY_OF_MONTH: return ValueRange.of(1, lengthOfMonth());
//                     case DAY_OF_YEAR: return ValueRange.of(1, lengthOfYear());
//                     case ALIGNED_WEEK_OF_MONTH: return ValueRange.of(1, 5);  // TODO
//                     // TODO does the limited range of valid years cause years to
//                     // start/end part way through? that would affect range
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
//                 case DAY_OF_WEEK: return getDayOfWeek();
//                 case ALIGNED_DAY_OF_WEEK_IN_MONTH: return ((dayOfMonth - 1) % 7) + 1;
//                 case ALIGNED_DAY_OF_WEEK_IN_YEAR: return ((getDayOfYear() - 1) % 7) + 1;
//                 case DAY_OF_MONTH: return this.dayOfMonth;
//                 case DAY_OF_YEAR: return this.getDayOfYear();
//                 case EPOCH_DAY: return toEpochDay();
//                 case ALIGNED_WEEK_OF_MONTH: return ((dayOfMonth - 1) / 7) + 1;
//                 case ALIGNED_WEEK_OF_YEAR: return ((getDayOfYear() - 1) / 7) + 1;
//                 case MONTH_OF_YEAR: return monthOfYear;
//                 case PROLEPTIC_MONTH: return getProlepticMonth();
//                 case YEAR_OF_ERA: return prolepticYear;
//                 case YEAR: return prolepticYear;
//                 case ERA: return getEraValue();
//             }
//             throw new UnsupportedTemporalTypeException("Unsupported field: " ~ field);
//         }
//         return field.getFrom(this);
//     }

//     private long getProlepticMonth() {
//         return prolepticYear * 12L + monthOfYear - 1;
//     }

//     override
//     public HijrahDate _with(TemporalField field, long newValue) {
//         if (cast(ChronoField)(field) !is null) {
//             ChronoField f = cast(ChronoField) field;
//             // not using checkValidIntValue so EPOCH_DAY and PROLEPTIC_MONTH work
//             chrono.range(f).checkValidValue(newValue, f);    // TODO: validate value
//             int nvalue = cast(int) newValue;
//             switch (f) {
//                 case DAY_OF_WEEK: return plusDays(newValue - getDayOfWeek());
//                 case ALIGNED_DAY_OF_WEEK_IN_MONTH: return plusDays(newValue - getLong(ALIGNED_DAY_OF_WEEK_IN_MONTH));
//                 case ALIGNED_DAY_OF_WEEK_IN_YEAR: return plusDays(newValue - getLong(ALIGNED_DAY_OF_WEEK_IN_YEAR));
//                 case DAY_OF_MONTH: return resolvePreviousValid(prolepticYear, monthOfYear, nvalue);
//                 case DAY_OF_YEAR: return plusDays(Math.min(nvalue, lengthOfYear()) - getDayOfYear());
//                 case EPOCH_DAY: return new HijrahDate(chrono, newValue);
//                 case ALIGNED_WEEK_OF_MONTH: return plusDays((newValue - getLong(ALIGNED_WEEK_OF_MONTH)) * 7);
//                 case ALIGNED_WEEK_OF_YEAR: return plusDays((newValue - getLong(ALIGNED_WEEK_OF_YEAR)) * 7);
//                 case MONTH_OF_YEAR: return resolvePreviousValid(prolepticYear, nvalue, dayOfMonth);
//                 case PROLEPTIC_MONTH: return plusMonths(newValue - getProlepticMonth());
//                 case YEAR_OF_ERA: return resolvePreviousValid(prolepticYear >= 1 ? nvalue : 1 - nvalue, monthOfYear, dayOfMonth);
//                 case YEAR: return resolvePreviousValid(nvalue, monthOfYear, dayOfMonth);
//                 case ERA: return resolvePreviousValid(1 - prolepticYear, monthOfYear, dayOfMonth);
//             }
//             throw new UnsupportedTemporalTypeException("Unsupported field: " ~ field);
//         }
//         return super._with(field, newValue);
//     }

//     private HijrahDate resolvePreviousValid(int prolepticYear, int month, int day) {
//         int monthDays = chrono.getMonthLength(prolepticYear, month);
//         if (day > monthDays) {
//             day = monthDays;
//         }
//         return HijrahDate.of(chrono, prolepticYear, month, day);
//     }

//     /**
//      * {@inheritDoc}
//      * @throws DateTimeException if unable to make the adjustment.
//      *     For example, if the adjuster requires an ISO chronology
//      * @throws ArithmeticException {@inheritDoc}
//      */
//     override
//     public  HijrahDate _with(TemporalAdjuster adjuster) {
//         return super._with(adjuster);
//     }

//     /**
//      * Returns a {@code HijrahDate} with the Chronology requested.
//      * !(p)
//      * The year, month, and day are checked against the new requested
//      * HijrahChronology.  If the chronology has a shorter month length
//      * for the month, the day is reduced to be the last day of the month.
//      *
//      * @param chronology the new HijrahChonology, non-null
//      * @return a HijrahDate with the requested HijrahChronology, non-null
//      */
//     public HijrahDate withVariant(HijrahChronology chronology) {
//         if (chrono == chronology) {
//             return this;
//         }
//         // Like resolvePreviousValid the day is constrained to stay _in the same month
//         int monthDays = chronology.getDayOfYear(prolepticYear, monthOfYear);
//         return HijrahDate.of(chronology, prolepticYear, monthOfYear,(dayOfMonth > monthDays) ? monthDays : dayOfMonth );
//     }

//     /**
//      * {@inheritDoc}
//      * @throws DateTimeException {@inheritDoc}
//      * @throws ArithmeticException {@inheritDoc}
//      */
//     override
//     public HijrahDate plus(TemporalAmount amount) {
//         return super.plus(amount);
//     }

//     /**
//      * {@inheritDoc}
//      * @throws DateTimeException {@inheritDoc}
//      * @throws ArithmeticException {@inheritDoc}
//      */
//     override
//     public HijrahDate minus(TemporalAmount amount) {
//         return super.minus(amount);
//     }

//     override
//     public long toEpochDay() {
//         return chrono.getEpochDay(prolepticYear, monthOfYear, dayOfMonth);
//     }

//     /**
//      * Gets the day-of-year field.
//      * !(p)
//      * This method returns the primitive {@code int} value for the day-of-year.
//      *
//      * @return the day-of-year
//      */
//     private int getDayOfYear() {
//         return chrono.getDayOfYear(prolepticYear, monthOfYear) + dayOfMonth;
//     }

//     /**
//      * Gets the day-of-week value.
//      *
//      * @return the day-of-week; computed from the epochday
//      */
//     private int getDayOfWeek() {
//         int dow0 = Math.floorMod(toEpochDay() + 3, 7);
//         return dow0 + 1;
//     }

//     /**
//      * Gets the Era of this date.
//      *
//      * @return the Era of this date; computed from epochDay
//      */
//     private int getEraValue() {
//         return (prolepticYear > 1 ? 1 : 0);
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Checks if the year is a leap year, according to the Hijrah calendar system rules.
//      *
//      * @return true if this date is _in a leap year
//      */
//     override
//     public bool isLeapYear() {
//         return chrono.isLeapYear(prolepticYear);
//     }

//     //-----------------------------------------------------------------------
//     override
//     HijrahDate plusYears(long years) {
//         if (years == 0) {
//             return this;
//         }
//         int newYear = Math.addExact(this.prolepticYear, cast(int)years);
//         return resolvePreviousValid(newYear, monthOfYear, dayOfMonth);
//     }

//     override
//     HijrahDate plusMonths(long monthsToAdd) {
//         if (monthsToAdd == 0) {
//             return this;
//         }
//         long monthCount = prolepticYear * 12L + (monthOfYear - 1);
//         long calcMonths = monthCount + monthsToAdd;  // safe overflow
//         int newYear = chrono.checkValidYear(Math.floorDiv(calcMonths, 12L));
//         int newMonth = cast(int)Math.floorMod(calcMonths, 12L) + 1;
//         return resolvePreviousValid(newYear, newMonth, dayOfMonth);
//     }

//     override
//     HijrahDate plusWeeks(long weeksToAdd) {
//         return super.plusWeeks(weeksToAdd);
//     }

//     override
//     HijrahDate plusDays(long days) {
//         return new HijrahDate(chrono, toEpochDay() + days);
//     }

//     override
//     public HijrahDate plus(long amountToAdd, TemporalUnit unit) {
//         return super.plus(amountToAdd, unit);
//     }

//     override
//     public HijrahDate minus(long amountToSubtract, TemporalUnit unit) {
//         return super.minus(amountToSubtract, unit);
//     }

//     override
//     HijrahDate minusYears(long yearsToSubtract) {
//         return super.minusYears(yearsToSubtract);
//     }

//     override
//     HijrahDate minusMonths(long monthsToSubtract) {
//         return super.minusMonths(monthsToSubtract);
//     }

//     override
//     HijrahDate minusWeeks(long weeksToSubtract) {
//         return super.minusWeeks(weeksToSubtract);
//     }

//     override
//     HijrahDate minusDays(long daysToSubtract) {
//         return super.minusDays(daysToSubtract);
//     }

//     override        // for javadoc and covariant return type
//     /*@SuppressWarnings("unchecked")*/
//     public final ChronoLocalDateTime!(HijrahDate) atTime(LocalTime localTime) {
//         return cast(ChronoLocalDateTime!(HijrahDate))super.atTime(localTime);
//     }

//     override
//     public ChronoPeriod until(ChronoLocalDate endDate) {
//         // TODO: untested
//         HijrahDate end = getChronology().date(endDate);
//         long totalMonths = (end.prolepticYear - this.prolepticYear) * 12 + (end.monthOfYear - this.monthOfYear);  // safe
//         int days = end.dayOfMonth - this.dayOfMonth;
//         if (totalMonths > 0 && days < 0) {
//             totalMonths--;
//             HijrahDate calcDate = this.plusMonths(totalMonths);
//             days = cast(int) (end.toEpochDay() - calcDate.toEpochDay());  // safe
//         } else if (totalMonths < 0 && days > 0) {
//             totalMonths++;
//             days -= end.lengthOfMonth();
//         }
//         long years = totalMonths / 12;  // safe
//         int months = cast(int) (totalMonths % 12);  // safe
//         return getChronology().period(Math.toIntExact(years), months, days);
//     }

//     //-------------------------------------------------------------------------
//     /**
//      * Compares this date to another date, including the chronology.
//      * !(p)
//      * Compares this {@code HijrahDate} with another ensuring that the date is the same.
//      * !(p)
//      * Only objects of type {@code HijrahDate} are compared, other types return false.
//      * To compare the dates of two {@code TemporalAccessor} instances, including dates
//      * _in two different chronologies, use {@link ChronoField#EPOCH_DAY} as a comparator.
//      *
//      * @param obj  the object to check, null returns false
//      * @return true if this is equal to the other date and the Chronologies are equal
//      */
//     override  // override for performance
//     public bool opEquals(Object obj) {
//         if (this is obj) {
//             return true;
//         }
//         if (cast(HijrahDate)(obj) !is null) {
//             HijrahDate otherDate = cast(HijrahDate) obj;
//             return prolepticYear == otherDate.prolepticYear
//                 && this.monthOfYear == otherDate.monthOfYear
//                 && this.dayOfMonth == otherDate.dayOfMonth
//                 && getChronology().equals(otherDate.getChronology());
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
//         int yearValue = prolepticYear;
//         int monthValue = monthOfYear;
//         int dayValue = dayOfMonth;
//         return getChronology().getId().toHash() ^ (yearValue & 0xFFFFF800)
//                 ^ ((yearValue << 11) + (monthValue << 6) + (dayValue));
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Defend against malicious streams.
//      *
//      * @param s the stream to read
//      * @throws InvalidObjectException always
//      */
//     private void readObject(ObjectInputStream s) /*throws InvalidObjectException*/ {
//         throw new InvalidObjectException("Deserialization via serialization delegate");
//     }

//     /**
//      * Writes the object using a
//      * <a href="{@docRoot}/serialized-form.html#hunt.time.chrono.Ser">dedicated serialized form</a>.
//      * @serialData
//      * !(pre)
//      *  _out.writeByte(6);                 // identifies a HijrahDate
//      *  _out.writeObject(chrono);          // the HijrahChronology variant
//      *  _out.writeInt(get(YEAR));
//      *  _out.writeByte(get(MONTH_OF_YEAR));
//      *  _out.writeByte(get(DAY_OF_MONTH));
//      * </pre>
//      *
//      * @return the instance of {@code Ser}, not null
//      */
//     private Object writeReplace() {
//         return new Ser(Ser.HIJRAH_DATE_TYPE, this);
//     }

//     void writeExternal(ObjectOutput _out) /*throws IOException*/ {
//         // HijrahChronology is implicit _in the Hijrah_DATE_TYPE
//         _out.writeObject(getChronology());
//         _out.writeInt(get(YEAR));
//         _out.writeByte(get(MONTH_OF_YEAR));
//         _out.writeByte(get(DAY_OF_MONTH));
//     }

//     static HijrahDate readExternal(ObjectInput _in) /*throws IOException, ClassNotFoundException*/ {
//         HijrahChronology chrono = cast(HijrahChronology) _in.readObject();
//         int year = _in.readInt();
//         int month = _in.readByte();
//         int dayOfMonth = _in.readByte();
//         return chrono.date(year, month, dayOfMonth);
//     }

// }
