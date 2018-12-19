module test.TestInstant;

import hunt.time;
import hunt.logging;
import std.stdio;
import test.common;


class TestInstant {

    static void test()
    {
        test_now();
    }

    static void test_now()
    {
        mixin(DO_TEST);
        trace("Instant.now() : ",Instant.now());
    }

}