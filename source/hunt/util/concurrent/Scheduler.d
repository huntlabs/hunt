module hunt.util.concurrent.Scheduler;

import hunt.lang.common;
import hunt.util.Lifecycle;

import core.time;

public interface Scheduler : Lifecycle {

    interface Future {
        bool cancel();
    }

    Future schedule(Runnable task, long delay, ref Duration unit);

    Future scheduleWithFixedDelay(Runnable task, long initialDelay, long delay, ref Duration unit);

    Future scheduleAtFixedRate(Runnable task, long initialDelay, long period, ref Duration unit);
}
