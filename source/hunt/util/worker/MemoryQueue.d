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
    private Duration _timeout;
    private bool _isWaiting = false;

    shared int _incomings = 0;
    shared int _outgoings = 0;

    /** Wait queue for waiting takes */
    private Condition _notEmpty;

    this(Duration timeout = 10.seconds) {
        _timeout = timeout;
        _headLock = new Mutex();
        _notEmpty = new Condition(_headLock);
    }

    override bool isEmpty() {
        return _list.empty();
    }

    size_t size() {
        version (HUNT_METRIC) {
            return _incomings - _outgoings;
        } else {
            throw new Exception("Unimplemented");
        }
    }

    override Task pop() {
        _headLock.lock();
        scope (exit) {
            _headLock.unlock();
        }

        if(isEmpty()) {
            _isWaiting = true;
            bool v = _notEmpty.wait(_timeout);
            _isWaiting = false;
            if(!v) {
                version (HUNT_IO_DEBUG) {
                    tracef("Timeout in %s. pop: %d, put: %d", _timeout, _outgoings, _incomings);
                }
                return null;
            }
        }

        version (HUNT_METRIC) {
            atomicOp!("+=")(_outgoings, 1);
        }

        Task task = _list.front();
        _list.removeFront();

        return task;
    }

    override void push(Task task) {
        _headLock.lock();
        scope (exit)
            _headLock.unlock();

        version (HUNT_METRIC) {
            uint id = atomicOp!("+=")(_incomings, 1);
        }

        _list.insert(task);

        if(_isWaiting)
            _notEmpty.notify();
    }


version (HUNT_METRIC) {
    override void inspect() {
        tracef("incomings: %d, outgoings: %d, size: %d", _incomings, _outgoings, size());
    }
}        
}
