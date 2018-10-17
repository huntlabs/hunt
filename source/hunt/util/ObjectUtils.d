module hunt.util.ObjectUtils;

import hunt.lang.exception;
import std.format;


/**
 * <p>
 * The root class from which all event state objects shall be derived.
 * <p>
 * All Events are constructed with a reference to the object, the "source",
 * that is logically deemed to be the object upon which the Event in question
 * initially occurred upon.
 */
class EventObject {

    /**
     * The object on which the Event initially occurred.
     */
    protected Object  source;

    /**
     * Constructs a prototypical Event.
     *
     * @param    source    The object on which the Event initially occurred.
     * @exception  IllegalArgumentException  if source is null.
     */
    this(Object source) {
        if (source is null)
            throw new IllegalArgumentException("null source");

        this.source = source;
    }

    /**
     * The object on which the Event initially occurred.
     *
     * @return   The object on which the Event initially occurred.
     */
    Object getSource() {
        return source;
    }

    /**
     * Returns a string representation of this EventObject.
     *
     * @return  A a string representation of this EventObject.
     */
    override
    string toString() {
        return typeid(this).name ~ "[source=" ~ source.toString() ~ "]";
    }
}



class ObjectUtils {

    private enum int INITIAL_HASH = 7;
	private enum int MULTIPLIER = 31;

	private enum string EMPTY_STRING = "";
	private enum string NULL_STRING = "null";
	private enum string ARRAY_START = "{";
	private enum string ARRAY_END = "}";
	private enum string EMPTY_ARRAY = ARRAY_START ~ ARRAY_END;
	private enum string ARRAY_ELEMENT_SEPARATOR = ", ";
    
    /**
	 * Return a string representation of an object's overall identity.
	 * @param obj the object (may be {@code null})
	 * @return the object's identity as string representation,
	 * or an empty string if the object was {@code null}
	 */
	static string identityToString(Object obj) {
		if (obj is null) {
			return EMPTY_STRING;
		}
		return typeid(obj).name ~ "@" ~ getIdentityHexString(obj);
	}



	/**
	 * Return a hex String form of an object's identity hash code.
	 * @param obj the object
	 * @return the object's identity code in hex notation
	 */
	static string getIdentityHexString(Object obj) {
		return format("%s", cast(void*)obj);
	}

}
