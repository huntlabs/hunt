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
 * Expert Group and released to the public domain, as explained at
 * http://creativecommons.org/publicdomain/zero/1.0/
 */

module hunt.concurrent.ScheduledThreadPoolExecutor;

import hunt.concurrent.atomic.AtomicHelper;
import hunt.concurrent.BlockingQueue;
import hunt.concurrent.Delayed;
import hunt.concurrent.Future;
import hunt.concurrent.FutureTask;
import hunt.concurrent.ScheduledExecutorService;
import hunt.concurrent.thread;
import hunt.concurrent.ThreadFactory;
import hunt.concurrent.ThreadPoolExecutor;

import hunt.container;
import hunt.datetime.Helper;
import hunt.lang.common;
import hunt.lang.exception;
import hunt.lang.Object;
debug import hunt.logging.ConsoleLogger;
// import core.time;

import core.atomic;
import core.sync.condition;
import core.sync.mutex;

import std.datetime;
// import hunt.container.AbstractQueue;
// import java.util.Arrays;
// import hunt.container.Collection;
// import hunt.container.Iterator;
// import java.util.List;
// import java.util.NoSuchElementException;
// import java.util.Objects;
// import hunt.concurrent.atomic.AtomicLong;
// import hunt.concurrent.locks.Condition;
// import hunt.concurrent.locks.ReentrantLock;

alias ReentrantLock = Mutex;

interface IScheduledFutureTask {
    void heapIndex(int index);
    int heapIndex();
}

/**
 * A {@link ThreadPoolExecutor} that can additionally schedule
 * commands to run after a given delay, or to execute periodically.
 * This class is preferable to {@link java.util.Timer} when multiple
 * worker threads are needed, or when the additional flexibility or
 * capabilities of {@link ThreadPoolExecutor} (which this class
 * extends) are required.
 *
 * <p>Delayed tasks execute no sooner than they are enabled, but
 * without any real-time guarantees about when, after they are
 * enabled, they will commence. Tasks scheduled for exactly the same
 * execution time are enabled in first-in-first-out (FIFO) order of
 * submission.
 *
 * <p>When a submitted task is cancelled before it is run, execution
 * is suppressed.  By default, such a cancelled task is not
 * automatically removed from the work queue until its delay elapses.
 * While this enables further inspection and monitoring, it may also
 * cause unbounded retention of cancelled tasks.  To avoid this, use
 * {@link #setRemoveOnCancelPolicy} to cause tasks to be immediately
 * removed from the work queue at time of cancellation.
 *
 * <p>Successive executions of a periodic task scheduled via
 * {@link #scheduleAtFixedRate scheduleAtFixedRate} or
 * {@link #scheduleWithFixedDelay scheduleWithFixedDelay}
 * do not overlap. While different executions may be performed by
 * different threads, the effects of prior executions
 * <a href="package-summary.html#MemoryVisibility"><i>happen-before</i></a>
 * those of subsequent ones.
 *
 * <p>While this class inherits from {@link ThreadPoolExecutor}, a few
 * of the inherited tuning methods are not useful for it. In
 * particular, because it acts as a fixed-sized pool using
 * {@code corePoolSize} threads and an unbounded queue, adjustments
 * to {@code maximumPoolSize} have no useful effect. Additionally, it
 * is almost never a good idea to set {@code corePoolSize} to zero or
 * use {@code allowCoreThreadTimeOut} because this may leave the pool
 * without threads to handle tasks once they become eligible to run.
 *
 * <p>As with {@code ThreadPoolExecutor}, if not otherwise specified,
 * this class uses {@link Executors#defaultThreadFactory} as the
 * default thread factory, and {@link ThreadPoolExecutor.AbortPolicy}
 * as the default rejected execution handler.
 *
 * <p><b>Extension notes:</b> This class overrides the
 * {@link ThreadPoolExecutor#execute(Runnable) execute} and
 * {@link AbstractExecutorService#submit(Runnable) submit}
 * methods to generate internal {@link ScheduledFuture} objects to
 * control per-task delays and scheduling.  To preserve
 * functionality, any further overrides of these methods in
 * subclasses must invoke superclass versions, which effectively
 * disables additional task customization.  However, this class
 * provides alternative protected extension method
 * {@code decorateTask} (one version each for {@code Runnable} and
 * {@code Callable}) that can be used to customize the concrete task
 * types used to execute commands entered via {@code execute},
 * {@code submit}, {@code schedule}, {@code scheduleAtFixedRate},
 * and {@code scheduleWithFixedDelay}.  By default, a
 * {@code ScheduledThreadPoolExecutor} uses a task type extending
 * {@link FutureTask}. However, this may be modified or replaced using
 * subclasses of the form:
 *
 * <pre> {@code
 * class CustomScheduledExecutor extends ScheduledThreadPoolExecutor {
 *
 *   static class CustomTask!(V) : RunnableScheduledFuture!(V) { ... }
 *
 *   protected !(V) RunnableScheduledFuture!(V) decorateTask(
 *                Runnable r, RunnableScheduledFuture!(V) task) {
 *       return new CustomTask!(V)(r, task);
 *   }
 *
 *   protected !(V) RunnableScheduledFuture!(V) decorateTask(
 *                Callable!(V) c, RunnableScheduledFuture!(V) task) {
 *       return new CustomTask!(V)(c, task);
 *   }
 *   // ... add constructors, etc.
 * }}</pre>
 *
 * @since 1.5
 * @author Doug Lea
 */
class ScheduledThreadPoolExecutor : ThreadPoolExecutor, ScheduledExecutorService {

