module test.CompletableFutureTest;

import hunt.Assert;
import hunt.Exceptions;
import hunt.concurrency.thread;
import hunt.concurrency.CompletableFuture;
import hunt.concurrency.atomic;
import hunt.logging.ConsoleLogger;
import hunt.util.Common;
import hunt.util.DateTime;

import core.atomic;
import core.thread;
import core.time;
import std.random;

alias assertTrue = Assert.assertTrue;
alias assertFalse = Assert.assertFalse;
alias assertThat = Assert.assertThat;
alias assertEquals = Assert.assertEquals;
alias assertNotNull = Assert.assertNotNull;
alias assertNull = Assert.assertNull;

import hunt.String;


/**
http://www.importnew.com/28319.html
https://mahmoudanouti.wordpress.com/2018/01/26/20-examples-of-using-javas-completablefuture/
https://github.com/manouti/completablefuture-examples
*/
class CompletableFutureTest {

    // void testCompletedFuture01() {
    //     CompletableFuture!String cf = AbstractCompletableFuture.completedFuture(new String("message"));
    //     assertTrue(cf.isDone());
    //     assertEquals(new String("message"), cf.getNow(null));
    // }

    void testRunAsync() {
        CompletableFuture!Void cf = AbstractCompletableFuture.runAsync(() {
            assertTrue(ThreadEx.currentThread().isDaemon());
            // FIXME: Needing refactor or cleanup -@zxp at 5/2/2019, 10:41:12 PM
            // 
            randomSleep();
        });
        assertFalse(cf.isDone());
        sleepEnough();
        assertTrue(cf.isDone());
    }


    private static void randomSleep() {
        try {
            int r = uniform(0, 1000);
            tracef("sleeping %d msecs", r);
            Thread.sleep(r.msecs);
        } catch (InterruptedException e) {
            // ...
        }
    }

    private static void sleepEnough() {
        try {
            trace("sleeping 2 secondes");
            Thread.sleep(2.seconds);
        } catch (InterruptedException e) {
            // ...
        }
    }
}
