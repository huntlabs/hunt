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

module hunt.concurrent.Executors;

import hunt.concurrent.AbstractExecutorService;
import hunt.concurrent.AtomicHelper;
import hunt.concurrent.exception;
import hunt.concurrent.ExecutorService;
import hunt.concurrent.ForkJoinPool;
import hunt.concurrent.Future;
import hunt.concurrent.LinkedBlockingQueue;
import hunt.concurrent.ThreadFactory;
import hunt.concurrent.ThreadPoolExecutor;

import hunt.datetime;
import hunt.lang.common;
import hunt.lang.exception;
import hunt.util.thread;

import core.thread;
import core.time;
import std.conv;

// import static java.lang.ref.Reference.reachabilityFence;
// import java.security.AccessControlContext;
// import java.security.AccessControlException;
// import java.security.AccessController;
// import java.security.PrivilegedAction;
// import java.security.PrivilegedActionException;
// import java.security.PrivilegedExceptionAction;
// import hunt.container.Collection;
// import java.util.List;
// import sun.security.util.SecurityConstants;

/**
 * Factory and utility methods for {@link Executor}, {@link
 * ExecutorService}, {@link ScheduledExecutorService}, {@link
 * ThreadFactory}, and {@link Callable} classes defined in this
 * package. This class supports the following kinds of methods:
 *
 * <ul>
 *   <li>Methods that create and return an {@link ExecutorService}
 *       set up with commonly useful configuration settings.
 *   <li>Methods that create and return a {@link ScheduledExecutorService}
 *       set up with commonly useful configuration settings.
 *   <li>Methods that create and return a "wrapped" ExecutorService, that
 *       disables reconfiguration by making implementation-specific methods
 *       inaccessible.
 *   <li>Methods that create and return a {@link ThreadFactory}
 *       that sets newly created threads to a known state.
 *   <li>Methods that create and return a {@link Callable}
 *       out of other closure-like forms, so they can be used
 *       in execution methods requiring {@code Callable}.
 * </ul>
 *
 * @since 1.5
 * @author Doug Lea
 */
class Executors {

    /**
     * Creates a thread pool that reuses a fixed number of threads
     * operating off a shared unbounded queue.  At any point, at most
     * {@code nThreads} threads will be active processing tasks.
     * If additional tasks are submitted when all threads are active,
     * they will wait in the queue until a thread is available.
     * If any thread terminates due to a failure during execution
     * prior to shutdown, a new one will take its place if needed to
     * execute subsequent tasks.  The threads in the pool will exist
     * until it is explicitly {@link ExecutorService#shutdown shutdown}.
     *
     * @param nThreads the number of threads in the pool
     * @return the newly created thread pool
     * @throws IllegalArgumentException if {@code nThreads <= 0}
     */
    static ThreadPoolExecutor newFixedThreadPool(int nThreads) {
        return new ThreadPoolExecutor(nThreads, nThreads, dur!(TimeUnit.HectoNanosecond)(0) ,
                                      new LinkedBlockingQueue!(Runnable)());
    }

    // /**
    //  * Creates a thread pool that maintains enough threads to support
    //  * the given parallelism level, and may use multiple queues to
    //  * reduce contention. The parallelism level corresponds to the
    //  * maximum number of threads actively engaged in, or available to
    //  * engage in, task processing. The actual number of threads may
    //  * grow and shrink dynamically. A work-stealing pool makes no
    //  * guarantees about the order in which submitted tasks are
    //  * executed.
    //  *
    //  * @param parallelism the targeted parallelism level
    //  * @return the newly created thread pool
    //  * @throws IllegalArgumentException if {@code parallelism <= 0}
    //  * @since 1.8
    //  */
    // static ExecutorService newWorkStealingPool(int parallelism) {
    //     return new ForkJoinPool
    //         (parallelism,
    //          ForkJoinPool.defaultForkJoinWorkerThreadFactory,
    //          null, true);
    // }

    // /**
    //  * Creates a work-stealing thread pool using the number of
    //  * {@linkplain Runtime#availableProcessors available processors}
    //  * as its target parallelism level.
    //  *
    //  * @return the newly created thread pool
    //  * @see #newWorkStealingPool(int)
    //  * @since 1.8
    //  */
    // static ExecutorService newWorkStealingPool() {
    //     return new ForkJoinPool
    //         (Runtime.getRuntime().availableProcessors(),
    //          ForkJoinPool.defaultForkJoinWorkerThreadFactory,
    //          null, true);
    // }

