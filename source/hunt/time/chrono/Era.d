
module hunt.time.chrono.Era;

import hunt.time.temporal.ChronoField;
import hunt.time.temporal.ChronoUnit;

import hunt.time.DateTimeException;
import hunt.time.temporal.UnsupportedTemporalTypeException;
// import hunt.time.format.DateTimeFormatterBuilder;
import hunt.time.format.TextStyle;
import hunt.time.temporal.ChronoField;
import hunt.time.temporal.Temporal;
import hunt.time.temporal.TemporalAccessor;
import hunt.time.temporal.TemporalAdjuster;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.TemporalQueries;
import hunt.time.temporal.TemporalQuery;
import hunt.time.temporal.ValueRange;
import hunt.time.util.Locale;

/**
 * An era of the time-line.
 * !(p)
 * Most calendar systems have a single epoch dividing the time-line into two eras.
 * However, some calendar systems, have multiple eras, such as one for the reign
 * of each leader.
 * In all cases, the era is conceptually the largest division of the time-line.
 * Each chronology defines the Era's that are known Eras and a
 * {@link Chronology#eras Chronology.eras} to get the valid eras.
 * !(p)
 * For example, the Thai Buddhist calendar system divides time into two eras,
 * before and after a single date. By contrast, the Japanese calendar system
 * has one era for the reign of each Emperor.
 * !(p)
 * Instances of {@code Era} may be compared using the {@code ==} operator.
 *
 * @implSpec
 * This interface must be implemented with care to ensure other classes operate correctly.
 * All implementations must be singletons - final, immutable and thread-safe.
 * It is recommended to use an enum whenever possible.
 *
 * @since 1.8
 */
public interface Era : TemporalAccessor, TemporalAdjuster {

    /**
     * Gets the numeric value associated with the era as defined by the chronology.
     * Each chronology defines the predefined Eras and methods to list the Eras
     * of the chronology.
     * !(p)
     * All fields, including eras, have an associated numeric value.
     * The meaning of the numeric value for era is determined by the chronology
     * according to these principles:
     * !(ul)
     * !(li)The era _in use at the epoch 1970-01-01 (ISO) has the value 1.
     * !(li)Later eras have sequentially higher values.
     * !(li)Earlier eras have sequentially lower values, which may be negative.
     * </ul>
     *
     * @return the numeric era value
     */
    int getValue();

    //-----------------------------------------------------------------------
    /**
     * Checks if the specified field is supported.
     * !(p)
     * This checks if this era can be queried for the specified field.
     * If false, then calling the {@link #range(TemporalField) range} and
     * {@link #get(TemporalField) get} methods will throw an exception.
     * !(p)
     * If the field is a {@link ChronoField} then the query is implemented here.
     * The {@code ERA} field returns true.
     * All other {@code ChronoField} instances will return false.
     * !(p)
     * If the field is not a {@code ChronoField}, then the result of this method
     * is obtained by invoking {@code TemporalField.isSupportedBy(TemporalAccessor)}
     * passing {@code this} as the argument.
     * Whether the field is supported is determined by the field.
     *
     * @param field  the field to check, null returns false
     * @return true if the field is supported on this era, false if not
     */
    // override
    //  bool isSupported(TemporalField field) {
    //     if (cast(ChronoField)(field) !is null) {
    //         return field == ERA;
    //     }
    //     return field !is null && field.isSupportedBy(this);
    // }

    /**
     * Gets the range of valid values for the specified field.
     * !(p)
     * The range object expresses the minimum and maximum valid values for a field.
     * This era is used to enhance the accuracy of the returned range.
     * If it is not possible to return the range, because the field is not supported
     * or for some other reason, an exception is thrown.
     * !(p)
     * If the field is a {@link ChronoField} then the query is implemented here.
     * The {@code ERA} field returns the range.
     * All other {@code ChronoField} instances will throw an {@code UnsupportedTemporalTypeException}.
     * !(p)
     * If the field is not a {@code ChronoField}, then the result of this method
     * is obtained by invoking {@code TemporalField.rangeRefinedBy(TemporalAccessor)}
     * passing {@code this} as the argument.
     * Whether the range can be obtained is determined by the field.
     * !(p)
     * The  implementation must return a range for {@code ERA} from
     * zero to one, suitable for two era calendar systems such as ISO.
     *
     * @param field  the field to query the range for, not null
     * @return the range of valid values for the field, not null
     * @throws DateTimeException if the range for the field cannot be obtained
     * @throws UnsupportedTemporalTypeException if the unit is not supported
     */
    // override  // override for Javadoc
    //  ValueRange range(TemporalField field) {
    //     return /* TemporalAccessor. */super.range(field);
    // }

