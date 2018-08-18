import std.stdio;

import hunt.util.UnitTest;

import ArrayListDemo;
import HashSetDemo;
import HashMapDemo;
import LinkedListDemo;
import LinkedHashSetDemo;
import LinkedHashMapDemo;
import MapDemo;
import SetDemo;

void main()
{
    // testUnits!(ArrayListDemo)();
    // testUnits!HashMapDemo();
    // testUnits!HashSetDemo();
    testUnits!(LinkedListDemo)();
    // testUnits!LinkedHashSetDemo();
    // testUnits!LinkedHashMapDemo();
    // testUnits!MapDemo();
    // testUnits!SetDemo();

}