    // /**
    //  * Creates a thread pool that reuses a fixed number of threads
    //  * operating off a shared unbounded queue, using the provided
    //  * ThreadFactory to create new threads when needed.  At any point,
    //  * at most {@code nThreads} threads will be active processing
    //  * tasks.  If additional tasks are submitted when all threads are
    //  * active, they will wait in the queue until a thread is
    //  * available.  If any thread terminates due to a failure during
    //  * execution prior to shutdown, a new one will take its place if
    //  * needed to execute subsequent tasks.  The threads in the pool will
    //  * exist until it is explicitly {@link ExecutorService#shutdown
    //  * shutdown}.
    //  *
    //  * @param nThreads the number of threads in the pool
    //  * @param threadFactory the factory to use when creating new threads
    //  * @return the newly created thread pool
    //  * @throws NullPointerException if threadFactory is null
    //  * @throws IllegalArgumentException if {@code nThreads <= 0}
    //  */
    // static ExecutorService newFixedThreadPool(int nThreads, ThreadFactory threadFactory) {
    //     return new ThreadPoolExecutor(nThreads, nThreads,
    //                                   0L, TimeUnit.MILLISECONDS,
    //                                   new LinkedBlockingQueue!(Runnable)(),
    //                                   threadFactory);
    // }

    // /**
    //  * Creates an Executor that uses a single worker thread operating
    //  * off an unbounded queue. (Note however that if this single
    //  * thread terminates due to a failure during execution prior to
    //  * shutdown, a new one will take its place if needed to execute
    //  * subsequent tasks.)  Tasks are guaranteed to execute
    //  * sequentially, and no more than one task will be active at any
    //  * given time. Unlike the otherwise equivalent
    //  * {@code newFixedThreadPool(1)} the returned executor is
    //  * guaranteed not to be reconfigurable to use additional threads.
    //  *
    //  * @return the newly created single-threaded Executor
    //  */
    // static ExecutorService newSingleThreadExecutor() {
    //     return new FinalizableDelegatedExecutorService
    //         (new ThreadPoolExecutor(1, 1,
    //                                 0L, TimeUnit.MILLISECONDS,
    //                                 new LinkedBlockingQueue!(Runnable)()));
    // }

    // /**
    //  * Creates an Executor that uses a single worker thread operating
    //  * off an unbounded queue, and uses the provided ThreadFactory to
    //  * create a new thread when needed. Unlike the otherwise
    //  * equivalent {@code newFixedThreadPool(1, threadFactory)} the
    //  * returned executor is guaranteed not to be reconfigurable to use
    //  * additional threads.
    //  *
    //  * @param threadFactory the factory to use when creating new threads
    //  * @return the newly created single-threaded Executor
    //  * @throws NullPointerException if threadFactory is null
    //  */
    // static ExecutorService newSingleThreadExecutor(ThreadFactory threadFactory) {
    //     return new FinalizableDelegatedExecutorService
    //         (new ThreadPoolExecutor(1, 1,
    //                                 0L, TimeUnit.MILLISECONDS,
    //                                 new LinkedBlockingQueue!(Runnable)(),
    //                                 threadFactory));
    // }

    // /**
    //  * Creates a thread pool that creates new threads as needed, but
    //  * will reuse previously constructed threads when they are
    //  * available.  These pools will typically improve the performance
    //  * of programs that execute many short-lived asynchronous tasks.
    //  * Calls to {@code execute} will reuse previously constructed
    //  * threads if available. If no existing thread is available, a new
    //  * thread will be created and added to the pool. Threads that have
    //  * not been used for sixty seconds are terminated and removed from
    //  * the cache. Thus, a pool that remains idle for long enough will
    //  * not consume any resources. Note that pools with similar
    //  * properties but different details (for example, timeout parameters)
    //  * may be created using {@link ThreadPoolExecutor} constructors.
    //  *
    //  * @return the newly created thread pool
    //  */
    // static ExecutorService newCachedThreadPool() {
    //     return new ThreadPoolExecutor(0, Integer.MAX_VALUE,
    //                                   60L, TimeUnit.SECONDS,
    //                                   new SynchronousQueue!(Runnable)());
    // }

    // /**
    //  * Creates a thread pool that creates new threads as needed, but
    //  * will reuse previously constructed threads when they are
    //  * available, and uses the provided
    //  * ThreadFactory to create new threads when needed.
    //  *
    //  * @param threadFactory the factory to use when creating new threads
    //  * @return the newly created thread pool
    //  * @throws NullPointerException if threadFactory is null
    //  */
    // static ExecutorService newCachedThreadPool(ThreadFactory threadFactory) {
    //     return new ThreadPoolExecutor(0, Integer.MAX_VALUE,
    //                                   60L, TimeUnit.SECONDS,
    //                                   new SynchronousQueue!(Runnable)(),
    //                                   threadFactory);
    // }

