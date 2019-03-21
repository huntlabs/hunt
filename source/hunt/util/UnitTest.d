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

module hunt.util.UnitTest;

import hunt.util.Traits;

void testUnits(T)() {
	enum v = generateUnitTests!T;
	// pragma(msg, v);
	mixin(v);
}

string generateUnitTests(T)() {
	import std.string;
	import std.algorithm;
	import std.traits;

	enum fullTypeName = fullyQualifiedName!(T);
	enum memberModuleName = moduleName!(T);

	string str;
	str ~= `import std.stdio;
writeln("=================================");
writeln("Module: ` ~ fullTypeName ~ `     ");
writeln("=================================");

`;
	str ~= "import " ~ memberModuleName ~ ";\n";
	str ~= "auto t = new " ~ T.stringof ~ "();\n";

	foreach (memberName; __traits(allMembers, T)) {
		// pragma(msg, "member: " ~ memberName);
		static if (is(T == class) && FixedObjectMembers.canFind(memberName)) {
			// pragma(msg, "skipping fixed Object member: " ~ memberName);
		} else {
			enum memberProtection = __traits(getProtection, __traits(getMember, T, memberName));
			static if (memberProtection == "private"
					|| memberProtection == "protected" 
					|| memberProtection == "export") {
				// version (HUNT_DEBUG) pragma(msg, "skip private member: " ~ memberName);
			} else {
				import std.meta : Alias;
				alias currentMember = Alias!(__traits(getMember, T, memberName));
				static if (memberName.startsWith("test") 
						|| memberName.endsWith("Test")
						|| hasUDA!(currentMember, Test)) {
					alias memberType = typeof(currentMember);
					static if (is(memberType == function)) {
						str ~= `writeln("\n========> testing: ` ~ memberName ~ "\");\n";
						str ~= "t." ~ memberName ~ "();\n";
					}
				}
			}
		}
	}
	return str;
}

/**
*/
struct Test {
	TypeInfo expected;
}
