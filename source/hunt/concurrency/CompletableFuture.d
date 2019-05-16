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

module hunt.concurrency.CompletableFuture;

import hunt.concurrency.CompletionStage;
import hunt.concurrency.Delayed;
import hunt.concurrency.Exceptions;
import hunt.concurrency.ForkJoinPool;
import hunt.concurrency.ForkJoinTask;
import hunt.concurrency.Future;
import hunt.concurrency.ScheduledThreadPoolExecutor;
import hunt.concurrency.thread;
import hunt.concurrency.ThreadFactory;
import hunt.concurrency.atomic.AtomicHelper;

import hunt.Exceptions;
import hunt.Functions;
import hunt.util.Common;
import hunt.util.DateTime;
import hunt.util.ObjectUtils;

import hunt.logging.ConsoleLogger;

import core.time;
import std.conv;


// Modes for Completion.tryFire. Signedness matters.
enum int SYNC   =  0;
enum int ASYNC  =  1;
enum int NESTED = -1;


/** The encoding of the null value. */
__gshared AltResult NIL; // = new AltResult(null);

/* ------------- Async task preliminaries -------------- */

private __gshared bool USE_COMMON_POOL;

/**
 * Default executor -- ForkJoinPool.commonPool() unless it cannot
 * support parallelism.
 */
private __gshared Executor ASYNC_POOL;


shared static this() {
    NIL = new AltResult(null);
    USE_COMMON_POOL = (ForkJoinPool.getCommonPoolParallelism() > 1);
    if(USE_COMMON_POOL){
        ASYNC_POOL = ForkJoinPool.commonPool();
    } else {
        ASYNC_POOL = new ThreadPerTaskExecutor();
    }
}


/**
*/
abstract class AbstractCompletableFuture {
    Object result;       // Either the result or boxed AltResult
    Completion stack;    // Top of Treiber stack of dependent actions

    abstract void bipush(AbstractCompletableFuture b, BiCompletion c);
    abstract void cleanStack();
    abstract bool completeExceptionally(Throwable ex);
    abstract void postComplete();
    abstract void unipush(Completion c);
    
    /**
     * Returns {@code true} if completed in any fashion: normally,
     * exceptionally, or via cancellation.
     *
     * @return {@code true} if completed
     */
    bool isDone() {
        return result !is null;
    }


}

/**
 * A {@link Future} that may be explicitly completed (setting its
 * value and status), and may be used as a {@link CompletionStage},
 * supporting dependent functions and actions that trigger upon its
 * completion.
 *
 * <p>When two or more threads attempt to
 * {@link #complete complete},
 * {@link #completeExceptionally completeExceptionally}, or
 * {@link #cancel cancel}
 * a CompletableFuture, only one of them succeeds.
 *
 * <p>In addition to these and related methods for directly
 * manipulating status and results, CompletableFuture implements
 * interface {@link CompletionStage} with the following policies: <ul>
 *
 * <li>Actions supplied for dependent completions of
 * <em>non-async</em> methods may be performed by the thread that
 * completes the current CompletableFuture, or by any other caller of
 * a completion method.
 *
 * <li>All <em>async</em> methods without an explicit Executor
 * argument are performed using the {@link ForkJoinPool#commonPool()}
 * (unless it does not support a parallelism level of at least two, in
 * which case, a new Thread is created to run each task).  This may be
 * overridden for non-static methods in subclasses by defining method
 * {@link #defaultExecutor()}. To simplify monitoring, debugging,
 * and tracking, all generated asynchronous tasks are instances of the
 * marker interface {@link AsynchronousCompletionTask}.  Operations
 * with time-delays can use adapter methods defined in this class, for
 * example: {@code supplyAsync(supplier, delayedExecutor(timeout,
 * timeUnit))}.  To support methods with delays and timeouts, this
 * class maintains at most one daemon thread for triggering and
 * cancelling actions, not for running them.
 *
 * <li>All CompletionStage methods are implemented independently of
 * other public methods, so the behavior of one method is not impacted
 * by overrides of others in subclasses.
 *
 * <li>All CompletionStage methods return CompletableFutures.  To
 * restrict usages to only those methods defined in interface
 * CompletionStage, use method {@link #minimalCompletionStage}. Or to
 * ensure only that clients do not themselves modify a future, use
 * method {@link #copy}.
 * </ul>
 *
 * <p>CompletableFuture also implements {@link Future} with the following
 * policies: <ul>
 *
 * <li>Since (unlike {@link FutureTask}) this class has no direct
 * control over the computation that causes it to be completed,
 * cancellation is treated as just another form of exceptional
 * completion.  Method {@link #cancel cancel} has the same effect as
 * {@code completeExceptionally(new CancellationException())}. Method
 * {@link #isCompletedExceptionally} can be used to determine if a
 * CompletableFuture completed in any exceptional fashion.
 *
 * <li>In case of exceptional completion with a CompletionException,
 * methods {@link #get()} and {@link #get(long, TimeUnit)} throw an
 * {@link ExecutionException} with the same cause as held in the
 * corresponding CompletionException.  To simplify usage in most
 * contexts, this class also defines methods {@link #join()} and
 * {@link #getNow} that instead throw the CompletionException directly
 * in these cases.
 * </ul>
 *
 * <p>Arguments used to pass a completion result (that is, for
 * parameters of type {@code T}) for methods accepting them may be
 * null, but passing a null value for any other parameter will result
 * in a {@link NullPointerException} being thrown.
 *
 * <p>Subclasses of this class should normally override the "virtual
 * constructor" method {@link #newIncompleteFuture}, which establishes
 * the concrete type returned by CompletionStage methods. For example,
 * here is a class that substitutes a different default Executor and
 * disables the {@code obtrude} methods:
 *
 * <pre> {@code
 * class MyCompletableFuture(T) : CompletableFuture!(T) {
 *   final Executor myExecutor = ...;
 *   MyCompletableFuture() { }
 *   <U> CompletableFuture!(U) newIncompleteFuture() {
 *     return new MyCompletableFuture!(U)(); }
 *   Executor defaultExecutor() {
 *     return myExecutor; }
 *   void obtrudeValue(T value) {
 *     throw new UnsupportedOperationException(); }
 *   void obtrudeException(Throwable ex) {
 *     throw new UnsupportedOperationException(); }
 * }}</pre>
 *
 * @author Doug Lea
 * @param <T> The result type returned by this future's {@code join}
 * and {@code get} methods
 * @since 1.8
 */
class CompletableFuture(T) : AbstractCompletableFuture, Future!(T), CompletionStage!(T) {

    /*
     * Overview:
     *
     * A CompletableFuture may have dependent completion actions,
     * collected in a linked stack. It atomically completes by CASing
     * a result field, and then pops off and runs those actions. This
     * applies across normal vs exceptional outcomes, sync vs async
     * actions, binary triggers, and various forms of completions.
     *
     * Non-nullness of field "result" indicates done.  It may
     * be set directly if known to be thread-confined, else via CAS.
     * An AltResult is used to box null as a result, as well as to
     * hold exceptions.  Using a single field makes completion simple
     * to detect and trigger.  Result encoding and decoding is
     * straightforward but tedious and adds to the sprawl of trapping
     * and associating exceptions with targets.  Minor simplifications
     * rely on (static) NIL (to box null results) being the only
     * AltResult with a null exception field, so we don't usually need
     * explicit comparisons.  Even though some of the generics casts
     * are unchecked (see SuppressWarnings annotations), they are
     * placed to be appropriate even if checked.
     *
     * Dependent actions are represented by Completion objects linked
     * as Treiber stacks headed by field "stack". There are Completion
     * classes for each kind of action, grouped into:
     * - single-input (UniCompletion),
     * - two-input (BiCompletion),
     * - projected (BiCompletions using exactly one of two inputs),
     * - shared (CoCompletion, used by the second of two sources),
     * - zero-input source actions,
     * - Signallers that unblock waiters.
     * class Completion : ForkJoinTask to enable async execution
     * (adding no space overhead because we exploit its "tag" methods
     * to maintain claims). It is also declared as Runnable to allow
     * usage with arbitrary executors.
     *
     * Support for each kind of CompletionStage relies on a separate
     * class, along with two CompletableFuture methods:
     *
     * * A Completion class with name X corresponding to function,
     *   prefaced with "Uni", "Bi", or "Or". Each class contains
     *   fields for source(s), actions, and dependent. They are
     *   boringly similar, differing from others only with respect to
     *   underlying functional forms. We do this so that users don't
     *   encounter layers of adapters in common usages.
     *
     * * Boolean CompletableFuture method x(...) (for example
     *   biApply) takes all of the arguments needed to check that an
     *   action is triggerable, and then either runs the action or
     *   arranges its async execution by executing its Completion
     *   argument, if present. The method returns true if known to be
     *   complete.
     *
     * * Completion method tryFire(int mode) invokes the associated x
     *   method with its held arguments, and on success cleans up.
     *   The mode argument allows tryFire to be called twice (SYNC,
     *   then ASYNC); the first to screen and trap exceptions while
     *   arranging to execute, and the second when called from a task.
     *   (A few classes are not used async so take slightly different
     *   forms.)  The claim() callback suppresses function invocation
     *   if already claimed by another thread.
     *
     * * Some classes (for example UniApply) have separate handling
     *   code for when known to be thread-confined ("now" methods) and
     *   for when shared (in tryFire), for efficiency.
     *
     * * CompletableFuture method xStage(...) is called from a public
     *   stage method of CompletableFuture f. It screens user
     *   arguments and invokes and/or creates the stage object.  If
     *   not async and already triggerable, the action is run
     *   immediately.  Otherwise a Completion c is created, and
     *   submitted to the executor if triggerable, or pushed onto f's
     *   stack if not.  Completion actions are started via c.tryFire.
     *   We recheck after pushing to a source future's stack to cover
     *   possible races if the source completes while pushing.
     *   Classes with two inputs (for example BiApply) deal with races
     *   across both while pushing actions.  The second completion is
     *   a CoCompletion pointing to the first, shared so that at most
     *   one performs the action.  The multiple-arity methods allOf
     *   does this pairwise to form trees of completions.  Method
     *   anyOf is handled differently from allOf because completion of
     *   any source should trigger a cleanStack of other sources.
     *   Each AnyOf completion can reach others via a shared array.
     *
     * Note that the generic type parameters of methods vary according
     * to whether "this" is a source, dependent, or completion.
     *
     * Method postComplete is called upon completion unless the target
     * is guaranteed not to be observable (i.e., not yet returned or
     * linked). Multiple threads can call postComplete, which
     * atomically pops each dependent action, and tries to trigger it
     * via method tryFire, in NESTED mode.  Triggering can propagate
     * recursively, so NESTED mode returns its completed dependent (if
     * one exists) for further processing by its caller (see method
     * postFire).
     *
     * Blocking methods get() and join() rely on Signaller Completions
     * that wake up waiting threads.  The mechanics are similar to
     * Treiber stack wait-nodes used in FutureTask, Phaser, and
     * SynchronousQueue. See their internal documentation for
     * algorithmic details.
     *
     * Without precautions, CompletableFutures would be prone to
     * garbage accumulation as chains of Completions build up, each
     * pointing back to its sources. So we null out fields as soon as
     * possible.  The screening checks needed anyway harmlessly ignore
     * null arguments that may have been obtained during races with
     * threads nulling out fields.  We also try to unlink non-isLive
     * (fired or cancelled) Completions from stacks that might
     * otherwise never be popped: Method cleanStack always unlinks non
     * isLive completions from the head of stack; others may
     * occasionally remain if racing with other cancellations or
     * removals.
     *
     * Completion fields need not be declared as final or volatile
     * because they are only visible to other threads upon safe
     * publication.
     */


    final bool internalComplete(Object r) { // CAS from null to r
        return AtomicHelper.compareAndSet(this.result, null, r);
    }

