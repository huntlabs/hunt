module hunt.lang.Nullable;

import hunt.lang.object;

/**
*/
class Nullable(T) : IObject {
    
    protected T _value;
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

    T value() @trusted nothrow {
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

        return this._value == that._value;
    }

    override string toString() {
        return super.toString();
    }

    override size_t toHash() @trusted nothrow {
        return super.toHash();
    }
}