    /*
     * This class specializes ThreadPoolExecutor implementation by
     *
     * 1. Using a custom task type ScheduledFutureTask, even for tasks
     *    that don't require scheduling because they are submitted
     *    using ExecutorService rather than ScheduledExecutorService
     *    methods, which are treated as tasks with a delay of zero.
     *
     * 2. Using a custom queue (DelayedWorkQueue), a variant of
     *    unbounded DelayQueue. The lack of capacity constraint and
     *    the fact that corePoolSize and maximumPoolSize are
     *    effectively identical simplifies some execution mechanics
     *    (see delayedExecute) compared to ThreadPoolExecutor.
     *
     * 3. Supporting optional run-after-shutdown parameters, which
     *    leads to overrides of shutdown methods to remove and cancel
     *    tasks that should NOT be run after shutdown, as well as
     *    different recheck logic when task (re)submission overlaps
     *    with a shutdown.
     *
     * 4. Task decoration methods to allow interception and
     *    instrumentation, which are needed because subclasses cannot
     *    otherwise override submit methods to get this effect. These
     *    don't have any impact on pool control logic though.
     */

    /**
     * False if should cancel/suppress periodic tasks on shutdown.
     */
    private bool continueExistingPeriodicTasksAfterShutdown;

    /**
     * False if should cancel non-periodic not-yet-expired tasks on shutdown.
     */
    private bool executeExistingDelayedTasksAfterShutdown = true;

    /**
     * True if ScheduledFutureTask.cancel should remove from queue.
     */
    bool removeOnCancel;

    /**
     * Sequence number to break scheduling ties, and in turn to
     * guarantee FIFO order among tied entries.
     */
    private shared static long sequencer; //= new AtomicLong();

    /**
     * Returns true if can run a task given current run state and
     * run-after-shutdown parameters.
     */
    bool canRunInCurrentRunState(V)(RunnableScheduledFuture!V task) {
        if (!isShutdown())
            return true;
        if (isStopped())
            return false;
        return task.isPeriodic()
            ? continueExistingPeriodicTasksAfterShutdown
            : (executeExistingDelayedTasksAfterShutdown
               || task.getDelay() <= Duration.zero);
    }

    /**
     * Main execution method for delayed or periodic tasks.  If pool
     * is shut down, rejects the task. Otherwise adds task to queue
     * and starts a thread, if necessary, to run it.  (We cannot
     * prestart the thread to run the task because the task (probably)
     * shouldn't be run yet.)  If the pool is shut down while the task
     * is being added, cancel and remove it if required by state and
     * run-after-shutdown parameters.
     *
     * @param task the task
     */
    private void delayedExecute(V)(RunnableScheduledFuture!V task) {
        if (isShutdown())
            reject(task);
        else {
            super.getQueue().add(task);
            if (!canRunInCurrentRunState(task) && remove(task))
                task.cancel(false);
            else
                ensurePrestart();
        }
    }

    /**
     * Requeues a periodic task unless current run state precludes it.
     * Same idea as delayedExecute except drops task rather than rejecting.
     *
     * @param task the task
     */
    void reExecutePeriodic(V)(RunnableScheduledFuture!V task) {
        if (canRunInCurrentRunState(task)) {
            super.getQueue().add(task);
            if (canRunInCurrentRunState(task) || !remove(task)) {
                ensurePrestart();
                return;
            }
        }
        task.cancel(false);
    }

    /**
     * Cancels and clears the queue of all tasks that should not be run
     * due to shutdown policy.  Invoked within super.shutdown.
     */
    override void onShutdown() {
        BlockingQueue!(Runnable) q = super.getQueue();
        bool keepDelayed =
            getExecuteExistingDelayedTasksAfterShutdownPolicy();
        bool keepPeriodic =
            getContinueExistingPeriodicTasksAfterShutdownPolicy();
        // Traverse snapshot to avoid iterator exceptions
        // TODO: implement and use efficient removeIf
        // super.getQueue().removeIf(...);
        foreach (Runnable e ; q.toArray()) {
            warning(typeid(e));
            implementationMissing(false);
            // RunnableScheduledFuture!V t = cast(RunnableScheduledFuture!V)e;
            // if (t !is null) {
            //     if ((t.isPeriodic()
            //          ? !keepPeriodic
            //          : (!keepDelayed && t.getDelay() > Duration.zero))
            //         || t.isCancelled()) { // also remove if already cancelled
            //         if (q.remove(t))
            //             t.cancel(false);
            //     }
            // }
        }
        tryTerminate();
    }

    /**
     * Modifies or replaces the task used to execute a runnable.
     * This method can be used to override the concrete
     * class used for managing internal tasks.
     * The default implementation simply returns the given task.
     *
     * @param runnable the submitted Runnable
     * @param task the task created to execute the runnable
     * @param (V) the type of the task's result
     * @return a task that can execute the runnable
     * @since 1.6
     */
    protected RunnableScheduledFuture!(V) decorateTask(V) (
        Runnable runnable, RunnableScheduledFuture!(V) task) {
        return task;
    }

    /**
     * Modifies or replaces the task used to execute a callable.
     * This method can be used to override the concrete
     * class used for managing internal tasks.
     * The default implementation simply returns the given task.
     *
     * @param callable the submitted Callable
     * @param task the task created to execute the callable
     * @param (V) the type of the task's result
     * @return a task that can execute the callable
     * @since 1.6
     */
    protected RunnableScheduledFuture!(V) decorateTask(V)(
        Callable!(V) callable, RunnableScheduledFuture!(V) task) {
        return task;
    }

    /**
     * The default keep-alive time for pool threads.
     *
     * Normally, this value is unused because all pool threads will be
     * core threads, but if a user creates a pool with a corePoolSize
     * of zero (against our advice), we keep a thread alive as long as
     * there are queued tasks.  If the keep alive time is zero (the
     * historic value), we end up hot-spinning in getTask, wasting a
     * CPU.  But on the other hand, if we set the value too high, and
     * users create a one-shot pool which they don't cleanly shutdown,
     * the pool's non-daemon threads will prevent JVM termination.  A
     * small but non-zero value (relative to a JVM's lifetime) seems
     * best.
     */
    private enum long DEFAULT_KEEPALIVE_MILLIS = 10L;

