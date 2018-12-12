
 module hunt.time.chrono.HijrahChronology;

// import hunt.time.temporal.ChronoField;

// // import hunt.io.FilePermission;
// import hunt.io.common;

// //import hunt.io.ObjectInputStream;
// import hunt.io.Serializable;
// // import hunt.security.AccessController;
// // import hunt.security.PrivilegedAction;
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
// import hunt.container.Map;
// // import hunt.util.Properties;

// // import sun.util.logging.PlatformLogger;

// /**
//  * The Hijrah calendar is a lunar calendar supporting Islamic calendars.
//  * !(p)
//  * The HijrahChronology follows the rules of the Hijrah calendar system. The Hijrah
//  * calendar has several variants based on differences _in when the new moon is
//  * determined to have occurred and where the observation is made.
//  * In some variants the length of each month is
//  * computed algorithmically from the astronomical data for the moon and earth and
//  * _in others the length of the month is determined by an authorized sighting
//  * of the new moon. For the algorithmically based calendars the calendar
//  * can project into the future.
//  * For sighting based calendars only historical data from past
//  * sightings is available.
//  * !(p)
//  * The length of each month is 29 or 30 days.
//  * Ordinary years have 354 days; leap years have 355 days.
//  *
//  * !(p)
//  * CLDR and LDML identify variants:
//  * <table class="striped" style="text-align:left">
//  * <caption style="display:none">Variants of Hijrah Calendars</caption>
//  * !(thead)
//  * !(tr)
//  * <th scope="col">Chronology ID</th>
//  * <th scope="col">Calendar Type</th>
//  * <th scope="col">Locale extension, see {@link java.util.Locale}</th>
//  * <th scope="col">Description</th>
//  * </tr>
//  * </thead>
//  * !(tbody)
//  * !(tr)
//  * <th scope="row">Hijrah-umalqura</th>
//  * !(td)islamic-umalqura</td>
//  * !(td)ca-islamic-umalqura</td>
//  * !(td)Islamic - Umm Al-Qura calendar of Saudi Arabia</td>
//  * </tr>
//  * </tbody>
//  * </table>
//  * !(p)Additional variants may be available through {@link Chronology#getAvailableChronologies()}.
//  *
//  * !(p)Example</p>
//  * !(p)
//  * Selecting the chronology from the locale uses {@link Chronology#ofLocale}
//  * to find the Chronology based on Locale supported BCP 47 extension mechanism
//  * to request a specific calendar ("ca"). For example,
//  * </p>
//  * !(pre)
//  *      Locale locale = Locale.forLanguageTag("en-US-u-ca-islamic-umalqura");
//  *      Chronology chrono = Chronology.ofLocale(locale);
//  * </pre>
//  *
//  * @implSpec
//  * This class is immutable and thread-safe.
//  *
//  * @implNote
//  * Each Hijrah variant is configured individually. Each variant is defined by a
//  * property resource that defines the {@code ID}, the {@code calendar type},
//  * the start of the calendar, the alignment with the
//  * ISO calendar, and the length of each month for a range of years.
//  * The variants are loaded by HijrahChronology as a resource from
//  * hijrah-config-&lt;calendar type&gt;.properties.
//  * !(p)
//  * The Hijrah property resource is a set of properties that describe the calendar.
//  * The syntax is defined by {@code java.util.Properties#load(Reader)}.
//  * <table class="striped" style="text-align:left">
//  * <caption style="display:none">Configuration of Hijrah Calendar</caption>
//  * !(thead)
//  * !(tr)
//  * <th scope="col">Property Name</th>
//  * <th scope="col">Property value</th>
//  * <th scope="col">Description</th>
//  * </tr>
//  * </thead>
//  * !(tbody)
//  * !(tr)
//  * <th scope="row">id</th>
//  * !(td)Chronology Id, for example, "Hijrah-umalqura"</td>
//  * !(td)The Id of the calendar _in common usage</td>
//  * </tr>
//  * !(tr)
//  * <th scope="row">type</th>
//  * !(td)Calendar type, for example, "islamic-umalqura"</td>
//  * !(td)LDML defines the calendar types</td>
//  * </tr>
//  * !(tr)
//  * <th scope="row">_version</th>
//  * !(td)Version, for example: "1.8.0_1"</td>
//  * !(td)The _version of the Hijrah variant data</td>
//  * </tr>
//  * !(tr)
//  * <th scope="row">iso-start</th>
//  * !(td)ISO start date, formatted as {@code yyyy-MM-dd}, for example: "1900-04-30"</td>
//  * !(td)The ISO date of the first day of the minimum Hijrah year.</td>
//  * </tr>
//  * !(tr)
//  * <th scope="row">yyyy - a numeric 4 digit year, for example "1434"</th>
//  * !(td)The value is a sequence of 12 month lengths,
//  * for example: "29 30 29 30 29 30 30 30 29 30 29 29"</td>
//  * !(td)The lengths of the 12 months of the year separated by whitespace.
//  * A numeric year property must be present for every year without any gaps.
//  * The month lengths must be between 29-32 inclusive.
//  * </td>
//  * </tr>
//  * </tbody>
//  * </table>
//  *
//  * @since 1.8
//  */
// public final class HijrahChronology : AbstractChronology , Serializable {

