/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.cn
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

/**

*/
final class EventLoop : AbstractSelector {

    this() {
        super();
    }

    void run(long timeout = -1) {
        if (_running) {
            version (HUNT_DEBUG) warning("The current eventloop is running!");
        } else {
            version (HUNT_DEBUG) info("running eventloop...");
            _thread = Thread.getThis();
            onLoop(&onWeakUp, timeout);
        }
    }

    void runAsync(long timeout = -1) {
        import std.parallelism;

        auto clientTask = task(&run, timeout);
        taskPool.put(clientTask);
    }


    override void stop() {
        _thread = null;
        super.stop();
    }

    bool isRuning() {
        return (_thread !is null);
    }

    bool isLoopThread() {
        return isRuning() && _thread is Thread.getThis();
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