    // /**
    //  * Creates a single-threaded executor that can schedule commands
    //  * to run after a given delay, or to execute periodically.
    //  * (Note however that if this single
    //  * thread terminates due to a failure during execution prior to
    //  * shutdown, a new one will take its place if needed to execute
    //  * subsequent tasks.)  Tasks are guaranteed to execute
    //  * sequentially, and no more than one task will be active at any
    //  * given time. Unlike the otherwise equivalent
    //  * {@code newScheduledThreadPool(1)} the returned executor is
    //  * guaranteed not to be reconfigurable to use additional threads.
    //  *
    //  * @return the newly created scheduled executor
    //  */
    // static ScheduledExecutorService newSingleThreadScheduledExecutor() {
    //     return new DelegatedScheduledExecutorService
    //         (new ScheduledThreadPoolExecutor(1));
    // }

    // /**
    //  * Creates a single-threaded executor that can schedule commands
    //  * to run after a given delay, or to execute periodically.  (Note
    //  * however that if this single thread terminates due to a failure
    //  * during execution prior to shutdown, a new one will take its
    //  * place if needed to execute subsequent tasks.)  Tasks are
    //  * guaranteed to execute sequentially, and no more than one task
    //  * will be active at any given time. Unlike the otherwise
    //  * equivalent {@code newScheduledThreadPool(1, threadFactory)}
    //  * the returned executor is guaranteed not to be reconfigurable to
    //  * use additional threads.
    //  *
    //  * @param threadFactory the factory to use when creating new threads
    //  * @return the newly created scheduled executor
    //  * @throws NullPointerException if threadFactory is null
    //  */
    // static ScheduledExecutorService newSingleThreadScheduledExecutor(ThreadFactory threadFactory) {
    //     return new DelegatedScheduledExecutorService
    //         (new ScheduledThreadPoolExecutor(1, threadFactory));
    // }

    // /**
    //  * Creates a thread pool that can schedule commands to run after a
    //  * given delay, or to execute periodically.
    //  * @param corePoolSize the number of threads to keep in the pool,
    //  * even if they are idle
    //  * @return the newly created scheduled thread pool
    //  * @throws IllegalArgumentException if {@code corePoolSize < 0}
    //  */
    // static ScheduledExecutorService newScheduledThreadPool(int corePoolSize) {
    //     return new ScheduledThreadPoolExecutor(corePoolSize);
    // }

    // /**
    //  * Creates a thread pool that can schedule commands to run after a
    //  * given delay, or to execute periodically.
    //  * @param corePoolSize the number of threads to keep in the pool,
    //  * even if they are idle
    //  * @param threadFactory the factory to use when the executor
    //  * creates a new thread
    //  * @return the newly created scheduled thread pool
    //  * @throws IllegalArgumentException if {@code corePoolSize < 0}
    //  * @throws NullPointerException if threadFactory is null
    //  */
    // static ScheduledExecutorService newScheduledThreadPool(
    //         int corePoolSize, ThreadFactory threadFactory) {
    //     return new ScheduledThreadPoolExecutor(corePoolSize, threadFactory);
    // }

    // /**
    //  * Returns an object that delegates all defined {@link
    //  * ExecutorService} methods to the given executor, but not any
    //  * other methods that might otherwise be accessible using
    //  * casts. This provides a way to safely "freeze" configuration and
    //  * disallow tuning of a given concrete implementation.
    //  * @param executor the underlying implementation
    //  * @return an {@code ExecutorService} instance
    //  * @throws NullPointerException if executor null
    //  */
    // static ExecutorService unconfigurableExecutorService(ExecutorService executor) {
    //     if (executor is null)
    //         throw new NullPointerException();
    //     return new DelegatedExecutorService(executor);
    // }

    // /**
    //  * Returns an object that delegates all defined {@link
    //  * ScheduledExecutorService} methods to the given executor, but
    //  * not any other methods that might otherwise be accessible using
    //  * casts. This provides a way to safely "freeze" configuration and
    //  * disallow tuning of a given concrete implementation.
    //  * @param executor the underlying implementation
    //  * @return a {@code ScheduledExecutorService} instance
    //  * @throws NullPointerException if executor null
    //  */
    // static ScheduledExecutorService unconfigurableScheduledExecutorService(ScheduledExecutorService executor) {
    //     if (executor is null)
    //         throw new NullPointerException();
    //     return new DelegatedScheduledExecutorService(executor);
    // }

