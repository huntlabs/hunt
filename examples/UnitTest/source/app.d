import hunt.concurrency.thread;
import hunt.util.DateTime;
import hunt.logging;
import hunt.system.Memory;
import hunt.util.UnitTest;

import test.AtomicTest;
import test.BigIntegerTest;
import test.JsonHelperTest;
import test.ForkJoinPoolTest;
import test.LinkedBlockingQueueTest;
import test.MimeTypeTest;
import test.NullableTest;
import test.NumberTest;
import test.PathMatcherTest;
import test.ScheduledThreadPoolTest;
import test.StringTokenizerTest;
import test.TaskTest;
import test.TaskPoolTest;
import test.ThreadPoolExecutorTest;
import test.ThreadTest;

import core.thread;
import std.stdio;

import benchmark.LinkedBlockingQueueBench;

void main()
{
	writeln("Thread id: ", Thread.getThis().id);
	writeln("CPU: ", totalCPUs);
	writeln("TimeZone ID: ", DateTimeHelper.getSystemTimeZoneId());

	testUnits!(TaskPoolTest);


	// LinkedBlockingQueueBench b = new LinkedBlockingQueueBench();
	// b.bench();

	// testUnits!(AtomicTest);
	// testUnits!(BigIntegerTest);
	// // testTask();

	// testUnits!(JsonHelperTest);
	// testUnits!(LinkedBlockingQueueTest);
	// testUnits!(MimeTypeTest);
	// testUnits!(NullableTest);
	// testUnits!(NumberTest);
	// testUnits!(PathMatcherTest);
	// testUnits!(ScheduledThreadPoolTest);
	// testUnits!(StringTokenizerTest);
	// testUnits!(ThreadPoolExecutorTest);
	// testUnits!(ThreadTest);

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