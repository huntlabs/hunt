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
import test.MagedQueueTest;
import test.MimeTypeTest;
import test.NullableTest;
import test.NumberTest;
import test.PathMatcherTest;
import test.PropertySetterTest;
import test.ScheduledThreadPoolTest;
import test.StringTokenizerTest;
import test.TaskPoolTest;
import test.ThreadPoolExecutorTest;
import test.ThreadTest;

import core.thread;
import std.stdio;

import benchmark.LinkedBlockingQueueBench;
import test.MagedQueueTest;

void main()
{
	writeln("Thread id: ", Thread.getThis().id);
	writeln("CPU: ", totalCPUs);
	writeln("Memory page: ", pageSize);
	writeln("TimeZone ID: ", DateTimeHelper.getSystemTimeZoneId());

	testPropertySetter();

	// testUnits!(MagedQueueTest);

	// testUnits!(AtomicTest);
	// testUnits!(BigIntegerTest);
	// testUnits!(JsonHelperTest);
	// testUnits!(LinkedBlockingQueueTest);
	// testUnits!(MimeTypeTest);
	// testUnits!(NullableTest);
	// testUnits!(NumberTest);
	// // TODO: Tasks pending completion -@zxp at 2/28/2019, 5:45:41 PM
	// // 
	// // testUnits!(PathMatcherTest); 
	// testUnits!(StringTokenizerTest);
	// testUnits!(ThreadTest);

	// // These tests belown will block the test procession.

	// // testUnits!(TaskPoolTest);
	// // LinkedBlockingQueueBench b = new LinkedBlockingQueueBench();
	// // b.bench();
	// // testTask();
	// // testLockSupport01();
	// // testUnits!(ScheduledThreadPoolTest);
	// // testUnits!(ThreadPoolExecutorTest);
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