    /**
     * Returns a default thread factory used to create new threads.
     * This factory creates all new threads used by an Executor in the
     * same {@link ThreadGroupEx}. If there is a {@link
     * java.lang.SecurityManager}, it uses the group of {@link
     * System#getSecurityManager}, else the group of the thread
     * invoking this {@code defaultThreadFactory} method. Each new
     * thread is created as a non-daemon thread with priority set to
     * the smaller of {@code Thread.PRIORITY_DEFAULT} and the maximum
     * priority permitted in the thread group.  New threads have names
     * accessible via {@link Thread#getName} of
     * <em>pool-N-thread-M</em>, where <em>N</em> is the sequence
     * number of this factory, and <em>M</em> is the sequence number
     * of the thread created by this factory.
     * @return a thread factory
     */
    static ThreadFactory defaultThreadFactory() {
        return ThreadFactory.defaultThreadFactory();
    }

    // /**
    //  * Returns a thread factory used to create new threads that
    //  * have the same permissions as the current thread.
    //  * This factory creates threads with the same settings as {@link
    //  * Executors#defaultThreadFactory}, additionally setting the
    //  * AccessControlContext and contextClassLoader of new threads to
    //  * be the same as the thread invoking this
    //  * {@code privilegedThreadFactory} method.  A new
    //  * {@code privilegedThreadFactory} can be created within an
    //  * {@link AccessController#doPrivileged AccessController.doPrivileged}
    //  * action setting the current thread's access control context to
    //  * create threads with the selected permission settings holding
    //  * within that action.
    //  *
    //  * <p>Note that while tasks running within such threads will have
    //  * the same access control and class loader settings as the
    //  * current thread, they need not have the same {@link
    //  * java.lang.ThreadLocal} or {@link
    //  * java.lang.InheritableThreadLocal} values. If necessary,
    //  * particular values of thread locals can be set or reset before
    //  * any task runs in {@link ThreadPoolExecutor} subclasses using
    //  * {@link ThreadPoolExecutor#beforeExecute(Thread, Runnable)}.
    //  * Also, if it is necessary to initialize worker threads to have
    //  * the same InheritableThreadLocal settings as some other
    //  * designated thread, you can create a custom ThreadFactory in
    //  * which that thread waits for and services requests to create
    //  * others that will inherit its values.
    //  *
    //  * @return a thread factory
    //  * @throws AccessControlException if the current access control
    //  * context does not have permission to both get and set context
    //  * class loader
    //  */
    // static ThreadFactory privilegedThreadFactory() {
    //     return new PrivilegedThreadFactory();
    // }

    /**
     * Returns a {@link Callable} object that, when
     * called, runs the given task and returns the given result.  This
     * can be useful when applying methods requiring a
     * {@code Callable} to an otherwise resultless action.
     * @param task the task to run
     * @param result the result to return
     * @param (T) the type of the result
     * @return a callable object
     * @throws NullPointerException if task null
     */
    static Callable!(void) callable(Runnable task) {
        if (task is null)
            throw new NullPointerException();
        return new RunnableAdapter!(void)(task);
    }

    static Callable!(T) callable(T)(Runnable task, T result) if(!is(T == void)) {
        if (task is null)
            throw new NullPointerException();
        return new RunnableAdapter!(T)(task, result);
    }

    /**
     * Returns a {@link Callable} object that, when
     * called, runs the given task and returns {@code null}.
     * @param task the task to run
     * @return a callable object
     * @throws NullPointerException if task null
     */
    // static Callable<Object> callable(Runnable task) {
    //     if (task is null)
    //         throw new NullPointerException();
    //     return new RunnableAdapter<Object>(task, null);
    // }

    // /**
    //  * Returns a {@link Callable} object that, when
    //  * called, runs the given privileged action and returns its result.
    //  * @param action the privileged action to run
    //  * @return a callable object
    //  * @throws NullPointerException if action null
    //  */
    // static Callable<Object> callable(PrivilegedAction<?> action) {
    //     if (action is null)
    //         throw new NullPointerException();
    //     return new Callable<Object>() {
    //         Object call() { return action.run(); }};
    // }

    // /**
    //  * Returns a {@link Callable} object that, when
    //  * called, runs the given privileged exception action and returns
    //  * its result.
    //  * @param action the privileged exception action to run
    //  * @return a callable object
    //  * @throws NullPointerException if action null
    //  */
    // static Callable<Object> callable(PrivilegedExceptionAction<?> action) {
    //     if (action is null)
    //         throw new NullPointerException();
    //     return new Callable<Object>() {
    //         Object call() throws Exception { return action.run(); }};
    // }

