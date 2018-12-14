module test.TestTimeZone;

import hunt.time;
import hunt.logging;
import std.stdio;
import test.common;


class TestTimeZone {

    static void test()
    {
        test_zoneid();
    }

    static void test_zoneid()
    {
        mixin(DO_TEST);

        ZoneId id = ZoneId.of("Asia/Shanghai");
        ZonedDateTime zoned = ZonedDateTime.of(LocalDateTime.now(), id);
        trace("ZoneId.of(\"Asia/Shanghai\") : ",ZoneId.of("Asia/Shanghai"));
        trace("ZonedDateTime.of(LocalDateTime.now(), id) : ",ZonedDateTime.of(LocalDateTime.now(), id));
    }
}