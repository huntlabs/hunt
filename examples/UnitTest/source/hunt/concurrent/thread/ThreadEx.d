module hunt.concurrent.thread.ThreadEx;

import hunt.lang.common;
import hunt.logging.ConsoleLogger;
import hunt.util.memory;

import core.atomic;
import core.thread;
import core.time;
import core.sync.condition;
import core.sync.mutex;


version (Posix) {
    import hunt.sys.syscall;

    ThreadID getTid() {
        version(FreeBSD) {
            long tid;
            syscall(SYS_thr_self, &tid);
            return cast(ThreadID)tid;
        } else version(OSX) {
            return cast(ThreadID)syscall(SYS_thread_selfid);
        } else version(linux) {
            return cast(ThreadID)syscall(__NR_gettid);
        } else {
            return 0;
        }
    }
} else {
    import core.sys.windows.winbase: GetCurrentThreadId;
    ThreadID getTid() {
        return GetCurrentThreadId();
    }
}

interface Interruptible {

    void interrupt(Thread t);

}

/**
*/
class ThreadEx : Thread {

    Object parkBlocker;

    /* The object in which this thread is blocked in an interruptible I/O
     * operation, if any.  The blocker's interrupt method should be invoked
     * after setting this thread's interrupt status.
     */
    private Interruptible blocker;
    private Object blockerLock;
    private shared bool _interrupted;     // Thread.isInterrupted state

    this(Runnable target, size_t sz = 0) {
        this({ target.run(); }, sz);
    }

    this(void function() fn, size_t sz = 0) nothrow {
        super(fn, sz);
        initialize();
    }

    this(void delegate() dg, size_t sz = 0) nothrow {
        super(dg , sz);
        initialize();
    }

    ~this() {
        blocker = null;
        blockerLock = null;
        parkBlocker = null;
        _parker = null;
    }

    private void initialize() nothrow {
        _parker = Parker.allocate(this);
        blockerLock = new Object();
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
        // if (this !is Thread.getThis())
        //     checkAccess();

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
        _parker.unpark();

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
            // osthread->set_interrupted(false);
            // consider thread->_SleepEvent->reset() ... optional optimization
        }

        return _interrupted;
    }


    Parker parker() {
        return _parker;
    }
    private Parker _parker;

    // Low-level leaf-lock primitives used to implement synchronization
    // and native monitor-mutex infrastructure.
    // Not for general synchronization use.
    static void spinAcquire(shared(int)* adr, string name) nothrow  {
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
        ThreadEx tex = cast(ThreadEx)Thread.getThis();
        if(tex is null) {
            // FIXME: Needing refactor or cleanup -@zxp at 11/4/2018, 10:45:33 PM
            // 
            return false;
        } else {
            return tex.isInterrupted(true);
        }
    }

    static void spinRelease(shared(int)* adr) @safe nothrow @nogc {
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

    private shared int _counter;
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

    // For simplicity of interface with Java, all forms of park (indefinite,
    // relative, and absolute) are multiplexed into one call.
    // Parker.park decrements count if > 0, else does a condvar wait.  Unpark
    // sets count to 1 and signals condvar.  Only one thread ever waits
    // on the condvar. Contention seen when trying to park implies that someone
    // is unparking you, so don't wait. And spurious returns are fine, so there
    // is no need to track notifications.
    void park(Duration time) {
        bool isAbsolute = false;

        // Optional fast-path check:
        // Return immediately if a permit is available.
        // We depend on Atomic.xchg() having full barrier semantics
        // since we are doing a lock-free update to _counter.
        int old = _counter;
        atomicStore(_counter, 0);
        if (old > 0)
            return;

        Thread thread = Thread.getThis();
        ThreadEx jt = cast(ThreadEx) thread;
        // assert(jt !is null, "Must be ThreadEx");
        if(jt is null) warning("Must be ThreadEx");

        // // Optional optimization -- avoid state transitions if there's
        // // an interrupt pending.
        // if (Thread.is_interrupted(thread, false)) {
        //     return;
        // }

        // Next, demultiplex/decode time arguments
        if (time < Duration.zero || (isAbsolute && time == Duration.zero)) { // don't wait at all
            return;
        }

        // Enter safepoint region
        // Beware of deadlocks such as 6317397.
        // The per-thread Parker. mutex is a classic leaf-lock.
        // In particular a thread must never block on the Threads_lock while
        // holding the Parker. mutex.  If safepoints are pending both the
        // the ThreadBlockInVM() CTOR and DTOR may grab Threads_lock.
        //   ThreadBlockInVM tbivm(jt);

        // Don't wait if cannot get lock since interference arises from
        // unparking. Also re-check interrupt before trying wait.
        // if (Thread.is_interrupted(thread, false) || pthread_mutex_trylock(_mutex) != 0) {
        //     return;
        // }
        if(!_mutex.tryLock())
            return;

        if (_counter > 0) { // no wait needed
            _counter = 0;
            _mutex.unlock();
            // Paranoia to ensure our locked and lock-free paths interact
            // correctly with each other and Java-level accesses.
            atomicFence();
            return;
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
            _cur_index = isAbsolute ? ABS_INDEX : REL_INDEX;
            _cond[_cur_index].wait(time);
        }
        _cur_index = -1;

        _counter = 0;
        _mutex.unlock();
        // Paranoia to ensure our locked and lock-free paths interact
        // correctly with each other and Java-level accesses.
        atomicFence();

        // // If externally suspended while waiting, re-suspend
        // if (jt.handle_special_suspend_equivalent_condition()) {
        //     jt.java_suspend_self();
        // }
    }

    void unpark() {
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