    /** Returns true if successfully pushed c onto stack. */
    final bool tryPushStack(Completion c) {
        // info(typeid(c).name);

        Completion h = stack;

        AtomicHelper.store(c.next, h); // CAS piggyback
        bool r = AtomicHelper.compareAndSet(this.stack, h, c);
        // Completion x = this.stack;
        // while(x !is null) {
        //     tracef("%s, Completion: %s", cast(Object*)this, typeid(x).name);
        //     x = x.next;
        // }
        return r;
    }

    /** Unconditionally pushes c onto stack, retrying if necessary. */
    final void pushStack(Completion c) {
        do {} while (!tryPushStack(c));
    }

    /* ------------- Encoding and decoding outcomes -------------- */

    /** Completes with the null value, unless already completed. */
    final bool completeNull() {
        return AtomicHelper.compareAndSet(this.result, null, NIL);
    }

    /** Returns the encoding of the given non-exceptional value. */
    final Object encodeValue(T t) {
        return (t is null) ? NIL : t;
    }

    /** Completes with a non-exceptional result, unless already completed. */
    final bool completeValue(T t) {
        return AtomicHelper.compareAndSet(this.result, null, (t is null) ? NIL : t);
    }

    /**
     * Returns the encoding of the given (non-null) exception as a
     * wrapped CompletionException unless it is one already.
     */
    private static AltResult encodeThrowable(Throwable x) {
        CompletionException ex = cast(CompletionException)x;
        if(ex is null) {
            return new AltResult(new CompletionException(x));
        } else {
            return new AltResult(x);
        }
    }

    /** Completes with an exceptional result, unless already completed. */
    final bool completeThrowable(Throwable x) {
        return AtomicHelper.compareAndSet(this.result, null, encodeThrowable(x));
    }

    /**
     * Returns the encoding of the given (non-null) exception as a
     * wrapped CompletionException unless it is one already.  May
     * return the given Object r (which must have been the result of a
     * source future) if it is equivalent, i.e. if this is a simple
     * relay of an existing CompletionException.
     */
    static Object encodeThrowable(Throwable x, Object r) {
        CompletionException cex = cast(CompletionException)x;
        if (cex is null)
            x = new CompletionException(x);
        else {
            AltResult ar = cast(AltResult)r;
            if (ar !is null && x is ar.ex)
                return r;
        }
        return new AltResult(x);
    }

    /**
     * Completes with the given (non-null) exceptional result as a
     * wrapped CompletionException unless it is one already, unless
     * already completed.  May complete with the given Object r
     * (which must have been the result of a source future) if it is
     * equivalent, i.e. if this is a simple propagation of an
     * existing CompletionException.
     */
    final bool completeThrowable(Throwable x, Object r) {
        return AtomicHelper.compareAndSet(this.result, null, encodeThrowable(x, r));
    }

    /**
     * Returns the encoding of the given arguments: if the exception
     * is non-null, encodes as AltResult.  Otherwise uses the given
     * value, boxed as NIL if null.
     */
    Object encodeOutcome(T t, Throwable x) {
        return (x is null) ? (t is null) ? NIL : t : encodeThrowable(x);
    }

    /**
     * Returns the encoding of a copied outcome; if exceptional,
     * rewraps as a CompletionException, else returns argument.
     */
    static Object encodeRelay(Object r) {
        Throwable x;

        AltResult ar = cast(AltResult)r;

        if (ar !is null && (x = ar.ex) !is null) {
            CompletionException cex = cast(CompletionException)x;
            if(x is null) {
                r = new AltResult(new CompletionException(x));
            }
        }
        return r;
    }

    /**
     * Completes with r or a copy of r, unless already completed.
     * If exceptional, r is first coerced to a CompletionException.
     */
    final bool completeRelay(Object r) {
        return AtomicHelper.compareAndSet(this.result, null, encodeRelay(r));
    }

    /**
     * Reports result using Future.get conventions.
     */
    private static Object reportGet(Object r) {
        if (r is null) // by convention below, null means interrupted
            throw new InterruptedException();
        AltResult ar = cast(AltResult)r;
        if (ar !is null) {
            Throwable x, cause;
            if ((x = ar.ex) is null)
                return null;
            CancellationException cex = cast(CancellationException)x;
            if (cex !is null)
                throw cex;
            CompletionException cex2 = cast(CompletionException)x;
            if (cex2 !is null &&
                (cause = x.next) !is null)
                x = cause;
            throw new ExecutionException(x);
        }
        return r;
    }

    /**
     * Decodes outcome to return result or throw unchecked exception.
     */
    private static Object reportJoin(Object r) {
        AltResult ar = cast(AltResult)r;
        if (ar !is null) {
            Throwable x;
            if ((x = ar.ex) is null)
                return null;
            CancellationException cex = cast(CancellationException)x;
            if (cex !is null)
                throw cex;
            CompletionException cex2 = cast(CompletionException)x;
            if (cex2 !is null)
                throw cex2;
            throw new CompletionException(x);
        }
        return r;
    }

    /* ------------- Base Completion classes and operations -------------- */


    /**
     * Pops and tries to trigger all reachable dependents.  Call only
     * when known to be done.
     */
    final override void postComplete() {
        /*
         * On each step, variable f holds current dependents to pop
         * and run.  It is extended along only one path at a time,
         * pushing others to avoid unbounded recursion.
         */

        AbstractCompletableFuture f = this; Completion h;
        while ((h = f.stack) !is null ||
               (f !is this && (h = (f = this).stack) !is null)) {
            AbstractCompletableFuture d; Completion t;
            t = h.next;
            // infof("this: %s, h: %s", cast(Object*)this, typeid(h).name);

            if(AtomicHelper.compareAndSet(f.stack, h, t)) {
                if (t !is null) {
                    if (f !is this) {
                        pushStack(h);
                        continue;
                    }
                    AtomicHelper.compareAndSet(h.next, t, null); // try to detach
                }
                // infof("Completion: %s, this: %s", typeid(h).name, typeid(this).name);
                d = h.tryFire(NESTED);
                f = (d is null) ? this : d;
            }
        }
    }

    /** Traverses stack and unlinks one or more dead Completions, if found. */
    final override void cleanStack() {
        Completion p = stack;
        // ensure head of stack live
        for (bool unlinked = false;;) {
            if (p is null)
                return;
            else if (p.isLive()) {
                if (unlinked)
                    return;
                else
                    break;
            }
            else if (AtomicHelper.compareAndSet(this.stack, p, (p = p.next)))
                unlinked = true;
            else
                p = stack;
        }
        // try to unlink first non-live
        for (Completion q = p.next; q !is null;) {
            Completion s = q.next;
            if (q.isLive()) {
                p = q;
                q = s;
            } else if (AtomicHelper.compareAndSet(p.next, q, s))
                break;
            else
                q = p.next;
        }
    }

    /* ------------- One-input Completions -------------- */

    /**
     * Pushes the given completion unless it completes while trying.
     * Caller should first check that result is null.
     */
    final override void unipush(Completion c) {
        if (c !is null) {
            while (!tryPushStack(c)) {
                if (result !is null) {
                    AtomicHelper.store(c.next, null);
                    break;
                }
            }
            if (result !is null)
                c.tryFire(SYNC);
        }
    }

    /**
     * Post-processing by dependent after successful UniCompletion tryFire.
     * Tries to clean stack of source a, and then either runs postComplete
     * or returns this to caller, depending on mode.
     */
    final CompletableFuture!(T) postFire(AbstractCompletableFuture a, int mode) {

        // infof("this: %s, h: %s", cast(Object*)this, typeid(this.stack).name);

        if (a !is null && a.stack !is null) {
            Object r;
            if ((r = a.result) is null)
                a.cleanStack();
            if (mode >= 0 && (r !is null || a.result !is null))
                a.postComplete();
        }

        // if(stack is null)
        //     infof("this: %s, mode=%d, result: %s, stack: null", cast(Object*)this, mode, result is null);
        // else
        //     infof("this: %s, mode=%d, result: %s, stack: %s", cast(Object*)this, mode, result is null, typeid(this.stack).name);

        if (result !is null && stack !is null) {
            if (mode < 0)
                return this;
            else
                postComplete();
        }
        return null;
    }

    private CompletableFuture!(V) uniApplyStage(V)(Executor e, Function!(T,V) f) {
        if (f is null) throw new NullPointerException();
        Object r;
        if ((r = result) !is null)
            return uniApplyNow!(V)(r, e, f);
        CompletableFuture!(V) d = newIncompleteFuture!(V)();
        unipush(new UniApply!(T,V)(e, d, this, f));
        return d;
    }

    private CompletableFuture!(V) uniApplyNow(V)(Object r, Executor e, Function!(T,V) f) {
        Throwable x;
        CompletableFuture!(V) d = newIncompleteFuture!(V)();
        AltResult ar = cast(AltResult)r;
        if (ar !is null) {
            if ((x = ar.ex) !is null) {
                d.result = encodeThrowable(x, r);
                return d;
            }
            r = null;
        }
        try {
            if (e !is null) {
                e.execute(new UniApply!(T,V)(null, d, this, f));
            } else {
                T t = cast(T) r;
                d.result = d.encodeValue(f(t));
            }
        } catch (Throwable ex) {
            d.result = encodeThrowable(ex);
        }
        return d;
    }


    private CompletableFuture!(Void) uniAcceptStage(Executor e,
                                                   Consumer!(T) f) {
        if (f is null) throw new NullPointerException();
        Object r;
        if ((r = result) !is null)
            return uniAcceptNow(r, e, f);
        CompletableFuture!(Void) d = newIncompleteFuture!(Void)();
        unipush(new UniAccept!(T)(e, d, this, f));
        return d;
    }

    private CompletableFuture!(Void) uniAcceptNow(Object r, Executor e, Consumer!(T) f) {
        Throwable x;
        CompletableFuture!(Void) d = newIncompleteFuture!(Void)();
        AltResult ar = cast(AltResult)r;
        if (ar !is null) {
            if ((x = ar.ex) !is null) {
                d.result = encodeThrowable(x, r);
                return d;
            }
            r = null;
        }
        try {
            if (e !is null) {
                e.execute(new UniAccept!(T)(null, d, this, f));
            } else {
                T t = cast(T) r;
                f(t);
                d.result = NIL;
            }
        } catch (Throwable ex) {
            d.result = encodeThrowable(ex);
        }
        return d;
    }


    private CompletableFuture!(Void) uniRunStage(Executor e, Runnable f) {
        if (f is null) throw new NullPointerException();
        Object r;
        if ((r = result) !is null)
            return uniRunNow(r, e, f);
        CompletableFuture!(Void) d = newIncompleteFuture!(Void)();
        unipush(new UniRun!(T)(e, d, this, f));
        return d;
    }

    private CompletableFuture!(Void) uniRunNow(Object r, Executor e, Runnable f) {
        Throwable x;
        CompletableFuture!(Void) d = newIncompleteFuture!(Void)();
        AltResult ar = cast(AltResult)r;
        if (ar !is null && (x = ar.ex) !is null)
            d.result = encodeThrowable(x, r);
        else
            try {
                if (e !is null) {
                    e.execute(new UniRun!(T)(null, d, this, f));
                } else {
                    f.run();
                    d.result = NIL;
                }
            } catch (Throwable ex) {
                d.result = encodeThrowable(ex);
            }
        return d;
    }


    final bool uniWhenComplete(Object r,
                                  BiConsumer!(T, Throwable) f,
                                  UniWhenComplete!(T) c) {
        T t; Throwable x = null;
        if (result is null) {
            try {
                if (c !is null && !c.claim())
                    return false;
                AltResult ar = cast(AltResult)r;
                if (ar !is null) {
                    x = ar.ex;
                    t = null;
                } else {
                    T tr = cast(T) r;
                    t = tr;
                }
                f(t, x);
                if (x is null) {
                    internalComplete(r);
                    return true;
                }
            } catch (Throwable ex) {
                if (x is null)
                    x = ex;
                else if (x !is ex)
                    x.next = ex;
            }
            completeThrowable(x, r);
        }
        return true;
    }

