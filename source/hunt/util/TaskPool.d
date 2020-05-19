module hunt.util.TaskPool;

import hunt.io.SimpleQueue;
import hunt.logging.ConsoleLogger;
import hunt.system.Memory;
import hunt.util.Common;

import core.thread;
import core.atomic;
import core.sync.condition;
import core.sync.mutex;

import std.conv;
import std.format;
import std.traits;

private enum TaskStatus : ubyte {
    ready,
    processing,
    done
}

/* Atomics code.  These forward to core.atomic, but are written like this
   for two reasons:

   1.  They used to actually contain ASM code and I don' want to have to change
       to directly calling core.atomic in a zillion different places.

   2.  core.atomic has some misc. issues that make my use cases difficult
       without wrapping it.  If I didn't wrap it, casts would be required
       basically everywhere.
*/
private void atomicSetUbyte(T)(ref T stuff, T newVal)
        if (__traits(isIntegral, T) && is(T : ubyte)) {
    //core.atomic.cas(cast(shared) &stuff, stuff, newVal);
    atomicStore(*(cast(shared)&stuff), newVal);
}

private ubyte atomicReadUbyte(T)(ref T val)
        if (__traits(isIntegral, T) && is(T : ubyte)) {
    return atomicLoad(*(cast(shared)&val));
}

// This gets rid of the need for a lot of annoying casts in other parts of the
// code, when enums are involved.
private bool atomicCasUbyte(T)(ref T stuff, T testVal, T newVal)
        if (__traits(isIntegral, T) && is(T : ubyte)) {
    return core.atomic.cas(cast(shared)&stuff, testVal, newVal);
}


/**
 * 
 */
class AbstractTask : Runnable {

    Throwable exception;
    ubyte taskStatus = TaskStatus.ready;

    final void run() {
        atomicSetUbyte(taskStatus, TaskStatus.processing);
        try {
            onRun();
        } catch (Throwable e) {
            exception = e;
            debug warning(e.msg);
            version(HUNT_DEBUG) {
                warning(e);
            } 
        }

        atomicSetUbyte(taskStatus, TaskStatus.done);
    }

    abstract protected void onRun();

    bool done() @property {
        if (atomicReadUbyte(taskStatus) == TaskStatus.done) {
            if (exception) {
                throw exception;
            }
            return true;
        }
        return false;
    }
}

/**
 * 
 */
class Task(alias fun, Args...) : AbstractTask {
    Args _args;

    static if (Args.length > 0) {
        this(Args args) {
            _args = args;
        }
    } else {
        this() {
        }
    }

    /**
    The return type of the function called by this `Task`.  This can be
    `void`.
    */
    alias ReturnType = typeof(fun(_args));

    static if (!is(ReturnType == void)) {
        static if (is(typeof(&fun(_args)))) {
            // Ref return.
            ReturnType* returnVal;

            ref ReturnType fixRef(ReturnType* val) {
                return *val;
            }

        } else {
            ReturnType returnVal;

            ref ReturnType fixRef(ref ReturnType val) {
                return val;
            }
        }
    }

    private static void impl(AbstractTask myTask) {
        auto myCastedTask = cast(typeof(this)) myTask;
        static if (is(ReturnType == void)) {
            fun(myCastedTask._args);
        } else static if (is(typeof(addressOf(fun(myCastedTask._args))))) {
            myCastedTask.returnVal = addressOf(fun(myCastedTask._args));
        } else {
            myCastedTask.returnVal = fun(myCastedTask._args);
        }
    }

    protected override void onRun() {
        impl(this);
    }
}

T* addressOf(T)(ref T val) {
    return &val;
}

auto makeTask(alias fun, Args...)(Args args) {
    return new Task!(fun, Args)(args);
}

auto makeTask(F, Args...)(F delegateOrFp, Args args)
        if (is(typeof(delegateOrFp(args)))) // && !isSafeTask!F
        {
    return new Task!(run, F, Args)(delegateOrFp, args);
}

// Calls `fpOrDelegate` with `args`.  This is an
// adapter that makes `Task` work with delegates, function pointers and
// functors instead of just aliases.
ReturnType!F run(F, Args...)(F fpOrDelegate, ref Args args) {
    return fpOrDelegate(args);
}

/*
This class serves two purposes:

1.  It distinguishes std.parallelism threads from other threads so that
    the std.parallelism daemon threads can be terminated.

2.  It adds a reference to the pool that the thread is a member of,
    which is also necessary to allow the daemon threads to be properly
    terminated.
*/
final class ParallelismThread : Thread {

    this(void delegate() dg) {
        super(dg);
        taskQueue = new BlockingQueue!(AbstractTask)();
        state = ThreadState.NEW;
    }

    ThreadState state;
    int factor = -1;

