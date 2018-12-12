
module hunt.time.DateTimeException;

import std.exception;
/**
 * Exception used to indicate a problem while calculating a date-time.
 * !(p)
 * This exception is used to indicate problems with creating, querying
 * and manipulating date-time objects.
 *
 * @implSpec
 * This class is intended for use _in a single thread.
 *
 * @since 1.8
 */
public class DateTimeException : Exception {

    /**
     * Serialization version.
     */
    private static  long serialVersionUID = -1632418723876261839L;

    /**
     * Constructs a new date-time exception with the specified message.
     *
     * @param message  the message to use for this exception, may be null
     */
    public this(string message) {
        super(message);
    }

    /**
     * Constructs a new date-time exception with the specified message and cause.
     *
     * @param message  the message to use for this exception, may be null
     * @param cause  the cause of the exception, may be null
     */
    public this(string message, Throwable cause) {
        super(message, cause);
    }

}