    // /**
    //  * Returns a {@link Callable} object that will, when called,
    //  * execute the given {@code callable} under the current access
    //  * control context. This method should normally be invoked within
    //  * an {@link AccessController#doPrivileged AccessController.doPrivileged}
    //  * action to create callables that will, if possible, execute
    //  * under the selected permission settings holding within that
    //  * action; or if not possible, throw an associated {@link
    //  * AccessControlException}.
    //  * @param callable the underlying task
    //  * @param (T) the type of the callable's result
    //  * @return a callable object
    //  * @throws NullPointerException if callable null
    //  */
    // static !(T) Callable!(T) privilegedCallable(Callable!(T) callable) {
    //     if (callable is null)
    //         throw new NullPointerException();
    //     return new PrivilegedCallable!(T)(callable);
    // }

    // /**
    //  * Returns a {@link Callable} object that will, when called,
    //  * execute the given {@code callable} under the current access
    //  * control context, with the current context class loader as the
    //  * context class loader. This method should normally be invoked
    //  * within an
    //  * {@link AccessController#doPrivileged AccessController.doPrivileged}
    //  * action to create callables that will, if possible, execute
    //  * under the selected permission settings holding within that
    //  * action; or if not possible, throw an associated {@link
    //  * AccessControlException}.
    //  *
    //  * @param callable the underlying task
    //  * @param (T) the type of the callable's result
    //  * @return a callable object
    //  * @throws NullPointerException if callable null
    //  * @throws AccessControlException if the current access control
    //  * context does not have permission to both set and get context
    //  * class loader
    //  */
    // static !(T) Callable!(T) privilegedCallableUsingCurrentClassLoader(Callable!(T) callable) {
    //     if (callable is null)
    //         throw new NullPointerException();
    //     return new PrivilegedCallableUsingCurrentClassLoader!(T)(callable);
    // }


    // Methods for ExecutorService

    /**
     * Submits a Runnable task for execution and returns a Future
     * representing that task. The Future's {@code get} method will
     * return {@code null} upon <em>successful</em> completion.
     *
     * @param task the task to submit
     * @return a Future representing pending completion of the task
     * @throws RejectedExecutionException if the task cannot be
     *         scheduled for execution
     * @throws NullPointerException if the task is null
     */
    static Future!(void) submit(ExecutorService es, Runnable task) {

        AbstractExecutorService aes = cast(AbstractExecutorService)es;
        if(aes is null) 
            throw new RejectedExecutionException("ExecutorService is null");
        else
            return aes.submit(task);

        // TypeInfo typeInfo = typeid(cast(Object)es);
        // if(typeInfo == typeid(ThreadPoolExecutor)) {
        //     AbstractExecutorService aes = cast(AbstractExecutorService)es;
        //     return aes.submit(task);
        // } else {
        //     implementationMissing(false);
        // }
    }

    /**
     * Submits a Runnable task for execution and returns a Future
     * representing that task. The Future's {@code get} method will
     * return the given result upon successful completion.
     *
     * @param task the task to submit
     * @param result the result to return
     * @param (T) the type of the result
     * @return a Future representing pending completion of the task
     * @throws RejectedExecutionException if the task cannot be
     *         scheduled for execution
     * @throws NullPointerException if the task is null
     */
    static Future!(T) submit(T)(ExecutorService es, Runnable task, T result) {
        AbstractExecutorService aes = cast(AbstractExecutorService)es;
        if(aes is null) 
            throw new RejectedExecutionException("ExecutorService is null");
        else
            return aes.submit!T(task, result);
                    
        // TypeInfo typeInfo = typeid(cast(Object)es);
        // if(typeInfo == typeid(ThreadPoolExecutor)) {
        //     AbstractExecutorService aes = cast(AbstractExecutorService)es;
        //     if(aes is null) 
        //         throw new RejectedExecutionException("ExecutorService is null");
        //     else
        //         return aes.submit!T(task, result);
        // } else {
        //     implementationMissing(false);
        // }
    }

