/*
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.  Oracle designates this
 * particular file as subject to the "Classpath" exception as provided
 * by Oracle in the LICENSE file that accompanied this code.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 *
 * You should have received a copy of the GNU General Public License version
 * 2 along with this work; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
 * or visit www.oracle.com if you need additional information or have any
 * questions.
 */

/*
 * This file is available under and governed by the GNU General Public
 * License version 2 only, as published by the Free Software Foundation.
 * However, the following notice accompanied the original version of this
 * file:
 *
 * Written by Doug Lea with assistance from members of JCP JSR-166
 * Expert Group and released to the domain, as explained at
 * http://creativecommons.org/publicdomain/zero/1.0/
 */

module hunt.concurrency.FutureTask;

import hunt.concurrency.atomic.AtomicHelper;
import hunt.concurrency.Executors;
import hunt.concurrency.Future;
import hunt.concurrency.thread;
import hunt.Exceptions;
import hunt.util.Common;

import core.thread;
import core.time;

import hunt.concurrency.thread;
import hunt.logging.ConsoleLogger;


/**
 * A cancellable asynchronous computation.  This class provides a base
 * implementation of {@link Future}, with methods to start and cancel
 * a computation, query to see if the computation is complete, and
 * retrieve the result of the computation.  The result can only be
 * retrieved when the computation has completed; the {@code get}
 * methods will block if the computation has not yet completed.  Once
 * the computation has completed, the computation cannot be restarted
 * or cancelled (unless the computation is invoked using
 * {@link #runAndReset}).
 *
 * <p>A {@code FutureTask} can be used to wrap a {@link Callable} or
 * {@link Runnable} object.  Because {@code FutureTask} implements
 * {@code Runnable}, a {@code FutureTask} can be submitted to an
 * {@link Executor} for execution.
 *
 * <p>In addition to serving as a standalone class, this class provides
 * {@code protected} functionality that may be useful when creating
 * customized task classes.
 *
 * @since 1.5
 * @author Doug Lea
 * @param (V) The result type returned by this FutureTask's {@code get} methods
 */
class FutureTask(V) : RunnableFuture!(V) {
    /*
     * Revision notes: This differs from previous versions of this
     * class that relied on AbstractQueuedSynchronizer, mainly to
     * avoid surprising users about retaining interrupt status during
     * cancellation races. Sync control in the current design relies
     * on a "state" field updated via CAS to track completion, along
     * with a simple Treiber stack to hold waiting threads.
     */

    /**
     * The run state of this task, initially NEW.  The run state
     * transitions to a terminal state only in methods set,
     * setException, and cancel.  During completion, state may take on
     * values of COMPLETING (while outcome is being set) or
     * INTERRUPTING (only while interrupting the runner to satisfy a
     * cancel(true)). Transitions from these intermediate to final
     * states use cheaper ordered/lazy writes because values are unique
     * and cannot be further modified.
     *
     * Possible state transitions:
     * NEW -> COMPLETING -> NORMAL
     * NEW -> COMPLETING -> EXCEPTIONAL
     * NEW -> CANCELLED
     * NEW -> INTERRUPTING -> INTERRUPTED
     */
    private shared(int) state;
    private enum int NEW          = 0;
    private enum int COMPLETING   = 1;
    private enum int NORMAL       = 2;
    private enum int EXCEPTIONAL  = 3;
    private enum int CANCELLED    = 4;
    private enum int INTERRUPTING = 5;
    private enum int INTERRUPTED  = 6;

    /** The underlying callable; nulled out after running */
    private Callable!(V) callable;
    /** The result to return or exception to throw from get() */
    static if(!is(V == void)) {
        private V outcome; // non-volatile, protected by state reads/writes
    }
    private Throwable exception;
    /** The thread running the callable; CASed during run() */
    private Thread runner;
    /** Treiber stack of waiting threads */
    private WaitNode waiters;

    /**
     * Returns result or throws exception for completed task.
     *
     * @param s completed state value
     */

    private V report(int s) {
        // Object x = outcome;
        if (s == NORMAL) {
            static if(!is(V == void)) {
                return outcome; // cast(V)
            } else {
                return ; // cast(V)
            }
        }
            
        if (s >= CANCELLED)
            throw new CancellationException();
        throw new ExecutionException(exception);
    }

