module test.ThreadTest;

import hunt.concurrent.thread;
import hunt.logging.ConsoleLogger;

class ThreadTest {

    void testBasic01() {
        int x = 0;

        new Thread(
        {
            x++;
        }).start().join();
        assert( x == 1 );

        Thread ex = Thread.getThis();
        assert(ex !is null);
    }
}