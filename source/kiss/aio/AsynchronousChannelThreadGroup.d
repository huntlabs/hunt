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



int WORK_THREAD_INIT = 0;
int WORK_THREAD_READY = 1;
int WORK_THREAD_RUN = 2;


struct WORK_THREAD_POOL {
    AsynchronousChannelSelector worker;
    int status = 0;   
}

class AsynchronousChannelThreadGroup {


public:
    this(int timeout, int worker_numbers)
    {
        _workerNum = worker_numbers;
        _workerPool = new WORK_THREAD_POOL[worker_numbers];
        for(int i = 0; i < worker_numbers; i++)
            _workerPool[i].worker = new AsynchronousChannelSelector(timeout);
    }

    ~this()
    {
		_workerPool.destroy();
    }


    static open(int timeout = 10, int worker_numbers = totalCPUs) 
    {
        return new AsynchronousChannelThreadGroup(timeout, worker_numbers); 
    }


    void start()
	{
        log("AsynchronousChannelThreadGroup start");
        synchronized(this){
            foreach (ref t; _workerPool)
            {
                if (t.status == WORK_THREAD_READY)
                {
                    t.worker.start();   
                    t.status = WORK_THREAD_RUN;
                }
            }	 
        }
	}

	void stop()
	{
        synchronized(this){
            foreach (ref t; _workerPool)
            {
                if (t.status == WORK_THREAD_RUN)
                {
                    t.worker.stop();
                    t.status = WORK_THREAD_INIT;
                }
                else if(t.status == WORK_THREAD_READY)
                    t.status = WORK_THREAD_INIT;
            }
        }
	}

	void wait()
	{
		synchronized(this){
            foreach (ref t; _workerPool)
            {
                if (t.status == WORK_THREAD_RUN)
                {
                    t.worker.wait();
                    t.status = WORK_THREAD_INIT;
                }
            }
        }
	}


 
    AsynchronousChannelSelector getWorkSelector()
    {
        synchronized(this){
            uint r = cast(uint)(_workIndex % _workerNum);
            _workIndex ++ ;
            if(_workerPool[r].status == WORK_THREAD_INIT)
                _workerPool[r].status = WORK_THREAD_READY;
            return _workerPool[r].worker;
        } 
    }



private:
    int _workIndex;
    int _workerNum;


    WORK_THREAD_POOL[] _workerPool;


}