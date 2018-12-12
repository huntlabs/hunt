
module hunt.time.temporal.TemporalAdjuster;

import hunt.time.DateTimeException;
import hunt.time.temporal.Temporal;


/**
 * Strategy for adjusting a temporal object.
 * !(p)
 * Adjusters are a key tool for modifying temporal objects.
 * They exist to externalize the process of adjustment, permitting different
 * approaches, as per the strategy design pattern.
 * Examples might be an adjuster that sets the date avoiding weekends, or one that
 * sets the date to the last day of the month.
 * !(p)
 * There are two equivalent ways of using a {@code TemporalAdjuster}.
 * The first is to invoke the method on this interface directly.
 * The second is to use {@link Temporal#_with(TemporalAdjuster)}:
 * !(pre)
 *   // these two lines are equivalent, but the second approach is recommended
 *   temporal = thisAdjuster.adjustInto(temporal);
 *   temporal = temporal._with(thisAdjuster);
 * </pre>
 * It is recommended to use the second approach, {@code _with(TemporalAdjuster)},
 * as it is a lot clearer to read _in code.
 * !(p)
 * The {@link TemporalAdjusters} class contains a standard set of adjusters,
 * available as static methods.
 * These include:
 * !(ul)
 * !(li)finding the first or last day of the month
 * !(li)finding the first day of next month
 * !(li)finding the first or last day of the year
 * !(li)finding the first day of next year
 * !(li)finding the first or last day-of-week within a month, such as "first Wednesday _in June"
 * !(li)finding the next or previous day-of-week, such as "next Thursday"
 * </ul>
 *
 * @implSpec
 * This interface places no restrictions on the mutability of implementations,
 * however immutability is strongly recommended.
 *
 * @see TemporalAdjusters
 * @since 1.8
 */
// @FunctionalInterface
public interface TemporalAdjuster {

    /**
     * Adjusts the specified temporal object.
     * !(p)
     * This adjusts the specified temporal object using the logic
     * encapsulated _in the implementing class.
     * Examples might be an adjuster that sets the date avoiding weekends, or one that
     * sets the date to the last day of the month.
     * !(p)
     * There are two equivalent ways of using this method.
     * The first is to invoke this method directly.
     * The second is to use {@link Temporal#_with(TemporalAdjuster)}:
     * !(pre)
     *   // these two lines are equivalent, but the second approach is recommended
     *   temporal = thisAdjuster.adjustInto(temporal);
     *   temporal = temporal._with(thisAdjuster);
     * </pre>
     * It is recommended to use the second approach, {@code _with(TemporalAdjuster)},
     * as it is a lot clearer to read _in code.
     *
     * @implSpec
     * The implementation must take the input object and adjust it.
     * The implementation defines the logic of the adjustment and is responsible for
     * documenting that logic. It may use any method on {@code Temporal} to
     * query the temporal object and perform the adjustment.
     * The returned object must have the same observable type as the input object
     * !(p)
     * The input object must not be altered.
     * Instead, an adjusted copy of the original must be returned.
     * This provides equivalent, safe behavior for immutable and mutable temporal objects.
     * !(p)
     * The input temporal object may be _in a calendar system other than ISO.
     * Implementations may choose to document compatibility with other calendar systems,
     * or reject non-ISO temporal objects by {@link TemporalQueries#chronology() querying the chronology}.
     * !(p)
     * This method may be called from multiple threads _in parallel.
     * It must be thread-safe when invoked.
     *
     * @param temporal  the temporal object to adjust, not null
     * @return an object of the same observable type with the adjustment made, not null
     * @throws DateTimeException if unable to make the adjustment
     * @throws ArithmeticException if numeric overflow occurs
     */
    Temporal adjustInto(Temporal temporal);

}
