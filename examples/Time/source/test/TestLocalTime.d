module test.TestLocalTime;

import hunt.time;
import hunt.logging;
import std.stdio;
import test.common;


class TestLocalTime {
    __gshared static  LocalTime TEST_15_20_40_987654321;
    shared static this()
    {
        // version(HUNT_DEBUG) trace("LocalTime.of before");
        TEST_15_20_40_987654321 = LocalTime.of(15, 20, 40, 987654321);
        // version(HUNT_DEBUG) trace("LocalTime.of after");
    }

    static void test()
    {
        test_toLocalTime();
        test_parse();
    }

    static void test_toLocalTime()
    {
        mixin(DO_TEST);
        trace("LocalTime (TEST_15_20_40_987654321): ",TEST_15_20_40_987654321);
    }

    static void test_parse()
    {
        mixin(DO_TEST);
        assert(LocalTime.parse("15:20:40").toString == LocalTime.of(15, 20, 40).toString);
    }
}