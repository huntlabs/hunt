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

module hunt.concurrency.ScheduledExecutorService;

import hunt.concurrency.ExecutorService;
import hunt.concurrency.Delayed;

import hunt.util.Common;

import core.time;

/**
 * An {@link ExecutorService} that can schedule commands to run after a given
 * delay, or to execute periodically.
 *
 * <p>The {@code schedule} methods create tasks with various delays
 * and return a task object that can be used to cancel or check
 * execution. The {@code scheduleAtFixedRate} and
 * {@code scheduleWithFixedDelay} methods create and execute tasks
 * that run periodically until cancelled.
 *
 * <p>Commands submitted using the {@link Executor#execute(Runnable)}
 * and {@link ExecutorService} {@code submit} methods are scheduled
 * with a requested delay of zero. Zero and negative delays (but not
 * periods) are also allowed in {@code schedule} methods, and are
 * treated as requests for immediate execution.
 *
 * <p>All {@code schedule} methods accept <em>relative</em> delays and
 * periods as arguments, not absolute times or dates. It is a simple
 * matter to transform an absolute time represented as a {@link
 * java.util.Date} to the required form. For example, to schedule at
 * a certain future {@code date}, you can use: {@code schedule(task,
 * date.getTime() - System.currentTimeMillis(),
 * TimeUnit.MILLISECONDS)}. Beware however that expiration of a
 * relative delay need not coincide with the current {@code Date} at
 * which the task is enabled due to network time synchronization
 * protocols, clock drift, or other factors.
 *
 * <p>The {@link Executors} class provides convenient factory methods for
 * the ScheduledExecutorService implementations provided in this package.
 *
 * <h3>Usage Example</h3>
 *
 * Here is a class with a method that sets up a ScheduledExecutorService
 * to beep every ten seconds for an hour:
 *
 * <pre> {@code
 * import static hunt.concurrency.TimeUnit.*;
 * class BeeperControl {
 *   private final ScheduledExecutorService scheduler =
 *     Executors.newScheduledThreadPool(1);
 *
 *   public void beepForAnHour() {
 *     Runnable beeper = () -> System.out.println("beep");
 *     ScheduledFuture<?> beeperHandle =
 *       scheduler.scheduleAtFixedRate(beeper, 10, 10, SECONDS);
 *     Runnable canceller = () -> beeperHandle.cancel(false);
 *     scheduler.schedule(canceller, 1, HOURS);
 *   }
 * }}</pre>
 *
 * @author Doug Lea
 */
interface ScheduledExecutorService : ExecutorService {

    /**
     * Submits a one-shot task that becomes enabled after the given delay.
     *
     * @param command the task to execute
     * @param delay the time from now to delay execution
     * @param unit the time unit of the delay parameter
     * @return a ScheduledFuture representing pending completion of
     *         the task and whose {@code get()} method will return
     *         {@code null} upon completion
     * @throws RejectedExecutionException if the task cannot be
     *         scheduled for execution
     * @throws NullPointerException if command or unit is null
     */
    ScheduledFuture!void schedule(Runnable command, Duration delay);

    // /**
    //  * Submits a value-returning one-shot task that becomes enabled
    //  * after the given delay.
    //  *
    //  * @param callable the function to execute
    //  * @param delay the time from now to delay execution
    //  * @param unit the time unit of the delay parameter
    //  * @param (V) the type of the callable's result
    //  * @return a ScheduledFuture that can be used to extract result or cancel
    //  * @throws RejectedExecutionException if the task cannot be
    //  *         scheduled for execution
    //  * @throws NullPointerException if callable or unit is null
    //  */
    // !(V) ScheduledFuture!(V) schedule(Callable!(V) callable, Duration delay);

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
     * <li>The executor terminates, also resulting in task cancellation.
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
     * @param command the task to execute
     * @param initialDelay the time to delay first execution
     * @param period the period between successive executions
     * @param unit the time unit of the initialDelay and period parameters
     * @return a ScheduledFuture representing pending completion of
     *         the series of repeated tasks.  The future's {@link
     *         Future#get() get()} method will never return normally,
     *         and will throw an exception upon task cancellation or
     *         abnormal termination of a task execution.
     * @throws RejectedExecutionException if the task cannot be
     *         scheduled for execution
     * @throws NullPointerException if command or unit is null
     * @throws IllegalArgumentException if period less than or equal to zero
     */
    ScheduledFuture!void scheduleAtFixedRate(Runnable command,
                                                  Duration initialDelay,
                                                  Duration period);

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
     * <li>The executor terminates, also resulting in task cancellation.
     * <li>An execution of the task throws an exception.  In this case
     * calling {@link Future#get() get} on the returned future will throw
     * {@link ExecutionException}, holding the exception as its cause.
     * </ul>
     * Subsequent executions are suppressed.  Subsequent calls to
     * {@link Future#isDone isDone()} on the returned future will
     * return {@code true}.
     *
     * @param command the task to execute
     * @param initialDelay the time to delay first execution
     * @param delay the delay between the termination of one
     * execution and the commencement of the next
     * @param unit the time unit of the initialDelay and delay parameters
     * @return a ScheduledFuture representing pending completion of
     *         the series of repeated tasks.  The future's {@link
     *         Future#get() get()} method will never return normally,
     *         and will throw an exception upon task cancellation or
     *         abnormal termination of a task execution.
     * @throws RejectedExecutionException if the task cannot be
     *         scheduled for execution
     * @throws NullPointerException if command or unit is null
     * @throws IllegalArgumentException if delay less than or equal to zero
     */
    ScheduledFuture!void scheduleWithFixedDelay(Runnable command,
                                                     Duration initialDelay,
                                                     Duration delay);

}
