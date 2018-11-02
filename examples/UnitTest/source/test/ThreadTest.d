module test.ThreadTest;

import hunt.concurrent.thread;
import hunt.logging.ConsoleLogger;
import hunt.util.UnitTest;

import core.thread;
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

    void testLockSupport01() {
        ThreadEx tx;
        tx = new ThreadEx(
        {
            tracef("runing thread[id=%d, tid=%d]", tx.id(), getTid());
            LockSupport.unpark(tx);  
            trace("step a");  
            LockSupport.park();  
            trace("step b");  
            trace("parking ", 10.seconds);
            LockSupport.park(10.seconds);  
            trace("step c");  
        });
        tx.start();
        // tx.isDaemon = true;
        // tx.run();

        // Thread thread = Thread.getThis();  
        // LockSupport.unpark(thread);  
      
        // writeln("a");  
        // LockSupport.park();  
        // writeln("b");  
        // LockSupport.park();  
        // writeln("c");  
        tracef("wainting for sub thread [%d] in %s...", tx.id(), 5.seconds); 
        Thread.sleep(5.seconds) ;
        tracef("unparking sub thread [%d] ...", tx.id()); 
        LockSupport.unpark(tx);  
        thread_joinAll();
        trace("done.");  
    }
}