module LinkedHashSetDemo;

import common;

import hunt.collection.HashMap;
import hunt.collection.LinkedHashSet;
import hunt.collection.Set;
import hunt.collection.Iterator;

import std.stdio;
import std.conv;
import std.range;

class LinkedHashSetDemo
{
    void testBasicOperations()
    {
         LinkedHashSet!string hs = new LinkedHashSet!string();
        //add elements to LinkedHashSet
        hs.add("first");
        hs.add("second");
        hs.add("third");
        writeln(hs);
		assert(hs.toString() == "[first, second, third]");
        writeln("Is LinkedHashSet empty? " ~ hs.isEmpty().to!string());
        assert(!hs.isEmpty());
        assert(hs.size == 3);

        LinkedHashSet!string subSet = new LinkedHashSet!string();
		subSet.add("s1");
		subSet.add("s2");
		hs.addAll(subSet);
		writeln("LinkedHashSet content after adding another collection:");
		writeln(hs);
        assert(hs.size == 5);

        hs.remove("third");
        writeln("\nremoving...");
        writeln(hs);
        writeln("Size of the LinkedHashSet: " ~ hs.size().to!string());
        writeln("Does LinkedHashSet contains first element? " ~ hs.contains("first").to!string());
        assert(hs.size == 4);


		writeln("Clearing LinkedHashSet:");
		hs.clear();
		writeln("Content After clear:");
		writeln(hs);
        assert(hs.size == 0);
   
    }

    void testCompare()
    {
        LinkedHashSet!string hs = new LinkedHashSet!string();
		//add elements to LinkedHashSet
		hs.add("first");
		hs.add("second");
		hs.add("third");
		hs.add("apple");
		hs.add("rat");
		writeln(hs);

        assert(hs.size == 5);

		LinkedHashSet!string subSet = new LinkedHashSet!string();
		subSet.add("rat");
		subSet.add("second");
		subSet.add("first");
		hs.retainAll(subSet);
		writeln("LinkedHashSet content:");
		writeln(hs);
        assert(hs.size == 3);
    }

    void testObjectSet()
    {
        LinkedHashSet!Price lhs = new LinkedHashSet!Price();
		lhs.add(new Price("Banana", 20));
		lhs.add(new Price("Apple", 40));
		lhs.add(new Price("Orange", 30));
		foreach(Price pr; lhs){
			writeln(pr);
		}
        assert(lhs.size == 3);

		Price duplicate = new Price("Banana", 20);
		writeln("\ninserting duplicate object...");
		lhs.add(duplicate);
		writeln("After insertion:");
        assert(lhs.size == 3);
		foreach(Price pr; lhs){
			writeln(pr);
		}


		Price key = new Price("Banana", 20);
		writeln("Does set contains key? " ~ lhs.contains(key).to!string());

        writeln("\ndeleting key from set...");
		lhs.remove(key);
		writeln("Elements after delete:");
        assert(lhs.size == 2);
		foreach(Price pr; lhs){
			writeln(pr);
		}

		writeln("Does set contains key? " ~ lhs.contains(key).to!string());
    }
}