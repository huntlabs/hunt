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

import core.thread;
import hunt.event.core;
import hunt.event.selector;
import hunt.event.task;
import hunt.logging;

import std.parallelism;
import core.thread;

/**

*/
final class EventLoop : AbstractSelector {
    private long timeout = -1;

    this() {
        super();
    }

    void run(long timeout = -1) {
        this.timeout = timeout;
        doRun();
    }

    void runAsync(long timeout = -1) {
        this.timeout = timeout;
        version (HUNT_DEBUG) trace("runAsync ...");
        // BUG: Reported defects -@zxp at 12/3/2018, 8:17:58 PM
        // The task may not be executed.
        // auto runTask = task(&run, timeout);
        // taskPool.put(runTask); // 
        Thread th = new Thread(&doRun);
        th.start();
    }

    private void doRun() {
        if (_running) {
            version (HUNT_DEBUG) warning("The current eventloop is running!");
        } else {
            version (HUNT_DEBUG) trace("running eventloop...");
            _thread = Thread.getThis();
            onLoop(&onWeakUp, timeout);
        }
    }

    override void stop() {
        if(!_running) {
            version (HUNT_DEBUG) trace("event loop has been stopped.");
            return;
        }
        
        version (HUNT_DEBUG) trace("Stopping event loop...");
        if(isLoopThread()) {
            auto stopTask = task(&stop);
            taskPool.put(stopTask);
        } else {
            _thread = null;
            super.stop();
            // dispose();
        }
    }

    // bool isRuning() {
    //     return (_thread !is null);
    // }

    bool isLoopThread() {
        return _thread is Thread.getThis();
    }

    EventLoop postTask(AbstractTask task) {
        synchronized (this) {
            _queue.enQueue(task);
        }
        return this;
    }

    static AbstractTask createTask(alias fun, Args...)(Args args) {
        return newTask!(fun, Args)(args);
    }

    static AbstractTask createTask(F, Args...)(F delegateOrFp, Args args)
            if (is(typeof(delegateOrFp(args)))) {
        return newTask(F, Args)(delegateOrFp, args);
    }

    protected void onWeakUp() {
        TaskQueue queue;
        synchronized (this) {
            queue = _queue;
            _queue = TaskQueue();
        }
        while (!queue.empty) {
            auto task = queue.deQueue();
            task.job();
        }
    }

private:
    Thread _thread;
    TaskQueue _queue;
}
