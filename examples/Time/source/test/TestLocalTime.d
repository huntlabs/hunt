module test.TestLocalTime;

import hunt.time;
import hunt.logging;
import std.stdio;
import test.common;

import hunt.logging;

class TestLocalTime {
    static  LocalDateTime TEST_2018_12_10_15_20_40_987654321;
    static this()
    {
        version(HUNT_DEBUG) trace("LocalDateTime.of before");
        TEST_2018_12_10_15_20_40_987654321 = LocalDateTime.of(2018, 12, 10, 15, 20, 40, 987654321);
        version(HUNT_DEBUG) trace("LocalDateTime.of after");
    }

    static void test()
    {
        test_toLocalTime();
    }

    static void test_toLocalTime()
    {
        trace("LocalTime 11: ",TEST_2018_12_10_15_20_40_987654321.toLocalTime());
    }
}