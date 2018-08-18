module HashSetDemo;

import common;

import hunt.container.HashMap;
import hunt.container.HashSet;
import hunt.container.Set;
import hunt.container.Iterator;

import std.stdio;
import std.conv;
import std.range;

class HashSetDemo
{
    void testBasicOperations()
    {
         HashSet!string hs = new HashSet!string();
        //add elements to HashSet
        hs.add("first");
        hs.add("second");
        hs.add("third");
        writeln(hs);
        writeln("Is HashSet empty? " ~ hs.isEmpty().to!string());
        assert(!hs.isEmpty());
        assert(hs.size == 3);

        HashSet!string subSet = new HashSet!string();
		subSet.add("s1");
		subSet.add("s2");
		hs.addAll(subSet);
		writeln("HashSet content after adding another collection:");
		writeln(hs);
        assert(hs.size == 5);

        hs.remove("third");
        writeln("\nremoving...");
        writeln(hs);
        writeln("Size of the HashSet: " ~ hs.size().to!string());
        writeln("Does HashSet contains first element? " ~ hs.contains("first").to!string());
        assert(hs.size == 4);


		writeln("Clearing HashSet:");
		hs.clear();
		writeln("Content After clear:");
		writeln(hs);
        assert(hs.size == 0);
   
    }

    void testCompare()
    {
        HashSet!string hs = new HashSet!string();
		//add elements to HashSet
		hs.add("first");
		hs.add("second");
		hs.add("third");
		hs.add("apple");
		hs.add("rat");
		writeln(hs);

        assert(hs.size == 5);

		HashSet!string subSet = new HashSet!string();
		subSet.add("rat");
		subSet.add("second");
		subSet.add("first");
		hs.retainAll(subSet);
		writeln("HashSet content:");
		writeln(hs);
        assert(hs.size == 3);
    }

    void testObjectSet()
    {
        HashSet!Price lhs = new HashSet!Price();
		lhs.add(new Price("Banana", 20));
		lhs.add(new Price("Apple", 40));
		lhs.add(new Price("Orange", 30));
		foreach(Price pr; lhs){
			writeln(pr);
		}
        assert(hs.size == 3);

		Price duplicate = new Price("Banana", 20);
		writeln("\ninserting duplicate object...");
		lhs.add(duplicate);
		writeln("After insertion:");
        assert(hs.size == 3);
		foreach(Price pr; lhs){
			writeln(pr);
		}


		Price key = new Price("Banana", 20);
		writeln("Does set contains key? " ~ lhs.contains(key).to!string());

        writeln("\ndeleting key from set...");
		lhs.remove(key);
		writeln("Elements after delete:");
        assert(hs.size == 2);
		foreach(Price pr; lhs){
			writeln(pr);
		}

		writeln("Does set contains key? " ~ lhs.contains(key).to!string());
    }
}