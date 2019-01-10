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

import hunt.util.Memory;
import hunt.event.EventLoop;
import hunt.logging;

class EventLoopGroup {

    this(uint size = (totalCPUs - 1)) {
        assert(size <= totalCPUs && size >= 0);
        this._size = size > 0 ? size : 1;
        eventLoopPool = new EventLoop[this._size];

        foreach (i; 0 .. this._size) {
            eventLoopPool[i] = new EventLoop();
        }
    }

    void start(long timeout = -1) {
        if (_started)
            return;
        _started = true;
        foreach (i; 0 .. this._size) {
            eventLoopPool[i].runAsync(timeout);
        }
    }

    void stop() {
        version (HUNT_DEBUG)
            trace("stopping EventLoopGroup...");
        if (!_started)
            return;
        foreach (i; 0 .. this._size) {
            eventLoopPool[i].stop();
        }
        _started = false;

        version (HUNT_DEBUG)
            trace("EventLoopGroup stopped.");
    }

    @property size_t size() {
        return _size;
    }

    EventLoop nextLoop() {
        import core.atomic;
        int index = atomicOp!"+="(_loopIndex, 1);
        if(index > 10000) {
            index = 0;
            atomicStore(_loopIndex, 0);
        }
        index %= _size;
        return eventLoopPool[index];
    }
    private shared int _loopIndex;

    EventLoop opIndex(size_t index) {
        auto i = index % _size;
        return eventLoopPool[i];
    }

    int opApply(scope int delegate(EventLoop) dg) {
        int ret = 0;
        foreach (i; 0 .. this._size) {
            ret = dg(eventLoopPool[i]);
            if (ret)
                break;
        }
        return ret;
    }

private:
    bool _started;
    uint _size;

    EventLoop[] eventLoopPool;

}
