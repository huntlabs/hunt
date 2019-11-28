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

module hunt.util.ObjectUtils;

import hunt.Exceptions;
import hunt.logging.ConsoleLogger;
import hunt.util.Common;

import std.algorithm : canFind;
import std.array;
import std.conv : to;
import std.format;
import std.meta;
import std.string;
import std.traits;
import std.typecons;


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


/**
*/
class ObjectUtils {

    private enum int INITIAL_HASH = 7;
	private enum int MULTIPLIER = 31;

	private enum string EMPTY_STRING = "";
	private enum string NULL_STRING = "null";
	private enum string ARRAY_START = "{";
	private enum string ARRAY_END = "}";
	private enum string EMPTY_ARRAY = ARRAY_START ~ ARRAY_END;
	private enum string ARRAY_ELEMENT_SEPARATOR = ", ";
    
    /**
	 * Return a string representation of an object's overall identity.
	 * @param obj the object (may be {@code null})
	 * @return the object's identity as string representation,
	 * or an empty string if the object was {@code null}
	 */
	static string identityToString(Object obj) {
		if (obj is null) {
			return EMPTY_STRING;
		}
		return typeid(obj).name ~ "@" ~ getIdentityHexString(obj);
	}



	/**
	 * Return a hex String form of an object's identity hash code.
	 * @param obj the object
	 * @return the object's identity code in hex notation
	 */
	static string getIdentityHexString(Object obj) {
		return format("%s", cast(void*)obj);
	}


	//---------------------------------------------------------------------
	// Convenience methods for content-based equality/hash-code handling
	//---------------------------------------------------------------------

	/**
	 * Determine if the given objects are equal, returning {@code true} if
	 * both are {@code null} or {@code false} if only one is {@code null}.
	 * <p>Compares arrays with {@code Arrays.equals}, performing an equality
	 * check based on the array elements rather than the array reference.
	 * @param o1 first Object to compare
	 * @param o2 second Object to compare
	 * @return whether the given objects are equal
	 * @see Object#equals(Object)
	 * @see java.util.Arrays#equals
	 */
	static bool nullSafeEquals(Object o1, Object o2) {
		if (o1 is o2) {
			return true;
		}
		if (o1 is null || o2 is null) {
			return false;
		}
		if (o1 == o2) {
			return true;
		}
		// if (o1.getClass().isArray() && o2.getClass().isArray()) {
		// 	return arrayEquals(o1, o2);
		// }
		return false;
	}
}


bool isInstanceOf(T, S)(S obj) if(is(S == class) || is(S == interface)) {
	T t = cast(T)obj;
	return t !is null;
}


mixin template ValuesMemberTempate(T) if (is(T == struct) || is(T == class)) {
    import std.concurrency : initOnce;
    import std.traits;
    
	static T[] values() {
		__gshared T[] inst;
        
        return initOnce!inst({
            T[] r;
            enum s = __getValues!(r.stringof, T)();
            // pragma(msg, s);
            mixin(s);
            return r;
        }());
	}

	private static string __getValues(string name, T)() {
		string str;

		foreach (string memberName; __traits(derivedMembers, typeof(this))) {
			alias memberType = typeof(__traits(getMember, typeof(this), memberName));
			static if (is(memberType : T)) {
				str ~= name ~ " ~= " ~ memberName ~ ";\r\n";
			}
		}

		return str;
	}

	static T[string] namedValues() {
		__gshared T[string] inst;
        
        return initOnce!inst({
            T[string] r;
            enum s = __getNamedValues!(r.stringof, T)();
            // pragma(msg, s);
            mixin(s);
            return r;
        }());
	}


	private static string __getNamedValues(string name, T)() {
		string str;

		foreach (string memberName; __traits(derivedMembers, typeof(this))) {
			alias memberType = typeof(__traits(getMember, typeof(this), memberName));
			static if (is(memberType : T)) {
				str ~= name ~ "[\"" ~ memberName ~ "\"] = " ~ memberName ~ ";\r\n";
			}
		}

		return str;
	}
}


deprecated("Using ValuesMemberTempate instead.")
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

// alias Helper(alias T) = T;

// template Pointer(T) {
// 	static if (is(T == class) || is(T == interface)) {
// 		alias Pointer = T;
// 	} else {
// 		alias Pointer = T*;
// 	}
// }

enum string[] FixedObjectMembers = ["toString", "opCmp", "opEquals", "Monitor", "factory"];


alias TopLevel = Flag!"TopLevel";

