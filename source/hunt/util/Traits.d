/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2018-2019 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.util.Traits;

import std.meta;
import std.traits;
import std.typecons;

import std.array;
import std.string;
import std.conv;
import std.stdio;

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



/**
* Params
*	name = xXX will map to T's memeber function void setXXX()
*/
void setProperty(T, Args...)(ref T p, string name, Args value) 
    if(is(T == class) || is(T == struct) || is(T == interface)) {
	enum string MethodPrefix = "set";

	// pragma(msg, "Args: " ~ Args.stringof);

	if (name.empty) {
		throw new Exception("Name can't be empty");
	}

	enum PrefixLength = MethodPrefix.length;
	string currentMember = MethodPrefix ~ toUpper(name[0 .. 1]) ~ name[1 .. $];
	bool isSuccess = false;

	foreach (memberName; __traits(allMembers, T)) {
		// pragma(msg, "Member: " ~ memberName);

		static if (memberName.length > PrefixLength && memberName[0 .. PrefixLength] == MethodPrefix) {
			// writeln("checking: ", memberName);
			if (!isSuccess && currentMember == memberName) {
				isSuccess = true;
				// writefln("value length: %d, name: %s", value.length, value.stringof);
				// foreach (i, s; value) {
				// 	writefln("value[%d] type: %s, value: %s", i, typeid(s), s);
				// }
				static if (is(typeof(__traits(getMember, T, memberName)) == function)) {
					// pragma(msg, "Function: " ~ memberName);

					foreach (PT; __traits(getOverloads, T, memberName)) {
						// pragma(msg, "overload function: " ~ memberName);

						enum memberParams = ParameterIdentifierTuple!PT;
						static if (Args.length == memberParams.length) {
							alias memberParamTypes = Parameters!PT;

							static if (__traits(isSame, memberParamTypes, Args)) {
								__traits(getMember, p, memberName)(value);
							} else {
								enum string str = generateSetter!(PT, p.stringof, memberName,
											value.stringof, Args)();
								// pragma(msg, "== code == " ~ str);

								static if (str.length > 0) {
									mixin(str);
								}
							}
						}
					}
				}
			}
		} else {
			// writeln("skipping: ", memberName);
			// pragma(msg, "skipping: " ~ memberName);

		}
	}

	if(!isSuccess) {
		writefln("Can't find member %s in %s", currentMember, typeid(T));
	}
	// assert(false, T.stringof ~ " has no member " ~ name);
}

private string generateSetter(alias T, string objectName, string memeberName,
		string parameterName, Args...)() {
	string str;
	import std.conv;

	enum memberParams = ParameterIdentifierTuple!T;

	str ~= objectName ~ "." ~ memeberName ~ "(";
	alias memberParamTypes = Parameters!T;

	bool isFirst = true;

	static foreach (int i; 0 .. memberParams.length) {
		if (isFirst)
			isFirst = false;
		else {
			str ~= ", ";
		}

		static if (is(memberParamTypes[i] == Args[i])) {
			str ~= parameterName ~ "[" ~ to!string(i) ~ "]";
		} else {
			str ~= "to!(" ~ memberParamTypes[i].stringof ~ ")(" ~ parameterName ~ "[" ~ to!string(
					i) ~ "])";
		}

	}
	str ~= ");";
	return str;
}

unittest {

struct Foo {
	string name = "dog";
	int bar = 42;
	int baz = 31337;

	void setBar(int value) {
		// writefln("setting: value=%d", value);
		bar = value;
	}

	void setBar(string name, int value) {
		// writefln("setting: name=%s, value=%d", name, value);
        this.name = name;
        this.bar = value;
	}

	int getBar() {
		return bar;
	}
}

	Foo foo;

	setProperty(foo, "bar", 12);
	assert(foo.bar == 12);
	setProperty(foo, "bar", "112");
	assert(foo.bar == 112);

	setProperty(foo, "bar", "age", 16);
	assert(foo.name == "age");
	assert(foo.bar == 16);
	setProperty(foo, "bar", "age", "36");
	assert(foo.name == "age");
	assert(foo.bar == 36);
}