//     mixin MakeServiceLoader!AbstractChronology;
//     /**
//      * The Hijrah Calendar id.
//      */
//     private final /*transient*/ string typeId;
//     /**
//      * The Hijrah calendarType.
//      */
//     private final /*transient*/ string calendarType;
//     /**
//      * Serialization _version.
//      */
//     private static final long serialVersionUID = 3127340209035924785L;
//     /**
//      * Singleton instance of the Islamic Umm Al-Qura calendar of Saudi Arabia.
//      * Other Hijrah chronology variants may be available from
//      * {@link Chronology#getAvailableChronologies}.
//      */
//     public static final HijrahChronology INSTANCE;
//     /**
//      * Flag to indicate the initialization of configuration data is complete.
//      * @see #checkCalendarInit()
//      */
//     private /*transient*/ /* volatile */ bool initComplete;
//     /**
//      * Array of epoch days indexed by Hijrah Epoch month.
//      * Computed by {@link #loadCalendarData}.
//      */
//     private /*transient*/ int[] hijrahEpochMonthStartDays;
//     /**
//      * The minimum epoch day of this Hijrah calendar.
//      * Computed by {@link #loadCalendarData}.
//      */
//     private /*transient*/ int minEpochDay;
//     /**
//      * The maximum epoch day for which calendar data is available.
//      * Computed by {@link #loadCalendarData}.
//      */
//     private /*transient*/ int maxEpochDay;
//     /**
//      * The minimum epoch month.
//      * Computed by {@link #loadCalendarData}.
//      */
//     private /*transient*/ int hijrahStartEpochMonth;
//     /**
//      * The minimum length of a month.
//      * Computed by {@link #createEpochMonths}.
//      */
//     private /*transient*/ int minMonthLength;
//     /**
//      * The maximum length of a month.
//      * Computed by {@link #createEpochMonths}.
//      */
//     private /*transient*/ int maxMonthLength;
//     /**
//      * The minimum length of a year _in days.
//      * Computed by {@link #createEpochMonths}.
//      */
//     private /*transient*/ int minYearLength;
//     /**
//      * The maximum length of a year _in days.
//      * Computed by {@link #createEpochMonths}.
//      */
//     private /*transient*/ int maxYearLength;

//     /**
//      * Prefix of resource names for Hijrah calendar variants.
//      */
//     private static final string RESOURCE_PREFIX = "hijrah-config-";

//     /**
//      * Suffix of resource names for Hijrah calendar variants.
//      */
//     private static final string RESOURCE_SUFFIX = ".properties";

//     /**
//      * Static initialization of the built-_in calendars.
//      * The data is not loaded until it is used.
//      */
//     static this(){
//         INSTANCE = new HijrahChronology("Hijrah-umalqura", "islamic-umalqura");
//         // Register it by its aliases
//         AbstractChronology.registerChrono(INSTANCE, "Hijrah");
//         AbstractChronology.registerChrono(INSTANCE, "islamic");
//     }

//     /**
//      * Create a HijrahChronology for the named variant and type.
//      *
//      * @param id the id of the calendar
//      * @param calType the typeId of the calendar
//      * @throws IllegalArgumentException if the id or typeId is empty
//      */
//     private this(string id, string calType) {
//         if (id.isEmpty()) {
//             throw new IllegalArgumentException("calendar id is empty");
//         }
//         if (calType.isEmpty()) {
//             throw new IllegalArgumentException("calendar typeId is empty");
//         }
//         this.typeId = id;
//         this.calendarType = calType;
//     }