    /**
     * Creates a {@code FutureTask} that will, upon running, execute the
     * given {@code Callable}.
     *
     * @param  callable the callable task
     * @throws NullPointerException if the callable is null
     */
    this(Callable!(V) callable) {
        if (callable is null)
            throw new NullPointerException();
        this.callable = callable;
        this.state = NEW;       // ensure visibility of callable
    }

    /**
     * Creates a {@code FutureTask} that will, upon running, execute the
     * given {@code Runnable}, and arrange that {@code get} will return the
     * given result on successful completion.
     *
     * @param runnable the runnable task
     * @param result the result to return on successful completion. If
     * you don't need a particular result, consider using
     * constructions of the form:
     * {@code Future<?> f = new FutureTask!(void)(runnable, null)}
     * @throws NullPointerException if the runnable is null
     */
static if(is(V == void)) {
    this(Runnable runnable) {
        this.callable = Executors.callable(runnable);
        this.state = NEW;       // ensure visibility of callable
    }
} else {
    this(Runnable runnable, V result) {
        this.callable = Executors.callable(runnable, result);
        this.state = NEW;       // ensure visibility of callable
    }
}

    bool isCancelled() {
        return state >= CANCELLED;
    }

    bool isDone() {
        return state != NEW;
    }

    bool cancel(bool mayInterruptIfRunning) {
        if (!(state == NEW && AtomicHelper.compareAndSet(state, NEW,
            mayInterruptIfRunning ? INTERRUPTING : CANCELLED)))
            return false;
        try {    // in case call to interrupt throws exception
            if (mayInterruptIfRunning) {
                try {
                    ThreadEx t = cast(ThreadEx) runner;
                    if (t !is null)
                        t.interrupt();
                } finally { // final state
                    AtomicHelper.store(state, INTERRUPTED);
                }
            }
        } finally {
            finishCompletion();
        }
        return true;
    }

    /**
     * @throws CancellationException {@inheritDoc}
     */
    V get() {
        int s = state;
        if (s <= COMPLETING)
            s = awaitDone(false, Duration.zero);
        return report(s);
    }

    /**
     * @throws CancellationException {@inheritDoc}
     */
    V get(Duration timeout) {
        int s = state;
        if (s <= COMPLETING &&
            (s = awaitDone(true, timeout)) <= COMPLETING)
            throw new TimeoutException();
        return report(s);
    }

    /**
     * Protected method invoked when this task transitions to state
     * {@code isDone} (whether normally or via cancellation). The
     * default implementation does nothing.  Subclasses may override
     * this method to invoke completion callbacks or perform
     * bookkeeping. Note that you can query status inside the
     * implementation of this method to determine whether this task
     * has been cancelled.
     */
    protected void done() { }

    /**
     * Sets the result of this future to the given value unless
     * this future has already been set or has been cancelled.
     *
     * <p>This method is invoked internally by the {@link #run} method
     * upon successful completion of the computation.
     *
     * @param v the value
     */

static if(is(V == void)) {
    protected void set() {
        if (AtomicHelper.compareAndSet(state, NEW, COMPLETING)) {
            // outcome = v;
            AtomicHelper.store(state, NORMAL);  // final state
            finishCompletion();
        }
    }

    void run() {
        if (state != NEW ||
            !AtomicHelper.compareAndSet(runner, null, Thread.getThis()))
            return;
        try {
            Callable!(V) c = callable;
            if (c !is null && state == NEW) {
                bool ran;
                try {
                    c.call();
                    ran = true;
                } catch (Throwable ex) {
                    ran = false;
                    setException(ex);
                }
                if (ran)
                    set();
            }
        } finally {
            // runner must be non-null until state is settled to
            // prevent concurrent calls to run()
            runner = null;
            // state must be re-read after nulling runner to prevent
            // leaked interrupts
            int s = state;
            if (s >= INTERRUPTING)
                handlePossibleCancellationInterrupt(s);
        }
    }    
} else {
    protected void set(V v) {
        if (AtomicHelper.compareAndSet(state, NEW, COMPLETING)) {
            outcome = v;
            AtomicHelper.store(state, NORMAL);  // final state
            finishCompletion();
        }
    }

    void run() {
        if (state != NEW ||
            !AtomicHelper.compareAndSet(runner, null, Thread.getThis()))
            return;
        try {
            Callable!(V) c = callable;
            if (c !is null && state == NEW) {
                V result;
                bool ran;
                try {
                    result = c.call();
                    ran = true;
                } catch (Throwable ex) {
                    result = V.init;
                    ran = false;
                    setException(ex);
                }
                if (ran)
                    set(result);
            }
        } finally {
            // runner must be non-null until state is settled to
            // prevent concurrent calls to run()
            runner = null;
            // state must be re-read after nulling runner to prevent
            // leaked interrupts
            int s = state;
            if (s >= INTERRUPTING)
                handlePossibleCancellationInterrupt(s);
        }
    }    
}

