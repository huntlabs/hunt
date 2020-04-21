module ArrayListDemo;

import common;

import hunt.collection.AbstractList;
import hunt.collection.ArrayList;
import hunt.collection.Collections;
import hunt.collection.List;

import hunt.logging.ConsoleLogger;

import std.stdio;
import std.conv;
import std.range;

// http://www.java2novice.com/java-collections-and-util/arraylist/
class ArrayListDemo
{
    void testBasicOperations()
    {
        ArrayList!(string) al = new ArrayList!(string)();
        //add elements to the ArrayList
        al.add("JAVA");
        al.add("C++");
        al.add("PERL");
        al.add("PHP");
        writeln(al);
        assert(al.size() == 4);
        writeln("\nIterating...");
        foreach (string v; al)
        {
            writeln(v);
        }

        //get elements by index
        writeln("\nIndexing...");
        writeln("Element at index 0: " ~ al[0]);
        writeln("Element at index 1: " ~ al.get(1));
        writeln("Does list contains JAVA? " ~ al.contains("JAVA").to!string());

        //add elements at a specific index
        writeln("\nAdding...");
        al.add(2, "PLAY");

        assert(al.size() == 5);
        assert(al[2] == "PLAY");

        writeln(al);
        writeln("Is arraylist empty? " ~ al.isEmpty().to!string());
        writeln("Index of PERL is " ~ al.indexOf("PERL").to!string());
        writeln("Size of the arraylist is: " ~ al.size().to!string());

        writeln("\nRemoving...");
        al.removeAt(2);
        assert(al.size() == 4);
        assert(al[2] != "PLAY");
        writeln(al);

        writeln("\nClearing...");
        al.clear();
        writeln("After clear ArrayList:" ~ al.toString());
        assert(al.size() == 0);

    }

    void testAddListElements()
    {
        ArrayList!(string) arrl = new ArrayList!(string)();
        //adding elements to the end
        arrl.add("First");
        arrl.add("Second");
        arrl.add("Third");
        arrl.add("Random");
        writeln("Actual ArrayList:" ~ arrl.toString());
        List!(string) list = new ArrayList!(string)();
        list.add("one");
        list.add("two");
        arrl.addAll(list);
        writeln("After Copy: " ~ arrl.toString());
    }

    void testContains()
    {
        ArrayList!(string) arrl = new ArrayList!(string)();
        //adding elements to the end
        arrl.add("First");
        arrl.add("Second");
        arrl.add("Third");
        arrl.add("Random");
        writeln("Actual ArrayList:" ~ arrl.toString());

        List!(string) list = new ArrayList!(string)();
        list.add("Second");
        list.add("Random");
        writeln("Does ArrayList contains all list elements?: " ~ arrl.containsAll(list)
                .to!string());
        list.add("one");
        writeln("Does ArrayList contains all list elements?: " ~ arrl.containsAll(list)
                .to!string());
    }

    // TODO: Tasks pending completion -@zxp at 5/15/2019, 6:12:03 PM
    // 
    // void testSubList()
    // {
    //     ArrayList!(string) arrl = new ArrayList!(string)();
    //     //adding elements to the end
    //     arrl.add("First");
    //     arrl.add("Second");
    //     arrl.add("Third");
    //     arrl.add("Random");
    //     arrl.add("Click");
    //     writeln("Actual ArrayList:" ~ arrl.toString());
    //     List!(string) list = arrl.subList(2, 4);
    //     writeln("Sub List: " ~ list.toString());
    // }

    // void testReverse()
    // {
    //     ArrayList!(string) list = new ArrayList!(string)();
    // 	list.add("Java");
    // 	list.add("Cric");
    // 	list.add("Play");
    // 	list.add("Watch");
    // 	list.add("Glass");
    // 	Collections.reverse(list);
    // 	writeln("Results after reverse operation:");
    // 	foreach(string str; list){
    // 		writeln(str);
    // 	}
    // }

    // void testShuffle()
    // {
    //     ArrayList!(string) list = new ArrayList!(string)();
    //     list.add("Java");
    //     list.add("Cric");
    //     list.add("Play");
    //     list.add("Watch");
    //     list.add("Glass");
    //     list.add("Movie");
    //     list.add("Girl");

    //     Collections.shuffle(list);
    //     writeln("Results after shuffle operation:");
    //     foreach(string str; list){
    //         writeln(str);
    //     }

    //     Collections.shuffle(list);
    //     writeln("Results after shuffle operation:");
    //     foreach(string str; list){
    //         writeln(str);
    //     }
    // }

    // void testSwap()
    // {
    //     ArrayList!(string) list = new ArrayList!(string)();
    // 	list.add("Java");
    // 	list.add("Cric");
    // 	list.add("Play");
    // 	list.add("Watch");
    // 	list.add("Glass");
    // 	list.add("Movie");
    // 	list.add("Girl");

    // 	Collections.swap(list, 2, 5);
    // 	writeln("Results after swap operation:");
    // 	foreach(string str; list){
    // 		writeln(str);
    // 	}
    // }

    void testInsert() {
        ArrayList!(string) arrl = new ArrayList!(string)();

        //adding elements to the end
        arrl.add(0, "Second");
        assert(arrl[0] == "Second");

        arrl.add("Third");
        arrl.add("Random");

        arrl.add(0, "First");
        assert(arrl[0] == "First");

        arrl.add(2, "Random1");
        assert(arrl[2] == "Random1");
        assert(arrl[3] == "Third");

        foreach(string s; arrl) {
            trace(s);
        }
    }

}
