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

    void testBasic01() {
        Fruit f = new Fruit("apple", 5.8f);
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

    void testGetAndSet01() {
        Fruit f = new Fruit("apple", 5.8f);
        Fruit f1 = new Fruit("banana", 3.8f);

        {

            Fruit old = AtomicHelper.getAndSet(f, f1);
            // trace(old.toString());
            // trace(f.toString());
            assert(old.getName() == "apple");
            assert(f.getName() == "banana");
        }

        // Fruit rr = cast(Fruit)atomicExchange(cast(shared)&f, cast(shared)f1);
        // trace(rr.toString());

        {
            value = 12;

            int old = AtomicHelper.getAndSet(value, 23);
            // tracef("old: %d, new: %d", old, value);

            assert(old == 12 && value == 23);
        }

    }
    
    void testGetAndSet02() {
        Fruit[] fruits = [
            new Fruit("apple", 5.8f),
            new Fruit("banana", 3.8f),
            new Fruit("peach", 4.6f)
        ];


        Fruit old = AtomicHelper.getAndSet(fruits[1], null);
        // trace(old.toString());
        // trace(f.toString());
        assert(old.getName() == "banana");
        assert(fruits[0] !is null);
        assert(fruits[0].getName() == "apple");

        assert(fruits[1] is null);

        assert(fruits[2] !is null);
        assert(fruits[2].getName() == "peach");

    }
}
