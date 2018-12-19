import std.stdio;
import hunt.logging;
import hunt.util.UnitTest;

import std.string;
import core.thread;

import test.TestLocalDateTime;
import test.TestLocalTime;
import test.TestLocalDate;
import test.TestMonthDay;
import test.TestTimeZone;
import test.TestInstant;

void main()
{
	trace("Test Time.");

	new Thread({ Thread.sleep(1.seconds); TestLocalTime.test(); }).start();
	new Thread({ Thread.sleep(1.seconds); TestLocalDate.test(); }).start();
	new Thread({ Thread.sleep(2.seconds); TestLocalDateTime.test(); }).start();
	new Thread({ Thread.sleep(3.seconds); testUnits!(TestMonthDay); }).start();

	TestTimeZone.test();
	TestInstant.test();
}