    /**
     * Creates a new {@code ScheduledThreadPoolExecutor} with the
     * given core pool size.
     *
     * @param corePoolSize the number of threads to keep in the pool, even
     *        if they are idle, unless {@code allowCoreThreadTimeOut} is set
     * @throws IllegalArgumentException if {@code corePoolSize < 0}
     */
    this(int corePoolSize) {
        super(corePoolSize, int.max, dur!(TimeUnit.Millisecond)(DEFAULT_KEEPALIVE_MILLIS),
              new DelayedWorkQueue());
    }

    /**
     * Creates a new {@code ScheduledThreadPoolExecutor} with the
     * given initial parameters.
     *
     * @param corePoolSize the number of threads to keep in the pool, even
     *        if they are idle, unless {@code allowCoreThreadTimeOut} is set
     * @param threadFactory the factory to use when the executor
     *        creates a new thread
     * @throws IllegalArgumentException if {@code corePoolSize < 0}
     * @throws NullPointerException if {@code threadFactory} is null
     */
    this(int corePoolSize, ThreadFactory threadFactory) {
        super(corePoolSize, int.max,
              dur!(TimeUnit.Millisecond)(DEFAULT_KEEPALIVE_MILLIS),
              new DelayedWorkQueue(), threadFactory);
    }

    /**
     * Creates a new {@code ScheduledThreadPoolExecutor} with the
     * given initial parameters.
     *
     * @param corePoolSize the number of threads to keep in the pool, even
     *        if they are idle, unless {@code allowCoreThreadTimeOut} is set
     * @param handler the handler to use when execution is blocked
     *        because the thread bounds and queue capacities are reached
     * @throws IllegalArgumentException if {@code corePoolSize < 0}
     * @throws NullPointerException if {@code handler} is null
     */
    this(int corePoolSize, RejectedExecutionHandler handler) {
        super(corePoolSize, int.max,
              dur!(TimeUnit.Millisecond)(DEFAULT_KEEPALIVE_MILLIS),
              new DelayedWorkQueue(), handler);
    }

    /**
     * Creates a new {@code ScheduledThreadPoolExecutor} with the
     * given initial parameters.
     *
     * @param corePoolSize the number of threads to keep in the pool, even
     *        if they are idle, unless {@code allowCoreThreadTimeOut} is set
     * @param threadFactory the factory to use when the executor
     *        creates a new thread
     * @param handler the handler to use when execution is blocked
     *        because the thread bounds and queue capacities are reached
     * @throws IllegalArgumentException if {@code corePoolSize < 0}
     * @throws NullPointerException if {@code threadFactory} or
     *         {@code handler} is null
     */
    this(int corePoolSize, ThreadFactory threadFactory,
                                       RejectedExecutionHandler handler) {
        super(corePoolSize, int.max,
              dur!(TimeUnit.Millisecond)(DEFAULT_KEEPALIVE_MILLIS),
              new DelayedWorkQueue(), threadFactory, handler);
    }

    /**
     * Returns the nanoTime-based trigger time of a delayed action.
     */
    private long triggerTime(Duration delay) {
        return triggerTime(delay.isNegative ? 0 : delay.total!(TimeUnit.HectoNanosecond)());
    }

    /**
     * Returns the nanoTime-based trigger time of a delayed action.
     */
    long triggerTime(long delay) {
        return Clock.currStdTime +
            ((delay < (long.max >> 1)) ? delay : overflowFree(delay));
    }

    /**
     * Constrains the values of all delays in the queue to be within
     * long.max of each other, to avoid overflow in compareTo.
     * This may occur if a task is eligible to be dequeued, but has
     * not yet been, while some other task is added with a delay of
     * long.max.
     */
    private long overflowFree(long delay) {
        Delayed head = cast(Delayed) super.getQueue().peek();
        if (head !is null) {
            long headDelay = head.getDelay().total!(TimeUnit.HectoNanosecond)();
            if (headDelay < 0 && (delay - headDelay < 0))
                delay = long.max + headDelay;
        }
        return delay;
    }

    /**
     * @throws RejectedExecutionException {@inheritDoc}
     * @throws NullPointerException       {@inheritDoc}
     */
    ScheduledFuture!(void) schedule(Runnable command, Duration delay) {
        if (command is null)
            throw new NullPointerException();
        long n = atomicOp!"+="(sequencer, 1);
        n--;
        RunnableScheduledFuture!(void) t = decorateTask(command,
            new ScheduledFutureTask!(void)(command, triggerTime(delay), n, this));
        delayedExecute!(void)(t);
        return t;
    }

    /**
     * @throws RejectedExecutionException {@inheritDoc}
     * @throws NullPointerException       {@inheritDoc}
     */
    ScheduledFuture!(V) schedule(V)(Callable!(V) callable, Duration delay) {
        if (callable is null || unit is null)
            throw new NullPointerException();
        RunnableScheduledFuture!(V) t = decorateTask(callable,
            new ScheduledFutureTask!(V)(callable,
                                       triggerTime(delay),
                                       cast(long)AtomicHelper.getAndIncrement(sequencer), this));
        delayedExecute(t);
        return t;
    }

