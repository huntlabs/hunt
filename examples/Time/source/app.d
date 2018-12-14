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

void main()
{
	trace("Test Time.");

	TestLocalTime.test();

	TestLocalDate.test();

	TestLocalDateTime.test();

	testUnits!(TestMonthDay);

	TestTimeZone.test();

}
