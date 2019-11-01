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
        if(isStopping()) {
            // version (HUNT_IO_DEBUG) 
            warningf("The event loop %d is stopping.", number);
            return;
        }
        
        version (HUNT_IO_DEBUG) 
        tracef("Stopping event loop %d...", number);
        if(isSelfThread()) {
            version (HUNT_IO_DEBUG) infof("Try to stop the event loop %d in another thread", number);
            auto stopTask = task(&stop);
            taskPool.put(stopTask);
        } else {
            super.stop();
        }
    }

}
