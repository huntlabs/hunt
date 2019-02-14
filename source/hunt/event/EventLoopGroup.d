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

module hunt.event.EventLoopGroup;

import hunt.system.Memory;
import hunt.event.EventLoop;
import hunt.logging;

class EventLoopGroup {

    this(size_t size = (totalCPUs - 1)) {
        size_t _size = size > 0 ? size : 1;
        eventLoopPool = new EventLoop[_size];

        foreach (i; 0 .. _size) {
            eventLoopPool[i] = new EventLoop();
        }
    }

    /**
        timeout: in millisecond
    */
    void start(long timeout = -1) {
        if (_started)
            return;
        _started = true;
        foreach (pool; eventLoopPool) {
            pool.runAsync(timeout);
        }
    }

    void stop() {
        version (HUNT_DEBUG)
            trace("stopping EventLoopGroup...");
        if (!_started)
            return;
        foreach (pool; eventLoopPool) {
            pool.stop();
        }
        _started = false;

        version (HUNT_DEBUG)
            trace("EventLoopGroup stopped.");
    }

    @property size_t size() {
        return eventLoopPool.length;
    }

    EventLoop nextLoop() {
        import core.atomic;
        size_t index = atomicOp!"+="(_loopIndex, 1);
        if(index > 10000) {
            index = 0;
            atomicStore(_loopIndex, 0);
        }
        index %= eventLoopPool.length;
        return eventLoopPool[index];
    }
    private shared int _loopIndex;

    EventLoop opIndex(size_t index) {
        auto i = index % eventLoopPool.length;
        return eventLoopPool[i];
    }

    int opApply(scope int delegate(EventLoop) dg) {
        int ret = 0;
        foreach (pool; eventLoopPool) {
            ret = dg(pool);
            if (ret)
                break;
        }
        return ret;
    }

private:
    bool _started;
    EventLoop[] eventLoopPool;
}
