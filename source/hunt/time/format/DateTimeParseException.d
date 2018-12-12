
module hunt.time.format.DateTimeParseException;

import hunt.time.DateTimeException;

/**
 * An exception thrown when an error occurs during parsing.
 * !(p)
 * This exception includes the text being parsed and the error index.
 *
 * @implSpec
 * This class is intended for use _in a single thread.
 *
 * @since 1.8
 */
public class DateTimeParseException : DateTimeException {

    /**
     * Serialization version.
     */
    private static const long serialVersionUID = 4304633501674722597L;

    /**
     * The text that was being parsed.
     */
    private const string parsedString;
    /**
     * The error index _in the text.
     */
    private const int errorIndex;

    /**
     * Constructs a new exception with the specified message.
     *
     * @param message  the message to use for this exception, may be null
     * @param parsedData  the parsed text, should not be null
     * @param errorIndex  the index _in the parsed string that was invalid, should be a valid index
     */
    public this(string message, string parsedData, int errorIndex) {
        super(message);
        this.parsedString = parsedData;
        this.errorIndex = errorIndex;
    }

    /**
     * Constructs a new exception with the specified message and cause.
     *
     * @param message  the message to use for this exception, may be null
     * @param parsedData  the parsed text, should not be null
     * @param errorIndex  the index _in the parsed string that was invalid, should be a valid index
     * @param cause  the cause exception, may be null
     */
    public this(string message, string parsedData, int errorIndex, Throwable cause) {
        super(message, cause);
        this.parsedString = parsedData;
        this.errorIndex = errorIndex;
    }

    //-----------------------------------------------------------------------
    /**
     * Returns the string that was being parsed.
     *
     * @return the string that was being parsed, should not be null.
     */
    public string getParsedString() {
        return parsedString;
    }

    /**
     * Returns the index where the error was found.
     *
     * @return the index _in the parsed string that was invalid, should be a valid index
     */
    public int getErrorIndex() {
        return errorIndex;
    }

}
