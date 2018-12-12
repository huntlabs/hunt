
module hunt.time.chrono.JapaneseChronology;

// import hunt.time.temporal.ChronoField;
// import hunt.time.temporal.ChronoUnit;


// //import hunt.io.ObjectInputStream;
// import hunt.io.Serializable;
// import hunt.time.Clock;
// import hunt.time.DateTimeException;
// import hunt.time.Instant;
// import hunt.time.LocalDate;
// import hunt.time.Year;
// import hunt.time.ZoneId;
// import hunt.time.format.ResolverStyle;
// import hunt.time.temporal.ChronoField;
// import hunt.time.temporal.TemporalAccessor;
// import hunt.time.temporal.TemporalAdjusters;
// import hunt.time.temporal.TemporalField;
// import hunt.time.temporal.UnsupportedTemporalTypeException;
// import hunt.time.temporal.ValueRange;
// import hunt.time.util.Calendar;
// import hunt.container.List;
// import hunt.time.util.Locale;
// import hunt.container.Map;
// import hunt.time.chrono.AbstractChronology;
// import hunt.time.util.ServiceLoader;
// import hunt.time.chrono.JapaneseChronology;
// import hunt.time.chrono.Era;
// import hunt.time.chrono.ChronoLocalDateTime;
// import hunt.time.chrono.JapaneseDate;
// import hunt.time.chrono.JapaneseEra;
// import hunt.lang;
// import hunt.time.chrono.chrldi
// // import sun.util.calendar.CalendarSystem;
// // import sun.util.calendar.LocalGregorianCalendar;

// /**
//  * The Japanese Imperial calendar system.
//  * !(p)
//  * This chronology defines the rules of the Japanese Imperial calendar system.
//  * This calendar system is primarily used _in Japan.
//  * The Japanese Imperial calendar system is the same as the ISO calendar system
//  * apart from the era-based year numbering.
//  * !(p)
//  * Japan introduced the Gregorian calendar starting with Meiji 6.
//  * Only Meiji and later eras are supported;
//  * dates before Meiji 6, January 1 are not supported.
//  * !(p)
//  * The supported {@code ChronoField} instances are:
//  * !(ul)
//  * !(li){@code DAY_OF_WEEK}
//  * !(li){@code DAY_OF_MONTH}
//  * !(li){@code DAY_OF_YEAR}
//  * !(li){@code EPOCH_DAY}
//  * !(li){@code MONTH_OF_YEAR}
//  * !(li){@code PROLEPTIC_MONTH}
//  * !(li){@code YEAR_OF_ERA}
//  * !(li){@code YEAR}
//  * !(li){@code ERA}
//  * </ul>
//  *
//  * @implSpec
//  * This class is immutable and thread-safe.
//  *
//  * @since 1.8
//  */
// public final class JapaneseChronology : AbstractChronology , Serializable {

//     mixin MakeServiceLoader!AbstractChronology;

//     // __gshared LocalGregorianCalendar JCAL;

//     // Locale for creating a JapaneseImpericalCalendar.
//     __gshared Locale LOCALE;

//     /**
//      * Singleton instance for Japanese chronology.
//      */
//     public __gshared JapaneseChronology INSTANCE;

//     /**
//      * Serialization version.
//      */
//     private enum long serialVersionUID = 459996390165777884L;

//     shared static this()
//     {
//         // JCAL =
//         // cast(LocalGregorianCalendar) CalendarSystem.forName("japanese");
//         // LOCALE = Locale.forLanguageTag("ja-JP-u-ca-japanese");
//         // INSTANCE = new JapaneseChronology();
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Restricted constructor.
//      */
//     private this() {
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Gets the ID of the chronology - 'Japanese'.
//      * !(p)
//      * The ID uniquely identifies the {@code Chronology}.
//      * It can be used to lookup the {@code Chronology} using {@link Chronology#of(string)}.
//      *
//      * @return the chronology ID - 'Japanese'
//      * @see #getCalendarType()
//      */
//     // override
//     public string getId() {
//         return "Japanese";
//     }