//     /**
//      * Check and ensure that the calendar data has been initialized.
//      * The initialization check is performed at the boundary between
//      * public and package methods.  If a public calls another public method
//      * a check is not necessary _in the caller.
//      * The constructors of HijrahDate call {@link #getEpochDay} or
//      * {@link #getHijrahDateInfo} so every call from HijrahDate to a
//      * HijrahChronology via package private methods has been checked.
//      *
//      * @throws DateTimeException if the calendar data configuration is
//      *     malformed or IOExceptions occur loading the data
//      */
//     private void checkCalendarInit() {
//         // Keep this short so it can be inlined for performance
//         if (initComplete == false) {
//             loadCalendarData();
//             initComplete = true;
//         }
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Gets the ID of the chronology.
//      * !(p)
//      * The ID uniquely identifies the {@code Chronology}. It can be used to
//      * lookup the {@code Chronology} using {@link Chronology#of(string)}.
//      *
//      * @return the chronology ID, non-null
//      * @see #getCalendarType()
//      */
//     override
//     public string getId() {
//         return typeId;
//     }

//     /**
//      * Gets the calendar type of the Islamic calendar.
//      * !(p)
//      * The calendar type is an identifier defined by the
//      * !(em)Unicode Locale Data Markup Language (LDML)</em> specification.
//      * It can be used to lookup the {@code Chronology} using {@link Chronology#of(string)}.
//      *
//      * @return the calendar system type; non-null if the calendar has
//      *    a standard type, otherwise null
//      * @see #getId()
//      */
//     override
//     public string getCalendarType() {
//         return calendarType;
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Obtains a local date _in Hijrah calendar system from the
//      * era, year-of-era, month-of-year and day-of-month fields.
//      *
//      * @param era  the Hijrah era, not null
//      * @param yearOfEra  the year-of-era
//      * @param month  the month-of-year
//      * @param dayOfMonth  the day-of-month
//      * @return the Hijrah local date, not null
//      * @throws DateTimeException if unable to create the date
//      * @throws ClassCastException if the {@code era} is not a {@code HijrahEra}
//      */
//     override
//     public HijrahDate date(Era era, int yearOfEra, int month, int dayOfMonth) {
//         return date(prolepticYear(era, yearOfEra), month, dayOfMonth);
//     }

//     /**
//      * Obtains a local date _in Hijrah calendar system from the
//      * proleptic-year, month-of-year and day-of-month fields.
//      *
//      * @param prolepticYear  the proleptic-year
//      * @param month  the month-of-year
//      * @param dayOfMonth  the day-of-month
//      * @return the Hijrah local date, not null
//      * @throws DateTimeException if unable to create the date
//      */
//     override
//     public HijrahDate date(int prolepticYear, int month, int dayOfMonth) {
//         return HijrahDate.of(this, prolepticYear, month, dayOfMonth);
//     }

//     /**
//      * Obtains a local date _in Hijrah calendar system from the
//      * era, year-of-era and day-of-year fields.
//      *
//      * @param era  the Hijrah era, not null
//      * @param yearOfEra  the year-of-era
//      * @param dayOfYear  the day-of-year
//      * @return the Hijrah local date, not null
//      * @throws DateTimeException if unable to create the date
//      * @throws ClassCastException if the {@code era} is not a {@code HijrahEra}
//      */
//     override
//     public HijrahDate dateYearDay(Era era, int yearOfEra, int dayOfYear) {
//         return dateYearDay(prolepticYear(era, yearOfEra), dayOfYear);
//     }

//     /**
//      * Obtains a local date _in Hijrah calendar system from the
//      * proleptic-year and day-of-year fields.
//      *
//      * @param prolepticYear  the proleptic-year
//      * @param dayOfYear  the day-of-year
//      * @return the Hijrah local date, not null
//      * @throws DateTimeException if the value of the year is _out of range,
//      *  or if the day-of-year is invalid for the year
//      */
//     override
//     public HijrahDate dateYearDay(int prolepticYear, int dayOfYear) {
//         HijrahDate date = HijrahDate.of(this, prolepticYear, 1, 1);
//         if (dayOfYear > date.lengthOfYear()) {
//             throw new DateTimeException("Invalid dayOfYear: " ~ dayOfYear);
//         }
//         return date.plusDays(dayOfYear - 1);
//     }