    /**
     * Gets the value of the specified field from this era as an {@code int}.
     * !(p)
     * This queries this era for the value of the specified field.
     * The returned value will always be within the valid range of values for the field.
     * If it is not possible to return the value, because the field is not supported
     * or for some other reason, an exception is thrown.
     * !(p)
     * If the field is a {@link ChronoField} then the query is implemented here.
     * The {@code ERA} field returns the value of the era.
     * All other {@code ChronoField} instances will throw an {@code UnsupportedTemporalTypeException}.
     * !(p)
     * If the field is not a {@code ChronoField}, then the result of this method
     * is obtained by invoking {@code TemporalField.getFrom(TemporalAccessor)}
     * passing {@code this} as the argument. Whether the value can be obtained,
     * and what the value represents, is determined by the field.
     *
     * @param field  the field to get, not null
     * @return the value for the field
     * @throws DateTimeException if a value for the field cannot be obtained or
     *         the value is outside the range of valid values for the field
     * @throws UnsupportedTemporalTypeException if the field is not supported or
     *         the range of values exceeds an {@code int}
     * @throws ArithmeticException if numeric overflow occurs
     */
    // override  // override for Javadoc and performance
    //  int get(TemporalField field) {
    //     if (field == ERA) {
    //         return getValue();
    //     }
    //     return /* TemporalAccessor. */super.get(field);
    // }

    /**
     * Gets the value of the specified field from this era as a {@code long}.
     * !(p)
     * This queries this era for the value of the specified field.
     * If it is not possible to return the value, because the field is not supported
     * or for some other reason, an exception is thrown.
     * !(p)
     * If the field is a {@link ChronoField} then the query is implemented here.
     * The {@code ERA} field returns the value of the era.
     * All other {@code ChronoField} instances will throw an {@code UnsupportedTemporalTypeException}.
     * !(p)
     * If the field is not a {@code ChronoField}, then the result of this method
     * is obtained by invoking {@code TemporalField.getFrom(TemporalAccessor)}
     * passing {@code this} as the argument. Whether the value can be obtained,
     * and what the value represents, is determined by the field.
     *
     * @param field  the field to get, not null
     * @return the value for the field
     * @throws DateTimeException if a value for the field cannot be obtained
     * @throws UnsupportedTemporalTypeException if the field is not supported
     * @throws ArithmeticException if numeric overflow occurs
     */
    // override
    //  long getLong(TemporalField field) {
    //     if (field == ERA) {
    //         return getValue();
    //     } else if (cast(ChronoField)(field) !is null) {
    //         throw new UnsupportedTemporalTypeException("Unsupported field: " ~ field);
    //     }
    //     return field.getFrom(this);
    // }

    //-----------------------------------------------------------------------
    /**
     * Queries this era using the specified query.
     * !(p)
     * This queries this era using the specified query strategy object.
     * The {@code TemporalQuery} object defines the logic to be used to
     * obtain the result. Read the documentation of the query to understand
     * what the result of this method will be.
     * !(p)
     * The result of this method is obtained by invoking the
     * {@link TemporalQuery#queryFrom(TemporalAccessor)} method on the
     * specified query passing {@code this} as the argument.
     *
     * @param !(R) the type of the result
     * @param query  the query to invoke, not null
     * @return the query result, null may be returned (defined by the query)
     * @throws DateTimeException if unable to query (defined by the query)
     * @throws ArithmeticException if numeric overflow occurs (defined by the query)
     */
    /*@SuppressWarnings("unchecked")*/
    // override
    R query(R)(TemporalQuery!(R) query) {
        if (query == TemporalQueries.precision()) {
            return cast(R) ERAS;
        }
        return /* TemporalAccessor. */super_query(query);
    }
    R super_query(R)(TemporalQuery!(R) query) {
         if (query == TemporalQueries.zoneId()
                 || query == TemporalQueries.chronology()
                 || query == TemporalQueries.precision()) {
             return null;
         }
         return query.queryFrom(this);
     }
    /**
     * Adjusts the specified temporal object to have the same era as this object.
     * !(p)
     * This returns a temporal object of the same observable type as the input
     * with the era changed to be the same as this.
     * !(p)
     * The adjustment is equivalent to using {@link Temporal#_with(TemporalField, long)}
     * passing {@link ChronoField#ERA} as the field.
     * !(p)
     * In most cases, it is clearer to reverse the calling pattern by using
     * {@link Temporal#_with(TemporalAdjuster)}:
     * !(pre)
     *   // these two lines are equivalent, but the second approach is recommended
     *   temporal = thisEra.adjustInto(temporal);
     *   temporal = temporal._with(thisEra);
     * </pre>
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param temporal  the target object to be adjusted, not null
     * @return the adjusted object, not null
     * @throws DateTimeException if unable to make the adjustment
     * @throws ArithmeticException if numeric overflow occurs
     */
    // override
    //  Temporal adjustInto(Temporal temporal) {
    //     return temporal._with(ERA, getValue());
    // }

    //-----------------------------------------------------------------------
    /**
     * Gets the textual representation of this era.
     * !(p)
     * This returns the textual name used to identify the era,
     * suitable for presentation to the user.
     * The parameters control the style of the returned text and the locale.
     * !(p)
     * If no textual mapping is found then the {@link #getValue() numeric value} is returned.
     *
     * @apiNote This  implementation is suitable for most implementations.
     *
     * @param style  the style of the text required, not null
     * @param locale  the locale to use, not null
     * @return the text value of the era, not null
     */
    //  string getDisplayName(TextStyle style, Locale locale);
    //  string getDisplayName(TextStyle style, Locale locale) {
    //     return new DateTimeFormatterBuilder().appendText(ERA, style).toFormatter(locale).format(this);
    // }

    // NOTE: methods to convert year-of-era/proleptic-year cannot be here as they may depend on month/day (Japanese)
    string toString();
}
