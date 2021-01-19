module hunt.util.worker.MemoryQueue;

import hunt.util.worker.Task;
import hunt.util.worker.TaskQueue;

import hunt.logging.ConsoleLogger;

import core.atomic;
import core.sync.condition;
import core.sync.mutex;

import core.time;

import std.container.slist;

/**
 * It's a thread-safe queue
 */
class MemoryQueue : TaskQueue {
    private SList!Task _list;
    private Mutex _headLock;
    private Mutex _tailLock;
    private Duration _timeout;

    version (HUNT_DEBUG) {
    shared int putCounter;
    shared int popCounter;
    }

    /** Wait queue for waiting takes */
    private Condition _notEmpty;

    this(Duration timeout = 10.seconds) {
        _timeout = timeout;
        _headLock = new Mutex();
        _tailLock = new Mutex();
        _notEmpty = new Condition(_headLock);
    }

    override bool isEmpty() {
        return _list.empty();
    }

    override Task pop() {
        _headLock.lock();
        scope (exit)
            _headLock.unlock();

        if(isEmpty()) {
            bool v = _notEmpty.wait(_timeout);
            if(!v) {
                version (HUNT_DEBUG) {
                    tracef("Timeout in %s. pop: %d, put: %d", _timeout, popCounter, putCounter);
                }
                return null;
            }
        }

        version (HUNT_DEBUG) {
            atomicOp!("+=")(popCounter, 1);
        }

        Task task = _list.front();
        _list.removeFront();

        return task;
    }

    override void push(Task task) {
        _headLock.lock();
        scope (exit)
            _headLock.unlock();

        version (HUNT_DEBUG) {
            uint id = atomicOp!("+=")(putCounter, 1);
            task.id = id -1;
        }

        _list.insert(task);

        _notEmpty.notifyAll();
    }
}
