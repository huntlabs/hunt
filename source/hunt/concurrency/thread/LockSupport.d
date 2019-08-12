/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2018-2019 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.concurrency.thread.LockSupport;

import core.atomic;
import core.thread;
import core.time;

import hunt.concurrency.thread.ThreadEx;
import hunt.Exceptions;
import hunt.logging.ConsoleLogger;
import hunt.util.DateTime;


/**
 * Basic thread blocking primitives for creating locks and other
 * synchronization classes.
 *
 * <p>This class associates, with each thread that uses it, a permit
 * (in the sense of the {@link java.util.concurrent.Semaphore
 * Semaphore} class). A call to {@code park} will return immediately
 * if the permit is available, consuming it in the process; otherwise
 * it <em>may</em> block.  A call to {@code unpark} makes the permit
 * available, if it was not already available. (Unlike with Semaphores
 * though, permits do not accumulate. There is at most one.)
 * Reliable usage requires the use of volatile (or atomic) variables
 * to control when to park or unpark.  Orderings of calls to these
 * methods are maintained with respect to volatile variable accesses,
 * but not necessarily non-volatile variable accesses.
 *
 * <p>Methods {@code park} and {@code unpark} provide efficient
 * means of blocking and unblocking threads that do not encounter the
 * problems that cause the deprecated methods {@code Thread.suspend}
 * and {@code Thread.resume} to be unusable for such purposes: Races
 * between one thread invoking {@code park} and another thread trying
 * to {@code unpark} it will preserve liveness, due to the
 * permit. Additionally, {@code park} will return if the caller's
 * thread was interrupted, and timeout versions are supported. The
 * {@code park} method may also return at any other time, for "no
 * reason", so in general must be invoked within a loop that rechecks
 * conditions upon return. In this sense {@code park} serves as an
 * optimization of a "busy wait" that does not waste as much time
 * spinning, but must be paired with an {@code unpark} to be
 * effective.
 *
 * <p>The three forms of {@code park} each also support a
 * {@code blocker} object parameter. This object is recorded while
 * the thread is blocked to permit monitoring and diagnostic tools to
 * identify the reasons that threads are blocked. (Such tools may
 * access blockers using method {@link #getBlocker(Thread)}.)
 * The use of these forms rather than the original forms without this
 * parameter is strongly encouraged. The normal argument to supply as
 * a {@code blocker} within a lock implementation is {@code this}.
 *
 * <p>These methods are designed to be used as tools for creating
 * higher-level synchronization utilities, and are not in themselves
 * useful for most concurrency control applications.  The {@code park}
 * method is designed for use only in constructions of the form:
 *
 * <pre> {@code
 * while (!canProceed()) {
 *   // ensure request to unpark is visible to other threads
 *   ...
 *   LockSupport.park(this);
 * }}</pre>
 *
 * where no actions by the thread publishing a request to unpark,
 * prior to the call to {@code park}, entail locking or blocking.
 * Because only one permit is associated with each thread, any
 * intermediary uses of {@code park}, including implicitly via class
 * loading, could lead to an unresponsive thread (a "lost unpark").
 *
 * <p><b>Sample Usage.</b> Here is a sketch of a first-in-first-out
 * non-reentrant lock class:
 * <pre> {@code
 * class FIFOMutex {
 *   private final AtomicBoolean locked = new AtomicBoolean(false);
 *   private final Queue!(Thread) waiters
 *     = new ConcurrentLinkedQueue<>();
 *
 *   void lock() {
 *     boolean wasInterrupted = false;
 *     // publish current thread for unparkers
 *     waiters.add(Thread.currentThread());
 *
 *     // Block while not first in queue or cannot acquire lock
 *     while (waiters.peek() != Thread.currentThread() ||
 *            !locked.compareAndSet(false, true)) {
 *       LockSupport.park(this);
 *       // ignore interrupts while waiting
 *       if (Thread.interrupted())
 *         wasInterrupted = true;
 *     }
 *
 *     waiters.remove();
 *     // ensure correct interrupt status on return
 *     if (wasInterrupted)
 *       Thread.currentThread().interrupt();
 *   }
 *
 *   void unlock() {
 *     locked.set(false);
 *     LockSupport.unpark(waiters.peek());
 *   }
 *
 *   static {
 *     // Reduce the risk of "lost unpark" due to classloading
 *     Class<?> ensureLoaded = LockSupport.class;
 *   }
 * }}</pre>
 *
 */
class LockSupport {
    private static Parker _parker;    
    private __gshared Parker[Thread] parkers;
    private shared static bool m_lock;

    private this() {} // Cannot be instantiated.

    static Parker getParker() {
        if(_parker is null) {
            Thread t = Thread.getThis();
            ThreadEx tx = cast(ThreadEx)t;
            if(tx !is null) {
                return tx.parker();
            } else {
                _parker = createParker(t);
            }
        }
        return _parker;
    }

