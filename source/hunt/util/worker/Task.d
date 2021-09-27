module hunt.util.worker.Task;

import hunt.util.queue;
import hunt.logging.ConsoleLogger;

import core.atomic;
import std.datetime;
import std.format;

enum TaskStatus : ubyte {
    Ready,
    Processing,
    Terminated,
    Done
}

alias TaskQueue = Queue!Task;
alias MemoryTaskQueue = SimpleQueue!Task;

/**
 * 
 */
abstract class Task {
    protected shared TaskStatus _status;

    size_t id;
    
    private MonoTime _createTime;
    private MonoTime _startTime;
    private MonoTime _endTime;

    this() {
        _status = TaskStatus.Ready;
        _createTime = MonoTime.currTime;
    }

    Duration survivalTime() {
        return _endTime - _createTime;
    }

    Duration executionTime() {
        return _endTime - _startTime;
    }

    Duration lifeTime() {
        if(_endTime > _createTime) {
            return survivalTime();
        } else {
            return MonoTime.currTime - _createTime;
        }
    }

    TaskStatus status() {
        return _status;
    }

    bool isReady() {
        return _status == TaskStatus.Ready;
    }

    bool isProcessing() {
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
            tracef("The task %d status: %s", id, _status);
        }

        if(cas(&_status, TaskStatus.Processing, TaskStatus.Done) || 
            cas(&_status, TaskStatus.Ready, TaskStatus.Done)) {
                
            _endTime = MonoTime.currTime;
            version(HUNT_IO_DEBUG) {
                infof("The task %d done.", id);
            }
        } else {
            version(HUNT_IO_DEBUG) {
                warningf("The task %d status: %s", _status, id);
                warningf("Failed to set the task status to Done: %s", _status);
            }
        }
    }

    protected void doExecute();

    void execute() {
        if(cas(&_status, TaskStatus.Ready, TaskStatus.Processing)) {
            version(HUNT_IO_DEBUG) {
                tracef("Task %d executing... status: %s", id, _status);
            }
            _startTime = MonoTime.currTime;
            scope(exit) {
                finish();
                version(HUNT_IO_DEBUG) {
                    infof("Task %d Done!", id);
                }
            }
            doExecute();
        } else {
            warningf("Failed to execute task %d. Its status is: %s", id, _status);
        }
    }

    override string toString() {
        return format("id: %d, status: %s", id, _status);
    }

}