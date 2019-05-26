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

module hunt.concurrency.thread.ThreadEx;

import hunt.concurrency.thread.LockSupport;

import hunt.Exceptions;
import hunt.Functions;
import hunt.logging.ConsoleLogger;
import hunt.system.Memory;
import hunt.util.Common;
import hunt.util.DateTime;

import core.atomic;
import core.thread;
import core.time;
import core.sync.condition;
import core.sync.mutex;

import std.algorithm: min, max;
import std.conv: to;


/**
*/
interface Interruptible {
    void interrupt(Thread t);
}


/**
 * Interface for handlers invoked when a {@code Thread} abruptly
 * terminates due to an uncaught exception.
 * <p>When a thread is about to terminate due to an uncaught exception
 * the Java Virtual Machine will query the thread for its
 * {@code UncaughtExceptionHandler} using
 * {@link #getUncaughtExceptionHandler} and will invoke the handler's
 * {@code uncaughtException} method, passing the thread and the
 * exception as arguments.
 * If a thread has not had its {@code UncaughtExceptionHandler}
 * explicitly set, then its {@code ThreadGroupEx} object acts as its
 * {@code UncaughtExceptionHandler}. If the {@code ThreadGroupEx} object
 * has no
 * special requirements for dealing with the exception, it can forward
 * the invocation to the {@linkplain #getDefaultUncaughtExceptionHandler
 * default uncaught exception handler}.
 *
 * @see #setDefaultUncaughtExceptionHandler
 * @see #setUncaughtExceptionHandler
 * @see ThreadGroupEx#uncaughtException
 * @since 1.5
 */
interface UncaughtExceptionHandler {
    /**
     * Method invoked when the given thread terminates due to the
     * given uncaught exception.
     * <p>Any exception thrown by this method will be ignored by the
     * Java Virtual Machine.
     * @param t the thread
     * @param e the exception
     */
    void uncaughtException(Thread t, Throwable e);
}


/**
 * A thread state.  A thread can be in one of the following states:
 * <ul>
 * <li>{@link #NEW}<br>
 *     A thread that has not yet started is in this state.
 *     </li>
 * <li>{@link #RUNNABLE}<br>
 *     A thread executing in the Java virtual machine is in this state.
 *     </li>
 * <li>{@link #BLOCKED}<br>
 *     A thread that is blocked waiting for a monitor lock
 *     is in this state.
 *     </li>
 * <li>{@link #WAITING}<br>
 *     A thread that is waiting indefinitely for another thread to
 *     perform a particular action is in this state.
 *     </li>
 * <li>{@link #TIMED_WAITING}<br>
 *     A thread that is waiting for another thread to perform an action
 *     for up to a specified waiting time is in this state.
 *     </li>
 * <li>{@link #TERMINATED}<br>
 *     A thread that has exited is in this state.
 *     </li>
 * </ul>
 *
 * <p>
 * A thread can be in only one state at a given point in time.
 * These states are virtual machine states which do not reflect
 * any operating system thread states.
 *
 * @since   1.5
 * @see #getState
 */
enum ThreadState {
    /**
     * Thread state for a thread which has not yet started.
     */
    NEW,

    /**
     * Thread state for a runnable thread.  A thread in the runnable
     * state is executing in the Java virtual machine but it may
     * be waiting for other resources from the operating system
     * such as processor.
     */
    RUNNABLE,

    /**
     * Thread state for a thread blocked waiting for a monitor lock.
     * A thread in the blocked state is waiting for a monitor lock
     * to enter a synchronized block/method or
     * reenter a synchronized block/method after calling
     * {@link Object#wait() Object.wait}.
     */
    BLOCKED,

    /**
     * Thread state for a waiting thread.
     * A thread is in the waiting state due to calling one of the
     * following methods:
     * <ul>
     *   <li>{@link Object#wait() Object.wait} with no timeout</li>
     *   <li>{@link #join() Thread.join} with no timeout</li>
     *   <li>{@link LockSupport#park() LockSupport.park}</li>
     * </ul>
     *
     * <p>A thread in the waiting state is waiting for another thread to
     * perform a particular action.
     *
     * For example, a thread that has called {@code Object.wait()}
     * on an object is waiting for another thread to call
     * {@code Object.notify()} or {@code Object.notifyAll()} on
     * that object. A thread that has called {@code Thread.join()}
     * is waiting for a specified thread to terminate.
     */
    WAITING,

    /**
     * Thread state for a waiting thread with a specified waiting time.
     * A thread is in the timed waiting state due to calling one of
     * the following methods with a specified positive waiting time:
     * <ul>
     *   <li>{@link #sleep Thread.sleep}</li>
     *   <li>{@link Object#wait(long) Object.wait} with timeout</li>
     *   <li>{@link #join(long) Thread.join} with timeout</li>
     *   <li>{@link LockSupport#parkNanos LockSupport.parkNanos}</li>
     *   <li>{@link LockSupport#parkUntil LockSupport.parkUntil}</li>
     * </ul>
     */
    TIMED_WAITING,

    /**
     * Thread state for a terminated thread.
     * The thread has completed execution.
     */
    TERMINATED
}


/**
 * A <i>thread</i> is a thread of execution in a program. The Java
 * Virtual Machine allows an application to have multiple threads of
 * execution running concurrently.
 * <p>
 * Every thread has a priority. Threads with higher priority are
 * executed in preference to threads with lower priority. Each thread
 * may or may not also be marked as a daemon. When code running in
 * some thread creates a new {@code Thread} object, the new
 * thread has its priority initially set equal to the priority of the
 * creating thread, and is a daemon thread if and only if the
 * creating thread is a daemon.
 * <p>
 * When a Java Virtual Machine starts up, there is usually a single
 * non-daemon thread (which typically calls the method named
 * {@code main} of some designated class). The Java Virtual
 * Machine continues to execute threads until either of the following
 * occurs:
 * <ul>
 * <li>The {@code exit} method of class {@code Runtime} has been
 *     called and the security manager has permitted the exit operation
 *     to take place.
 * <li>All threads that are not daemon threads have died, either by
 *     returning from the call to the {@code run} method or by
 *     throwing an exception that propagates beyond the {@code run}
 *     method.
 * </ul>
 * <p>
 * There are two ways to create a new thread of execution. One is to
 * declare a class to be a subclass of {@code Thread}. This
 * subclass should override the {@code run} method of class
 * {@code Thread}. An instance of the subclass can then be
 * allocated and started. For example, a thread that computes primes
 * larger than a stated value could be written as follows:
 * <hr><blockquote><pre>
 *     class PrimeThread extends Thread {
 *         long minPrime;
 *         PrimeThread(long minPrime) {
 *             this.minPrime = minPrime;
 *         }
 *
 *         public void run() {
 *             // compute primes larger than minPrime
 *             &nbsp;.&nbsp;.&nbsp;.
 *         }
 *     }
 * </pre></blockquote><hr>
 * <p>
 * The following code would then create a thread and start it running:
 * <blockquote><pre>
 *     PrimeThread p = new PrimeThread(143);
 *     p.start();
 * </pre></blockquote>
 * <p>
 * The other way to create a thread is to declare a class that
 * implements the {@code Runnable} interface. That class then
 * implements the {@code run} method. An instance of the class can
 * then be allocated, passed as an argument when creating
 * {@code Thread}, and started. The same example in this other
 * style looks like the following:
 * <hr><blockquote><pre>
 *     class PrimeRun implements Runnable {
 *         long minPrime;
 *         PrimeRun(long minPrime) {
 *             this.minPrime = minPrime;
 *         }
 *
 *         public void run() {
 *             // compute primes larger than minPrime
 *             &nbsp;.&nbsp;.&nbsp;.
 *         }
 *     }
 * </pre></blockquote><hr>
 * <p>
 * The following code would then create a thread and start it running:
 * <blockquote><pre>
 *     PrimeRun p = new PrimeRun(143);
 *     new Thread(p).start();
 * </pre></blockquote>
 * <p>
 * Every thread has a name for identification purposes. More than
 * one thread may have the same name. If a name is not specified when
 * a thread is created, a new name is generated for it.
 * <p>
 * Unless otherwise noted, passing a {@code null} argument to a constructor
 * or method in this class will cause a {@link NullPointerException} to be
 * thrown.
 *
 */