    /**
     * Causes this future to report an {@link ExecutionException}
     * with the given throwable as its cause, unless this future has
     * already been set or has been cancelled.
     *
     * <p>This method is invoked internally by the {@link #run} method
     * upon failure of the computation.
     *
     * @param t the cause of failure
     */
    protected void setException(Throwable t) {
        if (AtomicHelper.compareAndSet(state, NEW, COMPLETING)) {
            exception = t;
            AtomicHelper.store(state, EXCEPTIONAL); // final state
            finishCompletion();
        }
    }

    /**
     * Executes the computation without setting its result, and then
     * resets this future to initial state, failing to do so if the
     * computation encounters an exception or is cancelled.  This is
     * designed for use with tasks that intrinsically execute more
     * than once.
     *
     * @return {@code true} if successfully run and reset
     */
    protected bool runAndReset() {
        if (state != NEW ||
            !AtomicHelper.compareAndSet(runner, null, Thread.getThis()))
            return false;
        bool ran = false;
        int s = state;
        try {
            Callable!(V) c = callable;
            if (c !is null && s == NEW) {
                try {
                    c.call(); // don't set result
                    ran = true;
                } catch (Throwable ex) {
                    setException(ex);
                }
            }
        } finally {
            // runner must be non-null until state is settled to
            // prevent concurrent calls to run()
            runner = null;
            // state must be re-read after nulling runner to prevent
            // leaked interrupts
            s = state;
            if (s >= INTERRUPTING)
                handlePossibleCancellationInterrupt(s);
        }
        return ran && s == NEW;
    }

    /**
     * Ensures that any interrupt from a possible cancel(true) is only
     * delivered to a task while in run or runAndReset.
     */
    private void handlePossibleCancellationInterrupt(int s) {
        // It is possible for our interrupter to stall before getting a
        // chance to interrupt us.  Let's spin-wait patiently.
        if (s == INTERRUPTING)
            while (state == INTERRUPTING)
                Thread.yield(); // wait out pending interrupt

        assert(state == INTERRUPTED);

        // We want to clear any interrupt we may have received from
        // cancel(true).  However, it is permissible to use interrupts
        // as an independent mechanism for a task to communicate with
        // its caller, and there is no way to clear only the
        // cancellation interrupt.
        //
        ThreadEx.interrupted();
    }

    /**
     * Simple linked list nodes to record waiting threads in a Treiber
     * stack.  See other classes such as Phaser and SynchronousQueue
     * for more detailed explanation.
     */
    static final class WaitNode {
        Thread thread;
        WaitNode next;
        this() { thread = Thread.getThis(); }
    }

    /**
     * Removes and signals all waiting threads, invokes done(), and
     * nulls out callable.
     */
    private void finishCompletion() {
        // assert state > COMPLETING;
        for (WaitNode q; (q = waiters) !is null;) {
            if (AtomicHelper.compareAndSet(waiters, q, null)) {
                for (;;) {
                    Thread t = q.thread;
                    if (t !is null) {
                        q.thread = null;
                        LockSupport.unpark(t);
                    }
                    WaitNode next = q.next;
                    if (next is null)
                        break;
                    q.next = null; // unlink to help gc
                    q = next;
                }
                break;
            }
        }

        done();

        callable = null;        // to reduce footprint
    }

