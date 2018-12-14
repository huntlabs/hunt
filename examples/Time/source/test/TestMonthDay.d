
module test.TestMonthDay;

import hunt.time;
import hunt.util.UnitTest;

import hunt.container.List;

import hunt.util.Assert;
import hunt.lang.exception;

alias assertTrue = Assert.assertTrue;
alias assertFalse = Assert.assertFalse;
alias assertThat = Assert.assertThat;
alias assertEquals = Assert.assertEquals;
alias assertNotNull = Assert.assertNotNull;
alias assertNull = Assert.assertNull;
alias assertSame = Assert.assertSame;


/**
 * Test MonthDay.
 */
// @Test
public class TestMonthDay  {

    private __gshared MonthDay TEST_07_15;

    shared static this() {
        TEST_07_15 = MonthDay.of(7, 15);
    }

    @Test
    public void test_with_Month_noChangeSame() {
        MonthDay test = MonthDay.of(6, 30);
        assertSame(test._with(Month.JUNE), test);
    }

    @Test
    public void test_withMonth_int_noChangeSame() {
        MonthDay test = MonthDay.of(6, 30);
        assertSame(test.withMonth(6), test);
    }
    @Test
    public void test_withDayOfMonth_noChangeSame() {
        MonthDay test = MonthDay.of(6, 30);
        assertSame(test.withDayOfMonth(30), test);
    }

    @Test
    public void test_adjustDate_same() {
        MonthDay test = MonthDay.of(6, 30);
        LocalDate date = LocalDate.of(2007, 6, 30);
        assertSame(test.adjustInto(date), date);
    }

}