class ThreadEx : Thread, Runnable {

    /* What will be run. */
    private Runnable target;

    // Object parkBlocker;
    ThreadState state;
    

    /* The object in which this thread is blocked in an interruptible I/O
     * operation, if any.  The blocker's interrupt method should be invoked
     * after setting this thread's interrupt status.
     */
    private Interruptible blocker;
    private Object blockerLock;
    private shared bool _interrupted;     // Thread.isInterrupted state
    
    /* For autonumbering anonymous threads. */
    private static shared int threadInitNumber;
    private static int nextThreadNum() {
        return core.atomic.atomicOp!"+="(threadInitNumber, 1);
    }

    this() {
        this(null, null, "Thread-" ~ nextThreadNum().to!string());
    }

    this(string name) {
        this(null, null, name);
    }

    this(Runnable target) {
        this(null, target, "Thread-" ~ nextThreadNum().to!string());
    }

    this(Runnable target, string name) {
        this(null, target, name);
    }

    this(ThreadGroupEx group,  string name) {
        this(group, null, name);
    }

    this(ThreadGroupEx group, Runnable target, string name,  size_t sz = 0) {
        this.name = name;
        this.group = group;
        this.target = target;
        super(&run, sz);
        initialize();
    }

    this(Action dg, string name) {
        this(new class Runnable {
            void run() { dg();}
        }, name);
    }

    this(Action dg) {
        this(new class Runnable {
            void run() { dg();}
        });
    }

    this(void function() fn) {
        this(new class Runnable {
            void run() { fn();}
        });
    }

    ~this() {
        blocker = null;
        blockerLock = null;
        // parkBlocker = null;
        target = null;
        // _parker = null;
    }

    private void initialize() nothrow {
        // _parker = Parker.allocate(this);
        blockerLock = new Object();
        state = ThreadState.NEW;
    }

    
    /**
     * Returns the thread group to which this thread belongs.
     * This method returns null if this thread has died
     * (been stopped).
     *
     * @return  this thread's thread group.
     */
    final ThreadGroupEx getThreadGroup() {
        return group;
    }

    /* The group of this thread */
    private ThreadGroupEx group;

    /**
     * If this thread was constructed using a separate
     * {@code Runnable} run object, then that
     * {@code Runnable} object's {@code run} method is called;
     * otherwise, this method does nothing and returns.
     * <p>
     * Subclasses of {@code Thread} should override this method.
     *
     * @see     #start()
     * @see     #stop()
     * @see     #Thread(ThreadGroup, Runnable, String)
     * See_also:
     *  https://stackoverflow.com/questions/8579657/whats-the-difference-between-thread-start-and-runnable-run
     */
    void run() {
        version(HUNT_DEBUG_CONCURRENCY) {
            infof("trying to run a target (%s null)...", target is null ? "is" : "is not");
        }
        if (target !is null) {
            target.run();
        }
    }



     /**
     * Tests if this thread is alive. A thread is alive if it has
     * been started and has not yet died.
     *
     * @return  <code>true</code> if this thread is alive;
     *          <code>false</code> otherwise.
     */
    final bool isAlive() {
        // TODO: Tasks pending completion -@zxp at 11/7/2018, 10:30:43 AM
        // 
        return isRunning;
    }

    /**
     * Returns the state of this thread.
     * This method is designed for use in monitoring of the system state,
     * not for synchronization control.
     *
     * @return this thread's state.
     * @since 1.5
     */
    ThreadState getState() {
        // get current thread state
        // return jdk.internal.misc.VM.toThreadState(threadStatus);
        return state;
    }

    /* Set the blocker field; invoked via sun.misc.SharedSecrets from java.nio code
     */
    void blockedOn(Interruptible b) {
        synchronized (blockerLock) {
            blocker = b;
        }
    }

    /**
     * Interrupts this thread.
     *
     * <p> Unless the current thread is interrupting itself, which is
     * always permitted, the {@link #checkAccess() checkAccess} method
     * of this thread is invoked, which may cause a {@link
     * SecurityException} to be thrown.
     *
     * <p> If this thread is blocked in an invocation of the {@link
     * Object#wait() wait()}, {@link Object#wait(long) wait(long)}, or {@link
     * Object#wait(long, int) wait(long, int)} methods of the {@link Object}
     * class, or of the {@link #join()}, {@link #join(long)}, {@link
     * #join(long, int)}, {@link #sleep(long)}, or {@link #sleep(long, int)},
     * methods of this class, then its interrupt status will be cleared and it
     * will receive an {@link InterruptedException}.
     *
     * <p> If this thread is blocked in an I/O operation upon an {@link
     * java.nio.channels.InterruptibleChannel InterruptibleChannel}
     * then the channel will be closed, the thread's interrupt
     * status will be set, and the thread will receive a {@link
     * java.nio.channels.ClosedByInterruptException}.
     *
     * <p> If this thread is blocked in a {@link java.nio.channels.Selector}
     * then the thread's interrupt status will be set and it will return
     * immediately from the selection operation, possibly with a non-zero
     * value, just as if the selector's {@link
     * java.nio.channels.Selector#wakeup wakeup} method were invoked.
     *
     * <p> If none of the previous conditions hold then this thread's interrupt
     * status will be set. </p>
     *
     * <p> Interrupting a thread that is not alive need not have any effect.
     *
     * @throws  SecurityException
     *          if the current thread cannot modify this thread
     *
     * @revised 6.0
     * @spec JSR-51
     */
    void interrupt() {
        synchronized (blockerLock) {
            Interruptible b = blocker;
            if (b !is null) {
                interrupt0();           // Just to set the interrupt flag
                b.interrupt(this);
                return;
            }
        }
        interrupt0();
    }

    private void interrupt0() {
        if(!_interrupted) {
            _interrupted = true;
            // More than one thread can get here with the same value of osthread,
            // resulting in multiple notifications.  We do, however, want the store
            // to interrupted() to be visible to other threads before we execute unpark().
            // OrderAccess::fence();
            // ParkEvent * const slp = thread->_SleepEvent ;
            // if (slp != NULL) slp->unpark() ;
        }

        // For JSR166. Unpark even if interrupt status already was set
        // _parker.unpark();
        LockSupport.unpark();

        // ParkEvent * ev = thread->_ParkEvent ;
        // if (ev != NULL) ev->unpark() ;
    }

    /**
     * Tests whether this thread has been interrupted.  The <i>interrupted
     * status</i> of the thread is unaffected by this method.
     *
     * <p>A thread interruption ignored because a thread was not alive
     * at the time of the interrupt will be reflected by this method
     * returning false.
     *
     * @return  <code>true</code> if this thread has been interrupted;
     *          <code>false</code> otherwise.
     * @see     #interrupted()
     * @revised 6.0
     */
    bool isInterrupted() {
        return isInterrupted(false);
    }


    /**
     * Tests whether the current thread has been interrupted.  The
     * <i>interrupted status</i> of the thread is cleared by this method.  In
     * other words, if this method were to be called twice in succession, the
     * second call would return false (unless the current thread were
     * interrupted again, after the first call had cleared its interrupted
     * status and before the second call had examined it).
     *
     * <p>A thread interruption ignored because a thread was not alive
     * at the time of the interrupt will be reflected by this method
     * returning false.
     *
     * @return  <code>true</code> if the current thread has been interrupted;
     *          <code>false</code> otherwise.
     * @see #isInterrupted()
     * @revised 6.0
     */
    static bool interrupted() {
        ThreadEx tex = cast(ThreadEx) Thread.getThis();
        if(tex is null)
            return false;

        return tex.isInterrupted(true);
    }