    TaskPool pool;
    Queue!(AbstractTask) taskQueue;
}

enum ThreadState {
    NEW,
    BUSY,
    IDLE,
    TERMINATED
}

/**
 * 
 */
enum PoolState : ubyte {
    running,
    finishing,
    stopNow
}

/**
 * 
 */
class PoolStatus {
    size_t total;

    int active;

    int idle;
    
    int waiting;

    override string toString() {
        return format("total: %d, active: %d, idle: %d, waiting: %d", 
            total, active, idle, waiting);
    }
}

/** 
 *
 */
class TaskPool {

    private ParallelismThread[] pool;
    private PoolState status = PoolState.running;

    // The instanceStartIndex of the next instance that will be created.
    // __gshared size_t nextInstanceIndex = 1;

    // The index of the first thread in this instance.
    // immutable size_t instanceStartIndex;

    // The index of the current thread.
    static size_t threadIndex;

    // The index that the next thread to be initialized in this pool will have.
    shared size_t nextThreadIndex;

    Condition workerCondition;
    Condition waiterCondition;
    Mutex queueMutex;
    Mutex waiterMutex; // For waiterCondition

    bool isSingleTask = false;

    /**
    Default constructor that initializes a `TaskPool` with
    `totalCPUs` - 1 worker threads.  The minus 1 is included because the
    main thread will also be available to do work.

    Note:  On single-core machines, the primitives provided by `TaskPool`
           operate transparently in single-threaded mode.
     */
    this() {
        this(totalCPUs - 1);
    }
    
    /**
    Allows for custom number of worker threads.
    */
    this(size_t nWorkers, bool isDaemon = false) {
        if (nWorkers == 0)
            nWorkers = 1;

        queueMutex = new Mutex(this);
        waiterMutex = new Mutex();
        workerCondition = new Condition(queueMutex);
        waiterCondition = new Condition(waiterMutex);
        nextThreadIndex = 0;

        pool = new ParallelismThread[nWorkers];

        foreach (size_t index, ref ParallelismThread poolThread; pool) {
            poolThread = new ParallelismThread(&startWorkLoop);
            poolThread.pool = this;
            poolThread.name = "worker-thread-" ~ index.to!string();
            poolThread.start();
        }

        this.isDaemon = isDaemon;
    }

    bool isDaemon() @property @trusted {
        return pool[0].isDaemon;
    }

    /// Ditto
    void isDaemon(bool newVal) @property @trusted {
        foreach (thread; pool) {
            thread.isDaemon = newVal;
        }
    }

    // This function performs initialization for each thread that affects
    // thread local storage and therefore must be done from within the
    // worker thread.  It then calls executeWorkLoop().
    private void startWorkLoop() {
        // Initialize thread index.
        size_t index = atomicOp!("+=")(nextThreadIndex, 1);
        threadIndex = index - 1;

        executeWorkLoop();
    }

    // This is the main work loop that worker threads spend their time in
    // until they terminate.  It's also entered by non-worker threads when
    // finish() is called with the blocking variable set to true.
    private void executeWorkLoop() {
        ParallelismThread workerThread = pool[threadIndex];
        workerThread.state = ThreadState.IDLE;
        scope(exit) {
            version(HUNT_IO_DEBUG) infof("Thread exited, threadIndex: %d, name: %s", threadIndex, workerThread.name());
            workerThread.state = ThreadState.TERMINATED;
        }

        while (atomicReadUbyte(status) != PoolState.stopNow) {
            AbstractTask task = workerThread.taskQueue.dequeue();
            if (task is null) {
                if (atomicReadUbyte(status) == PoolState.finishing) {
                    atomicSetUbyte(status, PoolState.stopNow);
                    break;
                }
            } else {
                version(HUNT_IO_DEBUG) infof("running a task in thread: %s", workerThread.name());
                workerThread.state = ThreadState.BUSY;
                // scope(exit) {
                //     workerThread.state = ThreadState.IDLE;
                // }
                
                doJob(task);
                
                workerThread.state = ThreadState.IDLE;
                workerThread.factor = -1;

                version(HUNT_IO_DEBUG) infof("A task finished in thread: %s", workerThread.name());
            }
        }

    }

    private void doJob(AbstractTask job) nothrow {        
        try {
            job.run();
        } catch(Throwable t) {
            warning(t.msg);
            version(HUNT_DEBUG) warning(t);
        }
    }

    private void waiterLock() {
        if (!isSingleTask)
            waiterMutex.lock();
    }

    private void waiterUnlock() {
        if (!isSingleTask)
            waiterMutex.unlock();
    }

    private void wait() {
        if (!isSingleTask)
            workerCondition.wait();
    }

    private void notify() {
        if (!isSingleTask)
            workerCondition.notify();
    }

