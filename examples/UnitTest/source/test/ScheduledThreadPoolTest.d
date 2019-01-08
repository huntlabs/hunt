module test.ScheduledThreadPoolTest;

import hunt.concurrent.AbstractExecutorService;
import hunt.concurrent.Delayed;
import hunt.concurrent.exception;
import hunt.concurrent.Executors;
import hunt.concurrent.ExecutorService;
import hunt.concurrent.Future;

import hunt.concurrent.ScheduledThreadPoolExecutor;
import hunt.concurrent.ThreadPoolExecutor;
import hunt.concurrent.thread;

import hunt.util.datetime;
import hunt.common;
import hunt.exception;
import hunt.logging.ConsoleLogger;

import core.thread;
import core.time;
import std.conv;
import std.stdio;

// https://www.cnblogs.com/huhx/p/baseusejavaScheduledExecutorService.html
class ScheduledThreadPoolTest {

    void testBasicOperatoins01() {
        ThreadEx tx = new ThreadEx(&doBasicOperatoins01);
        tx.start();

        // thread_joinAll();
        // trace("done.");  
    }

    void doBasicOperatoins01() {
        ScheduledThreadPoolExecutor executor = cast(ScheduledThreadPoolExecutor) Executors.newScheduledThreadPool(
                1);
        tracef("Main thread starting...");
        // for (int i = 0; i < 5; i++) {
        //     StringTask task = new StringTask("StringTask " ~ i);
        //     executor.schedule(task, i, TimeUnit.SECONDS);
        // }
        executor.scheduleAtFixedRate(new FixedRateTase(), Duration.zero, seconds(1));

        IntTask task3 = new IntTask("IntTask");
        VoidTask task2 = new VoidTask("VoidTask");
        StringTask task1 = new StringTask("StringTask");

        ScheduledFuture!(string) f1 = executor.schedule!(string)(task1, seconds(3));
        ScheduledFuture!(void) f2 = executor.schedule(task2, seconds(5));
        ScheduledFuture!(int) f3 = executor.schedule(task3, seconds(5));

        tracef("wainting for the result... ");
        string str = f1.get();
        tracef("get the result: " ~ str);

        executor.shutdown();

        try {
            executor.awaitTermination(days(1));
        } catch (InterruptedException e) {
            warning(e.msg);
        }
        tracef("Main thread: Ends");
    }
}

class FixedRateTase : Runnable {
    void run() {
        trace("running at fixed rate");
    }
}

class StringTask : Callable!string {

    private string name;

    this(string name) {
        this.name = name;
    }

    string call() {
        tracef("Running task %s, and return a result", name);
        return "hello world";
    }
}

class IntTask : Callable!int {

    private string name;

    this(string name) {
        this.name = name;
    }

    int call() {
        tracef("Running task %s, and return a result", name);
        return 100;
    }
}

class VoidTask : Runnable {
    private string name;

    this(string name) {
        this.name = name;
    }

    string getName() {
        return name;
    }

    void run() {
        try {
            tracef("Running task %s", name);
        } catch (Exception e) {
            warning(e.msg);
        }
    }
}
