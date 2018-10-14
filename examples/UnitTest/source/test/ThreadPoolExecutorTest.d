module test.ThreadPoolExecutorTest;

import hunt.concurrent.LinkedBlockingQueue;
import hunt.concurrent.ThreadPoolExecutor;
import hunt.datetime;
import hunt.logging.ConsoleLogger;

import core.time;
import std.stdio;

class ThreadPoolExecutorTest {

    void testBasicOperatoins() {

		ThreadPoolExecutor executor = new ThreadPoolExecutor(7, 8, 
			5.seconds, new LinkedBlockingDeque!Runnable());
		writeln(executor.getCorePoolSize());
		writeln(executor.getMaximumPoolSize());
		writeln("");
		// executor = new ThreadPoolExecutor(7, 8, 5, TimeUnit.Second,
		// 		new SynchronousQueue!Runnable());
		// writeln(executor.getCorePoolSize());
		// writeln(executor.getMaximumPoolSize());
    }
}