    private CompletableFuture!(T) uniWhenCompleteStage(
        Executor e, BiConsumer!(T, Throwable) f) {
        if (f is null) throw new NullPointerException();
        CompletableFuture!(T) d = newIncompleteFuture!(T)();
        Object r;
        if ((r = result) is null)
            unipush(new UniWhenComplete!(T)(e, d, this, f));
        else if (e is null)
            d.uniWhenComplete(r, f, null);
        else {
            try {
                e.execute(new UniWhenComplete!(T)(null, d, this, f));
            } catch (Throwable ex) {
                d.result = encodeThrowable(ex);
            }
        }
        return d;
    }

    final bool uniHandle(S)(Object r,
                                BiFunction!(S, Throwable, T) f,
                                UniHandle!(S,T) c) {
        S s; Throwable x;
        if (result is null) {
            try {
                if (c !is null && !c.claim())
                    return false;
                AltResult ar = cast(AltResult)r;
                if (ar !is null) {
                    x = ar.ex;
                    s = null;
                } else {
                    x = null;
                    S ss = cast(S) r;
                    s = ss;
                }
                completeValue(f(s, x));
            } catch (Throwable ex) {
                completeThrowable(ex);
            }
        }
        return true;
    }

    private CompletableFuture!(V) uniHandleStage(V)(
        Executor e, BiFunction!(T, Throwable, V) f) {
        if (f is null) throw new NullPointerException();
        CompletableFuture!(V) d = newIncompleteFuture!(V)();
        Object r;
        if ((r = result) is null)
            unipush(new UniHandle!(T,V)(e, d, this, f));
        else if (e is null)
            d.uniHandle!(T)(r, f, null);
        else {
            try {
                e.execute(new UniHandle!(T,V)(null, d, this, f));
            } catch (Throwable ex) {
                d.result = encodeThrowable(ex);
            }
        }
        return d;
    }

 
    final bool uniExceptionally(Object r,
                                   Function!(Throwable,  T) f,
                                   UniExceptionally!(T) c) {
        Throwable x;
        if (result is null) {
            try {
                AltResult ar = cast(AltResult)r;
                if (ar !is null && (x = ar.ex) !is null) {
                    if (c !is null && !c.claim())
                        return false;
                    completeValue(f(x));
                } else
                    internalComplete(r);
            } catch (Throwable ex) {
                completeThrowable(ex);
            }
        }
        return true;
    }

    private CompletableFuture!(T) uniExceptionallyStage(
        Function!(Throwable, T) f) {
        if (f is null) throw new NullPointerException();
        CompletableFuture!(T) d = newIncompleteFuture!(T)();
        Object r;
        if ((r = result) is null)
            unipush(new UniExceptionally!(T)(d, this, f));
        else
            d.uniExceptionally(r, f, null);
        return d;
    }

// T : U
    private static CompletableFuture!(U) uniCopyStage(U, T)(CompletableFuture!(T) src) {
        Object r;
        CompletableFuture!(U) d = newIncompleteFuture!(U)();// src.newIncompleteFuture();
        if ((r = src.result) !is null)
            d.result = encodeRelay(r);
        else
            src.unipush(new UniRelay!(U,T)(d, src));
        return d;
    }

    private MinimalStage!(T) uniAsMinimalStage() {
        Object r;
        if ((r = result) !is null)
            return new MinimalStage!(T)(encodeRelay(r));
        MinimalStage!(T) d = new MinimalStage!(T)();
        unipush(new UniRelay!(T,T)(d, this));
        return d;
    }

    private CompletableFuture!(V) uniComposeStage(V)(
        Executor e, Function!(T, CompletionStage!(V)) f) {
        if (f is null) throw new NullPointerException();
        CompletableFuture!(V) d = newIncompleteFuture!(V)();
        Object r, s; Throwable x;
        if ((r = result) is null)
            unipush(new UniCompose!(T,V)(e, d, this, f));
        else if (e is null) {
            AltResult ar = cast(AltResult)r;
            if (ar !is null) {
                if ((x = ar.ex) !is null) {
                    d.result = encodeThrowable(x, r);
                    return d;
                }
                r = null;
            }
            try {
                T t = cast(T) r;
                CompletableFuture!(V) g = f(t).toCompletableFuture();
                if ((s = g.result) !is null)
                    d.result = encodeRelay(s);
                else {
                    g.unipush(new UniRelay!(V,V)(d, g));
                }
            } catch (Throwable ex) {
                d.result = encodeThrowable(ex);
            }
        }
        else
            try {
                e.execute(new UniCompose!(T,V)(null, d, this, f));
            } catch (Throwable ex) {
                d.result = encodeThrowable(ex);
            }
        return d;
    }

    /* ------------- Two-input Completions -------------- */

    /** A Completion for an action with two sources */

    /**
     * Pushes completion to this and b unless both done.
     * Caller should first check that either result or b.result is null.
     */
    final override void bipush(AbstractCompletableFuture b, BiCompletion c) {
        if (c !is null) {
            while (result is null) {
                if (tryPushStack(c)) {
                    if (b.result is null)
                        b.unipush(new CoCompletion(c));
                    else if (result !is null)
                        c.tryFire(SYNC);
                    return;
                }
            }
            b.unipush(c);
        }
    }

    /** Post-processing after successful BiCompletion tryFire. */
    final CompletableFuture!(T) postFire(AbstractCompletableFuture a,
                                        AbstractCompletableFuture b, int mode) {
        if (b !is null && b.stack !is null) { // clean second source
            Object r;
            if ((r = b.result) is null)
                b.cleanStack();
            if (mode >= 0 && (r !is null || b.result !is null))
                b.postComplete();
        }
        return postFire(a, mode);
    }


    final bool biApply(R,S)(Object r, Object s,
                                BiFunction!(R, S, T) f,
                                BiApply!(R,S,T) c) {
        Throwable x;
        tryComplete: if (result is null) {
            AltResult ar = cast(AltResult)r;
            if (ar !is null) {
                if ((x = ar.ex) !is null) {
                    completeThrowable(x, r);
                    break tryComplete;
                }
                r = null;
            }
            AltResult ars = cast(AltResult)r;
            if (ars !is null) {
                if ((x = ars.ex) !is null) {
                    completeThrowable(x, s);
                    break tryComplete;
                }
                s = null;
            }
            try {
                if (c !is null && !c.claim())
                    return false;
                R rr = cast(R) r;
                S ss = cast(S) s;
                completeValue(f(rr, ss));
            } catch (Throwable ex) {
                completeThrowable(ex);
            }
        }
        return true;
    }

    private CompletableFuture!(V) biApplyStage(U,V)(
        Executor e, CompletionStage!(U) o, BiFunction!(T, U, V) f) {

        CompletableFuture!(U) b = cast(CompletableFuture!(U))o.toCompletableFuture(); 
        Object r, s;

        if (f is null || b is null)
            throw new NullPointerException();
        CompletableFuture!(V) d = newIncompleteFuture!(V)();
        if ((r = result) is null || (s = b.result) is null)
            bipush(b, new BiApply!(T,U,V)(e, d, this, b, f));
        else if (e is null)
            d.biApply(r, s, f, null);
        else
            try {
                e.execute(new BiApply!(T,U,V)(null, d, this, b, f));
            } catch (Throwable ex) {
                d.result = encodeThrowable(ex);
            }
        return d;
    }


    final bool biAccept(R,S)(Object r, Object s,
                                 BiConsumer!(R,S) f,
                                 BiAccept!(R,S) c) {
        Throwable x;
        tryComplete: if (result is null) {
            AltResult ar = cast(AltResult)r;
            if (ar !is null) {
                if ((x = ar.ex) !is null) {
                    completeThrowable(x, r);
                    break tryComplete;
                }
                r = null;
            }
            AltResult ars = cast(AltResult)r;
            if (ars !is null) {
                if ((x = ars.ex) !is null) {
                    completeThrowable(x, s);
                    break tryComplete;
                }
                s = null;
            }
            try {
                if (c !is null && !c.claim())
                    return false;
                R rr = cast(R) r;
                S ss = cast(S) s;
                f.accept(rr, ss);
                completeNull();
            } catch (Throwable ex) {
                completeThrowable(ex);
            }
        }
        return true;
    }

    private CompletableFuture!(Void) biAcceptStage(U)(
        Executor e, CompletionStage!(U) o,
        BiConsumer!(T, U) f) {
        CompletableFuture!(U) b; Object r, s;
        if (f is null || (b = o.toCompletableFuture()) is null)
            throw new NullPointerException();
        CompletableFuture!(Void) d = newIncompleteFuture!(Void)();
        if ((r = result) is null || (s = b.result) is null)
            bipush(b, new BiAccept!(T,U)(e, d, this, b, f));
        else if (e is null)
            d.biAccept(r, s, f, null);
        else
            try {
                e.execute(new BiAccept!(T,U)(null, d, this, b, f));
            } catch (Throwable ex) {
                d.result = encodeThrowable(ex);
            }
        return d;
    }

    
    final bool biRun(Object r, Object s, Runnable f, IUniCompletion c) {
        Throwable x; Object z;
        if (result is null) {
            AltResult ar = cast(AltResult)r;
            AltResult ars = cast(AltResult)s;
            if(ar !is null && (x = ar.ex) !is null){
                completeThrowable(x, r);
            } else if(ars !is null && (x = ars.ex) !is null){
                completeThrowable(x, s);
            } else {
                try {
                    if (c !is null && !c.claim())
                        return false;
                    f.run();
                    completeNull();
                } catch (Throwable ex) {
                    completeThrowable(ex);
                }
            }
        }
        return true;
    }

    private CompletableFuture!(Void) biRunStage(U)(Executor e, CompletionStage!U o,
                                               Runnable f) {
        AbstractCompletableFuture b; Object r, s;
        if (f is null || (b = cast(AbstractCompletableFuture)o.toCompletableFuture()) is null)
            throw new NullPointerException();
        CompletableFuture!(Void) d = newIncompleteFuture!(Void)();
        if ((r = result) is null || (s = b.result) is null)
            bipush(b, new BiRun(e, d, this, b, f));
        else if (e is null)
            d.biRun(r, s, f, null);
        else
            try {
                e.execute(new BiRun(null, d, this, b, f));
            } catch (Throwable ex) {
                d.result = encodeThrowable(ex);
            }
        return d;
    }


    /** Recursively constructs a tree of completions. */
    static CompletableFuture!(Void) andTree(AbstractCompletableFuture[] cfs,
                                           int lo, int hi) {
        CompletableFuture!(Void) d = new CompletableFuture!(Void)();
        if (lo > hi) // empty
            d.result = NIL;
        else {
            AbstractCompletableFuture a, b; 
            Object r, s, z; 
            Throwable x;

            int mid = (lo + hi) >>> 1;
            if ((a = (lo == mid ? cfs[lo] :
                      andTree(cfs, lo, mid))) is null ||
                (b = (lo == hi ? a : (hi == mid+1) ? cfs[hi] :
                      andTree(cfs, mid+1, hi))) is null)
                throw new NullPointerException();
            if ((r = a.result) is null || (s = b.result) is null)
                a.bipush(b, new BiRelay(d, a, b));
            else {
                AltResult ar = cast(AltResult)r;
                AltResult ars = cast(AltResult)s;
                if(ar !is null && (x = ar.ex) !is null){
                    d.result = encodeThrowable(x, r);
                } else if(ars !is null && (x = ars.ex) !is null){
                    d.result = encodeThrowable(x, s);
                }
                else
                    d.result = NIL;
            }
        }
        return d;
    }

    /* ------------- Projected (Ored) BiCompletions -------------- */

    /**
     * Pushes completion to this and b unless either done.
     * Caller should first check that result and b.result are both null.
     */
    final void orpush(AbstractCompletableFuture b, BiCompletion c) {
        if (c !is null) {
            while (!tryPushStack(c)) {
                if (result !is null) {
                    AtomicHelper.store(c.next, null);
                    break;
                }
            }
            if (result !is null)
                c.tryFire(SYNC);
            else
                b.unipush(new CoCompletion(c));
        }
    }

