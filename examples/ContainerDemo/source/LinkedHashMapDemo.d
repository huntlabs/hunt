module LinkedHashMapDemo;

import std.stdio;

import hunt.container.LinkedHashMap;
import hunt.container.HashMap;
import hunt.container.Map;
import hunt.container.Iterator;

import std.stdio;
import std.conv;
import std.range;

class LinkedHashMapDemo
{
    // http://java2novice.com/java-collections-and-util/linkedhashmap/
    void testBasic()
    {
        // http://java2novice.com/java-collections-and-util/linkedhashmap/basic-operations/
        LinkedHashMap!(string, string) lhm = new LinkedHashMap!(string, string)();
        lhm.put("one", "This is first element");
        lhm.put("two", "This is second element");
        lhm.put("four", "this element inserted at 3rd position");

        writeln(lhm.toString());
        writeln("Getting value for key 'one': " ~ lhm.get("one"));
        writeln("Size of the map: " ~ lhm.size().to!string());
        writeln("Is map empty? " ~ lhm.isEmpty().to!string());
        writeln("Contains key 'two'? " ~ lhm.containsKey("two").to!string());
        writeln("Contains value 'This is first element'? " ~ lhm.containsValue(
                "This is first element").to!string());

        assert(lhm.size() == 3);
        writeln("delete element 'one': " ~ lhm.remove("one"));
        assert(lhm.size() == 2);
        writeln(lhm.toString());

        lhm.clear();
        assert(lhm.size() == 0);
        writeln(lhm.toString());
    }

    void testIterator()
    {
        //
        writeln("Testing LinkedHashMap...");
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

        writeln("\nTesting LinkedHashMap byValue...");
        foreach (size_t index, string value; lhmap.byValue)
        {
            writefln("value[%d] is: %s ", index, value);
        }
    }

    // http://java2novice.com/java-collections-and-util/linkedhashmap/duplicate-key/
    void testObjectKey()
    {
        LinkedHashMap!(Price, string) hm = new LinkedHashMap!(Price, string)();
        hm.put(new Price("Banana", 20), "Yellow Banana");
        hm.put(new Price("Apple", 40), "Red Apple");
        hm.put(new Price("Orange", 30), "Juicy Orange");
        printMap(hm);

        assert(hm.size() == 3);
        Price key = new Price("Banana", 20);
        writeln("Adding duplicate key...");
        hm.put(key, "Grape");
        
        assert(hm.size() == 3);
        writeln("After adding dulicate key:");
        printMap(hm);

        writeln("Does key available? " ~ hm.containsKey(key).to!string());

		writeln("Deleting key...");
		hm.remove(key);
		writeln("After deleting key:");
        writeln("Does key available? " ~ hm.containsKey(key).to!string());
		printMap(hm);
    }

    void printMap(LinkedHashMap!(Price, string) map)
    {
        foreach (Price p; map.byKey)
        {
            writeln(p.toString() ~ " ==> " ~ map.get(p));
        }
    }
}

class Price
{

    private string item;
    private int price;

    this(string itm, int pr)
    {
        this.item = itm;
        this.price = pr;
    }

    string getItem()
    {
        return item;
    }

    void setItem(string item)
    {
        this.item = item;
    }

    int getPrice()
    {
        return price;
    }

    void setPrice(int price)
    {
        this.price = price;
    }

    override size_t toHash() @trusted nothrow
    {
        size_t hashcode = 0;
        hashcode = price * 20;
        hashcode += hashOf(item);
        return hashcode;
    }

    override bool opEquals(Object obj)
    {
        Price pp = cast(Price) obj;
        if (pp is null)
            return false;
        return (pp.item == this.item && pp.price == this.price);
    }

    override string toString()
    {
        return "item: " ~ item ~ "  price: " ~ price.to!string();
    }
}