    /**
     * Submits a periodic action that becomes enabled first after the
     * given initial delay, and subsequently with the given period;
     * that is, executions will commence after
     * {@code initialDelay}, then {@code initialDelay + period}, then
     * {@code initialDelay + 2 * period}, and so on.
     *
     * <p>The sequence of task executions continues indefinitely until
     * one of the following exceptional completions occur:
     * <ul>
     * <li>The task is {@linkplain Future#cancel explicitly cancelled}
     * via the returned future.
     * <li>Method {@link #shutdown} is called and the {@linkplain
     * #getContinueExistingPeriodicTasksAfterShutdownPolicy policy on
     * whether to continue after shutdown} is not set true, or method
     * {@link #shutdownNow} is called; also resulting in task
     * cancellation.
     * <li>An execution of the task throws an exception.  In this case
     * calling {@link Future#get() get} on the returned future will throw
     * {@link ExecutionException}, holding the exception as its cause.
     * </ul>
     * Subsequent executions are suppressed.  Subsequent calls to
     * {@link Future#isDone isDone()} on the returned future will
     * return {@code true}.
     *
     * <p>If any execution of this task takes longer than its period, then
     * subsequent executions may start late, but will not concurrently
     * execute.
     *
     * @throws RejectedExecutionException {@inheritDoc}
     * @throws NullPointerException       {@inheritDoc}
     * @throws IllegalArgumentException   {@inheritDoc}
     */
    ScheduledFuture!void scheduleAtFixedRate(Runnable command,
                                                  Duration initialDelay,
                                                  Duration period) {
        if (command is null)
            throw new NullPointerException();
        if (period <= Duration.zero)
            throw new IllegalArgumentException();
        ScheduledFutureTask!(void) sft =
            new ScheduledFutureTask!(void)(command,
                                          triggerTime(initialDelay),
                                          period.total!(TimeUnit.HectoNanosecond)(), 
                                          cast(long)AtomicHelper.getAndIncrement(sequencer), this);
        RunnableScheduledFuture!(void) t = decorateTask(command, sft);
        sft.outerTask = t;
        delayedExecute(t);
        return t;
    }

    /**
     * Submits a periodic action that becomes enabled first after the
     * given initial delay, and subsequently with the given delay
     * between the termination of one execution and the commencement of
     * the next.
     *
     * <p>The sequence of task executions continues indefinitely until
     * one of the following exceptional completions occur:
     * <ul>
     * <li>The task is {@linkplain Future#cancel explicitly cancelled}
     * via the returned future.
     * <li>Method {@link #shutdown} is called and the {@linkplain
     * #getContinueExistingPeriodicTasksAfterShutdownPolicy policy on
     * whether to continue after shutdown} is not set true, or method
     * {@link #shutdownNow} is called; also resulting in task
     * cancellation.
     * <li>An execution of the task throws an exception.  In this case
     * calling {@link Future#get() get} on the returned future will throw
     * {@link ExecutionException}, holding the exception as its cause.
     * </ul>
     * Subsequent executions are suppressed.  Subsequent calls to
     * {@link Future#isDone isDone()} on the returned future will
     * return {@code true}.
     *
     * @throws RejectedExecutionException {@inheritDoc}
     * @throws NullPointerException       {@inheritDoc}
     * @throws IllegalArgumentException   {@inheritDoc}
     */
    ScheduledFuture!(void) scheduleWithFixedDelay(Runnable command,
                                                     Duration initialDelay,
                                                     Duration delay) {
        if (command is null)
            throw new NullPointerException();
        if (delay <= Duration.zero)
            throw new IllegalArgumentException();
        ScheduledFutureTask!(void) sft =
            new ScheduledFutureTask!(void)(command,
                                          triggerTime(initialDelay),
                                          -delay.total!(TimeUnit.HectoNanosecond)(),
                                          cast(long)AtomicHelper.getAndIncrement(sequencer), this);
        RunnableScheduledFuture!(void) t = decorateTask(command, sft);
        sft.outerTask = t;
        delayedExecute(t);
        return t;
    }

    /**
     * Executes {@code command} with zero required delay.
     * This has effect equivalent to
     * {@link #schedule(Runnable,long,TimeUnit) schedule(command, 0, anyUnit)}.
     * Note that inspections of the queue and of the list returned by
     * {@code shutdownNow} will access the zero-delayed
     * {@link ScheduledFuture}, not the {@code command} itself.
     *
     * <p>A consequence of the use of {@code ScheduledFuture} objects is
     * that {@link ThreadPoolExecutor#afterExecute afterExecute} is always
     * called with a null second {@code Throwable} argument, even if the
     * {@code command} terminated abruptly.  Instead, the {@code Throwable}
     * thrown by such a task can be obtained via {@link Future#get}.
     *
     * @throws RejectedExecutionException at discretion of
     *         {@code RejectedExecutionHandler}, if the task
     *         cannot be accepted for execution because the
     *         executor has been shut down
     * @throws NullPointerException {@inheritDoc}
     */
    override void execute(Runnable command) {
        schedule(command, Duration.zero);
    }

    // Override AbstractExecutorService methods

    /**
     * @throws RejectedExecutionException {@inheritDoc}
     * @throws NullPointerException       {@inheritDoc}
     */
    override Future!void submit(Runnable task) {
        return schedule(task, Duration.zero);
    }

    /**
     * @throws RejectedExecutionException {@inheritDoc}
     * @throws NullPointerException       {@inheritDoc}
     */
    Future!(T) submit(T)(Runnable task, T result) {
        return schedule(Executors.callable(task, result), Duration.zero);
    }

    /**
     * @throws RejectedExecutionException {@inheritDoc}
     * @throws NullPointerException       {@inheritDoc}
     */
    Future!(T) submit(T)(Callable!(T) task) {
        return schedule(task, Duration.zero);
    }

    /**
     * Sets the policy on whether to continue executing existing
     * periodic tasks even when this executor has been {@code shutdown}.
     * In this case, executions will continue until {@code shutdownNow}
     * or the policy is set to {@code false} when already shutdown.
     * This value is by default {@code false}.
     *
     * @param value if {@code true}, continue after shutdown, else don't
     * @see #getContinueExistingPeriodicTasksAfterShutdownPolicy
     */
    void setContinueExistingPeriodicTasksAfterShutdownPolicy(bool value) {
        continueExistingPeriodicTasksAfterShutdown = value;
        if (!value && isShutdown())
            onShutdown();
    }

