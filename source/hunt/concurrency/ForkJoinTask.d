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

module hunt.concurrency.ForkJoinTask;

import hunt.concurrency.atomic;
import hunt.concurrency.Future;
import hunt.concurrency.thread;

import hunt.concurrency.ForkJoinPool;
import hunt.concurrency.ForkJoinTaskHelper;

import hunt.collection.Collection;
import hunt.logging.ConsoleLogger;
import hunt.Exceptions;
import hunt.util.Common;
import hunt.util.DateTime;

import core.time;
import core.sync.condition;
import core.sync.mutex;
import core.thread;


/**
 * Abstract base class for tasks that run within a {@link ForkJoinPool}.
 * A {@code ForkJoinTask} is a thread-like entity that is much
 * lighter weight than a normal thread.  Huge numbers of tasks and
 * subtasks may be hosted by a small number of actual threads in a
 * ForkJoinPool, at the price of some usage limitations.
 *
 * <p>A "main" {@code ForkJoinTask} begins execution when it is
 * explicitly submitted to a {@link ForkJoinPool}, or, if not already
 * engaged in a ForkJoin computation, commenced in the {@link
 * ForkJoinPool#commonPool()} via {@link #fork}, {@link #invoke}, or
 * related methods.  Once started, it will usually in turn start other
 * subtasks.  As indicated by the name of this class, many programs
 * using {@code ForkJoinTask} employ only methods {@link #fork} and
 * {@link #join}, or derivatives such as {@link
 * #invokeAll(ForkJoinTask...) invokeAll}.  However, this class also
 * provides a number of other methods that can come into play in
 * advanced usages, as well as extension mechanics that allow support
 * of new forms of fork/join processing.
 *
 * <p>A {@code ForkJoinTask} is a lightweight form of {@link Future}.
 * The efficiency of {@code ForkJoinTask}s stems from a set of
 * restrictions (that are only partially statically enforceable)
 * reflecting their main use as computational tasks calculating pure
 * functions or operating on purely isolated objects.  The primary
 * coordination mechanisms are {@link #fork}, that arranges
 * asynchronous execution, and {@link #join}, that doesn't proceed
 * until the task's result has been computed.  Computations should
 * ideally avoid {@code synchronized} methods or blocks, and should
 * minimize other blocking synchronization apart from joining other
 * tasks or using synchronizers such as Phasers that are advertised to
 * cooperate with fork/join scheduling. Subdividable tasks should also
 * not perform blocking I/O, and should ideally access variables that
 * are completely independent of those accessed by other running
 * tasks. These guidelines are loosely enforced by not permitting
 * checked exceptions such as {@code IOExceptions} to be
 * thrown. However, computations may still encounter unchecked
 * exceptions, that are rethrown to callers attempting to join
 * them. These exceptions may additionally include {@link
 * RejectedExecutionException} stemming from internal resource
 * exhaustion, such as failure to allocate internal task
 * queues. Rethrown exceptions behave in the same way as regular
 * exceptions, but, when possible, contain stack traces (as displayed
 * for example using {@code ex.printStackTrace()}) of both the thread
 * that initiated the computation as well as the thread actually
 * encountering the exception; minimally only the latter.
 *
 * <p>It is possible to define and use ForkJoinTasks that may block,
 * but doing so requires three further considerations: (1) Completion
 * of few if any <em>other</em> tasks should be dependent on a task
 * that blocks on external synchronization or I/O. Event-style async
 * tasks that are never joined (for example, those subclassing {@link
 * CountedCompleter}) often fall into this category.  (2) To minimize
 * resource impact, tasks should be small; ideally performing only the
 * (possibly) blocking action. (3) Unless the {@link
 * ForkJoinPool.ManagedBlocker} API is used, or the number of possibly
 * blocked tasks is known to be less than the pool's {@link
 * ForkJoinPool#getParallelism} level, the pool cannot guarantee that
 * enough threads will be available to ensure progress or good
 * performance.
 *
 * <p>The primary method for awaiting completion and extracting
 * results of a task is {@link #join}, but there are several variants:
 * The {@link Future#get} methods support interruptible and/or timed
 * waits for completion and report results using {@code Future}
 * conventions. Method {@link #invoke} is semantically
 * equivalent to {@code fork(); join()} but always attempts to begin
 * execution in the current thread. The "<em>quiet</em>" forms of
 * these methods do not extract results or report exceptions. These
 * may be useful when a set of tasks are being executed, and you need
 * to delay processing of results or exceptions until all complete.
 * Method {@code invokeAll} (available in multiple versions)
 * performs the most common form of parallel invocation: forking a set
 * of tasks and joining them all.
 *
 * <p>In the most typical usages, a fork-join pair act like a call
 * (fork) and return (join) from a parallel recursive function. As is
 * the case with other forms of recursive calls, returns (joins)
 * should be performed innermost-first. For example, {@code a.fork();
 * b.fork(); b.join(); a.join();} is likely to be substantially more
 * efficient than joining {@code a} before {@code b}.
 *
 * <p>The execution status of tasks may be queried at several levels
 * of detail: {@link #isDone} is true if a task completed in any way
 * (including the case where a task was cancelled without executing);
 * {@link #isCompletedNormally} is true if a task completed without
 * cancellation or encountering an exception; {@link #isCancelled} is
 * true if the task was cancelled (in which case {@link #getException}
 * returns a {@link CancellationException}); and
 * {@link #isCompletedAbnormally} is true if a task was either
 * cancelled or encountered an exception, in which case {@link
 * #getException} will return either the encountered exception or
 * {@link CancellationException}.
 *
 * <p>The ForkJoinTask class is not usually directly subclassed.
 * Instead, you subclass one of the abstract classes that support a
 * particular style of fork/join processing, typically {@link
 * RecursiveAction} for most computations that do not return results,
 * {@link RecursiveTask} for those that do, and {@link
 * CountedCompleter} for those in which completed actions trigger
 * other actions.  Normally, a concrete ForkJoinTask subclass declares
 * fields comprising its parameters, established in a constructor, and
 * then defines a {@code compute} method that somehow uses the control
 * methods supplied by this base class.
 *
 * <p>Method {@link #join} and its variants are appropriate for use
 * only when completion dependencies are acyclic; that is, the
 * parallel computation can be described as a directed acyclic graph
 * (DAG). Otherwise, executions may encounter a form of deadlock as
 * tasks cyclically wait for each other.  However, this framework
 * supports other methods and techniques (for example the use of
 * {@link Phaser}, {@link #helpQuiesce}, and {@link #complete}) that
 * may be of use in constructing custom subclasses for problems that
 * are not statically structured as DAGs. To support such usages, a
 * ForkJoinTask may be atomically <em>tagged</em> with a {@code short}
 * value using {@link #setForkJoinTaskTag} or {@link
 * #compareAndSetForkJoinTaskTag} and checked using {@link
 * #getForkJoinTaskTag}. The ForkJoinTask implementation does not use
 * these {@code protected} methods or tags for any purpose, but they
 * may be of use in the construction of specialized subclasses.  For
 * example, parallel graph traversals can use the supplied methods to
 * avoid revisiting nodes/tasks that have already been processed.
 * (Method names for tagging are bulky in part to encourage definition
 * of methods that reflect their usage patterns.)
 *
 * <p>Most base support methods are {@code final}, to prevent
 * overriding of implementations that are intrinsically tied to the
 * underlying lightweight task scheduling framework.  Developers
 * creating new basic styles of fork/join processing should minimally
 * implement {@code protected} methods {@link #exec}, {@link
 * #setRawResult}, and {@link #getRawResult}, while also introducing
 * an abstract computational method that can be implemented in its
 * subclasses, possibly relying on other {@code protected} methods
 * provided by this class.
 *
 * <p>ForkJoinTasks should perform relatively small amounts of
 * computation. Large tasks should be split into smaller subtasks,
 * usually via recursive decomposition. As a very rough rule of thumb,
 * a task should perform more than 100 and less than 10000 basic
 * computational steps, and should avoid indefinite looping. If tasks
 * are too big, then parallelism cannot improve throughput. If too
 * small, then memory and internal task maintenance overhead may
 * overwhelm processing.
 *
 * <p>This class provides {@code adapt} methods for {@link Runnable}
 * and {@link Callable}, that may be of use when mixing execution of
 * {@code ForkJoinTasks} with other kinds of tasks. When all tasks are
 * of this form, consider using a pool constructed in <em>asyncMode</em>.
 *
 * <p>ForkJoinTasks are {@code Serializable}, which enables them to be
 * used in extensions such as remote execution frameworks. It is
 * sensible to serialize tasks only before or after, but not during,
 * execution. Serialization is not relied on during execution itself.
 *
 * @author Doug Lea
 */
abstract class ForkJoinTask(V) : Future!(V), IForkJoinTask {

    /*
     * See the internal documentation of class ForkJoinPool for a
     * general implementation overview.  ForkJoinTasks are mainly
     * responsible for maintaining their "status" field amidst relays
     * to methods in ForkJoinWorkerThread and ForkJoinPool.
     *
     * The methods of this class are more-or-less layered into
     * (1) basic status maintenance
     * (2) execution and awaiting completion
     * (3) user-level methods that additionally report results.
     * This is sometimes hard to see because this file orders exported
     * methods in a way that flows well in javadocs.
     */

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
    shared int status; // accessed directly by pool and workers

    Mutex thisMutex;
    Condition thisLocker;

    private enum int DONE     = 1 << 31; // must be negative
    private enum int ABNORMAL = 1 << 18; // set atomically with DONE
    private enum int THROWN   = 1 << 17; // set atomically with ABNORMAL
    private enum int SIGNAL   = 1 << 16; // true if joiner waiting
    private enum int SMASK    = 0xffff;  // short bits for tags

