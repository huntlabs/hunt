/*
 * KISS - A refined core library for dlang
 *
 * Copyright (C) 2015-2017  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
module kiss.aio.AsynchronousChannelSelector;

import kiss.aio.AbstractPoll;
import kiss.aio.task;

import core.thread;
import std.experimental.logger.core;
import std.conv;
import std.exception;
import std.stdio;

class AsynchronousChannelSelector : Thread {
public:
    this(int timeout)
    {
        _timeout = timeout;
        _isRunning = false;
        version(linux)
        {
            import kiss.aio.EpollA;
            _poll = new EpollA();
        }
        super(&run);
    }

    void start()
    {
        if(_isRunning)
        {
			log(LogLevel.warning , "already started");
			return ;
		}
        super.start();
    }

    void run()
    {
        _isRunning = true;
        _threadID = Thread.getThis.id();
        log(LogLevel.info , _threadID.to!string ~ " thread started");
        while(_isRunning)
        {
            _poll.poll(_timeout);
            doTaskList();
        }
        _threadID = ThreadID.init;
        _isRunning = false;
    }

    void stop()
    {
        if (_isRunning)
        {
            _poll.wakeUp();
            _isRunning = false;
        }
    }

    void wait()
    {
        super.join();
    }

    void addTask(bool MustInQueue = true)(AbstractTask task)
    {
        static if(!MustInQueue) {
            if (isInLoopThread())
            {
                task.job();
                return;
            }
        }
        synchronized (this)
        {
            _taskList.enQueue(task);
        }
        _poll.wakeUp();
    }


    void doTaskList()
    {
        import std.algorithm : swap;

        TaskQueue tmp;
        synchronized (this){
            swap(tmp, _taskList);
        }
        while (!tmp.empty)
        {
            auto fp = tmp.deQueue();
            try
            {
                fp.job();
            }
            catch (Error e){
                collectException({error(e.toString); writeln(e.toString());}());
                import core.stdc.stdlib;
                exit(-1);
            }
        }
    }

    bool isInThread()
    {
        if (!isRunning)
            return true;
        return _threadID == Thread.getThis.id();
    }
public:
    AbstractPoll _poll;
private:
    int _timeout;
    bool _isRunning;
    ThreadID _threadID;
    TaskQueue _taskList;


}
