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

import std.algorithm : canFind;
import std.array;
import std.conv : to;
import std.meta;
import std.typecons;
import std.string;
import std.traits;

import hunt.logging.ConsoleLogger;

enum string[] FixedObjectMembers = ["toString", "opCmp", "opEquals", "Monitor", "factory"];

mixin template GetConstantValues(T) if (is(T == struct) || is(T == class)) {
	static T[] values() {
		T[] r;
		enum s = __getValues!(r.stringof, T)();
		// pragma(msg, s);
		mixin(s);
		return r;
	}

	private static string __getValues(string name, T)() {
		string str;

		foreach (string memberName; __traits(derivedMembers, T)) {
			// enum member = __traits(getMember, T, memberName);
			alias memberType = typeof(__traits(getMember, T, memberName));
			static if (is(memberType : T)) {
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
		alias Pointer = T*;
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

template isRefType(T) {
	enum isRefType = /*isPointer!T ||*/ isDelegate!T || isDynamicArray!T
			|| isAssociativeArray!T || is(T == class) || is(T == interface);
}

template isPublic(alias T) {
	enum protection = __traits(getProtection, T);
	enum isPublic = (protection == "public");
}


mixin template CloneMemberTemplate(T, alias cloneHandler = null) 	{
	import std.traits;
	alias baseClasses = BaseClassesTuple!T;

	static if(baseClasses.length == 1 && is(baseClasses[0] == Object)) {
		T clone() {
			T copy = cast(T)typeid(this).create();
			__copyFieldsTo(copy);
			return copy;
		}
	} else {
		override T clone() {
			T copy = cast(T)super.clone();
			__copyFieldsTo(copy);
			return copy;
		}
	}

	private void __copyFieldsTo(T copy) {
		assert(copy !is null);	

		static foreach (string fieldName; FieldNameTuple!T) {
			__traits(getMember, copy, fieldName) = __traits(getMember, this, fieldName);
			version(HUNT_DEBUG_MORE) {
				tracef("cloning field: name=%s, value=%s", fieldName, __traits(getMember, this, fieldName));
			}
		}

		static if(cloneHandler !is null) {
			cloneHandler(this, copy);
		}
	}
}



/**
*/
string generateObjectClone(T, string fromName, string toName)()
		if (is(T == struct) || is(T == union) || is(T == class)) {

	string s;
	static foreach (string fieldName; FieldNameTuple!T) {
		// pragma(msg, fieldName);
		s ~= toName ~ "." ~ fieldName ~ " = " ~ fromName ~ "." ~ fieldName ~ ";\n";
	}

	return s;
}

/**
* Params
*	name = xXX will map to T's memeber function void setXXX()
*/
bool setProperty(T, Args...)(ref T p, string name, Args value) {
	enum string MethodPrefix = "set";
	// pragma(msg, "Args: " ~ Args.stringof);

	if (name.empty) {
		throw new Exception("The name can't be empty");
	}

	enum PrefixLength = MethodPrefix.length;
	string currentMember = MethodPrefix ~ toUpper(name[0 .. 1]) ~ name[1 .. $];
	bool isSuccess = false;

	foreach (memberName; __traits(allMembers, T)) {
		// pragma(msg, "Member: " ~ memberName);

		static if (is(T == class) && FixedObjectMembers.canFind(memberName)) {
			// pragma(msg, "skipping fixed Object member: " ~ memberName);
		} else static if (memberName.length > PrefixLength
				&& memberName[0 .. PrefixLength] == MethodPrefix) {
			// tracef("checking: %s", memberName);

			if (!isSuccess && currentMember == memberName) {
				static if (is(typeof(__traits(getMember, T, memberName)) == function)) {
					// pragma(msg, "Function: " ~ memberName);

					foreach (PT; __traits(getOverloads, T, memberName)) {
						// pragma(msg, "overload function: " ~ memberName);

						enum memberParams = ParameterIdentifierTuple!PT;
						static if (Args.length == memberParams.length) {
							alias memberParamTypes = Parameters!PT;
							isSuccess = true;

							// tracef("try to execute method %s, with value: %s", memberName, value.stringof);
							// foreach (i, s; value) {
							// 	tracef("value[%d] type: %s, actual value: %s", i, typeid(s), s);
							// }

							static if (__traits(isSame, memberParamTypes, Args)) {
								__traits(getMember, p, memberName)(value);
							} else {
								enum string str = generateSetter!(PT,
											p.stringof ~ "." ~ memberName, value.stringof, Args)();
								// pragma(msg, "== code == " ~ str);

								static if (str.length > 0) {
									mixin(str);
								}
							}
						}
					}

					if (!isSuccess) {
						warningf("Mismatch member %s in %s for parameter size %d",
								currentMember, typeid(T), Args.length);
					} else {
						return true;
					}
				}
			}
		} else {
			// pragma(msg, "skipping: " ~ memberName);
		}
	}

	if (!isSuccess) {
		warningf("Failed to set member %s in %s", currentMember, typeid(T));
		// assert(false, T.stringof ~ " has no member " ~ currentMember);
	}
	return isSuccess;
}

/**
*/
private string generateSetter(alias T, string callerName, string parameterName, argumentTypes...)() {
	string str;
	import std.conv;

	enum memberParams = ParameterIdentifierTuple!T;
	str ~= callerName ~ "(";
	alias memberParamTypes = Parameters!T;

	bool isFirst = true;

	static foreach (int i; 0 .. memberParams.length) {
		if (isFirst)
			isFirst = false;
		else
			str ~= ", ";

		static if (is(memberParamTypes[i] == argumentTypes[i])) {
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
			bar = value;
		}

		void setBar(string name, int value) {
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

	foo.setProperty("bar", "age", 16);
	assert(foo.name == "age");
	assert(foo.bar == 16);
	foo.setProperty("bar", "age", "36");
	assert(foo.name == "age");
	assert(foo.bar == 36);
}