    /**
     * Tests if some Thread has been interrupted.  The interrupted state
     * is reset or not based on the value of ClearInterrupted that is
     * passed.
     */
    private bool isInterrupted(bool canClear) {
        // bool interrupted = osthread->interrupted();

        // NOTE that since there is no "lock" around the interrupt and
        // is_interrupted operations, there is the possibility that the
        // interrupted flag (in osThread) will be "false" but that the
        // low-level events will be in the signaled state. This is
        // intentional. The effect of this is that Object.wait() and
        // LockSupport.park() will appear to have a spurious wakeup, which
        // is allowed and not harmful, and the possibility is so rare that
        // it is not worth the added complexity to add yet another lock.
        // For the sleep event an explicit reset is performed on entry
        // to os::sleep, so there is no early return. It has also been
        // recommended not to put the interrupted flag into the "event"
        // structure because it hides the issue.
        if (_interrupted && canClear) {
            _interrupted = false;
            // consider thread->_SleepEvent->reset() ... optional optimization
        }

        return _interrupted;
    }

    static ThreadEx currentThread() {
        ThreadEx tex = cast(ThreadEx) Thread.getThis();
        assert(tex !is null, "Must be a ThreadEx");
        return tex;
    }


    // Parker parker() {
    //     return _parker;
    // }
    // private Parker _parker;

    // Short sleep, direct OS call.
    static void nakedSleep(Duration timeout) {
        Thread.sleep(timeout);
    }

    // Sleep forever; naked call to OS-specific sleep; use with CAUTION
    static void infiniteSleep() {
        while (true) {    // sleep forever ...
            Thread.sleep(100.seconds);   // ... 100 seconds at a time
        }
    }

    static void sleep(Duration timeout) {
        // TODO: Tasks pending completion -@zxp at 11/6/2018, 12:29:22 PM
        // using ParkEvent
        LockSupport.park(timeout);
    }

    // Low-level leaf-lock primitives used to implement synchronization
    // and native monitor-mutex infrastructure.
    // Not for general synchronization use.
    private static void spinAcquire(shared(int)* adr, string name) nothrow  {
        int last = *adr;
        cas(adr, 0, 1);
        if (last == 0) return; // normal fast-path return

        // Slow-path : We've encountered contention -- Spin/Yield/Block strategy.
        //   TEVENT(SpinAcquire - ctx);
        int ctr = 0;
        int yields = 0;
        for (;;) {
            while (*adr != 0) {
                ++ctr;
                if ((ctr & 0xFFF) == 0 && !is_MP()) {
                    if (yields > 5) {
                        Thread.sleep(1.msecs);
                    } else {
                        Thread.yield();
                        ++yields;
                    }
                } else {
                    spinPause();
                }
            }
            last = *adr;
            cas(adr, 1, 0);
            if (last == 0) return;
        }
    }

    private static void spinRelease(shared(int)* adr) @safe nothrow @nogc {
        assert(*adr != 0, "invariant");
        atomicFence(); // guarantee at least release consistency.
        // Roach-motel semantics.
        // It's safe if subsequent LDs and STs float "up" into the critical section,
        // but prior LDs and STs within the critical section can't be allowed
        // to reorder or float past the ST that releases the lock.
        // Loads and stores in the critical section - which appear in program
        // order before the store that releases the lock - must also appear
        // before the store that releases the lock in memory visibility order.
        // Conceptually we need a #loadstore|#storestore "release" MEMBAR before
        // the ST of 0 into the lock-word which releases the lock, so fence
        // more than covers this on all platforms.
        *adr = 0;
    }

    //   static void muxAcquire(shared intptr_t * Lock, string Name);
    // //   static void muxAcquireW(shared intptr_t * Lock, ParkEvent * ev);
    //   static void muxRelease(shared intptr_t * Lock);

    private static int spinPause() @safe nothrow @nogc {
        version (X86_64) {
            return 0;
        }
        else version (AsmX86_Windows) {
            asm pure nothrow @nogc {
                pause;
            }
            return 1;
        }
        else {
            return -1;
        }
    }

    private static bool is_MP() @safe pure nothrow @nogc {
        // During bootstrap if _processor_count is not yet initialized
        // we claim to be MP as that is safest. If any platform has a
        // stub generator that might be triggered in this phase and for
        // which being declared MP when in fact not, is a problem - then
        // the bootstrap routine for the stub generator needs to check
        // the processor count directly and leave the bootstrap routine
        // in place until called after initialization has ocurred.
        // return (_processor_count != 1); // AssumeMP || 
        return totalCPUs != 1;
    }

    
    
    // null unless explicitly set
    private UncaughtExceptionHandler uncaughtExceptionHandler;

    // null unless explicitly set
    private __gshared UncaughtExceptionHandler defaultUncaughtExceptionHandler;

    /**
     * Set the default handler invoked when a thread abruptly terminates
     * due to an uncaught exception, and no other handler has been defined
     * for that thread.
     *
     * <p>Uncaught exception handling is controlled first by the thread, then
     * by the thread's {@link ThreadGroup} object and finally by the default
     * uncaught exception handler. If the thread does not have an explicit
     * uncaught exception handler set, and the thread's thread group
     * (including parent thread groups)  does not specialize its
     * {@code uncaughtException} method, then the default handler's
     * {@code uncaughtException} method will be invoked.
     * <p>By setting the default uncaught exception handler, an application
     * can change the way in which uncaught exceptions are handled (such as
     * logging to a specific device, or file) for those threads that would
     * already accept whatever &quot;default&quot; behavior the system
     * provided.
     *
     * <p>Note that the default uncaught exception handler should not usually
     * defer to the thread's {@code ThreadGroup} object, as that could cause
     * infinite recursion.
     *
     * @param eh the object to use as the default uncaught exception handler.
     * If {@code null} then there is no default handler.
     *
     * @throws SecurityException if a security manager is present and it denies
     *         {@link RuntimePermission}{@code ("setDefaultUncaughtExceptionHandler")}
     *
     * @see #setUncaughtExceptionHandler
     * @see #getUncaughtExceptionHandler
     * @see ThreadGroup#uncaughtException
     * @since 1.5
     */
    static void setDefaultUncaughtExceptionHandler(UncaughtExceptionHandler eh) {
        // SecurityManager sm = System.getSecurityManager();
        // if (sm != null) {
        //     sm.checkPermission(
        //         new RuntimePermission("setDefaultUncaughtExceptionHandler")
        //             );
        // }

         defaultUncaughtExceptionHandler = eh;
     }

    /**
     * Returns the default handler invoked when a thread abruptly terminates
     * due to an uncaught exception. If the returned value is {@code null},
     * there is no default.
     * @since 1.5
     * @see #setDefaultUncaughtExceptionHandler
     * @return the default uncaught exception handler for all threads
     */
    static UncaughtExceptionHandler getDefaultUncaughtExceptionHandler(){
        return defaultUncaughtExceptionHandler;
    }

    /**
     * Returns the handler invoked when this thread abruptly terminates
     * due to an uncaught exception. If this thread has not had an
     * uncaught exception handler explicitly set then this thread's
     * {@code ThreadGroup} object is returned, unless this thread
     * has terminated, in which case {@code null} is returned.
     * @since 1.5
     * @return the uncaught exception handler for this thread
     */
    UncaughtExceptionHandler getUncaughtExceptionHandler() {
        return uncaughtExceptionHandler !is null ?
            uncaughtExceptionHandler : group;
    }

    /**
     * Set the handler invoked when this thread abruptly terminates
     * due to an uncaught exception.
     * <p>A thread can take full control of how it responds to uncaught
     * exceptions by having its uncaught exception handler explicitly set.
     * If no such handler is set then the thread's {@code ThreadGroup}
     * object acts as its handler.
     * @param eh the object to use as this thread's uncaught exception
     * handler. If {@code null} then this thread has no explicit handler.
     * @throws  SecurityException  if the current thread is not allowed to
     *          modify this thread.
     * @see #setDefaultUncaughtExceptionHandler
     * @see ThreadGroup#uncaughtException
     * @since 1.5
     */
    void setUncaughtExceptionHandler(UncaughtExceptionHandler eh) {
        checkAccess();
        uncaughtExceptionHandler = eh;
    }

    void checkAccess() {

    }
}


