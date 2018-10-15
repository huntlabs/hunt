module hunt.lang.object;

import hunt.util.exception;

interface IObject {
    bool opEquals(Object o);
    string toString();
    size_t toHash() @trusted nothrow;
}

/**
*/
class Nullable(T) : IObject {
    private T _value;
    private bool _isNull = true;

    this() {
        _value = T.init;
    }

    this(T v) {
        _value = v;
        _isNull = false;
    }

    bool isNull() {
        return _isNull;
    }

    T value() {
        return _value;
    }

    override bool opEquals(Object o) {
        Nullable!(T) that = cast(Nullable!(T))o;
        if(that is null)
            return false;

        if(_isNull) return that._isNull;
        if(that._isNull) return false;

        static if(is(T == class)) {
            if(this._value is that._value)
                return true;
        }

        if(this._value == that._value)
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
