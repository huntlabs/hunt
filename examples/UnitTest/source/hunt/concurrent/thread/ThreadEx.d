module hunt.concurrent.thread.ThreadEx;

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

/**
*/
class ThreadEx : Thread {

    Object parkBlocker;

    this(void function() fn, size_t sz = 0) nothrow {
        super(fn, sz);
        initialize();
    }

    this(void delegate() dg, size_t sz = 0) nothrow {
        super(dg , sz);
        initialize();
    }

    private void initialize() nothrow {
        _parker = Parker.allocate(this);
    }

    // void run() {
    //     start();
    //     _tid = getTid();
    // }

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


//   static void start(Thread* thread);
//   static void interrupt(Thread* thr);
//   static bool is_interrupted(Thread* thr, bool clear_interrupted);

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
