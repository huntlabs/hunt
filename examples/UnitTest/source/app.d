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

import hunt.concurrent.thread;
import hunt.util.memory;

void main()
{
	writeln("Thread id: ", Thread.getThis().id);
	writeln("CPU: ", totalCPUs);
	// testUnits!(BigIntegerTest);
	// testTask();
	// testUnits!(LinkedBlockingQueueTest);
	testUnits!(ThreadPoolExecutorTest);
	// testUnits!(ThreadTest);
	// testUnits!(NullableTest);
	// testUnits!(NumberTest);
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