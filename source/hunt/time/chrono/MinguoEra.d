
module hunt.time.chrono.MinguoEra;

import std.conv;
import hunt.time.temporal.ChronoField;

import hunt.time.DateTimeException;
import hunt.time.format.DateTimeFormatterBuilder;
import hunt.time.format.TextStyle;
import hunt.time.util.Locale;
import hunt.time.chrono.Era;
import hunt.time.chrono.ChronoLocalDateImpl;
import hunt.time.chrono.MinguoChronology;

/**
 * An era _in the Minguo calendar system.
 * !(p)
 * The Minguo calendar system has two eras.
 * The current era, for years from 1 onwards, is known as the 'Republic of China' era.
 * All previous years, zero or earlier _in the proleptic count or one and greater
 * _in the year-of-era count, are part of the 'Before Republic of China' era.
 *
 * <table class="striped" style="text-align:left">
 * <caption style="display:none">Minguo years and eras</caption>
 * !(thead)
 * !(tr)
 * !(th)year-of-era</th>
 * !(th)era</th>
 * !(th)proleptic-year</th>
 * !(th)ISO proleptic-year</th>
 * </tr>
 * </thead>
 * !(tbody)
 * !(tr)
 * !(td)2</td>!(td)ROC</td><th scope="row">2</th>!(td)1913</td>
 * </tr>
 * !(tr)
 * !(td)1</td>!(td)ROC</td><th scope="row">1</th>!(td)1912</td>
 * </tr>
 * !(tr)
 * !(td)1</td>!(td)BEFORE_ROC</td><th scope="row">0</th>!(td)1911</td>
 * </tr>
 * !(tr)
 * !(td)2</td>!(td)BEFORE_ROC</td><th scope="row">-1</th>!(td)1910</td>
 * </tr>
 * </tbody>
 * </table>
 * !(p)
 * !(b)Do not use {@code ordinal()} to obtain the numeric representation of {@code MinguoEra}.
 * Use {@code getValue()} instead.</b>
 *
 * @implSpec
 * This is an immutable and thread-safe enum.
 *
 * @since 1.8
 */
// public class MinguoEra : Era {

//     /**
//      * The singleton instance for the era before the current one, 'Before Republic of China Era',
//      * which has the numeric value 0.
//      */
//     static MinguoEra BEFORE_ROC;
//     /**
//      * The singleton instance for the current era, 'Republic of China Era',
//      * which has the numeric value 1.
//      */
//     static MinguoEra ROC;

//     static this()
//     {
//         BEFORE_ROC = new MinguoEra(0);
//         ROC = new MinguoEra(1);
//     }

//     private int _ordinal;

//     this(int ordinal)
//     {
//         _ordinal = ordinal;
//     }
//     //-----------------------------------------------------------------------
//     /**
//      * Obtains an instance of {@code MinguoEra} from an {@code int} value.
//      * !(p)
//      * {@code MinguoEra} is an enum representing the Minguo eras of BEFORE_ROC/ROC.
//      * This factory allows the enum to be obtained from the {@code int} value.
//      *
//      * @param minguoEra  the BEFORE_ROC/ROC value to represent, from 0 (BEFORE_ROC) to 1 (ROC)
//      * @return the era singleton, not null
//      * @throws DateTimeException if the value is invalid
//      */
//     public static MinguoEra of(int minguoEra) {
//         switch (minguoEra) {
//             case 0:
//                 return BEFORE_ROC;
//             case 1:
//                 return ROC;
//             default:
//                 throw new DateTimeException("Invalid era: " ~ minguoEra.to!string);
//         }
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Gets the numeric era {@code int} value.
//      * !(p)
//      * The era BEFORE_ROC has the value 0, while the era ROC has the value 1.
//      *
//      * @return the era value, from 0 (BEFORE_ROC) to 1 (ROC)
//      */
//     override
//     public int getValue() {
//         return ordinal();
//     }

//     /**
//      * {@inheritDoc}
//      *
//      * @param style {@inheritDoc}
//      * @param locale {@inheritDoc}
//      */
//     override
//     public string getDisplayName(TextStyle style, Locale locale) {
//         // return new DateTimeFormatterBuilder()
//         //     .appendText(ChronoField.ERA, style)
//         //     .toFormatter(locale)
//         //     // .withChronology(MinguoChronology.INSTANCE)
//         //     .format(this == ROC ? MinguoDate.of(1, 1, 1) : MinguoDate.of(0, 1, 1));
//         return null;
//     }

//     int ordinal()
//     {
//         return _ordinal;
//     }
// }
