
module hunt.time.temporal.JulianFields;

import hunt.time.temporal.ChronoField;
import hunt.time.temporal.ChronoUnit;

import hunt.time.DateTimeException;
import hunt.time.chrono.ChronoLocalDate;
import hunt.time.chrono.Chronology;
import hunt.time.format.ResolverStyle;
import hunt.container.Map;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.TemporalUnit;
import hunt.time.temporal.ValueRange;
import hunt.time.temporal.TemporalAccessor;
import hunt.lang;
import hunt.util.Assert;
/**
 * A set of date fields that provide access to Julian Days.
 * !(p)
 * The Julian Day is a standard way of expressing date and time commonly used _in the scientific community.
 * It is expressed as a decimal number of whole days where days start at midday.
 * This class represents variations on Julian Days that count whole days from midnight.
 * !(p)
 * The fields are implemented relative to {@link ChronoField#EPOCH_DAY EPOCH_DAY}.
 * The fields are supported, and can be queried and set if {@code EPOCH_DAY} is available.
 * The fields work with all chronologies.
 *
 * @implSpec
 * This is an immutable and thread-safe class.
 *
 * @since 1.8
 */
// public final class JulianFields {

//     /**
//      * The offset from Julian to EPOCH DAY.
//      */
//     private enum long JULIAN_DAY_OFFSET = 2440588L;

//     /**
//      * Julian Day field.
//      * !(p)
//      * This is an integer-based version of the Julian Day Number.
//      * Julian Day is a well-known system that represents the count of whole days since day 0,
//      * which is defined to be January 1, 4713 BCE _in the Julian calendar, and -4713-11-24 Gregorian.
//      * The field  has "JulianDay" as 'name', and 'DAYS' as 'baseUnit'.
//      * The field always refers to the local date-time, ignoring the offset or zone.
//      * !(p)
//      * For date-times, 'JULIAN_DAY.getFrom()' assumes the same value from
//      * midnight until just before the next midnight.
//      * When 'JULIAN_DAY.adjustInto()' is applied to a date-time, the time of day portion remains unaltered.
//      * 'JULIAN_DAY.adjustInto()' and 'JULIAN_DAY.getFrom()' only apply to {@code Temporal} objects that
//      * can be converted into {@link ChronoField#EPOCH_DAY}.
//      * An {@link UnsupportedTemporalTypeException} is thrown for any other type of object.
//      * !(p)
//      * In the resolving phase of parsing, a date can be created from a Julian Day field.
//      * In {@linkplain ResolverStyle#STRICT strict mode} and {@linkplain ResolverStyle#SMART smart mode}
//      * the Julian Day value is validated against the _range of valid values.
//      * In {@linkplain ResolverStyle#LENIENT lenient mode} no validation occurs.
//      *
//      * !(h3)Astronomical and Scientific Notes</h3>
//      * The standard astronomical definition uses a fraction to indicate the time-of-day,
//      * where each day is counted from midday to midday. For example,
//      * a fraction of 0 represents midday, a fraction of 0.25
//      * represents 18:00, a fraction of 0.5 represents midnight and a fraction
//      * of 0.75 represents 06:00.
//      * !(p)
//      * By contrast, this implementation has no fractional part, and counts
//      * days from midnight to midnight.
//      * This implementation uses an integer and days starting at midnight.
//      * The integer value for the Julian Day Number is the astronomical Julian Day value at midday
//      * of the date _in question.
//      * This amounts to the astronomical Julian Day, rounded to an integer {@code JDN = floor(JD + 0.5)}.
//      *
//      * !(pre)
//      *  | ISO date          |  Julian Day Number | Astronomical Julian Day |
//      *  | 1970-01-01T00:00  |         2,440,588  |         2,440,587.5     |
//      *  | 1970-01-01T06:00  |         2,440,588  |         2,440,587.75    |
//      *  | 1970-01-01T12:00  |         2,440,588  |         2,440,588.0     |
//      *  | 1970-01-01T18:00  |         2,440,588  |         2,440,588.25    |
//      *  | 1970-01-02T00:00  |         2,440,589  |         2,440,588.5     |
//      *  | 1970-01-02T06:00  |         2,440,589  |         2,440,588.75    |
//      *  | 1970-01-02T12:00  |         2,440,589  |         2,440,589.0     |
//      * </pre>
//      * !(p)
//      * Julian Days are sometimes taken to imply Universal Time or UTC, but this
//      * implementation always uses the Julian Day number for the local date,
//      * regardless of the offset or time-zone.
//      */
//     public __gshared TemporalField JULIAN_DAY;

