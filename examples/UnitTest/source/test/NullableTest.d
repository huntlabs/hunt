module test.NullableTest;

import hunt.lang.Long;
import hunt.lang.Nullable;

import std.conv;
import std.stdio;

class NullableTest {

    void testValueType() {
        Nullable!long l12 = Long.valueOf(12);
        Nullable!long l20 = new Long(20);

        // assert(l12 == 12);

        // Long l20 = new Long(20);

        // assert(l12 > 10);
        // assert(10 < l12 );
        // assert(l12 < 20 );
        // assert(l12 < l20 );
        // assert(l20 != l12);
        assert(l20 == 20 && 12 == l12 );

        l12 = 30;
        assert(l12 == 30);
        long v = cast(long)l12;
        assert(v == 30);
        int intValue = cast(int)l12;
        assert(intValue == 30);
    }

    void testString() {
        enum string TestValue = "string object";
        Nullable!string object = new Nullable!string(TestValue);
        assert(object.value == TestValue);
        string str = cast(string)object;
        assert(str == TestValue);
    }

    void testStruct() {
        struct Student {
            string name;
            int age;

            string toString() {
                return name ~ " " ~age.to!string();
            }

            string getName() {
                return name;
            }
        }

        Nullable!Student sa = new Nullable!Student(Student("AAA", 20));
        assert("AAA 20" == sa.toString());
        assert(sa.getName() == "AAA");

        Student s = cast(Student)sa;
        assert(s.getName() == "AAA");
    }


    void testClass() {
        class Student {
            string name;
            int age;

            this(string name, int age) {
                this.name = name;
                this.age = age;
            }

            override string toString() {
                return name ~ " " ~age.to!string();
            }

            string getName() {
                return name;
            }
        }

        Nullable!Student sa = new Nullable!Student(new Student("AAA", 20));
        assert("AAA 20" == sa.toString());
        assert(sa.getName() == "AAA");

        Student s = cast(Student)sa;
        assert(s.getName() == "AAA");
    }
}