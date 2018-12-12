
module hunt.time.chrono.ThaiBuddhistChronology;


// import hunt.time.temporal.ChronoField;

// //import hunt.io.ObjectInputStream;
// import hunt.io.Serializable;
// import hunt.time.Clock;
// import hunt.time.DateTimeException;
// import hunt.time.Instant;
// import hunt.time.LocalDate;
// import hunt.time.ZoneId;
// import hunt.time.format.ResolverStyle;
// import hunt.time.temporal.ChronoField;
// import hunt.time.temporal.TemporalAccessor;
// import hunt.time.temporal.TemporalField;
// import hunt.time.temporal.ValueRange;
// import hunt.time.util;
// //import hunt.util.concurrent.ConcurrentMap;;

// import hunt.container.List;
// import hunt.time.util.Locale;
// import hunt.container.Map;

// /**
//  * The Thai Buddhist calendar system.
//  * !(p)
//  * This chronology defines the rules of the Thai Buddhist calendar system.
//  * This calendar system is primarily used _in Thailand.
//  * Dates are aligned such that {@code 2484-01-01 (Buddhist)} is {@code 1941-01-01 (ISO)}.
//  * !(p)
//  * The fields are defined as follows:
//  * !(ul)
//  * !(li)era - There are two eras, the current 'Buddhist' (ERA_BE) and the previous era (ERA_BEFORE_BE).
//  * !(li)year-of-era - The year-of-era for the current era increases uniformly from the epoch at year one.
//  *  For the previous era the year increases from one as time goes backwards.
//  *  The value for the current era is equal to the ISO proleptic-year plus 543.
//  * !(li)proleptic-year - The proleptic year is the same as the year-of-era for the
//  *  current era. For the previous era, years have zero, then negative values.
//  *  The value is equal to the ISO proleptic-year plus 543.
//  * !(li)month-of-year - The ThaiBuddhist month-of-year exactly matches ISO.
//  * !(li)day-of-month - The ThaiBuddhist day-of-month exactly matches ISO.
//  * !(li)day-of-year - The ThaiBuddhist day-of-year exactly matches ISO.
//  * !(li)leap-year - The ThaiBuddhist leap-year pattern exactly matches ISO, such that the two calendars
//  *  are never _out of step.
//  * </ul>
//  *
//  * @implSpec
//  * This class is immutable and thread-safe.
//  *
//  * @since 1.8
//  */
// public final class ThaiBuddhistChronology : AbstractChronology , Serializable {

//     mixin MakeServiceLoader!AbstractChronology;

//     /**
//      * Singleton instance of the Buddhist chronology.
//      */
//     public static final ThaiBuddhistChronology INSTANCE = new ThaiBuddhistChronology();

//     /**
//      * Serialization version.
//      */
//     private static final long serialVersionUID = 2775954514031616474L;
//     /**
//      * Containing the offset to add to the ISO year.
//      */
//     static final int YEARS_DIFFERENCE = 543;
//     /**
//      * Narrow names for eras.
//      */
//     private static final HashMap!(string, string[]) ERA_NARROW_NAMES = new HashMap!()();
//     /**
//      * Short names for eras.
//      */
//     private static final HashMap!(string, string[]) ERA_SHORT_NAMES = new HashMap!()();
//     /**
//      * Full names for eras.
//      */
//     private static final HashMap!(string, string[]) ERA_FULL_NAMES = new HashMap!()();
//     /**
//      * Fallback language for the era names.
//      */
//     private static final string FALLBACK_LANGUAGE = "en";
//     /**
//      * Language that has the era names.
//      */
//     private static final string TARGET_LANGUAGE = "th";
//     /**
//      * Name data.
//      */
//     static this(){
//         ERA_NARROW_NAMES.put(FALLBACK_LANGUAGE, ["BB", "BE"]);
//         ERA_NARROW_NAMES.put(TARGET_LANGUAGE, ["BB", "BE"]);
//         ERA_SHORT_NAMES.put(FALLBACK_LANGUAGE, ["B.B.", "B.E."]);
//         ERA_SHORT_NAMES.put(TARGET_LANGUAGE,
//                 ["\u0e1e.\u0e28.",
//                 "\u0e1b\u0e35\u0e01\u0e48\u0e2d\u0e19\u0e04\u0e23\u0e34\u0e2a\u0e15\u0e4c\u0e01\u0e32\u0e25\u0e17\u0e35\u0e48"]);
//         ERA_FULL_NAMES.put(FALLBACK_LANGUAGE, ["Before Buddhist", "Budhhist Era"]);
//         ERA_FULL_NAMES.put(TARGET_LANGUAGE,
//                 ["\u0e1e\u0e38\u0e17\u0e18\u0e28\u0e31\u0e01\u0e23\u0e32\u0e0a",
//                 "\u0e1b\u0e35\u0e01\u0e48\u0e2d\u0e19\u0e04\u0e23\u0e34\u0e2a\u0e15\u0e4c\u0e01\u0e32\u0e25\u0e17\u0e35\u0e48"]);
//     }

