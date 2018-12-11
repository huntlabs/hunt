module hunt.util.Assert;

import std.algorithm;
import std.array;
import std.conv;
import std.exception;
import std.format;
import std.math;
import std.range;
import std.range;
import std.traits;

import hunt.logging;
import hunt.lang.exception;

class AssertionError : Error {
    // this(string file = __FILE__, size_t line = __LINE__,
    //      Throwable next = null) @nogc @safe pure nothrow
    // {
    //     super("", file, line, next);
    // }

    mixin basicExceptionCtors;
}

class Matchers {
    static T[] contains(T)(T[] items...) {
        T[] r;
        foreach (T item; items)
            r ~= item;
        return r;
    }

    // bool containsString(string source, string item)
    // {

    // }

}

/**
 * A set of assertion methods useful for writing tests. Only failed assertions
 * are recorded. These methods can be used directly:
 * <code>Assert.assertEquals(...)</code>, however, they read better if they
 * are referenced through static import:
 *
 * <pre>
 * import org.junit.Assert.*;
 *    ...
 *    assertEquals(...);
 * </pre>
 *
 * @see AssertionError
 * @since 4.0
 */
class Assert {
    /**
     * Protect constructor since it is a static only class
     */
    protected this() {
    }

    /**
     * Asserts that a condition is true. If it isn't it throws an
     * {@link AssertionError} with the given message.
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param condition condition to be checked
     */
    static void assertTrue(size_t line = __LINE__, string file = __FILE__)(
            string message, bool condition) {
        if (!condition) {
            fail!(line, file)(message);
        }
    }

    /**
     * Asserts that a condition is true. If it isn't it throws an
     * {@link AssertionError} without a message.
     *
     * @param condition condition to be checked
     */
    static void assertTrue(size_t line = __LINE__, string file = __FILE__)(bool condition) {
        assertTrue!(line, file)(null, condition);
    }

    /**
     * Asserts that a condition is false. If it isn't it throws an
     * {@link AssertionError} with the given message.
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param condition condition to be checked
     */
    static void assertFalse(size_t line = __LINE__, string file = __FILE__)(
            string message, bool condition) {
        assertTrue!(line, file)(message, !condition);
    }

    /**
     * Asserts that a condition is false. If it isn't it throws an
     * {@link AssertionError} without a message.
     *
     * @param condition condition to be checked
     */
    static void assertFalse(size_t line = __LINE__, string file = __FILE__)(bool condition) {
        assertFalse!(line, file)(null, condition);
    }

    /**
     * Fails a test with the given message.
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @see AssertionError
     */
    static void fail(size_t line = __LINE__, string file = __FILE__)(string message) {

        if (message.empty)
            message = std.format.format("raised in %s:%s", file, line);
        else
            message = std.format.format("raised in %s:%s, message: %s", file, line, message);

        throw new AssertionError(message, file, line, cast(Throwable) null);
    }

    /**
     * Fails a test with no message.
     */
    static void fail(size_t line = __LINE__, string file = __FILE__)() {
        fail!(line, file)(null);
    }

    /**
     * Asserts that two objects are equal. If they are not, an
     * {@link AssertionError} is thrown with the given message. If
     * <code>expected</code> and <code>actual</code> are <code>null</code>,
     * they are considered equal.
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param expected expected value
     * @param actual actual value
     */
    static void assertEquals(T, size_t line = __LINE__, string file = __FILE__)(
            string message, T expected, T actual) {
        if (!message.empty)
            message = std.format.format("raised in %s:%s, message: %s", file, line, message);
        else
            message = std.format.format("raised in %s:%s", file, line);

        version (HUNT_DEBUG) {
            trace("expected: ", expected);
            trace("actual: ", actual);
        }

        static if (is(T == class)) {
            assert(expected == actual, message);
        } else {
            assert(expected == actual, message);
        }
    }

    private static bool equalsRegardingNull(Object expected, Object actual) {
        if (expected is null) {
            return actual is null;
        }

        return isEquals(expected, actual);
    }

    private static bool isEquals(Object expected, Object actual) {
        return expected.opEquals(actual);
    }

