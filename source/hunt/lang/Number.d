module hunt.lang.Number;

import hunt.lang.Nullable;
import std.traits;

/**
 * The class {@code Number} is the superclass of platform
 * classes representing numeric values that are convertible to the
 * primitive types {@code byte}, {@code double}, {@code float}, {@code
 * int}, {@code long}, and {@code short}.
 *
 * The specific semantics of the conversion from the numeric value of
 * a particular {@code Number} implementation to a given primitive
 * type is defined by the {@code Number} implementation in question.
 *
 * For platform classes, the conversion is often analogous to a
 * narrowing primitive conversion or a widening primitive conversion
 * as defined in <cite>The Java&trade; Language Specification</cite>
 * for converting between primitive types.  Therefore, conversions may
 * lose information about the overall magnitude of a numeric value, may
 * lose precision, and may even return a result of a different sign
 * than the input.
 *
 * See the documentation of a given {@code Number} implementation for
 * conversion details.
 *
 * @author      Lee Boynton
 * @author      Arthur van Hoff
 * @jls 5.1.2 Widening Primitive Conversions
 * @jls 5.1.3 Narrowing Primitive Conversions
 * @since   1.0
 */
// class Number(T) : Nullable!(T) if(isNumeric!T) {
interface Number {

    /**
     * Returns the value of the specified number as an {@code int}.
     *
     * @return  the numeric value represented by this object after conversion
     *          to type {@code int}.
     */
    int intValue();

    /**
     * Returns the value of the specified number as a {@code long}.
     *
     * @return  the numeric value represented by this object after conversion
     *          to type {@code long}.
     */
    long longValue();

    /**
     * Returns the value of the specified number as a {@code float}.
     *
     * @return  the numeric value represented by this object after conversion
     *          to type {@code float}.
     */
    float floatValue();

    /**
     * Returns the value of the specified number as a {@code double}.
     *
     * @return  the numeric value represented by this object after conversion
     *          to type {@code double}.
     */
    double doubleValue();

    /**
     * Returns the value of the specified number as a {@code byte}.
     *
     * <p>This implementation returns the result of {@link #intValue} cast
     * to a {@code byte}.
     *
     * @return  the numeric value represented by this object after conversion
     *          to type {@code byte}.
     * @since   1.1
     */
    byte byteValue();

    /**
     * Returns the value of the specified number as a {@code short}.
     *
     * <p>This implementation returns the result of {@link #intValue} cast
     * to a {@code short}.
     *
     * @return  the numeric value represented by this object after conversion
     *          to type {@code short}.
     * @since   1.1
     */
    short shortValue();
}


/**
*/
abstract class AbstractNumber : Number {

    byte byteValue() {
        return cast(byte) intValue();
    }

    short shortValue() {
        return cast(short) intValue();
    }
}
