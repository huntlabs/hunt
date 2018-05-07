module kiss.event.EventLoop;

import kiss.event.core;
import kiss.event.selector;
import core.thread;
import kiss.event.task;
import kiss.exception;

/**

*/
final class EventLoop : AbstractSelector
{

    this()
    {
        super();
    }

    // deprecated("Using run instead!")
    void join()
    {
        run();
    }

    void run()
    {
        if (isRuning())
            throw new LoopException("The current eventloop is running!");
        _thread = Thread.getThis();
        onLoop(&onWeakUp);
    }

    override void stop()
    {
        _thread = null;
        super.stop();
    }

    bool isRuning()
    {
        return (_thread !is null);
    }

    bool isInLoopThread()
    {
        return isRuning() && _thread is Thread.getThis();
    }

    EventLoop postTask(AbstractTask task)
    {
        import std.experimental.logger;

        synchronized (this)
        {
            _queue.enQueue(task);
        }
        return this;
    }

    static AbstractTask createTask(alias fun, Args...)(Args args)
    {
        return newTask!(fun, Args)(args);
    }

    static AbstractTask createTask(F, Args...)(F delegateOrFp, Args args)
            if (is(typeof(delegateOrFp(args))))
    {
        return newTask(F, Args)(delegateOrFp, args);
    }

    protected void onWeakUp()
    {
        TaskQueue queue;
        synchronized (this)
        {
            queue = _queue;
            _queue = TaskQueue();
        }
        while (!queue.empty)
        {
            auto task = queue.deQueue();
            task.job();
        }
    }

private:
    Thread _thread;
    TaskQueue _queue;
}
