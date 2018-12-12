

module hunt.time.text.ParsePosition;

import std.conv;
/**
 * <code>ParsePosition</code> is a simple class used by <code>Format</code>
 * and its subclasses to keep track of the current position during parsing.
 * The <code>parseObject</code> method in the various <code>Format</code>
 * classes requires a <code>ParsePosition</code> object as an argument.
 *
 * <p>
 * By design, as you parse through a string with different formats,
 * you can use the same <code>ParsePosition</code>, since the index parameter
 * records the current position.
 *
 * @author      Mark Davis
 * @since 1.1
 * @see         java.text.Format
 */

public class ParsePosition {

    /**
     * Input: the place you start parsing.
     * <br>Output: position where the parse stopped.
     * This is designed to be used serially,
     * with each call setting index up for the next one.
     */
    int index = 0;
    int errorIndex = -1;

    /**
     * Retrieve the current parse position.  On input to a parse method, this
     * is the index of the character at which parsing will begin; on output, it
     * is the index of the character following the last character parsed.
     *
     * @return the current parse position
     */
    public int getIndex() {
        return index;
    }

    /**
     * Set the current parse position.
     *
     * @param index the current parse position
     */
    public void setIndex(int index) {
        this.index = index;
    }

    /**
     * Create a new ParsePosition with the given initial index.
     *
     * @param index initial index
     */
    public this(int index) {
        this.index = index;
    }
    /**
     * Set the index at which a parse error occurred.  Formatters
     * should set this before returning an error code from their
     * parseObject method.  The default value is -1 if this is not set.
     *
     * @param ei the index at which an error occurred
     * @since 1.2
     */
    public void setErrorIndex(int ei)
    {
        errorIndex = ei;
    }

    /**
     * Retrieve the index at which an error occurred, or -1 if the
     * error index has not been set.
     *
     * @return the index at which an error occurred
     * @since 1.2
     */
    public int getErrorIndex()
    {
        return errorIndex;
    }

    /**
     * Overrides equals
     */
     override
    public bool opEquals(Object obj)
    {
        if (obj is null) return false;
        if (!(cast(ParsePosition)obj !is null))
            return false;
        ParsePosition other = cast(ParsePosition) obj;
        return (index == other.index && errorIndex == other.errorIndex);
    }

    /**
     * Returns a hash code for this ParsePosition.
     * @return a hash code value for this object
     */
    override
    public size_t toHash() @trusted nothrow {
        return (errorIndex << 16) | index;
    }

    /**
     * Return a string representation of this ParsePosition.
     * @return  a string representation of this object
     */
    override
    public string toString() {
        return typeof(this).stringof ~
            "[index=" ~ index.to!string ~
            ",errorIndex=" ~ errorIndex.to!string ~ ']';
    }
}
