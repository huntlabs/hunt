import std.stdio;

import hunt.lang.exception;
import hunt.util.UnitTest;
import hunt.logging;

import test.BigIntegerTest;
import test.LinkedBlockingQueueTest;
import test.NullableTest;
import test.TaskTest;
import test.ThreadPoolExecutorTest;

void main()
{
	// testUnits!(BigIntegerTest);
	// testTask();
	// testUnits!(LinkedBlockingQueueTest);
	// testUnits!(ThreadPoolExecutorTest);
	testUnits!(NullableTest);
}
