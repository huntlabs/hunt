module test.TestLocalDateTime;

import hunt.time;
import hunt.logging;
import test.common;

class TestLocalDateTime
{
    __gshared static LocalDateTime TEST_2018_12_10_15_20_40_987654321;
    shared static this()
    {
        TEST_2018_12_10_15_20_40_987654321 = LocalDateTime.of(2018, 12, 10, 15, 20, 40, 987654321);
    }

    static void test()
    {
        test_toLocalTime();
        test_other();
    }

    static void test_toLocalTime()
    {
        mixin(DO_TEST);
        trace("LocalDateTime (TEST_2018_12_10_15_20_40_987654321): ",
                TEST_2018_12_10_15_20_40_987654321.toLocalTime());
    }

    static void test_other()
    {
        mixin(DO_TEST);

        trace("TEST_2018_12_10_15_20_40_987654321.toLocalDate() : ",
                TEST_2018_12_10_15_20_40_987654321.toLocalDate());
        trace("TEST_2018_12_10_15_20_40_987654321.getMonth() : ",
                TEST_2018_12_10_15_20_40_987654321.getMonth());
        trace("TEST_2018_12_10_15_20_40_987654321.getDayOfMonth() : ",
                TEST_2018_12_10_15_20_40_987654321.getDayOfMonth());
        trace("TEST_2018_12_10_15_20_40_987654321.getSecond() : ",
                TEST_2018_12_10_15_20_40_987654321.getSecond());

        // Set the value, returning a new object
        trace("TEST_2018_12_10_15_20_40_987654321.withDayOfMonth(15).withYear(2017) : ",
                TEST_2018_12_10_15_20_40_987654321.withDayOfMonth(13).withYear(2017));

        /* You can use direct manipulation methods, 
    or pass a value and field pair */
        trace("TEST_2018_12_10_15_20_40_987654321.plusWeeks(3).plus(3, ChronoUnit.WEEKS) : ",
                TEST_2018_12_10_15_20_40_987654321.plusWeeks(3).plus(3, ChronoUnit.WEEKS));

        trace("TEST_2018_12_10_15_20_40_987654321.with(lastDayOfMonth()) : ",
                TEST_2018_12_10_15_20_40_987654321._with (TemporalAdjusters.lastDayOfMonth())
                    );

        trace("TEST_2018_12_10_15_20_40_987654321.with(previousOrSame(DayOfWeek.WEDNESDAY)) : ",
                TEST_2018_12_10_15_20_40_987654321._with (TemporalAdjusters.previousOrSame(DayOfWeek.WEDNESDAY))
                    );
    }
}
