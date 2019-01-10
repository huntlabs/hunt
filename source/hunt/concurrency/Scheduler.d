/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2018-2019 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.concurrency.Scheduler;

import hunt.util.Common;
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