    /**
     * Gets the policy on whether to continue executing existing
     * periodic tasks even when this executor has been {@code shutdown}.
     * In this case, executions will continue until {@code shutdownNow}
     * or the policy is set to {@code false} when already shutdown.
     * This value is by default {@code false}.
     *
     * @return {@code true} if will continue after shutdown
     * @see #setContinueExistingPeriodicTasksAfterShutdownPolicy
     */
    bool getContinueExistingPeriodicTasksAfterShutdownPolicy() {
        return continueExistingPeriodicTasksAfterShutdown;
    }

    /**
     * Sets the policy on whether to execute existing delayed
     * tasks even when this executor has been {@code shutdown}.
     * In this case, these tasks will only terminate upon
     * {@code shutdownNow}, or after setting the policy to
     * {@code false} when already shutdown.
     * This value is by default {@code true}.
     *
     * @param value if {@code true}, execute after shutdown, else don't
     * @see #getExecuteExistingDelayedTasksAfterShutdownPolicy
     */
    void setExecuteExistingDelayedTasksAfterShutdownPolicy(bool value) {
        executeExistingDelayedTasksAfterShutdown = value;
        if (!value && isShutdown())
            onShutdown();
    }

    /**
     * Gets the policy on whether to execute existing delayed
     * tasks even when this executor has been {@code shutdown}.
     * In this case, these tasks will only terminate upon
     * {@code shutdownNow}, or after setting the policy to
     * {@code false} when already shutdown.
     * This value is by default {@code true}.
     *
     * @return {@code true} if will execute after shutdown
     * @see #setExecuteExistingDelayedTasksAfterShutdownPolicy
     */
    bool getExecuteExistingDelayedTasksAfterShutdownPolicy() {
        return executeExistingDelayedTasksAfterShutdown;
    }

    /**
     * Sets the policy on whether cancelled tasks should be immediately
     * removed from the work queue at time of cancellation.  This value is
     * by default {@code false}.
     *
     * @param value if {@code true}, remove on cancellation, else don't
     * @see #getRemoveOnCancelPolicy
     * @since 1.7
     */
    void setRemoveOnCancelPolicy(bool value) {
        removeOnCancel = value;
    }

    /**
     * Gets the policy on whether cancelled tasks should be immediately
     * removed from the work queue at time of cancellation.  This value is
     * by default {@code false}.
     *
     * @return {@code true} if cancelled tasks are immediately removed
     *         from the queue
     * @see #setRemoveOnCancelPolicy
     * @since 1.7
     */
    bool getRemoveOnCancelPolicy() {
        return removeOnCancel;
    }

    /**
     * Initiates an orderly shutdown in which previously submitted
     * tasks are executed, but no new tasks will be accepted.
     * Invocation has no additional effect if already shut down.
     *
     * <p>This method does not wait for previously submitted tasks to
     * complete execution.  Use {@link #awaitTermination awaitTermination}
     * to do that.
     *
     * <p>If the {@code ExecuteExistingDelayedTasksAfterShutdownPolicy}
     * has been set {@code false}, existing delayed tasks whose delays
     * have not yet elapsed are cancelled.  And unless the {@code
     * ContinueExistingPeriodicTasksAfterShutdownPolicy} has been set
     * {@code true}, future executions of existing periodic tasks will
     * be cancelled.
     *
     * @throws SecurityException {@inheritDoc}
     */
    override void shutdown() {
        super.shutdown();
    }

    /**
     * Attempts to stop all actively executing tasks, halts the
     * processing of waiting tasks, and returns a list of the tasks
     * that were awaiting execution. These tasks are drained (removed)
     * from the task queue upon return from this method.
     *
     * <p>This method does not wait for actively executing tasks to
     * terminate.  Use {@link #awaitTermination awaitTermination} to
     * do that.
     *
     * <p>There are no guarantees beyond best-effort attempts to stop
     * processing actively executing tasks.  This implementation
     * interrupts tasks via {@link Thread#interrupt}; any task that
     * fails to respond to interrupts may never terminate.
     *
     * @return list of tasks that never commenced execution.
     *         Each element of this list is a {@link ScheduledFuture}.
     *         For tasks submitted via one of the {@code schedule}
     *         methods, the element will be identical to the returned
     *         {@code ScheduledFuture}.  For tasks submitted using
     *         {@link #execute execute}, the element will be a
     *         zero-delay {@code ScheduledFuture}.
     * @throws SecurityException {@inheritDoc}
     */
    override List!(Runnable) shutdownNow() {
        return super.shutdownNow();
    }

    /**
     * Returns the task queue used by this executor.  Access to the
     * task queue is intended primarily for debugging and monitoring.
     * This queue may be in active use.  Retrieving the task queue
     * does not prevent queued tasks from executing.
     *
     * <p>Each element of this queue is a {@link ScheduledFuture}.
     * For tasks submitted via one of the {@code schedule} methods, the
     * element will be identical to the returned {@code ScheduledFuture}.
     * For tasks submitted using {@link #execute execute}, the element
     * will be a zero-delay {@code ScheduledFuture}.
     *
     * <p>Iteration over this queue is <em>not</em> guaranteed to traverse
     * tasks in the order in which they will execute.
     *
     * @return the task queue
     */
    override BlockingQueue!(Runnable) getQueue() {
        return super.getQueue();
    }
}


