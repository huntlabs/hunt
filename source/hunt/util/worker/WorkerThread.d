module hunt.util.worker.WorkerThread;

import hunt.util.worker.Task;
import hunt.util.worker.Worker;

import core.thread;
import core.sync.condition;
import core.sync.mutex;
import std.conv; 

import hunt.logging.ConsoleLogger;


private enum WorkerState {
    Idle,
    Busy,
    Stopped
}

/**
 *
 */ 
class WorkerThread : Thread {

    private WorkerState _state;
    private size_t _index;
    private Task _task;
    private Worker _worker;
    
    private Condition _condition;
    private Mutex _mutex;

    
    /* For autonumbering anonymous threads. */
    // private static shared int threadInitNumber = 0;
    // private static int nextThreadNumber() {
    //     return core.atomic.atomicOp!"+="(threadInitNumber, 1);
    // }

    this(Worker worker, size_t index, size_t stackSize = 0) {
        _worker = worker;
        _index = index;
        _state = WorkerState.Idle;
        _mutex = new Mutex();
        _condition = new Condition(_mutex);
        this.name = "WorkerThread-" ~ _index.to!string();
        super(&run, stackSize);
    }

    void stop() {
        _state = WorkerState.Stopped;
    }

    bool isBusy() {
        return _state == WorkerState.Busy;
    }

    size_t index() {
        return _index;
    }

    void attatch(Task task) {
        if(_state == WorkerState.Idle) {

            _mutex.lock();
            scope(exit) {
                _mutex.unlock();
            }

            _task = task;
            _condition.notify();
        } else {
            warningf("WorkerThread %s is unavailable.", this.name());
        }
    }

    private void run() nothrow {
        while(_state != WorkerState.Stopped) {

            try {
                doRun();
            } catch(Throwable ex) {
                warning(ex);
            }

            _worker.setWorkerThreadAvailable(_index);
        }
    }

    private void doRun() {

        version(HUNT_DEBUG) trace("Running");

        _mutex.lock();
        scope(exit) {
            _state = WorkerState.Idle;
            _mutex.unlock();
        }

        _condition.wait();
        _state = WorkerState.Busy;
        Task task = _task;

        if(task is null) {
            warningf("No task attatch in ", this.name());
        } else {
            task.execute();
        }
    }

}

