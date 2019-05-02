module test.AtomicTest;

import common;
import hunt.concurrency.atomic;
import hunt.logging.ConsoleLogger;

import core.atomic;

class AtomicTest {

    __gshared Fruit fruit;

    shared static int value;

    shared static this() {
        AtomicHelper.store(value, 12);
    }

    void atomicStore1(MemoryOrder ms = MemoryOrder.seq, T, V1)(ref shared T val, V1 newval ) {
        val = newval;
    }

    void testBasic01() {
        Fruit f = new Fruit("apple", 5.8f);
        // atomicStore1((cast(shared Fruit)fruit), cast(shared)f); // bad
        atomicStore(*(cast(shared)&fruit), cast(shared)f);

        assert(fruit !is null);
        trace(fruit.toString());
        

        int v = AtomicHelper.load(value);
        assert(v == 12);
    }

    void testBasic02() {
        Fruit f = new Fruit("apple", 5.8f);
        AtomicHelper.store(fruit, f);

        assert(fruit !is null);
        trace(fruit.toString());
        
        int v = AtomicHelper.load(value);
        assert(v == 12);
    }
}