    this() {
        thisMutex = new Mutex(this);
        thisLocker = new Condition(thisMutex);
    }

    static bool isExceptionalStatus(int s) {  // needed by subclasses
        return (s & THROWN) != 0;
    }

    /**
     * Sets DONE status and wakes up threads waiting to join this task.
     *
     * @return status on exit
     */
    private int setDone() {
        int s = AtomicHelper.getAndBitwiseOr(this.status, DONE);
        version(HUNT_CONCURRENCY_DEBUG) {
            tracef("status: last=%d, new=%d", s, status);
        }
        if((s & SIGNAL) != 0) {
            synchronized (this) { 
                version(HUNT_CONCURRENCY_DEBUG) info("notifying on done .....");
                thisLocker.notifyAll();
            }
        }
        return s | DONE;
    }

    /**
     * Marks cancelled or exceptional completion unless already done.
     *
     * @param completion must be DONE | ABNORMAL, ORed with THROWN if exceptional
     * @return status on exit
     */
    private int abnormalCompletion(int completion) {
        for (int s, ns;;) {
            if ((s = status) < 0) {
                return s;
            } else {
                if(this.status == s) {
                    this.status = ns = s | completion;
                    if ((s & SIGNAL) != 0)
                    synchronized (this) { 
                        thisLocker.notifyAll(); 
                    }
                    return ns;
                }
            }
            // FIXME: Needing refactor or cleanup -@zxp at 2019/2/7 10:33:03
            // 
            // if (STATUS.weakCompareAndSet(this, s, ns = s | completion)) {
            //     if ((s & SIGNAL) != 0)
            //         synchronized (this) { notifyAll(); }
            //     return ns;
            // }
        }
    }

    int getStatus() {
        return status;
    }

    /**
     * Primary execution method for stolen tasks. Unless done, calls
     * exec and records status if completed, but doesn't wait for
     * completion otherwise.
     *
     * @return status on exit from this method
     */
    final int doExec() {
        int s; bool completed;
        if ((s = status) >= 0) {
            try {
                completed = exec();
            } catch (Throwable rex) {
                completed = false;
                s = setExceptionalCompletion(rex);
            }
            version(HUNT_CONCURRENCY_DEBUG) tracef("completed: %s", completed);
            if (completed) {
                s = setDone();
            }
        }
        return s;
    }

    /**
     * If not done, sets SIGNAL status and performs Object.wait(timeout).
     * This task may or may not be done on exit. Ignores interrupts.
     *
     * @param timeout using Object.wait conventions.
     */
    final void internalWait(long timeout) {        
        int s = cast(int)(this.status | SIGNAL);
        if (s >= 0) {
            synchronized (this) {
                if (status >= 0)
                    try { 
                        thisLocker.wait(dur!(TimeUnit.Millisecond)(timeout)); 
                    } catch (InterruptedException ie) { }
                else
                    thisLocker.notifyAll();
            }
        }
    }

    /**
     * Blocks a non-worker-thread until completion.
     * @return status upon completion
     */
    private int externalAwaitDone() {
        int s = tryExternalHelp();
        if(s < 0)
            return s;
        
        s = AtomicHelper.getAndBitwiseOr(this.status, SIGNAL);
        version(HUNT_CONCURRENCY_DEBUG) {
            infof("status: last=%d, new=%d", s, status);
        }
        if(s < 0)
            return s;

        bool interrupted = false;
        synchronized (this) {
            for (;;) {
                if ((s = status) >= 0) {
                    try {
                        thisLocker.wait(Duration.zero);
                    } catch (InterruptedException ie) {
                        interrupted = true;
                    }
                }
                else {
                    thisLocker.notifyAll();
                    break;
                }
            }
        }
        if (interrupted) {
            ThreadEx th = cast(ThreadEx) Thread.getThis();
            if(th !is null)
                th.interrupt();
        }
        return s;
    }

    /**
     * Blocks a non-worker-thread until completion or interruption.
     */
    private int externalInterruptibleAwaitDone() {
        int s = tryExternalHelp();
        if(s <0) {
            if (ThreadEx.interrupted())
                throw new InterruptedException();
            return s;
        }

        s = AtomicHelper.getAndBitwiseOr(this.status, SIGNAL);
        version(HUNT_CONCURRENCY_DEBUG) {
            infof("status: last=%d, new=%d", s, status);
        }
        if (s >= 0) {
            synchronized (this) {
                for (;;) {
                    if ((s = status) >= 0)
                        thisLocker.wait(Duration.zero);
                    else {
                        thisLocker.notifyAll();
                        break;
                    }
                }
            }
        }
        else if (ThreadEx.interrupted())
            throw new InterruptedException();
        return s;
    }

    /**
     * Tries to help with tasks allowed for external callers.
     *
     * @return current status
     */
    private int tryExternalHelp() {
        int s = status;
        if(s<0) return s;
        ICountedCompleter cc = cast(ICountedCompleter)this;
        if(cc !is null) {
            return ForkJoinPool.common.externalHelpComplete(
                    cc, 0);
        } else if(ForkJoinPool.common.tryExternalUnpush(this)) {
            return doExec();
        } else
            return 0;
        // return ((s = status) < 0 ? s:
        //         (this instanceof CountedCompleter) ?
        //         ForkJoinPool.common.externalHelpComplete(
        //             (ICountedCompleter)this, 0) :
        //         ForkJoinPool.common.tryExternalUnpush(this) ?
        //         doExec() : 0);
    }

    /**
     * Implementation for join, get, quietlyJoin. Directly handles
     * only cases of already-completed, external wait, and
     * unfork+exec.  Others are relayed to ForkJoinPool.awaitJoin.
     *
     * @return status upon completion
     */
    private int doJoin() {
        int s = status; 
        if(s < 0) return s;

        ForkJoinWorkerThread wt = cast(ForkJoinWorkerThread)Thread.getThis(); 
        if(wt !is null) {
            WorkQueue w = wt.workQueue;
            if(w.tryUnpush(this) && (s = doExec()) < 0 )
                return s;
            else
                return wt.pool.awaitJoin(w, this, MonoTime.zero);
        } else {
            return externalAwaitDone();
        }
    }

    /**
     * Implementation for invoke, quietlyInvoke.
     *
     * @return status upon completion
     */
    private int doInvoke() {
        int s = doExec(); 
        if(s < 0)
            return s;
        ForkJoinWorkerThread wt = cast(ForkJoinWorkerThread)Thread.getThis();
        if(wt !is null) {
            return wt.pool.awaitJoin(wt.workQueue, this, MonoTime.zero());
        } else {
            return externalAwaitDone();
        }
    }

    /**
     * Records exception and sets status.
     *
     * @return status on exit
     */
    final int recordExceptionalCompletion(Throwable ex) {
        int s;
        if ((s = status) >= 0) {
            size_t h = this.toHash();
            ReentrantLock lock = ForkJoinTaskHelper.exceptionTableLock;
            lock.lock();
            try {
                ExceptionNode[] t = ForkJoinTaskHelper.exceptionTable;
                size_t i = h & (t.length - 1);
                for (ExceptionNode e = t[i]; ; e = e.next) {
                    if (e is null) {
                        t[i] = new ExceptionNode(this, ex, t[i]);
                        break;
                    }
                    if (e.get() == this) // already present
                        break;
                }
            } finally {
                lock.unlock();
            }
            s = abnormalCompletion(DONE | ABNORMAL | THROWN);
        }
        return s;
    }

    /**
     * Records exception and possibly propagates.
     *
     * @return status on exit
     */
    private int setExceptionalCompletion(Throwable ex) {
        int s = recordExceptionalCompletion(ex);
        if ((s & THROWN) != 0)
            internalPropagateException(ex);
        return s;
    }

    /**
     * Hook for exception propagation support for tasks with completers.
     */
    void internalPropagateException(Throwable ex) {
    }

    /**
     * Removes exception node and clears status.
     */
    private void clearExceptionalCompletion() {
        size_t h = this.toHash();
        ReentrantLock lock = ForkJoinTaskHelper.exceptionTableLock;
        lock.lock();
        try {
            ExceptionNode[] t = ForkJoinTaskHelper.exceptionTable;
            size_t i = h & (t.length - 1);
            ExceptionNode e = t[i];
            ExceptionNode pred = null;
            while (e !is null) {
                ExceptionNode next = e.next;
                if (e.get() == this) {
                    if (pred is null)
                        t[i] = next;
                    else
                        pred.next = next;
                    break;
                }
                pred = e;
                e = next;
            }
            status = 0;
        } finally {
            lock.unlock();
        }
    }

    /**
     * Returns a rethrowable exception for this task, if available.
     * To provide accurate stack traces, if the exception was not
     * thrown by the current thread, we try to create a new exception
     * of the same type as the one thrown, but with the recorded
     * exception as its cause. If there is no such constructor, we
     * instead try to use a no-arg constructor, followed by initCause,
     * to the same effect. If none of these apply, or any fail due to
     * other exceptions, we return the recorded exception, which is
     * still correct, although it may contain a misleading stack
     * trace.
     *
     * @return the exception, or null if none
     */
    private Throwable getThrowableException() {
        size_t h = this.toHash();
        ExceptionNode e;
        ReentrantLock lock = ForkJoinTaskHelper.exceptionTableLock;
        lock.lock();
        try {
            ExceptionNode[] t = ForkJoinTaskHelper.exceptionTable;
            e = t[h & ($ - 1)];
            while (e !is null && e.get() !is this)
                e = e.next;
        } finally {
            lock.unlock();
        }
        Throwable ex;
        if (e is null || (ex = e.ex) is null)
            return null;
        return ex;
    }