//     /**
//      * Obtains a local date _in the Hijrah calendar system from the epoch-day.
//      *
//      * @param epochDay  the epoch day
//      * @return the Hijrah local date, not null
//      * @throws DateTimeException if unable to create the date
//      */
//     override  // override with covariant return type
//     public HijrahDate dateEpochDay(long epochDay) {
//         return HijrahDate.ofEpochDay(this, epochDay);
//     }

//     override
//     public HijrahDate dateNow() {
//         return dateNow(Clock.systemDefaultZone());
//     }

//     override
//     public HijrahDate dateNow(ZoneId zone) {
//         return dateNow(Clock.system(zone));
//     }

//     override
//     public HijrahDate dateNow(Clock clock) {
//         return date(LocalDate.now(clock));
//     }

//     override
//     public HijrahDate date(TemporalAccessor temporal) {
//         if (cast(HijrahDate)(temporal) !is null) {
//             return cast(HijrahDate) temporal;
//         }
//         return HijrahDate.ofEpochDay(this, temporal.getLong(EPOCH_DAY));
//     }

//     override
//     /*@SuppressWarnings("unchecked")*/
//     public ChronoLocalDateTime!(HijrahDate) localDateTime(TemporalAccessor temporal) {
//         return cast(ChronoLocalDateTime!(HijrahDate)) super.localDateTime(temporal);
//     }

//     override
//     /*@SuppressWarnings("unchecked")*/
//     public ChronoZonedDateTime!(HijrahDate) zonedDateTime(TemporalAccessor temporal) {
//         return cast(ChronoZonedDateTime!(HijrahDate)) super.zonedDateTime(temporal);
//     }

//     override
//     /*@SuppressWarnings("unchecked")*/
//     public ChronoZonedDateTime!(HijrahDate) zonedDateTime(Instant instant, ZoneId zone) {
//         return cast(ChronoZonedDateTime!(HijrahDate)) super.zonedDateTime(instant, zone);
//     }

//     //-----------------------------------------------------------------------
//     override
//     public bool isLeapYear(long prolepticYear) {
//         checkCalendarInit();
//         if (prolepticYear < getMinimumYear() || prolepticYear > getMaximumYear()) {
//             return false;
//         }
//         int len = getYearLength(cast(int) prolepticYear);
//         return (len > 354);
//     }

//     override
//     public int prolepticYear(Era era, int yearOfEra) {
//         if ((cast(HijrahEra)(era) !is null) == false) {
//             throw new ClassCastException("Era must be HijrahEra");
//         }
//         return yearOfEra;
//     }

//     /**
//      * Creates the HijrahEra object from the numeric value.
//      * The Hijrah calendar system has only one era covering the
//      * proleptic years greater than zero.
//      * This method returns the singleton HijrahEra for the value 1.
//      *
//      * @param eraValue  the era value
//      * @return the calendar system era, not null
//      * @throws DateTimeException if unable to create the era
//      */
//     override
//     public HijrahEra eraOf(int eraValue) {
//         switch (eraValue) {
//             case 1:
//                 return HijrahEra.AH;
//             default:
//                 throw new DateTimeException("invalid Hijrah era");
//         }
//     }

//     override
//     public List!(Era) eras() {
//         return List.of(HijrahEra.values());
//     }

//     //-----------------------------------------------------------------------
//     override
//     public ValueRange range(ChronoField field) {
//         checkCalendarInit();
//         if (cast(ChronoField)(field) !is null) {
//             ChronoField f = field;
//             switch (f) {
//                 case DAY_OF_MONTH:
//                     return ValueRange.of(1, 1, getMinimumMonthLength(), getMaximumMonthLength());
//                 case DAY_OF_YEAR:
//                     return ValueRange.of(1, getMaximumDayOfYear());
//                 case ALIGNED_WEEK_OF_MONTH:
//                     return ValueRange.of(1, 5);
//                 case YEAR:
//                 case YEAR_OF_ERA:
//                     return ValueRange.of(getMinimumYear(), getMaximumYear());
//                 case ERA:
//                     return ValueRange.of(1, 1);
//                 default:
//                     return field.range();
//             }
//         }
//         return field.range();
//     }

