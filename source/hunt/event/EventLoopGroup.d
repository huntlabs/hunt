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
import hunt.util.Lifecycle;

import core.atomic;

/**
 * 
 */
class EventLoopGroup : Lifecycle {

    this(size_t size = (totalCPUs - 1)) {
        size_t _size = size > 0 ? size : 1;
        _eventLoops = new EventLoop[_size];

        foreach (i; 0 .. _size) {
            _eventLoops[i] = new EventLoop(i, _size);
        }
    }

    void start() {
        start(-1);
    }

    /**
        timeout: in millisecond
    */
    void start(long timeout) {
        if (cas(&_isRunning, false, true)) {
            foreach (EventLoop pool; _eventLoops) {
                pool.runAsync(timeout);
            }
        }
    }

    void stop() {
        if (!cas(&_isRunning, true, false))
            return;

        version (HUNT_IO_DEBUG)
            trace("stopping EventLoopGroup...");
        foreach (EventLoop pool; _eventLoops) {
            pool.stop();
        }

        version (HUNT_IO_DEBUG)
            trace("EventLoopGroup stopped.");
    }

	bool isRunning() {
        return _isRunning;
    }

    bool isReady() {
        
        foreach (EventLoop pool; _eventLoops) {
            if(!pool.isReady()) return false;
        }

        return true;
    }

    @property size_t size() {
        return _eventLoops.length;
    }

    EventLoop nextLoop(size_t factor) {
       return _eventLoops[factor % _eventLoops.length];
    }

    EventLoop nextLoop() {
        size_t index = atomicOp!"+="(_loopIndex, 1);
        if(index > 10000) {
            index = 0;
            atomicStore(_loopIndex, 0);
        }
        index %= _eventLoops.length;
        return _eventLoops[index];
    }

    EventLoop opIndex(size_t index) {
        auto i = index % _eventLoops.length;
        return _eventLoops[i];
    }

    int opApply(scope int delegate(EventLoop) dg) {
        int ret = 0;
        foreach (pool; _eventLoops) {
            ret = dg(pool);
            if (ret)
                break;
        }
        return ret;
    }

private:
    shared int _loopIndex;
    shared bool _isRunning;
    EventLoop[] _eventLoops;
}
