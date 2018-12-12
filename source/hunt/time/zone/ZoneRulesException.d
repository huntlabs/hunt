
module hunt.time.zone.ZoneRulesException;

import hunt.time.DateTimeException;

/**
 * Thrown to indicate a problem with time-zone configuration.
 * !(p)
 * This exception is used to indicate a problems with the configured
 * time-zone rules.
 *
 * @implSpec
 * This class is intended for use _in a single thread.
 *
 * @since 1.8
 */
public class ZoneRulesException : DateTimeException {

    /**
     * Serialization version.
     */
    private enum long serialVersionUID = -1632418723876261839L;

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
