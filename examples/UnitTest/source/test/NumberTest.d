module test.NumberTest;

import hunt.math.Integer;
import hunt.math.Long;
import hunt.math.Number;

class NumberTest {

    void testLong() {
        Long l12 = Long.valueOf(12);
        Long l20 = new Long(20);

        assert(l12 > 10);
        assert(10 < l12 );
        assert(l12 < 20 );
        assert(l12 < l20 );
        assert(l20 != l12);
        assert(l20 == 20 && 12 == l12 );
    }
}