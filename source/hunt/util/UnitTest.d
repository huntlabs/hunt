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

import hunt.util.ObjectUtils;
import core.time;

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
	// 	pragma(msg, "member: " ~ memberName);
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

				static if (isFunction!(currentMember)) {
					alias testWithUDAs = getUDAs!(currentMember, TestWith);// hasUDA!(currentMember, Test);
					static if(testWithUDAs.length >0) {
						str ~= `writeln("\n========> testing: ` ~ memberName ~ "\");\n";

						// Every @Test method will be test alone. 
						str ~= "t = new " ~ T.stringof ~ "();\n";

						// running methods annotated with BEFORE
						foreach(string s; methodsBefore) {
							str ~= "t." ~ s ~ "();\n";
						}
						
						// execute a test 
						alias expectedType = typeof(testWithUDAs[0].expected);
						static if(is(expectedType : Throwable)) {
							str ~= "try { t." ~ memberName ~ "(); } catch(" ~ fullyQualifiedName!expectedType ~ 
								" ex) { version(HUNT_DEBUG) { warning(ex.msg); } }\n";
						} else {
							str ~= "t." ~ memberName ~ "();\n"; 
						}

						// running methods annotated with BEFORE
						foreach(string s; methodsAfter) {
							str ~= "t." ~ s ~ "();\n";
						}
					} else {
						static if (memberName.startsWith("test") || memberName.endsWith("Test")
							|| hasUDA!(currentMember, Test)) {
							str ~= `writeln("\n========> testing: ` ~ memberName ~ "\");\n";

							// Every @Test method will be test alone. 
							str ~= "t = new " ~ T.stringof ~ "();\n";

							// running methods annotated with BEFORE
							foreach(string s; methodsBefore) {
								str ~= "t." ~ s ~ "();\n";
							}
							
							// execute a test 
							str ~= "t." ~ memberName ~ "();\n"; 

							// running methods annotated with BEFORE
							foreach(string s; methodsAfter) {
								str ~= "t." ~ s ~ "();\n";
							}
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
struct TestWith(T = Object) {
	T expected; 
}


/**
 * The <code>Test</code> annotation tells JUnit that the <code>public void</code> method
 * to which it is attached can be run as a test case. To run the method,
 * JUnit first constructs a fresh instance of the class then invokes the
 * annotated method. Any exceptions thrown by the test will be reported
 * by JUnit as a failure. If no exceptions are thrown, the test is assumed
 * to have succeeded.
 * <p>
 * A simple test looks like this:
 * <pre>
 * public class Example {
 *    <b>&#064;Test</b>
 *    public void method() {
 *       org.junit.Assert.assertTrue( new ArrayList().isEmpty() );
 *    }
 * }
 * </pre>
 * <p>
 * The <code>Test</code> annotation supports two optional parameters.
 * The first, <code>expected</code>, declares that a test method should throw
 * an exception. If it doesn't throw an exception or if it throws a different exception
 * than the one declared, the test fails. For example, the following test succeeds:
 * <pre>
 *    &#064;Test(<b>expected=IndexOutOfBoundsException.class</b>) public void outOfBounds() {
 *       new ArrayList&lt;Object&gt;().get(1);
 *    }
 * </pre>
 * If the exception's message or one of its properties should be verified, the
 * {@link org.junit.rules.ExpectedException ExpectedException} rule can be used. Further
 * information about exception testing can be found at the
 * <a href="https://github.com/junit-team/junit/wiki/Exception-testing">JUnit Wiki</a>.
 * <p>
 * The second optional parameter, <code>timeout</code>, causes a test to fail if it takes
 * longer than a specified amount of clock time (measured in milliseconds). The following test fails:
 * <pre>
 *    &#064;Test(<b>timeout=100</b>) public void infinity() {
 *       while(true);
 *    }
 * </pre>
 * <b>Warning</b>: while <code>timeout</code> is useful to catch and terminate
 * infinite loops, it should <em>not</em> be considered deterministic. The
 * following test may or may not fail depending on how the operating system
 * schedules threads:
 * <pre>
 *    &#064;Test(<b>timeout=100</b>) public void sleep100() {
 *       Thread.sleep(100);
 *    }
 * </pre>
 * <b>THREAD SAFETY WARNING:</b> Test methods with a timeout parameter are run in a thread other than the
 * thread which runs the fixture's @Before and @After methods. This may yield different behavior for
 * code that is not thread safe when compared to the same test method without a timeout parameter.
 * <b>Consider using the {@link org.junit.rules.Timeout} rule instead</b>, which ensures a test method is run on the
 * same thread as the fixture's @Before and @After methods.
 *
 */
struct Test {
	Duration timeout;
}


/**
 * When writing tests, it is common to find that several tests need similar
 * objects created before they can run. Annotating a <code>public void</code> method
 * with <code>&#064;Before</code> causes that method to be run before the {@link org.junit.Test} method.
 * The <code>&#064;Before</code> methods of superclasses will be run before those of the current class,
 * unless they are overridden in the current class. No other ordering is defined.
 * <p>
 * Here is a simple example:
 * <pre>
 * public class Example {
 *    List empty;
 *    &#064;Before public void initialize() {
 *       empty= new ArrayList();
 *    }
 *    &#064;Test public void size() {
 *       ...
 *    }
 *    &#064;Test public void remove() {
 *       ...
 *    }
 * }
 * </pre>
 *
 */
interface Before {
}


/**
 * If you allocate external resources in a {@link org.junit.Before} method you need to release them
 * after the test runs. Annotating a <code>public void</code> method
 * with <code>&#064;After</code> causes that method to be run after the {@link org.junit.Test} method. All <code>&#064;After</code>
 * methods are guaranteed to run even if a {@link org.junit.Before} or {@link org.junit.Test} method throws an
 * exception. The <code>&#064;After</code> methods declared in superclasses will be run after those of the current
 * class, unless they are overridden in the current class.
 * <p>
 * Here is a simple example:
 * <pre>
 * public class Example {
 *    File output;
 *    &#064;Before public void createOutputFile() {
 *          output= new File(...);
 *    }
 *    &#064;Test public void something() {
 *          ...
 *    }
 *    &#064;After public void deleteOutputFile() {
 *          output.delete();
 *    }
 * }
 * </pre>
 *
 */
interface After {
}


/**
 * Sometimes several tests need to share computationally expensive setup
 * (like logging into a database). While this can compromise the independence of
 * tests, sometimes it is a necessary optimization. Annotating a <code>public static void</code> no-arg method
 * with <code>@BeforeClass</code> causes it to be run once before any of
 * the test methods in the class. The <code>@BeforeClass</code> methods of superclasses
 * will be run before those of the current class, unless they are shadowed in the current class.
 * <p>
 * For example:
 * <pre>
 * public class Example {
 *    &#064;BeforeClass public static void onlyOnce() {
 *       ...
 *    }
 *    &#064;Test public void one() {
 *       ...
 *    }
 *    &#064;Test public void two() {
 *       ...
 *    }
 * }
 * </pre>
 *
 */
interface BeforeClass {

}


/**
 * If you allocate expensive external resources in a {@link org.junit.BeforeClass} method you need to release them
 * after all the tests in the class have run. Annotating a <code>public static void</code> method
 * with <code>&#064;AfterClass</code> causes that method to be run after all the tests in the class have been run. All <code>&#064;AfterClass</code>
 * methods are guaranteed to run even if a {@link org.junit.BeforeClass} method throws an
 * exception. The <code>&#064;AfterClass</code> methods declared in superclasses will be run after those of the current
 * class, unless they are shadowed in the current class.
 * <p>
 * Here is a simple example:
 * <pre>
 * public class Example {
 *    private static DatabaseConnection database;
 *    &#064;BeforeClass public static void login() {
 *          database= ...;
 *    }
 *    &#064;Test public void something() {
 *          ...
 *    }
 *    &#064;Test public void somethingElse() {
 *          ...
 *    }
 *    &#064;AfterClass public static void logout() {
 *          database.logout();
 *    }
 * }
 * </pre>
 *
 */
interface AfterClass {

}


/**
 * Sometimes you want to temporarily disable a test or a group of tests. Methods annotated with
 * {@link org.junit.Test} that are also annotated with <code>&#064;Ignore</code> will not be executed as tests.
 * Also, you can annotate a class containing test methods with <code>&#064;Ignore</code> and none of the containing
 * tests will be executed. Native JUnit 4 test runners should report the number of ignored tests along with the
 * number of tests that ran and the number of tests that failed.
 *
 * <p>For example:
 * <pre>
 *    &#064;Ignore &#064;Test public void something() { ...
 * </pre>
 * &#064;Ignore takes an optional default parameter if you want to record why a test is being ignored:
 * <pre>
 *    &#064;Ignore("not ready yet") &#064;Test public void something() { ...
 * </pre>
 * &#064;Ignore can also be applied to the test class:
 * <pre>
 *      &#064;Ignore public class IgnoreMe {
 *          &#064;Test public void test1() { ... }
 *          &#064;Test public void test2() { ... }
 *         }
 * </pre>
 *
 */
struct Ignore {
    /**
     * The optional reason why the test is ignored.
     */	
	string value;
}