//     /**
//      * Restricted constructor.
//      */
//     private this() {
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Gets the ID of the chronology - 'ThaiBuddhist'.
//      * !(p)
//      * The ID uniquely identifies the {@code Chronology}.
//      * It can be used to lookup the {@code Chronology} using {@link Chronology#of(string)}.
//      *
//      * @return the chronology ID - 'ThaiBuddhist'
//      * @see #getCalendarType()
//      */
//     override
//     public string getId() {
//         return "ThaiBuddhist";
//     }

//     /**
//      * Gets the calendar type of the underlying calendar system - 'buddhist'.
//      * !(p)
//      * The calendar type is an identifier defined by the
//      * !(em)Unicode Locale Data Markup Language (LDML)</em> specification.
//      * It can be used to lookup the {@code Chronology} using {@link Chronology#of(string)}.
//      * It can also be used as part of a locale, accessible via
//      * {@link Locale#getUnicodeLocaleType(string)} with the key 'ca'.
//      *
//      * @return the calendar system type - 'buddhist'
//      * @see #getId()
//      */
//     override
//     public string getCalendarType() {
//         return "buddhist";
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Obtains a local date _in Thai Buddhist calendar system from the
//      * era, year-of-era, month-of-year and day-of-month fields.
//      *
//      * @param era  the Thai Buddhist era, not null
//      * @param yearOfEra  the year-of-era
//      * @param month  the month-of-year
//      * @param dayOfMonth  the day-of-month
//      * @return the Thai Buddhist local date, not null
//      * @throws DateTimeException if unable to create the date
//      * @throws ClassCastException if the {@code era} is not a {@code ThaiBuddhistEra}
//      */
//     override
//     public ThaiBuddhistDate date(Era era, int yearOfEra, int month, int dayOfMonth) {
//         return date(prolepticYear(era, yearOfEra), month, dayOfMonth);
//     }

//     /**
//      * Obtains a local date _in Thai Buddhist calendar system from the
//      * proleptic-year, month-of-year and day-of-month fields.
//      *
//      * @param prolepticYear  the proleptic-year
//      * @param month  the month-of-year
//      * @param dayOfMonth  the day-of-month
//      * @return the Thai Buddhist local date, not null
//      * @throws DateTimeException if unable to create the date
//      */
//     override
//     public ThaiBuddhistDate date(int prolepticYear, int month, int dayOfMonth) {
//         return new ThaiBuddhistDate(LocalDate.of(prolepticYear - YEARS_DIFFERENCE, month, dayOfMonth));
//     }

//     /**
//      * Obtains a local date _in Thai Buddhist calendar system from the
//      * era, year-of-era and day-of-year fields.
//      *
//      * @param era  the Thai Buddhist era, not null
//      * @param yearOfEra  the year-of-era
//      * @param dayOfYear  the day-of-year
//      * @return the Thai Buddhist local date, not null
//      * @throws DateTimeException if unable to create the date
//      * @throws ClassCastException if the {@code era} is not a {@code ThaiBuddhistEra}
//      */
//     override
//     public ThaiBuddhistDate dateYearDay(Era era, int yearOfEra, int dayOfYear) {
//         return dateYearDay(prolepticYear(era, yearOfEra), dayOfYear);
//     }

//     /**
//      * Obtains a local date _in Thai Buddhist calendar system from the
//      * proleptic-year and day-of-year fields.
//      *
//      * @param prolepticYear  the proleptic-year
//      * @param dayOfYear  the day-of-year
//      * @return the Thai Buddhist local date, not null
//      * @throws DateTimeException if unable to create the date
//      */
//     override
//     public ThaiBuddhistDate dateYearDay(int prolepticYear, int dayOfYear) {
//         return new ThaiBuddhistDate(LocalDate.ofYearDay(prolepticYear - YEARS_DIFFERENCE, dayOfYear));
//     }

//     /**
//      * Obtains a local date _in the Thai Buddhist calendar system from the epoch-day.
//      *
//      * @param epochDay  the epoch day
//      * @return the Thai Buddhist local date, not null
//      * @throws DateTimeException if unable to create the date
//      */
//     override  // override with covariant return type
//     public ThaiBuddhistDate dateEpochDay(long epochDay) {
//         return new ThaiBuddhistDate(LocalDate.ofEpochDay(epochDay));
//     }

//     override
//     public ThaiBuddhistDate dateNow() {
//         return dateNow(Clock.systemDefaultZone());
//     }