    private CompletableFuture!(V) orApplyStage(U, V)( // U : T,V
        Executor e, CompletionStage!(U) o, Function!(T, V) f) {

        CompletableFuture!(U) b = cast(CompletableFuture!(U))o.toCompletableFuture();
        if (f is null || b is null)
            throw new NullPointerException();

        Object r; CompletableFuture!T z;
        if ((r = (z = this).result) !is null ||
            (r = (z = b).result) !is null)
            return z.uniApplyNow!(V)(r, e, f);

        CompletableFuture!(V) d = newIncompleteFuture!(V)();
        orpush(b, new OrApply!(T,U,V)(e, d, this, b, f));
        return d;
    }


    private CompletableFuture!(Void) orAcceptStage(U)( // U : T
        Executor e, CompletionStage!(U) o, Consumer!(T) f) {
        CompletableFuture!(U) b;
        if (f is null || (b = cast(CompletableFuture!(U))o) is null)
            throw new NullPointerException();

        Object r; CompletableFuture!T z;
        if ((r = (z = this).result) !is null ||
            (r = (z = b).result) !is null)
            return z.uniAcceptNow(r, e, f);

        CompletableFuture!(Void) d = newIncompleteFuture!(Void)();
        orpush(b, new OrAccept!(T,U)(e, d, this, b, f));
        return d;
    }

    private CompletableFuture!(Void) orRunStage(U)(Executor e, CompletionStage!U o,
                                               Runnable f) {
        AbstractCompletableFuture b;
        if (f is null || (b = o.toCompletableFuture()) is null)
            throw new NullPointerException();

        Object r; AbstractCompletableFuture z;
        if ((r = (z = this).result) !is null ||
            (r = (z = b).result) !is null)
            return z.uniRunNow(r, e, f);

        CompletableFuture!(Void) d = newIncompleteFuture!(Void)();
        orpush(b, new OrRun(e, d, this, b, f));
        return d;
    }


    /* ------------- Signallers -------------- */

    /**
     * Returns raw result after waiting, or null if interruptible and
     * interrupted.
     */
    private Object waitingGet(bool interruptible) {
        Signaller q = null;
        bool queued = false;
        Object r;
        while ((r = result) is null) {
            if (q is null) {
                q = new Signaller(interruptible, 0L, 0L);
                ForkJoinWorkerThread th = cast(ForkJoinWorkerThread)ThreadEx.currentThread();
                if (th !is null)
                    ForkJoinPool.helpAsyncBlocker(defaultExecutor(), q);
            }
            else if (!queued) {
                queued = tryPushStack(q);
            }
            else {
                try {
                    ForkJoinPool.managedBlock(q);
                } catch (InterruptedException ie) { // currently cannot happen
                    q.interrupted = true;
                }
                if (q.interrupted && interruptible)
                    break;
            }
        }
        if (q !is null && queued) {
            q.thread = null;
            if (!interruptible && q.interrupted)
                ThreadEx.currentThread().interrupt();
            if (r is null)
                cleanStack();
        }
        if (r !is null || (r = result) !is null)
            postComplete();
        return r;
    }

    /**
     * Returns raw result after waiting, or null if interrupted, or
     * throws TimeoutException on timeout.
     */
    private Object timedGet(long nanos) {
        if (ThreadEx.interrupted())
            return null;
        if (nanos > 0L) {
            long d = DateTimeHelper.currentTimeMillis + nanos;
            long deadline = (d == 0L) ? 1L : d; // avoid 0
            Signaller q = null;
            bool queued = false;
            Object r;
            while ((r = result) is null) { // similar to untimed
                if (q is null) {
                    q = new Signaller(true, nanos, deadline);
                    ForkJoinWorkerThread th = cast(ForkJoinWorkerThread)ThreadEx.currentThread();
                    if (th !is null)
                        ForkJoinPool.helpAsyncBlocker(defaultExecutor(), q);
                }
                else if (!queued)
                    queued = tryPushStack(q);
                else if (q.nanos <= 0L)
                    break;
                else {
                    try {
                        ForkJoinPool.managedBlock(q);
                    } catch (InterruptedException ie) {
                        q.interrupted = true;
                    }
                    if (q.interrupted)
                        break;
                }
            }
            if (q !is null && queued) {
                q.thread = null;
                if (r is null)
                    cleanStack();
            }
            if (r !is null || (r = result) !is null)
                postComplete();
            if (r !is null || (q !is null && q.interrupted))
                return r;
        }
        throw new TimeoutException();
    }

    /* ------------- public methods -------------- */

    /**
     * Creates a new incomplete CompletableFuture.
     */
    this() {
    }

    /**
     * Creates a new complete CompletableFuture with given encoded result.
     */
    this(Object r) {
        this.result = r;
    }



    /**
     * Waits if necessary for this future to complete, and then
     * returns its result.
     *
     * @return the result value
     * @throws CancellationException if this future was cancelled
     * @throws ExecutionException if this future completed exceptionally
     * @throws InterruptedException if the current thread was interrupted
     * while waiting
     */
    T get() {
        Object r;
        if ((r = result) is null)
            r = waitingGet(true);
        return cast(T) reportGet(r);
    }

    /**
     * Waits if necessary for at most the given time for this future
     * to complete, and then returns its result, if available.
     *
     * @param timeout the maximum time to wait
     * @param unit the time unit of the timeout argument
     * @return the result value
     * @throws CancellationException if this future was cancelled
     * @throws ExecutionException if this future completed exceptionally
     * @throws InterruptedException if the current thread was interrupted
     * while waiting
     * @throws TimeoutException if the wait timed out
     */
    T get(Duration timeout) {
        long nanos = timeout.total!(TimeUnit.Millisecond)();
        Object r;
        if ((r = result) is null)
            r = timedGet(nanos);
        return cast(T) reportGet(r);
    }

    /**
     * Returns the result value when complete, or throws an
     * (unchecked) exception if completed exceptionally. To better
     * conform with the use of common functional forms, if a
     * computation involved in the completion of this
     * CompletableFuture threw an exception, this method throws an
     * (unchecked) {@link CompletionException} with the underlying
     * exception as its cause.
     *
     * @return the result value
     * @throws CancellationException if the computation was cancelled
     * @throws CompletionException if this future completed
     * exceptionally or a completion computation threw an exception
     */
    T join() {
        Object r;
        if ((r = result) is null)
            r = waitingGet(false);
        return cast(T) reportJoin(r);
    }

    /**
     * Returns the result value (or throws any encountered exception)
     * if completed, else returns the given valueIfAbsent.
     *
     * @param valueIfAbsent the value to return if not completed
     * @return the result value, if completed, else the given valueIfAbsent
     * @throws CancellationException if the computation was cancelled
     * @throws CompletionException if this future completed
     * exceptionally or a completion computation threw an exception
     */
    T getNow(T valueIfAbsent) {
        Object r;
        return ((r = result) is null) ? valueIfAbsent : cast(T) reportJoin(r);
    }

    /**
     * If not already completed, sets the value returned by {@link
     * #get()} and related methods to the given value.
     *
     * @param value the result value
     * @return {@code true} if this invocation caused this CompletableFuture
     * to transition to a completed state, else {@code false}
     */
    bool complete(T value) {
        bool triggered = completeValue(value);
        postComplete();
        return triggered;
    }

    /**
     * If not already completed, causes invocations of {@link #get()}
     * and related methods to throw the given exception.
     *
     * @param ex the exception
     * @return {@code true} if this invocation caused this CompletableFuture
     * to transition to a completed state, else {@code false}
     */
    override bool completeExceptionally(Throwable ex) {
        if (ex is null) throw new NullPointerException();
        bool triggered = internalComplete(new AltResult(ex));
        postComplete();
        return triggered;
    }

    CompletableFuture!(U) thenApply(U)(Function!(T, U) fn) {
        return uniApplyStage!(U)(cast(Executor)null, fn);
    }

    CompletableFuture!(U) thenApplyAsync(U)(Function!(T, U) fn) {
        return uniApplyStage!(U)(defaultExecutor(), fn);
    }

    CompletableFuture!(U) thenApplyAsync(U)(Function!(T, U) fn, Executor executor) {
        return uniApplyStage!(U)(screenExecutor(executor), fn);
    }

    CompletableFuture!(Void) thenAccept(Consumer!(T) action) {
        return uniAcceptStage(cast(Executor)null, action);
    }

    CompletableFuture!(Void) thenAcceptAsync(Consumer!(T) action) {
        return uniAcceptStage(defaultExecutor(), action);
    }

    CompletableFuture!(Void) thenAcceptAsync(Consumer!(T) action,
                                                   Executor executor) {
        return uniAcceptStage(screenExecutor(executor), action);
    }

    CompletableFuture!(Void) thenRun(Runnable action) {
        return uniRunStage(null, action);
    }

    CompletableFuture!(Void) thenRunAsync(Runnable action) {
        return uniRunStage(defaultExecutor(), action);
    }

    CompletableFuture!(Void) thenRunAsync(Runnable action,
                                                Executor executor) {
        return uniRunStage(screenExecutor(executor), action);
    }

    CompletableFuture!(V) thenCombine(U, V)(
        CompletionStage!(U) other,
        BiFunction!(T, U, V) fn) {
        return biApplyStage(null, other, fn);
    }

    CompletableFuture!(V) thenCombineAsync(U, V)(
        CompletionStage!(U) other,
        BiFunction!(T, U, V) fn) {
        return biApplyStage(defaultExecutor(), other, fn);
    }

    CompletableFuture!(V) thenCombineAsync(U, V)(
        CompletionStage!(U) other,
        BiFunction!(T, U, V) fn, Executor executor) {
        return biApplyStage(screenExecutor(executor), other, fn);
    }

    CompletableFuture!(Void) thenAcceptBoth(U)(
        CompletionStage!(U) other,
        BiConsumer!(T, U) action) {
        return biAcceptStage(null, other, action);
    }

    CompletableFuture!(Void) thenAcceptBothAsync(U)(
        CompletionStage!(U) other,
        BiConsumer!(T, U) action) {
        return biAcceptStage(defaultExecutor(), other, action);
    }

    CompletableFuture!(Void) thenAcceptBothAsync(U)(
        CompletionStage!(U) other,
        BiConsumer!(T, U) action, Executor executor) {
        return biAcceptStage(screenExecutor(executor), other, action);
    }

    CompletableFuture!(Void) runAfterBoth(U)(CompletionStage!U other,
                                                Action action) {
        return biRunStage(null, other, new class Runnable {
            void run() {
                action();
            }
        } );
    }

    CompletableFuture!(Void) runAfterBoth(U)(CompletionStage!U other,
                                                Runnable action) {
        return biRunStage(null, other, action);
    }

    CompletableFuture!(Void) runAfterBothAsync(U)(CompletionStage!U other,
                                                     Runnable action) {
        return biRunStage(defaultExecutor(), other, action);
    }

    CompletableFuture!(Void) runAfterBothAsync(U)(CompletionStage!U other,
                                                     Runnable action,
                                                     Executor executor) {
        return biRunStage(screenExecutor(executor), other, action);
    }

    CompletableFuture!(U) applyToEither(U)(
        CompletionStage!(T) other, Function!(T, U) fn) {
        return orApplyStage!(T, U)(null, other, fn);
    }

    CompletableFuture!(U) applyToEitherAsync(U)(
        CompletionStage!(T) other, Function!(T, U) fn) {
        return orApplyStage!(T, U)(defaultExecutor(), other, fn);
    }

    CompletableFuture!(U) applyToEitherAsync(U)(
        CompletionStage!(T) other, Function!(T, U) fn,
        Executor executor) {
        return orApplyStage!(T, U)(screenExecutor(executor), other, fn);
    }

    CompletableFuture!(Void) acceptEither(
        CompletionStage!(T) other, Consumer!(T) action) {
        return orAcceptStage(null, other, action);
    }

    CompletableFuture!(Void) acceptEitherAsync(
        CompletionStage!(T) other, Consumer!(T) action) {
        return orAcceptStage(defaultExecutor(), other, action);
    }

