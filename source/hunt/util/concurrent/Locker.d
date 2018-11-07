module hunt.util.concurrent.Locker;

import hunt.lang.common;
import hunt.lang.exception;

/**
 * <p>
 * This is a lock designed to protect VERY short sections of critical code.
 * Threads attempting to take the lock will wait until the lock is available,
 * thus it is important that the code protected by this lock is extremely simple
 * and non blocking.
 * </p>
 *
 * <pre>
 * try (SpinLock.Lock lock = locker.lock()) {
 * 	// something very quick and non blocking
 * }
 * </pre>
 */
class Locker {
    private enum bool SPIN = true; 

    private  bool _spin;
    // private  ReentrantLock _lock = new ReentrantLock();
    // private  AtomicReference!(Thread) _spinLockState = new AtomicReference<>(null);
    private  Lock _unlock; // = new Lock();

    this() {
        this(SPIN);
    }

    this(bool spin) {
        _unlock = new Lock();
        this._spin = spin;
    }

    Lock lock() {
        // if (_spin)
        //     spinLock();
        // else
        //     concLock();
        return _unlock;
    }

    // private void spinLock() {
    //     Thread current = Thread.currentThread();
    //     while (true) {
    //         // Using test-and-test-and-set for better performance.
    //         Thread locker = _spinLockState.get();
    //         if (locker !is null || !_spinLockState.compareAndSet(null, current)) {
    //             if (locker == current)
    //                 throw new IllegalStateException("Locker is not reentrant");
    //             continue;
    //         }
    //         return;
    //     }
    // }

    private void concLock() {
        // if (_lock.isHeldByCurrentThread())
        //     throw new IllegalStateException("Locker is not reentrant");
        // _lock.lock();
    }

    bool isLocked() {
        // if (_spin)
        //     return _spinLockState.get() !is null;
        // else
        //     return _lock.isLocked();
        // implementationMissing();
        return false;
    }

    class Lock : AutoCloseable {
        override
        void close() {
            // if (_spin)
            //     _spinLockState.set(null);
            // else
            //     _lock.unlock();
        }
    }

    // void lock(Action0 action0) {
    //     try (Lock lock = lock()) {
    //         action0.call();
    //     }
    // }

    // !(T) T lock(Func0!(T) func0) {
    //     try (Lock lock = lock()) {
    //         return func0.call();
    //     }
    // }
}