    /**
     * Asserts that two objects are equal. If they are not, an
     * {@link AssertionError} without a message is thrown. If
     * <code>expected</code> and <code>actual</code> are <code>null</code>,
     * they are considered equal.
     *
     * @param expected expected value
     * @param actual the value to check against <code>expected</code>
     */
    static void assertEquals(T, size_t line = __LINE__, string file = __FILE__)(T expected, T actual) {
        assertEquals!(T, line, file)(null, expected, actual);
    }

    /**
     * Asserts that two objects are <b>not</b> equals. If they are, an
     * {@link AssertionError} is thrown with the given message. If
     * <code>unexpected</code> and <code>actual</code> are <code>null</code>,
     * they are considered equal.
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param unexpected unexpected value to check
     * @param actual the value to check against <code>unexpected</code>
     */
    static void assertNotEquals(string message, Object unexpected, Object actual) {
        if (equalsRegardingNull(unexpected, actual)) {
            failEquals(message, actual);
        }
    }

    /**
     * Asserts that two objects are <b>not</b> equals. If they are, an
     * {@link AssertionError} without a message is thrown. If
     * <code>unexpected</code> and <code>actual</code> are <code>null</code>,
     * they are considered equal.
     *
     * @param unexpected unexpected value to check
     * @param actual the value to check against <code>unexpected</code>
     */
    static void assertNotEquals(Object unexpected, Object actual) {
        assertNotEquals(null, unexpected, actual);
    }

    private static void failEquals(string message, Object actual) {
        string formatted = "Values should be different. ";
        if (message !is null) {
            formatted = message ~ ". ";
        }

        formatted ~= "Actual: " ~ actual.toString();
        fail(formatted);
    }

    private static void failEquals(T)(string message, T actual) if (isNumeric!T) {
        string formatted = "Values should be different. ";
        if (message !is null) {
            formatted = message ~ ". ";
        }

        formatted ~= "Actual: " ~ to!string(actual);
        fail(formatted);
    }

    /**
     * Asserts that two longs are <b>not</b> equals. If they are, an
     * {@link AssertionError} is thrown with the given message.
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param unexpected unexpected value to check
     * @param actual the value to check against <code>unexpected</code>
     */
    static void assertNotEquals(string message, long unexpected, long actual) {
        if (unexpected == actual) {
            failEquals(message, actual);
        }
    }

    /**
     * Asserts that two longs are <b>not</b> equals. If they are, an
     * {@link AssertionError} without a message is thrown.
     *
     * @param unexpected unexpected value to check
     * @param actual the value to check against <code>unexpected</code>
     */
    static void assertNotEquals(long unexpected, long actual) {
        assertNotEquals(null, unexpected, actual);
    }

    /**
     * Asserts that two doubles are <b>not</b> equal to within a positive delta.
     * If they are, an {@link AssertionError} is thrown with the given
     * message. If the unexpected value is infinity then the delta value is
     * ignored. NaNs are considered equal:
     * <code>assertNotEquals(Double.NaN, Double.NaN, *)</code> fails
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param unexpected unexpected value
     * @param actual the value to check against <code>unexpected</code>
     * @param delta the maximum delta between <code>unexpected</code> and
     * <code>actual</code> for which both numbers are still
     * considered equal.
     */
    static void assertNotEquals(string message, double unexpected, double actual, double delta) {
        if (!doubleIsDifferent(unexpected, actual, delta)) {
            failEquals(message, actual);
        }
    }

    /**
     * Asserts that two doubles are <b>not</b> equal to within a positive delta.
     * If they are, an {@link AssertionError} is thrown. If the unexpected
     * value is infinity then the delta value is ignored.NaNs are considered
     * equal: <code>assertNotEquals(Double.NaN, Double.NaN, *)</code> fails
     *
     * @param unexpected unexpected value
     * @param actual the value to check against <code>unexpected</code>
     * @param delta the maximum delta between <code>unexpected</code> and
     * <code>actual</code> for which both numbers are still
     * considered equal.
     */
    static void assertNotEquals(double unexpected, double actual, double delta) {
        assertNotEquals(null, unexpected, actual, delta);
    }

