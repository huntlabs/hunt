module test.ThreadPoolExecutorTest;

import hunt.concurrency.AbstractExecutorService;
import hunt.concurrency.Exceptions;
import hunt.concurrency.Executors;
import hunt.concurrency.ExecutorService;
import hunt.concurrency.Future;
import hunt.concurrency.LinkedBlockingQueue;
import hunt.concurrency.ThreadFactory;
import hunt.concurrency.ThreadPoolExecutor;
import hunt.concurrency.thread;

import hunt.util.DateTime;
import hunt.Exceptions;
import hunt.util.Common;
import hunt.logging.ConsoleLogger;

import core.thread;
import core.time;
import std.conv;
import std.stdio;

class ThreadPoolExecutorTest {

	void testBasicOperatoins01() {
		// ThreadEx tx = new ThreadEx(&doBasicOperatoins01);
		// tx.start();

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

	// https://www.journaldev.com/1069/threadpoolexecutor-java-thread-pool-example-executorservice
	// void test02() {
	// 	doTest02();
	// }

	// void test02() {

	// 	ExecutorService executor = Executors.newFixedThreadPool(5);
	// 	for (int i = 0; i < 10; i++) {
	// 		Runnable worker = new WorkerThread(i.to!string());
	// 		executor.execute(worker);
	// 	}
	// 	executor.shutdown();
	// 	while (!executor.isTerminated()) {
	// 	}
	// 	trace("Finished all threads");
	// }

	void test03() {
		//RejectedExecutionHandler implementation
		RejectedExecutionHandlerImpl rejectionHandler = new RejectedExecutionHandlerImpl();
		//Get the ThreadFactory implementation to use
		ThreadFactory threadFactory = Executors.defaultThreadFactory();
		//creating the ThreadPoolExecutor
		ThreadPoolExecutor executorPool = new ThreadPoolExecutor(2, 4, 10.seconds,
				new LinkedBlockingQueue!(Runnable)(2), threadFactory, rejectionHandler);
		//start the monitoring thread
		MyMonitorThread monitor = new MyMonitorThread(executorPool, 3);
		Thread monitorThread = new Thread(() {
			monitor.run();
		});
		monitorThread.start();
		//submit work to the thread pool
		for (int i = 0; i < 10; i++) {
			executorPool.execute(new WorkerThread("cmd" ~ i.to!string));
		}

		Thread.sleep(25.seconds);
		//shut down the pool

		warning(executorPool.toString());
		executorPool.shutdown();
		//shut down the monitor thread

		while(executorPool.getPoolSize() > 0) {
			warning(executorPool.toString());
			Thread.sleep(15.seconds);
		}

		monitor.shutdown();
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

class WorkerThread : Runnable {

	private string command;

	this(string s) {
		this.command = s;
	}

	override void run() {
		trace(Thread.getThis().name() ~ " Start. Command = " ~ command);
		processCommand();
		trace(Thread.getThis().name() ~ " End. Command = " ~ command);
	}

	private void processCommand() {
		try {
			Thread.sleep(5.seconds);
		} catch (InterruptedException e) {
			warning(e);
		}
	}

	override string toString() {
		return this.command;
	}
}

class RejectedExecutionHandlerImpl : RejectedExecutionHandler {

	override void rejectedExecution(Runnable r, ThreadPoolExecutor executor) {
		warning((cast(Object)r).toString() ~ " is rejected");
	}

}

class MyMonitorThread : Runnable {
	private ThreadPoolExecutor executor;
	private int delay;
	private bool isRunning = true;

	this(ThreadPoolExecutor executor, int delay) {
		this.executor = executor;
		this.delay = delay;
	}

	void shutdown() {
		this.isRunning = false;
	}

	override void run() {

		while (isRunning) {
			tracef("[monitor] [%d/%d] Active: %d, Completed: %d, Task: %d, isShutdown: %s, isTerminated: %s",
					this.executor.getPoolSize(),
					this.executor.getCorePoolSize(), this.executor.getActiveCount(),
					this.executor.getCompletedTaskCount(), this.executor.getTaskCount(),
					this.executor.isShutdown(), this.executor.isTerminated());
			try {
				Thread.sleep(delay.seconds);
			} catch (InterruptedException e) {
				warning(e);
			}
		}

	}
}
