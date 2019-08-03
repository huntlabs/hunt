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

module hunt.event.EventLoop;

import hunt.io.channel.Common;
import hunt.event.selector;
import hunt.logging;

import core.thread;
import std.parallelism;

/**

*/
final class EventLoop : AbstractSelector {

    this() {
        super(0, 1);
    }

    this(size_t number, size_t divider) {
        super(number, divider);
    }


    override void stop() {
        if(!isRuning) {
            version (HUNT_DEBUG) trace("The event loop is not running.");
            return;
        }
        
        version (HUNT_DEBUG) trace("Stopping event loop...");
        if(isSelfThread()) {
            version (HUNT_DEBUG) info("Try to stop the event loop in another thread");
            auto stopTask = task(&stop);
            taskPool.put(stopTask);
        } else {
            super.stop();
        }
    }

}