    /**
     * Asserts that two floats are <b>not</b> equal to within a positive delta.
     * If they are, an {@link AssertionError} is thrown. If the unexpected
     * value is infinity then the delta value is ignored.NaNs are considered
     * equal: <code>assertNotEquals(Float.NaN, Float.NaN, *)</code> fails
     *
     * @param unexpected unexpected value
     * @param actual the value to check against <code>unexpected</code>
     * @param delta the maximum delta between <code>unexpected</code> and
     * <code>actual</code> for which both numbers are still
     * considered equal.
     */
    static void assertNotEquals(float unexpected, float actual, float delta) {
        assertNotEquals(null, unexpected, actual, delta);
    }

    /**
     * Asserts that two object arrays are equal. If they are not, an
     * {@link AssertionError} is thrown with the given message. If
     * <code>expecteds</code> and <code>actuals</code> are <code>null</code>,
     * they are considered equal.
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param expecteds Object array or array of arrays (multi-dimensional array) with
     * expected values.
     * @param actuals Object array or array of arrays (multi-dimensional array) with
     * actual values
     */
    static void assertArrayEquals(string message, Object[] expecteds, Object[] actuals) {
        internalArrayEquals(message, expecteds, actuals);
    }

    /**
     * Asserts that two object arrays are equal. If they are not, an
     * {@link AssertionError} is thrown. If <code>expected</code> and
     * <code>actual</code> are <code>null</code>, they are considered
     * equal.
     *
     * @param expecteds Object array or array of arrays (multi-dimensional array) with
     * expected values
     * @param actuals Object array or array of arrays (multi-dimensional array) with
     * actual values
     */
    static void assertArrayEquals(Object[] expecteds, Object[] actuals) {
        assertArrayEquals(null, expecteds, actuals);
    }

    /**
     * Asserts that two bool arrays are equal. If they are not, an
     * {@link AssertionError} is thrown with the given message. If
     * <code>expecteds</code> and <code>actuals</code> are <code>null</code>,
     * they are considered equal.
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param expecteds bool array with expected values.
     * @param actuals bool array with expected values.
     */
    static void assertArrayEquals(string message, bool[] expecteds, bool[] actuals) {
        internalArrayEquals(message, expecteds, actuals);
    }

    /**
     * Asserts that two bool arrays are equal. If they are not, an
     * {@link AssertionError} is thrown. If <code>expected</code> and
     * <code>actual</code> are <code>null</code>, they are considered
     * equal.
     *
     * @param expecteds bool array with expected values.
     * @param actuals bool array with expected values.
     */
    static void assertArrayEquals(bool[] expecteds, bool[] actuals) {
        assertArrayEquals(null, expecteds, actuals);
    }

    /**
     * Asserts that two byte arrays are equal. If they are not, an
     * {@link AssertionError} is thrown with the given message.
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param expecteds byte array with expected values.
     * @param actuals byte array with actual values
     */
    static void assertArrayEquals(string message, byte[] expecteds, byte[] actuals) {
        internalArrayEquals(message, expecteds, actuals);
    }

    /**
     * Asserts that two byte arrays are equal. If they are not, an
     * {@link AssertionError} is thrown.
     *
     * @param expecteds byte array with expected values.
     * @param actuals byte array with actual values
     */
    static void assertArrayEquals(byte[] expecteds, byte[] actuals) {
        assertArrayEquals(null, expecteds, actuals);
    }

    /**
     * Asserts that two char arrays are equal. If they are not, an
     * {@link AssertionError} is thrown with the given message.
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param expecteds char array with expected values.
     * @param actuals char array with actual values
     */
    static void assertArrayEquals(string message, char[] expecteds, char[] actuals) {
        internalArrayEquals(message, expecteds, actuals);
    }

    /**
     * Asserts that two char arrays are equal. If they are not, an
     * {@link AssertionError} is thrown.
     *
     * @param expecteds char array with expected values.
     * @param actuals char array with actual values
     */
    static void assertArrayEquals(char[] expecteds, char[] actuals) {
        assertArrayEquals(null, expecteds, actuals);
    }

    /**
     * Asserts that two short arrays are equal. If they are not, an
     * {@link AssertionError} is thrown with the given message.
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param expecteds short array with expected values.
     * @param actuals short array with actual values
     */
    static void assertArrayEquals(string message, short[] expecteds, short[] actuals) {
        internalArrayEquals(message, expecteds, actuals);
    }

