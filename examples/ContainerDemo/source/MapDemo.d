module MapDemo;

import std.stdio;

import hunt.container.LinkedHashMap;
import hunt.container.HashMap;
import hunt.container.Map;
import hunt.container.Iterator;

import std.stdio;
import std.conv;
import std.range;

class MapDemo
{
    void testHashMap()
    {
        // https://stackoverflow.com/questions/4234985/how-to-for-each-the-hashmap
        // HashMap Declaration
        writeln("Testing HashMap...");
        HashMap!(int, string) hmap = new HashMap!(int, string)();

        //Adding elements to LinkedHashMap
        hmap.put(22, "Abey");
        hmap.put(33, "Dawn");
        hmap.put(1, "Sherry");
        hmap.put(2, "Karon");
        hmap.put(100, "Jim");

        foreach (int key, string v; hmap)
        {
            writeln("Key is: " ~ key.to!string ~ " & Value is: " ~ v);
        }

        writeln("\nTesting HashMap foreach...");
        foreach (MapEntry!(int, string) entry; hmap)
        {
            writeln("Key is: " ~ entry.getKey().to!string ~ " & Value is: " ~ entry.getValue());
        }

        writeln("\nTesting HashMap byKey1...");
        // Iterator!int keyIterator  = hmap.byKey();
        // while(keyIterator.hasNext)
        // {
        //         writeln("Key is: " ~ keyIterator.next().to!string());
        // }

        InputRange!int keyIterator = hmap.byKey();
        while (!keyIterator.empty)
        {
            writeln("Key is: " ~ keyIterator.front.to!string());
            keyIterator.popFront();
        }

        writeln("\nTesting HashMap byKey2...");
        foreach (int key; hmap.byKey)
        {
            writeln("Key is: " ~ key.to!string());
        }

        writeln("\nTesting HashMap byKey3...");
        foreach (size_t index, int key; hmap.byKey)
        {
            writefln("Key[%d] is: %d ", index, key);
        }

        writeln("\nTesting HashMap byValue1...");
        InputRange!string valueIterator = hmap.byValue();
        while (!valueIterator.empty)
        {
            writeln("value is: " ~ valueIterator.front.to!string());
            valueIterator.popFront();
        }

        writeln("\nTesting HashMap byValue2...");
        foreach (string value; hmap.byValue)
        {
            writeln("value is: " ~ value);
        }

        writeln("\nTesting HashMap byValue3...");
        foreach (size_t index, string value; hmap.byValue)
        {
            writefln("value[%d] is: %s ", index, value);
        }

    }

    void testLinkedHashMap()
    {
        //
        writeln("\n\nTesting LinkedHashMap...");
        LinkedHashMap!(int, string) lhmap = new LinkedHashMap!(int, string)();

        //Adding elements to LinkedHashMap
        lhmap.put(22, "Abey");
        lhmap.put(33, "Dawn");
        lhmap.put(1, "Sherry");
        lhmap.put(2, "Karon");
        lhmap.put(100, "Jim");

        assert(lhmap[1] == "Sherry");

        foreach (int key, string v; lhmap)
        {
            writeln("Key is: " ~ key.to!string ~ " & Value is: " ~ v);
        }

        writeln("\nTesting LinkedHashMap byValue3...");
        foreach (size_t index, string value; lhmap.byValue)
        {
            writefln("value[%d] is: %s ", index, value);
        }
    }
}
