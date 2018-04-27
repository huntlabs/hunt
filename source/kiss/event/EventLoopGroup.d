module kiss.event.EventLoopGroup;

import core.thread;
import std.parallelism;

import kiss.event.EventLoop;

class EventLoopGroup
{
    this(uint size = (totalCPUs - 1))
    {
		assert(size <= totalCPUs && size > 0);

        size = size > 0 ? size : 1;
        foreach (i; 0 .. size)
        {
            auto loop = new EventLoop();
            _loops[loop] = new Thread(&loop.run);
        }
    }

    void start()
    {
        if (_started)
            return;
        foreach (ref t; _loops.values)
        {
            t.start();
        }
        _started = true;
    }

    void stop()
    {
        if (!_started)
            return;
        foreach (ref loop; _loops.keys)
        {
            loop.stop();
        }
        _started = false;
        wait();
    }

    @property size_t length()
    {
        return _loops.length;
    }

    // void addEventLoop(EventLoop lop)
    // {
    //     auto loop = new GroupMember(lop);
    //     auto th = new Thread(&loop.start);
    //     _loops[loop] = th;
    //     if (_started)
    //         th.start();
    // }

    EventLoop opIndex(size_t index)
    {
        return at(index);
    }

    EventLoop at(size_t index)
    {
        auto loops = _loops.keys;
        auto i = index % cast(size_t) loops.length;
        return loops[i];
    }

    void wait()
    {
        foreach (ref t; _loops.values)
        {
            t.join(false);
        }
    }

    int opApply(scope int delegate(EventLoop) dg)
    {
        int ret = 0;
        foreach (ref loop; _loops.keys)
        {
            ret = dg(loop);
            if (ret)
                break;
        }
        return ret;
    }

	private	EventLoop _mainLoop;
    
private:
    bool _started;

    Thread[EventLoop] _loops;

    // class GroupMember
    // {
    //     this(EventLoop loop)
    //     {
    //         _loop = loop;
    //     }

    //     void start()
    //     {
    //         _loop.join();
    //     }

    //     alias eventLoop this;

    //     @property EventLoop eventLoop()
    //     {
    //         return _loop;
    //     }

    // private:
    //     EventLoop _loop;
    // }
}
