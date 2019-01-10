module SetDemo;

import std.stdio;

import hunt.util.UnitTest;
import hunt.collection.Set;
import hunt.collection.SortedSet;
import hunt.collection.TreeSet;
import std.conv;
import std.range;

import hunt.exception;
import hunt.logging.ConsoleLogger;
import hunt.util.UnitTest;
import hunt.Assert;

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

        InputRange!int i = sm.iterator();
        int k;
        k = (i.front());
        assertEquals(two, k);
        i.popFront();
        k = (i.front());
        assertEquals(three, k);
        i.popFront();
        k = (i.front());
        assertEquals(four, k);
        i.popFront();
        k = (i.front());
        assertEquals(five, k);
        i.popFront();
        assertTrue(i.empty());

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

        //delete all elements from set
        ts.clear();
        writeln("Is set empty: " ~ ts.isEmpty().to!string());
        writeln("Elements: " ~ ts.toString());
        values = ts.toArray();
        assert(values == []);
        assert(ts.size() == 0);
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

// class MyStrComp : Comparator<string>{

//     @Override
//     public int compare(string str1, string str2) {
//         return str1.compareTo(str2);
//     }

// }