    /**
     * Asserts that two short arrays are equal. If they are not, an
     * {@link AssertionError} is thrown.
     *
     * @param expecteds short array with expected values.
     * @param actuals short array with actual values
     */
    static void assertArrayEquals(short[] expecteds, short[] actuals) {
        assertArrayEquals(null, expecteds, actuals);
    }

    /**
     * Asserts that two int arrays are equal. If they are not, an
     * {@link AssertionError} is thrown with the given message.
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param expecteds int array with expected values.
     * @param actuals int array with actual values
     */
    static void assertArrayEquals(string message, int[] expecteds, int[] actuals) {
        internalArrayEquals(message, expecteds, actuals);
    }

    /**
     * Asserts that two int arrays are equal. If they are not, an
     * {@link AssertionError} is thrown.
     *
     * @param expecteds int array with expected values.
     * @param actuals int array with actual values
     */
    static void assertArrayEquals(int[] expecteds, int[] actuals) {
        assertArrayEquals(null, expecteds, actuals);
    }

    /**
     * Asserts that two long arrays are equal. If they are not, an
     * {@link AssertionError} is thrown with the given message.
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param expecteds long array with expected values.
     * @param actuals long array with actual values
     */
    static void assertArrayEquals(string message, long[] expecteds, long[] actuals) {
        internalArrayEquals(message, expecteds, actuals);
    }

    /**
     * Asserts that two long arrays are equal. If they are not, an
     * {@link AssertionError} is thrown.
     *
     * @param expecteds long array with expected values.
     * @param actuals long array with actual values
     */
    static void assertArrayEquals(long[] expecteds, long[] actuals) {
        assertArrayEquals(null, expecteds, actuals);
    }

    /**
     * Asserts that two double arrays are equal. If they are not, an
     * {@link AssertionError} is thrown with the given message.
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param expecteds double array with expected values.
     * @param actuals double array with actual values
     * @param delta the maximum delta between <code>expecteds[i]</code> and
     * <code>actuals[i]</code> for which both numbers are still
     * considered equal.
     */
    // static void assertArrayEquals(string message, double[] expecteds,
    //         double[] actuals, double delta){
    //     // new InexactComparisonCriteria(delta).arrayEquals(message, expecteds, actuals);
    // }

    /**
     * Asserts that two double arrays are equal. If they are not, an
     * {@link AssertionError} is thrown.
     *
     * @param expecteds double array with expected values.
     * @param actuals double array with actual values
     * @param delta the maximum delta between <code>expecteds[i]</code> and
     * <code>actuals[i]</code> for which both numbers are still
     * considered equal.
     */
    // static void assertArrayEquals(double[] expecteds, double[] actuals, double delta) {
    //     assertArrayEquals(null, expecteds, actuals, delta);
    // }

    /**
     * Asserts that two float arrays are equal. If they are not, an
     * {@link AssertionError} is thrown with the given message.
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param expecteds float array with expected values.
     * @param actuals float array with actual values
     * @param delta the maximum delta between <code>expecteds[i]</code> and
     * <code>actuals[i]</code> for which both numbers are still
     * considered equal.
     */
    // static void assertArrayEquals(string message, float[] expecteds,
    //         float[] actuals, float delta){
    //     new InexactComparisonCriteria(delta).arrayEquals(message, expecteds, actuals);
    // }

    /**
     * Asserts that two float arrays are equal. If they are not, an
     * {@link AssertionError} is thrown.
     *
     * @param expecteds float array with expected values.
     * @param actuals float array with actual values
     * @param delta the maximum delta between <code>expecteds[i]</code> and
     * <code>actuals[i]</code> for which both numbers are still
     * considered equal.
     */
    // static void assertArrayEquals(float[] expecteds, float[] actuals, float delta) {
    //     assertArrayEquals(null, expecteds, actuals, delta);
    // }

