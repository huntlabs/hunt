
module hunt.time.chrono.MinguoChronology;


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
// import hunt.container.List;
// import hunt.time.util.Locale;
// import hunt.container.Map;
// import hunt.time.chrono.AbstractChronology;
// import hunt.time.util.ServiceLoader;
// import hunt.time.chrono.MinguoDate;
// import hunt.time.chrono.Era;
// import hunt.time.chrono.ChronoLocalDateTime;
// import hunt.time.chrono.MinguoDate;
// import hunt.time.chrono.ChronoZonedDateTime;
// import hunt.time.chrono.MinguoEra;
// import hunt.lang;
// /**
//  * The Minguo calendar system.
//  * !(p)
//  * This chronology defines the rules of the Minguo calendar system.
//  * This calendar system is primarily used _in the Republic of China, often known as Taiwan.
//  * Dates are aligned such that {@code 0001-01-01 (Minguo)} is {@code 1912-01-01 (ISO)}.
//  * !(p)
//  * The fields are defined as follows:
//  * !(ul)
//  * !(li)era - There are two eras, the current 'Republic' (ERA_ROC) and the previous era (ERA_BEFORE_ROC).
//  * !(li)year-of-era - The year-of-era for the current era increases uniformly from the epoch at year one.
//  *  For the previous era the year increases from one as time goes backwards.
//  *  The value for the current era is equal to the ISO proleptic-year minus 1911.
//  * !(li)proleptic-year - The proleptic year is the same as the year-of-era for the
//  *  current era. For the previous era, years have zero, then negative values.
//  *  The value is equal to the ISO proleptic-year minus 1911.
//  * !(li)month-of-year - The Minguo month-of-year exactly matches ISO.
//  * !(li)day-of-month - The Minguo day-of-month exactly matches ISO.
//  * !(li)day-of-year - The Minguo day-of-year exactly matches ISO.
//  * !(li)leap-year - The Minguo leap-year pattern exactly matches ISO, such that the two calendars
//  *  are never _out of step.
//  * </ul>
//  *
//  * @implSpec
//  * This class is immutable and thread-safe.
//  *
//  * @since 1.8
//  */
// public final class MinguoChronology : AbstractChronology , Serializable {

//     mixin MakeServiceLoader!AbstractChronology;

//     /**
//      * Singleton instance for the Minguo chronology.
//      */
//     public __gshared MinguoChronology INSTANCE;

//     shared static this()
//     {
//         INSTANCE = new MinguoChronology();
//     }

//     /**
//      * Serialization version.
//      */
//     private enum long serialVersionUID = 1039765215346859963L;
//     /**
//      * The difference _in years between ISO and Minguo.
//      */
//     enum int YEARS_DIFFERENCE = 1911;

//     /**
//      * Restricted constructor.
//      */
//     private this() {
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Gets the ID of the chronology - 'Minguo'.
//      * !(p)
//      * The ID uniquely identifies the {@code Chronology}.
//      * It can be used to lookup the {@code Chronology} using {@link Chronology#of(string)}.
//      *
//      * @return the chronology ID - 'Minguo'
//      * @see #getCalendarType()
//      */
//     // override
//     public string getId() {
//         return "Minguo";
//     }

//     /**
//      * Gets the calendar type of the underlying calendar system - 'roc'.
//      * !(p)
//      * The calendar type is an identifier defined by the
//      * !(em)Unicode Locale Data Markup Language (LDML)</em> specification.
//      * It can be used to lookup the {@code Chronology} using {@link Chronology#of(string)}.
//      * It can also be used as part of a locale, accessible via
//      * {@link Locale#getUnicodeLocaleType(string)} with the key 'ca'.
//      *
//      * @return the calendar system type - 'roc'
//      * @see #getId()
//      */
//     // override
//     public string getCalendarType() {
//         return "roc";
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Obtains a local date _in Minguo calendar system from the
//      * era, year-of-era, month-of-year and day-of-month fields.
//      *
//      * @param era  the Minguo era, not null
//      * @param yearOfEra  the year-of-era
//      * @param month  the month-of-year
//      * @param dayOfMonth  the day-of-month
//      * @return the Minguo local date, not null
//      * @throws DateTimeException if unable to create the date
//      * @throws ClassCastException if the {@code era} is not a {@code MinguoEra}
//      */
//     // override
//     public MinguoDate date(Era era, int yearOfEra, int month, int dayOfMonth) {
//         return date(prolepticYear(era, yearOfEra), month, dayOfMonth);
//     }

//     /**
//      * Obtains a local date _in Minguo calendar system from the
//      * proleptic-year, month-of-year and day-of-month fields.
//      *
//      * @param prolepticYear  the proleptic-year
//      * @param month  the month-of-year
//      * @param dayOfMonth  the day-of-month
//      * @return the Minguo local date, not null
//      * @throws DateTimeException if unable to create the date
//      */
//     // override
//     public MinguoDate date(int prolepticYear, int month, int dayOfMonth) {
//         return new MinguoDate(LocalDate.of(prolepticYear + YEARS_DIFFERENCE, month, dayOfMonth));
//     }

