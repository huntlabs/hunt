module hunt.util.concurrency.MemoryQueue;

import hunt.util.concurrency.Task;
import hunt.util.concurrency.TaskQueue;

import core.sync.condition;
import core.sync.mutex;

import std.container.slist;

/**
 * 
 */
class MemoryQueue : TaskQueue {
    private SList!Task _list;
    private Condition _condition;
    private Mutex _mutex;

    this() {
        _mutex = new Mutex();
        _condition = new Condition(_mutex);
    }

    bool isEmpty() {
        return _list.empty();
    }

    Task pop() {
        _mutex.lock();
        scope(exit) {
            _mutex.unlock();
        }

        if(isEmpty()) {
            _condition.wait();
        }

        Task task = _list.front();
        _list.removeFront();

        return task;
    }

    void push(Task task) {
        _mutex.lock();
        scope(exit) {
            _mutex.unlock();
        }

        _list.insert(task);

        _condition.notifyAll();
    }
}

