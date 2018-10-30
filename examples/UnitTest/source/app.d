import std.stdio;

import hunt.lang.exception;
import hunt.util.UnitTest;
import hunt.logging;

import test.BigIntegerTest;
import test.LinkedBlockingQueueTest;
import test.NullableTest;
import test.NumberTest;
import test.PathMatcherTest;
import test.TaskTest;
import test.ThreadPoolExecutorTest;
import test.ThreadTest;

import core.thread;

void main()
{
	writeln(Thread.getThis().id);
	// testUnits!(BigIntegerTest);
	// testTask();
	// testUnits!(LinkedBlockingQueueTest);
	// testUnits!(ThreadPoolExecutorTest);
	testUnits!(ThreadTest);
	// testUnits!(NullableTest);
	// testUnits!(NumberTest);
	// testUnits!(PathMatcherTest);

}