    private void notifyAll() {
        if (!isSingleTask)
            workerCondition.notifyAll();
    }

    private void waitUntilCompletion() {
        waiterCondition.wait();
    }

    private void notifyWaiters() {
        if (!isSingleTask)
            waiterCondition.notifyAll();
    }

    void stop() @trusted {
        // queueLock();
        // scope(exit) queueUnlock();
        atomicSetUbyte(status, PoolState.stopNow);
        notifyAll();
    }

    void finish(bool blocking = false) @trusted {
        {
            // queueLock();
            // scope(exit) queueUnlock();
            atomicCasUbyte(status, PoolState.running, PoolState.finishing);
            notifyAll();
        }
        if (blocking) {
            // Use this thread as a worker until everything is finished.
            // stopWorkLoop();
            // taskQueue.wakeup();
            executeWorkLoop();

            foreach (t; pool) {
                // Maybe there should be something here to prevent a thread
                // from calling join() on itself if this function is called
                // from a worker thread in the same pool, but:
                //
                // 1.  Using an if statement to skip join() would result in
                //     finish() returning without all tasks being finished.
                //
                // 2.  If an exception were thrown, it would bubble up to the
                //     Task from which finish() was called and likely be
                //     swallowed.
                t.join();
            }
        }
    }

    void put(int factor, AbstractTask task) {
        int nWorkers = cast(int)pool.length;
        if(factor<0) factor = -factor;
        int i = factor % nWorkers;
        ParallelismThread selectedThread = pool[i];

        // Make sure that an IDLE thread selected
        // int j = 0;
        // while(selectedThread.state != ThreadState.IDLE) {
        //     version(HUNT_IO_DEBUG) warningf("Worker thread is busy: %s, index: %d", selectedThread.name(), i);
        //     i = (i+1) % nWorkers;
        //     selectedThread = pool[i];
        //     j++;
        //     if(j >= nWorkers) {
        //         j = 0;
        //         version(HUNT_DEBUG) warning("All the worker threads are busy. Select one randomly.");
        //         // No idle thread found after checking the whole pool.
        //         // No wait. Select one randomly.
        //         // Warning: It may be in a dead-lock status;
        //         break;
        //     }
        // }

        if(selectedThread.state != ThreadState.IDLE) {
            version(HUNT_IO_DEBUG) {
                warningf("The %s is busy, index: %d, factor: %d", selectedThread.name(), i, factor);
            }

            int lastFactor = selectedThread.factor;
            if(lastFactor != -1 && lastFactor != factor) {
                version(HUNT_DEBUG) {
                    warningf("A factor collision detected, last: %d, current: %d. " ~ 
                        "To remove this warning, increase the size of the task pool please!", 
                        lastFactor, factor);
                }

                ParallelismThread newSelectedThread = getIdleThread(factor);
                if(newSelectedThread !is null) {
                    selectedThread = newSelectedThread;
                    selectedThread.factor = factor;
                } else {
                    // TODO: Tasks pending completion -@zhangxueping at 2020-04-26T10:00:58+08:00
                    // Create a new worker thread.
                }
            } else {
                selectedThread.factor = factor;
            }
        } else {
            selectedThread.factor = factor;
        }

        version(HUNT_IO_DEBUG) {
            tracef("selected a thread: %s, index: %d", selectedThread.name(), i);
            PoolStatus status = checkStatus();
            warning(status.toString());
        }

        selectedThread.taskQueue.enqueue(task);
    }

    private ParallelismThread getIdleThread(int startIndex = 0) {
        int j = 0;
        int nWorkers = cast(int)pool.length;
        ParallelismThread selectedThread;

        do {            
            startIndex = (startIndex+1) % nWorkers;
            selectedThread = pool[startIndex];
            version(HUNT_IO_DEBUG) {
                warningf("The worker thread status: %s, index: %d", 
                selectedThread.name(), startIndex);
            }

            j++;
            if(j >= nWorkers) {
                j = 0;
                version(HUNT_DEBUG) warning("All the worker threads are busy. Then nothing selected.");
                // No idle thread found after checking the whole pool.
                // No wait. Select one randomly.
                // Warning: It may be in a dead-lock status;
                break;
            }
        } while(selectedThread.state != ThreadState.IDLE);

        return selectedThread;
    }

    PoolStatus checkStatus() {
        PoolStatus status = new PoolStatus();

        status.total = pool.length;
        foreach (ParallelismThread th; pool) {
            if(th.state == ThreadState.BUSY) {
                status.active++;
            } else if(th.state == ThreadState.IDLE) {
                status.idle++;
            }
            // tracef("Current: %s, WorkerThread: %s, state: %s", Thread.getThis().name(), t.name(), t.state);
        }

        return status;
    }
}
