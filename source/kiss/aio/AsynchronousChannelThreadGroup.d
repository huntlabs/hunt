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

module kiss.aio.AsynchronousChannelThreadGroup;

import kiss.aio.AsynchronousChannelSelector;

import std.parallelism;
import std.experimental.logger.core;

class AsynchronousChannelThreadGroup {
public:
    this(int timeout, int worker_numbers)
    {
        _workerNum = worker_numbers;
        _workSelector = new AsynchronousChannelSelector[worker_numbers];
        for(int i = 0; i < worker_numbers; i++)
            _workSelector[i] = new AsynchronousChannelSelector(timeout);
    }

    ~this()
    {
		_workSelector.destroy();
    }


    static open(int timeout = 10, int worker_numbers = totalCPUs - 1) 
    {
        return new AsynchronousChannelThreadGroup(timeout, worker_numbers); 
    }


    void start()
	{
        log("AsynchronousChannelThreadGroup start");
		foreach (ref t; _workSelector)
			t.start();    
	}

	void stop()
	{

		foreach (ref t; _workSelector)
			t.stop();
	}

	void wait()
	{
		foreach (ref t; _workSelector)
			t.wait();
	}


 
    AsynchronousChannelSelector getWorkSelector()
    {
        long r = _workIndex % _workerNum;
        _workIndex ++ ;
		return _workSelector[cast(size_t) r]; 
    }



private:
    int _workIndex;
    int _workerNum;
    AsynchronousChannelSelector[] _workSelector;
}