//     //-----------------------------------------------------------------------
//     override  // override for return type
//     public HijrahDate resolveDate(Map!(TemporalField, Long) fieldValues, ResolverStyle resolverStyle) {
//         return cast(HijrahDate) super.resolveDate(fieldValues, resolverStyle);
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Check the validity of a year.
//      *
//      * @param prolepticYear the year to check
//      */
//     int checkValidYear(long prolepticYear) {
//         if (prolepticYear < getMinimumYear() || prolepticYear > getMaximumYear()) {
//             throw new DateTimeException("Invalid Hijrah year: " ~ prolepticYear);
//         }
//         return cast(int) prolepticYear;
//     }

//     void checkValidDayOfYear(int dayOfYear) {
//         if (dayOfYear < 1 || dayOfYear > getMaximumDayOfYear()) {
//             throw new DateTimeException("Invalid Hijrah day of year: " ~ dayOfYear);
//         }
//     }

//     void checkValidMonth(int month) {
//         if (month < 1 || month > 12) {
//             throw new DateTimeException("Invalid Hijrah month: " ~ month);
//         }
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Returns an array containing the Hijrah year, month and day
//      * computed from the epoch day.
//      *
//      * @param epochDay  the EpochDay
//      * @return int[0] = YEAR, int[1] = MONTH, int[2] = DATE
//      */
//     int[] getHijrahDateInfo(int epochDay) {
//         checkCalendarInit();    // ensure that the chronology is initialized
//         if (epochDay < minEpochDay || epochDay >= maxEpochDay) {
//             throw new DateTimeException("Hijrah date _out of range");
//         }

//         int epochMonth = epochDayToEpochMonth(epochDay);
//         int year = epochMonthToYear(epochMonth);
//         int month = epochMonthToMonth(epochMonth);
//         int day1 = epochMonthToEpochDay(epochMonth);
//         int date = epochDay - day1; // epochDay - dayOfEpoch(year, month);

//         int[] dateInfo = new int[3];
//         dateInfo[0] = year;
//         dateInfo[1] = month + 1; // change to 1-based.
//         dateInfo[2] = date + 1; // change to 1-based.
//         return dateInfo;
//     }

//     /**
//      * Return the epoch day computed from Hijrah year, month, and day.
//      *
//      * @param prolepticYear the year to represent, 0-origin
//      * @param monthOfYear the month-of-year to represent, 1-origin
//      * @param dayOfMonth the day-of-month to represent, 1-origin
//      * @return the epoch day
//      */
//     long getEpochDay(int prolepticYear, int monthOfYear, int dayOfMonth) {
//         checkCalendarInit();    // ensure that the chronology is initialized
//         checkValidMonth(monthOfYear);
//         int epochMonth = yearToEpochMonth(prolepticYear) + (monthOfYear - 1);
//         if (epochMonth < 0 || epochMonth >= hijrahEpochMonthStartDays.length) {
//             throw new DateTimeException("Invalid Hijrah date, year: " ~
//                     prolepticYear +  ", month: " ~ monthOfYear);
//         }
//         if (dayOfMonth < 1 || dayOfMonth > getMonthLength(prolepticYear, monthOfYear)) {
//             throw new DateTimeException("Invalid Hijrah day of month: " ~ dayOfMonth);
//         }
//         return epochMonthToEpochDay(epochMonth) + (dayOfMonth - 1);
//     }

//     /**
//      * Returns day of year for the year and month.
//      *
//      * @param prolepticYear a proleptic year
//      * @param month a month, 1-origin
//      * @return the day of year, 1-origin
//      */
//     int getDayOfYear(int prolepticYear, int month) {
//         return yearMonthToDayOfYear(prolepticYear, (month - 1));
//     }

//     /**
//      * Returns month length for the year and month.
//      *
//      * @param prolepticYear a proleptic year
//      * @param monthOfYear a month, 1-origin.
//      * @return the length of the month
//      */
//     int getMonthLength(int prolepticYear, int monthOfYear) {
//         int epochMonth = yearToEpochMonth(prolepticYear) + (monthOfYear - 1);
//         if (epochMonth < 0 || epochMonth >= hijrahEpochMonthStartDays.length) {
//             throw new DateTimeException("Invalid Hijrah date, year: " ~
//                     prolepticYear +  ", month: " ~ monthOfYear);
//         }
//         return epochMonthLength(epochMonth);
//     }

//     /**
//      * Returns year length.
//      * Note: The 12th month must exist _in the data.
//      *
//      * @param prolepticYear a proleptic year
//      * @return year length _in days
//      */
//     int getYearLength(int prolepticYear) {
//         return yearMonthToDayOfYear(prolepticYear, 12);
//     }

