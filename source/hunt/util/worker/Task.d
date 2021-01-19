module hunt.util.worker.Task;

import core.atomic;
import hunt.logging.ConsoleLogger;

enum TaskStatus : ubyte {
    Ready,
    Processing,
    Terminated,
    Done
}

/**
 * 
 */
abstract class Task {
    protected shared TaskStatus _status;

    uint id;

    this() {
        _status = TaskStatus.Ready;
    }

    TaskStatus status() {
        return _status;
    }

    bool isReady() {
        return _status == TaskStatus.Ready;
    }

    bool isBusy() {
        return _status == TaskStatus.Processing;
    }

    bool isTerminated() {
        return _status == TaskStatus.Terminated;
    }

    bool isDone() {
        return _status == TaskStatus.Done;
    }

    void stop() {
        
        version(HUNT_IO_DEBUG) {
            tracef("The task status: %s", _status);
        }

        if(!cas(&_status, TaskStatus.Processing, TaskStatus.Terminated) && 
            !cas(&_status, TaskStatus.Ready, TaskStatus.Terminated)) {
            version(HUNT_IO_DEBUG) {
                warningf("The task status: %s", _status);
            }
        }
    }

    void finish() {
        version(HUNT_IO_DEBUG) {
            tracef("The task status: %s", _status);
        }

        if(cas(&_status, TaskStatus.Processing, TaskStatus.Done) || 
            cas(&_status, TaskStatus.Ready, TaskStatus.Done)) {
            version(HUNT_IO_DEBUG) {
                infof("The task done.");
            }
        } else {
            version(HUNT_IO_DEBUG) {
                warningf("The task status: %s", _status);
            }
        }
    }

    protected void doExecute();

    void execute() {
        if(cas(&_status, TaskStatus.Ready, TaskStatus.Processing)) {
            version(HUNT_DEBUG) {
                tracef("Task %d executing... status: %s", id, _status);
            }
            doExecute();
        } else {
            version(HUNT_DEBUG) {
                warningf("Failed to execute task %d. It's status: %s", id, _status);
            }
        }
    }
}