/*
 * Per-thread blocking support for JSR166. See the Java-level
 * Documentation for rationale. Basically, park acts like wait, unpark
 * like notify.
 *
 * 6271289 --
 * To avoid errors where an os thread expires but the JavaThread still
 * exists, Parkers are immortal (type-stable) and are recycled across
 * new threads.  This parallels the ParkEvent implementation.
 * Because park-unpark allow spurious wakeups it is harmless if an
 * unpark call unparks a new thread using the old Parker reference.
 *
 * In the future we'll want to think about eliminating Parker and using
 * ParkEvent instead.  There's considerable duplication between the two
 * services.
 *
 */
class Parker {

    enum int REL_INDEX = 0;
    enum int ABS_INDEX = 1;

    Object parkBlocker;

    private shared int _counter;
    private int _nParked;
    private Parker freeNext;
    private Thread associatedWith; // Current association

    private  int _cur_index;  // which cond is in use: -1, 0, 1
    private Mutex _mutex;
    private Condition[2]  _cond; // one for relative times and one for absolute

    this() @safe nothrow {
        _counter = 0;
        _mutex = new Mutex();
        _cond[REL_INDEX] = new Condition(_mutex);
        _cond[ABS_INDEX] = new Condition(_mutex);
        _cur_index = -1; // mark as unused
    }

    // For simplicity of interface, all forms of park (indefinite,
    // relative, and absolute) are multiplexed into one call.
    // park decrements count if > 0, else does a condvar wait.  Unpark
    // sets count to 1 and signals condvar.  Only one thread ever waits
    // on the condvar. Contention seen when trying to park implies that someone
    // is unparking you, so don't wait. And spurious returns are fine, so there
    // is no need to track notifications.
    void park(bool isAbsolute, Duration time) {
        version(HUNT_DEBUG_CONCURRENCY) {
            if(isAbsolute) {
                Duration d = time - DateTimeHelper.currentTimeMillis().msecs;
                tracef("try to park a thread: isAbsolute=%s, in %s", isAbsolute, 
                    d <= Duration.zero ? "forever" : "in " ~ d.toString());
            } else {
                tracef("try to park a thread: isAbsolute=%s, %s", isAbsolute, 
                    time <= Duration.zero ? "forever" : "in " ~ time.toString());
            }
        }
        // Optional fast-path check:
        // Return immediately if a permit is available.
        // We depend on Atomic::xchg() having full barrier semantics
        // since we are doing a lock-free update to _counter.
        const int c = _counter;
        if(c > 0) {
            atomicStore(_counter, 0);
            version(HUNT_DEBUG_CONCURRENCY) infof("no need to park, counter=%s", c);
            return;
        }

        // Next, demultiplex/decode time arguments
        if (time < Duration.zero || (isAbsolute && time == Duration.zero)) { // don't wait at all
            return;
        }

        ThreadEx thread = cast(ThreadEx) Thread.getThis();

        // Enter safepoint region
        // Beware of deadlocks such as 6317397.
        // The per-thread Parker. mutex is a classic leaf-lock.
        // In particular a thread must never block on the Threads_lock while
        // holding the Parker.mutex. 

        // Don't wait if cannot get lock since interference arises from
        // unparking. Also re-check interrupt before trying wait.
        if((thread !is null && thread.isInterrupted()) || !_mutex.tryLock())
            return;

        if (_counter > 0) { // no wait needed
            return;
        }

        scope(exit) {
            _counter = 0;
            _mutex.unlock();
            // Paranoia to ensure our locked and lock-free paths interact
            // correctly with each other and Java-level accesses.
            atomicFence();
        }

        // OSThreadWaitState osts(thread.osthread(), false  /* not Object.wait() */ );
        // jt.set_suspend_equivalent();
        // // cleared by handle_special_suspend_equivalent_condition() or java_suspend_self()

        assert(_cur_index == -1, "invariant");
        if (time == Duration.zero) {
            _cur_index = REL_INDEX; // arbitrary choice when not timed
            _cond[_cur_index].wait();
        }
        else {
            if(isAbsolute) {
                _cur_index = ABS_INDEX;
                Duration t = time - msecs(DateTimeHelper.currentTimeMillis());
                if(t > Duration.zero)
                    _cond[ABS_INDEX].wait(t);
            } else {
                _cur_index = REL_INDEX;
                _cond[REL_INDEX].wait(time);
            }

        }
        _cur_index = -1;
    }

    void unpark() {
        version(HUNT_DEBUG_CONCURRENCY) {
            tracef("try to unpark a thread");
        }
        _mutex.lock();
        const int s = _counter;
        _counter = 1;
        // must capture correct index before unlocking
        int index = _cur_index;
        _mutex.unlock();

        // Note that we signal() *after* dropping the lock for "immortal" Events.
        // This is safe and avoids a common class of futile wakeups.  In rare
        // circumstances this can cause a thread to return prematurely from
        // cond_{timed}wait() but the spurious wakeup is benign and the victim
        // will simply re-test the condition and re-park itself.
        // This provides particular benefit if the underlying platform does not
        // provide wait morphing.

        if (s < 1 && index != -1) {
            // thread is definitely parked
            _cond[index].notify();
        }
    }

    // Lifecycle operators
    static Parker allocate(Thread t) nothrow {
        assert(t !is null, "invariant");
        Parker p;

        // Start by trying to recycle an existing but unassociated
        // Parker from the global free list.
        // 8028280: using concurrent free list without memory management can leak
        // pretty badly it turns out.
        ThreadEx.spinAcquire(&listLock, "ParkerFreeListAllocate");
        {
            p = freeList;
            if (p !is null) {
                freeList = p.freeNext;
            }
        }
        ThreadEx.spinRelease(&listLock);

        if (p !is null) {
            assert(p.associatedWith is null, "invariant");
        }
        else {
            // Do this the hard way -- materialize a new Parker..
            p = new Parker();
        }
        p.associatedWith = t; // Associate p with t
        p.freeNext = null;
        return p;
    }

    static void release(Parker p) {
        if (p is null)
            return;
        assert(p.associatedWith !is null, "invariant");
        assert(p.freeNext is null, "invariant");
        p.associatedWith = null;

        ThreadEx.spinAcquire(&listLock, "ParkerFreeListRelease");
        {
            p.freeNext = freeList;
            freeList = p;
        }
        ThreadEx.spinRelease(&listLock);
    }

    private static Parker freeList;
    private static shared int listLock;
}


/**
 * A thread group represents a set of threads. In addition, a thread
 * group can also include other thread groups. The thread groups form
 * a tree in which every thread group except the initial thread group
 * has a parent.
 * <p>
 * A thread is allowed to access information about its own thread
 * group, but not to access information about its thread group's
 * parent thread group or any other thread groups.
 *
 * @author  unascribed
 * @since   1.0
 */
/* The locking strategy for this code is to try to lock only one level of the
 * tree wherever possible, but otherwise to lock from the bottom up.
 * That is, from child thread groups to parents.
 * This has the advantage of limiting the number of locks that need to be held
 * and in particular avoids having to grab the lock for the root thread group,
 * (or a global lock) which would be a source of contention on a
 * multi-processor system with many thread groups.
 * This policy often leads to taking a snapshot of the state of a thread group
 * and working off of that snapshot, rather than holding the thread group locked
 * while we work on the children.
 */
class ThreadGroupEx : UncaughtExceptionHandler { 
    private ThreadGroupEx parent;
    string name;
    int maxPriority;
    bool destroyed;
    bool daemon;

    int nUnstartedThreads = 0;
    int nthreads;
    Thread[] threads;

    int ngroups;
    ThreadGroupEx[] groups;

    /**
     * Creates an empty Thread group that is not in any Thread group.
     * This method is used to create the system Thread group.
     */
    private this() {     // called from C code
        this.name = "system";
        this.maxPriority = Thread.PRIORITY_MAX;
        this.parent = null;
    }