//     /**
//      * Return the minimum supported Hijrah year.
//      *
//      * @return the minimum
//      */
//     int getMinimumYear() {
//         return epochMonthToYear(0);
//     }

//     /**
//      * Return the maximum supported Hijrah year.
//      *
//      * @return the minimum
//      */
//     int getMaximumYear() {
//         return epochMonthToYear(hijrahEpochMonthStartDays.length - 1) - 1;
//     }

//     /**
//      * Returns maximum day-of-month.
//      *
//      * @return maximum day-of-month
//      */
//     int getMaximumMonthLength() {
//         return maxMonthLength;
//     }

//     /**
//      * Returns smallest maximum day-of-month.
//      *
//      * @return smallest maximum day-of-month
//      */
//     int getMinimumMonthLength() {
//         return minMonthLength;
//     }

//     /**
//      * Returns maximum day-of-year.
//      *
//      * @return maximum day-of-year
//      */
//     int getMaximumDayOfYear() {
//         return maxYearLength;
//     }

//     /**
//      * Returns smallest maximum day-of-year.
//      *
//      * @return smallest maximum day-of-year
//      */
//     int getSmallestMaximumDayOfYear() {
//         return minYearLength;
//     }

//     /**
//      * Returns the epochMonth found by locating the epochDay _in the table. The
//      * epochMonth is the index _in the table
//      *
//      * @param epochDay
//      * @return The index of the element of the start of the month containing the
//      * epochDay.
//      */
//     private int epochDayToEpochMonth(int epochDay) {
//         // binary search
//         int ndx = Arrays.binarySearch(hijrahEpochMonthStartDays, epochDay);
//         if (ndx < 0) {
//             ndx = -ndx - 2;
//         }
//         return ndx;
//     }

//     /**
//      * Returns the year computed from the epochMonth
//      *
//      * @param epochMonth the epochMonth
//      * @return the Hijrah Year
//      */
//     private int epochMonthToYear(int epochMonth) {
//         return (epochMonth + hijrahStartEpochMonth) / 12;
//     }

//     /**
//      * Returns the epochMonth for the Hijrah Year.
//      *
//      * @param year the HijrahYear
//      * @return the epochMonth for the beginning of the year.
//      */
//     private int yearToEpochMonth(int year) {
//         return (year * 12) - hijrahStartEpochMonth;
//     }

//     /**
//      * Returns the Hijrah month from the epochMonth.
//      *
//      * @param epochMonth the epochMonth
//      * @return the month of the Hijrah Year
//      */
//     private int epochMonthToMonth(int epochMonth) {
//         return (epochMonth + hijrahStartEpochMonth) % 12;
//     }

//     /**
//      * Returns the epochDay for the start of the epochMonth.
//      *
//      * @param epochMonth the epochMonth
//      * @return the epochDay for the start of the epochMonth.
//      */
//     private int epochMonthToEpochDay(int epochMonth) {
//         return hijrahEpochMonthStartDays[epochMonth];

//     }

//     /**
//      * Returns the day of year for the requested HijrahYear and month.
//      *
//      * @param prolepticYear the Hijrah year
//      * @param month the Hijrah month
//      * @return the day of year for the start of the month of the year
//      */
//     private int yearMonthToDayOfYear(int prolepticYear, int month) {
//         int epochMonthFirst = yearToEpochMonth(prolepticYear);
//         return epochMonthToEpochDay(epochMonthFirst + month)
//                 - epochMonthToEpochDay(epochMonthFirst);
//     }

//     /**
//      * Returns the length of the epochMonth. It is computed from the start of
//      * the following month minus the start of the requested month.
//      *
//      * @param epochMonth the epochMonth; assumed to be within range
//      * @return the length _in days of the epochMonth
//      */
//     private int epochMonthLength(int epochMonth) {
//         // The very last entry _in the epochMonth table is not the start of a month
//         return hijrahEpochMonthStartDays[epochMonth + 1]
//                 - hijrahEpochMonthStartDays[epochMonth];
//     }

//     //-----------------------------------------------------------------------
//     private static final string KEY_ID = "id";
//     private static final string KEY_TYPE = "type";
//     private static final string KEY_VERSION = "_version";
//     private static final string KEY_ISO_START = "iso-start";

