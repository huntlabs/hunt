import std.stdio;

import hunt.util.exception;
import hunt.util.UnitTest;
import hunt.logging;

import test.BigIntegerTest;
import test.LinkedBlockingQueueTest;
import test.TaskTest;

void main()
{
	// testUnits!(BigIntegerTest);
	// testTask();
	testUnits!(LinkedBlockingQueueTest);
	
}
