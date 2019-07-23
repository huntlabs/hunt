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

import std.array;
import std.meta;
import std.typecons;
import std.string;
import std.traits;



template isInheritClass(T, Base) {
	enum FFilter(U) = is(U == Base);
	enum isInheritClass = (Filter!(FFilter, BaseTypeTuple!T).length > 0);
}

template isByteType(T) {
	enum bool isByteType = is(T == byte) || is(T == ubyte) || is(T == char);
}

template isCharByte(T) {
	enum bool isCharByte = is(Unqual!T == byte) || is(Unqual!T == ubyte) || is(Unqual!T == char);
}

template isByteArray(T) {
	static if(is(T : U[], U) && isByteType!(Unqual!U)) {
		enum bool isByteArray = true;
	} else {
		enum bool isByteArray = false;
	}
}


template isRefType(T) {
	enum isRefType = /*isPointer!T ||*/ isDelegate!T || isDynamicArray!T
			|| isAssociativeArray!T || is(T == class) || is(T == interface);
}

template isPublic(alias T) {
	enum isPublic = (__traits(getProtection, T) == "public");
}
