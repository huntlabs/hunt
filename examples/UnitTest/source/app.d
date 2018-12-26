import std.stdio;

import hunt.lang.exception;
import hunt.util.UnitTest;
import hunt.logging;

import test.BigIntegerTest;
import test.JsonHelperTest;
import test.LinkedBlockingQueueTest;
import test.MimeTypeTest;
import test.NullableTest;
import test.NumberTest;
import test.PathMatcherTest;
import test.TaskTest;
import test.ThreadPoolExecutorTest;
import test.ThreadTest;

import core.thread;

import hunt.concurrent.thread;
import hunt.util.memory;
import hunt.datetime;

void main()
{
	writeln("Thread id: ", Thread.getThis().id);
	writeln("CPU: ", totalCPUs);
	writeln("TimeZone ID: ", DateTimeHelper.getSystemTimeZoneId());
	// testUnits!(BigIntegerTest);
	// testTask();

	// testUnits!(JsonHelperTest);
	// testUnits!(LinkedBlockingQueueTest);
	// testUnits!(MimeTypeTest);
	// testUnits!(ThreadPoolExecutorTest);
	// testUnits!(ThreadTest);
	testUnits!(NullableTest);
	testUnits!(NumberTest);
	// testUnits!(PathMatcherTest);

	// testLockSupport01();

}



    // void testLockSupport01() {
    //     Thread thread = Thread.getThis();  
      
    //     LockSupport.unpark(thread);  
      
    //     writeln("a");  
    //     LockSupport.park();  
    //     writeln("b");  
    //     LockSupport.park();  
    //     writeln("c");  
    // }