    /**
     * Awaits completion or aborts on interrupt or timeout.
     *
     * @param timed true if use timed waits
     * @param duration time to wait, if timed
     * @return state upon completion or at timeout
     */
    private int awaitDone(bool timed, Duration timeout) {
        // The code below is very delicate, to achieve these goals:
        // - call nanoTime exactly once for each call to park
        // - if nanos <= 0L, return promptly without allocation or nanoTime
        // - if nanos == Long.MIN_VALUE, don't underflow
        // - if nanos == Long.MAX_VALUE, and nanoTime is non-monotonic
        //   and we suffer a spurious wakeup, we will do no worse than
        //   to park-spin for a while
        MonoTime startTime = MonoTime.zero;    // Special value 0L means not yet parked
        WaitNode q = null;
        bool queued = false;
        for (;;) {
            int s = state;
            if (s > COMPLETING) {
                if (q !is null)
                    q.thread = null;
                return s;
            } else if (s == COMPLETING) {
                // We may have already promised (via isDone) that we are done
                // so never return empty-handed or throw InterruptedException
                Thread.yield();
            } else if (ThreadEx.interrupted()) {
                removeWaiter(q);
                throw new InterruptedException();
            } else if (q is null) {
                if (timed && timeout <= Duration.zero)
                    return s;
                q = new WaitNode();
            } else if (!queued) {
                queued = AtomicHelper.compareAndSet!(WaitNode)(waiters, q.next = waiters, q);
            } else if (timed) {
                Duration parkDuration;
                if (startTime == MonoTime.zero) { // first time
                    startTime = MonoTime.currTime;
                    if (startTime == MonoTime.zero)
                        startTime = MonoTime(1);
                    parkDuration = timeout;
                } else {                    
                    Duration elapsed = MonoTime.currTime - startTime;
                    if (elapsed >= timeout) {
                        removeWaiter(q);
                        return state;
                    }
                    parkDuration = timeout - elapsed;
                }
                // nanoTime may be slow; recheck before parking
                if (state < COMPLETING) {
                    LockSupport.park(this, parkDuration);
                }
            } else {
                LockSupport.park(this);
            }
        }
    }

    /**
     * Tries to unlink a timed-out or interrupted wait node to avoid
     * accumulating garbage.  Internal nodes are simply unspliced
     * without CAS since it is harmless if they are traversed anyway
     * by releasers.  To avoid effects of unsplicing from already
     * removed nodes, the list is retraversed in case of an apparent
     * race.  This is slow when there are a lot of nodes, but we don't
     * expect lists to be long enough to outweigh higher-overhead
     * schemes.
     */
    private void removeWaiter(WaitNode node) {
        if (node !is null) {
            node.thread = null;
            retry:
            for (;;) {          // restart on removeWaiter race
                for (WaitNode pred = null, q = waiters, s; q !is null; q = s) {
                    s = q.next;
                    if (q.thread !is null)
                        pred = q;
                    else if (pred !is null) {
                        pred.next = s;
                        if (pred.thread is null) // check for race
                            continue retry;
                    }
                    else if (!AtomicHelper.compareAndSet(waiters, q, s))
                        continue retry;
                }
                break;
            }
        }
    }

    /**
     * Returns a string representation of this FutureTask.
     *
     * @implSpec
     * The default implementation returns a string identifying this
     * FutureTask, as well as its completion state.  The state, in
     * brackets, contains one of the strings {@code "Completed Normally"},
     * {@code "Completed Exceptionally"}, {@code "Cancelled"}, or {@code
     * "Not completed"}.
     *
     * @return a string representation of this FutureTask
     */
    override string toString() {
        string status;
        switch (state) {
        case NORMAL:
            status = "[Completed normally]";
            break;
        case EXCEPTIONAL:
            status = "[Completed exceptionally: " ~ exception.toString() ~ "]";
            break;
        case CANCELLED:
        case INTERRUPTING:
        case INTERRUPTED:
            status = "[Cancelled]";
            break;
        default:
            Callable!V callable = this.callable;
            status = (callable is null)
                ? "[Not completed]"
                : "[Not completed, task = " ~ (cast(Object)callable).toString() ~ "]";
        }
        return super.toString() ~ status;
    }

}