    /**
     * Constructs a new thread group. The parent of this new group is
     * the thread group of the currently running thread.
     * <p>
     * The {@code checkAccess} method of the parent thread group is
     * called with no arguments; this may result in a security exception.
     *
     * @param   name   the name of the new thread group.
     * @throws  SecurityException  if the current thread cannot create a
     *               thread in the specified thread group.
     * @see     java.lang.ThreadGroupEx#checkAccess()
     * @since   1.0
     */
    this(string name) {
        ThreadEx t = cast(ThreadEx)Thread.getThis();
        if(t is null)
            this(null, name);
        else
            this(t.getThreadGroup(), name);
    }

    /**
     * Creates a new thread group. The parent of this new group is the
     * specified thread group.
     * <p>
     * The {@code checkAccess} method of the parent thread group is
     * called with no arguments; this may result in a security exception.
     *
     * @param     parent   the parent thread group.
     * @param     name     the name of the new thread group.
     * @throws    NullPointerException  if the thread group argument is
     *               {@code null}.
     * @throws    SecurityException  if the current thread cannot create a
     *               thread in the specified thread group.
     * @see     java.lang.SecurityException
     * @see     java.lang.ThreadGroupEx#checkAccess()
     * @since   1.0
     */
    this(ThreadGroupEx parent, string name) {
        // this(checkParentAccess(parent), parent, name);
        
        this.name = name;
        if(parent !is null) {
            parent.checkAccess();
            this.maxPriority = parent.maxPriority;
            this.daemon = parent.daemon;
            this.parent = parent;
            parent.add(this);
        }
    }

    // private ThreadGroupEx(Void unused, ThreadGroupEx parent, string name) {
    //     this.name = name;
    //     this.maxPriority = parent.maxPriority;
    //     this.daemon = parent.daemon;
    //     this.parent = parent;
    //     parent.add(this);
    // }

    /*
     * @throws  NullPointerException  if the parent argument is {@code null}
     * @throws  SecurityException     if the current thread cannot create a
     *                                thread in the specified thread group.
     */
    // private static void checkParentAccess(ThreadGroupEx parent) {
    //     parent.checkAccess();
    //     // return null;
    // }

    /**
     * Returns the name of this thread group.
     *
     * @return  the name of this thread group.
     * @since   1.0
     */
    final string getName() {
        return name;
    }

    /**
     * Returns the parent of this thread group.
     * <p>
     * First, if the parent is not {@code null}, the
     * {@code checkAccess} method of the parent thread group is
     * called with no arguments; this may result in a security exception.
     *
     * @return  the parent of this thread group. The top-level thread group
     *          is the only thread group whose parent is {@code null}.
     * @throws  SecurityException  if the current thread cannot modify
     *               this thread group.
     * @see        java.lang.ThreadGroupEx#checkAccess()
     * @see        java.lang.SecurityException
     * @see        java.lang.RuntimePermission
     * @since   1.0
     */
    final ThreadGroupEx getParent() {
        if (parent !is null)
            parent.checkAccess();
        return parent;
    }

    /**
     * Returns the maximum priority of this thread group. Threads that are
     * part of this group cannot have a higher priority than the maximum
     * priority.
     *
     * @return  the maximum priority that a thread in this thread group
     *          can have.
     * @see     #setMaxPriority
     * @since   1.0
     */
    final int getMaxPriority() {
        return maxPriority;
    }

    /**
     * Tests if this thread group is a daemon thread group. A
     * daemon thread group is automatically destroyed when its last
     * thread is stopped or its last thread group is destroyed.
     *
     * @return  {@code true} if this thread group is a daemon thread group;
     *          {@code false} otherwise.
     * @since   1.0
     */
    final bool isDaemon() {
        return daemon;
    }

    /**
     * Tests if this thread group has been destroyed.
     *
     * @return  true if this object is destroyed
     * @since   1.1
     */
    bool isDestroyed() {
        return destroyed;
    }

    /**
     * Changes the daemon status of this thread group.
     * <p>
     * First, the {@code checkAccess} method of this thread group is
     * called with no arguments; this may result in a security exception.
     * <p>
     * A daemon thread group is automatically destroyed when its last
     * thread is stopped or its last thread group is destroyed.
     *
     * @param      daemon   if {@code true}, marks this thread group as
     *                      a daemon thread group; otherwise, marks this
     *                      thread group as normal.
     * @throws     SecurityException  if the current thread cannot modify
     *               this thread group.
     * @see        java.lang.SecurityException
     * @see        java.lang.ThreadGroupEx#checkAccess()
     * @since      1.0
     */
    final void setDaemon(bool daemon) {
        checkAccess();
        this.daemon = daemon;
    }

    /**
     * Sets the maximum priority of the group. Threads in the thread
     * group that already have a higher priority are not affected.
     * <p>
     * First, the {@code checkAccess} method of this thread group is
     * called with no arguments; this may result in a security exception.
     * <p>
     * If the {@code pri} argument is less than
     * {@link Thread#PRIORITY_MIN} or greater than
     * {@link Thread#PRIORITY_MAX}, the maximum priority of the group
     * remains unchanged.
     * <p>
     * Otherwise, the priority of this ThreadGroupEx object is set to the
     * smaller of the specified {@code pri} and the maximum permitted
     * priority of the parent of this thread group. (If this thread group
     * is the system thread group, which has no parent, then its maximum
     * priority is simply set to {@code pri}.) Then this method is
     * called recursively, with {@code pri} as its argument, for
     * every thread group that belongs to this thread group.
     *
     * @param      pri   the new priority of the thread group.
     * @throws     SecurityException  if the current thread cannot modify
     *               this thread group.
     * @see        #getMaxPriority
     * @see        java.lang.SecurityException
     * @see        java.lang.ThreadGroupEx#checkAccess()
     * @since      1.0
     */
    final void setMaxPriority(int pri) {
        int ngroupsSnapshot;
        ThreadGroupEx[] groupsSnapshot;
        synchronized (this) {
            checkAccess();
            if (pri < Thread.PRIORITY_MIN || pri > Thread.PRIORITY_MAX) {
                return;
            }
            maxPriority = (parent !is null) ? min(pri, parent.maxPriority) : pri;
            ngroupsSnapshot = ngroups;
            if (groups !is null) {
                // groupsSnapshot = Arrays.copyOf(groups, ngroupsSnapshot);
                size_t limit = min(ngroupsSnapshot, groups.length);
                groupsSnapshot = groups[0..limit].dup;
            } else {
                groupsSnapshot = null;
            }
        }
        for (int i = 0 ; i < ngroupsSnapshot ; i++) {
            groupsSnapshot[i].setMaxPriority(pri);
        }
    }

    /**
     * Tests if this thread group is either the thread group
     * argument or one of its ancestor thread groups.
     *
     * @param   g   a thread group.
     * @return  {@code true} if this thread group is the thread group
     *          argument or one of its ancestor thread groups;
     *          {@code false} otherwise.
     * @since   1.0
     */
    final bool parentOf(ThreadGroupEx g) {
        for (; g !is null ; g = g.parent) {
            if (g is this) {
                return true;
            }
        }
        return false;
    }

    /**
     * Determines if the currently running thread has permission to
     * modify this thread group.
     * <p>
     * If there is a security manager, its {@code checkAccess} method
     * is called with this thread group as its argument. This may result
     * in throwing a {@code SecurityException}.
     *
     * @throws     SecurityException  if the current thread is not allowed to
     *               access this thread group.
     * @see        java.lang.SecurityManager#checkAccess(java.lang.ThreadGroupEx)
     * @since      1.0
     */
    final void checkAccess() {
        // SecurityManager security = System.getSecurityManager();
        // if (security !is null) {
        //     security.checkAccess(this);
        // }
    }

