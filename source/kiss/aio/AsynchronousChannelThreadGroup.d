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

import core.thread;

import std.parallelism;
import std.stdio;
import core.sync.mutex; 


class AsynchronousChannelThreadGroup {


public:
    this (int timeout , int io_numbers, int work_numbers )
    {   

        lock = new Mutex();
      
        _ioThreadNum = io_numbers;
        _ioThreadIndex = 0;

        _workThreadNum = work_numbers;
        _workThreadIndex = 0;


        _workSelector = new AsynchronousChannelSelector[work_numbers];
        for(int i = 0; i < work_numbers; i++)
            _workSelector[i] = new AsynchronousChannelSelector(timeout);


        _ioSelector = new AsynchronousChannelSelector[io_numbers];
        for(int i = 0; i < io_numbers; i++)
            _ioSelector[i] = new AsynchronousChannelSelector(timeout);



    }

    ~this()
    {
		_workSelector.destroy();
    }


    static open(int timeout = 10, int io_numbers = 1, int work_numbers = totalCPUs - 1) 
    {
        return new AsynchronousChannelThreadGroup(timeout,  io_numbers, work_numbers); 
    }


    void start()
	{
        writeln("AsynchronousChannelThreadGroup start");

		foreach (ref t; _workSelector)
			t.start();

        foreach (ref t; _ioSelector)
			t.start();
            
	}

	void stop()
	{

		foreach (ref t; _workSelector)
			t.stop();
        foreach (ref t; _ioSelector)
			t.stop();
	}

	void wait()
	{

		foreach (ref t; _workSelector)
			t.wait();
        foreach (ref t; _ioSelector)
			t.wait();
	}


 
    AsynchronousChannelSelector getIOSelector()
    {
        long r = _ioThreadIndex % _ioThreadNum;
        _ioThreadIndex ++ ;
		return _ioSelector[cast(size_t) r]; 
    }

    AsynchronousChannelSelector getWorkSelector()
    {
        long r;
        synchronized(lock){
            r = _workThreadIndex % _workThreadNum;
            _workThreadIndex ++ ;
        }
		return _workSelector[cast(size_t) r]; 
    }
    


private:

    Mutex lock;


    int _workThreadNum;
    int _workThreadIndex;


    int _ioThreadNum ;
    int _ioThreadIndex ;


    AsynchronousChannelSelector[] _workSelector;
    AsynchronousChannelSelector[] _ioSelector;

}