    /**
     * Submits a value-returning task for execution and returns a
     * Future representing the pending results of the task. The
     * Future's {@code get} method will return the task's result upon
     * successful completion.
     *
     * <p>
     * If you would like to immediately block waiting
     * for a task, you can use constructions of the form
     * {@code result = exec.submit(aCallable).get();}
     *
     * <p>Note: The {@link Executors} class includes a set of methods
     * that can convert some other common closure-like objects,
     * for example, {@link java.security.PrivilegedAction} to
     * {@link Callable} form so they can be submitted.
     *
     * @param task the task to submit
     * @param (T) the type of the task's result
     * @return a Future representing pending completion of the task
     * @throws RejectedExecutionException if the task cannot be
     *         scheduled for execution
     * @throws NullPointerException if the task is null
     */
    static Future!(T) submit(T)(ExecutorService es, Callable!(T) task) {
        AbstractExecutorService aes = cast(AbstractExecutorService)es;
        if(aes is null) 
            throw new RejectedExecutionException("ExecutorService is null");
        else
            return aes.submit!(T)(task);
            
        // TypeInfo typeInfo = typeid(cast(Object)es);
        // if(typeInfo == typeid(ThreadPoolExecutor)) {
        //     AbstractExecutorService aes = cast(AbstractExecutorService)es;
        //     if(aes is null) 
        //         throw new RejectedExecutionException("ExecutorService is null");
        //     else
        //         return aes.submit!(T)(task);
        // } else {
        //     implementationMissing(false);
        // }
    }

    /**
     * Executes the given tasks, returning a list of Futures holding
     * their status and results when all complete.
     * {@link Future#isDone} is {@code true} for each
     * element of the returned list.
     * Note that a <em>completed</em> task could have
     * terminated either normally or by throwing an exception.
     * The results of this method are undefined if the given
     * collection is modified while this operation is in progress.
     *
     * @param tasks the collection of tasks
     * @param (T) the type of the values returned from the tasks
     * @return a list of Futures representing the tasks, in the same
     *         sequential order as produced by the iterator for the
     *         given task list, each of which has completed
     * @throws InterruptedException if interrupted while waiting, in
     *         which case unfinished tasks are cancelled
     * @throws NullPointerException if tasks or any of its elements are {@code null}
     * @throws RejectedExecutionException if any task cannot be
     *         scheduled for execution
     */
    static List!(Future!(T)) invokeAll(T)(ExecutorService es, Collection!(Callable!(T)) tasks) {

        AbstractExecutorService aes = cast(AbstractExecutorService)es;
        if(aes is null) 
            throw new RejectedExecutionException("ExecutorService is null");
        else {
            aes.invokeAll!(T)(tasks);
        }

    }

    /**
     * Executes the given tasks, returning a list of Futures holding
     * their status and results
     * when all complete or the timeout expires, whichever happens first.
     * {@link Future#isDone} is {@code true} for each
     * element of the returned list.
     * Upon return, tasks that have not completed are cancelled.
     * Note that a <em>completed</em> task could have
     * terminated either normally or by throwing an exception.
     * The results of this method are undefined if the given
     * collection is modified while this operation is in progress.
     *
     * @param tasks the collection of tasks
     * @param timeout the maximum time to wait
     * @param unit the time unit of the timeout argument
     * @param (T) the type of the values returned from the tasks
     * @return a list of Futures representing the tasks, in the same
     *         sequential order as produced by the iterator for the
     *         given task list. If the operation did not time out,
     *         each task will have completed. If it did time out, some
     *         of these tasks will not have completed.
     * @throws InterruptedException if interrupted while waiting, in
     *         which case unfinished tasks are cancelled
     * @throws NullPointerException if tasks, any of its elements, or
     *         unit are {@code null}
     * @throws RejectedExecutionException if any task cannot be scheduled
     *         for execution
     */
    static List!(Future!(T)) invokeAll(T)(ExecutorService es, Collection!(Callable!(T)) tasks,
                                  Duration timeout) {
        AbstractExecutorService aes = cast(AbstractExecutorService)es;
        if(aes is null) 
            throw new RejectedExecutionException("ExecutorService is null");
        else {
            aes.invokeAll!(T)(tasks, timeout);
        }
    }

    /**
     * Executes the given tasks, returning the result
     * of one that has completed successfully (i.e., without throwing
     * an exception), if any do. Upon normal or exceptional return,
     * tasks that have not completed are cancelled.
     * The results of this method are undefined if the given
     * collection is modified while this operation is in progress.
     *
     * @param tasks the collection of tasks
     * @param (T) the type of the values returned from the tasks
     * @return the result returned by one of the tasks
     * @throws InterruptedException if interrupted while waiting
     * @throws NullPointerException if tasks or any element task
     *         subject to execution is {@code null}
     * @throws IllegalArgumentException if tasks is empty
     * @throws ExecutionException if no task successfully completes
     * @throws RejectedExecutionException if tasks cannot be scheduled
     *         for execution
     */
    static T invokeAny(T)(ExecutorService es, Collection!(Callable!(T)) tasks) {
        AbstractExecutorService aes = cast(AbstractExecutorService)es;
        if(aes is null) 
            throw new RejectedExecutionException("ExecutorService is null");
        else {
            aes.invokeAny!(T)(tasks);
        }
    }

