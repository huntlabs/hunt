module hunt.serialization.BinaryDeserializer;

import hunt.serialization.Common;
import hunt.serialization.Specify;
import std.traits;

/**
 * 
 */
struct BinaryDeserializer {

    private {
        const(ubyte)[] _buffer;
    }

    this(ubyte[] buffer) {
        this._buffer = buffer;
    }

    const(ubyte[]) bytes() const nothrow {
        return _buffer;
    }

    ulong bytesLeft() const {
        return _buffer.length;
    }

    T iArchive(SerializationOptions options, T)()
            if (!isDynamicArray!T && !isAssociativeArray!T && !is(T == class) && __traits(compiles, T())) {
        T obj;
        specify!(options)(this, obj);
        return obj;
    }

    T iArchive(SerializationOptions options, T)()
            if (!isDynamicArray!T && !isAssociativeArray!T && !is(T == class)
                && !__traits(compiles, T())) {
        T obj = void;
        specify!(options)(this, obj);
        return obj;
    }

    T iArchive(SerializationOptions options, T, A...)(A args) if (is(T == class)) {
        T obj = new T(args);
        specify!(options)(this, obj);
        return obj;
    }

    T iArchive(SerializationOptions options, T)() if (isDynamicArray!T || isAssociativeArray!T) {
        return iArchive!(options, T, ushort)();
    }

    T iArchive(SerializationOptions options, T, U)() if (isDynamicArray!T || isAssociativeArray!T) {
        T obj;
        specify!(options)(this, obj);
        return obj;
    }

    void putUbyte(ref ubyte val) {
        val = _buffer[0];
        _buffer = _buffer[1 .. $];
    }

    void putClass(SerializationOptions options, T)(T val) if (is(T == class)) {
        specifyClass!(options)(this, val);
    }

    deprecated("Using take instead.")
    alias putRaw = take;

    const(ubyte)[] take(size_t length) {
        const(ubyte)[] res = _buffer[0 .. length];
        _buffer = _buffer[length .. $];
        return res;
    }

    bool isNullObj() {
        return _buffer[0 .. 4] == NULL ? true : false;
    }
}
