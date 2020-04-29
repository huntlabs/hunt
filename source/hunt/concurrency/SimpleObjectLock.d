module hunt.concurrency.SimpleObjectLock;

import core.time;
import core.sync.mutex;
import core.sync.condition;

/**
 * 
 */
class SimpleObjectLock {

    private Mutex _mutex;
    private Condition _condition;

    this() {
        _mutex = new Mutex();
        _condition = new Condition(_mutex);
    }

    void wait() {
        _mutex.lock();
        scope(exit) {
            _mutex.unlock();
        }
        _condition.wait();
    }

    void wait(Duration value) {
        _mutex.lock();
        scope(exit) {
            _mutex.unlock();
        }
        _condition.wait(value);
    }

    void notify() {
        _mutex.lock();
        scope(exit) {
            _mutex.unlock();
        }
        _condition.notify();
    }

    void notifyAll() {
        _mutex.lock();
        scope(exit) {
            _mutex.unlock();
        }
        _condition.notifyAll();
    }
}