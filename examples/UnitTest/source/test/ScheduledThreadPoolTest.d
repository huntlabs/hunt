module test.ScheduledThreadPoolTest;

import hunt.concurrent.AbstractExecutorService;
import hunt.concurrent.exception;
import hunt.concurrent.Executors;
import hunt.concurrent.ExecutorService;
import hunt.concurrent.Future;
// import hunt.concurrent.LinkedBlockingQueue;
import hunt.concurrent.ScheduledThreadPoolExecutor;
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

class ScheduledThreadPoolTest {

    void testBasicOperatoins01() {
        ThreadEx tx = new ThreadEx(&doBasicOperatoins01);
        tx.start();

        // thread_joinAll();
        // trace("done.");  
    }

	void doBasicOperatoins01() {
        ScheduledThreadPoolExecutor executor = cast(ScheduledThreadPoolExecutor) Executors.newScheduledThreadPool(1);
        System.out.printf("Main: Starting at: %s\n", new Date());
        // for (int i = 0; i < 5; i++) {
        //     StringTask task = new StringTask("StringTask " ~ i);
        //     executor.schedule(task, i, TimeUnit.SECONDS);
        // }
        StringTask task1 = new StringTask("StringTask");
        VoidTask task2 = new VoidTask ("VoidTask");

        tracef("The time is : " ~ new Date());
        ScheduledFuture<string> f1 = executor.schedule(task1, 1, TimeUnit.SECONDS);
        
        tracef("The time is : " ~ new Date());
        ScheduledFuture<?> f2 = executor.schedule(task2, 5 , TimeUnit.SECONDS);
        
        tracef("The time is : " ~ new Date());
        string str = f1.get();
        
        tracef("The time is : " ~ new Date() ~ "   =>" ~ str);

        executor.shutdown();

        try {
            executor.awaitTermination(1, TimeUnit.DAYS);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.printf("Main: Ends at: %s\n", new Date());
    }
}

class StringTask : Callable<string> {

    private string name;

    this(string name) {
        super();
        this.name = name;
    }

    string call() {
        System.out.printf("%s: Starting at : %s\n", name, new Date());
        return "hello world";
    }
}


class VoidTask : Runnable
{
    private string name;
 
    VoidTask(string name) {
        this.name = name;
    }
     
    string getName() {
        return name;
    }
 
    void run()
    {
        try {
            tracef("Doing a task during : " ~ name ~ " - Time - " ~ new Date());
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }
}