//     /**
//      * Gets the calendar type of the underlying calendar system - 'japanese'.
//      * !(p)
//      * The calendar type is an identifier defined by the
//      * !(em)Unicode Locale Data Markup Language (LDML)</em> specification.
//      * It can be used to lookup the {@code Chronology} using {@link Chronology#of(string)}.
//      * It can also be used as part of a locale, accessible via
//      * {@link Locale#getUnicodeLocaleType(string)} with the key 'ca'.
//      *
//      * @return the calendar system type - 'japanese'
//      * @see #getId()
//      */
//     // override
//     public string getCalendarType() {
//         return "japanese";
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Obtains a local date _in Japanese calendar system from the
//      * era, year-of-era, month-of-year and day-of-month fields.
//      * !(p)
//      * The Japanese month and day-of-month are the same as those _in the
//      * ISO calendar system. They are not reset when the era changes.
//      * For example:
//      * !(pre)
//      *  6th Jan Showa 64 = ISO 1989-01-06
//      *  7th Jan Showa 64 = ISO 1989-01-07
//      *  8th Jan Heisei 1 = ISO 1989-01-08
//      *  9th Jan Heisei 1 = ISO 1989-01-09
//      * </pre>
//      *
//      * @param era  the Japanese era, not null
//      * @param yearOfEra  the year-of-era
//      * @param month  the month-of-year
//      * @param dayOfMonth  the day-of-month
//      * @return the Japanese local date, not null
//      * @throws DateTimeException if unable to create the date
//      * @throws ClassCastException if the {@code era} is not a {@code JapaneseEra}
//      */
//     override
//     public JapaneseDate date(Era era, int yearOfEra, int month, int dayOfMonth) {
//         if ((cast(JapaneseEra)(era) !is null) == false) {
//             throw new ClassCastException("Era must be JapaneseEra");
//         }
//         return JapaneseDate.of(cast(JapaneseEra) era, yearOfEra, month, dayOfMonth);
//     }

//     /**
//      * Obtains a local date _in Japanese calendar system from the
//      * proleptic-year, month-of-year and day-of-month fields.
//      * !(p)
//      * The Japanese proleptic year, month and day-of-month are the same as those
//      * _in the ISO calendar system. They are not reset when the era changes.
//      *
//      * @param prolepticYear  the proleptic-year
//      * @param month  the month-of-year
//      * @param dayOfMonth  the day-of-month
//      * @return the Japanese local date, not null
//      * @throws DateTimeException if unable to create the date
//      */
//     override
//     public JapaneseDate date(int prolepticYear, int month, int dayOfMonth) {
//         return new JapaneseDate(LocalDate.of(prolepticYear, month, dayOfMonth));
//     }

//     /**
//      * Obtains a local date _in Japanese calendar system from the
//      * era, year-of-era and day-of-year fields.
//      * !(p)
//      * The day-of-year _in this factory is expressed relative to the start of the year-of-era.
//      * This definition changes the normal meaning of day-of-year only _in those years
//      * where the year-of-era is reset to one due to a change _in the era.
//      * For example:
//      * !(pre)
//      *  6th Jan Showa 64 = day-of-year 6
//      *  7th Jan Showa 64 = day-of-year 7
//      *  8th Jan Heisei 1 = day-of-year 1
//      *  9th Jan Heisei 1 = day-of-year 2
//      * </pre>
//      *
//      * @param era  the Japanese era, not null
//      * @param yearOfEra  the year-of-era
//      * @param dayOfYear  the day-of-year
//      * @return the Japanese local date, not null
//      * @throws DateTimeException if unable to create the date
//      * @throws ClassCastException if the {@code era} is not a {@code JapaneseEra}
//      */
//     override
//     public JapaneseDate dateYearDay(Era era, int yearOfEra, int dayOfYear) {
//         return JapaneseDate.ofYearDay(cast(JapaneseEra) era, yearOfEra, dayOfYear);
//     }