    CompletableFuture!(Void) acceptEitherAsync(
        CompletionStage!(T) other, Consumer!(T) action,
        Executor executor) {
        return orAcceptStage(screenExecutor(executor), other, action);
    }

    CompletableFuture!(Void) runAfterEither(U)(CompletionStag!U other,
                                                  Runnable action) {
        return orRunStage(null, other, action);
    }

    CompletableFuture!(Void) runAfterEitherAsync(U)(CompletionStage!U other,
                                                       Runnable action) {
        return orRunStage(defaultExecutor(), other, action);
    }

    CompletableFuture!(Void) runAfterEitherAsync(U)(CompletionStage!U other,
                                                       Runnable action,
                                                       Executor executor) {
        return orRunStage(screenExecutor(executor), other, action);
    }

    CompletableFuture!(U) thenCompose(U)(
        Function!(T, CompletionStage!(U)) fn) {
        return uniComposeStage(null, fn);
    }

    CompletableFuture!(U) thenComposeAsync(U)(
        Function!(T, CompletionStage!(U)) fn) {
        return uniComposeStage(defaultExecutor(), fn);
    }

    CompletableFuture!(U) thenComposeAsync(U)(
        Function!(T, CompletionStage!(U)) fn,
        Executor executor) {
        return uniComposeStage(screenExecutor(executor), fn);
    }

    CompletableFuture!(T) whenComplete(
        BiConsumer!(T, Throwable) action) {
        return uniWhenCompleteStage(null, action);
    }

    CompletableFuture!(T) whenCompleteAsync(
        BiConsumer!(T, Throwable) action) {
        return uniWhenCompleteStage(defaultExecutor(), action);
    }

    CompletableFuture!(T) whenCompleteAsync(
        BiConsumer!(T, Throwable) action, Executor executor) {
        return uniWhenCompleteStage(screenExecutor(executor), action);
    }

    CompletableFuture!(U) handle(U)(BiFunction!(T, Throwable, U) fn) {
        return uniHandleStage!(U)(null, fn);
    }

    CompletableFuture!(U) handleAsync(U)(
        BiFunction!(T, Throwable, U) fn) {
        return uniHandleStage!(U)(defaultExecutor(), fn);
    }

    CompletableFuture!(U) handleAsync(U)(
        BiFunction!(T, Throwable, U) fn, Executor executor) {
        return uniHandleStage!(U)(screenExecutor(executor), fn);
    }

    /**
     * Returns this CompletableFuture.
     *
     * @return this CompletableFuture
     */
    CompletableFuture!(T) toCompletableFuture() {
        return this;
    }

    // not in interface CompletionStage

    /**
     * Returns a new CompletableFuture that is completed when this
     * CompletableFuture completes, with the result of the given
     * function of the exception triggering this CompletableFuture's
     * completion when it completes exceptionally; otherwise, if this
     * CompletableFuture completes normally, then the returned
     * CompletableFuture also completes normally with the same value.
     * Note: More flexible versions of this functionality are
     * available using methods {@code whenComplete} and {@code handle}.
     *
     * @param fn the function to use to compute the value of the
     * returned CompletableFuture if this CompletableFuture completed
     * exceptionally
     * @return the new CompletableFuture
     */
    CompletableFuture!(T) exceptionally(
        Function!(Throwable, T) fn) {
        return uniExceptionallyStage(fn);
    }


    /* ------------- Arbitrary-arity constructions -------------- */

    /**
     * Returns a new CompletableFuture that is completed when all of
     * the given CompletableFutures complete.  If any of the given
     * CompletableFutures complete exceptionally, then the returned
     * CompletableFuture also does so, with a CompletionException
     * holding this exception as its cause.  Otherwise, the results,
     * if any, of the given CompletableFutures are not reflected in
     * the returned CompletableFuture, but may be obtained by
     * inspecting them individually. If no CompletableFutures are
     * provided, returns a CompletableFuture completed with the value
     * {@code null}.
     *
     * <p>Among the applications of this method is to await completion
     * of a set of independent CompletableFutures before continuing a
     * program, as in: {@code CompletableFuture.allOf(c1, c2,
     * c3).join();}.
     *
     * @param cfs the CompletableFutures
     * @return a new CompletableFuture that is completed when all of the
     * given CompletableFutures complete
     * @throws NullPointerException if the array or any of its elements are
     * {@code null}
     */
    static CompletableFuture!(Void) allOf(AbstractCompletableFuture[] cfs...) {
        return andTree(cfs, 0, cast(int)cfs.length - 1);
    }

    /**
     * Returns a new CompletableFuture that is completed when any of
     * the given CompletableFutures complete, with the same result.
     * Otherwise, if it completed exceptionally, the returned
     * CompletableFuture also does so, with a CompletionException
     * holding this exception as its cause.  If no CompletableFutures
     * are provided, returns an incomplete CompletableFuture.
     *
     * @param cfs the CompletableFutures
     * @return a new CompletableFuture that is completed with the
     * result or exception of any of the given CompletableFutures when
     * one completes
     * @throws NullPointerException if the array or any of its elements are
     * {@code null}
     */
    static CompletableFuture!(Object) anyOf(U)(CompletableFuture!(U)[] cfs...) {
        int n; Object r;
        if ((n = cast(int)cfs.length) <= 1)
            return (n == 0)
                ? new CompletableFuture!(Object)()
                : uniCopyStage(U, T)(cfs[0]);

        foreach(AbstractCompletableFuture cf; cfs) {
            if ((r = cf.result) !is null)
                return new CompletableFuture!(Object)(encodeRelay(r));
        }

        cfs = cfs.dup;
        CompletableFuture!(Object) d = new CompletableFuture!Object();
        foreach (AbstractCompletableFuture cf;  cfs)
            cf.unipush(new AnyOf(d, cf, cfs));
        // If d was completed while we were adding completions, we should
        // clean the stack of any sources that may have had completions
        // pushed on their stack after d was completed.
        if (d.result !is null)
            for (size_t i = 0, len = cfs.length; i < len; i++)
                if (cfs[i].result !is null)
                    for (i++; i < len; i++)
                        if (cfs[i].result is null)
                            cfs[i].cleanStack();
        return d;
    }

    /* ------------- Control and status methods -------------- */

    /**
     * If not already completed, completes this CompletableFuture with
     * a {@link CancellationException}. Dependent CompletableFutures
     * that have not already completed will also complete
     * exceptionally, with a {@link CompletionException} caused by
     * this {@code CancellationException}.
     *
     * @param mayInterruptIfRunning this value has no effect in this
     * implementation because interrupts are not used to control
     * processing.
     *
     * @return {@code true} if this task is now cancelled
     */
    bool cancel(bool mayInterruptIfRunning) {
        bool cancelled = (result is null) &&
            internalComplete(new AltResult(new CancellationException()));
        postComplete();
        return cancelled || isCancelled();
    }

    /**
     * Returns {@code true} if this CompletableFuture was cancelled
     * before it completed normally.
     *
     * @return {@code true} if this CompletableFuture was cancelled
     * before it completed normally
     */
    bool isCancelled() {
        Object r = result;
        AltResult ar = cast(AltResult)r;
        if (ar !is null) {
            CancellationException ce = cast(CancellationException)ar.ex;
            if(ce !is null)
                return true;
        }
        return false;
    }

    /**
     * Returns {@code true} if this CompletableFuture completed
     * exceptionally, in any way. Possible causes include
     * cancellation, explicit invocation of {@code
     * completeExceptionally}, and abrupt termination of a
     * CompletionStage action.
     *
     * @return {@code true} if this CompletableFuture completed
     * exceptionally
     */
    bool isCompletedExceptionally() {
        Object r = result;
        AltResult ar = cast(AltResult)r;
        return ar !is null && r !is NIL;
    }

    /**
     * Forcibly sets or resets the value subsequently returned by
     * method {@link #get()} and related methods, whether or not
     * already completed. This method is designed for use only in
     * error recovery actions, and even in such situations may result
     * in ongoing dependent completions using established versus
     * overwritten outcomes.
     *
     * @param value the completion value
     */
    void obtrudeValue(T value) {
        result = (value is null) ? NIL : value;
        postComplete();
    }

    /**
     * Forcibly causes subsequent invocations of method {@link #get()}
     * and related methods to throw the given exception, whether or
     * not already completed. This method is designed for use only in
     * error recovery actions, and even in such situations may result
     * in ongoing dependent completions using established versus
     * overwritten outcomes.
     *
     * @param ex the exception
     * @throws NullPointerException if the exception is null
     */
    void obtrudeException(Throwable ex) {
        if (ex is null) throw new NullPointerException();
        result = new AltResult(ex);
        postComplete();
    }

    /**
     * Returns the estimated number of CompletableFutures whose
     * completions are awaiting completion of this CompletableFuture.
     * This method is designed for use in monitoring system state, not
     * for synchronization control.
     *
     * @return the number of dependent CompletableFutures
     */
    int getNumberOfDependents() {
        int count = 0;
        for (Completion p = stack; p !is null; p = p.next)
            ++count;
        return count;
    }

    /**
     * Returns a string identifying this CompletableFuture, as well as
     * its completion state.  The state, in brackets, contains the
     * String {@code "Completed Normally"} or the String {@code
     * "Completed Exceptionally"}, or the String {@code "Not
     * completed"} followed by the number of CompletableFutures
     * dependent upon its completion, if any.
     *
     * @return a string identifying this CompletableFuture, as well as its state
     */
    override string toString() {
        Object r = result;
        int count = 0; // avoid call to getNumberOfDependents in case disabled
        for (Completion p = stack; p !is null; p = p.next)
            ++count;
        string s;
        if(r is null) {
            s = (count == 0)
                ? "[Not completed]"
                : "[Not completed, " ~ count.to!string ~ " dependents]";
        } else {
            s = "[Completed normally]";
            AltResult ar = cast(AltResult)r;
            if(ar !is null) {
                if(ar.ex !is null) {
                    s = "[Completed exceptionally: " ~ ar.ex.msg ~ "]";
                }
            }
        }
        return super.toString() ~ s;
    }

    // jdk9 additions

    /**
     * Returns a new incomplete CompletableFuture of the type to be
     * returned by a CompletionStage method. Subclasses should
     * normally override this method to return an instance of the same
     * class as this CompletableFuture. The default implementation
     * returns an instance of class CompletableFuture.
     *
     * @param <U> the type of the value
     * @return a new CompletableFuture
     * @since 9
     */
    static CompletableFuture!(U) newIncompleteFuture(U)() {
        return new CompletableFuture!(U)();
    }

    /**
     * Returns the default Executor used for async methods that do not
     * specify an Executor. This class uses the {@link
     * ForkJoinPool#commonPool()} if it supports more than one
     * parallel thread, or else an Executor using one thread per async
     * task.  This method may be overridden in subclasses to return
     * an Executor that provides at least one independent thread.
     *
     * @return the executor
     * @since 9
     */
    Executor defaultExecutor() {
        return ASYNC_POOL;
    }

    /**
     * Returns a new CompletableFuture that is completed normally with
     * the same value as this CompletableFuture when it completes
     * normally. If this CompletableFuture completes exceptionally,
     * then the returned CompletableFuture completes exceptionally
     * with a CompletionException with this exception as cause. The
     * behavior is equivalent to {@code thenApply(x -> x)}. This
     * method may be useful as a form of "defensive copying", to
     * prevent clients from completing, while still being able to
     * arrange dependent actions.
     *
     * @return the new CompletableFuture
     * @since 9
     */
    CompletableFuture!(T) copy() {
        return uniCopyStage!(T, T)(this);
    }

    /**
     * Returns a new CompletionStage that is completed normally with
     * the same value as this CompletableFuture when it completes
     * normally, and cannot be independently completed or otherwise
     * used in ways not defined by the methods of interface {@link
     * CompletionStage}.  If this CompletableFuture completes
     * exceptionally, then the returned CompletionStage completes
     * exceptionally with a CompletionException with this exception as
     * cause.
     *
     * <p>Unless overridden by a subclass, a new non-minimal
     * CompletableFuture with all methods available can be obtained from
     * a minimal CompletionStage via {@link #toCompletableFuture()}.
     * For example, completion of a minimal stage can be awaited by
     *
     * <pre> {@code minimalStage.toCompletableFuture().join(); }</pre>
     *
     * @return the new CompletionStage
     * @since 9
     */
    CompletionStage!(T) minimalCompletionStage() {
        return uniAsMinimalStage();
    }