//     /**
//      * Obtains a local date _in Minguo calendar system from the
//      * era, year-of-era and day-of-year fields.
//      *
//      * @param era  the Minguo era, not null
//      * @param yearOfEra  the year-of-era
//      * @param dayOfYear  the day-of-year
//      * @return the Minguo local date, not null
//      * @throws DateTimeException if unable to create the date
//      * @throws ClassCastException if the {@code era} is not a {@code MinguoEra}
//      */
//     // override
//     public MinguoDate dateYearDay(Era era, int yearOfEra, int dayOfYear) {
//         return dateYearDay(prolepticYear(era, yearOfEra), dayOfYear);
//     }

//     /**
//      * Obtains a local date _in Minguo calendar system from the
//      * proleptic-year and day-of-year fields.
//      *
//      * @param prolepticYear  the proleptic-year
//      * @param dayOfYear  the day-of-year
//      * @return the Minguo local date, not null
//      * @throws DateTimeException if unable to create the date
//      */
//     // override
//     public MinguoDate dateYearDay(int prolepticYear, int dayOfYear) {
//         return new MinguoDate(LocalDate.ofYearDay(prolepticYear + YEARS_DIFFERENCE, dayOfYear));
//     }

//     /**
//      * Obtains a local date _in the Minguo calendar system from the epoch-day.
//      *
//      * @param epochDay  the epoch day
//      * @return the Minguo local date, not null
//      * @throws DateTimeException if unable to create the date
//      */
//     // override  // override with covariant return type
//     public MinguoDate dateEpochDay(long epochDay) {
//         return new MinguoDate(LocalDate.ofEpochDay(epochDay));
//     }

//     // override
//     public MinguoDate dateNow() {
//         return dateNow(Clock.systemDefaultZone());
//     }

//     // override
//     public MinguoDate dateNow(ZoneId zone) {
//         return dateNow(Clock.system(zone));
//     }

//     // override
//     public MinguoDate dateNow(Clock clock) {
//         return date(LocalDate.now(clock));
//     }

//     // override
//     public MinguoDate date(TemporalAccessor temporal) {
//         if (cast(MinguoDate)(temporal) !is null) {
//             return cast(MinguoDate) temporal;
//         }
//         return new MinguoDate(LocalDate.from(temporal));
//     }

//     // override
//     /*@SuppressWarnings("unchecked")*/
//     public ChronoLocalDateTime!(MinguoDate) localDateTime(TemporalAccessor temporal) {
//         return cast(ChronoLocalDateTime!(MinguoDate))super.localDateTime(temporal);
//     }

//     // override
//     /*@SuppressWarnings("unchecked")*/
//     public ChronoZonedDateTime!(MinguoDate) zonedDateTime(TemporalAccessor temporal) {
//         return cast(ChronoZonedDateTime!(MinguoDate))super.zonedDateTime(temporal);
//     }

//     // override
//     /*@SuppressWarnings("unchecked")*/
//     public ChronoZonedDateTime!(MinguoDate) zonedDateTime(Instant instant, ZoneId zone) {
//         return cast(ChronoZonedDateTime!(MinguoDate))super.zonedDateTime(instant, zone);
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Checks if the specified year is a leap year.
//      * !(p)
//      * Minguo leap years occur exactly _in line with ISO leap years.
//      * This method does not validate the year passed _in, and only has a
//      * well-defined result for years _in the supported range.
//      *
//      * @param prolepticYear  the proleptic-year to check, not validated for range
//      * @return true if the year is a leap year
//      */
//     // override
//     public bool isLeapYear(long prolepticYear) {
//         return IsoChronology.INSTANCE.isLeapYear(prolepticYear + YEARS_DIFFERENCE);
//     }

//     // override
//     public int prolepticYear(Era era, int yearOfEra) {
//         if ((cast(MinguoEra)(era) !is null) == false) {
//             throw new ClassCastException("Era must be MinguoEra");
//         }
//         return (era == MinguoEra.ROC ? yearOfEra : 1 - yearOfEra);
//     }

//     // override
//     public MinguoEra eraOf(int eraValue) {
//         return MinguoEra.of(eraValue);
//     }

//     // override
//     public List!(Era) eras() {
//         return List.of(MinguoEra.values());
//     }

//     //-----------------------------------------------------------------------
//     // override
//     public ValueRange range(ChronoField field) {
//         switch (field) {
//             case PROLEPTIC_MONTH: {
//                 ValueRange range = PROLEPTIC_MONTH.range();
//                 return ValueRange.of(range.getMinimum() - YEARS_DIFFERENCE * 12L, range.getMaximum() - YEARS_DIFFERENCE * 12L);
//             }
//             case YEAR_OF_ERA: {
//                 ValueRange range = YEAR.range();
//                 return ValueRange.of(1, range.getMaximum() - YEARS_DIFFERENCE, -range.getMinimum() + 1 + YEARS_DIFFERENCE);
//             }
//             case YEAR: {
//                 ValueRange range = YEAR.range();
//                 return ValueRange.of(range.getMinimum() - YEARS_DIFFERENCE, range.getMaximum() - YEARS_DIFFERENCE);
//             }
//         }
//         return field.range();
//     }

//     //-----------------------------------------------------------------------
//     override  // override for return type
//     public MinguoDate resolveDate(Map!(TemporalField, Long) fieldValues, ResolverStyle resolverStyle) {
//         return cast(MinguoDate) super.resolveDate(fieldValues, resolverStyle);
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
//      ///@gxc
//     // private void readObject(ObjectInputStream s) /*throws InvalidObjectException*/ {
//     //     throw new InvalidObjectException("Deserialization via serialization delegate");
//     // }
// }
