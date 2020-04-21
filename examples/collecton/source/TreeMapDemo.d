module TreeMapDemo;

import hunt.collection.HashMap;
import hunt.collection.TreeMap;
import hunt.collection.Map;
import hunt.collection.Iterator;

import std.stdio;
import std.conv;
import std.range;

class TreeMapDemo {

    void testBasicOperation() {
        /* This is how to declare TreeMap */
        TreeMap!(int, string) tmap = new TreeMap!(int, string)();

        /*Adding elements to TreeMap*/
        tmap.put(1, "Data1");
        tmap.put(23, "Data23");
        tmap.put(70, "Data70");
        tmap.put(4, "Data4");
        tmap.put(2, "Data2");

        writeln(tmap.toString());
        assert(tmap[70] == "Data70", tmap[70]);

        /* Display content using Iterator*/
        //   Set!(MapEntry!(K,V)) set = tmap.entrySet();
        //   Iterator!(MapEntry!(K,V)) iterator = set.iterator();
        //   while(iterator.hasNext()) {
        //      Map.Entry mentry = (Map.Entry)iterator.next();
        //      System.out.print("key is: "+ mentry.getKey() ~ " & Value is: ");
        //      writeln(mentry.getValue());
        //   }
        writeln("\nTesting TreeMap foreach1...");
        foreach (int key, string value; tmap) {
            writeln("key is: " ~ key.to!string ~ " & Value is: " ~ value);
        }

        writeln("\nTesting TreeMap foreach2...");
        foreach (MapEntry!(int, string) entry; tmap) {
            writeln("Key is: " ~ entry.getKey().to!string ~ " & Value is: " ~ entry.getValue());
        }

        writeln("\nTesting TreeMap byKey...");
        foreach (size_t index, int key; tmap.byKey) {
            writefln("Key[%d] is: %d ", index, key);
        }

        writeln("\nTesting TreeMap byValue...");
        foreach (size_t index, string value; tmap.byValue) {
            writefln("value[%d] is: %s ", index, value);
        }
    }

    void testElementWithClass() {
        
    }
}
