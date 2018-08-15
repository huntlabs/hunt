module SetDemo;

import std.stdio;

import hunt.util.UnitTest;
import hunt.container.TreeSet;
import std.conv;

class SetDemo
{
    void testTreeSet()
    {
        TreeSet!(string) ts = new TreeSet!(string)();
        ts.add("one");
        ts.add("two");
        ts.add("three");
        writeln("Elements: " ~ ts.toString());
        //check is set empty?
        writeln("Is set empty: " ~ ts.isEmpty().to!string());
        //delete all elements from set
        ts.clear();
        writeln("Is set empty: " ~ ts.isEmpty().to!string());
        ts.add("one");
        ts.add("two");
        ts.add("three");
        writeln("Size of the set: " ~ ts.size().to!string());
        //remove one string
        ts.remove("two");
        writeln("Elements: " ~ ts.toString());
    }
}