    /**
     * Completes this CompletableFuture with the result of
     * the given Supplier function invoked from an asynchronous
     * task using the given executor.
     *
     * @param supplier a function returning the value to be used
     * to complete this CompletableFuture
     * @param executor the executor to use for asynchronous execution
     * @return this CompletableFuture
     * @since 9
     */
    CompletableFuture!(T) completeAsync(Supplier!(T) supplier,
                                              Executor executor) {
        if (supplier is null || executor is null)
            throw new NullPointerException();
        executor.execute(new AsyncSupply!(T)(this, supplier));
        return this;
    }

    /**
     * Completes this CompletableFuture with the result of the given
     * Supplier function invoked from an asynchronous task using the
     * default executor.
     *
     * @param supplier a function returning the value to be used
     * to complete this CompletableFuture
     * @return this CompletableFuture
     * @since 9
     */
    CompletableFuture!(T) completeAsync(Supplier!(T) supplier) {
        return completeAsync(supplier, defaultExecutor());
    }

    /**
     * Exceptionally completes this CompletableFuture with
     * a {@link TimeoutException} if not otherwise completed
     * before the given timeout.
     *
     * @param timeout how long to wait before completing exceptionally
     *        with a TimeoutException, in units of {@code unit}
     * @param unit a {@code TimeUnit} determining how to interpret the
     *        {@code timeout} parameter
     * @return this CompletableFuture
     * @since 9
     */
    CompletableFuture!(T) orTimeout(Duration timeout) {
        if (result is null) {
            ScheduledFuture!(Void) f = Delayer.delay(new Timeout(this), timeout);
            whenComplete((T ignore, Throwable ex) {
                if (ex is null && f !is null && !f.isDone())
                    f.cancel(false);
            });
        }
        return this;
    }


    /**
     * Completes this CompletableFuture with the given value if not
     * otherwise completed before the given timeout.
     *
     * @param value the value to use upon timeout
     * @param timeout how long to wait before completing normally
     *        with the given value, in units of {@code unit}
     * @param unit a {@code TimeUnit} determining how to interpret the
     *        {@code timeout} parameter
     * @return this CompletableFuture
     * @since 9
     */
    CompletableFuture!(T) completeOnTimeout(T value, Duration timeout) {
        if (result is null) {
          ScheduledFuture!(Void) f = 
            Delayer.delay(new DelayedCompleter!(T)(this, value), timeout);

            whenComplete((T ignore, Throwable ex) {
                if (ex is null && f !is null && !f.isDone())
                    f.cancel(false);
            });            
        }
        return this;
    }

}



private final class AltResult { // See above
    Throwable ex;        // null only for NIL
    this(Throwable x) { this.ex = x; }
}



abstract class Completion : ForkJoinTask!(Void),
    Runnable, AsynchronousCompletionTask {
    Completion next;      // Treiber stack link

    /**
     * Performs completion action if triggered, returning a
     * dependent that may need propagation, if one exists.
     *
     * @param mode SYNC, ASYNC, or NESTED
     */
    abstract AbstractCompletableFuture tryFire(int mode);

    /** Returns true if possibly still triggerable. Used by cleanStack. */
    abstract bool isLive();

    final void run()                { tryFire(ASYNC); }
    final override bool exec()            { tryFire(ASYNC); return false; }
    final override Void getRawResult()       { return null; }
    final override void setRawResult(Void v) {}
}


/**
 * A marker interface identifying asynchronous tasks produced by
 * {@code async} methods. This may be useful for monitoring,
 * debugging, and tracking asynchronous activities.
 *
 * @since 1.8
 */
private interface AsynchronousCompletionTask {
}



/** Fallback if ForkJoinPool.commonPool() cannot support parallelism */
private final class ThreadPerTaskExecutor : Executor {
    void execute(Runnable r) { new ThreadEx(r).start(); }
}


/** A Completion with a source, dependent, and executor. */

interface IUniCompletion {
    bool claim();
    bool isLive();
}

abstract class UniCompletion : Completion, IUniCompletion {
    Executor executor;                 // executor to use (null if none)
    AbstractCompletableFuture dep;          // the dependent to complete
    AbstractCompletableFuture src;          // source for action

    this(Executor executor, AbstractCompletableFuture dep,
                  AbstractCompletableFuture src) {
        this.executor = executor; this.dep = dep; this.src = src;
    }

    /**
     * Returns true if action can be run. Call only when known to
     * be triggerable. Uses FJ tag bit to ensure that only one
     * thread claims ownership.  If async, starts as task -- a
     * later call to tryFire will run action.
     */
    final bool claim() {
        Executor e = executor;
        if (compareAndSetForkJoinTaskTag(cast(short)0, cast(short)1)) {
            if (e is null)
                return true;
            executor = null; // disable
            e.execute(this);
        }
        return false;
    }

    final override bool isLive() { return dep !is null; }
}


final class UniApply(T,V) : UniCompletion {
    Function!(T,V) fn;
    this(Executor executor, CompletableFuture!(V) dep,
             CompletableFuture!(T) src,
             Function!(T,V) fn) {
        super(executor, dep, src); this.fn = fn;
    }

    final override CompletableFuture!(V) tryFire(int mode) {
        CompletableFuture!(V) d; CompletableFuture!(T) a;
        Object r; Throwable x; Function!(T,V) f;
        if ((d = cast(CompletableFuture!(V))dep) is null || (f = fn) is null
            || (a = cast(CompletableFuture!(T))src) is null || (r = a.result) is null)
            return null;

        tryComplete: if (d.result is null) {
            AltResult ar = cast(AltResult)r;
            if (ar !is null) {
                if ((x = ar.ex) !is null) {
                    d.completeThrowable(x, r);
                    goto tryComplete;
                }
                r = null;
            }
            try {
                if (mode <= 0 && !claim()) {
                    return null;
                }
                else {
                    T t = cast(T) r;
                    d.completeValue(f(t));
                }
            } catch (Throwable ex) {
                d.completeThrowable(ex);
            }
        }
        dep = null; src = null; fn = null;

        return d.postFire(a, mode);
    }
}


final class UniAccept(T) : UniCompletion {
    Consumer!(T) fn;

    this(Executor executor, CompletableFuture!(Void) dep,
              CompletableFuture!(T) src, Consumer!(T) fn) {
        super(executor, dep, src); this.fn = fn;
    }

    final override CompletableFuture!(Void) tryFire(int mode) {
        CompletableFuture!(Void) d; CompletableFuture!(T) a;
        Object r; Throwable x; Consumer!(T) f;
        if ((d = cast(CompletableFuture!(Void))dep) is null || (f = fn) is null
            || (a = cast(CompletableFuture!(T))src) is null || (r = a.result) is null)
            return null;
        tryComplete: if (d.result is null) {
            AltResult ar = cast(AltResult)r;
            if (ar !is null) {
                if ((x = ar.ex) !is null) {
                    d.completeThrowable(x, r);
                    goto tryComplete;
                }
                r = null;
            }
            try {
                if (mode <= 0 && !claim())
                    return null;
                else {
                    T t = cast(T) r;
                    f(t);
                    d.completeNull();
                }
            } catch (Throwable ex) {
                d.completeThrowable(ex);
            }
        }
        dep = null; src = null; fn = null;
        return d.postFire(a, mode);
    }
}

    
final class UniRun(T) : UniCompletion {
    Runnable fn;

    this(Executor executor, CompletableFuture!(Void) dep,
           CompletableFuture!(T) src, Runnable fn) {
        super(executor, dep, src); this.fn = fn;
    }

    final override CompletableFuture!(Void) tryFire(int mode) {
        CompletableFuture!(Void) d; CompletableFuture!(T) a;
        Object r; Throwable x; Runnable f;
        if ((d = cast(CompletableFuture!(Void))dep) is null || (f = fn) is null
            || (a = cast(CompletableFuture!(T))src) is null || (r = a.result) is null)
            return null;
        if (d.result is null) {
            AltResult ar = cast(AltResult)r;
            if(ar !is null && (x = ar.ex) !is null) {
                d.completeThrowable(x, r);
            } else {
                try {
                    if (mode <= 0 && !claim())
                        return null;
                    else {
                        f.run();
                        d.completeNull();
                    }
                } catch (Throwable ex) {
                    d.completeThrowable(ex);
                }
            }
        }
        dep = null; src = null; fn = null;
        return d.postFire(a, mode);
    }
}

    
final class UniWhenComplete(T) : UniCompletion {
    BiConsumer!(T, Throwable) fn;
    this(Executor executor, CompletableFuture!(T) dep,
                    CompletableFuture!(T) src,
                    BiConsumer!(T, Throwable) fn) {
        super(executor, dep, src); this.fn = fn;
    }
    
    final override CompletableFuture!(T) tryFire(int mode) {
        CompletableFuture!(T) d; CompletableFuture!(T) a;
        Object r; BiConsumer!(T, Throwable) f;
        if ((d = cast(CompletableFuture!(T))dep) is null || (f = fn) is null
            || (a = cast(CompletableFuture!(T))src) is null || (r = a.result) is null
            || !d.uniWhenComplete(r, f, mode > 0 ? null : this))
            return null;
        dep = null; src = null; fn = null;
        return d.postFire(a, mode);
    }
}



final class UniHandle(T, V) : UniCompletion {
    BiFunction!(T, Throwable, V) fn;
    this(Executor executor, CompletableFuture!(V) dep,
              CompletableFuture!(T) src,
              BiFunction!(T, Throwable, V) fn) {
        super(executor, dep, src); this.fn = fn;
    }

    final override CompletableFuture!(V) tryFire(int mode) {
        CompletableFuture!(V) d = cast(CompletableFuture!(V))dep;
        CompletableFuture!(T) a = cast(CompletableFuture!(T))src;
        Object r; BiFunction!(T, Throwable, V) f;

        if (d is null || (f = fn) is null
            || a is null || (r = a.result) is null
            || !d.uniHandle!(T)(r, f, mode > 0 ? null : this))
            return null;
        dep = null; src = null; fn = null;
        return d.postFire(a, mode);
    }
}


final class UniExceptionally(T) : UniCompletion {
    Function!(Throwable,  T) fn;

    this(CompletableFuture!(T) dep, CompletableFuture!(T) src,
                     Function!(Throwable,  T) fn) {
        super(null, dep, src); this.fn = fn;
    }

    final override CompletableFuture!(T) tryFire(int mode) { // never ASYNC
        // assert mode != ASYNC;
        CompletableFuture!(T) d; CompletableFuture!(T) a;
        Object r; Function!(Throwable,  T) f;
        if ((d = cast(CompletableFuture!(T))dep) is null || (f = fn) is null
            || (a = cast(CompletableFuture!(T))src) is null || (r = a.result) is null
            || !d.uniExceptionally(r, f, this))
            return null;
        dep = null; src = null; fn = null;
        return d.postFire(a, mode);
    }
}


final class UniRelay(U, T : U) : UniCompletion {
    this(CompletableFuture!(U) dep, CompletableFuture!(T) src) {
        super(null, dep, src);
    }

    final override CompletableFuture!(U) tryFire(int mode) {
        CompletableFuture!(U) d; CompletableFuture!(T) a; Object r;
        if ((d = cast(CompletableFuture!(U))dep) is null
            || (a = cast(CompletableFuture!(U))src) is null || (r = a.result) is null)
            return null;
        if (d.result is null)
            d.completeRelay(r);
        src = null; dep = null;
        return d.postFire(a, mode);
    }
}

    
final class UniCompose(T,V) : UniCompletion {
    Function!(T, CompletionStage!(V)) fn;

