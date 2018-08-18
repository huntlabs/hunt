module HashMapDemo;

import common;

import hunt.container.HashMap;
import hunt.container.Map;
import hunt.container.Iterator;

import std.stdio;
import std.conv;
import std.range;


// http://www.java2novice.com/java-collections-and-util/hashmap/
class HashMapDemo
{
    void testBasicOperations()
    {
        HashMap!(string, string) hm = new HashMap!(string, string)();
        //add key-value pair to hashmap
        hm.put("first", "FIRST INSERTED");
        hm.put("second", "SECOND INSERTED");
        hm.put("third","THIRD INSERTED");
        writeln(hm);
        assert(hm.size() == 3);
        //getting value for the given key from hashmap
        writeln("Value of second: " ~ hm.get("second"));
        writeln("Is HashMap empty? " ~ hm.isEmpty());

        hm.remove("third");
        writeln();
        writeln(hm);
        writeln("Size of the HashMap: " ~ hm.size().to!string());
        assert(hm.size() == 2);

        writeln(hm);
		foreach(string key ; hm.byKey){
			writeln("Value of " ~ key ~ " is: " ~ hm.get(key));
		}

        if(hm.containsKey("first")){
			writeln("The hashmap contains key first");
		} else {
			writeln("The hashmap does not contains key first");
		}
		if(hm.containsKey("fifth")){
			writeln("The hashmap contains key fifth");
		} else {
			writeln("The hashmap does not contains key fifth");
		}

        writeln(hm);
		if(hm.containsValue("SECOND INSERTED")){
			writeln("The hashmap contains value SECOND INSERTED");
		} else {
			writeln("The hashmap does not contains value SECOND INSERTED");
		}
		if(hm.containsValue("first")){
			writeln("The hashmap contains value first");
		} else {
			writeln("The hashmap does not contains value first");
		}
    }

    void testObjectKey()
    {
        HashMap!(Price, string) hm = new HashMap!(Price, string)();
        hm.put(new Price("Banana", 20), "Yellow Banana");
        hm.put(new Price("Apple", 40), "Red Apple");
        hm.put(new Price("Orange", 30), "Juicy Orange");
        printMap(hm);


        assert(hm.size() == 3);
        Price key = new Price("Banana", 20);
        writeln("\nAdding duplicate key...");
        hm.put(key, "Grape");
        
        assert(hm.size() == 3);
        writeln("After adding dulicate key:");
        printMap(hm);

        writeln("Does key available? " ~ hm.containsKey(key).to!string());

		writeln("\nDeleting key...");
		hm.remove(key);
		writeln("After deleting key:");
        writeln("Does key available? " ~ hm.containsKey(key).to!string());
		printMap(hm);
    }

    
    void printMap(HashMap!(Price, string) map)
    {
        foreach (Price p; map.byKey)
        {
            writeln(p.toString() ~ " ==> " ~ map.get(p));
        }
    }
}