module hunt.concurrency.ForkJoinTaskHelper;

import hunt.Exceptions;
import hunt.util.WeakReference;

import core.sync.condition;
import core.sync.mutex;
import core.thread;

import std.exception;

alias ReentrantLock = Mutex;


interface IForkJoinTask {
    /**
     * The status field holds run control status bits packed into a
     * single int to ensure atomicity.  Status is initially zero, and
     * takes on nonnegative values until completed, upon which it
     * holds (sign bit) DONE, possibly with ABNORMAL (cancelled or
     * exceptional) and THROWN (in which case an exception has been
     * stored). Tasks with dependent blocked waiting joiners have the
     * SIGNAL bit set.  Completion of a task with SIGNAL set awakens
     * any waiters via notifyAll. (Waiters also help signal others
     * upon completion.)
     *
     * These control bits occupy only (some of) the upper half (16
     * bits) of status field. The lower bits are used for user-defined
     * tags.
     */
    int getStatus(); // accessed directly by pool and workers

    int doExec();

    void internalWait(long timeout);

    bool cancel(bool mayInterruptIfRunning);

    /**
     * Cancels, ignoring any exceptions thrown by cancel. Used during
     * worker and pool shutdown. Cancel is spec'ed not to throw any
     * exceptions, but if it does anyway, we have no recourse during
     * shutdown, so guard against this case.
     */
    static void cancelIgnoringExceptions(IForkJoinTask t) {
        if (t !is null && t.getStatus() >= 0) {
            try {
                t.cancel(false);
            } catch (Throwable ignore) {
            }
        }
    }
}



/**
 * Key-value nodes for exception table.  The chained hash table
 * uses identity comparisons, full locking, and weak references
 * for keys. The table has a fixed capacity because it only
 * maintains task exceptions long enough for joiners to access
 * them, so should never become very large for sustained
 * periods. However, since we do not know when the last joiner
 * completes, we must use weak references and expunge them. We do
 * so on each operation (hence full locking). Also, some thread in
 * any ForkJoinPool will call helpExpungeStaleExceptions when its
 * pool becomes isQuiescent.
 */
final class ExceptionNode : WeakReference!IForkJoinTask { 
    Throwable ex;
    ExceptionNode next;
    ThreadID thrower;  // use id not ref to avoid weak cycles
    size_t hashCode;  // store task hashCode before weak ref disappears
    this(IForkJoinTask task, Throwable ex, ExceptionNode next) {
        this.ex = ex;
        this.next = next;
        this.thrower = Thread.getThis().id();
        this.hashCode = hashOf(task);
        super(task);
    }
}


/**
*/
struct ForkJoinTaskHelper {

    // Exception table support

    /**
     * Hash table of exceptions thrown by tasks, to enable reporting
     * by callers. Because exceptions are rare, we don't directly keep
     * them with task objects, but instead use a weak ref table.  Note
     * that cancellation exceptions don't appear in the table, but are
     * instead recorded as status values.
     *
     * The exception table has a fixed capacity.
     */
    package __gshared ExceptionNode[] exceptionTable;

    /** Lock protecting access to exceptionTable. */
    package __gshared ReentrantLock exceptionTableLock;

    shared static this() {
        exceptionTable = new ExceptionNode[32];
        exceptionTableLock = new ReentrantLock();
    }

    /**
     * A version of "sneaky throw" to relay exceptions.
     */
    static void rethrow(Throwable ex) {
        uncheckedThrow!(RuntimeException)(ex);
    }

    /**
     * The sneaky part of sneaky throw, relying on generics
     * limitations to evade compiler complaints about rethrowing
     * unchecked exceptions.
     */
    static void uncheckedThrow(T)(Throwable t) if(is(T : Throwable)) {
        if (t !is null)
            throw cast(T)t; // rely on vacuous cast
        else
            throw new Error("Unknown Exception");
    }
}
