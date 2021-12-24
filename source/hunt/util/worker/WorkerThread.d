module hunt.util.worker.WorkerThread;

import hunt.util.Closeable;
import hunt.util.ResoureManager;
import hunt.util.worker.Task;
import hunt.util.worker.Worker;

import hunt.logging;

import core.atomic;
import core.memory;
import core.thread;
import core.sync.condition;
import core.sync.mutex;
import std.conv;



enum WorkerThreadState {
    Idle,
    Busy, // occupied
    Stopped
}

bool inWorkerThread() {
    WorkerThread th = cast(WorkerThread) Thread.getThis();
    return th !is null;
}

/**
 *
 */
class WorkerThread : Thread {

    private shared WorkerThreadState _state;
    private size_t _index;
    private Task _task;
    private Duration _timeout;

    private Condition _condition;
    private Mutex _mutex;

    this(size_t index, Duration timeout = 5.seconds, size_t stackSize = 0) {
        _index = index;
        _timeout = timeout;
        _state = WorkerThreadState.Idle;
        _mutex = new Mutex();
        _condition = new Condition(_mutex);
        this.name = "WorkerThread-" ~ _index.to!string();
        super(&run, stackSize);
    }

    void stop() {
        version(HUNT_IO_DEBUG) {
            infof("Stopping thread %s", this.name);
        }
        _state = WorkerThreadState.Stopped;

        _mutex.lock();
        scope (exit) {
            _mutex.unlock();
        }
        _condition.notify();
    }

    bool isBusy() {
        return _state == WorkerThreadState.Busy;
    }
    
    bool isIdle() {
        return _state == WorkerThreadState.Idle;
    }

    WorkerThreadState state() {
        return _state;
    }

    size_t index() {
        return _index;
    }

    Task task() {
        return _task;
    }

    bool attatch(Task task) {
        assert(task !is null);
        bool r = cas(&_state, WorkerThreadState.Idle, WorkerThreadState.Busy);

        if (r) {
            version(HUNT_IO_DEBUG) {
                infof("attatching task %d with thread %s", task.id, this.name);
            }

            _mutex.lock();
            scope (exit) {
                _mutex.unlock();
            }
            _task = task;
            _condition.notify();
            
        } else {
            warningf("%s is unavailable. state: %s", this.name(), _state);
        }

        return r;
    }

    private void run() nothrow {
        while (_state != WorkerThreadState.Stopped) {

            scope (exit) {
                version (HUNT_IO_DEBUG) {
                    tracef("%s Done. state: %s", this.name(), _state);
                }

                collectResoure();
                _task = null;

                if(_state != WorkerThreadState.Stopped) {
                    bool r = cas(&_state, WorkerThreadState.Busy, WorkerThreadState.Idle);
                    version(HUNT_IO_DEBUG) {
                        if(!r) {
                            warningf("Failed to set thread %s to Idle, its state is %s", this.name, _state);
                        }
                    }
                }
            } 

            try {
                doRun();
            } catch (Throwable ex) {
                warning(ex);
            } 
        }
        
        version (HUNT_DEBUG) tracef("%s Stopped. state: %s", this.name(), _state);
    }

    private bool _isWaiting = false;

    private void doRun() {
        _mutex.lock();
        
        Task task = _task;
        while(task is null && _state != WorkerThreadState.Stopped) {
            bool r = _condition.wait(_timeout);
            task = _task;

            version(HUNT_IO_DEBUG) {
                if(!r && _state == WorkerThreadState.Busy) {
                    if(task is null) {
                        warningf("No task attatched on a busy thread %s in %s, task: %s", this.name, _timeout);
                    } else {
                        warningf("more tests need for this status, thread %s in %s", this.name, _timeout);
                    }
                }
            }
        }

        _mutex.unlock();

        if(task !is null) {
            version(HUNT_IO_DEBUG) {
                tracef("Try to exeucte task %d in thread %s, its status: %s", task.id, this.name, task.status);
            }
            task.execute();
        }
    }
}