    this(Executor executor, CompletableFuture!(V) dep,
               CompletableFuture!(T) src,
               Function!(T, CompletionStage!(V)) fn) {
        super(executor, dep, src); this.fn = fn;
    }

    final override CompletableFuture!(V) tryFire(int mode) {
        CompletableFuture!(V) d; CompletableFuture!(T) a;
        Function!(T, CompletionStage!(V)) f;
        Object r; Throwable x;
        if ((d = dep) is null || (f = fn) is null
            || (a = src) is null || (r = a.result) is null)
            return null;
        tryComplete: if (d.result is null) {
            if (ar !is null) {
                if ((x = ar.ex) !is null) {
                    d.completeThrowable(x, r);
                    break tryComplete;
                }
                r = null;
            }
            try {
                if (mode <= 0 && !claim())
                    return null;
                T t = cast(T) r;
                CompletableFuture!(V) g = f.apply(t).toCompletableFuture();
                if ((r = g.result) !is null)
                    d.completeRelay(r);
                else {
                    g.unipush(new UniRelay!(V,V)(d, g));
                    if (d.result is null)
                        return null;
                }
            } catch (Throwable ex) {
                d.completeThrowable(ex);
            }
        }
        dep = null; src = null; fn = null;
        return d.postFire(a, mode);
    }
}


/** A Completion for an action with two sources */

abstract class BiCompletion : UniCompletion {
    AbstractCompletableFuture snd; // second source for action

    this(Executor executor, AbstractCompletableFuture dep,
                 AbstractCompletableFuture src, AbstractCompletableFuture snd) {
        super(executor, dep, src); this.snd = snd;
    }
}

/** A Completion delegating to a BiCompletion */

final class CoCompletion : Completion {
    BiCompletion base;

    this(BiCompletion base) { this.base = base; }

    final override AbstractCompletableFuture tryFire(int mode) {
        BiCompletion c; AbstractCompletableFuture d;
        if ((c = base) is null || (d = c.tryFire(mode)) is null)
            return null;
        base = null; // detach
        return d;
    }

    final override bool isLive() {
        BiCompletion c;
        return (c = base) !is null
            // && c.isLive()
            && c.dep !is null;
    }
}

    
final class BiApply(T, U, V) : BiCompletion {
    BiFunction!(T, U, V) fn;

    this(Executor executor, CompletableFuture!(V) dep,
            CompletableFuture!(T) src, CompletableFuture!(U) snd,
            BiFunction!(T, U, V) fn) {
        super(executor, dep, src, snd); this.fn = fn;
    }

    final override CompletableFuture!(V) tryFire(int mode) {
        CompletableFuture!(V) d;
        CompletableFuture!(T) a;
        CompletableFuture!(U) b;
        Object r, s; BiFunction!(T, U, V) f;
        if ((d = dep) is null || (f = fn) is null
            || (a = src) is null || (r = a.result) is null
            || (b = snd) is null || (s = b.result) is null
            || !d.biApply(r, s, f, mode > 0 ? null : this))
            return null;
        dep = null; src = null; snd = null; fn = null;
        return d.postFire(a, b, mode);
    }
}

    
final class BiAccept(T, U) : BiCompletion {
    BiConsumer!(T, U) fn;

    this(Executor executor, CompletableFuture!(Void) dep,
             CompletableFuture!(T) src, CompletableFuture!(U) snd,
             BiConsumer!(T, U) fn) {
        super(executor, dep, src, snd); this.fn = fn;
    }

    final override CompletableFuture!(Void) tryFire(int mode) {
        CompletableFuture!(Void) d;
        CompletableFuture!(T) a;
        CompletableFuture!(U) b;
        Object r, s; BiConsumer!(T, U) f;
        if ((d = dep) is null || (f = fn) is null
            || (a = src) is null || (r = a.result) is null
            || (b = snd) is null || (s = b.result) is null
            || !d.biAccept(r, s, f, mode > 0 ? null : this))
            return null;
        dep = null; src = null; snd = null; fn = null;
        return d.postFire(a, b, mode);
    }
}


final class BiRun : BiCompletion {
    Runnable fn;

    this(Executor executor, CompletableFuture!(Void) dep,
          AbstractCompletableFuture src, AbstractCompletableFuture snd,
          Runnable fn) {
        super(executor, dep, src, snd); this.fn = fn;
    }

    final override CompletableFuture!(Void) tryFire(int mode) {
        CompletableFuture!(Void) d;
        AbstractCompletableFuture a;
        AbstractCompletableFuture b;
        Object r, s; Runnable f;
        if ((d = cast(CompletableFuture!(Void))dep) is null || (f = fn) is null
            || (a = src) is null || (r = a.result) is null
            || (b = snd) is null || (s = b.result) is null
            || !d.biRun(r, s, f, mode > 0 ? null : this))
            return null;
        dep = null; src = null; snd = null; fn = null;
        return d.postFire(a, b, mode);
    }
}

    
final class BiRelay : BiCompletion { // for And
    this(CompletableFuture!(Void) dep,
            AbstractCompletableFuture src, AbstractCompletableFuture snd) {
        super(null, dep, src, snd);
    }

    final override CompletableFuture!(Void) tryFire(int mode) {
        CompletableFuture!(Void) d;
        AbstractCompletableFuture a;
        AbstractCompletableFuture b;
        Object r, s, z; Throwable x;
        if ((d = cast(CompletableFuture!(Void))dep) is null
            || (a = src) is null || (r = a.result) is null
            || (b = snd) is null || (s = b.result) is null)
            return null;
        if (d.result is null) {
            AltResult ar = cast(AltResult)r;
            AltResult ars = cast(AltResult)s;
            if(ar !is null && (x = ar.ex) !is null){
                d.completeThrowable(x, r);
            } else if(ars !is null && (x = ars.ex) !is null){
                d.completeThrowable(x, s);
            }
            else
                d.completeNull();
        }
        src = null; snd = null; dep = null;
        return d.postFire(a, b, mode);
    }
}

    
final class OrApply(T, U : T, V) : BiCompletion {
    Function!(T,V) fn;

    this(Executor executor, CompletableFuture!(V) dep,
            CompletableFuture!(T) src, CompletableFuture!(U) snd,
            Function!(T,V) fn) {
        super(executor, dep, src, snd); this.fn = fn;
    }

    final override CompletableFuture!(V) tryFire(int mode) {
        CompletableFuture!(V) d = cast(CompletableFuture!(V))dep;
        CompletableFuture!(T) a = cast(CompletableFuture!(T))src;
        CompletableFuture!(U) b = cast(CompletableFuture!(U))snd;
        Object r; Throwable x; 
        Function!(T,V) f = fn;
        
        if (d is null || f is null || a is null || b is null
            || ((r = a.result) is null && (r = b.result) is null))
            return null;

        tryComplete: if (d.result is null) {
            try {
                if (mode <= 0 && !claim())
                    return null;
                
                AltResult ar = cast(AltResult)r;
                if (ar !is null) {
                    if ((x = ar.ex) !is null) {
                        d.completeThrowable(x, r);
                        goto tryComplete;
                    }
                    r = null;
                }
                T t = cast(T) r;
                d.completeValue(f(t));
            } catch (Throwable ex) {
                d.completeThrowable(ex);
            }
        }
        dep = null; src = null; snd = null; fn = null;
        return d.postFire(a, b, mode);
    }
}


final class OrAccept(T, U : T) : BiCompletion {
    Consumer!(T) fn;
    this(Executor executor, CompletableFuture!(Void) dep,
             CompletableFuture!(T) src, CompletableFuture!(U) snd,
             Consumer!(T) fn) {
        super(executor, dep, src, snd); this.fn = fn;
    }

    final override CompletableFuture!(Void) tryFire(int mode) {
        CompletableFuture!(Void) d = cast(CompletableFuture!(Void))dep;
        CompletableFuture!(T) a = cast(CompletableFuture!(T))src;
        CompletableFuture!(U) b = cast(CompletableFuture!(U))snd;
        Object r; Throwable x; 
        Consumer!(T) f = fn;

        if (d is null || f is null || a is null || b is null
            || ((r = a.result) is null && (r = b.result) is null))
            return null;

        tryComplete: if (d.result is null) {
            try {
                if (mode <= 0 && !claim())
                    return null;
                AltResult ar = cast(AltResult)r;
                if (ar !is null) {
                    if ((x = ar.ex) !is null) {
                        d.completeThrowable(x, r);
                        goto tryComplete;
                    }
                    r = null;
                }
                T t = cast(T) r;
                f(t);
                d.completeNull();
            } catch (Throwable ex) {
                d.completeThrowable(ex);
            }
        }
        dep = null; src = null; snd = null; fn = null;
        return d.postFire(a, b, mode);
    }
}

    
final class OrRun : BiCompletion {
    Runnable fn;

    this(Executor executor, CompletableFuture!(Void) dep,
          AbstractCompletableFuture src, AbstractCompletableFuture snd,
          Runnable fn) {
        super(executor, dep, src, snd); this.fn = fn;
    }

    final override CompletableFuture!(Void) tryFire(int mode) {
        CompletableFuture!(Void) d;
        AbstractCompletableFuture a;
        AbstractCompletableFuture b;
        Object r; Throwable x; Runnable f;
        if ((d = cast(CompletableFuture!(Void))dep) is null || (f = fn) is null
            || (a = src) is null || (b = snd) is null
            || ((r = a.result) is null && (r = b.result) is null))
            return null;
        if (d.result is null) {
            try {
                if (mode <= 0 && !claim())
                    return null;
                else {
                    AltResult ar = cast(AltResult)r;
                    if (ar !is null && (x = ar.ex) !is null)
                        d.completeThrowable(x, r);
                    else {
                        f.run();
                        d.completeNull();
                    }
                }
            } catch (Throwable ex) {
                d.completeThrowable(ex);
            }
        }
        dep = null; src = null; snd = null; fn = null;
        return d.postFire(a, b, mode);
    }
}


/** Completion for an anyOf input future. */

static class AnyOf : Completion {
    CompletableFuture!(Object) dep; 
    AbstractCompletableFuture src;
    AbstractCompletableFuture[] srcs;

    this(CompletableFuture!(Object) dep, AbstractCompletableFuture src,
          AbstractCompletableFuture[] srcs) {
        this.dep = dep; this.src = src; this.srcs = srcs;
    }

    final override CompletableFuture!(Object) tryFire(int mode) {
        // assert mode != ASYNC;
        CompletableFuture!(Object) d; AbstractCompletableFuture a;
        AbstractCompletableFuture[] as;
        Object r;
        if ((d = dep) is null
            || (a = src) is null || (r = a.result) is null
            || (as = srcs) is null)
            return null;
        dep = null; src = null; srcs = null;
        if (d.completeRelay(r)) {
            foreach (AbstractCompletableFuture b; as)
                if (b != a)
                    b.cleanStack();
            if (mode < 0)
                return d;
            else
                d.postComplete();
        }
        return null;
    }

    final override bool isLive() {
        CompletableFuture!(Object) d;
        return (d = dep) !is null && d.result is null;
    }
}


/* ------------- Zero-input Async forms -------------- */


final class AsyncSupply(T) : ForkJoinTask!(Void), 
    Runnable, AsynchronousCompletionTask {
        
    CompletableFuture!(T) dep; Supplier!(T) fn;

    this(CompletableFuture!(T) dep, Supplier!(T) fn) {
        this.dep = dep; this.fn = fn;
    }

    final override Void getRawResult() { return null; }
    final override void setRawResult(Void v) {}
    final override bool exec() { run(); return false; }

    void run() {
        CompletableFuture!(T) d; Supplier!(T) f;
        if ((d = dep) !is null && (f = fn) !is null) {
            dep = null; fn = null;
            if (d.result is null) {
                try {
                    d.completeValue(f());
                } catch (Throwable ex) {
                    d.completeThrowable(ex);
                }
            }
            d.postComplete();
        }
    }
}


   
final class AsyncRun : ForkJoinTask!(Void), Runnable, AsynchronousCompletionTask {
    CompletableFuture!(Void) dep; Action fn;
    