    /**
     * Throws exception, if any, associated with the given status.
     */
    private void reportException(int s) {
        ForkJoinTaskHelper.rethrow((s & THROWN) != 0 ? getThrowableException() :
                new CancellationException());
    }

    // methods

    /**
     * Arranges to asynchronously execute this task in the pool the
     * current task is running in, if applicable, or using the {@link
     * ForkJoinPool#commonPool()} if not {@link #inForkJoinPool}.  While
     * it is not necessarily enforced, it is a usage error to fork a
     * task more than once unless it has completed and been
     * reinitialized.  Subsequent modifications to the state of this
     * task or any data it operates on are not necessarily
     * consistently observable by any thread other than the one
     * executing it unless preceded by a call to {@link #join} or
     * related methods, or a call to {@link #isDone} returning {@code
     * true}.
     *
     * @return {@code this}, to simplify usage
     */
    final ForkJoinTask!(V) fork() {
        ForkJoinWorkerThread t = cast(ForkJoinWorkerThread)Thread.getThis();
        if (t !is null)
            t.workQueue.push(this);
        else
            ForkJoinPool.common.externalPush(this);
        return this;
    }

    /**
     * Returns the result of the computation when it
     * {@linkplain #isDone is done}.
     * This method differs from {@link #get()} in that abnormal
     * completion results in {@code RuntimeException} or {@code Error},
     * not {@code ExecutionException}, and that interrupts of the
     * calling thread do <em>not</em> cause the method to abruptly
     * return by throwing {@code InterruptedException}.
     *
     * @return the computed result
     */
    final V join() {
        int s;
        if (((s = doJoin()) & ABNORMAL) != 0) {
            reportException(s);
        }
        
        static if(!is(V == void)) {
            return getRawResult();
        }          
    }

    /**
     * Commences performing this task, awaits its completion if
     * necessary, and returns its result, or throws an (unchecked)
     * {@code RuntimeException} or {@code Error} if the underlying
     * computation did so.
     *
     * @return the computed result
     */
    final V invoke() {
        int s;
        if (((s = doInvoke()) & ABNORMAL) != 0)
            reportException(s);

        static if(!is(V == void)) {
            return getRawResult();
        }       
    }

    /**
     * Forks the given tasks, returning when {@code isDone} holds for
     * each task or an (unchecked) exception is encountered, in which
     * case the exception is rethrown. If more than one task
     * encounters an exception, then this method throws any one of
     * these exceptions. If any task encounters an exception, the
     * other may be cancelled. However, the execution status of
     * individual tasks is not guaranteed upon exceptional return. The
     * status of each task may be obtained using {@link
     * #getException()} and related methods to check if they have been
     * cancelled, completed normally or exceptionally, or left
     * unprocessed.
     *
     * @param t1 the first task
     * @param t2 the second task
     * @throws NullPointerException if any task is null
     */
    static void invokeAll(IForkJoinTask t1, IForkJoinTask t2) {
        int s1, s2;
        implementationMissing(false);
        // t2.fork();
        // if (((s1 = t1.doInvoke()) & ABNORMAL) != 0)
        //     t1.reportException(s1);
        // if (((s2 = t2.doJoin()) & ABNORMAL) != 0)
        //     t2.reportException(s2);
    }

    /**
     * Forks the given tasks, returning when {@code isDone} holds for
     * each task or an (unchecked) exception is encountered, in which
     * case the exception is rethrown. If more than one task
     * encounters an exception, then this method throws any one of
     * these exceptions. If any task encounters an exception, others
     * may be cancelled. However, the execution status of individual
     * tasks is not guaranteed upon exceptional return. The status of
     * each task may be obtained using {@link #getException()} and
     * related methods to check if they have been cancelled, completed
     * normally or exceptionally, or left unprocessed.
     *
     * @param tasks the tasks
     * @throws NullPointerException if any task is null
     */
    static void invokeAll(IForkJoinTask[] tasks...) {
        Throwable ex = null;
        int last = cast(int)tasks.length - 1;
        // for (int i = last; i >= 0; --i) {
        //     IForkJoinTask t = tasks[i];
        //     if (t is null) {
        //         if (ex is null)
        //             ex = new NullPointerException();
        //     }
        //     else if (i != 0)
        //         t.fork();
        //     else if ((t.doInvoke() & ABNORMAL) != 0 && ex is null)
        //         ex = t.getException();
        // }
        // for (int i = 1; i <= last; ++i) {
        //     IForkJoinTask t = tasks[i];
        //     if (t !is null) {
        //         if (ex !is null)
        //             t.cancel(false);
        //         else if ((t.doJoin() & ABNORMAL) != 0)
        //             ex = t.getException();
        //     }
        // }
        implementationMissing(false);
        if (ex !is null)
            ForkJoinTaskHelper.rethrow(ex);
    }

    /**
     * Forks all tasks in the specified collection, returning when
     * {@code isDone} holds for each task or an (unchecked) exception
     * is encountered, in which case the exception is rethrown. If
     * more than one task encounters an exception, then this method
     * throws any one of these exceptions. If any task encounters an
     * exception, others may be cancelled. However, the execution
     * status of individual tasks is not guaranteed upon exceptional
     * return. The status of each task may be obtained using {@link
     * #getException()} and related methods to check if they have been
     * cancelled, completed normally or exceptionally, or left
     * unprocessed.
     *
     * @param tasks the collection of tasks
     * @param (T) the type of the values returned from the tasks
     * @return the tasks argument, to simplify usage
     * @throws NullPointerException if tasks or any element are null
     */
    static Collection!(T) invokeAll(T)(Collection!(T) tasks) if(is(T : IForkJoinTask)) {
        // TODO: Tasks pending completion -@zxp at 12/21/2018, 10:36:15 PM
        // 
        implementationMissing(false);
        // if (!(tasks instanceof RandomAccess) || !(tasks instanceof List<?>)) {
        //     invokeAll(tasks.toArray(new IForkJoinTask[0]));
        //     return tasks;
        // }
    
        // List!(IForkJoinTask) ts = cast(List!(IForkJoinTask)) tasks;
        // Throwable ex = null;
        // int last = ts.size() - 1;
        // for (int i = last; i >= 0; --i) {
        //     IForkJoinTask t = ts.get(i);
        //     if (t is null) {
        //         if (ex is null)
        //             ex = new NullPointerException();
        //     }
        //     else if (i != 0)
        //         t.fork();
        //     else if ((t.doInvoke() & ABNORMAL) != 0 && ex is null)
        //         ex = t.getException();
        // }
        // for (int i = 1; i <= last; ++i) {
        //     IForkJoinTask t = ts.get(i);
        //     if (t !is null) {
        //         if (ex !is null)
        //             t.cancel(false);
        //         else if ((t.doJoin() & ABNORMAL) != 0)
        //             ex = t.getException();
        //     }
        // }
        // if (ex !is null)
        //     rethrow(ex);
        return tasks;
    }

    /**
     * Attempts to cancel execution of this task. This attempt will
     * fail if the task has already completed or could not be
     * cancelled for some other reason. If successful, and this task
     * has not started when {@code cancel} is called, execution of
     * this task is suppressed. After this method returns
     * successfully, unless there is an intervening call to {@link
     * #reinitialize}, subsequent calls to {@link #isCancelled},
     * {@link #isDone}, and {@code cancel} will return {@code true}
     * and calls to {@link #join} and related methods will result in
     * {@code CancellationException}.
     *
     * <p>This method may be overridden in subclasses, but if so, must
     * still ensure that these properties hold. In particular, the
     * {@code cancel} method itself must not throw exceptions.
     *
     * <p>This method is designed to be invoked by <em>other</em>
     * tasks. To terminate the current task, you can just return or
     * throw an unchecked exception from its computation method, or
     * invoke {@link #completeExceptionally(Throwable)}.
     *
     * @param mayInterruptIfRunning this value has no effect in the
     * default implementation because interrupts are not used to
     * control cancellation.
     *
     * @return {@code true} if this task is now cancelled
     */
    bool cancel(bool mayInterruptIfRunning) {
        int s = abnormalCompletion(DONE | ABNORMAL);
        return (s & (ABNORMAL | THROWN)) == ABNORMAL;
    }

    final bool isDone() {
        return status < 0;
    }

    final bool isCancelled() {
        return (status & (ABNORMAL | THROWN)) == ABNORMAL;
    }

    /**
     * Returns {@code true} if this task threw an exception or was cancelled.
     *
     * @return {@code true} if this task threw an exception or was cancelled
     */
    final bool isCompletedAbnormally() {
        return (status & ABNORMAL) != 0;
    }

    /**
     * Returns {@code true} if this task completed without throwing an
     * exception and was not cancelled.
     *
     * @return {@code true} if this task completed without throwing an
     * exception and was not cancelled
     */
    final bool isCompletedNormally() {
        return (status & (DONE | ABNORMAL)) == DONE;
    }

    /**
     * Returns the exception thrown by the base computation, or a
     * {@code CancellationException} if cancelled, or {@code null} if
     * none or if the method has not yet completed.
     *
     * @return the exception, or {@code null} if none
     */
    final Throwable getException() {
        int s = status;
        return ((s & ABNORMAL) == 0 ? null :
                (s & THROWN)   == 0 ? new CancellationException() :
                getThrowableException());
    }

