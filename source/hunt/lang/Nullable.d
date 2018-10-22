module hunt.lang.Nullable;

import hunt.lang.object;

/**
*/
class Nullable(T) : IObject {
    
    protected T _value;
    private bool _isNull = true;

    alias value this;

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

    void opAssign(T v) {
        _value = v;
        _isNull = false;
    }

    // U opCast(U)() {
    //     return cast(U)_value;
    // }

    bool opEquals(T v) {
        return this._value == v;
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
        import std.conv;
        // static if(is(T == class)) {
        //     return this._value.toString();
        // } else static if(is(T == struct)) {
        //     return this._value.toString();
        // } else {
        //     return super.toString();
        // }
        return to!string(_value);
    }

    override size_t toHash() @trusted nothrow {
        return super.toHash();
    }
}