    /**
     * Returns an estimate of the number of active threads in this thread
     * group and its subgroups. Recursively iterates over all subgroups in
     * this thread group.
     *
     * <p> The value returned is only an estimate because the number of
     * threads may change dynamically while this method traverses internal
     * data structures, and might be affected by the presence of certain
     * system threads. This method is intended primarily for debugging
     * and monitoring purposes.
     *
     * @return  an estimate of the number of active threads in this thread
     *          group and in any other thread group that has this thread
     *          group as an ancestor
     *
     * @since   1.0
     */
    int activeCount() {
        int result;
        // Snapshot sub-group data so we don't hold this lock
        // while our children are computing.
        int ngroupsSnapshot;
        ThreadGroupEx[] groupsSnapshot;
        synchronized (this) {
            if (destroyed) {
                return 0;
            }
            result = nthreads;
            ngroupsSnapshot = ngroups;
            if (groups !is null) {
                size_t limit = min(ngroupsSnapshot, groups.length);
                groupsSnapshot = groups[0..limit].dup;
            } else {
                groupsSnapshot = null;
            }
        }
        for (int i = 0 ; i < ngroupsSnapshot ; i++) {
            result += groupsSnapshot[i].activeCount();
        }
        return result;
    }

    /**
     * Copies into the specified array every active thread in this
     * thread group and its subgroups.
     *
     * <p> An invocation of this method behaves in exactly the same
     * way as the invocation
     *
     * <blockquote>
     * {@linkplain #enumerate(Thread[], bool) enumerate}{@code (list, true)}
     * </blockquote>
     *
     * @param  list
     *         an array into which to put the list of threads
     *
     * @return  the number of threads put into the array
     *
     * @throws  SecurityException
     *          if {@linkplain #checkAccess checkAccess} determines that
     *          the current thread cannot access this thread group
     *
     * @since   1.0
     */
    int enumerate(Thread[] list) {
        checkAccess();
        return enumerate(list, 0, true);
    }

    /**
     * Copies into the specified array every active thread in this
     * thread group. If {@code recurse} is {@code true},
     * this method recursively enumerates all subgroups of this
     * thread group and references to every active thread in these
     * subgroups are also included. If the array is too short to
     * hold all the threads, the extra threads are silently ignored.
     *
     * <p> An application might use the {@linkplain #activeCount activeCount}
     * method to get an estimate of how big the array should be, however
     * <i>if the array is too short to hold all the threads, the extra threads
     * are silently ignored.</i>  If it is critical to obtain every active
     * thread in this thread group, the caller should verify that the returned
     * int value is strictly less than the length of {@code list}.
     *
     * <p> Due to the inherent race condition in this method, it is recommended
     * that the method only be used for debugging and monitoring purposes.
     *
     * @param  list
     *         an array into which to put the list of threads
     *
     * @param  recurse
     *         if {@code true}, recursively enumerate all subgroups of this
     *         thread group
     *
     * @return  the number of threads put into the array
     *
     * @throws  SecurityException
     *          if {@linkplain #checkAccess checkAccess} determines that
     *          the current thread cannot access this thread group
     *
     * @since   1.0
     */
    int enumerate(Thread[] list, bool recurse) {
        checkAccess();
        return enumerate(list, 0, recurse);
    }

    private int enumerate(Thread[] list, int n, bool recurse) {
        int ngroupsSnapshot = 0;
        ThreadGroupEx[] groupsSnapshot = null;
        synchronized (this) {
            if (destroyed) {
                return 0;
            }
            int nt = nthreads;
            if (nt > cast(int)list.length - n) {
                nt = cast(int)list.length - n;
            }
            for (int i = 0; i < nt; i++) {
                // TODO: Tasks pending completion -@zxp at 10/14/2018, 9:11:46 AM
                // 
                implementationMissing(false);
                // if (threads[i].isAlive()) {
                //     list[n++] = threads[i];
                // }
            }
            if (recurse) {
                ngroupsSnapshot = ngroups;
                if (groups !is null) {
                    size_t limit = min(ngroupsSnapshot, groups.length);
                    groupsSnapshot = groups[0..limit].dup;
                } else {
                    groupsSnapshot = null;
                }
            }
        }
        if (recurse) {
            for (int i = 0 ; i < ngroupsSnapshot ; i++) {
                n = groupsSnapshot[i].enumerate(list, n, true);
            }
        }
        return n;
    }

    /**
     * Returns an estimate of the number of active groups in this
     * thread group and its subgroups. Recursively iterates over
     * all subgroups in this thread group.
     *
     * <p> The value returned is only an estimate because the number of
     * thread groups may change dynamically while this method traverses
     * internal data structures. This method is intended primarily for
     * debugging and monitoring purposes.
     *
     * @return  the number of active thread groups with this thread group as
     *          an ancestor
     *
     * @since   1.0
     */
    int activeGroupCount() {
        int ngroupsSnapshot;
        ThreadGroupEx[] groupsSnapshot;
        synchronized (this) {
            if (destroyed) {
                return 0;
            }
            ngroupsSnapshot = ngroups;
            if (groups !is null) {
                size_t limit = min(ngroupsSnapshot, groups.length);
                groupsSnapshot = groups[0..limit].dup;
            } else {
                groupsSnapshot = null;
            }
        }
        int n = ngroupsSnapshot;
        for (int i = 0 ; i < ngroupsSnapshot ; i++) {
            n += groupsSnapshot[i].activeGroupCount();
        }
        return n;
    }

    /**
     * Copies into the specified array references to every active
     * subgroup in this thread group and its subgroups.
     *
     * <p> An invocation of this method behaves in exactly the same
     * way as the invocation
     *
     * <blockquote>
     * {@linkplain #enumerate(ThreadGroupEx[], bool) enumerate}{@code (list, true)}
     * </blockquote>
     *
     * @param  list
     *         an array into which to put the list of thread groups
     *
     * @return  the number of thread groups put into the array
     *
     * @throws  SecurityException
     *          if {@linkplain #checkAccess checkAccess} determines that
     *          the current thread cannot access this thread group
     *
     * @since   1.0
     */
    int enumerate(ThreadGroupEx[] list) {
        checkAccess();
        return enumerate(list, 0, true);
    }

    /**
     * Copies into the specified array references to every active
     * subgroup in this thread group. If {@code recurse} is
     * {@code true}, this method recursively enumerates all subgroups of this
     * thread group and references to every active thread group in these
     * subgroups are also included.
     *
     * <p> An application might use the
     * {@linkplain #activeGroupCount activeGroupCount} method to
     * get an estimate of how big the array should be, however <i>if the
     * array is too short to hold all the thread groups, the extra thread
     * groups are silently ignored.</i>  If it is critical to obtain every
     * active subgroup in this thread group, the caller should verify that
     * the returned int value is strictly less than the length of
     * {@code list}.
     *
     * <p> Due to the inherent race condition in this method, it is recommended
     * that the method only be used for debugging and monitoring purposes.
     *
     * @param  list
     *         an array into which to put the list of thread groups
     *
     * @param  recurse
     *         if {@code true}, recursively enumerate all subgroups
     *
     * @return  the number of thread groups put into the array
     *
     * @throws  SecurityException
     *          if {@linkplain #checkAccess checkAccess} determines that
     *          the current thread cannot access this thread group
     *
     * @since   1.0
     */
    int enumerate(ThreadGroupEx[] list, bool recurse) {
        checkAccess();
        return enumerate(list, 0, recurse);
    }

    private int enumerate(ThreadGroupEx[] list, int n, bool recurse) {
        int ngroupsSnapshot = 0;
        ThreadGroupEx[] groupsSnapshot = null;
        synchronized (this) {
            if (destroyed) {
                return 0;
            }
            int ng = ngroups;
            if (ng > cast(int)list.length - n) {
                ng = cast(int)list.length - n;
            }
            if (ng > 0) {
                // System.arraycopy(groups, 0, list, n, ng);
                list[n .. n+ng] = groups[0..ng];
                n += ng;
            }
            if (recurse) {
                ngroupsSnapshot = ngroups;
                if (groups !is null) {
                    size_t limit = min(ngroupsSnapshot, groups.length);
                    groupsSnapshot = groups[0..limit].dup;
                } else {
                    groupsSnapshot = null;
                }
            }
        }
        if (recurse) {
            for (int i = 0 ; i < ngroupsSnapshot ; i++) {
                n = groupsSnapshot[i].enumerate(list, n, true);
            }
        }
        return n;
    }