/**
*/
private class ScheduledFutureTask(V) : FutureTask!(V) , 
    RunnableScheduledFuture!(V), IScheduledFutureTask {

    /** Sequence number to break ties FIFO */
    private long sequenceNumber;

    /** The nanoTime-based time when the task is enabled to execute. */
    private long time;

    /**
     * Period for repeating tasks, in nanoseconds.
     * A positive value indicates fixed-rate execution.
     * A negative value indicates fixed-delay execution.
     * A value of 0 indicates a non-repeating (one-shot) task.
     */
    private long period;

    /** The actual task to be re-enqueued by reExecutePeriodic */
    RunnableScheduledFuture!(V) outerTask; // = this;
    ScheduledThreadPoolExecutor poolExecutor;

    /**
     * Index into delay queue, to support faster cancellation.
     */
    int _heapIndex;

static if(is(V == void)) {         
    this(Runnable r, long triggerTime,
                        long sequenceNumber, ScheduledThreadPoolExecutor poolExecutor) {
        super(r);
        this.time = triggerTime;
        this.period = 0;
        this.sequenceNumber = sequenceNumber;
        this.poolExecutor = poolExecutor;
        initializeMembers();
    }        

    /**
     * Creates a periodic action with given nanoTime-based initial
     * trigger time and period.
     */
    this(Runnable r, long triggerTime,
                        long period, long sequenceNumber, ScheduledThreadPoolExecutor poolExecutor) {
        super(r);
        this.time = triggerTime;
        this.period = period;
        this.sequenceNumber = sequenceNumber;
        this.poolExecutor = poolExecutor;
        initializeMembers();
    }
} else {

    /**
     * Creates a one-shot action with given nanoTime-based trigger time.
     */
    this(Runnable r, V result, long triggerTime,
                        long sequenceNumber, ScheduledThreadPoolExecutor poolExecutor) {
        super(r, result);
        this.time = triggerTime;
        this.period = 0;
        this.sequenceNumber = sequenceNumber;
        this.poolExecutor = poolExecutor;
        initializeMembers();
    }           

    /**
     * Creates a periodic action with given nanoTime-based initial
     * trigger time and period.
     */
    this(Runnable r, V result, long triggerTime,
                        long period, long sequenceNumber, ScheduledThreadPoolExecutor poolExecutor) {
        super(r, result);
        this.time = triggerTime;
        this.period = period;
        this.sequenceNumber = sequenceNumber;
        this.poolExecutor = poolExecutor;
        initializeMembers();
    } 
}

    /**
     * Creates a one-shot action with given nanoTime-based trigger time.
     */
    this(Callable!(V) callable, long triggerTime,
                        long sequenceNumber, ScheduledThreadPoolExecutor poolExecutor) {
        super(callable);
        this.time = triggerTime;
        this.period = 0;
        this.sequenceNumber = sequenceNumber;
        this.poolExecutor = poolExecutor;
        initializeMembers();
    }

    private void initializeMembers() {
        outerTask = this;
    }
    
    void heapIndex(int index) {
        _heapIndex = index;
    }

    int heapIndex() {
        return _heapIndex;
    }

    Duration getDelay() {
        return dur!(TimeUnit.HectoNanosecond)(time - Clock.currStdTime()); 
    }

    int opCmp(Delayed other) {
        if (other == this) // compare zero if same object
            return 0;
        ScheduledFutureTask!V x = cast(ScheduledFutureTask!V)other;
        if (x !is null) {
            long diff = time - x.time;
            if (diff < 0)
                return -1;
            else if (diff > 0)
                return 1;
            else if (sequenceNumber < x.sequenceNumber)
                return -1;
            else
                return 1;
        }
        Duration diff = getDelay() - other.getDelay();
        return (diff.isNegative) ? -1 : (diff > Duration.zero) ? 1 : 0;
    }

    /**
     * Returns {@code true} if this is a periodic (not a one-shot) action.
     *
     * @return {@code true} if periodic
     */
    bool isPeriodic() {
        return period != 0;
    }

    /**
     * Sets the next time to run for a periodic task.
     */
    private void setNextRunTime() {
        long p = period;
        if (p > 0)
            time += p;
        else
            time = poolExecutor.triggerTime(-p);
    }

    override bool cancel(bool mayInterruptIfRunning) {
        // The racy read of heapIndex below is benign:
        // if heapIndex < 0, then OOTA guarantees that we have surely
        // been removed; else we recheck under lock in remove()
        bool cancelled = super.cancel(mayInterruptIfRunning);
        if (cancelled && poolExecutor.removeOnCancel && heapIndex >= 0)
            poolExecutor.remove(this);
        return cancelled;
    }

    /**
     * Overrides FutureTask version so as to reset/requeue if periodic.
     */
    override void run() {
        if (!poolExecutor.canRunInCurrentRunState(this))
            cancel(false);
        else if (!isPeriodic())
            super.run();
        else if (super.runAndReset()) {
            setNextRunTime();
            poolExecutor.reExecutePeriodic(outerTask);
        }
    }

    // alias from FutureTask
    // alias isCancelled = FutureTask!V.isCancelled;
    // alias isDone = FutureTask!V.isDone;
    alias get = FutureTask!V.get;
    
    override bool isCancelled() {
        return super.isCancelled();
    }

    override bool isDone() {
        return super.isDone();
    }

    override V get() {
        return super.get();
    }

    override V get(Duration timeout) {
        return super.get(timeout);
    }
}


/**
 * Specialized delay queue. To mesh with TPE declarations, this
 * class must be declared as a BlockingQueue!(Runnable) even though
 * it can only hold RunnableScheduledFutures.
 */
class DelayedWorkQueue : AbstractQueue!(Runnable), BlockingQueue!(Runnable) {

    /*
     * A DelayedWorkQueue is based on a heap-based data structure
     * like those in DelayQueue and PriorityQueue, except that
     * every ScheduledFutureTask also records its index into the
     * heap array. This eliminates the need to find a task upon
     * cancellation, greatly speeding up removal (down from O(n)
     * to O(log n)), and reducing garbage retention that would
     * otherwise occur by waiting for the element to rise to top
     * before clearing. But because the queue may also hold
     * RunnableScheduledFutures that are not ScheduledFutureTasks,
     * we are not guaranteed to have such indices available, in
     * which case we fall back to linear search. (We expect that
     * most tasks will not be decorated, and that the faster cases
     * will be much more common.)
     *
     * All heap operations must record index changes -- mainly
     * within siftUp and siftDown. Upon removal, a task's
     * heapIndex is set to -1. Note that ScheduledFutureTasks can
     * appear at most once in the queue (this need not be true for
     * other kinds of tasks or work queues), so are uniquely
     * identified by heapIndex.
     */

