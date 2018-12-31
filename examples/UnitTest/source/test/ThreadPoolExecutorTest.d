module test.ThreadPoolExecutorTest;

import hunt.concurrent.AbstractExecutorService;
import hunt.concurrent.exception;
import hunt.concurrent.Executors;
import hunt.concurrent.ExecutorService;
import hunt.concurrent.Future;
import hunt.concurrent.LinkedBlockingQueue;
import hunt.concurrent.ThreadPoolExecutor;
import hunt.concurrent.thread;

import hunt.datetime;
import hunt.lang.common;
import hunt.lang.exception;
import hunt.logging.ConsoleLogger;

import core.thread;
import core.time;
import std.conv;
import std.stdio;

class ThreadPoolExecutorTest {


    void testBasicOperatoins01() {
        ThreadEx tx = new ThreadEx(&doBasicOperatoins01);
        tx.start();

        // thread_joinAll();
        // trace("done.");  
    }

	void doBasicOperatoins01() {
		try {
			StringCallable callable = new StringCallable();
			IntCallable intCallable = new IntCallable();

			ThreadPoolExecutor executor = new ThreadPoolExecutor(2, 3, 
				5.seconds, new LinkedBlockingQueue!Runnable());

			ConsoleLogger.trace(executor.getCorePoolSize());
			ConsoleLogger.trace(executor.getMaximumPoolSize());

			ConsoleLogger.trace("begin...");
			Future!(string) stringFuture = Executors.submit(executor, callable);
			Future!(int) intFuture = Executors.submit(executor, intCallable);
			ConsoleLogger.trace("Return string : " ~ stringFuture.get(12.seconds));
			ConsoleLogger.trace("Return int : " ~ intFuture.get(5.seconds).to!string());
			ConsoleLogger.trace("  end. ");
		} catch (InterruptedException e) {
			ConsoleLogger.trace("catch InterruptedException");
			ConsoleLogger.trace(e.toString());
		} catch (ExecutionException e) {
			ConsoleLogger.trace("catch ExecutionException");
			ConsoleLogger.trace(e.toString());
		} catch (TimeoutException e) {
			ConsoleLogger.trace("catch TimeoutException");
			ConsoleLogger.trace(e.toString());
		}
	}
}



class StringCallable : Callable!(string) {
	string call() {

		ConsoleLogger.tracef("sleeping 5 seconds in thread %s...", Thread.getThis().name);
		ThreadEx.sleep(5.seconds);
		// LockSupport.park(5.seconds);
		ConsoleLogger.trace("sleep 5 seconds done !");
		return "anyString";
	}
}


class IntCallable : Callable!(int) {
	int call() {
		ConsoleLogger.tracef("sleeping 3 seconds in thread %s...", Thread.getThis().name);
		ThreadEx.sleep(3.seconds);
		// LockSupport.park(3.seconds);
		ConsoleLogger.trace("sleep 3 seconds done !");
		return 100;
	}
}