    /**
     * Stops all threads in this thread group.
     * <p>
     * First, the {@code checkAccess} method of this thread group is
     * called with no arguments; this may result in a security exception.
     * <p>
     * This method then calls the {@code stop} method on all the
     * threads in this thread group and in all of its subgroups.
     *
     * @throws     SecurityException  if the current thread is not allowed
     *               to access this thread group or any of the threads in
     *               the thread group.
     * @see        java.lang.SecurityException
     * @see        java.lang.Thread#stop()
     * @see        java.lang.ThreadGroupEx#checkAccess()
     * @since      1.0
     * @deprecated    This method is inherently unsafe.  See
     *     {@link Thread#stop} for details.
     */
    // @Deprecated(since="1.2")
    // final void stop() {
    //     if (stopOrSuspend(false))
    //         Thread.getThis().stop();
    // }

    /**
     * Interrupts all threads in this thread group.
     * <p>
     * First, the {@code checkAccess} method of this thread group is
     * called with no arguments; this may result in a security exception.
     * <p>
     * This method then calls the {@code interrupt} method on all the
     * threads in this thread group and in all of its subgroups.
     *
     * @throws     SecurityException  if the current thread is not allowed
     *               to access this thread group or any of the threads in
     *               the thread group.
     * @see        java.lang.Thread#interrupt()
     * @see        java.lang.SecurityException
     * @see        java.lang.ThreadGroupEx#checkAccess()
     * @since      1.2
     */
    final void interrupt() {
        int ngroupsSnapshot;
        ThreadGroupEx[] groupsSnapshot;
        synchronized (this) {
            checkAccess();
            // for (int i = 0 ; i < nthreads ; i++) {
            //     threads[i].interrupt();
            // }
            ngroupsSnapshot = ngroups;
            if (groups !is null) {
                size_t limit = min(ngroupsSnapshot, groups.length);
                groupsSnapshot = groups[0..limit].dup;
            } else {
                groupsSnapshot = null;
            }
        }
        for (int i = 0 ; i < ngroupsSnapshot ; i++) {
            groupsSnapshot[i].interrupt();
        }
    }

    /**
     * Suspends all threads in this thread group.
     * <p>
     * First, the {@code checkAccess} method of this thread group is
     * called with no arguments; this may result in a security exception.
     * <p>
     * This method then calls the {@code suspend} method on all the
     * threads in this thread group and in all of its subgroups.
     *
     * @throws     SecurityException  if the current thread is not allowed
     *               to access this thread group or any of the threads in
     *               the thread group.
     * @see        java.lang.Thread#suspend()
     * @see        java.lang.SecurityException
     * @see        java.lang.ThreadGroupEx#checkAccess()
     * @since      1.0
     * @deprecated    This method is inherently deadlock-prone.  See
     *     {@link Thread#suspend} for details.
     */
    // @Deprecated(since="1.2")
    // @SuppressWarnings("deprecation")
    // final void suspend() {
    //     if (stopOrSuspend(true))
    //         Thread.getThis().suspend();
    // }

    /**
     * Helper method: recursively stops or suspends (as directed by the
     * bool argument) all of the threads in this thread group and its
     * subgroups, except the current thread.  This method returns true
     * if (and only if) the current thread is found to be in this thread
     * group or one of its subgroups.
     */
    // @SuppressWarnings("deprecation")
    // private bool stopOrSuspend(bool suspend) {
    //     bool suicide = false;
    //     Thread us = Thread.getThis();
    //     int ngroupsSnapshot;
    //     ThreadGroupEx[] groupsSnapshot = null;
    //     synchronized (this) {
    //         checkAccess();
    //         for (int i = 0 ; i < nthreads ; i++) {
    //             if (threads[i]==us)
    //                 suicide = true;
    //             else if (suspend)
    //                 threads[i].suspend();
    //             else
    //                 threads[i].stop();
    //         }

    //         ngroupsSnapshot = ngroups;
    //         if (groups !is null) {
    //             groupsSnapshot = Arrays.copyOf(groups, ngroupsSnapshot);
    //         }
    //     }
    //     for (int i = 0 ; i < ngroupsSnapshot ; i++)
    //         suicide = groupsSnapshot[i].stopOrSuspend(suspend) || suicide;

    //     return suicide;
    // }

    /**
     * Resumes all threads in this thread group.
     * <p>
     * First, the {@code checkAccess} method of this thread group is
     * called with no arguments; this may result in a security exception.
     * <p>
     * This method then calls the {@code resume} method on all the
     * threads in this thread group and in all of its sub groups.
     *
     * @throws     SecurityException  if the current thread is not allowed to
     *               access this thread group or any of the threads in the
     *               thread group.
     * @see        java.lang.SecurityException
     * @see        java.lang.Thread#resume()
     * @see        java.lang.ThreadGroupEx#checkAccess()
     * @since      1.0
     * @deprecated    This method is used solely in conjunction with
     *       {@code Thread.suspend} and {@code ThreadGroupEx.suspend},
     *       both of which have been deprecated, as they are inherently
     *       deadlock-prone.  See {@link Thread#suspend} for details.
     */
    // @Deprecated(since="1.2")
    // @SuppressWarnings("deprecation")
    // final void resume() {
    //     int ngroupsSnapshot;
    //     ThreadGroupEx[] groupsSnapshot;
    //     synchronized (this) {
    //         checkAccess();
    //         for (int i = 0 ; i < nthreads ; i++) {
    //             threads[i].resume();
    //         }
    //         ngroupsSnapshot = ngroups;
    //         if (groups !is null) {
    //             groupsSnapshot = Arrays.copyOf(groups, ngroupsSnapshot);
    //         } else {
    //             groupsSnapshot = null;
    //         }
    //     }
    //     for (int i = 0 ; i < ngroupsSnapshot ; i++) {
    //         groupsSnapshot[i].resume();
    //     }
    // }

    /**
     * Destroys this thread group and all of its subgroups. This thread
     * group must be empty, indicating that all threads that had been in
     * this thread group have since stopped.
     * <p>
     * First, the {@code checkAccess} method of this thread group is
     * called with no arguments; this may result in a security exception.
     *
     * @throws     IllegalThreadStateException  if the thread group is not
     *               empty or if the thread group has already been destroyed.
     * @throws     SecurityException  if the current thread cannot modify this
     *               thread group.
     * @see        java.lang.ThreadGroupEx#checkAccess()
     * @since      1.0
     */
    final void destroy() {
        int ngroupsSnapshot;
        ThreadGroupEx[] groupsSnapshot;
        synchronized (this) {
            checkAccess();
            if (destroyed || (nthreads > 0)) {
                throw new IllegalThreadStateException();
            }
            ngroupsSnapshot = ngroups;
            if (groups !is null) {
                size_t limit = min(ngroupsSnapshot, groups.length);
                groupsSnapshot = groups[0..limit].dup;
            } else {
                groupsSnapshot = null;
            }
            if (parent !is null) {
                destroyed = true;
                ngroups = 0;
                groups = null;
                nthreads = 0;
                threads = null;
            }
        }
        for (int i = 0 ; i < ngroupsSnapshot ; i += 1) {
            groupsSnapshot[i].destroy();
        }
        if (parent !is null) {
            parent.remove(this);
        }
    }

    /**
     * Adds the specified Thread group to this group.
     * @param g the specified Thread group to be added
     * @throws  IllegalThreadStateException If the Thread group has been destroyed.
     */
    private final void add(ThreadGroupEx g){
        synchronized (this) {
            if (destroyed) {
                throw new IllegalThreadStateException();
            }
            if (groups == null) {
                groups = new ThreadGroupEx[4];
            } else if (ngroups == groups.length) {
                size_t limit = min(ngroups * 2, groups.length);
                groups = groups[0..limit].dup;
            }
            groups[ngroups] = g;

            // This is done last so it doesn't matter in case the
            // thread is killed
            ngroups++;
        }
    }