//     /**
//      * Obtains a local date _in Japanese calendar system from the
//      * proleptic-year and day-of-year fields.
//      * !(p)
//      * The day-of-year _in this factory is expressed relative to the start of the proleptic year.
//      * The Japanese proleptic year and day-of-year are the same as those _in the ISO calendar system.
//      * They are not reset when the era changes.
//      *
//      * @param prolepticYear  the proleptic-year
//      * @param dayOfYear  the day-of-year
//      * @return the Japanese local date, not null
//      * @throws DateTimeException if unable to create the date
//      */
//     override
//     public JapaneseDate dateYearDay(int prolepticYear, int dayOfYear) {
//         return new JapaneseDate(LocalDate.ofYearDay(prolepticYear, dayOfYear));
//     }

//     /**
//      * Obtains a local date _in the Japanese calendar system from the epoch-day.
//      *
//      * @param epochDay  the epoch day
//      * @return the Japanese local date, not null
//      * @throws DateTimeException if unable to create the date
//      */
//     override  // override with covariant return type
//     public JapaneseDate dateEpochDay(long epochDay) {
//         return new JapaneseDate(LocalDate.ofEpochDay(epochDay));
//     }

//     override
//     public JapaneseDate dateNow() {
//         return dateNow(Clock.systemDefaultZone());
//     }

//     override
//     public JapaneseDate dateNow(ZoneId zone) {
//         return dateNow(Clock.system(zone));
//     }

//     override
//     public JapaneseDate dateNow(Clock clock) {
//         return date(LocalDate.now(clock));
//     }

//     override
//     public JapaneseDate date(TemporalAccessor temporal) {
//         if (cast(JapaneseDate)(temporal) !is null) {
//             return cast(JapaneseDate) temporal;
//         }
//         return new JapaneseDate(LocalDate.from(temporal));
//     }

//     override
//     /*@SuppressWarnings("unchecked")*/
//     public ChronoLocalDateTime!(JapaneseDate) localDateTime(TemporalAccessor temporal) {
//         return cast(ChronoLocalDateTime!(JapaneseDate))super.localDateTime(temporal);
//     }

//     override
//     /*@SuppressWarnings("unchecked")*/
//     public ChronoZonedDateTime!(JapaneseDate) zonedDateTime(TemporalAccessor temporal) {
//         return cast(ChronoZonedDateTime!(JapaneseDate))super.zonedDateTime(temporal);
//     }

//     override
//     /*@SuppressWarnings("unchecked")*/
//     public ChronoZonedDateTime!(JapaneseDate) zonedDateTime(Instant instant, ZoneId zone) {
//         return cast(ChronoZonedDateTime!(JapaneseDate))super.zonedDateTime(instant, zone);
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Checks if the specified year is a leap year.
//      * !(p)
//      * Japanese calendar leap years occur exactly _in line with ISO leap years.
//      * This method does not validate the year passed _in, and only has a
//      * well-defined result for years _in the supported range.
//      *
//      * @param prolepticYear  the proleptic-year to check, not validated for range
//      * @return true if the year is a leap year
//      */
//     override
//     public bool isLeapYear(long prolepticYear) {
//         return IsoChronology.INSTANCE.isLeapYear(prolepticYear);
//     }

//     ///@gxc
//     // override
//     // public int prolepticYear(Era era, int yearOfEra) {
//     //     if ((cast(JapaneseEra)(era) !is null) == false) {
//     //         throw new ClassCastException("Era must be JapaneseEra");
//     //     }

//     //     JapaneseEra jera = cast(JapaneseEra) era;
//     //     int gregorianYear = jera.getPrivateEra().getSinceDate().getYear() + yearOfEra - 1;
//     //     if (yearOfEra == 1) {
//     //         return gregorianYear;
//     //     }
//     //     if (gregorianYear >= Year.MIN_VALUE && gregorianYear <= Year.MAX_VALUE) {
//     //         LocalGregorianCalendar.Date jdate = JCAL.newCalendarDate(null);
//     //         jdate.setEra(jera.getPrivateEra()).setDate(yearOfEra, 1, 1);
//     //         if (JapaneseChronology.JCAL.validate(jdate)) {
//     //             return gregorianYear;
//     //         }
//     //     }
//     //     throw new DateTimeException("Invalid yearOfEra value");
//     // }