    /**
     * Asserts that two object arrays are equal. If they are not, an
     * {@link AssertionError} is thrown with the given message. If
     * <code>expecteds</code> and <code>actuals</code> are <code>null</code>,
     * they are considered equal.
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param expecteds Object array or array of arrays (multi-dimensional array) with
     * expected values.
     * @param actuals Object array or array of arrays (multi-dimensional array) with
     * actual values
     */
    private static void internalArrayEquals(T)(string message, T[] expecteds, T[] actuals) {
        // new ExactComparisonCriteria().arrayEquals(message, expecteds, actuals);
        assert(expecteds.length == actuals.length, message);
        for (int i = 0; i < expecteds.length; i++) {
            assertEquals(message, expecteds[i], actuals[i]);
        }
    }

    /**
     * Asserts that two doubles are equal to within a positive delta.
     * If they are not, an {@link AssertionError} is thrown with the given
     * message. If the expected value is infinity then the delta value is
     * ignored. NaNs are considered equal:
     * <code>assertEquals(Double.NaN, Double.NaN, *)</code> passes
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param expected expected value
     * @param actual the value to check against <code>expected</code>
     * @param delta the maximum delta between <code>expected</code> and
     * <code>actual</code> for which both numbers are still
     * considered equal.
     */
    static void assertEquals(size_t line = __LINE__, string file = __FILE__)(
            string message, double expected, double actual, double delta) {
        if (doubleIsDifferent(expected, actual, delta)) {
            failNotEquals!(double, line, file)(message, expected, actual);
        }
    }

    /**
     * Asserts that two floats are equal to within a positive delta.
     * If they are not, an {@link AssertionError} is thrown with the given
     * message. If the expected value is infinity then the delta value is
     * ignored. NaNs are considered equal:
     * <code>assertEquals(Float.NaN, Float.NaN, *)</code> passes
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param expected expected value
     * @param actual the value to check against <code>expected</code>
     * @param delta the maximum delta between <code>expected</code> and
     * <code>actual</code> for which both numbers are still
     * considered equal.
     */
    static void assertEquals(string message, float expected, float actual, float delta) {
        if (floatIsDifferent(expected, actual, delta)) {
            failNotEquals(message, expected, actual);
        }
    }

    /**
     * Asserts that two floats are <b>not</b> equal to within a positive delta.
     * If they are, an {@link AssertionError} is thrown with the given
     * message. If the unexpected value is infinity then the delta value is
     * ignored. NaNs are considered equal:
     * <code>assertNotEquals(Float.NaN, Float.NaN, *)</code> fails
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param unexpected unexpected value
     * @param actual the value to check against <code>unexpected</code>
     * @param delta the maximum delta between <code>unexpected</code> and
     * <code>actual</code> for which both numbers are still
     * considered equal.
     */
    static void assertNotEquals(string message, float unexpected, float actual, float delta) {
        if (!floatIsDifferent(unexpected, actual, delta)) {
            failEquals(message, actual);
        }
    }

    static private bool doubleIsDifferent(double d1, double d2, double delta) {
        if (d1 == d2) {
            return false;
        }
        if ((std.math.abs(d1 - d2) <= delta)) {
            return false;
        }

        return true;
    }

    static private bool floatIsDifferent(float f1, float f2, float delta) {
        if (f1 == f2) {
            return false;
        }
        if ((std.math.abs(f1 - f2) <= delta)) {
            return false;
        }

        return true;
    }

    /**
     * Asserts that two longs are equal. If they are not, an
     * {@link AssertionError} is thrown.
     *
     * @param expected expected long value.
     * @param actual actual long value
     */
    static void assertEquals(long expected, long actual) {
        assertEquals(null, expected, actual);
    }

    /**
     * Asserts that two longs are equal. If they are not, an
     * {@link AssertionError} is thrown with the given message.
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param expected long expected value.
     * @param actual long actual value
     */
    static void assertEquals(string message, long expected, long actual) {
        if (expected != actual) {
            failNotEquals(message, expected, actual);
        }
    }

    /**
     * @deprecated Use
     *             <code>assertEquals(double expected, double actual, double delta)</code>
     *             instead
     */
    // deprecated("")
    // static void assertEquals(double expected, double actual) {
    //     assertEquals(null, expected, actual);
    // }