//     /**
//      * Return the configuration properties from the resource.
//      * !(p)
//      * The location of the variant configuration resource is:
//      * !(pre)
//      *   "/java/time/chrono/hijrah-config-" ~ calendarType ~ ".properties"
//      * </pre>
//      *
//      * @param calendarType the calendarType of the calendar variant
//      * @return a Properties containing the properties read from the resource.
//      * @throws Exception if access to the property resource fails
//      */
//     private Properties readConfigProperties(final string calendarType) /* throws Exception */ {
//         // string resourceName = RESOURCE_PREFIX + calendarType + RESOURCE_SUFFIX;
//         // PrivilegedAction!(InputStream) getResourceAction =  () -> HijrahChronology.class.getResourceAsStream(resourceName);
//         // FilePermission perm1 = new FilePermission("<!(ALL FILES)>", "read");
//         // RuntimePermission perm2 = new RuntimePermission("accessSystemModules");
//         // try (InputStream is = AccessController.doPrivileged(getResourceAction, null, perm1, perm2)) {
//         //     if (is is null) {
//         //         throw new RuntimeException("Hijrah calendar resource not found: /java/time/chrono/" ~ resourceName);
//         //     }
//         //     Properties props = new Properties();
//         //     props.load(is);
//         //     return props;
//         // }
//         implementationMissing(false);
//         return null;
//     }

//     /**
//      * Loads and processes the Hijrah calendar properties file for this calendarType.
//      * The starting Hijrah date and the corresponding ISO date are
//      * extracted and used to calculate the epochDate offset.
//      * The _version number is identified and ignored.
//      * Everything else is the data for a year with containing the length of each
//      * of 12 months.
//      *
//      * @throws DateTimeException if initialization of the calendar data from the
//      *     resource fails
//      */
//     private void loadCalendarData() {
//         try {
//             Properties props = readConfigProperties(calendarType);

//             Map!(Integer, int[]) years = new HashMap!(Integer, int[])();
//             int minYear = Integer.MAX_VALUE;
//             int maxYear = Integer.MIN_VALUE;
//             string id = null;
//             string type = null;
//             string _version = null;
//             int isoStart = 0;
//             foreach(Map.Entry!(Object, Object) entry ; props.entrySet()) {
//                 string key = cast(string) entry.getKey();
//                 switch (key) {
//                     case KEY_ID:
//                         id = cast(string)entry.getValue();
//                         break;
//                     case KEY_TYPE:
//                         type = cast(string)entry.getValue();
//                         break;
//                     case KEY_VERSION:
//                         _version = cast(string)entry.getValue();
//                         break;
//                     case KEY_ISO_START: {
//                         int[] ymd = parseYMD(cast(string) entry.getValue());
//                         isoStart = cast(int) LocalDate.of(ymd[0], ymd[1], ymd[2]).toEpochDay();
//                         break;
//                     }
//                     default:
//                         try {
//                             // Everything else is either a year or invalid
//                             int year = Integer.parseInt(key);
//                             int[] months = parseMonths(cast(string) entry.getValue());
//                             years.put(year, months);
//                             maxYear = Math.max(maxYear, year);
//                             minYear = Math.min(minYear, year);
//                         } catch (NumberFormatException nfe) {
//                             throw new IllegalArgumentException("bad key: " ~ key);
//                         }
//                 }
//             }

//             if (!getId().equals(id)) {
//                 throw new IllegalArgumentException("Configuration is for a different calendar: " ~ id);
//             }
//             if (!getCalendarType().equals(type)) {
//                 throw new IllegalArgumentException("Configuration is for a different calendar type: " ~ type);
//             }
//             if (_version is null || _version.isEmpty()) {
//                 throw new IllegalArgumentException("Configuration does not contain a _version");
//             }
//             if (isoStart == 0) {
//                 throw new IllegalArgumentException("Configuration does not contain a ISO start date");
//             }

//             // Now create and validate the array of epochDays indexed by epochMonth
//             hijrahStartEpochMonth = minYear * 12;
//             minEpochDay = isoStart;
//             hijrahEpochMonthStartDays = createEpochMonths(minEpochDay, minYear, maxYear, years);
//             maxEpochDay = hijrahEpochMonthStartDays[hijrahEpochMonthStartDays.length - 1];

