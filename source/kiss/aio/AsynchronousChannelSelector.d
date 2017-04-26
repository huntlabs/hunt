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

import kiss.aio.EpollA;
import kiss.aio.AsynchronousChannelBase;
import kiss.aio.ByteBuffer;
import kiss.aio.CompletionHandle;

import core.sys.posix.signal;
import core.thread;

import std.experimental.logger;
import std.stdio;

class AsynchronousChannelSelector : Thread {
public:
    this (int timeout = 50)
    {
        _epoll = new EpollA();
        _isRunning = false;
        _timeout = timeout;
        super(&run);
    }


    void start()
    {
        if(_isRunning)
        {
			log(LogLevel.warning , "already started");
			return ;
		}
        _isRunning = true;
        super.start();
    }

    void stop()
    {
        _isRunning = false;
    }

    void wait()
    {
        super.join();
    }

    void run() {
        writeln("Thread run");
        while(_isRunning)
        {
            _epoll.poll(_timeout);
        }
    }


public:
    EpollA _epoll;
private:
    int _timeout;

    bool _isRunning;
    


}