static if (CompilerHelper.isGreaterThan(2086)) {
	
/**
*/
mixin template CloneMemberTemplate(T, TopLevel topLevel = TopLevel.no, alias onCloned = null) 	{
	import std.traits;
	version(HUNT_DEBUG) import hunt.logging.ConsoleLogger;
	alias baseClasses = BaseClassesTuple!T;

	static if(baseClasses.length == 1 && is(baseClasses[0] == Object) 
			|| topLevel == TopLevel.yes) {
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
		if(copy is null) {
			version(HUNT_DEBUG) warningf("Can't create an instance for %s", T.stringof);
			throw new Exception("Can't create an instance for " ~ T.stringof);
		}

		// debug(HUNT_DEBUG_MORE) pragma(msg, "========\n clone type: " ~ T.stringof);
		static foreach (string fieldName; FieldNameTuple!T) {
			debug(HUNT_DEBUG_MORE) {
				// pragma(msg, "clone field=" ~ fieldName);
				tracef("cloning: name=%s, value=%s", fieldName, __traits(getMember, this, fieldName));
			}
			__traits(getMember, copy, fieldName) = __traits(getMember, this, fieldName);
		}

		static if(onCloned !is null) {
			onCloned(this, copy);
		}
	}
}


/**
*/
string getAllFieldValues(T, string separator1 = "=", string separator2 = ", ")(T obj) 
	if (is(T == class) || is(T == struct)) {

	Appender!string sb;
	bool isFirst = true;
	alias baseClasses = BaseClassesTuple!T;

	static if(baseClasses.length == 1 && is(baseClasses[0] == Object)) {
	} else {
		string s = getAllFieldValues!(baseClasses[0], separator1, separator2)(obj);
		sb.put(s);
		isFirst = false; 
	}

	static foreach (string fieldName; FieldNameTuple!T) {
		if(isFirst) 
			isFirst = false; 
		else 
			sb.put(separator2);
		sb.put(fieldName);
		sb.put(separator1);
		sb.put(to!string(__traits(getMember, obj, fieldName)));
	}

	return sb.data;
}

/**
*/
U mappingToObject(U, T)(T t) if(is(U == struct)) {
	U u;

	mappingObject(t, u);

	return u;
}

/**
*/
U mappingToObject(U, T)(T t) 
	if(is(T == struct) && is(U == class) && is(typeof(new U()))) {

	U u = new U();
	mappingObject(t, u);
	return u;
}

/**
*/
U mappingToObject(U, T)(T t) 
	if(is(T == class) && is(U == class) && is(typeof(new U()))) {

	U u = new U();
	mappingObject(t, u);
	return u;
}

/**
*/
void mappingObject(T, U)(T src, ref U dst) if(is(U == struct)) {

	// super fields
	static if(is(T == class)) {
	alias baseClasses = BaseClassesTuple!T;
	static if(baseClasses.length >= 1) {
		alias BaseType = baseClasses[0];
		static if(!is(BaseType == Object)) {
			mappingObject!(BaseType, U)(src, dst);
		}
	}
	}

	foreach (targetMemberName; FieldNameTuple!U) {		
		foreach (sourceMemberName; FieldNameTuple!T) {
			static if(targetMemberName == sourceMemberName) {
				debug(HUNT_DEBUG_MORE) {
					tracef("mapping: name=%s, value=%s", targetMemberName, __traits(getMember, src, sourceMemberName));
				}
				__traits(getMember, dst, targetMemberName) = __traits(getMember, src, sourceMemberName);
			}
		}
	}

}

/**
*/
void mappingObject(T, U)(T src, U dst) 
		if((is(T == class) || is(T == struct)) && is(U == class)) {
	foreach (targetMemberName; FieldNameTuple!U) {		
		foreach (sourceMemberName; FieldNameTuple!T) {
			static if(targetMemberName == sourceMemberName) {
				debug(HUNT_DEBUG_MORE) {
					tracef("mapping: name=%s, value=%s", targetMemberName, __traits(getMember, src, sourceMemberName));
				}
				__traits(getMember, dst, targetMemberName) = __traits(getMember, src, sourceMemberName);
			}
		}
	}


	// super fields
	alias baseClasses = BaseClassesTuple!U;
	static if(baseClasses.length >= 1) {
		alias BaseType = baseClasses[0];
		static if(!is(BaseType == Object)) {
			static if(is(T : BaseType)) {
				mappingObject!(BaseType, BaseType)(src, dst);
			} else {
				mappingObject!(T, BaseType)(src, dst);
			}
		}
	}
}

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