//             // Compute the min and max year length _in days.
//             for (int year = minYear; year < maxYear; year++) {
//                 int length = getYearLength(year);
//                 minYearLength = Math.min(minYearLength, length);
//                 maxYearLength = Math.max(maxYearLength, length);
//             }
//         } catch (Exception ex) {
//             // Log error and throw a DateTimeException
//             PlatformLogger logger = PlatformLogger.getLogger("hunt.time.chrono");
//             logger.severe("Unable to initialize Hijrah calendar proxy: " ~ typeId, ex);
//             throw new DateTimeException("Unable to initialize HijrahCalendar: " ~ typeId, ex);
//         }
//     }

//     /**
//      * Converts the map of year to month lengths ranging from minYear to maxYear
//      * into a linear contiguous array of epochDays. The index is the hijrahMonth
//      * computed from year and month and offset by minYear. The value of each
//      * entry is the epochDay corresponding to the first day of the month.
//      *
//      * @param minYear The minimum year for which data is provided
//      * @param maxYear The maximum year for which data is provided
//      * @param years a Map of year to the array of 12 month lengths
//      * @return array of epochDays for each month from min to max
//      */
//     private int[] createEpochMonths(int epochDay, int minYear, int maxYear, Map!(Integer, int[]) years) {
//         // Compute the size for the array of dates
//         int numMonths = (maxYear - minYear + 1) * 12 + 1;

//         // Initialize the running epochDay as the corresponding ISO Epoch day
//         int epochMonth = 0; // index into array of epochMonths
//         int[] epochMonths = new int[numMonths];
//         minMonthLength = Integer.MAX_VALUE;
//         maxMonthLength = Integer.MIN_VALUE;

//         // Only whole years are valid, any zero's _in the array are illegal
//         for (int year = minYear; year <= maxYear; year++) {
//             int[] months = years.get(year);// must not be gaps
//             for (int month = 0; month < 12; month++) {
//                 int length = months[month];
//                 epochMonths[epochMonth++] = epochDay;

//                 if (length < 29 || length > 32) {
//                     throw new IllegalArgumentException("Invalid month length _in year: " ~ minYear);
//                 }
//                 epochDay += length;
//                 minMonthLength = Math.min(minMonthLength, length);
//                 maxMonthLength = Math.max(maxMonthLength, length);
//             }
//         }

//         // Insert the final epochDay
//         epochMonths[epochMonth++] = epochDay;

//         if (epochMonth != epochMonths.length) {
//             throw new IllegalStateException("Did not fill epochMonths exactly: ndx = " ~ epochMonth
//                     ~ " should be " ~ epochMonths.length);
//         }

//         return epochMonths;
//     }

//     /**
//      * Parses the 12 months lengths from a property value for a specific year.
//      *
//      * @param line the value of a year property
//      * @return an array of int[12] containing the 12 month lengths
//      * @throws IllegalArgumentException if the number of months is not 12
//      * @throws NumberFormatException if the 12 tokens are not numbers
//      */
//     private int[] parseMonths(string line) {
//         int[] months = new int[12];
//         string[] numbers = line.split("\\s");
//         if (numbers.length != 12) {
//             throw new IllegalArgumentException("wrong number of months on line: " ~ Arrays.toString(numbers) ~ "; count: " ~ numbers.length);
//         }
//         for (int i = 0; i < 12; i++) {
//             try {
//                 months[i] = Integer.parseInt(numbers[i]);
//             } catch (NumberFormatException nfe) {
//                 throw new IllegalArgumentException("bad key: " ~ numbers[i]);
//             }
//         }
//         return months;
//     }

//     /**
//      * Parse yyyy-MM-dd into a 3 element array [yyyy, mm, dd].
//      *
//      * @param string the input string
//      * @return the 3 element array with year, month, day
//      */
//     private int[] parseYMD(string string) {
//         // yyyy-MM-dd
//         string = string.trim();
//         try {
//             if (string.charAt(4) != '-' || string.charAt(7) != '-') {
//                 throw new IllegalArgumentException("date must be yyyy-MM-dd");
//             }
//             int[] ymd = new int[3];
//             ymd[0] = Integer.parseInt(string, 0, 4, 10);
//             ymd[1] = Integer.parseInt(string, 5, 7, 10);
//             ymd[2] = Integer.parseInt(string, 8, 10, 10);
//             return ymd;
//         } catch (NumberFormatException ex) {
//             throw new IllegalArgumentException("date must be yyyy-MM-dd", ex);
//         }
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
