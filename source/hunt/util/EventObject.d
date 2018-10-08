module hunt.util.EventObject;

import hunt.util.exception;


/**
 * <p>
 * The root class from which all event state objects shall be derived.
 * <p>
 * All Events are constructed with a reference to the object, the "source",
 * that is logically deemed to be the object upon which the Event in question
 * initially occurred upon.
 */
class EventObject {

    // private enum long serialVersionUID = 5516075349620653480L;

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