    static Parker getParker(Thread t) {
        if(t is Thread.getThis())
            return getParker();
        
        ThreadEx tx = cast(ThreadEx)t;
        if(tx !is null) {
            return tx.parker();
        } else {
            Parker* itemPtr = t in parkers;
            if(itemPtr is null) {
                _parker = createParker(t);
            }

            return *itemPtr;
        }
    }

    private static Parker createParker(Thread t) {
        version(HUNT_DEBUG) info("creating a new parker for " ~ typeid(t).name);
        Parker p = Parker.allocate(t);

        while(!cas(&m_lock, false, true)) {
            // waitting...
        }

        parkers[t] = p;
        m_lock = false;

        return p;
    }

    static void removeParker() {
        removeParker(Thread.getThis);
        _parker = null;
    }

    static void removeParker(Thread t) {
        while(!cas(&m_lock, false, true)) {
        }
        parkers.remove(t);
        m_lock = false;
    }

    /**
     * Makes available the permit for the given thread, if it
     * was not already available.  If the thread was blocked on
     * {@code park} then it will unblock.  Otherwise, its next call
     * to {@code park} is guaranteed not to block. This operation
     * is not guaranteed to have any effect at all if the given
     * thread has not been started.
     *
     * @param thread the thread to unpark, or {@code null}, in which case
     *        this operation has no effect
     */
    static void unpark(Thread thread) {
        getParker(thread).unpark();
    }

    static void unpark() {
        getParker().unpark();
    }


    /**
     * Disables the current thread for thread scheduling purposes unless the
     * permit is available.
     *
     * <p>If the permit is available then it is consumed and the call
     * returns immediately; otherwise the current thread becomes disabled
     * for thread scheduling purposes and lies dormant until one of three
     * things happens:
     *
     * <ul>
     *
     * <li>Some other thread invokes {@link #unpark unpark} with the
     * current thread as the target; or
     *
     * <li>Some other thread {@linkplain Thread#interrupt interrupts}
     * the current thread; or
     *
     * <li>The call spuriously (that is, for no reason) returns.
     * </ul>
     *
     * <p>This method does <em>not</em> report which of these caused the
     * method to return. Callers should re-check the conditions which caused
     * the thread to park in the first place. Callers may also determine,
     * for example, the interrupt status of the thread upon return.
     */
    static void park() {
        getParker().park(Duration.zero);
    }

    static void park(Duration time) {
        getParker().park(time);
    }

    /**
     * Disables the current thread for thread scheduling purposes unless the
     * permit is available.
     *
     * <p>If the permit is available then it is consumed and the call returns
     * immediately; otherwise
     * the current thread becomes disabled for thread scheduling
     * purposes and lies dormant until one of three things happens:
     *
     * <ul>
     * <li>Some other thread invokes {@link #unpark unpark} with the
     * current thread as the target; or
     *
     * <li>Some other thread {@linkplain Thread#interrupt interrupts}
     * the current thread; or
     *
     * <li>The call spuriously (that is, for no reason) returns.
     * </ul>
     *
     * <p>This method does <em>not</em> report which of these caused the
     * method to return. Callers should re-check the conditions which caused
     * the thread to park in the first place. Callers may also determine,
     * for example, the interrupt status of the thread upon return.
     *
     * @param blocker the synchronization object responsible for this
     *        thread parking
     */
    static void park(Object blocker) {
        park(blocker, Duration.zero);
    }

    static void park(Object blocker, Duration time) {
        if (time >= Duration.zero) {
            Parker p = getParker();
            p.setBlocker(blocker);
            p.park(time);
            p.setBlocker(null);
        } else {
            warning("The time must be greater than 0.");
        }
    }

    /**
     * Disables the current thread for thread scheduling purposes, for up to
     * the specified waiting time, unless the permit is available.
     *
     * <p>If the permit is available then it is consumed and the call
     * returns immediately; otherwise the current thread becomes disabled
     * for thread scheduling purposes and lies dormant until one of four
     * things happens:
     *
     * <ul>
     * <li>Some other thread invokes {@link #unpark unpark} with the
     * current thread as the target; or
     *
     * <li>Some other thread {@linkplain Thread#interrupt interrupts}
     * the current thread; or
     *
     * <li>The specified waiting time elapses; or
     *
     * <li>The call spuriously (that is, for no reason) returns.
     * </ul>
     *
     * <p>This method does <em>not</em> report which of these caused the
     * method to return. Callers should re-check the conditions which caused
     * the thread to park in the first place. Callers may also determine,
     * for example, the interrupt status of the thread, or the elapsed time
     * upon return.
     *
     * @param blocker the synchronization object responsible for this
     *        thread parking
     * @param nanos the maximum number of nanoseconds to wait
     */
    
    deprecated("Using park(Object, Duration) instead.")
    static void parkNanos(Object blocker, long nanos) {
        if(nanos > 0) {
            park(blocker, dur!(TimeUnit.Nanosecond)(nanos));
        }
    }

