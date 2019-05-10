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

interface Scheduler : Lifecycle {

    interface Future {
        bool cancel();
    }

    Future schedule(Runnable task, Duration delay);

    Future scheduleWithFixedDelay(Runnable task, Duration initialDelay, Duration delay);

    Future scheduleAtFixedRate(Runnable task, Duration initialDelay, Duration period);
}