    /**
     * Completes this task abnormally, and if not already aborted or
     * cancelled, causes it to throw the given exception upon
     * {@code join} and related operations. This method may be used
     * to induce exceptions in asynchronous tasks, or to force
     * completion of tasks that would not otherwise complete.  Its use
     * in other situations is discouraged.  This method is
     * overridable, but overridden versions must invoke {@code super}
     * implementation to maintain guarantees.
     *
     * @param ex the exception to throw. If this exception is not a
     * {@code RuntimeException} or {@code Error}, the actual exception
     * thrown will be a {@code RuntimeException} with cause {@code ex}.
     */
    void completeExceptionally(Exception ex) {
        RuntimeException re = cast(RuntimeException)ex;
        if(re !is null) {
            setExceptionalCompletion(ex);
        } else {
            Error er = cast(Error)ex;
            if(er is null) {
                setExceptionalCompletion(new RuntimeException(ex));
            } else {
                setExceptionalCompletion(ex);
            }
        }
    }

    /**
     * Completes this task, and if not already aborted or cancelled,
     * returning the given value as the result of subsequent
     * invocations of {@code join} and related operations. This method
     * may be used to provide results for asynchronous tasks, or to
     * provide alternative handling for tasks that would not otherwise
     * complete normally. Its use in other situations is
     * discouraged. This method is overridable, but overridden
     * versions must invoke {@code super} implementation to maintain
     * guarantees.
     *
     * @param value the result value for this task
     */
static if(is(V == void))   {  
    void complete() {
        // try {
        //     setRawResult();
        // } catch (Throwable rex) {
        //     setExceptionalCompletion(rex);
        //     return;
        // }
        setDone();
    }
} else {
    void complete(V value) {
        try {
            setRawResult(value);
        } catch (Throwable rex) {
            setExceptionalCompletion(rex);
            return;
        }
        setDone();
    }
}

    /**
     * Completes this task normally without setting a value. The most
     * recent value established by {@link #setRawResult} (or {@code
     * null} by default) will be returned as the result of subsequent
     * invocations of {@code join} and related operations.
     *
     */
    final void quietlyComplete() {
        setDone();
    }

    /**
     * Waits if necessary for the computation to complete, and then
     * retrieves its result.
     *
     * @return the computed result
     * @throws CancellationException if the computation was cancelled
     * @throws ExecutionException if the computation threw an
     * exception
     * @throws InterruptedException if the current thread is not a
     * member of a ForkJoinPool and was interrupted while waiting
     */
    final V get() {
        ForkJoinWorkerThread ft = cast(ForkJoinWorkerThread)Thread.getThis();
        int s = ft !is null ? doJoin() : externalInterruptibleAwaitDone();
        if ((s & THROWN) != 0)
            throw new ExecutionException(getThrowableException());
        else if ((s & ABNORMAL) != 0)
            throw new CancellationException();
        else {
            static if(!is(V == void)) {
                return getRawResult();
            }
        }
    }

    /**
     * Waits if necessary for at most the given time for the computation
     * to complete, and then retrieves its result, if available.
     *
     * @param timeout the maximum time to wait
     * @param unit the time unit of the timeout argument
     * @return the computed result
     * @throws CancellationException if the computation was cancelled
     * @throws ExecutionException if the computation threw an
     * exception
     * @throws InterruptedException if the current thread is not a
     * member of a ForkJoinPool and was interrupted while waiting
     * @throws TimeoutException if the wait timed out
     */
    final V get(Duration timeout) {
        int s;
// TODO: Tasks pending completion -@zxp at 12/21/2018, 10:55:12 PM
// 
        // if (Thread.interrupted())
        //     throw new InterruptedException();
        
        if ((s = status) >= 0 && timeout > Duration.zero) {
            MonoTime deadline = MonoTime.currTime + timeout;
            // long deadline = (d == 0L) ? 1L : d; // avoid 0
            ForkJoinWorkerThread wt = cast(ForkJoinWorkerThread)Thread.getThis();
            if (wt !is null) {
                s = wt.pool.awaitJoin(wt.workQueue, this, deadline);
            }
            else {
                ICountedCompleter ic = cast(ICountedCompleter)this;
                if(ic !is null) {
                    s = ForkJoinPool.common.externalHelpComplete(ic, 0);
                } else if(ForkJoinPool.common.tryExternalUnpush(this)){
                    s = doExec();
                } else 
                    s = 0;

                if (s >= 0) {
                Duration ns; // measure in nanosecs, but wait in millisecs
                long ms;
                while ((s = status) >= 0 &&
                       (ns = deadline - MonoTime.currTime) > Duration.zero) {
                    if ((ms = ns.total!(TimeUnit.Millisecond)()) > 0L) {
                        s = AtomicHelper.getAndBitwiseOr(this.status, SIGNAL);
                        if( s >= 0) {
                            synchronized (this) {
                                if (status >= 0) // OK to throw InterruptedException
                                    thisLocker.wait(dur!(TimeUnit.Millisecond)(ms)); 
                                else
                                    thisLocker.notifyAll();
                            }
                        }
                    }
                }
            }
        }
        }
        if (s >= 0)
            throw new TimeoutException();
        else if ((s & THROWN) != 0)
            throw new ExecutionException(getThrowableException());
        else if ((s & ABNORMAL) != 0)
            throw new CancellationException();
        else {
            static if(!is(V == void)) {
                return getRawResult();
            }
        }
    }

    /**
     * Joins this task, without returning its result or throwing its
     * exception. This method may be useful when processing
     * collections of tasks when some have been cancelled or otherwise
     * known to have aborted.
     */
    final void quietlyJoin() {
        doJoin();
    }

    /**
     * Commences performing this task and awaits its completion if
     * necessary, without returning its result or throwing its
     * exception.
     */
    final void quietlyInvoke() {
        doInvoke();
    }

    /**
     * Possibly executes tasks until the pool hosting the current task
     * {@linkplain ForkJoinPool#isQuiescent is quiescent}.  This
     * method may be of use in designs in which many tasks are forked,
     * but none are explicitly joined, instead executing them until
     * all are processed.
     */
    // static void helpQuiesce() {
    //     Thread t;
    //     if ((t = Thread.getThis()) instanceof ForkJoinWorkerThread) {
    //         ForkJoinWorkerThread wt = (ForkJoinWorkerThread)t;
    //         wt.pool.helpQuiescePool(wt.workQueue);
    //     }
    //     else
    //         ForkJoinPool.quiesceCommonPool();
    // }

    /**
     * Resets the internal bookkeeping state of this task, allowing a
     * subsequent {@code fork}. This method allows repeated reuse of
     * this task, but only if reuse occurs when this task has either
     * never been forked, or has been forked, then completed and all
     * outstanding joins of this task have also completed. Effects
     * under any other usage conditions are not guaranteed.
     * This method may be useful when executing
     * pre-constructed trees of subtasks in loops.
     *
     * <p>Upon completion of this method, {@code isDone()} reports
     * {@code false}, and {@code getException()} reports {@code
     * null}. However, the value returned by {@code getRawResult} is
     * unaffected. To clear this value, you can invoke {@code
     * setRawResult(null)}.
     */
    void reinitialize() {
        if ((status & THROWN) != 0)
            clearExceptionalCompletion();
        else
            status = 0;
    }

    /**
     * Returns the pool hosting the current thread, or {@code null}
     * if the current thread is executing outside of any ForkJoinPool.
     *
     * <p>This method returns {@code null} if and only if {@link
     * #inForkJoinPool} returns {@code false}.
     *
     * @return the pool, or {@code null} if none
     */
    // static ForkJoinPool getPool() {
    //     Thread t = Thread.getThis();
    //     return (t instanceof ForkJoinWorkerThread) ?
    //         ((ForkJoinWorkerThread) t).pool : null;
    // }

    /**
     * Returns {@code true} if the current thread is a {@link
     * ForkJoinWorkerThread} executing as a ForkJoinPool computation.
     *
     * @return {@code true} if the current thread is a {@link
     * ForkJoinWorkerThread} executing as a ForkJoinPool computation,
     * or {@code false} otherwise
     */
    static bool inForkJoinPool() {
        ForkJoinWorkerThread t = cast(ForkJoinWorkerThread)Thread.getThis();
        return t !is null;
    }

    /**
     * Tries to unschedule this task for execution. This method will
     * typically (but is not guaranteed to) succeed if this task is
     * the most recently forked task by the current thread, and has
     * not commenced executing in another thread.  This method may be
     * useful when arranging alternative local processing of tasks
     * that could have been, but were not, stolen.
     *
     * @return {@code true} if unforked
     */
    bool tryUnfork() {
        ForkJoinWorkerThread t = cast(ForkJoinWorkerThread)Thread.getThis();
        return t !is null? t.workQueue.tryUnpush(this) :
                ForkJoinPool.common.tryExternalUnpush(this);
    }

    /**
     * Returns an estimate of the number of tasks that have been
     * forked by the current worker thread but not yet executed. This
     * value may be useful for heuristic decisions about whether to
     * fork other tasks.
     *
     * @return the number of tasks
     */
    // static int getQueuedTaskCount() {
    //     Thread t; ForkJoinPool.WorkQueue q;
    //     if ((t = Thread.getThis()) instanceof ForkJoinWorkerThread)
    //         q = ((ForkJoinWorkerThread)t).workQueue;
    //     else
    //         q = ForkJoinPool.commonSubmitterQueue();
    //     return (q is null) ? 0 : q.queueSize();
    // }

    /**
     * Returns an estimate of how many more locally queued tasks are
     * held by the current worker thread than there are other worker
     * threads that might steal them, or zero if this thread is not
     * operating in a ForkJoinPool. This value may be useful for
     * heuristic decisions about whether to fork other tasks. In many
     * usages of ForkJoinTasks, at steady state, each worker should
     * aim to maintain a small constant surplus (for example, 3) of
     * tasks, and to process computations locally if this threshold is
     * exceeded.
     *
     * @return the surplus number of tasks, which may be negative
     */
    // static int getSurplusQueuedTaskCount() {
    //     return ForkJoinPool.getSurplusQueuedTaskCount();
    // }

