module hunt.util.worker.MemoryQueue;

import hunt.util.worker.Task;
import hunt.util.worker.TaskQueue;

import core.sync.condition;
import core.sync.mutex;

import std.container.slist;

/**
 * It's a thread-safe queue
 */
class MemoryQueue : TaskQueue {
    private SList!Task _list;
    private Mutex _headLock;
    private Mutex _tailLock;

    /** Wait queue for waiting takes */
    private Condition _notEmpty;

    this() {
        _headLock = new Mutex();
        _tailLock = new Mutex();
        _notEmpty = new Condition(_headLock);
    }

    bool isEmpty() {
        return _list.empty();
    }

    Task pop() {
        _headLock.lock();
        scope (exit)
            _headLock.unlock();

        if(isEmpty()) {
            _notEmpty.wait();
        }

        Task task = _list.front();
        _list.removeFront();

        return task;
    }

    void push(Task task) {
        _tailLock.lock();
        scope (exit)
            _tailLock.unlock();

        _list.insert(task);

        _notEmpty.notify();
    }
}

// class MemoryQueue : TaskQueue {
//     private SList!Task _list;
//     private Condition _condition;
//     private Mutex _mutex;

//     this() {
//         _mutex = new Mutex();
//         _condition = new Condition(_mutex);
//     }

//     bool isEmpty() {
//         return _list.empty();
//     }

//     Task pop() {
//         _mutex.lock();
//         scope(exit) {
//             _mutex.unlock();
//         }

//         if(isEmpty()) {
//             _condition.wait();
//         }

//         Task task = _list.front();
//         _list.removeFront();

//         return task;
//     }

//     void push(Task task) {
//         _mutex.lock();
//         scope(exit) {
//             _mutex.unlock();
//         }

//         _list.insert(task);

//         _condition.notifyAll();
//     }
// }