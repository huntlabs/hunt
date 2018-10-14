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

import hunt.concurrent.AtomicHelper;
import hunt.concurrent.ExecutorService;
import hunt.concurrent.LinkedBlockingQueue;
import hunt.concurrent.ThreadFactory;
import hunt.concurrent.ThreadPoolExecutor;

import hunt.datetime;
import hunt.util.common;
import hunt.util.exception;
import hunt.util.thread;

import core.thread;
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
// import hunt.concurrent.AtomicHelper.AtomicInteger;
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
        return new ThreadPoolExecutor(nThreads, nThreads,
                                      0L, TimeUnit.MILLISECONDS,
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
        return new DefaultThreadFactory();
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
    static Callable!(T) callable(T)(Runnable task, T result) {
        if (task is null)
            throw new NullPointerException();
        return new RunnableAdapter!(T)(task, result);
    }

    // /**
    //  * Returns a {@link Callable} object that, when
    //  * called, runs the given task and returns {@code null}.
    //  * @param task the task to run
    //  * @return a callable object
    //  * @throws NullPointerException if task null
    //  */
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



    /** Cannot instantiate. */
    private this() {}
}

  // // Non-classes supporting the methods

/**
 * A callable that runs given task and returns given result.
 */
private final class RunnableAdapter(T) : Callable!(T) {
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
    string toString() {
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

/**
 * The default thread factory.
 */
private class DefaultThreadFactory : ThreadFactory {
    private __gshared int poolNumber = 1;
    private ThreadGroupEx group;
    private shared(int) threadNumber = 1;
    private string namePrefix;

    this() {
        // SecurityManager s = System.getSecurityManager();
        // group = (s !is null) ? s.getThreadGroup() :
        //                       Thread.getThis().getThreadGroup();
        int n = AtomicHelper.getAndIncrement(poolNumber);
        namePrefix = "pool-" ~ t.to!string() ~ "-thread-";
    }

    
    Thread newThread(Action dg ) {
        int n = AtomicHelper.getAndIncrement(threadNumber);

        Thread t = new Thread(dg);
        t.name = namePrefix ~ n.to!string();
        t.isDaemon = false;
        t.priority = Thread.PRIORITY_DEFAULT;

        return t;
    }
}

// /**
//  * Thread factory capturing access control context and class loader.
//  */
// private class PrivilegedThreadFactory extends DefaultThreadFactory {
//     AccessControlContext acc;
//     ClassLoader ccl;

//     PrivilegedThreadFactory() {
//         super();
//         SecurityManager sm = System.getSecurityManager();
//         if (sm !is null) {
//             // Calls to getContextClassLoader from this class
//             // never trigger a security check, but we check
//             // whether our callers have this permission anyways.
//             sm.checkPermission(SecurityConstants.GET_CLASSLOADER_PERMISSION);

//             // Fail fast
//             sm.checkPermission(new RuntimePermission("setContextClassLoader"));
//         }
//         this.acc = AccessController.getContext();
//         this.ccl = Thread.getThis().getContextClassLoader();
//     }

//     Thread newThread(Runnable r) {
//         return super.newThread(new Runnable() {
//             void run() {
//                 AccessController.doPrivileged(new PrivilegedAction<>() {
//                     Void run() {
//                         Thread.getThis().setContextClassLoader(ccl);
//                         r.run();
//                         return null;
//                     }
//                 }, acc);
//             }
//         });
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