module HashMapDemo;

import common;

import hunt.collection.HashMap;
import hunt.collection.Map;
import hunt.collection.Iterator;

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

    
    void testHashMapForeach() {
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

        writeln(hmap.toString());

        writeln("\nTesting HashMap foreach1...");
        foreach (int key, string v; hmap) {
            writeln("Key is: " ~ key.to!string ~ " & Value is: " ~ v);
        }

        writeln("\nTesting HashMap foreach2...");
        foreach (MapEntry!(int, string) entry; hmap) {
            writeln("Key is: " ~ entry.getKey().to!string ~ " & Value is: " ~ entry.getValue());
        }

        writeln("\nTesting HashMap byKey1...");
        // Iterator!int keyIterator  = hmap.byKey();
        // while(keyIterator.hasNext)
        // {
        //         writeln("Key is: " ~ keyIterator.next().to!string());
        // }

        InputRange!int keyIterator = hmap.byKey();
        while (!keyIterator.empty) {
            writeln("Key is: " ~ keyIterator.front.to!string());
            keyIterator.popFront();
        }

        writeln("\nTesting HashMap byKey2...");
        foreach (int key; hmap.byKey) {
            writeln("Key is: " ~ key.to!string());
        }

        writeln("\nTesting HashMap byKey3...");
        foreach (size_t index, int key; hmap.byKey) {
            writefln("Key[%d] is: %d ", index, key);
        }

        writeln("\nTesting HashMap byValue1...");
        InputRange!string valueIterator = hmap.byValue();
        while (!valueIterator.empty) {
            writeln("value is: " ~ valueIterator.front.to!string());
            valueIterator.popFront();
        }

        writeln("\nTesting HashMap byValue2...");
        foreach (string value; hmap.byValue) {
            writeln("value is: " ~ value);
        }

        writeln("\nTesting HashMap byValue3...");
        foreach (size_t index, string value; hmap.byValue) {
            writefln("value[%d] is: %s ", index, value);
        }

    }

    void testHashMapRemove() {
        HashMap!(int, string) hmap = new HashMap!(int, string)();

        //Adding elements to LinkedHashMap
        hmap.put(22, "Abey");
        hmap.put(33, "Dawn");
        hmap.put(1, "Sherry");
        hmap.put(2, "Karon");
        hmap.put(100, "Jim");

        writefln("item[%d]=%s", 33, hmap.get(33));

        writeln(hmap.toString());

        assert(hmap.size() == 5);
        hmap.remove(1);

        writeln(hmap.toString());
        assert(hmap.size() == 4);

    }

    void testEquals1() {

        HashMap!(int, string) hmap1 = new HashMap!(int, string)();
        hmap1.put(1, "Sherry");
        hmap1.put(22, "Abey");

        HashMap!(int, string) hmap2 = new HashMap!(int, string)();
        hmap2.put(22, "Abey");
        hmap2.put(1, "Sherry");

        assert(hmap1 == hmap2);
    }


    void testEquals2() {

        HashMap!(Price, string) hm1 = new HashMap!(Price, string)();
        hm1.put(new Price("Banana", 20), "Yellow Banana");
        hm1.put(new Price("Apple", 40), "Red Apple");

        HashMap!(Price, string) hm2 = new HashMap!(Price, string)();
        hm2.put(new Price("Apple", 40), "Red Apple");
        hm2.put(new Price("Banana", 20), "Yellow Banana");

        assert(hm1 == hm2);
    }

}