    private enum int INITIAL_CAPACITY = 16;
    private IRunnableScheduledFuture[] queue;
    private ReentrantLock lock;
    private int _size;

    /**
     * Thread designated to wait for the task at the head of the
     * queue.  This variant of the Leader-Follower pattern
     * (http://www.cs.wustl.edu/~schmidt/POSA/POSA2/) serves to
     * minimize unnecessary timed waiting.  When a thread becomes
     * the leader, it waits only for the next delay to elapse, but
     * other threads await indefinitely.  The leader thread must
     * signal some other thread before returning from take() or
     * poll(...), unless some other thread becomes leader in the
     * interim.  Whenever the head of the queue is replaced with a
     * task with an earlier expiration time, the leader field is
     * invalidated by being reset to null, and some waiting
     * thread, but not necessarily the current leader, is
     * signalled.  So waiting threads must be prepared to acquire
     * and lose leadership while waiting.
     */
    private ThreadEx leader;

    /**
     * Condition signalled when a newer task becomes available at the
     * head of the queue or a new thread may need to become leader.
     */
    private Condition available;

    private void initializeMembers() {
        lock = new ReentrantLock();
        available = new Condition(lock);
        queue = new IRunnableScheduledFuture[INITIAL_CAPACITY];
    }

    /**
     * Sets f's heapIndex if it is a ScheduledFutureTask.
     */
    private static void setIndex(IRunnableScheduledFuture f, int idx) {
        IScheduledFutureTask t = cast(IScheduledFutureTask)f;
        if (t !is null)
            t.heapIndex = idx;
    }

    /**
     * Sifts element added at bottom up to its heap-ordered spot.
     * Call only when holding lock.
     */
    private void siftUp(int k, IRunnableScheduledFuture key) {
        while (k > 0) {
            int parent = (k - 1) >>> 1;
            IRunnableScheduledFuture e = queue[parent];
            if (key >= e)
                break;
            queue[k] = e;
            setIndex(e, k);
            k = parent;
        }
        queue[k] = key;
        setIndex(key, k);
    }

    /**
     * Sifts element added at top down to its heap-ordered spot.
     * Call only when holding lock.
     */
    private void siftDown(int k, IRunnableScheduledFuture key) {
        int half = size >>> 1;
        while (k < half) {
            int child = (k << 1) + 1;
            IRunnableScheduledFuture c = queue[child];
            int right = child + 1;
            if (right < size && c.opCmp(queue[right]) > 0)
                c = queue[child = right];
            if (key.opCmp(c) <= 0)
                break;
            queue[k] = c;
            setIndex(c, k);
            k = child;
        }
        queue[k] = key;
        setIndex(key, k);
    }

    /**
     * Resizes the heap array.  Call only when holding lock.
     */
    private void grow() {
        size_t oldCapacity = queue.length;
        size_t newCapacity = oldCapacity + (oldCapacity >> 1); // grow 50%
        if (newCapacity < 0) // overflow
            newCapacity = int.max;
        queue.length = newCapacity;
    }

    /**
     * Finds index of given object, or -1 if absent.
     */
    private int indexOf(Runnable x) {
        if (x !is null) {
            IScheduledFutureTask sf = cast(IScheduledFutureTask) x;
            if (sf !is null) {
                int i = sf.heapIndex;
                // Sanity check; x could conceivably be a
                // ScheduledFutureTask from some other pool.
                if (i >= 0 && i < size && queue[i] == x)
                    return i;
            } else {
                for (int i = 0; i < size; i++) {
                    // if (x.opEquals(cast(Object)queue[i]))
                    if(x is queue[i])
                        return i;
                }
            }
        }
        return -1;
    }

    override bool contains(Runnable x) {
        ReentrantLock lock = this.lock;
        lock.lock();
        try {
            return indexOf(x) != -1;
        } finally {
            lock.unlock();
        }
    }

    override bool remove(Runnable x) {
        ReentrantLock lock = this.lock;
        lock.lock();
        try {
            int i = indexOf(x);
            if (i < 0)
                return false;

            setIndex(queue[i], -1);
            int s = --_size;
            IRunnableScheduledFuture replacement = queue[s];
            queue[s] = null;
            if (s != i) {
                siftDown(i, replacement);
                if (queue[i] == replacement)
                    siftUp(i, replacement);
            }
            return true;
        } finally {
            lock.unlock();
        }
    }

    override int size() const {
        return _size;
        // ReentrantLock lock = this.lock;
        // lock.lock();
        // try {
        //     return size;
        // } finally {
        //     lock.unlock();
        // }
    }

    override bool isEmpty() {
        return size() == 0;
    }

    int remainingCapacity() {
        return int.max;
    }

    IRunnableScheduledFuture peek() {
        ReentrantLock lock = this.lock;
        lock.lock();
        try {
            return queue[0];
        } finally {
            lock.unlock();
        }
    }

    bool offer(Runnable x) {
        if (x is null)
            throw new NullPointerException();
        IRunnableScheduledFuture e = cast(IRunnableScheduledFuture)x;
        ReentrantLock lock = this.lock;
        lock.lock();
        try {
            int i = _size;
            if (i >= queue.length)
                grow();
            _size = i + 1;
            if (i == 0) {
                queue[0] = e;
                setIndex(e, 0);
            } else {
                siftUp(i, e);
            }
            if (queue[0] == e) {
                leader = null;
                available.notify();
            }
        } finally {
            lock.unlock();
        }
        return true;
    }

    override void put(Runnable e) {
        offer(e);
    }

    override bool add(Runnable e) {
        return offer(e);
    }

    bool offer(Runnable e, Duration timeout) {
        return offer(e);
    }

