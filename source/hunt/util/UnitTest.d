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

	string[] methodsBefore;
	string[] methodsAfter;

	string str;
	str ~= `import std.stdio; import hunt.logging.ConsoleLogger;
writeln("=================================");
writeln("Module: ` ~ fullTypeName ~ `     ");
writeln("=================================");

`;
	str ~= "import " ~ memberModuleName ~ ";\n";
	str ~= T.stringof ~ " t;\n";

	// 
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
				static if (hasUDA!(currentMember, Before)) {
					alias memberType = typeof(currentMember);
					static if (is(memberType == function)) {
						methodsBefore ~= memberName;
					}
				}

				static if (hasUDA!(currentMember, After)) {
					alias memberType = typeof(currentMember);
					static if (is(memberType == function)) {
						methodsAfter ~= memberName;
					}
				}
			}
		}
	}

	// 
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
				alias testUDAs = getUDAs!(currentMember, Test);// hasUDA!(currentMember, Test);
				static if (memberName.startsWith("test") 
						|| memberName.endsWith("Test")
						|| testUDAs.length>0) {
					alias memberType = typeof(currentMember);
					static if (is(memberType == function)) {
						str ~= `writeln("\n========> testing: ` ~ memberName ~ "\");\n";

						// Every @Test method will be test alone. 
						str ~= "t = new " ~ T.stringof ~ "();\n";

						// running methods annotated with BEFORE
						foreach(string s; methodsBefore) {
							str ~= "t." ~ s ~ "();\n";
						}
						
						// execute a test 
						static if(testUDAs.length > 0) {
							alias expectedType = typeof(testUDAs[0].expected);
							static if(is(expectedType : Throwable)) {
								str ~= "try { t." ~ memberName ~ "(); } catch(" ~ fullyQualifiedName!expectedType ~ 
									" ex) { version(HUNT_DEBUG) { warning(ex.msg); } }\n";
							} else {
								str ~= "t." ~ memberName ~ "();\n"; 
							}
						} else {
							str ~= "t." ~ memberName ~ "();\n"; 
						}

						// running methods annotated with BEFORE
						foreach(string s; methodsAfter) {
							str ~= "t." ~ s ~ "();\n";
						}
					}
				}
			}
		}
	}
	return str;
}

/**
*/
struct Test(T = Object) {
	T expected; 
}

/**
*/
interface Before {
}

/**
*/
interface After {
}