    // Extension methods
static if(is(V == void)) {
    // protected abstract void setRawResult();
} else {

    /**
     * Returns the result that would be returned by {@link #join}, even
     * if this task completed abnormally, or {@code null} if this task
     * is not known to have been completed.  This method is designed
     * to aid debugging, as well as to support extensions. Its use in
     * any other context is discouraged.
     *
     * @return the result, or {@code null} if not completed
     */
    abstract V getRawResult();

    /**
     * Forces the given value to be returned as a result.  This method
     * is designed to support extensions, and should not in general be
     * called otherwise.
     *
     * @param value the value
     */
    protected abstract void setRawResult(V value);
}    

    /**
     * Immediately performs the base action of this task and returns
     * true if, upon return from this method, this task is guaranteed
     * to have completed normally. This method may return false
     * otherwise, to indicate that this task is not necessarily
     * complete (or is not known to be complete), for example in
     * asynchronous actions that require explicit invocations of
     * completion methods. This method may also throw an (unchecked)
     * exception to indicate abnormal exit. This method is designed to
     * support extensions, and should not in general be called
     * otherwise.
     *
     * @return {@code true} if this task is known to have completed normally
     */
    protected abstract bool exec();

    /**
     * Returns, but does not unschedule or execute, a task queued by
     * the current thread but not yet executed, if one is immediately
     * available. There is no guarantee that this task will actually
     * be polled or executed next. Conversely, this method may return
     * null even if a task exists but cannot be accessed without
     * contention with other threads.  This method is designed
     * primarily to support extensions, and is unlikely to be useful
     * otherwise.
     *
     * @return the next task, or {@code null} if none are available
     */
    // protected static IForkJoinTask peekNextLocalTask() {
    //     Thread t; ForkJoinPool.WorkQueue q;
    //     if ((t = Thread.getThis()) instanceof ForkJoinWorkerThread)
    //         q = ((ForkJoinWorkerThread)t).workQueue;
    //     else
    //         q = ForkJoinPool.commonSubmitterQueue();
    //     return (q is null) ? null : q.peek();
    // }

    /**
     * Unschedules and returns, without executing, the next task
     * queued by the current thread but not yet executed, if the
     * current thread is operating in a ForkJoinPool.  This method is
     * designed primarily to support extensions, and is unlikely to be
     * useful otherwise.
     *
     * @return the next task, or {@code null} if none are available
     */
    // protected static IForkJoinTask pollNextLocalTask() {
    //     Thread t;
    //     return ((t = Thread.getThis()) instanceof ForkJoinWorkerThread) ?
    //         ((ForkJoinWorkerThread)t).workQueue.nextLocalTask() :
    //         null;
    // }

    /**
     * If the current thread is operating in a ForkJoinPool,
     * unschedules and returns, without executing, the next task
     * queued by the current thread but not yet executed, if one is
     * available, or if not available, a task that was forked by some
     * other thread, if available. Availability may be transient, so a
     * {@code null} result does not necessarily imply quiescence of
     * the pool this task is operating in.  This method is designed
     * primarily to support extensions, and is unlikely to be useful
     * otherwise.
     *
     * @return a task, or {@code null} if none are available
     */
    // protected static IForkJoinTask pollTask() {
    //     Thread t; ForkJoinWorkerThread wt;
    //     return ((t = Thread.getThis()) instanceof ForkJoinWorkerThread) ?
    //         (wt = (ForkJoinWorkerThread)t).pool.nextTaskFor(wt.workQueue) :
    //         null;
    // }

    // /**
    //  * If the current thread is operating in a ForkJoinPool,
    //  * unschedules and returns, without executing, a task externally
    //  * submitted to the pool, if one is available. Availability may be
    //  * transient, so a {@code null} result does not necessarily imply
    //  * quiescence of the pool.  This method is designed primarily to
    //  * support extensions, and is unlikely to be useful otherwise.
    //  *
    //  * @return a task, or {@code null} if none are available
    //  */
    // protected static IForkJoinTask pollSubmission() {
    //     ForkJoinWorkerThread t = cast(ForkJoinWorkerThread)Thread.getThis();
    //     return t !is null ? t.pool.pollSubmission() : null;
    // }

    // tag operations

    /**
     * Returns the tag for this task.
     *
     * @return the tag for this task
     */
    final short getForkJoinTaskTag() {
        return cast(short)status;
    }

    /**
     * Atomically sets the tag value for this task and returns the old value.
     *
     * @param newValue the new tag value
     * @return the previous value of the tag
     */
    final short setForkJoinTaskTag(short newValue) {
        while(true) {
            int s = status;
            if(AtomicHelper.compareAndSet(this.status, s,  (s & ~SMASK) | (newValue & SMASK)))
                return cast(short)s;
        }
        // return 0;
    }

    /**
     * Atomically conditionally sets the tag value for this task.
     * Among other applications, tags can be used as visit markers
     * in tasks operating on graphs, as in methods that check: {@code
     * if (task.compareAndSetForkJoinTaskTag((short)0, (short)1))}
     * before processing, otherwise exiting because the node has
     * already been visited.
     *
     * @param expect the expected tag value
     * @param update the new tag value
     * @return {@code true} if successful; i.e., the current value was
     * equal to {@code expect} and was changed to {@code update}.
     */
    final bool compareAndSetForkJoinTaskTag(short expect, short update) {
        for (int s;;) {
            if (cast(short)(s = status) != expect)
                return false;
            if (AtomicHelper.compareAndSet(this.status, s,
                                         (s & ~SMASK) | (update & SMASK)))
                return true;
        }
    }


    /**
     * Returns a new {@code ForkJoinTask} that performs the {@code run}
     * method of the given {@code Runnable} as its action, and returns
     * a null result upon {@link #join}.
     *
     * @param runnable the runnable action
     * @return the task
     */
    // static IForkJoinTask adapt(Runnable runnable) {
    //     return new AdaptedRunnableAction(runnable);
    // }

    /**
     * Returns a new {@code ForkJoinTask} that performs the {@code run}
     * method of the given {@code Runnable} as its action, and returns
     * the given result upon {@link #join}.
     *
     * @param runnable the runnable action
     * @param result the result upon completion
     * @param (T) the type of the result
     * @return the task
     */
    static ForkJoinTask!(T) adapt(T)(Runnable runnable, T result) {
        return new AdaptedRunnable!(T)(runnable, result);
    }

    /**
     * Returns a new {@code ForkJoinTask} that performs the {@code call}
     * method of the given {@code Callable} as its action, and returns
     * its result upon {@link #join}, translating any checked exceptions
     * encountered into {@code RuntimeException}.
     *
     * @param callable the callable action
     * @param (T) the type of the callable's result
     * @return the task
     */
    static ForkJoinTask!(T) adapt(T)(Callable!(T) callable) {
        return new AdaptedCallable!(T)(callable);
    }
}



/**
 * Adapter for Runnables. This implements RunnableFuture
 * to be compliant with AbstractExecutorService constraints
 * when used in ForkJoinPool.
 */
final class AdaptedRunnable(T) : ForkJoinTask!(T), RunnableFuture!(T) {
    final Runnable runnable;
    T result;
    this(Runnable runnable, T result) {
        if (runnable is null) throw new NullPointerException();
        this.runnable = runnable;
        this.result = result; // OK to set this even before completion
    }
    final T getRawResult() { return result; }
    final void setRawResult(T v) { result = v; }
    final bool exec() { runnable.run(); return true; }
    final void run() { invoke(); }
    string toString() {
        return super.toString() ~ "[Wrapped task = " ~ runnable ~ "]";
    }
}

/**
 * Adapter for Runnables without results.
 */
final class AdaptedRunnableAction : ForkJoinTask!(void), Runnable {
    Runnable runnable;
    this(Runnable runnable) {
        if (runnable is null) throw new NullPointerException();
        this.runnable = runnable;
    }
    // final Void getRawResult() { return null; }
    // final void setRawResult(Void v) { }
    final override bool exec() { runnable.run(); return true; }
    final void run() { invoke(); }
    override bool cancel(bool mayInterruptIfRunning) {
        return super.cancel(mayInterruptIfRunning);
    }
    
    // override bool isCancelled() {
    //     return super.isCancelled();
    // }
    
    // override bool isDone() {
    //     return super.isDone();
    // }

    // override void get() {
    //     super.get();
    // }
    
    // override void get(Duration timeout) {
    //     super.get(timeout);
    // }

    override string toString() {
        return super.toString() ~ "[Wrapped task = " ~ (cast(Object)runnable).toString() ~ "]";
    }
}

/**
 * Adapter for Runnables in which failure forces worker exception.
 */
final class RunnableExecuteAction : ForkJoinTask!(void) {
    Runnable runnable;
    this(Runnable runnable) {
        if (runnable is null) throw new NullPointerException();
        this.runnable = runnable;
    }
    // final Void getRawResult() { return null; }
    // final void setRawResult(Void v) { }
    final override bool exec() { runnable.run(); return true; }
    override void internalPropagateException(Throwable ex) {
        ForkJoinTaskHelper.rethrow(ex); // rethrow outside exec() catches.
    }
}

/**
 * Adapter for Callables.
 */