//     override
//     public ThaiBuddhistDate dateNow(ZoneId zone) {
//         return dateNow(Clock.system(zone));
//     }

//     override
//     public ThaiBuddhistDate dateNow(Clock clock) {
//         return date(LocalDate.now(clock));
//     }

//     override
//     public ThaiBuddhistDate date(TemporalAccessor temporal) {
//         if (cast(ThaiBuddhistDate)(temporal) !is null) {
//             return cast(ThaiBuddhistDate) temporal;
//         }
//         return new ThaiBuddhistDate(LocalDate.from(temporal));
//     }

//     override
//     /*@SuppressWarnings("unchecked")*/
//     public ChronoLocalDateTime!(ThaiBuddhistDate) localDateTime(TemporalAccessor temporal) {
//         return cast(ChronoLocalDateTime!(ThaiBuddhistDate))super.localDateTime(temporal);
//     }

//     override
//     /*@SuppressWarnings("unchecked")*/
//     public ChronoZonedDateTime!(ThaiBuddhistDate) zonedDateTime(TemporalAccessor temporal) {
//         return cast(ChronoZonedDateTime!(ThaiBuddhistDate))super.zonedDateTime(temporal);
//     }

//     override
//     /*@SuppressWarnings("unchecked")*/
//     public ChronoZonedDateTime!(ThaiBuddhistDate) zonedDateTime(Instant instant, ZoneId zone) {
//         return cast(ChronoZonedDateTime!(ThaiBuddhistDate))super.zonedDateTime(instant, zone);
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Checks if the specified year is a leap year.
//      * !(p)
//      * Thai Buddhist leap years occur exactly _in line with ISO leap years.
//      * This method does not validate the year passed _in, and only has a
//      * well-defined result for years _in the supported range.
//      *
//      * @param prolepticYear  the proleptic-year to check, not validated for range
//      * @return true if the year is a leap year
//      */
//     override
//     public bool isLeapYear(long prolepticYear) {
//         return IsoChronology.INSTANCE.isLeapYear(prolepticYear - YEARS_DIFFERENCE);
//     }

//     override
//     public int prolepticYear(Era era, int yearOfEra) {
//         if ((cast(ThaiBuddhistEra)(era) !is null) == false) {
//             throw new ClassCastException("Era must be BuddhistEra");
//         }
//         return (era == ThaiBuddhistEra.BE ? yearOfEra : 1 - yearOfEra);
//     }

//     override
//     public ThaiBuddhistEra eraOf(int eraValue) {
//         return ThaiBuddhistEra.of(eraValue);
//     }

//     override
//     public List!(Era) eras() {
//         return List.of(ThaiBuddhistEra.values());
//     }

//     //-----------------------------------------------------------------------
//     override
//     public ValueRange range(ChronoField field) {
//         switch (field) {
//             case PROLEPTIC_MONTH: {
//                 ValueRange range = PROLEPTIC_MONTH.range();
//                 return ValueRange.of(range.getMinimum() + YEARS_DIFFERENCE * 12L, range.getMaximum() + YEARS_DIFFERENCE * 12L);
//             }
//             case YEAR_OF_ERA: {
//                 ValueRange range = YEAR.range();
//                 return ValueRange.of(1, -(range.getMinimum() + YEARS_DIFFERENCE) + 1, range.getMaximum() + YEARS_DIFFERENCE);
//             }
//             case YEAR: {
//                 ValueRange range = YEAR.range();
//                 return ValueRange.of(range.getMinimum() + YEARS_DIFFERENCE, range.getMaximum() + YEARS_DIFFERENCE);
//             }
//         }
//         return field.range();
//     }

//     //-----------------------------------------------------------------------
//     override  // override for return type
//     public ThaiBuddhistDate resolveDate(Map!(TemporalField, Long) fieldValues, ResolverStyle resolverStyle) {
//         return cast(ThaiBuddhistDate) super.resolveDate(fieldValues, resolverStyle);
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Writes the Chronology using a
//      * <a href="{@docRoot}/serialized-form.html#hunt.time.chrono.Ser">dedicated serialized form</a>.
//      * @serialData
//      * !(pre)
//      *  _out.writeByte(1);     // identifies a Chronology
//      *  _out.writeUTF(getId());
//      * </pre>
//      *
//      * @return the instance of {@code Ser}, not null
//      */
//     override
//     Object writeReplace() {
//         return super.writeReplace();
//     }

//     /**
//      * Defend against malicious streams.
//      *
//      * @param s the stream to read
//      * @throws InvalidObjectException always
//      */
//     private void readObject(ObjectInputStream s) /*throws InvalidObjectException*/ {
//         throw new InvalidObjectException("Deserialization via serialization delegate");
//     }
// }