//     /**
//      * Returns the calendar system era object from the given numeric value.
//      *
//      * See the description of each Era for the numeric values of:
//      * {@link JapaneseEra#HEISEI}, {@link JapaneseEra#SHOWA},{@link JapaneseEra#TAISHO},
//      * {@link JapaneseEra#MEIJI}), only Meiji and later eras are supported.
//      *
//      * @param eraValue  the era value
//      * @return the Japanese {@code Era} for the given numeric era value
//      * @throws DateTimeException if {@code eraValue} is invalid
//      */
//     override
//     public JapaneseEra eraOf(int eraValue) {
//         return JapaneseEra.of(eraValue);
//     }

//     override
//     public List!(Era) eras() {
//         return List.of(JapaneseEra.values());
//     }

//     JapaneseEra getCurrentEra() {
//         // Assume that the last JapaneseEra is the current one.
//         JapaneseEra[] eras = JapaneseEra.values();
//         return eras[eras.length - 1];
//     }

//     //-----------------------------------------------------------------------
//     override
//     public ValueRange range(ChronoField field) {
//         switch (field) {
//             case ALIGNED_DAY_OF_WEEK_IN_MONTH:
//             case ALIGNED_DAY_OF_WEEK_IN_YEAR:
//             case ALIGNED_WEEK_OF_MONTH:
//             case ALIGNED_WEEK_OF_YEAR:
//                 throw new UnsupportedTemporalTypeException("Unsupported field: " ~ field);
//             case YEAR_OF_ERA: {
//                 Calendar jcal = Calendar.getInstance(LOCALE);
//                 int startYear = getCurrentEra().getPrivateEra().getSinceDate().getYear();
//                 return ValueRange.of(1, jcal.getGreatestMinimum(Calendar.YEAR),
//                         jcal.getLeastMaximum(Calendar.YEAR) + 1, // +1 due to the different definitions
//                         Year.MAX_VALUE - startYear);
//             }
//             case DAY_OF_YEAR: {
//                 Calendar jcal = Calendar.getInstance(LOCALE);
//                 int fieldIndex = Calendar.DAY_OF_YEAR;
//                 return ValueRange.of(jcal.getMinimum(fieldIndex), jcal.getGreatestMinimum(fieldIndex),
//                         jcal.getLeastMaximum(fieldIndex), jcal.getMaximum(fieldIndex));
//             }
//             case YEAR:
//                 return ValueRange.of(JapaneseDate.MEIJI_6_ISODATE.getYear(), Year.MAX_VALUE);
//             case ERA:
//                 return ValueRange.of(JapaneseEra.MEIJI.getValue(), getCurrentEra().getValue());
//             default:
//                 return field.range();
//         }
//     }

//     //-----------------------------------------------------------------------
//     override  // override for return type
//     public JapaneseDate resolveDate(Map !(TemporalField, Long) fieldValues, ResolverStyle resolverStyle) {
//         return cast(JapaneseDate) super.resolveDate(fieldValues, resolverStyle);
//     }

