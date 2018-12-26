module hunt.lang.Nullable;

import hunt.lang.common;
import hunt.lang.exception;
import hunt.lang.Object;

import std.traits;

interface INullable : IObject {
    TypeInfo valueType();

    // const(ubyte)[] getBytes();
}

/**
*/
class Nullable(T) : INullable {
    
    protected T _value;
    private TypeInfo _valueType;
    private bool _isNull = true;

    alias value this;

    this() {
        _value = T.init;
        _valueType = typeid(T);
    }

    this(T v) {
        _value = v;
        _isNull = false;
        _valueType = typeid(T);
    }


    /**
     * Returns an {@code Nullable} describing the given non-{@code null}
     * value.
     *
     * @param value the value to describe, which must be non-{@code null}
     * @param U the type of the value
     * @return an {@code Nullable} with the value present
     * @throws NullPointerException if value is {@code null}
     */
    static Nullable!U of(U)(U value) {
        return new Nullable!U(value);
    }

    /**
     * Returns an {@code Nullable} describing the given value, if
     * non-{@code null}, otherwise returns an empty {@code Nullable}.
     *
     * @param value the possibly-{@code null} value to describe
     * @param !U the type of the value
     * @return an {@code Nullable} with a present value if the specified value
     *         is non-{@code null}, otherwise an empty {@code Nullable}
     */
    static Nullable!U ofNullable(U)(U value) 
        if(!isBasicType!U && !is(T == struct) && !is(T == enum)) {
        return value is null ? empty!U() : of(value);
    }


    /**
     * Returns an empty {@code Nullable} instance.  No value is present for this
     * {@code Nullable}.
     *
     * @apiNote
     * Though it may be tempting to do so, avoid testing if an object is empty
     * by comparing with {@code ==} against instances returned by
     * {@code Nullable.empty()}.  There is no guarantee that it is a singleton.
     * Instead, use {@link #isPresent()}.
     *
     * @param U The type of the non-existent value
     * @return an empty {@code Nullable}
     */
    static Nullable!U empty(U)() {
        return new Nullable!U();
    }

    TypeInfo valueType() {
        return _valueType;
    }

    T value() @trusted nothrow {
        return _value;
    }

    alias payload = value;

    /**
     * If a value is present, returns the value, otherwise throws
     * {@code NoSuchElementException}.
     *
     * @apiNote
     * The preferred alternative to this method is {@link #orElseThrow()}.
     *
     * @return the non-{@code null} value described by this {@code Nullable}
     * @throws NoSuchElementException if no value is present
     */
    T get() {
        if (_isNull) {
            throw new NoSuchElementException("No value present");
        }
        return value;
    }

    bool isNull() {
        return _isNull;
    }

    /**
     * If a value is present, returns {@code true}, otherwise {@code false}.
     *
     * @return {@code true} if a value is present, otherwise {@code false}
     */
    bool isPresent() {
        return !_isNull;
    }

    /**
     * If a value is present, performs the given action with the value,
     * otherwise does nothing.
     *
     * @param action the action to be performed, if a value is present
     * @throws NullPointerException if value is present and the given action is
     *         {@code null}
     */
    void ifPresent(Consumer!T action) {
        if (!_isNull) {
            action(value);
        }
    }

    // void opAssign(T v) {
    //     _value = v;
    //     _isNull = false;
    // }

    // U opCast(U)() {
    //     return cast(U)_value;
    // }

    bool opEquals(const(IObject) o) const {
        return opEquals(cast(Object)o);
    }

    bool opEquals(T v) const {
        return this._value == v;
    }

    override bool opEquals(const(Object) o) const {
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
        static if(is(T == string)) {
            return this._value;
        } else {
            return to!string(_value);
        }
    }

    override size_t toHash() @trusted nothrow {
        return super.toHash();
    }
}