final class AdaptedCallable(T) : ForkJoinTask!(T), RunnableFuture!(T) {
    final Callable!(T) callable;
    T result;
    this(Callable!(T) callable) {
        if (callable is null) throw new NullPointerException();
        this.callable = callable;
    }
    final T getRawResult() { return result; }
    final void setRawResult(T v) { result = v; }
    final bool exec() {
        try {
            result = callable.call();
            return true;
        } catch (RuntimeException rex) {
            throw rex;
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
    final void run() { invoke(); }
    string toString() {
        return super.toString() ~ "[Wrapped task = " ~ callable ~ "]";
    }
}


/*************************************************/
// CountedCompleter
/*************************************************/

interface ICountedCompleter : IForkJoinTask {
    ICountedCompleter getCompleter();
}

/**
 * A {@link ForkJoinTask} with a completion action performed when
 * triggered and there are no remaining pending actions.
 * CountedCompleters are in general more robust in the
 * presence of subtask stalls and blockage than are other forms of
 * ForkJoinTasks, but are less intuitive to program.  Uses of
 * CountedCompleter are similar to those of other completion based
 * components (such as {@link java.nio.channels.CompletionHandler})
 * except that multiple <em>pending</em> completions may be necessary
 * to trigger the completion action {@link #onCompletion(CountedCompleter)},
 * not just one.
 * Unless initialized otherwise, the {@linkplain #getPendingCount pending
 * count} starts at zero, but may be (atomically) changed using
 * methods {@link #setPendingCount}, {@link #addToPendingCount}, and
 * {@link #compareAndSetPendingCount}. Upon invocation of {@link
 * #tryComplete}, if the pending action count is nonzero, it is
 * decremented; otherwise, the completion action is performed, and if
 * this completer itself has a completer, the process is continued
 * with its completer.  As is the case with related synchronization
 * components such as {@link Phaser} and {@link Semaphore}, these methods
 * affect only internal counts; they do not establish any further
 * internal bookkeeping. In particular, the identities of pending
 * tasks are not maintained. As illustrated below, you can create
 * subclasses that do record some or all pending tasks or their
 * results when needed.  As illustrated below, utility methods
 * supporting customization of completion traversals are also
 * provided. However, because CountedCompleters provide only basic
 * synchronization mechanisms, it may be useful to create further
 * abstract subclasses that maintain linkages, fields, and additional
 * support methods appropriate for a set of related usages.
 *
 * <p>A concrete CountedCompleter class must define method {@link
 * #compute}, that should in most cases (as illustrated below), invoke
 * {@code tryComplete()} once before returning. The class may also
 * optionally override method {@link #onCompletion(CountedCompleter)}
 * to perform an action upon normal completion, and method
 * {@link #onExceptionalCompletion(Throwable, CountedCompleter)} to
 * perform an action upon any exception.
 *
 * <p>CountedCompleters most often do not bear results, in which case
 * they are normally declared as {@code CountedCompleter!(void)}, and
 * will always return {@code null} as a result value.  In other cases,
 * you should override method {@link #getRawResult} to provide a
 * result from {@code join(), invoke()}, and related methods.  In
 * general, this method should return the value of a field (or a
 * function of one or more fields) of the CountedCompleter object that
 * holds the result upon completion. Method {@link #setRawResult} by
 * default plays no role in CountedCompleters.  It is possible, but
 * rarely applicable, to override this method to maintain other
 * objects or fields holding result data.
 *
 * <p>A CountedCompleter that does not itself have a completer (i.e.,
 * one for which {@link #getCompleter} returns {@code null}) can be
 * used as a regular ForkJoinTask with this added functionality.
 * However, any completer that in turn has another completer serves
 * only as an internal helper for other computations, so its own task
 * status (as reported in methods such as {@link ForkJoinTask#isDone})
 * is arbitrary; this status changes only upon explicit invocations of
 * {@link #complete}, {@link ForkJoinTask#cancel},
 * {@link ForkJoinTask#completeExceptionally(Throwable)} or upon
 * exceptional completion of method {@code compute}. Upon any
 * exceptional completion, the exception may be relayed to a task's
 * completer (and its completer, and so on), if one exists and it has
 * not otherwise already completed. Similarly, cancelling an internal
 * CountedCompleter has only a local effect on that completer, so is
 * not often useful.
 *
 * <p><b>Sample Usages.</b>
 *
 * <p><b>Parallel recursive decomposition.</b> CountedCompleters may
 * be arranged in trees similar to those often used with {@link
 * RecursiveAction}s, although the constructions involved in setting
 * them up typically vary. Here, the completer of each task is its
 * parent in the computation tree. Even though they entail a bit more
 * bookkeeping, CountedCompleters may be better choices when applying
 * a possibly time-consuming operation (that cannot be further
 * subdivided) to each element of an array or collection; especially
 * when the operation takes a significantly different amount of time
 * to complete for some elements than others, either because of
 * intrinsic variation (for example I/O) or auxiliary effects such as
 * garbage collection.  Because CountedCompleters provide their own
 * continuations, other tasks need not block waiting to perform them.
 *
 * <p>For example, here is an initial version of a utility method that
 * uses divide-by-two recursive decomposition to divide work into
 * single pieces (leaf tasks). Even when work is split into individual
 * calls, tree-based techniques are usually preferable to directly
 * forking leaf tasks, because they reduce inter-thread communication
 * and improve load balancing. In the recursive case, the second of
 * each pair of subtasks to finish triggers completion of their parent
 * (because no result combination is performed, the default no-op
 * implementation of method {@code onCompletion} is not overridden).
 * The utility method sets up the root task and invokes it (here,
 * implicitly using the {@link ForkJoinPool#commonPool()}).  It is
 * straightforward and reliable (but not optimal) to always set the
 * pending count to the number of child tasks and call {@code
 * tryComplete()} immediately before returning.
 *
 * <pre> {@code
 * static <E> void forEach(E[] array, Consumer<E> action) {
 *   class Task extends CountedCompleter!(void) {
 *     final int lo, hi;
 *     Task(Task parent, int lo, int hi) {
 *       super(parent); this.lo = lo; this.hi = hi;
 *     }
 *
 *     void compute() {
 *       if (hi - lo >= 2) {
 *         int mid = (lo + hi) >>> 1;
 *         // must set pending count before fork
 *         setPendingCount(2);
 *         new Task(this, mid, hi).fork(); // right child
 *         new Task(this, lo, mid).fork(); // left child
 *       }
 *       else if (hi > lo)
 *         action.accept(array[lo]);
 *       tryComplete();
 *     }
 *   }
 *   new Task(null, 0, array.length).invoke();
 * }}</pre>
 *
 * This design can be improved by noticing that in the recursive case,
 * the task has nothing to do after forking its right task, so can
 * directly invoke its left task before returning. (This is an analog
 * of tail recursion removal.)  Also, when the last action in a task
 * is to fork or invoke a subtask (a "tail call"), the call to {@code
 * tryComplete()} can be optimized away, at the cost of making the
 * pending count look "off by one".
 *
 * <pre> {@code
 *     void compute() {
 *       if (hi - lo >= 2) {
 *         int mid = (lo + hi) >>> 1;
 *         setPendingCount(1); // looks off by one, but correct!
 *         new Task(this, mid, hi).fork(); // right child
 *         new Task(this, lo, mid).compute(); // direct invoke
 *       } else {
 *         if (hi > lo)
 *           action.accept(array[lo]);
 *         tryComplete();
 *       }
 *     }}</pre>
 *
 * As a further optimization, notice that the left task need not even exist.
 * Instead of creating a new one, we can continue using the original task,
 * and add a pending count for each fork.  Additionally, because no task
 * in this tree implements an {@link #onCompletion(CountedCompleter)} method,
 * {@code tryComplete} can be replaced with {@link #propagateCompletion}.
 *
 * <pre> {@code
 *     void compute() {
 *       int n = hi - lo;
 *       for (; n >= 2; n /= 2) {
 *         addToPendingCount(1);
 *         new Task(this, lo + n/2, lo + n).fork();
 *       }
 *       if (n > 0)
 *         action.accept(array[lo]);
 *       propagateCompletion();
 *     }}</pre>
 *
 * When pending counts can be precomputed, they can be established in
 * the constructor:
 *
 * <pre> {@code
 * static <E> void forEach(E[] array, Consumer<E> action) {
 *   class Task extends CountedCompleter!(void) {
 *     final int lo, hi;
 *     Task(Task parent, int lo, int hi) {
 *       super(parent, 31 - Integer.numberOfLeadingZeros(hi - lo));
 *       this.lo = lo; this.hi = hi;
 *     }
 *
 *     void compute() {
 *       for (int n = hi - lo; n >= 2; n /= 2)
 *         new Task(this, lo + n/2, lo + n).fork();
 *       action.accept(array[lo]);
 *       propagateCompletion();
 *     }
 *   }
 *   if (array.length > 0)
 *     new Task(null, 0, array.length).invoke();
 * }}</pre>
 *
 * Additional optimizations of such classes might entail specializing
 * classes for leaf steps, subdividing by say, four, instead of two
 * per iteration, and using an adaptive threshold instead of always
 * subdividing down to single elements.
 *
 * <p><b>Searching.</b> A tree of CountedCompleters can search for a
 * value or property in different parts of a data structure, and
 * report a result in an {@link
 * hunt.concurrency.atomic.AtomicReference AtomicReference} as
 * soon as one is found. The others can poll the result to avoid
 * unnecessary work. (You could additionally {@linkplain #cancel
 * cancel} other tasks, but it is usually simpler and more efficient
 * to just let them notice that the result is set and if so skip
 * further processing.)  Illustrating again with an array using full
 * partitioning (again, in practice, leaf tasks will almost always
 * process more than one element):
 *
 * <pre> {@code
 * class Searcher<E> extends CountedCompleter<E> {
 *   final E[] array; final AtomicReference<E> result; final int lo, hi;
 *   Searcher(ICountedCompleter p, E[] array, AtomicReference<E> result, int lo, int hi) {
 *     super(p);
 *     this.array = array; this.result = result; this.lo = lo; this.hi = hi;
 *   }
 *   E getRawResult() { return result.get(); }
 *   void compute() { // similar to ForEach version 3
 *     int l = lo, h = hi;
 *     while (result.get() is null && h >= l) {
 *       if (h - l >= 2) {
 *         int mid = (l + h) >>> 1;
 *         addToPendingCount(1);
 *         new Searcher(this, array, result, mid, h).fork();
 *         h = mid;
 *       }
 *       else {
 *         E x = array[l];
 *         if (matches(x) && result.compareAndSet(null, x))
 *           quietlyCompleteRoot(); // root task is now joinable
 *         break;
 *       }
 *     }
 *     tryComplete(); // normally complete whether or not found
 *   }
 *   bool matches(E e) { ... } // return true if found
 *
 *   static <E> E search(E[] array) {
 *       return new Searcher<E>(null, array, new AtomicReference<E>(), 0, array.length).invoke();
 *   }
 * }}</pre>
 *
 * In this example, as well as others in which tasks have no other
 * effects except to {@code compareAndSet} a common result, the
 * trailing unconditional invocation of {@code tryComplete} could be
 * made conditional ({@code if (result.get() is null) tryComplete();})
 * because no further bookkeeping is required to manage completions
 * once the root task completes.
 *
 * <p><b>Recording subtasks.</b> CountedCompleter tasks that combine
 * results of multiple subtasks usually need to access these results
 * in method {@link #onCompletion(CountedCompleter)}. As illustrated in the following
 * class (that performs a simplified form of map-reduce where mappings
 * and reductions are all of type {@code E}), one way to do this in
 * divide and conquer designs is to have each subtask record its
 * sibling, so that it can be accessed in method {@code onCompletion}.
 * This technique applies to reductions in which the order of
 * combining left and right results does not matter; ordered
 * reductions require explicit left/right designations.  Variants of
 * other streamlinings seen in the above examples may also apply.
 *
 * <pre> {@code
 * class MyMapper<E> { E apply(E v) {  ...  } }
 * class MyReducer<E> { E apply(E x, E y) {  ...  } }
 * class MapReducer<E> extends CountedCompleter<E> {
 *   final E[] array; final MyMapper<E> mapper;
 *   final MyReducer<E> reducer; final int lo, hi;
 *   MapReducer<E> sibling;
 *   E result;
 *   MapReducer(ICountedCompleter p, E[] array, MyMapper<E> mapper,
 *              MyReducer<E> reducer, int lo, int hi) {
 *     super(p);
 *     this.array = array; this.mapper = mapper;
 *     this.reducer = reducer; this.lo = lo; this.hi = hi;
 *   }
 *   void compute() {
 *     if (hi - lo >= 2) {
 *       int mid = (lo + hi) >>> 1;
 *       MapReducer<E> left = new MapReducer(this, array, mapper, reducer, lo, mid);
 *       MapReducer<E> right = new MapReducer(this, array, mapper, reducer, mid, hi);
 *       left.sibling = right;
 *       right.sibling = left;
 *       setPendingCount(1); // only right is pending
 *       right.fork();
 *       left.compute();     // directly execute left
 *     }
 *     else {
 *       if (hi > lo)
 *           result = mapper.apply(array[lo]);
 *       tryComplete();
 *     }
 *   }
 *   void onCompletion(ICountedCompleter caller) {
 *     if (caller != this) {
 *       MapReducer<E> child = (MapReducer<E>)caller;
 *       MapReducer<E> sib = child.sibling;
 *       if (sib is null || sib.result is null)
 *         result = child.result;
 *       else
 *         result = reducer.apply(child.result, sib.result);
 *     }
 *   }
 *   E getRawResult() { return result; }
 *
 *   static <E> E mapReduce(E[] array, MyMapper<E> mapper, MyReducer<E> reducer) {
 *     return new MapReducer<E>(null, array, mapper, reducer,
 *                              0, array.length).invoke();
 *   }
 * }}</pre>
 *
 * Here, method {@code onCompletion} takes a form common to many
 * completion designs that combine results. This callback-style method
 * is triggered once per task, in either of the two different contexts
 * in which the pending count is, or becomes, zero: (1) by a task
 * itself, if its pending count is zero upon invocation of {@code
 * tryComplete}, or (2) by any of its subtasks when they complete and
 * decrement the pending count to zero. The {@code caller} argument
 * distinguishes cases.  Most often, when the caller is {@code this},
 * no action is necessary. Otherwise the caller argument can be used
 * (usually via a cast) to supply a value (and/or links to other
 * values) to be combined.  Assuming proper use of pending counts, the
 * actions inside {@code onCompletion} occur (once) upon completion of
 * a task and its subtasks. No additional synchronization is required
 * within this method to ensure thread safety of accesses to fields of
 * this task or other completed tasks.
 *
 * <p><b>Completion Traversals</b>. If using {@code onCompletion} to
 * process completions is inapplicable or inconvenient, you can use
 * methods {@link #firstComplete} and {@link #nextComplete} to create
 * custom traversals.  For example, to define a MapReducer that only
 * splits out right-hand tasks in the form of the third ForEach
 * example, the completions must cooperatively reduce along
 * unexhausted subtask links, which can be done as follows:
 *
 * <pre> {@code
 * class MapReducer<E> extends CountedCompleter<E> { // version 2
 *   final E[] array; final MyMapper<E> mapper;
 *   final MyReducer<E> reducer; final int lo, hi;
 *   MapReducer<E> forks, next; // record subtask forks in list
 *   E result;
 *   MapReducer(ICountedCompleter p, E[] array, MyMapper<E> mapper,
 *              MyReducer<E> reducer, int lo, int hi, MapReducer<E> next) {
 *     super(p);
 *     this.array = array; this.mapper = mapper;
 *     this.reducer = reducer; this.lo = lo; this.hi = hi;
 *     this.next = next;
 *   }
 *   void compute() {
 *     int l = lo, h = hi;
 *     while (h - l >= 2) {
 *       int mid = (l + h) >>> 1;
 *       addToPendingCount(1);
 *       (forks = new MapReducer(this, array, mapper, reducer, mid, h, forks)).fork();
 *       h = mid;
 *     }
 *     if (h > l)
 *       result = mapper.apply(array[l]);
 *     // process completions by reducing along and advancing subtask links
 *     for (ICountedCompleter c = firstComplete(); c !is null; c = c.nextComplete()) {
 *       for (MapReducer t = (MapReducer)c, s = t.forks; s !is null; s = t.forks = s.next)
 *         t.result = reducer.apply(t.result, s.result);
 *     }
 *   }
 *   E getRawResult() { return result; }
 *
 *   static <E> E mapReduce(E[] array, MyMapper<E> mapper, MyReducer<E> reducer) {
 *     return new MapReducer<E>(null, array, mapper, reducer,
 *                              0, array.length, null).invoke();
 *   }
 * }}</pre>
 *
 * <p><b>Triggers.</b> Some CountedCompleters are themselves never
 * forked, but instead serve as bits of plumbing in other designs;
 * including those in which the completion of one or more async tasks
 * triggers another async task. For example:
 *
 * <pre> {@code
 * class HeaderBuilder extends CountedCompleter<...> { ... }
 * class BodyBuilder extends CountedCompleter<...> { ... }
 * class PacketSender extends CountedCompleter<...> {
 *   PacketSender(...) { super(null, 1); ... } // trigger on second completion
 *   void compute() { } // never called
 *   void onCompletion(ICountedCompleter caller) { sendPacket(); }
 * }
 * // sample use:
 * PacketSender p = new PacketSender();
 * new HeaderBuilder(p, ...).fork();
 * new BodyBuilder(p, ...).fork();}</pre>
 *
 * @author Doug Lea
 */
abstract class CountedCompleter(T) : ForkJoinTask!(T), ICountedCompleter {

    /** This task's completer, or null if none */
    ICountedCompleter completer;
    /** The number of pending tasks until completion */
    int pending;

    /**
     * Creates a new CountedCompleter with the given completer
     * and initial pending count.
     *
     * @param completer this task's completer, or {@code null} if none
     * @param initialPendingCount the initial pending count
     */
    protected this(ICountedCompleter completer,
                               int initialPendingCount) {
        this.completer = completer;
        this.pending = initialPendingCount;
    }

    /**
     * Creates a new CountedCompleter with the given completer
     * and an initial pending count of zero.
     *
     * @param completer this task's completer, or {@code null} if none
     */
    protected this(ICountedCompleter completer) {
        this.completer = completer;
    }

    /**
     * Creates a new CountedCompleter with no completer
     * and an initial pending count of zero.
     */
    protected this() {
        this.completer = null;
    }

    ICountedCompleter getCompleter() {
        return completer;
    }

    /**
     * The main computation performed by this task.
     */
    abstract void compute();

    /**
     * Performs an action when method {@link #tryComplete} is invoked
     * and the pending count is zero, or when the unconditional
     * method {@link #complete} is invoked.  By default, this method
     * does nothing. You can distinguish cases by checking the
     * identity of the given caller argument. If not equal to {@code
     * this}, then it is typically a subtask that may contain results
     * (and/or links to other results) to combine.
     *
     * @param caller the task invoking this method (which may
     * be this task itself)
     */
    void onCompletion(ICountedCompleter caller) {
    }

    /**
     * Performs an action when method {@link
     * #completeExceptionally(Throwable)} is invoked or method {@link
     * #compute} throws an exception, and this task has not already
     * otherwise completed normally. On entry to this method, this task
     * {@link ForkJoinTask#isCompletedAbnormally}.  The return value
     * of this method controls further propagation: If {@code true}
     * and this task has a completer that has not completed, then that
     * completer is also completed exceptionally, with the same
     * exception as this completer.  The default implementation of
     * this method does nothing except return {@code true}.
     *
     * @param ex the exception
     * @param caller the task invoking this method (which may
     * be this task itself)
     * @return {@code true} if this exception should be propagated to this
     * task's completer, if one exists
     */
    bool onExceptionalCompletion(Throwable ex, ICountedCompleter caller) {
        return true;
    }

    /**
     * Returns the completer established in this task's constructor,
     * or {@code null} if none.
     *
     * @return the completer
     */
    final ICountedCompleter getCompleter() {
        return completer;
    }

    /**
     * Returns the current pending count.
     *
     * @return the current pending count
     */
    final int getPendingCount() {
        return pending;
    }

    /**
     * Sets the pending count to the given value.
     *
     * @param count the count
     */
    final void setPendingCount(int count) {
        pending = count;
    }

    /**
     * Adds (atomically) the given value to the pending count.
     *
     * @param delta the value to add
     */
    final void addToPendingCount(int delta) {
        PENDING.getAndAdd(this, delta);
    }

    /**
     * Sets (atomically) the pending count to the given count only if
     * it currently holds the given expected value.
     *
     * @param expected the expected value
     * @param count the new value
     * @return {@code true} if successful
     */
    final bool compareAndSetPendingCount(int expected, int count) {
        return PENDING.compareAndSet(this, expected, count);
    }

    /**
     * If the pending count is nonzero, (atomically) decrements it.
     *
     * @return the initial (undecremented) pending count holding on entry
     * to this method
     */
    final int decrementPendingCountUnlessZero() {
        int c;
        do {} while ((c = pending) != 0 &&
                     !PENDING.weakCompareAndSet(this, c, c - 1));
        return c;
    }

    /**
     * Returns the root of the current computation; i.e., this
     * task if it has no completer, else its completer's root.
     *
     * @return the root of the current computation
     */
    final ICountedCompleter getRoot() {
        ICountedCompleter a = this, p;
        while ((p = a.completer) !is null)
            a = p;
        return a;
    }

    /**
     * If the pending count is nonzero, decrements the count;
     * otherwise invokes {@link #onCompletion(CountedCompleter)}
     * and then similarly tries to complete this task's completer,
     * if one exists, else marks this task as complete.
     */
    final void tryComplete() {
        ICountedCompleter a = this, s = a;
        for (int c;;) {
            if ((c = a.pending) == 0) {
                a.onCompletion(s);
                if ((a = (s = a).completer) is null) {
                    s.quietlyComplete();
                    return;
                }
            }
            else if (PENDING.weakCompareAndSet(a, c, c - 1))
                return;
        }
    }

    /**
     * Equivalent to {@link #tryComplete} but does not invoke {@link
     * #onCompletion(CountedCompleter)} along the completion path:
     * If the pending count is nonzero, decrements the count;
     * otherwise, similarly tries to complete this task's completer, if
     * one exists, else marks this task as complete. This method may be
     * useful in cases where {@code onCompletion} should not, or need
     * not, be invoked for each completer in a computation.
     */
    final void propagateCompletion() {
        ICountedCompleter a = this, s;
        for (int c;;) {
            if ((c = a.pending) == 0) {
                if ((a = (s = a).completer) is null) {
                    s.quietlyComplete();
                    return;
                }
            }
            else if (PENDING.weakCompareAndSet(a, c, c - 1))
                return;
        }
    }

    /**
     * Regardless of pending count, invokes
     * {@link #onCompletion(CountedCompleter)}, marks this task as
     * complete and further triggers {@link #tryComplete} on this
     * task's completer, if one exists.  The given rawResult is
     * used as an argument to {@link #setRawResult} before invoking
     * {@link #onCompletion(CountedCompleter)} or marking this task
     * as complete; its value is meaningful only for classes
     * overriding {@code setRawResult}.  This method does not modify
     * the pending count.
     *
     * <p>This method may be useful when forcing completion as soon as
     * any one (versus all) of several subtask results are obtained.
     * However, in the common (and recommended) case in which {@code
     * setRawResult} is not overridden, this effect can be obtained
     * more simply using {@link #quietlyCompleteRoot()}.
     *
     * @param rawResult the raw result
     */
    void complete(T rawResult) {
        ICountedCompleter p;
        setRawResult(rawResult);
        onCompletion(this);
        quietlyComplete();
        if ((p = completer) !is null)
            p.tryComplete();
    }

    /**
     * If this task's pending count is zero, returns this task;
     * otherwise decrements its pending count and returns {@code null}.
     * This method is designed to be used with {@link #nextComplete} in
     * completion traversal loops.
     *
     * @return this task, if pending count was zero, else {@code null}
     */
    final ICountedCompleter firstComplete() {
        for (int c;;) {
            if ((c = pending) == 0)
                return this;
            else if (PENDING.weakCompareAndSet(this, c, c - 1))
                return null;
        }
    }

    /**
     * If this task does not have a completer, invokes {@link
     * ForkJoinTask#quietlyComplete} and returns {@code null}.  Or, if
     * the completer's pending count is non-zero, decrements that
     * pending count and returns {@code null}.  Otherwise, returns the
     * completer.  This method can be used as part of a completion
     * traversal loop for homogeneous task hierarchies:
     *
     * <pre> {@code
     * for (ICountedCompleter c = firstComplete();
     *      c !is null;
     *      c = c.nextComplete()) {
     *   // ... process c ...
     * }}</pre>
     *
     * @return the completer, or {@code null} if none
     */
    final ICountedCompleter nextComplete() {
        ICountedCompleter p;
        if ((p = completer) !is null)
            return p.firstComplete();
        else {
            quietlyComplete();
            return null;
        }
    }

    /**
     * Equivalent to {@code getRoot().quietlyComplete()}.
     */
    final void quietlyCompleteRoot() {
        for (ICountedCompleter a = this, p;;) {
            if ((p = a.completer) is null) {
                a.quietlyComplete();
                return;
            }
            a = p;
        }
    }

    /**
     * If this task has not completed, attempts to process at most the
     * given number of other unprocessed tasks for which this task is
     * on the completion path, if any are known to exist.
     *
     * @param maxTasks the maximum number of tasks to process.  If
     *                 less than or equal to zero, then no tasks are
     *                 processed.
     */
    final void helpComplete(int maxTasks) {
        Thread t = Thread.getThis(); 
        ForkJoinWorkerThread wt = cast(ForkJoinWorkerThread)t;
        if (maxTasks > 0 && status >= 0) {
            if (wt !is null)
                wt.pool.helpComplete(wt.workQueue, this, maxTasks);
            else
                ForkJoinPool.common.externalHelpComplete(this, maxTasks);
        }
    }

    /**
     * Supports ForkJoinTask exception propagation.
     */
    void internalPropagateException(Throwable ex) {
        ICountedCompleter a = this, s = a;
        while (a.onExceptionalCompletion(ex, s) &&
               (a = (s = a).completer) !is null && a.status >= 0 &&
               isExceptionalStatus(a.recordExceptionalCompletion(ex))) {

        }
    }

    /**
     * Implements execution conventions for CountedCompleters.
     */
    protected final bool exec() {
        compute();
        return false;
    }

    /**
     * Returns the result of the computation.  By default,
     * returns {@code null}, which is appropriate for {@code Void}
     * actions, but in other cases should be overridden, almost
     * always to return a field or function of a field that
     * holds the result upon completion.
     *
     * @return the result of the computation
     */
    T getRawResult() { return null; }

    /**
     * A method that result-bearing CountedCompleters may optionally
     * use to help maintain result data.  By default, does nothing.
     * Overrides are not recommended. However, if this method is
     * overridden to update existing objects or fields, then it must
     * in general be defined to be thread-safe.
     */
    protected void setRawResult(T t) { }

    // VarHandle mechanics
    // private static final VarHandle PENDING;
    // static {
    //     try {
    //         MethodHandles.Lookup l = MethodHandles.lookup();
    //         PENDING = l.findVarHandle(CountedCompleter.class, "pending", int.class);

    //     } catch (ReflectiveOperationException e) {
    //         throw new ExceptionInInitializerError(e);
    //     }
    // }
}


/**
 * A recursive result-bearing {@link ForkJoinTask}.
 *
 * <p>For a classic example, here is a task computing Fibonacci numbers:
 *
 * <pre> {@code
 * class Fibonacci extends RecursiveTask<Integer> {
 *   final int n;
 *   Fibonacci(int n) { this.n = n; }
 *   protected Integer compute() {
 *     if (n <= 1)
 *       return n;
 *     Fibonacci f1 = new Fibonacci(n - 1);
 *     f1.fork();
 *     Fibonacci f2 = new Fibonacci(n - 2);
 *     return f2.compute() + f1.join();
 *   }
 * }}</pre>
 *
 * However, besides being a dumb way to compute Fibonacci functions
 * (there is a simple fast linear algorithm that you'd use in
 * practice), this is likely to perform poorly because the smallest
 * subtasks are too small to be worthwhile splitting up. Instead, as
 * is the case for nearly all fork/join applications, you'd pick some
 * minimum granularity size (for example 10 here) for which you always
 * sequentially solve rather than subdividing.
 *
 * @author Doug Lea
 */
abstract class RecursiveTask(V) : ForkJoinTask!V {

    /**
     * The result of the computation.
     */
    V result;

    /**
     * The main computation performed by this task.
     * @return the result of the computation
     */
    protected abstract V compute();

    final override V getRawResult() {
        return result;
    }

    protected final override void setRawResult(V value) {
        result = value;
    }

    /**
     * Implements execution conventions for RecursiveTask.
     */
    protected final override bool exec() {
        result = compute();
        return true;
    }

}
