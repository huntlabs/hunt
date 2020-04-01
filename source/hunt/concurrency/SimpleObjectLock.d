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
        _condition.wait();
    }

    void wait(Duration value) {
        _condition.wait(value);
    }

    void notify() {
        _condition.notify();
    }

    void notifyAll() {
        _condition.notifyAll();
    }
}