    /**
     * @deprecated Use
     *             <code>assertEquals(string message, double expected, double actual, double delta)</code>
     *             instead
     */
    // deprecated("")
    // static void assertEquals(string message, double expected,
    //         double actual) {
    //     fail("Use assertEquals(expected, actual, delta) to compare floating-point numbers");
    // }

    /**
     * Asserts that two doubles are equal to within a positive delta.
     * If they are not, an {@link AssertionError} is thrown. If the expected
     * value is infinity then the delta value is ignored.NaNs are considered
     * equal: <code>assertEquals(Double.NaN, Double.NaN, *)</code> passes
     *
     * @param expected expected value
     * @param actual the value to check against <code>expected</code>
     * @param delta the maximum delta between <code>expected</code> and
     * <code>actual</code> for which both numbers are still
     * considered equal.
     */
    static void assertEquals(double expected, double actual, double delta) {
        assertEquals(null, expected, actual, delta);
    }

    /**
     * Asserts that two floats are equal to within a positive delta.
     * If they are not, an {@link AssertionError} is thrown. If the expected
     * value is infinity then the delta value is ignored. NaNs are considered
     * equal: <code>assertEquals(Float.NaN, Float.NaN, *)</code> passes
     *
     * @param expected expected value
     * @param actual the value to check against <code>expected</code>
     * @param delta the maximum delta between <code>expected</code> and
     * <code>actual</code> for which both numbers are still
     * considered equal.
     */

    static void assertEquals(float expected, float actual, float delta) {
        assertEquals(null, expected, actual, delta);
    }

    /**
     * Asserts that an object isn't null. If it is an {@link AssertionError} is
     * thrown with the given message.
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param object Object to check or <code>null</code>
     */
    static void assertNotNull(T)(string message, T object) {
        assertTrue(message, object !is null);
    }

    /**
     * Asserts that an object isn't null. If it is an {@link AssertionError} is
     * thrown.
     *
     * @param object Object to check or <code>null</code>
     */
    static void assertNotNull(T)(T object) {
        assertNotNull!(T)(null, object);
    }

    /**
     * Asserts that an object is null. If it is not, an {@link AssertionError}
     * is thrown with the given message.
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param object Object to check or <code>null</code>
     */
    static void assertNull(T, size_t line = __LINE__, string file = __FILE__)(
            string message, T object) {
        static if (is(T == class) || is(T == interface)) {
            if (object is null)
                return;
        } else static if (is(T == struct)) {
            if (object == T.init)
                return;
        } else {
            if (object.empty)
                return;
        }
        failNotNull!(T, line, file)(message, object);
    }

    /**
     * Asserts that an object is null. If it isn't an {@link AssertionError} is
     * thrown.
     *
     * @param object Object to check or <code>null</code>
     */
    static void assertNull(T, size_t line = __LINE__, string file = __FILE__)(T object) {
        assertNull!(T, line, file)(null, object);
    }

    static private void failNotNull(T, size_t line = __LINE__, string file = __FILE__)(
            string message, T actual) {
        string formatted = "";
        if (message !is null) {
            formatted = message ~ " ";
        }
        static if (is(T == class)) {
            fail!(line, file)(formatted ~ "expected null, but was:<" ~ actual.toString() ~ ">");
        } else {
            fail!(line, file)(formatted ~ "expected null, but was:<" ~ to!string(actual) ~ ">");
        }
    }

    /**
     * Asserts that two objects refer to the same object. If they are not, an
     * {@link AssertionError} is thrown with the given message.
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param expected the expected object
     * @param actual the object to compare to <code>expected</code>
     */
    static void assertSame(T, size_t line = __LINE__, string file = __FILE__)(
            string message, T expected, T actual) {
        if (expected == actual) {
            return;
        }
        failNotSame!(T, line, file)(message, expected, actual);
    }

    /**
     * Asserts that two objects refer to the same object. If they are not the
     * same, an {@link AssertionError} without a message is thrown.
     *
     * @param expected the expected object
     * @param actual the object to compare to <code>expected</code>
     */
    static void assertSame(T, size_t line = __LINE__, string file = __FILE__)(T expected, T actual) {
        assertSame!(T, line, file)(null, expected, actual);
    }

