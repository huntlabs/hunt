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

module hunt.concurrent.AbstractExecutorService;

import hunt.concurrent.Executor;
import hunt.concurrent.ExecutorService;
import hunt.concurrent.Future;
import hunt.concurrent.FutureTask;

import hunt.container.ArrayList;
import hunt.container.Collection;
import hunt.container.Iterator;
import hunt.container.List;
import hunt.datetime;
import hunt.lang.common;
import hunt.util.exception;

import std.datetime;

version(HUNT_DEBUG) import hunt.logging;

/**
 * Provides default implementations of {@link ExecutorService}
 * execution methods. This class implements the {@code submit},
 * {@code invokeAny} and {@code invokeAll} methods using a
 * {@link RunnableFuture} returned by {@code newTaskFor}, which defaults
 * to the {@link FutureTask} class provided in this package.  For example,
 * the implementation of {@code submit(Runnable)} creates an
 * associated {@code RunnableFuture} that is executed and
 * returned. Subclasses may override the {@code newTaskFor} methods
 * to return {@code RunnableFuture} implementations other than
 * {@code FutureTask}.
 *
 * <p><b>Extension example</b>. Here is a sketch of a class
 * that customizes {@link ThreadPoolExecutor} to use
 * a {@code CustomTask} class instead of the default {@code FutureTask}:
 * <pre> {@code
 * class CustomThreadPoolExecutor extends ThreadPoolExecutor {
 *
 *   static class CustomTask!(V) : RunnableFuture!(V) {...}
 *
 *   protected !(V) RunnableFuture!(V) newTaskFor(Callable!(V) c) {
 *       return new CustomTask!(V)(c);
 *   }
 *   protected !(V) RunnableFuture!(V) newTaskFor(Runnable r, V v) {
 *       return new CustomTask!(V)(r, v);
 *   }
 *   // ... add constructors, etc.
 * }}</pre>
 *
 * @since 1.5
 * @author Doug Lea
 */
abstract class AbstractExecutorService : ExecutorService {

    // /**
    //  * Returns a {@code RunnableFuture} for the given runnable and default
    //  * value.
    //  *
    //  * @param runnable the runnable task being wrapped
    //  * @param value the default value for the returned future
    //  * @param (T) the type of the given value
    //  * @return a {@code RunnableFuture} which, when run, will run the
    //  * underlying runnable and which, as a {@code Future}, will yield
    //  * the given value as its result and provide for cancellation of
    //  * the underlying task
    //  * @since 1.6
    //  */
    // protected RunnableFuture!(T) newTaskFor(T)(Runnable runnable, T value) {
    //     return new FutureTask!(T)(runnable, value);
    // }

    // /**
    //  * Returns a {@code RunnableFuture} for the given callable task.
    //  *
    //  * @param callable the callable task being wrapped
    //  * @param (T) the type of the callable's result
    //  * @return a {@code RunnableFuture} which, when run, will call the
    //  * underlying callable and which, as a {@code Future}, will yield
    //  * the callable's result as its result and provide for
    //  * cancellation of the underlying task
    //  * @since 1.6
    //  */
    // protected RunnableFuture!(T) newTaskFor(T)(Callable!(T) callable) {
    //     return new FutureTask!(T)(callable);
    // }

    /**
     * @throws RejectedExecutionException {@inheritDoc}
     * @throws NullPointerException       {@inheritDoc}
     */
    Future!(void) submit(Runnable task) {
        if (task is null) throw new NullPointerException();
        RunnableFuture!(void) ftask = new FutureTask!(void)(runnable);
        execute(ftask);
        return ftask;
    }

    // /**
    //  * @throws RejectedExecutionException {@inheritDoc}
    //  * @throws NullPointerException       {@inheritDoc}
    //  */
    // Future!(T) submit(T)(Runnable task, T result) {
    //     if (task is null) throw new NullPointerException();
    //     RunnableFuture!(T) ftask = newTaskFor(task, result);
    //     execute(ftask);
    //     return ftask;
    // }

    // /**
    //  * @throws RejectedExecutionException {@inheritDoc}
    //  * @throws NullPointerException       {@inheritDoc}
    //  */
    // Future!(T) submit(T)(Callable!(T) task) {
    //     if (task is null) throw new NullPointerException();
    //     RunnableFuture!(T) ftask = newTaskFor(task);
    //     execute(ftask);
    //     return ftask;
    // }

    // /**
    //  * the main mechanics of invokeAny.
    //  */
    // private T doInvokeAny(T)(Collection!(Callable!(T)) tasks,
    //                           bool timed, long nanos) {
    //     if (tasks is null)
    //         throw new NullPointerException();
    //     int ntasks = tasks.size();
    //     if (ntasks == 0)
    //         throw new IllegalArgumentException();
    //     ArrayList!(Future!(T)) futures = new ArrayList!(Future!(T))(ntasks);
    //     ExecutorCompletionService!(T) ecs =
    //         new ExecutorCompletionService!(T)(this);

    //     // For efficiency, especially in executors with limited
    //     // parallelism, check to see if previously submitted tasks are
    //     // done before submitting more of them. This interleaving
    //     // plus the exception mechanics account for messiness of main
    //     // loop.

