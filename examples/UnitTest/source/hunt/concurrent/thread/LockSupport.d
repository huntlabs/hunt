module hunt.concurrent.thread.LockSupport;

import core.thread;
import core.time;

import hunt.concurrent.thread.ThreadEx;
import hunt.datetime;
import hunt.lang.exception;

import hunt.logging.ConsoleLogger;


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
 *   private final Queue<Thread> waiters
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
 * @since 1.5
 */
class LockSupport {
    private this() {} // Cannot be instantiated.

    private static void setBlocker(ThreadEx t, Object arg) {
        // Even though volatile, hotspot doesn't need a write barrier here.
        t.parkBlocker = arg;
        // implementationMissing(false);
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
        ThreadEx tx = cast(ThreadEx)thread;
        if (tx !is null) 
            tx.parker().unpark();
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
     * @since 1.6
     */
    static void park(Object blocker) {
        park(blocker, Duration.zero);
    }

    static void park(Object blocker, Duration time) {
        ThreadEx tx = cast(ThreadEx)Thread.getThis();
        if (time >= Duration.zero && tx !is null) {
            setBlocker(tx, blocker);
            tx.parker().park(time);
            setBlocker(tx, null);
        } else {
            warning("The current thread is not ThreadEx!");
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
     * @since 1.6
     */
    static void parkNanos(Object blocker, long nanos) {
        if(nanos > 0) {
            park(blocker, dur!(TimeUnit.Nanosecond)(nanos));
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
     * @since 1.6
     */
    // static void parkUntil(Object blocker, long deadline) {
    //     Thread t = Thread.currentThread();
    //     setBlocker(t, blocker);
    //     U.park(true, deadline);
    //     setBlocker(t, null);
    // }

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
     * @since 1.6
     */
    static Object getBlocker(Thread t) {
         ThreadEx tx = cast(ThreadEx)t;
        if (tx !is null) 
            throw new NullPointerException();
        return tx.parkBlocker;
        
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
        ThreadEx tx = cast(ThreadEx)Thread.getThis();
        if (tx !is null) {
            tx.parker().park(Duration.zero);
        } else {
            warning("The current thread is not ThreadEx!");
        }
    }

    static void park(Duration time) {        
        ThreadEx tx = cast(ThreadEx)Thread.getThis();
        if (!time.isNegative && tx !is null) {
            tx.parker().park(time);
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
    static void parkNanos(long nanos) {        
        ThreadEx tx = cast(ThreadEx)Thread.getThis();
        if (nanos > 0 && tx !is null) {
            tx.parker().park(dur!(TimeUnit.Nanosecond)(nanos));
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
    static void parkUntil(long deadline) {
        // U.park(true, deadline);
        implementationMissing(false);
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

    // Hotspot implementation via intrinsics API
    // private static final Unsafe U = Unsafe.getUnsafe();
    // private static final long PARKBLOCKER = U.objectFieldOffset
    //         (Thread.class, "parkBlocker");
    // private static final long SECONDARY = U.objectFieldOffset
    //         (Thread.class, "threadLocalRandomSecondarySeed");
    // private static final long TID = U.objectFieldOffset
    //         (Thread.class, "tid");

}
