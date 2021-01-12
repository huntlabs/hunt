module hunt.util.worker.WorkerThread;

import hunt.util.Closeable;
import hunt.util.ResoureManager;
import hunt.util.worker.Task;
import hunt.util.worker.Worker;

import hunt.logging.ConsoleLogger;

import core.memory;
import core.thread;
import core.sync.condition;
import core.sync.mutex;
import std.conv;


enum WorkerState {
    Idle,
    Busy,
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

    private WorkerState _state;
    private size_t _index;
    private Task _task;
    // private Worker _worker;

    private Condition _condition;
    private Mutex _mutex;

    // private Closeable[] _closeableObjects;

    /* For autonumbering anonymous threads. */
    // private static shared int threadInitNumber = 0;
    // private static int nextThreadNumber() {
    //     return core.atomic.atomicOp!"+="(threadInitNumber, 1);
    // }

    this(size_t index, size_t stackSize = 0) {
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

    WorkerState state() {
        return _state;
    }

    size_t index() {
        return _index;
    }

    void attatch(Task task) {
        if (_state == WorkerState.Idle) {

            _mutex.lock();
            scope (exit) {
                _mutex.unlock();
            }

            _task = task;
            _condition.notify();
        } else {
            warningf("WorkerThread %s is unavailable.", this.name());
        }
    }


    // void registerResoure(Closeable res) {
    //     // if (!inWorkerThread()) {
    //     //     warningf("Only the objects in worker thread [%s] can be closed automaticaly.",
    //     //             Thread.getThis().name());
    //     //     return;
    //     // }

    //     assert(res !is null);
    //     _closeableObjects ~= res;
    // }

    // private void collectResoure() nothrow {
    //     foreach (obj; _closeableObjects) {
    //         try {
    //             obj.close();
    //         } catch (Throwable t) {
    //             warning(t);
    //         }
    //     }
    //     _closeableObjects = null;
    //     GC.collect();
    //     GC.minimize();
    // }

    private void run() nothrow {
        while (_state != WorkerState.Stopped) {

        version (HUNT_IO_DEBUG) tracef("%s Running...", this.name());
            scope (exit) {
                collectResoure();
        version (HUNT_IO_DEBUG) tracef("%s Done.", this.name());
            }

            try {
                doRun();
            } catch (Throwable ex) {
                warning(ex);
            }

            // _worker.setWorkerThreadAvailable(_index);
        }
    }

    private void doRun() {
        _mutex.lock();
        scope (exit) {
            _state = WorkerState.Idle;
            _mutex.unlock();
        }

        _condition.wait();
        _state = WorkerState.Busy;
        Task task = _task;

        if (task is null) {
            warningf("No task attatch in ", this.name());
        } else {
            task.execute();
        }
    }

}
