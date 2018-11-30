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

module hunt.event.EventLoopGroup;

import core.thread;
import std.parallelism;

import hunt.event.EventLoop;
import hunt.logging;

class EventLoopGroup {

    private long timeout = -1;

    this(uint size = (totalCPUs - 1)) {
        assert(size <= totalCPUs && size >= 0);
        this.size = size > 0 ? size : 1;
        foreach (i; 0 .. this.size) {
            auto loop = new EventLoop();
            _loops[loop] = new Thread(() { loop.run(timeout); });
        }
    }

    void start(long timeout = -1) {
        this.timeout = timeout;
        if (_started)
            return;
        _started = true;
        foreach (Thread t; _loops.values) {
            t.start();
        }
    }

    void stop() {
        version (HUNT_DEBUG) trace("stopping EventLoopGroup...");
        if (!_started)
            return;
        foreach (EventLoop loop; _loops.keys) {
            loop.stop();
        }
        _started = false;
        // wait();

        version (HUNT_DEBUG) trace("EventLoopGroup stopped.");
    }

    @property size_t length() {
        return size;
    }

    EventLoop opIndex(size_t index) {
        auto loops = _loops.keys;
        auto i = index % cast(size_t) loops.length;
        return loops[i];
    }

    void wait() {
        foreach (ref t; _loops.values) {
            t.join(false);
        }
    }

    int opApply(scope int delegate(EventLoop) dg) {
        int ret = 0;
        foreach (ref loop; _loops.keys) {
            ret = dg(loop);
            if (ret)
                break;
        }
        return ret;
    }

private:
    bool _started;
    uint size;

    Thread[EventLoop] _loops;

}