//     /**
//      * Modified Julian Day field.
//      * !(p)
//      * This is an integer-based version of the Modified Julian Day Number.
//      * Modified Julian Day (MJD) is a well-known system that counts days continuously.
//      * It is defined relative to astronomical Julian Day as  {@code MJD = JD - 2400000.5}.
//      * Each Modified Julian Day runs from midnight to midnight.
//      * The field always refers to the local date-time, ignoring the offset or zone.
//      * !(p)
//      * For date-times, 'MODIFIED_JULIAN_DAY.getFrom()' assumes the same value from
//      * midnight until just before the next midnight.
//      * When 'MODIFIED_JULIAN_DAY.adjustInto()' is applied to a date-time, the time of day portion remains unaltered.
//      * 'MODIFIED_JULIAN_DAY.adjustInto()' and 'MODIFIED_JULIAN_DAY.getFrom()' only apply to {@code Temporal} objects
//      * that can be converted into {@link ChronoField#EPOCH_DAY}.
//      * An {@link UnsupportedTemporalTypeException} is thrown for any other type of object.
//      * !(p)
//      * This implementation is an integer version of MJD with the decimal part rounded to floor.
//      * !(p)
//      * In the resolving phase of parsing, a date can be created from a Modified Julian Day field.
//      * In {@linkplain ResolverStyle#STRICT strict mode} and {@linkplain ResolverStyle#SMART smart mode}
//      * the Modified Julian Day value is validated against the _range of valid values.
//      * In {@linkplain ResolverStyle#LENIENT lenient mode} no validation occurs.
//      *
//      * !(h3)Astronomical and Scientific Notes</h3>
//      * !(pre)
//      *  | ISO date          | Modified Julian Day |      Decimal MJD |
//      *  | 1970-01-01T00:00  |             40,587  |       40,587.0   |
//      *  | 1970-01-01T06:00  |             40,587  |       40,587.25  |
//      *  | 1970-01-01T12:00  |             40,587  |       40,587.5   |
//      *  | 1970-01-01T18:00  |             40,587  |       40,587.75  |
//      *  | 1970-01-02T00:00  |             40,588  |       40,588.0   |
//      *  | 1970-01-02T06:00  |             40,588  |       40,588.25  |
//      *  | 1970-01-02T12:00  |             40,588  |       40,588.5   |
//      * </pre>
//      *
//      * Modified Julian Days are sometimes taken to imply Universal Time or UTC, but this
//      * implementation always uses the Modified Julian Day for the local date,
//      * regardless of the offset or time-zone.
//      */
//     public __gshared TemporalField MODIFIED_JULIAN_DAY;

//     /**
//      * Rata Die field.
//      * !(p)
//      * Rata Die counts whole days continuously starting day 1 at midnight at the beginning of 0001-01-01 (ISO).
//      * The field always refers to the local date-time, ignoring the offset or zone.
//      * !(p)
//      * For date-times, 'RATA_DIE.getFrom()' assumes the same value from
//      * midnight until just before the next midnight.
//      * When 'RATA_DIE.adjustInto()' is applied to a date-time, the time of day portion remains unaltered.
//      * 'RATA_DIE.adjustInto()' and 'RATA_DIE.getFrom()' only apply to {@code Temporal} objects
//      * that can be converted into {@link ChronoField#EPOCH_DAY}.
//      * An {@link UnsupportedTemporalTypeException} is thrown for any other type of object.
//      * !(p)
//      * In the resolving phase of parsing, a date can be created from a Rata Die field.
//      * In {@linkplain ResolverStyle#STRICT strict mode} and {@linkplain ResolverStyle#SMART smart mode}
//      * the Rata Die value is validated against the _range of valid values.
//      * In {@linkplain ResolverStyle#LENIENT lenient mode} no validation occurs.
//      */
//     public __gshared TemporalField RATA_DIE;

