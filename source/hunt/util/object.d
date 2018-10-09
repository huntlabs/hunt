module hunt.util.object;

import hunt.util.exception;

interface IObject {
    bool opEquals(Object o);
    string toString();
    size_t toHash() @trusted nothrow;
}

/**
*/
class NullableObject(T) : IObject {
    T payload;

    private bool _isNull = true;

    this() {
        payload = T.init;
    }

    this(T v) {
        payload = v;
        _isNull = false;
    }

    bool isNull() {
        return _isNull;
    }

    override bool opEquals(Object o) {
        NullableObject!(T) that = cast(NullableObject!(T))o;
        if(that is null)
            return false;

        if(_isNull) return that._isNull;
        if(that._isNull) return false;

        static if(is(T == class)) {
            if(this.payload is that.payload)
                return true;
        }

        if(this.payload == that.payload)
            return true;
        return false;
    }

    string toString() {
        return super.toString();
    }

    size_t toHash() @trusted nothrow {
        return super.toHash();
    }
}


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