    /**
     * Executes the given tasks, returning the result
     * of one that has completed successfully (i.e., without throwing
     * an exception), if any do before the given timeout elapses.
     * Upon normal or exceptional return, tasks that have not
     * completed are cancelled.
     * The results of this method are undefined if the given
     * collection is modified while this operation is in progress.
     *
     * @param tasks the collection of tasks
     * @param timeout the maximum time to wait
     * @param unit the time unit of the timeout argument
     * @param (T) the type of the values returned from the tasks
     * @return the result returned by one of the tasks
     * @throws InterruptedException if interrupted while waiting
     * @throws NullPointerException if tasks, or unit, or any element
     *         task subject to execution is {@code null}
     * @throws TimeoutException if the given timeout elapses before
     *         any task successfully completes
     * @throws ExecutionException if no task successfully completes
     * @throws RejectedExecutionException if tasks cannot be scheduled
     *         for execution
     */
    static T invokeAny(T)(ExecutorService es, Collection!(Callable!(T)) tasks,
                    Duration timeout)  {
        AbstractExecutorService aes = cast(AbstractExecutorService)es;
        if(aes is null) 
            throw new RejectedExecutionException("ExecutorService is null");
        else {
            aes.invokeAny!(T)(tasks, timeout);
        }
    }

    /** Cannot instantiate. */
    private this() {}
}

// Non-classes supporting the methods

/**
 * A callable that runs given task and returns given result.
 */
private final class RunnableAdapter(T) : Callable!(T) if(is(T == void)) {
    private Runnable task;
    this(Runnable task) {
        this.task = task;
    }

    T call() {
        task.run();
    }

    override string toString() {
        return super.toString() ~ "[Wrapped task = " ~ (cast(Object)task).toString() ~ "]";
    }
}

private final class RunnableAdapter(T) : Callable!(T) if(!is(T == void)) {
    private Runnable task;
    private T result;

    this(Runnable task, T result) {
        this.task = task;
        this.result = result;
    }

    T call() {
        task.run();
        return result;
    }

    override string toString() {
        return super.toString() ~ "[Wrapped task = " ~ (cast(Object)task).toString() ~ "]";
    }
}

// /**
//  * A callable that runs under established access control settings.
//  */
// private final class PrivilegedCallable!(T) : Callable!(T) {
//     Callable!(T) task;
//     AccessControlContext acc;

//     PrivilegedCallable(Callable!(T) task) {
//         this.task = task;
//         this.acc = AccessController.getContext();
//     }

//     T call() throws Exception {
//         try {
//             return AccessController.doPrivileged(
//                 new PrivilegedExceptionAction!(T)() {
//                     T run() throws Exception {
//                         return task.call();
//                     }
//                 }, acc);
//         } catch (PrivilegedActionException e) {
//             throw e.getException();
//         }
//     }

//     string toString() {
//         return super.toString() ~ "[Wrapped task = " ~ task ~ "]";
//     }
// }

// /**
//  * A callable that runs under established access control settings and
//  * current ClassLoader.
//  */
// private final class PrivilegedCallableUsingCurrentClassLoader(T)
//         : Callable!(T) {
//     Callable!(T) task;
//     AccessControlContext acc;
//     ClassLoader ccl;

//     this(Callable!(T) task) {
//         SecurityManager sm = System.getSecurityManager();
//         if (sm !is null) {
//             // Calls to getContextClassLoader from this class
//             // never trigger a security check, but we check
//             // whether our callers have this permission anyways.
//             sm.checkPermission(SecurityConstants.GET_CLASSLOADER_PERMISSION);

//             // Whether setContextClassLoader turns out to be necessary
//             // or not, we fail fast if permission is not available.
//             sm.checkPermission(new RuntimePermission("setContextClassLoader"));
//         }
//         this.task = task;
//         this.acc = AccessController.getContext();
//         this.ccl = Thread.getThis().getContextClassLoader();
//     }

