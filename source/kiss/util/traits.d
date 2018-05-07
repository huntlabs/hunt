module kiss.util.traits;

public import std.traits;
import std.typecons;
import std.meta;

alias Helper(alias T) = T;

template Pointer(T) {
    static if (is(T == class) || is(T == interface)) {
        alias Pointer = T;
    } else {
        alias Pointer = T *;
    }
}

template isInheritClass(T, Base) {
    enum FFilter(U) = is(U == Base);
    enum isInheritClass = (Filter!(FFilter, BaseTypeTuple!T).length > 0);
}

template isOnlyCharByte(T) {
    enum bool isOnlyCharByte = is(T == byte) || is(T == ubyte) || is(T == char);
}

template isCharByte(T) {
    enum bool isCharByte = is(Unqual!T == byte) || is(Unqual!T == ubyte) || is(Unqual!T == char);
}


template isRefType(T)
{
    enum isRefType = /*isPointer!T ||*/ isDelegate!T || isDynamicArray!T ||
            isAssociativeArray!T || is (T == class) || is(T == interface);
}

template isPublic(alias T)
{
	enum protection =  __traits(getProtection,T);
	enum isPublic = (protection == "public");
}