    /**
     * Removes the specified Thread group from this group.
     * @param g the Thread group to be removed
     * @return if this Thread has already been destroyed.
     */
    private void remove(ThreadGroupEx g) {
        synchronized (this) {
            if (destroyed) {
                return;
            }
            for (int i = 0 ; i < ngroups ; i++) {
                if (groups[i] == g) {
                    ngroups -= 1;
                    // System.arraycopy(groups, i + 1, groups, i, ngroups - i);
                    for(int j=i; j<ngroups; j++)
                        groups[j] = groups[j+1];                    
                    // Zap dangling reference to the dead group so that
                    // the garbage collector will collect it.
                    groups[ngroups] = null;
                    break;
                }
            }
            if (nthreads == 0) {
                // TODO: Tasks pending completion -@zxp at 12/19/2018, 4:57:38 PM
                // 
                // notifyAll();
            }
            if (daemon && (nthreads == 0) &&
                (nUnstartedThreads == 0) && (ngroups == 0))
            {
                // TODO: Tasks pending completion -@zxp at 12/19/2018, 4:57:42 PM
                // 
                // destroy();
            }
        }
    }


    /**
     * Increments the count of unstarted threads in the thread group.
     * Unstarted threads are not added to the thread group so that they
     * can be collected if they are never started, but they must be
     * counted so that daemon thread groups with unstarted threads in
     * them are not destroyed.
     */
    void addUnstarted() {
        synchronized(this) {
            if (destroyed) {
                throw new IllegalThreadStateException();
            }
            nUnstartedThreads++;
        }
    }

    /**
     * Adds the specified thread to this thread group.
     *
     * <p> Note: This method is called from both library code
     * and the Virtual Machine. It is called from VM to add
     * certain system threads to the system thread group.
     *
     * @param  t
     *         the Thread to be added
     *
     * @throws IllegalThreadStateException
     *          if the Thread group has been destroyed
     */
    void add(Thread t) {
        synchronized (this) {
            if (destroyed) {
                throw new IllegalThreadStateException();
            }
            if (threads == null) {
                threads = new Thread[4];
            } else if (nthreads == threads.length) {
                size_t limit = min(nthreads * 2, threads.length);
                threads = threads[0..limit].dup;
            }
            threads[nthreads] = t;

            // This is done last so it doesn't matter in case the
            // thread is killed
            nthreads++;

            // The thread is now a fully fledged member of the group, even
            // though it may, or may not, have been started yet. It will prevent
            // the group from being destroyed so the unstarted Threads count is
            // decremented.
            nUnstartedThreads--;
        }
    }

    /**
     * Notifies the group that the thread {@code t} has failed
     * an attempt to start.
     *
     * <p> The state of this thread group is rolled back as if the
     * attempt to start the thread has never occurred. The thread is again
     * considered an unstarted member of the thread group, and a subsequent
     * attempt to start the thread is permitted.
     *
     * @param  t
     *         the Thread whose start method was invoked
     */
    void threadStartFailed(Thread t) {
        synchronized(this) {
            remove(t);
            nUnstartedThreads++;
        }
    }

    /**
     * Notifies the group that the thread {@code t} has terminated.
     *
     * <p> Destroy the group if all of the following conditions are
     * true: this is a daemon thread group; there are no more alive
     * or unstarted threads in the group; there are no subgroups in
     * this thread group.
     *
     * @param  t
     *         the Thread that has terminated
     */
    void threadTerminated(Thread t) {
        synchronized (this) {
            remove(t);

            if (nthreads == 0) {
                // TODO: Tasks pending completion -@zxp at 12/19/2018, 4:57:55 PM
                // 
                // notifyAll();
            }
            if (daemon && (nthreads == 0) &&
                (nUnstartedThreads == 0) && (ngroups == 0))
            {
                destroy();
            }
        }
    }

    /**
     * Removes the specified Thread from this group. Invoking this method
     * on a thread group that has been destroyed has no effect.
     *
     * @param  t
     *         the Thread to be removed
     */
    private void remove(Thread t) {
        synchronized (this) {
            if (destroyed) {
                return;
            }
            for (int i = 0 ; i < nthreads ; i++) {
                if (threads[i] == t) {
                    // System.arraycopy(threads, i + 1, threads, i, --nthreads - i);
                    for(int j=i; j<ngroups; j++)
                        groups[j] = groups[j+1];                    
                    // Zap dangling reference to the dead thread so that
                    // the garbage collector will collect it.
                    threads[nthreads] = null;
                    break;
                }
            }
        }
    }

    /**
     * Prints information about this thread group to the standard
     * output. This method is useful only for debugging.
     *
     * @since   1.0
     */
    void list() {
        // list(System.out, 0);
    }
    // void list(PrintStream out, int indent) {
    //     int ngroupsSnapshot;
    //     ThreadGroupEx[] groupsSnapshot;
    //     synchronized (this) {
    //         for (int j = 0 ; j < indent ; j++) {
    //             out.print(" ");
    //         }
    //         out.println(this);
    //         indent += 4;
    //         for (int i = 0 ; i < nthreads ; i++) {
    //             for (int j = 0 ; j < indent ; j++) {
    //                 out.print(" ");
    //             }
    //             out.println(threads[i]);
    //         }
    //         ngroupsSnapshot = ngroups;
    //         if (groups !is null) {
    //             groupsSnapshot = Arrays.copyOf(groups, ngroupsSnapshot);
    //         } else {
    //             groupsSnapshot = null;
    //         }
    //     }
    //     for (int i = 0 ; i < ngroupsSnapshot ; i++) {
    //         groupsSnapshot[i].list(out, indent);
    //     }
    // }

    /**
     * Called by the Java Virtual Machine when a thread in this
     * thread group stops because of an uncaught exception, and the thread
     * does not have a specific {@link Thread.UncaughtExceptionHandler}
     * installed.
     * <p>
     * The {@code uncaughtException} method of
     * {@code ThreadGroupEx} does the following:
     * <ul>
     * <li>If this thread group has a parent thread group, the
     *     {@code uncaughtException} method of that parent is called
     *     with the same two arguments.
     * <li>Otherwise, this method checks to see if there is a
     *     {@linkplain Thread#getDefaultUncaughtExceptionHandler default
     *     uncaught exception handler} installed, and if so, its
     *     {@code uncaughtException} method is called with the same
     *     two arguments.
     * <li>Otherwise, this method determines if the {@code Throwable}
     *     argument is an instance of {@link ThreadDeath}. If so, nothing
     *     special is done. Otherwise, a message containing the
     *     thread's name, as returned from the thread's {@link
     *     Thread#getName getName} method, and a stack backtrace,
     *     using the {@code Throwable}'s {@link
     *     Throwable#printStackTrace printStackTrace} method, is
     *     printed to the {@linkplain System#err standard error stream}.
     * </ul>
     * <p>
     * Applications can override this method in subclasses of
     * {@code ThreadGroupEx} to provide alternative handling of
     * uncaught exceptions.
     *
     * @param   t   the thread that is about to exit.
     * @param   e   the uncaught exception.
     * @since   1.0
     */
    void uncaughtException(Thread t, Throwable e) {
        if (parent !is null) {
            parent.uncaughtException(t, e);
        } else {
            // Thread.UncaughtExceptionHandler ueh =
            //     Thread.getDefaultUncaughtExceptionHandler();
            // if (ueh !is null) {
            //     ueh.uncaughtException(t, e);
            // } else if (!(e instanceof ThreadDeath)) {
            //     System.err.print("Exception in thread \""
            //                      + t.getName() + "\" ");
            //     e.printStackTrace(System.err);
            // }
        }
    }

    /**
     * Used by VM to control lowmem implicit suspension.
     *
     * @param b bool to allow or disallow suspension
     * @return true on success
     * @since   1.1
     * @deprecated The definition of this call depends on {@link #suspend},
     *             which is deprecated.  Further, the behavior of this call
     *             was never specified.
     */
    // @Deprecated(since="1.2")
    // bool allowThreadSuspension(bool b) {
    //     return true;
    // }

    /**
     * Returns a string representation of this Thread group.
     *
     * @return  a string representation of this thread group.
     * @since   1.0
     */
    // string toString() {
    //     return getClass().getName() + "[name=" + getName() + ",maxpri=" + maxPriority + "]";
    // }
}
