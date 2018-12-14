module test.TestLocalDate;

import hunt.time;
import hunt.logging;
import std.stdio;
import test.common;


class TestLocalDate {
    __gshared static  LocalDate TEST_2018_12_14;
    shared static this()
    {
        TEST_2018_12_14 = LocalDate.of(2018,12,14);
    }

    static void test()
    {
        test_toLocalDate();
        test_parse();
    }

    static void test_toLocalDate()
    {
        mixin(DO_TEST);
        trace("LocalDate (TEST_2018_12_14): ",TEST_2018_12_14);
        trace("LocalDate.of(2012, Month.DECEMBER, 12) : ",LocalDate.of(2012, Month.DECEMBER, 12)); // from values
        trace("LocalDate.ofEpochDay(150) : ",LocalDate.ofEpochDay(150)); 
    }

    static void test_parse()
    {
        mixin(DO_TEST);
        assert(LocalDate.parse("2018-12-14").toString == TEST_2018_12_14.toString);
    }
    
}