    this(CompletableFuture!(Void) dep, Action fn) {
        this.dep = dep; this.fn = fn;
    }

    final override Void getRawResult() { return null; }
    final override void setRawResult(Void v) {}
    final override bool exec() { run(); return false; }

    void run() {
        CompletableFuture!(Void) d; Action f;
        if ((d = dep) !is null && (f = fn) !is null) {
            dep = null; fn = null;
            if (d.result is null) {
                try {
                    f();
                    d.completeNull();
                } catch (Throwable ex) {
                    warning(ex);
                    d.completeThrowable(ex);
                }
            }
            d.postComplete();
        }
    }
}


/* ------------- Signallers -------------- */

/**
 * Completion for recording and releasing a waiting thread.  This
 * class implements ManagedBlocker to avoid starvation when
 * blocking actions pile up in ForkJoinPools.
 */

final class Signaller : Completion, ManagedBlocker {
    long nanos;                    // remaining wait time if timed
    long deadline;           // non-zero if timed
    bool interruptible;
    bool interrupted;
    ThreadEx thread;

    this(bool interruptible, long nanos, long deadline) {
        this.thread = ThreadEx.currentThread();
        this.interruptible = interruptible;
        this.nanos = nanos;
        this.deadline = deadline;
    }

    final override AbstractCompletableFuture tryFire(int ignore) {
        ThreadEx w; // no need to atomically claim
        if ((w = thread) !is null) {
            thread = null;
            LockSupport.unpark(w);
        }
        return null;
    }

    bool isReleasable() {
        if (ThreadEx.interrupted())
            interrupted = true;
        return ((interrupted && interruptible) ||
                (deadline != 0L &&
                 (nanos <= 0L ||
                  (nanos = deadline - DateTimeHelper.currentTimeMillis()) <= 0L)) ||
                thread is null);
    }
    bool block() {
        while (!isReleasable()) {
            if (deadline == 0L)
                LockSupport.park(this);
            else
                LockSupport.parkNanos(this, nanos);
        }
        return true;
    }
    final override bool isLive() { return thread !is null; }
}


/**
 * Singleton delay scheduler, used only for starting and
 * cancelling tasks.
 */


final class Delayer {
    static ScheduledFuture!(Void) delay(Runnable command, Duration delay) {
        return delayer.schedule(command, delay);
    }

    __gshared ScheduledThreadPoolExecutor delayer;
    shared static this() {
        delayer = new ScheduledThreadPoolExecutor(1, new DaemonThreadFactory());

        delayer.setRemoveOnCancelPolicy(true);
    }
}

final class DaemonThreadFactory : ThreadFactory {
    ThreadEx newThread(Runnable runnable) {
        ThreadEx t = new ThreadEx(runnable, "CompletableFutureDelayScheduler");
        t.isDaemon = true;
        // t.name = "CompletableFutureDelayScheduler";
        return t;
    }
}

// Little class-ified lambdas to better support monitoring

final class DelayedExecutor : Executor {
    Duration delay;
    Executor executor;

    this(Duration delay, Executor executor) {
        this.delay = delay; this.executor = executor;
    }
    void execute(Runnable r) {
        Delayer.delay(new TaskSubmitter(executor, r), delay);
    }
}

/** Action to submit user task */
final class TaskSubmitter : Runnable {
    Executor executor;
    Runnable action;
    this(Executor executor, Runnable action) {
        this.executor = executor;
        this.action = action;
    }
    void run() { executor.execute(action); }
}

/** Action to completeExceptionally on timeout */
final class Timeout : Runnable {
    AbstractCompletableFuture f;

    this(AbstractCompletableFuture f) { this.f = f; }

    void run() {
        if (f !is null && !f.isDone())
            f.completeExceptionally(new TimeoutException());
    }
}

/** Action to complete on timeout */
final class DelayedCompleter(U) : Runnable {
    CompletableFuture!(U) f;
    U u;

    this(CompletableFuture!(U) f, U u) { this.f = f; this.u = u; }

    void run() {
        if (f !is null) {
            f.complete(u);
        }
    }
}



/**
 * A subclass that just throws UOE for most non-CompletionStage methods.
 */
final class MinimalStage(T) : CompletableFuture!(T) {
    this() { }
    this(Object r) { super(r); }
    override public CompletableFuture!(U) newIncompleteFuture(U)() {
        return new MinimalStage!(U)(); }
    override public T get() {
        throw new UnsupportedOperationException(); }
    override public T get(Duration timeout) {
        throw new UnsupportedOperationException(); }
    override public T getNow(T valueIfAbsent) {
        throw new UnsupportedOperationException(); }
    override public T join() {
        throw new UnsupportedOperationException(); }
    override public bool complete(T value) {
        throw new UnsupportedOperationException(); }
    override public bool completeExceptionally(Throwable ex) {
        throw new UnsupportedOperationException(); }
    override public bool cancel(bool mayInterruptIfRunning) {
        throw new UnsupportedOperationException(); }
    override public void obtrudeValue(T value) {
        throw new UnsupportedOperationException(); }
    override public void obtrudeException(Throwable ex) {
        throw new UnsupportedOperationException(); }
    override public bool isDone() {
        throw new UnsupportedOperationException(); }
    override public bool isCancelled() {
        throw new UnsupportedOperationException(); }
    override public bool isCompletedExceptionally() {
        throw new UnsupportedOperationException(); }
    override public int getNumberOfDependents() {
        throw new UnsupportedOperationException(); }
    override public CompletableFuture!(T) completeAsync
        (Supplier!(T) supplier, Executor executor) {
        throw new UnsupportedOperationException(); }
    override public CompletableFuture!(T) completeAsync
        (Supplier!(T) supplier) {
        throw new UnsupportedOperationException(); }
    override public CompletableFuture!(T) orTimeout
        (Duration timeout) {
        throw new UnsupportedOperationException(); }
    override public CompletableFuture!(T) completeOnTimeout
        (T value, Duration timeout) {
        throw new UnsupportedOperationException(); }
    override public CompletableFuture!(T) toCompletableFuture() {
        Object r;
        if ((r = result) !is null)
            return new CompletableFuture!(T)(encodeRelay(r));
        else {
            CompletableFuture!(T) d = new CompletableFuture!T();
            unipush(new UniRelay!(T,T)(d, this));
            return d;
        }
    }
}



/**
 * Null-checks user executor argument, and translates uses of
 * commonPool to ASYNC_POOL in case parallelism disabled.
 */
Executor screenExecutor(Executor e) {
    if (!USE_COMMON_POOL && e is ForkJoinPool.commonPool())
        return ASYNC_POOL;
    if (e is null) throw new NullPointerException();
    return e;
}


/**
 * Returns a new CompletableFuture that is asynchronously completed
 * by a task running in the {@link ForkJoinPool#commonPool()} with
 * the value obtained by calling the given Supplier.
 *
 * @param supplier a function returning the value to be used
 * to complete the returned CompletableFuture
 * @param <U> the function's return type
 * @return the new CompletableFuture
 */
CompletableFuture!(U) supplyAsync(U)(Supplier!(U) supplier) {
    return asyncSupplyStage(ASYNC_POOL, supplier);
}

/**
 * Returns a new CompletableFuture that is asynchronously completed
 * by a task running in the given executor with the value obtained
 * by calling the given Supplier.
 *
 * @param supplier a function returning the value to be used
 * to complete the returned CompletableFuture
 * @param executor the executor to use for asynchronous execution
 * @param <U> the function's return type
 * @return the new CompletableFuture
 */
CompletableFuture!(U) supplyAsync(U)(Supplier!(U) supplier, Executor executor) {
    return asyncSupplyStage(screenExecutor(executor), supplier);
}

/**
 * Returns a new CompletableFuture that is asynchronously completed
 * by a task running in the {@link ForkJoinPool#commonPool()} after
 * it runs the given action.
 *
 * @param runnable the action to run before completing the
 * returned CompletableFuture
 * @return the new CompletableFuture
 */
CompletableFuture!(Void) runAsync(Runnable runnable) {
    if(runnable is null) 
        throw new NullPointerException();
    return asyncRunStage(ASYNC_POOL, { runnable.run(); });
}


CompletableFuture!(Void) runAsync(Action act) {
    if(act is null) 
        throw new NullPointerException();
    return asyncRunStage(ASYNC_POOL, act);
}

/**
 * Returns a new CompletableFuture that is asynchronously completed
 * by a task running in the given executor after it runs the given
 * action.
 *
 * @param runnable the action to run before completing the
 * returned CompletableFuture
 * @param executor the executor to use for asynchronous execution
 * @return the new CompletableFuture
 */
CompletableFuture!(Void) runAsync(Runnable runnable, Executor executor) {
    if(runnable is null) 
        throw new NullPointerException();
    return asyncRunStage(screenExecutor(executor), { runnable.run(); });
}

/**
 * Returns a new CompletableFuture that is already completed with
 * the given value.
 *
 * @param value the value
 * @param <U> the type of the value
 * @return the completed CompletableFuture
 */
CompletableFuture!(U) completedFuture(U)(U value) {
    return new CompletableFuture!(U)((value is null) ? NIL : value);
}    

/* ------------- Zero-input Async forms -------------- */

CompletableFuture!(U) asyncSupplyStage(U)(Executor e,
                                                 Supplier!(U) f) {
    if (f is null) throw new NullPointerException();
    CompletableFuture!(U) d = new CompletableFuture!(U)();
    e.execute(new AsyncSupply!(U)(d, f));
    return d;
}


CompletableFuture!(Void) asyncRunStage(Executor e, Action f) {
    if (f is null) throw new NullPointerException();
    CompletableFuture!(Void) d = new CompletableFuture!(Void)();
    e.execute(new AsyncRun(d, f));
    return d;
}


/**
 * Returns a new Executor that submits a task to the given base
 * executor after the given delay (or no delay if non-positive).
 * Each delay commences upon invocation of the returned executor's
 * {@code execute} method.
 *
 * @param delay how long to delay, in units of {@code unit}
 * @param unit a {@code TimeUnit} determining how to interpret the
 *        {@code delay} parameter
 * @param executor the base executor
 * @return the new delayed executor
 * @since 9
 */
Executor delayedExecutor(Duration delay, Executor executor) {
    if (executor is null)
        throw new NullPointerException();
    return new DelayedExecutor(delay, executor);
}

/**
 * Returns a new Executor that submits a task to the default
 * executor after the given delay (or no delay if non-positive).
 * Each delay commences upon invocation of the returned executor's
 * {@code execute} method.
 *
 * @param delay how long to delay, in units of {@code unit}
 * @param unit a {@code TimeUnit} determining how to interpret the
 *        {@code delay} parameter
 * @return the new delayed executor
 * @since 9
 */
Executor delayedExecutor(Duration delay) {
    return new DelayedExecutor(delay, ASYNC_POOL);
}

/**
 * Returns a new CompletionStage that is already completed with
 * the given value and supports only those methods in
 * interface {@link CompletionStage}.
 *
 * @param value the value
 * @param <U> the type of the value
 * @return the completed CompletionStage
 * @since 9
 */
CompletionStage!(U) completedStage(U)(U value) {
    return new MinimalStage!(U)((value is null) ? NIL : value);
}

/**
 * Returns a new CompletableFuture that is already completed
 * exceptionally with the given exception.
 *
 * @param ex the exception
 * @param <U> the type of the value
 * @return the exceptionally completed CompletableFuture
 * @since 9
 */
CompletableFuture!(U) failedFuture(U)(Throwable ex) {
    if (ex is null) throw new NullPointerException();
    return new CompletableFuture!(U)(new AltResult(ex));
}

/**
 * Returns a new CompletionStage that is already completed
 * exceptionally with the given exception and supports only those
 * methods in interface {@link CompletionStage}.
 *
 * @param ex the exception
 * @param <U> the type of the value
 * @return the exceptionally completed CompletionStage
 * @since 9
 */
CompletionStage!(U) failedStage(U)(Throwable ex) {
    if (ex is null) throw new NullPointerException();
    return new MinimalStage!(U)(new AltResult(ex));
}