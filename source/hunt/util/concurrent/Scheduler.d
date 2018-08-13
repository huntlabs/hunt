module hunt.util.concurrent.Scheduler;

import hunt.util.common;
import hunt.util.LifeCycle;

import core.time;

public interface Scheduler : LifeCycle {

    interface Future {
        bool cancel();
    }

    Future schedule(Runnable task, long delay, ref Duration unit);

    Future scheduleWithFixedDelay(Runnable task, long initialDelay, long delay, ref Duration unit);

    Future scheduleAtFixedRate(Runnable task, long initialDelay, long period, ref Duration unit);
}
