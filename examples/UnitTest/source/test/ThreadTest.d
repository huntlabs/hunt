module test.ThreadTest;

import hunt.concurrency.thread;
import hunt.concurrency.FutureTask;
import hunt.logging.ConsoleLogger;
import hunt.util.Common;
import hunt.util.UnitTest;

import core.thread;
import std.conv;
import std.stdio;


class ThreadTest {

    // @Test
    // void basic01() {
    //     int x = 0;

    //     new ThreadEx(
    //     {
    //         auto ex = Thread.getThis();
    //         if(ex is null)
    //             ConsoleLogger.warning("ex is null");
    //         else
    //             ConsoleLogger.info(typeid(ex), " id=", Thread.getThis().id);
    //         assert(ex !is null);
    //         x++;
    //     }).start().join();

    //     assert( x == 1 );

    //     auto ex = Thread.getThis();
    //     if(ex is null)
    //         ConsoleLogger.warning("ex is null");
    //     else
    //         ConsoleLogger.info(typeid(ex), " id=", Thread.getThis().id);
    //     assert(ex !is null);

    // }

    // void testLockSupport01() {
    //     ThreadEx tx;
    //     tx = new ThreadEx(
    //     {
    //         tracef("runing thread[id=%d, tid=%d]", tx.id(), getTid());
    //         LockSupport.unpark(tx);  
    //         trace("step a");  
    //         LockSupport.park();  
    //         trace("step b");  
    //         trace("parking ", 10.seconds);
    //         LockSupport.park(10.seconds);  
    //         trace("step c");  
    //     });
    //     tx.start();
    //     // tx.isDaemon = true;
    //     // tx.run();

    //     tracef("wainting for sub thread [%d] in %s...", tx.id(), 5.seconds); 
    //     Thread.sleep(5.seconds) ;
    //     tracef("unparking sub thread [%d] ...", tx.id()); 
    //     LockSupport.unpark(tx);  
    //     thread_joinAll();
    //     trace("done.");  
    // }

    void testFutureTask01() {
        ThreadEx tx = new ThreadEx(&futureTask01);
        tx.start();

        thread_joinAll();
        trace("done.");  
    }

    /**
     See_also:
        https://www.cnblogs.com/dennyzhangdd/p/7010972.html
    */
    void futureTask01() {
        
        int count = 0;
        FutureTask!int futureTask = new FutureTask!int(new CallableTask());
        Thread futureTaskThread = new ThreadEx(futureTask);
        futureTaskThread.start();
        trace("futureTaskThread start！");

        // do somthing else
        trace("checking the target (3 seconds)");
        Thread.sleep(3.seconds);
        count += 10; 
        trace("checking done.");

        if (count >= 1) {
            trace("The target reached, so cancel the futureTask");
            futureTask.cancel(true); 
        }
        else {
            trace("The target doesn't reach, so querying more...");
            int i = futureTask.get(); // execute CallableTask
            trace("result: " ~ i.to!string());
            assert(i == 10);
        }
    }

    static class CallableTask : Callable!int {
        int call() {
            trace("task start... (10 seconds)");
            // FIXME: Needing refactor or cleanup -@zxp at 11/5/2018, 10:16:15 AM
            // to cancel the sleeping thread
            // Thread.sleep(10.seconds);
            // LockSupport.park(10.seconds);
            ThreadEx.sleep(10.seconds);
            trace("task done.");
            return 10;
        }
    }
}
