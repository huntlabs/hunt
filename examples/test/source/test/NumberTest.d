module test.NumberTest;

import hunt.Integer;
import hunt.Long;
import hunt.Number;

class NumberTest {

    void testInteger() {
        Integer i12 = Integer.valueOf(12);
        Integer i20 = new Integer(20);

        assert(i12 > 10);
        assert(10 < i12 );
        assert(i12 < 20 );
        assert(i12 < i20 );
        assert(i20 != i12);
        assert(i20 == 20 && 12 == i12 );
    }

    void testLong() {
        Long l12 = Long.valueOf(12);
        Long l20 = new Long(20);

        import std.stdio;
        writeln(l12.value());
        writeln(l20.value());

        assert(l12 > 10);
        assert(10 < l12 );
        assert(l12 < 20 );
        assert(l12 < l20 );
        assert(l20 != l12);
        assert(l20 == 20 && 12 == l12 );
    }
}