//     T call() throws Exception {
//         try {
//             return AccessController.doPrivileged(
//                 new PrivilegedExceptionAction!(T)() {
//                     T run() throws Exception {
//                         Thread t = Thread.getThis();
//                         ClassLoader cl = t.getContextClassLoader();
//                         if (ccl == cl) {
//                             return task.call();
//                         } else {
//                             t.setContextClassLoader(ccl);
//                             try {
//                                 return task.call();
//                             } finally {
//                                 t.setContextClassLoader(cl);
//                             }
//                         }
//                     }
//                 }, acc);
//         } catch (PrivilegedActionException e) {
//             throw e.getException();
//         }
//     }

//     string toString() {
//         return super.toString() ~ "[Wrapped task = " ~ task ~ "]";
//     }
// }



// /**
//  * A wrapper class that exposes only the ExecutorService methods
//  * of an ExecutorService implementation.
//  */
// private class DelegatedExecutorService
//         implements ExecutorService {
//     private ExecutorService e;
//     DelegatedExecutorService(ExecutorService executor) { e = executor; }
//     void execute(Runnable command) {
//         try {
//             e.execute(command);
//         } finally { reachabilityFence(this); }
//     }
//     void shutdown() { e.shutdown(); }
//     List!(Runnable) shutdownNow() {
//         try {
//             return e.shutdownNow();
//         } finally { reachabilityFence(this); }
//     }
//     bool isShutdown() {
//         try {
//             return e.isShutdown();
//         } finally { reachabilityFence(this); }
//     }
//     bool isTerminated() {
//         try {
//             return e.isTerminated();
//         } finally { reachabilityFence(this); }
//     }
//     bool awaitTermination(Duration timeout)
//         throws InterruptedException {
//         try {
//             return e.awaitTermination(timeout, unit);
//         } finally { reachabilityFence(this); }
//     }
//     Future<?> submit(Runnable task) {
//         try {
//             return e.submit(task);
//         } finally { reachabilityFence(this); }
//     }
//     !(T) Future!(T) submit(Callable!(T) task) {
//         try {
//             return e.submit(task);
//         } finally { reachabilityFence(this); }
//     }
//     !(T) Future!(T) submit(Runnable task, T result) {
//         try {
//             return e.submit(task, result);
//         } finally { reachabilityFence(this); }
//     }
//     !(T) List<Future!(T)> invokeAll(Collection<Callable!(T)> tasks)
//         throws InterruptedException {
//         try {
//             return e.invokeAll(tasks);
//         } finally { reachabilityFence(this); }
//     }
//     !(T) List<Future!(T)> invokeAll(Collection<Callable!(T)> tasks,
//                                          Duration timeout)
//         throws InterruptedException {
//         try {
//             return e.invokeAll(tasks, timeout, unit);
//         } finally { reachabilityFence(this); }
//     }
//     !(T) T invokeAny(Collection<Callable!(T)> tasks)
//         throws InterruptedException, ExecutionException {
//         try {
//             return e.invokeAny(tasks);
//         } finally { reachabilityFence(this); }
//     }
//     !(T) T invokeAny(Collection<Callable!(T)> tasks,
//                            Duration timeout)
//         throws InterruptedException, ExecutionException, TimeoutException {
//         try {
//             return e.invokeAny(tasks, timeout, unit);
//         } finally { reachabilityFence(this); }
//     }
// }

// private class FinalizableDelegatedExecutorService
//         extends DelegatedExecutorService {
//     FinalizableDelegatedExecutorService(ExecutorService executor) {
//         super(executor);
//     }

//     protected void finalize() {
//         super.shutdown();
//     }
// }

// /**
//  * A wrapper class that exposes only the ScheduledExecutorService
//  * methods of a ScheduledExecutorService implementation.
//  */
// private class DelegatedScheduledExecutorService
//         extends DelegatedExecutorService
//         implements ScheduledExecutorService {
//     private ScheduledExecutorService e;
//     DelegatedScheduledExecutorService(ScheduledExecutorService executor) {
//         super(executor);
//         e = executor;
//     }
//     ScheduledFuture<?> schedule(Runnable command, long delay, TimeUnit unit) {
//         return e.schedule(command, delay, unit);
//     }
//     !(V) ScheduledFuture!(V) schedule(Callable!(V) callable, long delay, TimeUnit unit) {
//         return e.schedule(callable, delay, unit);
//     }
//     ScheduledFuture<?> scheduleAtFixedRate(Runnable command, long initialDelay, long period, TimeUnit unit) {
//         return e.scheduleAtFixedRate(command, initialDelay, period, unit);
//     }
//     ScheduledFuture<?> scheduleWithFixedDelay(Runnable command, long initialDelay, long delay, TimeUnit unit) {
//         return e.scheduleWithFixedDelay(command, initialDelay, delay, unit);
//     }
// }