//     shared static this()
//     {
//         JULIAN_DAY = Field.JULIAN_DAY;
//         MODIFIED_JULIAN_DAY = Field.MODIFIED_JULIAN_DAY;
//         RATA_DIE = Field.RATA_DIE;
//     }

//     /**
//      * Restricted constructor.
//      */
//     private this() {
//         throw new AssertionError("Not instantiable");
//     }

//     /**
//      * Implementation of JulianFields.  Each instance is a singleton.
//      */
//     private static class Field : TemporalField {
//         static Field JULIAN_DAY;
//         static Field MODIFIED_JULIAN_DAY;
//         static Field RATA_DIE;

//         static this()
//         {
//              JULIAN_DAY = new Field("JulianDay", ChronoUnit.DAYS, ChronoUnit.FOREVER, JULIAN_DAY_OFFSET);
//              MODIFIED_JULIAN_DAY = new Field("ModifiedJulianDay", ChronoUnit.DAYS, ChronoUnit.FOREVER, 40587L);
//              RATA_DIE = new Field("RataDie", ChronoUnit.DAYS, ChronoUnit.FOREVER, 719163L);
//         }

//         private  /*transient*/ string name;
//         private  /*transient*/ TemporalUnit baseUnit;
//         private  /*transient*/ TemporalUnit rangeUnit;
//         private  /*transient*/ ValueRange _range;
//         private  /*transient*/ long offset;

//         private this(string name, TemporalUnit baseUnit, TemporalUnit rangeUnit, long offset) {
//             this.name = name;
//             this.baseUnit = baseUnit;
//             this.rangeUnit = rangeUnit;
//             this._range = ValueRange.of(-365243219162L + offset, 365241780471L + offset);
//             this.offset = offset;
//         }

//         //-----------------------------------------------------------------------
//         override
//         public TemporalUnit getBaseUnit() {
//             return baseUnit;
//         }

//         override
//         public TemporalUnit getRangeUnit() {
//             return rangeUnit;
//         }

//         override
//         public bool isDateBased() {
//             return true;
//         }

//         override
//         public bool isTimeBased() {
//             return false;
//         }

//         // override
//         public ValueRange range() {
//             return _range;
//         }

//         //-----------------------------------------------------------------------
//         override
//         public bool isSupportedBy(TemporalAccessor temporal) {
//             return temporal.isSupported(ChronoField.EPOCH_DAY);
//         }

//         override
//         public ValueRange rangeRefinedBy(TemporalAccessor temporal) {
//             if (isSupportedBy(temporal) == false) {
//                 throw new DateTimeException("Unsupported field: " ~ this.toString);
//             }
//             return range();
//         }

//         override
//         public long getFrom(TemporalAccessor temporal) {
//             return temporal.getLong(ChronoField.EPOCH_DAY) + offset;
//         }

//         /*@SuppressWarnings("unchecked")*/
//         override
//         public  R adjustInto(R)(R temporal, long newValue) if(is(R : Temporal)) {
//             if (range().isValidValue(newValue) == false) {
//                 throw new DateTimeException("Invalid value: " ~ name ~ " " ~ newValue);
//             }
//             return cast(R) temporal._with(EPOCH_DAY, Math.subtractExact(newValue, offset));
//         }

//         //-----------------------------------------------------------------------
//         override
//         public ChronoLocalDate resolve(
//                 Map!(TemporalField, Long) fieldValues, TemporalAccessor partialTemporal, ResolverStyle resolverStyle) {
//             long value = fieldValues.remove(this).longValue();
//             Chronology chrono = Chronology.from(partialTemporal);
//             if (resolverStyle == ResolverStyle.LENIENT) {
//                 return chrono.dateEpochDay(Math.subtractExact(value, offset));
//             }
//             range().checkValidValue(value, this);
//             return chrono.dateEpochDay(value - offset);
//         }

//         //-----------------------------------------------------------------------
//         override
//         public string toString() {
//             return name;
//         }
//     }
// }
