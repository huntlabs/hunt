module test.SerializationTest;


import hunt.logging.ConsoleLogger;
import hunt.util.Common;
import hunt.util.Serialize;
import hunt.util.ObjectUtils;

import std.conv;
import std.format;
import std.json;

class SerializationTest {

    // void testAssociativeArray() {

    //     int[string] data;
    //     data["total"] = 4;
    //     data["number"] = 2;

    //     byte[] bs = serialize(data);
    //     tracef("length: %d, data: %(%02X %)", bs.length, bs);

    //     auto d = unserialize!(int[string])(bs);
    //     assert(d == data, d.to!string());
    // }


    // void testSerializable() {
    //     B b = new B();
    //     b.id = 2;
    //     b.name = "Bob";
    //     b.age = 20;
    //     b.height = 1.8f;

    //     ubyte[] bytes = b.serialize();
    //     version(HUNT_DEBUG) tracef("length: %d, data: %(%02X %)", bytes.length, bytes);

    //     B b1 = unserialize!B(cast(byte[])bytes);
    //     version(HUNT_DEBUG) trace(b1.toString());
    //     assert(b1 !is b);
    //     assert(b1 == b);

    //     A a = unserialize!A(cast(byte[])bytes);
    //     version(HUNT_DEBUG) trace(a.toString());

    //     assert(a.name == b.name && a.id == b.id);

    //     a = new A();
    //     a.name = "Bob";
        
    //     bytes = a.serialize();
    //     tracef("length: %d, data: %(%02X %)", bytes.length, bytes);

    //     trace(b.toString());
    // }

    // void testClassInherit() {
    //     B b = new B();
    //     b.name = "Bob";
    //     b.age = 20;
    //     b.height = 1.8f;

    //     byte[] bytes = serialize(b);

    //     tracef("length: %d, data: %(%02X %)", bytes.length, bytes);

    //     B b1 = unserialize!B(bytes);
    //     // trace(getsize(b));
    //     // trace(getsize(a));
    //     trace(b.toString());
    //     trace(b1.toString());
    //     assert(b == b1);
    // }

    // void testClass1() {
    //     School school = new School();

    //     User user1 = new User();
    //     user1.age = 30;
    //     user1.name = "Bob";
    //     user1.school = school;

    //     User user2 = new User();
    //     user2.age = 31;
    //     user2.name = "Alice";
    //     user2.school = school;

    //     school.name = "Putao";
    //     school.users ~= user1;
    //     school.users ~= user2;

    //     test1(user1);
    //     test1(user2);
    // }
}

void test1(T)(T t) {
    assert(unserialize!T(serialize(t)) == t);
    assert(serialize(t).length == getsize(t));

    assert(toObject!T(toJson(t)) == t);
}


class A : Serializable {
    private int id;
    string name;

    override string toString() {
        return format("id=%d, name=%s", id, name);
    }

    mixin SerializationMember!(typeof(this));

    // abstract void test();
}


class B1 : A {

    // It's not necessary
    // mixin SerializationMember!(typeof(this));
}

class B : B1 {
    int age;
    float height;

    override bool opEquals(Object o) {
        if(o is null)
            return false;
        B b = cast(B) o;
        if(b is null) 
            return false;
        
        return b.name == this.name && b.age == this.age && b.id == this.id && b.height == this.height;
    }

    override string toString() {
        return format("name=%s, age=%d, height=%0.1f", name, age, height);
    }

    mixin SerializationMember!(typeof(this));

    // override void test() {

    // }
}



class C {
    int age;
    string name;
    T3 t3;
    override bool opEquals(Object c) {
        auto c1 = cast(C) c;
        return age == c1.age && name == c1.name && t3 == c1.t3;
    }

    C clone() {
        auto c = new C();
        c.age = age;
        c.name = name;
        c.t3 = t3;
        return c;
    }
}

class C2 {
    C[] c;
    C c1;
    T1 t1;
    override bool opEquals(Object c) {
        auto c2 = cast(C2) c;
        return this.c == c2.c && c1 == c2.c1 && t1 == c2.t1;
    }
}

//ref test
class School {
    string name;
    User[] users;
    override bool opEquals(Object c) {
        auto school = cast(School) c;
        return school.name == this.name;
    }
}

class User {
    int age;
    string name;
    School school;
    override bool opEquals(Object c) {
        auto user = cast(User) c;
        return user.age == this.age && user.name == this.name && user.school == this.school;
    }
}


struct J {
    string data;
    JSONValue val;

}

enum MONTH {
    M1,
    M2
}

enum WEEK : int {
    K1 = 1,
    K2 = 2
}

enum DAY : string {
    D1 = "one",
    D2 = "two"
}

class Date1 {
    MONTH month;
    WEEK week;
    DAY day;
    override bool opEquals(Object c) {
        auto date = cast(Date1) c;
        return date.month == this.month && date.week == this.week && date.day == this.day;
    }

}

struct T1 {
    bool b;
    byte ib;
    ubyte ub;
    short ish;
    ushort ush;
    int ii;
    uint ui;
    long il;
    ulong ul;
    string s;
    uint[10] sa;
    long[] sb;
}

struct T2 {
    string n;
    T1[] t;
}

struct T3 {
    T1 t1;
    T2 t2;
    string[] name;
}