    /**
     * Performs common bookkeeping for poll and take: Replaces
     * first element with last and sifts it down.  Call only when
     * holding lock.
     * @param f the task to remove and return
     */
    private IRunnableScheduledFuture finishPoll(IRunnableScheduledFuture f) {
        int s = --_size;
        IRunnableScheduledFuture x = queue[s];
        queue[s] = null;
        if (s != 0)
            siftDown(0, x);
        setIndex(f, -1);
        return f;
    }

    IRunnableScheduledFuture poll() {
        ReentrantLock lock = this.lock;
        lock.lock();
        try {
            IRunnableScheduledFuture first = queue[0];
            return (first is null || first.getDelay() > Duration.zero)
                ? null
                : finishPoll(first);
        } finally {
            lock.unlock();
        }
    }

    IRunnableScheduledFuture take() {
        ReentrantLock lock = this.lock;
        // lock.lockInterruptibly();
        lock.lock();
        try {
            for (;;) {
                IRunnableScheduledFuture first = queue[0];
                if (first is null)
                    available.wait();
                else {
                    Duration delay = first.getDelay();
                    if (delay <= Duration.zero)
                        return finishPoll(first);
                    first = null; // don't retain ref while waiting
                    if (leader !is null)
                        available.wait();
                    else {
                        ThreadEx thisThread = ThreadEx.currentThread();
                        leader = thisThread;
                        try {
                            available.wait(delay);
                        } finally {
                            if (leader == thisThread)
                                leader = null;
                        }
                    }
                }
            }
        } finally {
            if (leader is null && queue[0] !is null)
                available.notify();
            lock.unlock();
        }
    }

    IRunnableScheduledFuture poll(Duration timeout) {
        // long nanos = total!(TimeUnit.HectoNanosecond)(timeout);
        Duration nanos = timeout;
        ReentrantLock lock = this.lock;
        // lock.lockInterruptibly();
        lock.lock();
        try {
            for (;;) {
                IRunnableScheduledFuture first = queue[0];
                if (first is null) {
                    if (nanos <= Duration.zero)
                        return null;
                    else
                        available.wait(nanos); // nanos = 
                } else {
                    Duration delay = first.getDelay();
                    if (delay <= Duration.zero)
                        return finishPoll(first);
                    if (nanos <= Duration.zero)
                        return null;
                    first = null; // don't retain ref while waiting
                    if (nanos < delay || leader !is null)
                        available.wait(nanos); // nanos = 
                    else {
                        ThreadEx thisThread = ThreadEx.currentThread();
                        leader = thisThread;
                        try {
                            available.wait(delay);
                            nanos -= delay;
                            // long timeLeft = available.wait(delay);
                            // nanos -= delay - timeLeft;
                        } finally {
                            if (leader == thisThread)
                                leader = null;
                        }
                    }
                }
            }
        } finally {
            if (leader is null && queue[0] !is null)
                available.notify();
            lock.unlock();
        }
    }

    override void clear() {
        ReentrantLock lock = this.lock;
        lock.lock();
        try {
            for (int i = 0; i < size; i++) {
                IRunnableScheduledFuture t = queue[i];
                if (t !is null) {
                    queue[i] = null;
                    setIndex(t, -1);
                }
            }
            _size = 0;
        } finally {
            lock.unlock();
        }
    }

    int drainTo(Collection!(Runnable) c) {
        return drainTo(c, int.max);
    }

    int drainTo(Collection!(Runnable) c, int maxElements) {
        // Objects.requireNonNull(c);

        if (c == this)
            throw new IllegalArgumentException();
        if (maxElements <= 0)
            return 0;
        ReentrantLock lock = this.lock;
        lock.lock();
        try {
            int n = 0;
            for (IRunnableScheduledFuture first;
                 n < maxElements
                     && (first = queue[0]) !is null
                     && first.getDelay() <= Duration.zero;) {
                c.add(first);   // In this order, in case add() throws.
                finishPoll(first);
                ++n;
            }
            return n;
        } finally {
            lock.unlock();
        }
    }

    // Object[] toArray() {
    //     ReentrantLock lock = this.lock;
    //     lock.lock();
    //     try {
    //         return Arrays.copyOf(queue, size, Object[].class);
    //     } finally {
    //         lock.unlock();
    //     }
    // }


    // T[] toArray() {
    //     ReentrantLock lock = this.lock;
    //     lock.lock();
    //     try {
    //         if (a.length < size)
    //             return  (T[]) Arrays.copyOf(queue, size, a.getClass());
    //         System.arraycopy(queue, 0, a, 0, size);
    //         if (a.length > size)
    //             a[size] = null;
    //         return a;
    //     } finally {
    //         lock.unlock();
    //     }
    // }

    // Iterator!(Runnable) iterator() {
    //     ReentrantLock lock = this.lock;
    //     lock.lock();
    //     try {
    //         return new Itr(Arrays.copyOf(queue, size));
    //     } finally {
    //         lock.unlock();
    //     }
    // }

    /**
     * Snapshot iterator that works off copy of underlying q array.
     */
    // private class Itr : Iterator!(Runnable) {
    //     final IRunnableScheduledFuture[] array;
    //     int cursor;        // index of next element to return; initially 0
    //     int lastRet = -1;  // index of last element returned; -1 if no such

    //     this(IRunnableScheduledFuture[] array) {
    //         this.array = array;
    //     }

    //     bool hasNext() {
    //         return cursor < array.length;
    //     }

    //     Runnable next() {
    //         if (cursor >= array.length)
    //             throw new NoSuchElementException();
    //         return array[lastRet = cursor++];
    //     }

    //     void remove() {
    //         if (lastRet < 0)
    //             throw new IllegalStateException();
    //         DelayedWorkQueue.this.remove(array[lastRet]);
    //         lastRet = -1;
    //     }
    // }

    override bool opEquals(IObject o) {
        return opEquals(cast(Object) o);
    }

    override bool opEquals(Object o) {
        return super.opEquals(o);
    }
    
    override string toString() {
        return super.toString();
    }

    override size_t toHash() @trusted nothrow {
        return super.toHash();
    }
}