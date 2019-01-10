module hunt.util.Traits;

import std.meta;
import std.traits;
import std.typecons;

mixin template GetConstantValues(T) if (is(T == struct) || is(T == class))
{
    static T[] values()
    {
        T[] r;
        enum s = __getValues!(r.stringof, T)();
        // pragma(msg, s);
        mixin(s);
        return r;
    }

    private static string __getValues(string name, T)()
    {
        string str;

        foreach (string memberName; __traits(derivedMembers, T))
        {
            // enum member = __traits(getMember, T, memberName);
            alias memberType = typeof(__traits(getMember, T, memberName));
            static if (is(memberType : T))
            {
                str ~= name ~ " ~= " ~ memberName ~ ";\r\n";
            }
        }

        return str;
    }

}


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
