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

import hunt.event.selector;
import hunt.io.channel.Common;
import hunt.logging.ConsoleLogger;
import hunt.util.TaskPool;

import core.thread;
import std.parallelism;
import std.random;

alias HuntTaskPool = hunt.util.TaskPool.TaskPool;

/**
 * 
 */
final class EventLoop : AbstractSelector {

    this() {
        int id = uniform(0, 1024);
        super(id, 1);
    }

    this(HuntTaskPool pool) {
        int id = uniform(0, 1024);
        super(id, 1, pool);
    }

    this(size_t id, size_t divider, HuntTaskPool pool = null) {
        super(id, divider, pool);
    }

    override void stop() {
        if(isStopping()) {
            version (HUNT_IO_DEBUG) 
            warningf("The event loop %d is stopping.", getId());
            return;
        }
        
        version (HUNT_IO_DEBUG) 
        tracef("Stopping event loop %d...", getId());
        if(isSelfThread()) {
            version (HUNT_IO_DEBUG) infof("Try to stop the event loop %d in another thread", getId());
            auto stopTask = task(&stop);
            std.parallelism.taskPool.put(stopTask);
        } else {
            super.stop();
        }
    }

}