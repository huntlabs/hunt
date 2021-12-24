module hunt.util.queue.SimpleQueue;

import hunt.logging;
import hunt.util.queue.Queue;

import core.atomic;
import core.sync.condition;
import core.sync.mutex;
import core.time;
import core.thread;

import std.container.dlist;


/**
 * It's a thread-safe queue
 */
class SimpleQueue(T) : Queue!(T) {
    private DList!T _list;
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
        _headLock.lock();
        scope (exit)
            _headLock.unlock();

        return _list.empty();
    }

    override T pop() {
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
                    infof("Timeout in %s.", _timeout);
                }
                return T.init;
            }
        }

        if(_list.empty())   
            return T.init;

        T item = _list.front();
        _list.removeFront();

        return item;
    }

    override void push(T item) {
        _headLock.lock();
        scope (exit)
            _headLock.unlock();

        _list.insert(item);

        if(_isWaiting) {
            _notEmpty.notify();
        }
    }

    override void clear() {
        _headLock.lock();
        scope (exit)
            _headLock.unlock();
        
        _list.clear();
        _notEmpty.notify();
    }
}