    /**
     * Asserts that two objects do not refer to the same object. If they do
     * refer to the same object, an {@link AssertionError} is thrown with the
     * given message.
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param unexpected the object you don't expect
     * @param actual the object to compare to <code>unexpected</code>
     */
    static void assertNotSame(T, size_t line = __LINE__, string file = __FILE__)(
            string message, T unexpected, T actual) {
        if (unexpected == actual) {
            failSame!(line, file)(message);
        }
    }

    /**
     * Asserts that two objects do not refer to the same object. If they do
     * refer to the same object, an {@link AssertionError} without a message is
     * thrown.
     *
     * @param unexpected the object you don't expect
     * @param actual the object to compare to <code>unexpected</code>
     */
    static void assertNotSame(T, size_t line = __LINE__, string file = __FILE__)(
            T unexpected, T actual) {
        assertNotSame!(T, line, file)("", unexpected, actual);
    }

    static private void failSame(size_t line = __LINE__, string file = __FILE__)(string message) {
        string formatted = "";
        if (!message.empty) {
            formatted = message ~ " ";
        }
        fail!(line, file)(formatted ~ "expected not same");
    }

    static private void failNotSame(T, size_t line = __LINE__, string file = __FILE__)(
            string message, T expected, T actual) {
        string formatted = "";
        if (!message.empty) {
            formatted = message ~ " ";
        }
        fail!(line, file)(formatted ~ "expected same:<" ~ typeid(expected)
                .toString() ~ "> was not:<" ~ typeid(actual).toString() ~ ">");
    }

    static private void failNotEquals(T, size_t line = __LINE__, string file = __FILE__)(
            string message, T expected, T actual) {
        fail!(line, file)(format(message, expected, actual));
    }

    static string format(T)(string message, T expected, T actual)
            if (is(T == class) || is(T == struct) || is(T == interface)) {
        string formatted = "";
        if (!message.empty) {
            formatted = message ~ " ";
        }
        string expectedString = expected.toString();
        string actualString = actual.toString();
        if (expectedString == actualString) {
            return formatted ~ "expected: " ~ formatClassAndValue(expected,
                    expectedString) ~ " but was: " ~ formatClassAndValue(actual, actualString);
        } else {
            return formatted ~ "expected:<" ~ expectedString ~ "> but was:<" ~ actualString ~ ">";
        }
    }

    // static private void failNotEquals(T, size_t line = __LINE__, string file = __FILE__)
    //     (string message, T expected, T actual)
    //         if (isNumeric!T) {
    //     fail!(line, file)(format(message, expected, actual));
    // }

    static string format(T)(string message, T expected, T actual) if (isNumeric!T) {
        string formatted = "";
        if (!message.empty) {
            formatted = message ~ " ";
        }
        string expectedString = to!string(expected);
        string actualString = to!string(actual);
        if (expected != actual) {
            return formatted ~ "expected: " ~ expectedString ~ " but was: " ~ actualString;
        } else {
            return formatted;
        }
    }

    private static string formatClassAndValue(Object value, string valueString) {
        string className = value is null ? "null" : typeof(value).stringof;
        return className ~ "<" ~ valueString ~ ">";
    }

    /**
     * Asserts that two object arrays are equal. If they are not, an
     * {@link AssertionError} is thrown with the given message. If
     * <code>expecteds</code> and <code>actuals</code> are <code>null</code>,
     * they are considered equal.
     *
     * @param message the identifying message for the {@link AssertionError} (<code>null</code>
     * okay)
     * @param expecteds Object array or array of arrays (multi-dimensional array) with
     * expected values.
     * @param actuals Object array or array of arrays (multi-dimensional array) with
     * actual values
     * @deprecated use assertArrayEquals
     */
    // deprecated("")
    // static void assertEquals(string message, Object[] expecteds,
    //         Object[] actuals) {
    //     assertArrayEquals(message, expecteds, actuals);
    // }