//     override  // override for special Japanese behavior
//     ChronoLocalDate resolveYearOfEra(Map!(TemporalField, Long) fieldValues, ResolverStyle resolverStyle) {
//         // validate era and year-of-era
//         Long eraLong = fieldValues.get(ERA);
//         JapaneseEra era = null;
//         if (eraLong !is null) {
//             era = eraOf(range(ERA).checkValidIntValue(eraLong, ERA));  // always validated
//         }
//         Long yoeLong = fieldValues.get(YEAR_OF_ERA);
//         int yoe = 0;
//         if (yoeLong !is null) {
//             yoe = range(YEAR_OF_ERA).checkValidIntValue(yoeLong, YEAR_OF_ERA);  // always validated
//         }
//         // if only year-of-era and no year then invent era unless strict
//         if (era is null && yoeLong !is null && fieldValues.containsKey(YEAR) == false && resolverStyle != ResolverStyle.STRICT) {
//             era = JapaneseEra.values()[JapaneseEra.values().length - 1];
//         }
//         // if both present, then try to create date
//         if (yoeLong !is null && era !is null) {
//             if (fieldValues.containsKey(MONTH_OF_YEAR)) {
//                 if (fieldValues.containsKey(DAY_OF_MONTH)) {
//                     return resolveYMD(era, yoe, fieldValues, resolverStyle);
//                 }
//             }
//             if (fieldValues.containsKey(DAY_OF_YEAR)) {
//                 return resolveYD(era, yoe, fieldValues, resolverStyle);
//             }
//         }
//         return null;
//     }

//     private int prolepticYearLenient(JapaneseEra era, int yearOfEra) {
//         return era.getPrivateEra().getSinceDate().getYear() + yearOfEra - 1;
//     }

//     private ChronoLocalDate resolveYMD(JapaneseEra era, int yoe, Map!(TemporalField,Long) fieldValues, ResolverStyle resolverStyle) {
//         fieldValues.remove(ERA);
//         fieldValues.remove(YEAR_OF_ERA);
//         if (resolverStyle == ResolverStyle.LENIENT) {
//             int y = prolepticYearLenient(era, yoe);
//             long months = Math.subtractExact(fieldValues.remove(MONTH_OF_YEAR), 1);
//             long days = Math.subtractExact(fieldValues.remove(DAY_OF_MONTH), 1);
//             return date(y, 1, 1).plus(months, MONTHS).plus(days, DAYS);
//         }
//         int moy = range(MONTH_OF_YEAR).checkValidIntValue(fieldValues.remove(MONTH_OF_YEAR), MONTH_OF_YEAR);
//         int dom = range(DAY_OF_MONTH).checkValidIntValue(fieldValues.remove(DAY_OF_MONTH), DAY_OF_MONTH);
//         if (resolverStyle == ResolverStyle.SMART) {  // previous valid
//             if (yoe < 1) {
//                 throw new DateTimeException("Invalid YearOfEra: " ~ yoe);
//             }
//             int y = prolepticYearLenient(era, yoe);
//             JapaneseDate result;
//             try {
//                 result = date(y, moy, dom);
//             } catch (DateTimeException ex) {
//                 result = date(y, moy, 1)._with(TemporalAdjusters.lastDayOfMonth());
//             }
//             // handle the era being changed
//             // only allow if the new date is _in the same Jan-Dec as the era change
//             // determine by ensuring either original yoe or result yoe is 1
//             if (result.getEra() != era && result.get(YEAR_OF_ERA) > 1 && yoe > 1) {
//                 throw new DateTimeException("Invalid YearOfEra for Era: " ~ era ~ " " ~ yoe);
//             }
//             return result;
//         }
//         return date(era, yoe, moy, dom);
//     }

//     private ChronoLocalDate resolveYD(JapaneseEra era, int yoe, Map !(TemporalField,Long) fieldValues, ResolverStyle resolverStyle) {
//         fieldValues.remove(ERA);
//         fieldValues.remove(YEAR_OF_ERA);
//         if (resolverStyle == ResolverStyle.LENIENT) {
//             int y = prolepticYearLenient(era, yoe);
//             long days = Math.subtractExact(fieldValues.remove(DAY_OF_YEAR), 1);
//             return dateYearDay(y, 1).plus(days, DAYS);
//         }
//         int doy = range(DAY_OF_YEAR).checkValidIntValue(fieldValues.remove(DAY_OF_YEAR), DAY_OF_YEAR);
//         return dateYearDay(era, yoe, doy);  // smart is same as strict
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