    //     try {
    //         // Record exceptions so that if we fail to obtain any
    //         // result, we can throw the last exception we got.
    //         ExecutionException ee = null;
    //         long deadline = timed ? Clock.currStdTime() + nanos : 0L;
    //         Iterator!(Callable!(T)) it = tasks.iterator();

    //         // Start one task for sure; the rest incrementally
    //         futures.add(ecs.submit(it.next()));
    //         --ntasks;
    //         int active = 1;

    //         for (;;) {
    //             Future!(T) f = ecs.poll();
    //             if (f is null) {
    //                 if (ntasks > 0) {
    //                     --ntasks;
    //                     futures.add(ecs.submit(it.next()));
    //                     ++active;
    //                 }
    //                 else if (active == 0)
    //                     break;
    //                 else if (timed) {
    //                     f = ecs.poll(nanos, NANOSECONDS);
    //                     if (f is null)
    //                         throw new TimeoutException();
    //                     nanos = deadline - Clock.currStdTime();
    //                 }
    //                 else
    //                     f = ecs.take();
    //             }
    //             if (f !is null) {
    //                 --active;
    //                 try {
    //                     return f.get();
    //                 } catch (ExecutionException eex) {
    //                     ee = eex;
    //                 } catch (RuntimeException rex) {
    //                     ee = new ExecutionException(rex);
    //                 }
    //             }
    //         }

    //         if (ee is null)
    //             ee = new ExecutionException();
    //         throw ee;

    //     } finally {
    //         cancelAll(futures);
    //     }
    // }

    // T invokeAny(T)(Collection!(Callable!(T)) tasks) {
    //     try {
    //         return doInvokeAny(tasks, false, 0);
    //     } catch (TimeoutException cannotHappen) {
    //         assert(false);
    //         return null;
    //     }
    // }

    // T invokeAny(T)(Collection!(Callable!(T)) tasks,
    //                        Duration timeout) {
    //     return doInvokeAny(tasks, true, unit.toNanos(timeout));
    // }

    // List!(Future!(T)) invokeAll(T)(Collection!(Callable!(T)) tasks) {
    //     if (tasks is null)
    //         throw new NullPointerException();
    //     ArrayList!(Future!(T)) futures = new ArrayList!(Future!(T))(tasks.size());
    //     try {
    //         foreach (Callable!(T) t ; tasks) {
    //             RunnableFuture!(T) f = newTaskFor(t);
    //             futures.add(f);
    //             execute(f);
    //         }
    //         for (int i = 0, size = futures.size(); i < size; i++) {
    //             Future!(T) f = futures.get(i);
    //             if (!f.isDone()) {
    //                 try { f.get(); }
    //                 catch (CancellationException ex) {
    //                     version(HUNT_DEBUG) warning(ex.message());
    //                 }
    //                 catch (ExecutionException) {
    //                     version(HUNT_DEBUG) warning(ex.message());
    //                 }
    //             }
    //         }
    //         return futures;
    //     } catch (Throwable t) {
    //         cancelAll(futures);
    //         throw t;
    //     }
    // }

    // List!(Future!(T)) invokeAll(T)(Collection!(Callable!(T)) tasks,
    //                                      Duration timeout)  {
    //     if (tasks is null)
    //         throw new NullPointerException();
    //     long nanos = timeout.total!(TimeUnit.HectoNanosecond)();
    //     long deadline = Clock.currStdTime + nanos;
    //     ArrayList!(Future!(T)) futures = new ArrayList!(Future!(T))(tasks.size());
    //     int j = 0;

    //     timedOut: 
    //     try {
    //         foreach (Callable!(T) t ; tasks)
    //             futures.add(newTaskFor(t));

    //         final int size = futures.size();

    //         // Interleave time checks and calls to execute in case
    //         // executor doesn't have any/much parallelism.
    //         for (int i = 0; i < size; i++) {
    //             if (((i == 0) ? nanos : deadline - Clock.currStdTime) <= 0L)
    //                 break timedOut;
    //             execute(cast(Runnable)futures.get(i));
    //         }

    //         for (; j < size; j++) {
    //             Future!(T) f = futures.get(j);
    //             if (!f.isDone()) {
    //                 try { f.get( Duration(deadline - Clock.currStdTime)); }
    //                 catch (CancellationException ex) {
    //                     version(HUNT_DEBUG) warning(ex.message());
    //                 }
    //                 catch (ExecutionException ex) {
    //                     version(HUNT_DEBUG) warning(ex.message());
    //                 }
    //                 catch (TimeoutException ex) {
    //                     version(HUNT_DEBUG) warning(ex.message());
    //                     break timedOut;
    //                 }
    //             }
    //         }
    //         return futures;
    //     } catch (Throwable t) {
    //         cancelAll(futures);
    //         throw t;
    //     }
    //     // Timed out before all the tasks could be completed; cancel remaining
    //     cancelAll(futures, j);
    //     return futures;
    // }

    // private static void cancelAll(T)(ArrayList!(Future!(T)) futures) {
    //     cancelAll(futures, 0);
    // }

    // /** Cancels all futures with index at least j. */
    // private static void cancelAll(T)(ArrayList!(Future!(T)) futures, int j) {
    //     for (int size = futures.size(); j < size; j++)
    //         futures.get(j).cancel(true);
    // }
}
