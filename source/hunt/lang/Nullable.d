module hunt.lang.Nullable;

import hunt.lang.object;

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