    /**
     * Asserts that two object arrays are equal. If they are not, an
     * {@link AssertionError} is thrown. If <code>expected</code> and
     * <code>actual</code> are <code>null</code>, they are considered
     * equal.
     *
     * @param expecteds Object array or array of arrays (multi-dimensional array) with
     * expected values
     * @param actuals Object array or array of arrays (multi-dimensional array) with
     * actual values
     * @deprecated use assertArrayEquals
     */
    // deprecated("")
    // static void assertEquals(Object[] expecteds, Object[] actuals) {
    //     assertArrayEquals(expecteds, actuals);
    // }

    /**
     * Asserts that <code>actual</code> satisfies the condition specified by
     * <code>matcher</code>. If not, an {@link AssertionError} is thrown with
     * information about the matcher and failing value. Example:
     *
     * <pre>
     *   assertThat(0, is(1)); // fails:
     *     // failure message:
     *     // expected: is &lt;1&gt;
     *     // got value: &lt;0&gt;
     *   assertThat(0, is(not(1))) // passes
     * </pre>
     *
     * <code>org.hamcrest.Matcher</code> does not currently document the meaning
     * of its type parameter <code>T</code>.  This method assumes that a matcher
     * typed as <code>Matcher&lt;T&gt;</code> can be meaningfully applied only
     * to values that could be assigned to a variable of type <code>T</code>.
     *
     * @param (T) the static type accepted by the matcher (this can flag obvious
     * compile-time problems such as {@code assertThat(1, is("a"))}
     * @param actual the computed value being compared
     * @param matcher an expression, built of {@link Matcher}s, specifying allowed
     * values
     * @see org.hamcrest.CoreMatchers
     * @see org.hamcrest.MatcherAssert
     */
    static void assertThat(T, size_t line = __LINE__, string file = __FILE__)(T actual, T matcher) {
        assertThat!(T, line, file)("", actual, matcher);
    }

    /**
     * Asserts that <code>actual</code> satisfies the condition specified by
     * <code>matcher</code>. If not, an {@link AssertionError} is thrown with
     * the reason and information about the matcher and failing value. Example:
     *
     * <pre>
     *   assertThat(&quot;Help! Integers don't work&quot;, 0, is(1)); // fails:
     *     // failure message:
     *     // Help! Integers don't work
     *     // expected: is &lt;1&gt;
     *     // got value: &lt;0&gt;
     *   assertThat(&quot;Zero is one&quot;, 0, is(not(1))) // passes
     * </pre>
     *
     * <code>org.hamcrest.Matcher</code> does not currently document the meaning
     * of its type parameter <code>T</code>.  This method assumes that a matcher
     * typed as <code>Matcher&lt;T&gt;</code> can be meaningfully applied only
     * to values that could be assigned to a variable of type <code>T</code>.
     *
     * @param reason additional information about the error
     * @param (T) the static type accepted by the matcher (this can flag obvious
     * compile-time problems such as {@code assertThat(1, is("a"))}
     * @param actual the computed value being compared
     * @param matcher an expression, built of {@link Matcher}s, specifying allowed
     * values
     * @see org.hamcrest.CoreMatchers
     * @see org.hamcrest.MatcherAssert
     */
    static void assertThat(T, size_t line = __LINE__, string file = __FILE__)(
            string message, T actual, T matcher) {
        // trace("actual=>", actual);
        // trace("matcher=>", matcher);
        if (message.empty)
            message = std.format.format("raised in %s:%s", file, line);
        else
            message = std.format.format("raised in %s:%s, reason: %s", file, line, message);
        assert(actual == matcher, message);
    }

    static void assertContain(T)(T source, T substring) {
        assert(source.canFind(substring), source);
    }

    static void assertStartsWith(T)(T source, T substring) {
        assert(source.startsWith(substring));
    }

    /**
	 * Assert a bool expression, throwing {@code IllegalStateException} if
	 * the test result is {@code false}. Call isTrue if you wish to throw
	 * IllegalArgumentException on an assertion failure.
	 * 
	 * <pre class="code">
	 * Assert.state(id is null, "The id property must not already be initialized");
	 * </pre>
	 * 
	 * @param expression
	 *            a bool expression
	 * @param message
	 *            the exception message to use if the assertion fails
	 * @throws IllegalStateException
	 *             if expression is {@code false}
	 */
    static void state(bool expression, string message) {
        if (!expression) {
            throw new IllegalStateException(message);
        }
    }
}
