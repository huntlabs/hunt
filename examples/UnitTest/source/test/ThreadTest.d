module test.ThreadTest;

import hunt.concurrent.thread;
import hunt.logging.ConsoleLogger;
import hunt.util.UnitTest;

// import core.thread;

class ThreadTest {

    @Test
    void basic01() {
        int x = 0;

        new ThreadEx(
        {
            auto ex = ThreadEx.getThis();
            if(ex is null)
                ConsoleLogger.warning("ex is null");
            else
                ConsoleLogger.info(typeid(ex), " id=", ThreadEx.getThis().id);
            assert(ex !is null);
            x++;
        }).start().join();
        
        assert( x == 1 );

        auto ex = ThreadEx.getThis();
        if(ex is null)
            ConsoleLogger.warning("ex is null");
        else
            ConsoleLogger.info(typeid(ex), " id=", ThreadEx.getThis().id);
        assert(ex !is null);

    }
}