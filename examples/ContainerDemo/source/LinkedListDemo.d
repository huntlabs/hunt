module LinkedListDemo;

import common;

import hunt.collection.AbstractList;
import hunt.collection.ArrayList;
import hunt.collection.LinkedList;
import hunt.collection.Collections;
import hunt.collection.List;

import std.stdio;
import std.conv;
import std.range;

// http://www.java2novice.com/java-collections-and-util/arraylist/
class LinkedListDemo
{
    void testBasicOperations()
    {
        LinkedList!(string) arrl = new LinkedList!(string)();
        //adding elements to the end
        arrl.add("First");
        arrl.add("Second");
        arrl.add("Third");
        arrl.add("Random");

        assert(arrl.size == 4);
        assert(arrl.getLast() == "Random");


        writeln("Actual LinkedList:" ~ arrl.toString());

        writeln("First Element: " ~ arrl.element());
        writeln("First Element: " ~ arrl.getFirst());
        writeln("First Element: " ~ arrl.peek());
        writeln("First Element: " ~ arrl.peekFirst());

        writeln("Last Element: " ~ arrl.getLast());
        writeln("Last Element: " ~ arrl.peekLast());

        List!(string) list = new ArrayList!(string)();
        list.add("one");
        list.add("two");
        arrl.addAll(list);
        writeln("After Copy: " ~ arrl.toString());
        assert(arrl.size() == 6);

        writeln("Adding element at last position...");
        arrl.addLast("I am last");
        writeln(arrl);
        writeln("Adding element at last position...");
        arrl.offerLast("I am last - 1");
        writeln(arrl);
        writeln("Adding element at last position...");
        arrl.offer("I am last - 2");
        assert(arrl.size() == 9);
        writeln(arrl);

        assert(arrl.toString() == "[First, Second, Third, Random, one, two, I am last, I am last - 1, I am last - 2]", arrl.toString());

        // writeln("Actual LinkedList:"+arrl);
        arrl.clear();
        assert(arrl.size() == 0);
        writeln("After clear LinkedList:" ~ arrl.toString());

    }

    void testRemove()
    {
        LinkedList!(string) arrl = new LinkedList!(string)();
        arrl.add("First");
        arrl.add("Second");
        arrl.add("Third");
        arrl.add("Random");
        arrl.add("four");
        arrl.add("five");
        arrl.add("six");
        arrl.add("seven");
        arrl.add("eight");
        arrl.add("nine");
        writeln(arrl);
        assert(arrl.size == 10);

        writeln("\nRemov() method:" ~ arrl.remove());
        writeln("After remove() method call:");
        writeln(arrl);
        assert(arrl.size == 9);

        writeln("\nremove(index) method:" ~ arrl.removeAt(2).to!string());
        writeln("After remove(index) method call:");
        writeln(arrl);
        assert(arrl.size == 8);
        assert(arrl.toString() == "[Second, Third, four, five, six, seven, eight, nine]", arrl.toString());

        writeln("\nRemov(object) method:" ~ arrl.remove("six").to!string());
        writeln("After remove(object) method call:");
        writeln(arrl);
        assert(arrl.size == 7, arrl.size().to!string());

        writeln("\nremoveFirst() method:" ~ arrl.removeFirst());
        assert(arrl.size == 6, arrl.size().to!string());
        writeln("After removeFirst() method call:");
        writeln(arrl);

        writeln("\nremoveFirstOccurrence() method:" ~ arrl.removeFirstOccurrence("eight"));
        writeln("After removeFirstOccurrence() method call:");
        writeln(arrl);

        writeln("\nremoveLast() method:" ~ arrl.removeLast());
        writeln("After removeLast() method call:");
        writeln(arrl);
        assert(arrl.size == 4);
        assert(arrl.toString() == "[Third, four, five, seven]", arrl.toString());


        // writeln("removeLastOccurrence() method:" ~ arrl.removeLastOccurrence("five"));
        // writeln("After removeLastOccurrence() method call:");
        // writeln(arrl);
    }

    void testContains()
    {
        LinkedList!(string) arrl = new LinkedList!(string)();
        //adding elements to the end
        arrl.add("First");
        arrl.add("Second");
        arrl.add("Third");
        arrl.add("Random");
        writeln("Actual LinkedList:" ~ arrl.toString());

        List!(string) list = new LinkedList!(string)();
        list.add("Second");
        list.add("Random");
        writeln("Does LinkedList contains all list elements?: " ~ arrl.containsAll(list)
                .to!string());
        list.add("one");
        writeln("Does LinkedList contains all list elements?: " ~ arrl.containsAll(list)
                .to!string());
    }

    void testPushPop()
    {
        LinkedList!(string) arrl = new LinkedList!(string)();
        arrl.add("First");
        arrl.add("Second");
        arrl.add("Third");
        arrl.add("Random");
        writeln(arrl);
        arrl.push("push element");
        writeln("After push operation:");
        writeln(arrl);
        arrl.pop();
        writeln("After pop operation:");
        writeln(arrl);
    }

    // void testSubList()
    // {
    //     LinkedList!(string) arrl = new LinkedList!(string)();
    //     //adding elements to the end
    //     arrl.add("First");
    //     arrl.add("Second");
    //     arrl.add("Third");
    //     arrl.add("Random");
    //     arrl.add("Click");
    //     writeln("Actual LinkedList:" ~ arrl.toString());
    //     List!(string) list = arrl.subList(2, 4);
    //     writeln("Sub List: " ~ list.toString());
    // }

    // void testReverse()
    // {
    //     LinkedList!(string) list = new LinkedList!(string)();
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
    //     LinkedList!(string) list = new LinkedList!(string)();
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
    //     LinkedList!(string) list = new LinkedList!(string)();
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

}
