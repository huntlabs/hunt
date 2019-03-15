module SetDemo;

import std.stdio;

import common;
import hunt.util.UnitTest;
import hunt.collection.Set;
import hunt.collection.SortedSet;
import hunt.collection.TreeSet;

import hunt.Exceptions;
import hunt.logging.ConsoleLogger;
import hunt.util.UnitTest;
import hunt.util.Common;
import hunt.Assert;

import std.conv;
import std.range;

alias assertTrue = Assert.assertTrue;
alias assertFalse = Assert.assertFalse;
alias assertThat = Assert.assertThat;
alias assertEquals = Assert.assertEquals;
alias assertNotNull = Assert.assertNotNull;
alias assertNull = Assert.assertNull;

class SetDemo {

    enum one = 1;
    enum two = 2;
    enum three = 3;
    enum four = 4;
    enum five = 5;

    /**
     * Returns a new set of first 5 ints.
     */
    private static TreeSet!int set5() {
        TreeSet!int q = new TreeSet!int();
        assertTrue(q.isEmpty());
        q.add(1);
        q.add(3);
        q.add(4);
        q.add(2);
        q.add(5);
        assertEquals(5, q.size());
        return q;
    }

    void testTailSetContents() {
        TreeSet!int set = set5();
        SortedSet!int sm = set.tailSet(two);
        assertFalse(sm.contains(1));
        assertTrue(sm.contains(2));
        assertTrue(sm.contains(3));
        assertTrue(sm.contains(4));
        assertTrue(sm.contains(5));

        // trace(sm.toString());

        // InputRange!int i = sm.iterator();
        // int k;
        // k = (i.front());
        // assertEquals(two, k);
        // i.popFront();
        // k = (i.front());
        // assertEquals(three, k);
        // i.popFront();
        // k = (i.front());
        // assertEquals(four, k);
        // i.popFront();
        // k = (i.front());
        // assertEquals(five, k);
        // i.popFront();
        // assertTrue(i.empty());

        SortedSet!int ssm = sm.tailSet(four);
        // trace(ssm.toString());
        assertEquals(four, ssm.first());
        assertEquals(five, ssm.last());
        trace("ssm: ", ssm.toString());
        trace("sm: ", sm.toString());
        trace("set: ", set.toString());
        assertTrue(ssm.remove(four));
        assertEquals(1, ssm.size());
        assertEquals(3, sm.size());
        assertEquals(4, set.size());

        trace("ssm: ", ssm.toString());
        trace("sm: ", sm.toString());
        trace("set: ", set.toString());
    }

    void testInt() {
        TreeSet!(int) ts = new TreeSet!(int)();
        ts.add(3);
        ts.add(10);
        ts.add(2);
        writeln("Elements: " ~ ts.toString());
        writeln("First element: " ~ to!string(ts.first()));
    }

    void testTreeSetBasic() {
        TreeSet!(string) ts = new TreeSet!(string)();
        ts.add("one");
        ts.add("two");
        ts.add("three");

        assert(ts.size() == 3);
        writeln("Elements: " ~ ts.toString());
        writeln("First element: " ~ ts.first());

        //check is set empty?
        writeln("Is set empty: " ~ ts.isEmpty().to!string());

        string[] values = ts.toArray();
        writeln(values);

        writeln("Size of the set: " ~ ts.size().to!string());
        //remove one string
        ts.remove("two");
        writeln("Elements: " ~ ts.toString());
        assert(ts.size() == 2);

        //delete all elements from set
        ts.clear();
        writeln("Is set empty: " ~ ts.isEmpty().to!string());
        writeln("Elements: " ~ ts.toString());
        values = ts.toArray();
        assert(values == []);
        assert(ts.size() == 0);
    }

    void testTreeSetWithClass() {

        TreeSet!Person treeSet = new TreeSet!Person();
        treeSet.add(new Person("albert", 8));
        treeSet.add(new Person("bob", 5));
        treeSet.add(new Person("bob", 13));

        foreach (Person person; treeSet) {
            writeln(person.toString());
        }

        assert(treeSet.size() == 3, treeSet.size().to!string());
        Person p = treeSet.first();
        treeSet.remove(p);
        assert(treeSet.size() == 2);
    }

    void testTreeSetWithComparator() {
        
        ComparatorByPrice com = new ComparatorByPrice();

        TreeSet!(Price) ts = new TreeSet!(Price)(com);
        ts.add(new Price("Banana", 20));
        ts.add(new Price("Apple", 40));
        ts.add(new Price("Orange", 30));
        assert(ts.size() == 3, ts.size().to!string());
        foreach (Price p; ts) {
            writeln(p.toString());
        }

        Price p = ts.first();
        ts.remove(p);
        assert(ts.size == 2);
    }

    void testSubset() {
        // http://java2novice.com/java-collections-and-util/treeset/subset/
        TreeSet!string ts = new TreeSet!string();
        ts.add("RED");
        ts.add("ORANGE");
        ts.add("BLUE");
        ts.add("GREEN");
        ts.add("WHITE");
        ts.add("BROWN");
        ts.add("YELLOW");
        ts.add("BLACK");
        writeln(ts);
        Set!string subSet = ts.subSet("GREEN", "WHITE");
        writeln("sub set: " ~ subSet.toString());
        assert(subSet.toString() == "[GREEN, ORANGE, RED]", subSet.toString());

        subSet = ts.subSet("GREEN", true, "WHITE", true);
        writeln("sub set: " ~ subSet.toString());
        assert(subSet.toString() == "[GREEN, ORANGE, RED, WHITE]", subSet.toString());

        subSet = ts.subSet("GREEN", false, "WHITE", true);
        writeln("sub set: " ~ subSet.toString());
        assert(subSet.toString() == "[ORANGE, RED, WHITE]", subSet.toString());
    }

}

import std.format;
import hunt.util.Comparator;

class Person : Comparable!Person {

    string name;
    int age;

    this(string n, int a) {
        name = n;
        age = a;
    }

    override string toString() {
        return format("Name is %s, Age is %d", name, age);
    }

    int opCmp(Person o) {
        int nameComp = compare(this.name, o.name);
        return (nameComp != 0 ? nameComp : compare(this.age, o.age));
    }

    alias opCmp = Object.opCmp;

}

class ComparatorByPrice : Comparator!Price{

     int compare(Price v1, Price v2) nothrow {
        return .compare(v1.getPrice, v2.getPrice);
    }

}