    /**
     * Disables the current thread for thread scheduling purposes, for up to
     * the specified waiting time, unless the permit is available.
     *
     * <p>If the permit is available then it is consumed and the call
     * returns immediately; otherwise the current thread becomes disabled
     * for thread scheduling purposes and lies dormant until one of four
     * things happens:
     *
     * <ul>
     * <li>Some other thread invokes {@link #unpark unpark} with the
     * current thread as the target; or
     *
     * <li>Some other thread {@linkplain Thread#interrupt interrupts}
     * the current thread; or
     *
     * <li>The specified waiting time elapses; or
     *
     * <li>The call spuriously (that is, for no reason) returns.
     * </ul>
     *
     * <p>This method does <em>not</em> report which of these caused the
     * method to return. Callers should re-check the conditions which caused
     * the thread to park in the first place. Callers may also determine,
     * for example, the interrupt status of the thread, or the elapsed time
     * upon return.
     *
     * @param nanos the maximum number of nanoseconds to wait
     */
    deprecated("Using park(Duration) instead.")
    static void parkNanos(long nanos) {        
        if (nanos > 0) {
            getParker().park(nanos.nsecs);
        }
    }
    
    /**
     * Disables the current thread for thread scheduling purposes, until
     * the specified deadline, unless the permit is available.
     *
     * <p>If the permit is available then it is consumed and the call
     * returns immediately; otherwise the current thread becomes disabled
     * for thread scheduling purposes and lies dormant until one of four
     * things happens:
     *
     * <ul>
     * <li>Some other thread invokes {@link #unpark unpark} with the
     * current thread as the target; or
     *
     * <li>Some other thread {@linkplain Thread#interrupt interrupts} the
     * current thread; or
     *
     * <li>The specified deadline passes; or
     *
     * <li>The call spuriously (that is, for no reason) returns.
     * </ul>
     *
     * <p>This method does <em>not</em> report which of these caused the
     * method to return. Callers should re-check the conditions which caused
     * the thread to park in the first place. Callers may also determine,
     * for example, the interrupt status of the thread, or the current time
     * upon return.
     *
     * @param blocker the synchronization object responsible for this
     *        thread parking
     * @param deadline the absolute time, in milliseconds from the Epoch,
     *        to wait until
     */
    static void parkUntil(Object blocker, MonoTime deadline) {
        Parker p = getParker();
        p.setBlocker(blocker);
        p.park(deadline);
        p.setBlocker(null);
    }
    
    // deprecated("Using parkUntil(Object, Duration) instead.")
    // static void parkUntil(Object blocker, long deadline) {
    //     parkUntil(blocker, deadline.msecs);
    // }

    /**
     * Disables the current thread for thread scheduling purposes, until
     * the specified deadline, unless the permit is available.
     *
     * <p>If the permit is available then it is consumed and the call
     * returns immediately; otherwise the current thread becomes disabled
     * for thread scheduling purposes and lies dormant until one of four
     * things happens:
     *
     * <ul>
     * <li>Some other thread invokes {@link #unpark unpark} with the
     * current thread as the target; or
     *
     * <li>Some other thread {@linkplain Thread#interrupt interrupts}
     * the current thread; or
     *
     * <li>The specified deadline passes; or
     *
     * <li>The call spuriously (that is, for no reason) returns.
     * </ul>
     *
     * <p>This method does <em>not</em> report which of these caused the
     * method to return. Callers should re-check the conditions which caused
     * the thread to park in the first place. Callers may also determine,
     * for example, the interrupt status of the thread, or the current time
     * upon return.
     *
     * @param deadline the absolute time, in milliseconds from the Epoch,
     *        to wait until
     */
    static void parkUntil(MonoTime deadline) {
        getParker().park(deadline);
    }

    deprecated("Using parkUntil(Duration) instead.")
    static void parkUntil(long deadline) {
        parkUntil(MonoTime(deadline));
    }


    /**
     * Returns the blocker object supplied to the most recent
     * invocation of a park method that has not yet unblocked, or null
     * if not blocked.  The value returned is just a momentary
     * snapshot -- the thread may have since unblocked or blocked on a
     * different blocker object.
     *
     * @param t the thread
     * @return the blocker
     * @throws NullPointerException if argument is null
     */
    static Object getBlocker(Thread t) {
        return getParker(t).getBlocker();
    }

    /**
     * Returns the pseudo-randomly initialized or updated secondary seed.
     * Copied from ThreadLocalRandom due to package access restrictions.
     */
    // static final int nextSecondarySeed() {
    //     int r;
    //     Thread t = Thread.currentThread();
    //     if ((r = U.getInt(t, SECONDARY)) != 0) {
    //         r ^= r << 13;   // xorshift
    //         r ^= r >>> 17;
    //         r ^= r << 5;
    //     }
    //     else if ((r = java.util.concurrent.ThreadLocalRandom.current().nextInt()) == 0)
    //         r = 1; // avoid zero
    //     U.putInt(t, SECONDARY, r);
    //     return r;
    // }

    /**
     * Returns the thread id for the given thread.  We must access
     * this directly rather than via method Thread.getId() because
     * getId() has been known to be overridden in ways that do not
     * preserve unique mappings.
     */
    // static final long getThreadId(Thread thread) {
    //     return U.getLong(thread, TID);
    // }

}
