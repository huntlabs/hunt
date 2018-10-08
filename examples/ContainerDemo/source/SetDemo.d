module SetDemo;

import std.stdio;

import hunt.util.UnitTest;
import hunt.container.Set;
import hunt.container.TreeSet;
import std.conv;

class SetDemo
{
    void testTreeSetBasic()
    {
        TreeSet!(string) ts = new TreeSet!(string)();
        ts.add("one");
        ts.add("two");
        ts.add("three");
        writeln("Elements: " ~ ts.toString());

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

    void testSubset()
    {
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
