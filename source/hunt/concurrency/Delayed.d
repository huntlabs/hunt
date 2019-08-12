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

module hunt.concurrency.Delayed;

import hunt.concurrency.Future;

import hunt.util.Common;
import core.time;

/**
 * A mix-in style interface for marking objects that should be
 * acted upon after a given delay.
 *
 * <p>An implementation of this interface must define a
 * {@code compareTo} method that provides an ordering consistent with
 * its {@code getDelay} method.
 *
 * @author Doug Lea
 */
interface Delayed : Comparable!(Delayed) {

    /**
     * Returns the remaining delay associated with this object, in the
     * given time unit.
     *
     * @param unit the time unit
     * @return the remaining delay; zero or negative values indicate
     * that the delay has already elapsed
     */
    Duration getDelay();
}



/**
 * A delayed result-bearing action that can be cancelled.
 * Usually a scheduled future is the result of scheduling
 * a task with a {@link ScheduledExecutorService}.
 *
 * @author Doug Lea
 * @param (V) The result type returned by this Future
 */
interface ScheduledFuture(V) : Delayed, Future!(V) {
}


/**
 * A {@link ScheduledFuture} that is {@link Runnable}. Successful
 * execution of the {@code run} method causes completion of the
 * {@code Future} and allows access to its results.
 * @see FutureTask
 * @see Executor
 * @author Doug Lea
 * @param (V) The result type returned by this Future's {@code get} method
 */
interface RunnableScheduledFuture(V) : RunnableFuture!(V), 
    ScheduledFuture!(V), IRunnableScheduledFuture {

    /**
     * Returns {@code true} if this task is periodic. A periodic task may
     * re-run according to some schedule. A non-periodic task can be
     * run only once.
     *
     * @return {@code true} if this task is periodic
     */
    bool isPeriodic();
}

interface IRunnableScheduledFuture : Delayed, Runnable {
    
    bool isPeriodic();

    bool cancel(bool mayInterruptIfRunning);

    bool isCancelled();
}