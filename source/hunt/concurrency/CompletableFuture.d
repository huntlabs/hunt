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

import core.thread;
import core.time;
import std.conv;
import std.concurrency : initOnce;


// Modes for Completion.tryFire. Signedness matters.
enum int SYNC   =  0;
enum int ASYNC  =  1;
enum int NESTED = -1;


/** The encoding of the null value. */
__gshared AltResult NIL; // = new AltResult(null);

/* ------------- Async task preliminaries -------------- */

private static bool USE_COMMON_POOL() {
    return ForkJoinPool.getCommonPoolParallelism() > 1;
}

/**
 * Default executor -- ForkJoinPool.commonPool() unless it cannot
 * support parallelism.
 */
private static Executor ASYNC_POOL() {
    __gshared Executor inst;
    return initOnce!inst({
        Executor e;
        if(USE_COMMON_POOL){
            e = ForkJoinPool.commonPool();
        } else {
            e = new ThreadPerTaskExecutor();
        }
        return e;
    }());
}


shared static this() {
    NIL = new AltResult(null);
}


/**
*/
abstract class AbstractCompletableFuture {
    shared bool _isDone = false;
    bool _isNull = true;

    AltResult altResult;

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
        return _isDone;
    }


    /**
     * Returns {@code true} if this CompletableFuture was cancelled
     * before it completed normally.
     *
     * @return {@code true} if this CompletableFuture was cancelled
     * before it completed normally
     */
    bool isCancelled() {
        AltResult ar = altResult;
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
        // Object r = result;
        // AltResult ar = cast(AltResult)r;
        // return ar !is null && r !is NIL;

        return altResult !is null && altResult !is NIL;
    }

    bool isCompletedSuccessfully() {
        return _isDone && altResult is null;
    }

    alias isFaulted = isCompletedExceptionally;
    alias isCompleted = isDone;
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
 * other methods, so the behavior of one method is not impacted
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

static if(is(T == void)) {

    alias ConsumerT = Action;  
    alias BiConsumerT = Action1!(Throwable);

    alias FunctionT(V) = Func!(V);
    
    this(bool completed = false) {
        if(completed) completeValue!false();
    }

} else {

    alias ConsumerT = Consumer!(T);  
    alias BiConsumerT = Action2!(T, Throwable);
    alias FunctionT(V) = Func1!(T, V);

    private T result;       // Either the result or boxed AltResult

    /**
     * Creates a new complete CompletableFuture with given encoded result.
     */
    this(T r) {
        completeValue!false(r);
    }    
}
    /**
     * Creates a new incomplete CompletableFuture.
     */
    this() {
    }    

    this(AltResult r) {
        completeValue!false(r);
    }

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


    // final bool internalComplete(T r) { // CAS from null to r
    //     // return AtomicHelper.compareAndSet(this.result, null, r);
    //     if(AtomicHelper.compareAndSet(_isDone, false, true)) {
    //         this.result = r;
    //         _isNull = false;
    //         return true;
    //     }
    //     return false;
    // }

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
    final bool completeNull(bool useCas = true)() {
        // return AtomicHelper.compareAndSet(this.result, null, NIL);
        static if(useCas) {
            if(AtomicHelper.compareAndSet(_isDone, false, true)) {
                _isNull = true;
                altResult = NIL;
                return true;
            }
        } else {
            if(!_isDone) {
                _isNull = true;
                altResult = NIL;
                _isDone = true;
                return true;
            }
        }

        return false;
    }

    /** Returns the encoding of the given non-exceptional value. */
    // final Object encodeValue(T t) {
    //     return (t is null) ? NIL : cast(Object)t;
    // }

    /** Completes with a non-exceptional result, unless already completed. */

static if(is(T == void)) {
    final bool completeValue(bool useCas = true)() {
        // return AtomicHelper.compareAndSet(this.result, null, (t is null) ? NIL : cast(Object)t);
        static if(useCas) {
            if(AtomicHelper.compareAndSet(_isDone, false, true)) {
                _isNull = false;
                return true;
            }
        }
        else {
            if(!_isDone) {
                _isDone = true;
                _isNull = false;
                return true;
            }
        }
        return false;
    }
} else {
    final bool completeValue(bool useCas = true)(T t) {
        // return AtomicHelper.compareAndSet(this.result, null, (t is null) ? NIL : cast(Object)t);
        static if(useCas) {
            if(AtomicHelper.compareAndSet(_isDone, false, true)) {
                this.result = t;
                _isNull = false;
                return true;
            }
        }
        else {
            if(!_isDone) {
                this.result = t;
                _isDone = true;
                _isNull = false;
                return true;
            }
        }
        return false;
    }
}    

    final bool completeValue(bool useCas = true)(AltResult r) {
        static if(useCas) {
            if(AtomicHelper.compareAndSet(_isDone, false, true)) {
                altResult = r;
                return true;
            }
        } else {
            if(!_isDone) {
                _isDone = true;
                altResult = r;
                return true;
            }
        }
        return false;
    }

    /** Completes with an exceptional result, unless already completed. */
    private final bool completeThrowable(bool useCas = true)(Throwable x) {
        // return AtomicHelper.compareAndSet(this.result, null, encodeThrowable(x));
        static if(useCas) {
            if(AtomicHelper.compareAndSet(_isDone, false, true)) {
                altResult = encodeThrowable(x);
                return true;
            }
        } else {
            if(!_isDone) {
                _isDone = true;
                altResult = encodeThrowable(x);
                return true;
            }
        }
        return false;
    }


    /**
     * Completes with the given (non-null) exceptional result as a
     * wrapped CompletionException unless it is one already, unless
     * already completed.  May complete with the given Object r
     * (which must have been the result of a source future) if it is
     * equivalent, i.e. if this is a simple propagation of an
     * existing CompletionException.
     */
    private final bool completeThrowable(bool useCas = true)(Throwable x, AltResult r) {
        // return AtomicHelper.compareAndSet(this.result, null, encodeThrowable(x, r));
        static if(useCas) {
            if(AtomicHelper.compareAndSet(_isDone, false, true)) {
                _isDone = true;
                altResult = encodeThrowable(x, r);
                return true;
            }
        } else {
            if(!_isDone) {
                _isDone = true;
                altResult = encodeThrowable(x, r);
                return true;
            }
        }
        return false;
    }

    /**
     * Returns the encoding of the given arguments: if the exception
     * is non-null, encodes as AltResult.  Otherwise uses the given
     * value, boxed as NIL if null.
     */
    // Object encodeOutcome(T t, Throwable x) {
    //     return (x is null) ? (t is null) ? NIL : cast(Object)t : encodeThrowable(x);
    // }


    /**
     * Completes with r or a copy of r, unless already completed.
     * If exceptional, r is first coerced to a CompletionException.
     */
    // final bool completeRelay(T r, AltResult ar) {
    //     // return AtomicHelper.compareAndSet(this.result, null, encodeRelay(r));

    //     if(AtomicHelper.compareAndSet(_isDone, false, true)) {
    //         // altResult = encodeThrowable(x, r);
    //         // this.result = encodeRelay(r);
    //         implementationMissing(false);
    //         return true;
    //     }
    //     return false;
    // }


    /* ------------- Base Completion classes and operations -------------- */


    /**
     * Pops and tries to trigger all reachable dependents.  Call only
     * when known to be done.
     */
    protected final override void postComplete() {
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
    protected final override void cleanStack() {
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
    protected final override void unipush(Completion c) {
        if (c !is null) {
            while (!tryPushStack(c)) {
                if (_isDone) {
                    AtomicHelper.store(c.next, null);
                    break;
                }
            }
            if (_isDone)
                c.tryFire(SYNC);
        }
    }

    /**
     * Post-processing by dependent after successful UniCompletion tryFire.
     * Tries to clean stack of source a, and then either runs postComplete
     * or returns this to caller, depending on mode.
     */
    private final CompletableFuture!(T) postFire(AbstractCompletableFuture a, int mode) {

        // infof("this: %s, h: %s", cast(Object*)this, typeid(this.stack).name);

        if (a !is null && a.stack !is null) {
            bool done = a._isDone;
            if (!done)
                a.cleanStack();
            if (mode >= 0 && (done || a._isDone))
                a.postComplete();
        }

        // if(stack is null)
        //     infof("this: %s, mode=%d, result: %s, stack: null", cast(Object*)this, mode, result is null);
        // else
        //     infof("this: %s, mode=%d, result: %s, stack: %s", cast(Object*)this, mode, result is null, typeid(this.stack).name);

        if (_isDone && stack !is null) {
            if (mode < 0)
                return this;
            else
                postComplete();
        }
        return null;
    }

    private CompletableFuture!(V) uniApplyStage(V)(Executor e, FunctionT!(V) f) {
        if (f is null) throw new NullPointerException();
        if (_isDone) {
            return uniApplyNow!(V)(e, f);
        }
        CompletableFuture!(V) d = newIncompleteFuture!(V)();
        unipush(new UniApply!(T,V)(e, d, this, f));
        return d;
    }


    private CompletableFuture!(V) uniApplyNow(V)(Executor e, FunctionT!(V) f) {

        CompletableFuture!(V) d = newIncompleteFuture!(V)();

        AltResult ar = this.altResult;
        if(ar !is null) {
            Throwable x = ar.ex;
            if (x !is null) {
                d.completeThrowable!false(x, ar);
                return d;
            }
        } 

        try {
            if (e !is null) {
                e.execute(new UniApply!(T, V)(null, d, this, f));
            } else {
static if(is(T == void)) {
                d.completeValue!false(f());
} else {
                d.completeValue!false(f(this.result));
}
            }
        } catch (Throwable ex) {
            d.completeThrowable!false(ex);
        }
        return d;
    }


    private CompletableFuture!(void) uniAcceptStage(Executor e,
                                                   ConsumerT f) {
        if (f is null) throw new NullPointerException();
        if (isDone)
            return uniAcceptNow(e, f);
        CompletableFuture!(void) d = newIncompleteFuture!(void)();
        unipush(new UniAccept!(T)(e, d, this, f));
        return d;
    }

    private CompletableFuture!(void) uniAcceptNow(Executor e, ConsumerT f) {
        Throwable x;
        CompletableFuture!(void) d = newIncompleteFuture!(void)();
        AltResult ar = altResult;
        if (ar !is null) {
            if ((x = ar.ex) !is null) {
                d.completeValue!false(encodeThrowable(x, ar));
                return d;
            }
            // r = null;
        }

        try {
            if (e !is null) {
                e.execute(new UniAccept!(T)(null, d, this, f));
            } else {

static if(is(T == void)) {
                f();
} else {
                T t = this.result;
                f(t);
} 
                d.completeValue!false(NIL);
            }
        } catch (Throwable ex) {
            d.completeThrowable!false(ex);
        }
        return d;
    }


    private CompletableFuture!(void) uniRunStage(Executor e, Runnable f) {
        if (f is null) throw new NullPointerException();
        if (!isDone())
            return uniRunNow(altResult, e, f);
        CompletableFuture!(void) d = newIncompleteFuture!(void)();
        unipush(new UniRun!(T)(e, d, this, f));
        return d;
    }

    private CompletableFuture!(void) uniRunNow(AltResult ar, Executor e, Runnable f) {
        Throwable x;
        CompletableFuture!(void) d = newIncompleteFuture!(void)();
        if (ar !is null && (x = ar.ex) !is null)
            d.completeValue!false(encodeThrowable(x, ar));
        else
            try {
                if (e !is null) {
                    e.execute(new UniRun!(T)(null, d, this, f));
                } else {
                    f.run();
                    d.completeNull();
                }
            } catch (Throwable ex) {
                d.completeThrowable!false(ex);
            }
        return d;
    }


    final bool uniWhenComplete(CompletableFuture!(T) r,
                                  BiConsumerT f,
                                  UniWhenComplete!(T) c) {
        Throwable x = null;
        if (!_isDone) {
            try {
                if (c !is null && !c.claim())
                    return false;
                AltResult ar = r.altResult;
                if (ar !is null) {
                    x = ar.ex;
                    warning("Need to check");
static if(is(T == void)) {
                    f(x);
} else {
                    f(T.init, x);
}                    
                    if (x is null) {
                        completeValue(ar);
                    }
                } else {
static if(is(T == void)) {
                    f(x);
                    completeValue();
} else {
                    T t = r.result;
                    f(t, x);
                    completeValue(t);
}                    
                }

                if (x is null) {
                    return true;
                }
            } catch (Throwable ex) {
                if (x is null)
                    x = ex;
                else if (x !is ex)
                    x.next = ex;
            }

            completeThrowable(x, r.altResult);
        }
        return true;
    }

    private CompletableFuture!(T) uniWhenCompleteStage(
        Executor e, BiConsumerT f) {
        if (f is null) throw new NullPointerException();
        CompletableFuture!(T) d = newIncompleteFuture!(T)();
        Object r;
        if (!isDone)
            unipush(new UniWhenComplete!(T)(e, d, this, f));
        else if (e is null)
            d.uniWhenComplete(this, f, null);
        else {
            try {
                e.execute(new UniWhenComplete!(T)(null, d, this, f));
            } catch (Throwable ex) {
                d.completeThrowable!false(ex);
            }
        }
        return d;
    }

    final bool uniHandle(S)(CompletableFuture!(S) r, BiFunction!(S, Throwable, T) f,
                            UniHandle!(S,T) c) {
        Throwable x;
        if (!isDone()) {
            try {
                if (c !is null && !c.claim())
                    return false;
                S s;
                AltResult ar = r.altResult;
                if (ar !is null) {
                    x = ar.ex;
                    static if(is(S == class) || is(S == interface)) {
                        s = null;
                    } else {
                        warning("to check");
                        s = S.init;
                    }
                } else {
                    x = null;
                    s = r.result;
                }
                completeValue(f(s, x));
            } catch (Throwable ex) {
                completeThrowable(ex);
            }
        }
        return true;
    }

    private CompletableFuture!(V) uniHandleStage(V)(Executor e, 
                BiFunction!(T, Throwable, V) f) {

        if (f is null) throw new NullPointerException();
        CompletableFuture!(V) d = newIncompleteFuture!(V)();

        if (!isDone())
            unipush(new UniHandle!(T,V)(e, d, this, f));
        else if (e is null)
            d.uniHandle!(T)(this, f, null);
        else {
            try {
                e.execute(new UniHandle!(T,V)(null, d, this, f));
            } catch (Throwable ex) {
                d.completeThrowable!false(ex);
            }
        }
        return d;
    }

 
    final bool uniExceptionally(CompletableFuture!(T) r,
                                   Function!(Throwable, T) f,
                                   UniExceptionally!(T) c) {
        Throwable x;
        if (!isDone()) {
            try {
                AltResult ar = r.altResult;
                if (ar !is null && (x = ar.ex) !is null) {
                    if (c !is null && !c.claim())
                        return false;
static if(is(T == void)) {
                    f(x);
                    completeValue();

} else {
                    completeValue(f(x));
}                        
                } else {
                    // internalComplete(r);
static if(is(T == void)) {
                    completeValue();
} else {
                    completeValue(r.result);
}                    
                }
            } catch (Throwable ex) {
                completeThrowable(ex);
            }
        }
        return true;
    }

    private CompletableFuture!(T) uniExceptionallyStage(Function!(Throwable, T) f) {
        if (f is null) throw new NullPointerException();
        CompletableFuture!(T) d = newIncompleteFuture!(T)();
        if (!isDone())
            unipush(new UniExceptionally!(T)(d, this, f));
        else
            d.uniExceptionally(this, f, null);
        return d;
    }

    private MinimalStage!(T) uniAsMinimalStage() {
        if (isDone()) {
            if(isFaulted())
                return new MinimalStage!(T)(this.altResult);
            else {
static if(is(T == void)) {
                return new MinimalStage!(T)(true);
} else {
                return new MinimalStage!(T)(this.result);
}                
            }
        }
        MinimalStage!(T) d = new MinimalStage!(T)();
        unipush(new UniRelay!(T,T)(d, this));
        return d;
    }

    private CompletableFuture!(V) uniComposeStage(V)(Executor e, 
                FunctionT!(CompletionStage!(V)) f) {

        if (f is null) throw new NullPointerException();
        CompletableFuture!(V) d = newIncompleteFuture!(V)();
        Throwable x;
        if (!isDone())
            unipush(new UniCompose!(T,V)(e, d, this, f));
        else if (e is null) {
            T t = this.result;
            AltResult ar = this.altResult;
            if (ar !is null) {
                if ((x = ar.ex) !is null) {
                    d.completeThrowable!false(x, ar);
                    return d;
                }
                warning("To check");
                t = T.init;
            }
            
            try {
                auto gg = f(t).toCompletableFuture();
                CompletableFuture!(V) g = cast(CompletableFuture!(V))gg;
                if(g is null && gg !is null) {
                    warningf("bad cast");
                }

                if (g.isDone())
                    d.completeValue!false(g.result);
                else {
                    g.unipush(new UniRelay!(V,V)(d, g));
                }
            } catch (Throwable ex) {
                d.completeThrowable!false(ex);
            }
        }
        else
            try {
                e.execute(new UniCompose!(T,V)(null, d, this, f));
            } catch (Throwable ex) {
                d.completeThrowable!false(ex);
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
            while (!_isDone) {
                if (tryPushStack(c)) {
                    if (!b._isDone)
                        b.unipush(new CoCompletion(c));
                    else if (_isDone)
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
            if (!b.isDone())
                b.cleanStack();
            if (mode >= 0 && b.isDone())
                b.postComplete();
        }
        return postFire(a, mode);
    }


    final bool biApply(R, S)(CompletableFuture!R r, CompletableFuture!S s,
                                BiFunction!(R, S, T) f,
                                BiApply!(R,S,T) c) {
        Throwable x;

        AltResult ar = r.altResult;
        AltResult ars = s.altResult;
        R rr = r.result;
        S ss = s.result;

        tryComplete: if (!isDone) {
            if (ar !is null) {
                if ((x = ar.ex) !is null) {
                    completeThrowable(x, ar);
                    goto tryComplete;
                }
                warning("To check");
                rr = R.init;
            }
            if (ars !is null) {
                if ((x = ars.ex) !is null) {
                    completeThrowable(x, ars);
                    goto tryComplete;
                }
                warning("To check");
                ss = S.init;
            }

            try {
                if (c !is null && !c.claim())
                    return false;
                completeValue(f(rr, ss));
            } catch (Throwable ex) {
                completeThrowable(ex);
            }
        }
        return true;
    }

    private CompletableFuture!(V) biApplyStage(U,V)(
        Executor e, CompletionStage!(U) o, BiFunction!(T, U, V) f) {

        if (f is null)
            throw new NullPointerException();
        CompletableFuture!(U) b = cast(CompletableFuture!(U))o.toCompletableFuture(); 
        if (b is null)
            throw new NullPointerException();

        CompletableFuture!(V) d = newIncompleteFuture!(V)();

        if (!isDone() || !b.isDone())
            bipush(b, new BiApply!(T,U,V)(e, d, this, b, f));
        else if (e is null)
            d.biApply!(T, U)(this, b, f, null);
        else
            try {
                e.execute(new BiApply!(T,U,V)(null, d, this, b, f));
            } catch (Throwable ex) {
                d.completeThrowable!false(ex);
            }
        return d;
    }


    final bool biAccept(R, S)(CompletableFuture!R r, CompletableFuture!S s,
                                 BiConsumer!(R,S) f,
                                 BiAccept!(R, S) c) {
        Throwable x;

        AltResult ar = r.altResult;
        AltResult ars = s.altResult;
        R rr = r.result;
        S ss = s.result;

        tryComplete: if (!isDone()) {
            if (ar !is null) {
                if ((x = ar.ex) !is null) {
                    completeThrowable(x, ar);
                    goto tryComplete;
                }
                warning("To check");
                rr = R.init;
            }
            if (ars !is null) {
                if ((x = ars.ex) !is null) {
                    completeThrowable(x, ars);
                    goto tryComplete;
                }
                warning("To check");
                ss = S.init;
            }

            try {
                if (c !is null && !c.claim())
                    return false;
                f(rr, ss);
                completeNull();
            } catch (Throwable ex) {
                completeThrowable(ex);
            }
        }
        return true;
    }

    private CompletableFuture!(void) biAcceptStage(U)(Executor e, 
                CompletionStage!(U) o, BiConsumer!(T, U) f) {
            
        if (f is null)
            throw new NullPointerException();

        CompletableFuture!(U) b = cast(CompletableFuture!(U))o.toCompletableFuture(); 
        if (b is null)
            throw new NullPointerException();

        CompletableFuture!(void) d = newIncompleteFuture!(void)();
        if (!isDone() || !b.isDone())
            bipush(b, new BiAccept!(T,U)(e, d, this, b, f));
        else if (e is null)
            d.biAccept!(T, U)(this, b, f, null);
        else
            try {
                e.execute(new BiAccept!(T,U)(null, d, this, b, f));
            } catch (Throwable ex) {
                d.completeThrowable!false(ex);
            }
        return d;
    }

    
    final bool biRun(AbstractCompletableFuture r, AbstractCompletableFuture s, 
                    Runnable f, IUniCompletion c) {
        Throwable x;
        if (!isDone()) {
            AltResult ar = r.altResult;
            AltResult ars = s.altResult;
            if(ar !is null && (x = ar.ex) !is null){
                completeThrowable(x, ar);
            } else if(ars !is null && (x = ars.ex) !is null){
                completeThrowable(x, ars);
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

    private CompletableFuture!(void) biRunStage(U)(Executor e, CompletionStage!U o,
                                               Runnable f) {
        CompletableFuture!U b = cast(CompletableFuture!U)o.toCompletableFuture(); 
        if (f is null || b is null)
            throw new NullPointerException();
        CompletableFuture!(void) d = newIncompleteFuture!(void)();
        // if ((r = result) is null || (s = b.result) is null)
        if (!isDone() || !b.isDone())
            bipush(b, new BiRun!(T, U)(e, d, this, b, f));
        else if (e is null)
            d.biRun(this, b, f, null);
        else
            try {
                e.execute(new BiRun!(T, U)(null, d, this, b, f));
            } catch (Throwable ex) {
                d.completeThrowable!false(ex);
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
                if (_isDone) {
                    AtomicHelper.store(c.next, null);
                    break;
                }
            }
            if (_isDone)
                c.tryFire(SYNC);
            else
                b.unipush(new CoCompletion(c));
        }
    }

    private CompletableFuture!(V) orApplyStage(U, V)( // U : T,V
        Executor e, CompletionStage!(U) o, FunctionT!(V) f) {

        CompletableFuture!(U) b = cast(CompletableFuture!(U))o.toCompletableFuture();
        if (f is null || b is null)
            throw new NullPointerException();

        if(this._isDone)
            return uniApplyNow!(V)(e, f);
        else if(b._isDone) {
            return b.uniApplyNow!(V)(e, f);
        }
        // T r; CompletableFuture!T z;
        // if ((r = (z = this).result) !is null ||
        //     (r = (z = b).result) !is null)
        //     return z.uniApplyNow!(V)(e, f);

        CompletableFuture!(V) d = newIncompleteFuture!(V)();
        orpush(b, new OrApply!(T,U,V)(e, d, this, b, f));
        return d;
    }


    private CompletableFuture!(void) orAcceptStage(U)( // U : T
        Executor e, CompletionStage!(U) o, ConsumerT f) {
        CompletableFuture!(U) b;
        if (f is null || (b = cast(CompletableFuture!(U))o) is null)
            throw new NullPointerException();

        CompletableFuture!T z;
        if ((z = this).isDone() || (z = b).isDone())
            return z.uniAcceptNow(e, f);

        CompletableFuture!(void) d = newIncompleteFuture!(void)();
        orpush(b, new OrAccept!(T,U)(e, d, this, b, f));
        return d;
    }

    private CompletableFuture!(void) orRunStage(U)(Executor e, CompletionStage!U o,
                                               Runnable f) {
        AbstractCompletableFuture b;
        if (f is null || (b = o.toCompletableFuture()) is null)
            throw new NullPointerException();

        AbstractCompletableFuture z;
        if ((z = this).isDone() || (z = b).isDone())
            return z.uniRunNow(e, f);

        CompletableFuture!(void) d = newIncompleteFuture!(void)();
        orpush(b, new OrRun(e, d, this, b, f));
        return d;
    }


    /* ------------- Signallers -------------- */

    /**
     * Returns raw result after waiting, or null if interruptible and
     * interrupted.
     */
    private void waitingGet(bool interruptible) {
        Signaller q = null;
        bool queued = false;
        while (!isDone()) {
            if (q is null) {
                q = new Signaller(interruptible, Duration.zero, MonoTime.zero);
                ForkJoinWorkerThread th = cast(ForkJoinWorkerThread)Thread.getThis();
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
            if (!isDone())
                cleanStack();
        }
        if (isDone())
            postComplete();
    }

    /**
     * Returns raw result after waiting, or null if interrupted, or
     * throws TimeoutException on timeout.
     */
    private void timedGet(Duration timeout) {
        if (ThreadEx.interrupted())
            return;
            
        if (timeout <= Duration.zero) 
            throw new TimeoutException();

        MonoTime d = MonoTime.currTime + timeout;
        MonoTime deadline = (d == MonoTime.zero) ? MonoTime(1) : d; // avoid 0
        Signaller q = null;
        bool queued = false;
        while (!isDone()) { // similar to untimed
            if (q is null) {
                q = new Signaller(true, timeout, deadline);
                ForkJoinWorkerThread th = cast(ForkJoinWorkerThread)ThreadEx.currentThread();
                if (th !is null)
                    ForkJoinPool.helpAsyncBlocker(defaultExecutor(), q);
            }
            else if (!queued)
                queued = tryPushStack(q);
            else if (q.remaining <= Duration.zero)
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
        
        bool r = isDone();
        if (q !is null && queued) {
            q.thread = null;
            if (!r)
                cleanStack();
        }
        if (r)
            postComplete();
        if (r || (q !is null && q.interrupted))
            return ;
        
        throw new TimeoutException();
    }

    /* ------------- methods -------------- */

static if(is(T == void)) {
    void get() {
        if (!isDone()) waitingGet(true); {
            reportGet(this.altResult);
        }
    }
   
    void getNow() {
        if(isDone()) {
            reportJoin(this.altResult);
        }
    }

    bool complete() {
        bool triggered = completeValue();
        postComplete();
        return triggered;
    }
    
    void get(Duration timeout) {
        if (!isDone()) timedGet(timeout);
            reportGet(this.altResult);
    }

    void join() {
        if (!isDone()) waitingGet(false);
            reportJoin(this.altResult);
    }

} else {

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
        if (!isDone()) waitingGet(true);
        return reportGet!(T)(this.result, this.altResult);
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
        if (!isDone()) timedGet(timeout);
        return reportGet!T(this.result, this.altResult);
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
        if (!isDone()) waitingGet(false);
        return reportJoin!T(this.result, this.altResult);
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
        return (!isDone()) 
            ? valueIfAbsent 
            : reportJoin!T(this.result, this.altResult);
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
        bool triggered = completeValue(new AltResult(ex));
        postComplete();
        return triggered;
    }


    CompletableFuture!(U) thenApply(U)(FunctionT!(U) fn) {
        return uniApplyStage!(U)(cast(Executor)null, fn);
    }

    CompletableFuture!(U) thenApplyAsync(U)(FunctionT!(U) fn) {
        return uniApplyStage!(U)(defaultExecutor(), fn);
    }

    CompletableFuture!(U) thenApplyAsync(U)(FunctionT!(U) fn, Executor executor) {
        return uniApplyStage!(U)(screenExecutor(executor), fn);
    }

    CompletableFuture!(void) thenAccept(ConsumerT action) {
        return uniAcceptStage(cast(Executor)null, action);
    }

    CompletableFuture!(void) thenAcceptAsync(ConsumerT action) {
        return uniAcceptStage(defaultExecutor(), action);
    }

    CompletableFuture!(void) thenAcceptAsync(ConsumerT action,
                                                   Executor executor) {
        return uniAcceptStage(screenExecutor(executor), action);
    }

    CompletableFuture!(void) thenRun(Runnable action) {
        return uniRunStage(null, action);
    }

    CompletableFuture!(void) thenRunAsync(Runnable action) {
        return uniRunStage(defaultExecutor(), action);
    }

    CompletableFuture!(void) thenRunAsync(Runnable action,
                                                Executor executor) {
        return uniRunStage(screenExecutor(executor), action);
    }

    CompletableFuture!(V) thenCombine(U, V)(
        CompletionStage!(U) other,
        BiFunction!(T, U, V) fn) {
        return biApplyStage!(U, V)(null, other, fn);
    }

    CompletableFuture!(V) thenCombineAsync(U, V)(
        CompletionStage!(U) other,
        BiFunction!(T, U, V) fn) {
        return biApplyStage!(U, V)(defaultExecutor(), other, fn);
    }

    CompletableFuture!(V) thenCombineAsync(U, V)(
        CompletionStage!(U) other,
        BiFunction!(T, U, V) fn, Executor executor) {
        return biApplyStage!(U, V)(screenExecutor(executor), other, fn);
    }

    CompletableFuture!(void) thenAcceptBoth(U)(CompletionStage!(U) other, 
        BiConsumer!(T, U) action) {
        return biAcceptStage!(U)(null, other, action);
    }

    CompletableFuture!(void) thenAcceptBothAsync(U)(
        CompletionStage!(U) other,
        BiConsumer!(T, U) action) {
        return biAcceptStage!(U)(defaultExecutor(), other, action);
    }

    CompletableFuture!(void) thenAcceptBothAsync(U)(
        CompletionStage!(U) other,
        BiConsumer!(T, U) action, Executor executor) {
        return biAcceptStage!(U)(screenExecutor(executor), other, action);
    }

    CompletableFuture!(void) runAfterBoth(U)(CompletionStage!U other,
                                                Action action) {
        return biRunStage(null, other, new class Runnable {
            void run() {
                action();
            }
        } );
    }

    CompletableFuture!(void) runAfterBoth(U)(CompletionStage!U other,
                                                Runnable action) {
        return biRunStage(null, other, action);
    }

    CompletableFuture!(void) runAfterBothAsync(U)(CompletionStage!U other,
                                                     Runnable action) {
        return biRunStage(defaultExecutor(), other, action);
    }

    CompletableFuture!(void) runAfterBothAsync(U)(CompletionStage!U other,
                                                     Runnable action,
                                                     Executor executor) {
        return biRunStage(screenExecutor(executor), other, action);
    }

    CompletableFuture!(U) applyToEither(U)(
        CompletionStage!(T) other, FunctionT!(U) fn) {
        return orApplyStage!(T, U)(null, other, fn);
    }

    CompletableFuture!(U) applyToEitherAsync(U)(
        CompletionStage!(T) other, FunctionT!(U) fn) {
        return orApplyStage!(T, U)(defaultExecutor(), other, fn);
    }

    CompletableFuture!(U) applyToEitherAsync(U)(
        CompletionStage!(T) other, FunctionT!(U) fn,
        Executor executor) {
        return orApplyStage!(T, U)(screenExecutor(executor), other, fn);
    }

    CompletableFuture!(void) acceptEither(
        CompletionStage!(T) other, ConsumerT action) {
        return orAcceptStage(null, other, action);
    }

    CompletableFuture!(void) acceptEitherAsync(
        CompletionStage!(T) other, ConsumerT action) {
        return orAcceptStage(defaultExecutor(), other, action);
    }

    CompletableFuture!(void) acceptEitherAsync(
        CompletionStage!(T) other, ConsumerT action,
        Executor executor) {
        return orAcceptStage(screenExecutor(executor), other, action);
    }

    CompletableFuture!(void) runAfterEither(U)(CompletionStag!U other,
                                                  Runnable action) {
        return orRunStage(null, other, action);
    }

    CompletableFuture!(void) runAfterEitherAsync(U)(CompletionStage!U other,
                                                       Runnable action) {
        return orRunStage(defaultExecutor(), other, action);
    }

    CompletableFuture!(void) runAfterEitherAsync(U)(CompletionStage!U other,
                                                       Runnable action,
                                                       Executor executor) {
        return orRunStage(screenExecutor(executor), other, action);
    }

    CompletableFuture!(U) thenCompose(U)(
        FunctionT!(CompletionStage!(U)) fn) {
        return uniComposeStage!(U)(null, fn);
    }

    CompletableFuture!(U) thenComposeAsync(U)(
        FunctionT!(CompletionStage!(U)) fn) {
        return uniComposeStage!(U)(defaultExecutor(), fn);
    }

    CompletableFuture!(U) thenComposeAsync(U)(
        FunctionT!(CompletionStage!(U)) fn,
        Executor executor) {
        return uniComposeStage!(U)(screenExecutor(executor), fn);
    }

    CompletableFuture!(T) whenComplete(BiConsumerT action) {
        return uniWhenCompleteStage(null, action);
    }

    CompletableFuture!(T) whenCompleteAsync(BiConsumerT action) {
        return uniWhenCompleteStage(defaultExecutor(), action);
    }

    CompletableFuture!(T) whenCompleteAsync(
        BiConsumerT action, Executor executor) {
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
    CompletableFuture!(T) exceptionally(Function!(Throwable, T) fn) {
        return uniExceptionallyStage(fn);
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
        bool cancelled = (!_isDone) &&
            completeValue(new AltResult(new CancellationException()));
        postComplete();
        return cancelled || isCancelled();
    }

static if(is(T == void)) {
    void obtrudeValue() {
        _isNull = false;
        _isDone = true;
        postComplete();
    }

} else {
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
        // result = (value is null) ? NIL : value;

        static if(is(T == class) || is(T == interface)) {
            if(value is null) {
                this.altResult = NIL;
                this.result = null;
                _isNull = true;
            } else {
                this.result = value;
                _isNull = false;
            }
        } else {
            this.result = value;
            _isNull = false;
        }
        _isDone = true;

        postComplete();
    }


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
        altResult = new AltResult(ex);
        _isDone = true;
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

        int count = 0; // avoid call to getNumberOfDependents in case disabled
        for (Completion p = stack; p !is null; p = p.next)
            ++count;
        string s;
        if(!isDone) {
            s = (count == 0)
                ? "[Not completed]"
                : "[Not completed, " ~ count.to!string ~ " dependents]";
        } else {
            s = "[Completed normally]";
            AltResult ar = cast(AltResult)altResult;
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
        if (!_isDone) {
            ScheduledFuture!(void) f = Delayer.delay(new Timeout(this), timeout);
static if(is(T == void)) {
            whenComplete((Throwable ex) {
                if (ex is null && f !is null && !f.isDone())
                    f.cancel(false);
            });

} else {
            whenComplete((T ignore, Throwable ex) {
                if (ex is null && f !is null && !f.isDone())
                    f.cancel(false);
            });

}            
        }
        return this;
    }

static if(is(T == void)) {
    CompletableFuture!(T) completeOnTimeout(Duration timeout) {
        if (!_isDone) {
          ScheduledFuture!(void) f = 
            Delayer.delay(new DelayedCompleter!(T)(this), timeout);

            whenComplete((Throwable ex) {
                if (ex is null && f !is null && !f.isDone())
                    f.cancel(false);
            });            
        }
        return this;
    }

} else {

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
        if (!_isDone) {
          ScheduledFuture!(void) f = 
            Delayer.delay(new DelayedCompleter!(T)(this, value), timeout);

            whenComplete((T ignore, Throwable ex) {
                if (ex is null && f !is null && !f.isDone())
                    f.cancel(false);
            });            
        }
        return this;
    }

}
}



private final class AltResult { // See above
    Throwable ex;        // null only for NIL
    this(Throwable x) { this.ex = x; }
}



abstract class Completion : ForkJoinTask!(void),
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
    // final override void getRawResult()       { return null; }
    // final override void setRawResult(void v) {}
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


final class UniApply(T, V) : UniCompletion {

static if(is(T == void)) {
    alias FunctionT(V) = Func!(V);
} else {
    alias FunctionT(V) = Func1!(T, V);
}

    FunctionT!(V) fn;
    this(Executor executor, CompletableFuture!(V) dep,
             CompletableFuture!(T) src,
             FunctionT!(V) fn) {
        super(executor, dep, src); this.fn = fn;
    }

    final override CompletableFuture!(V) tryFire(int mode) {
        CompletableFuture!(V) d = cast(CompletableFuture!(V))dep; 
        CompletableFuture!(T) a = cast(CompletableFuture!(T))src;
        Throwable x; FunctionT!(V) f = fn;
        if (d is null || f is null || a is null || !a.isDone())
            return null;

        tryComplete: if (!d.isDone()) {
            AltResult ar = a.altResult;
            if (ar !is null) {
                if ((x = ar.ex) !is null) {
                    d.completeThrowable(x, ar);
                    goto tryComplete;
                }
            }
            try {
                if (mode <= 0 && !claim()) {
                    return null;
                }
                else {
static if(is(T == void)) {
                    d.completeValue(f());
} else {
                    T t = a.result;
                    d.completeValue(f(t));
}
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

static if(is(T == void)) {
    alias ConsumerT = Action;  
} else {
    alias ConsumerT = Consumer!(T);
}    
    ConsumerT fn;

    this(Executor executor, CompletableFuture!(void) dep,
              CompletableFuture!(T) src, ConsumerT fn) {
        super(executor, dep, src); this.fn = fn;
    }

    final override CompletableFuture!(void) tryFire(int mode) {
        CompletableFuture!(void) d = cast(CompletableFuture!(void))dep; 
        CompletableFuture!(T) a = cast(CompletableFuture!(T))src;
        Throwable x; 
        ConsumerT f = fn;
        if (d is null || f is null
            || a is null || !a.isDone())
            return null;

        tryComplete: if (!d._isDone) {
            AltResult ar = a.altResult;
            if (ar !is null) {
                if ((x = ar.ex) !is null) {
                    d.completeThrowable(x, ar);
                    goto tryComplete;
                }
            }

            try {
                if (mode <= 0 && !claim())
                    return null;
                else {
static if(is(T == void)) {
                    f();
} else {
                    T t = a.result;
                    f(t);
}                    
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

    this(Executor executor, CompletableFuture!(void) dep,
           CompletableFuture!(T) src, Runnable fn) {
        super(executor, dep, src); this.fn = fn;
    }

    final override CompletableFuture!(void) tryFire(int mode) {
        CompletableFuture!(void) d = cast(CompletableFuture!(void))dep;
        CompletableFuture!(T) a = cast(CompletableFuture!(T))src;
        Throwable x; 
        Runnable f = fn;
        if (d is null || f is null || a is null || !a.isDone())
            return null;

        if (!d.isDone()) {
            AltResult ar = a.altResult;
            if(ar !is null && (x = ar.ex) !is null) {
                d.completeThrowable(x, ar);
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
static if(is(T == void)) {

    alias ConsumerT = Action;  
    alias BiConsumerT = Action1!(Throwable);

} else {

    alias ConsumerT = Consumer!(T);  
    alias BiConsumerT = BiConsumer!(T, Throwable);
}

    BiConsumerT fn;
    this(Executor executor, CompletableFuture!(T) dep,
                    CompletableFuture!(T) src,
                    BiConsumerT fn) {
        super(executor, dep, src); this.fn = fn;
    }
    
    final override CompletableFuture!(T) tryFire(int mode) {
        CompletableFuture!(T) d = cast(CompletableFuture!(T))dep; 
        CompletableFuture!(T) a = cast(CompletableFuture!(T))src;
        BiConsumerT f = fn;

        if (d is null || f is null
            || a is null || !a.isDone()
            || !d.uniWhenComplete(a, f, mode > 0 ? null : this))
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
        BiFunction!(T, Throwable, V) f = fn;

        if (d is null || f is null || a is null || !a.isDone()
            || !d.uniHandle!(T)(a, f, mode > 0 ? null : this))
            return null;
        dep = null; src = null; fn = null;
        return d.postFire(a, mode);
    }
}


final class UniExceptionally(T) : UniCompletion {
    Function!(Throwable, T) fn;

    this(CompletableFuture!(T) dep, CompletableFuture!(T) src,
                     Function!(Throwable, T) fn) {
        super(null, dep, src); this.fn = fn;
    }

    final override CompletableFuture!(T) tryFire(int mode) { // never ASYNC
        // assert mode != ASYNC;
        CompletableFuture!(T) d = cast(CompletableFuture!(T))dep; 
        CompletableFuture!(T) a = cast(CompletableFuture!(T))src;
        Function!(Throwable, T) f = fn;

        if (d is null || f is null || a is null || !a.isDone()
            || !d.uniExceptionally(a, f, this))
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
        CompletableFuture!(U) d; CompletableFuture!(T) a;
        if ((d = cast(CompletableFuture!(U))dep) is null
            || (a = cast(CompletableFuture!(T))src) is null || !a.isDone())
            return null;

        if (!d.isDone()) {
            if(a.isFaulted())
                d.completeValue(a.altResult);
            else {
static if(is(T == void)) {
                d.completeValue();
} else {
                d.completeValue(a.result);
}                
            }
            // d.completeRelay(r);
        }
        src = null; dep = null;
        return d.postFire(a, mode);
    }
}

    
final class UniCompose(T, V) : UniCompletion {

static if(is(T == void)) {
    alias FunctionT(V) = Func!(V);
} else {
    alias FunctionT(V) = Func1!(T, V);
}

    FunctionT!(CompletionStage!(V)) fn;

    this(Executor executor, CompletableFuture!(V) dep,
               CompletableFuture!(T) src,
               FunctionT!(CompletionStage!(V)) fn) {
        super(executor, dep, src); this.fn = fn;
    }

    final override CompletableFuture!(V) tryFire(int mode) {
        CompletableFuture!(V) d = cast(CompletableFuture!(V))dep; 
        CompletableFuture!(T) a = cast(CompletableFuture!(T))src;
        FunctionT!(CompletionStage!(V)) f = fn;
        Throwable x;

        if (d is null || f is null
            || a is null || !a.isDone())
            return null;

        AltResult ar = a.altResult;
        T t = a.result;

        tryComplete: if (!d.isDone) {
            if (ar !is null) {
                if ((x = ar.ex) !is null) {
                    d.completeThrowable(x, ar);
                    goto tryComplete;
                }
                warning("To check");
                t = T.init;
            }

            try {
                if (mode <= 0 && !claim())
                    return null;
                CompletionStage!V ff = f(t);
                CompletableFuture!(V) g = cast(CompletableFuture!(V))(ff.toCompletableFuture());

                if (g.isDone()) {
                    if(g.isFaulted())
                        d.completeValue(g.altResult);
                    else
                        d.completeValue(g.result);
                }
                else {
                    g.unipush(new UniRelay!(V,V)(d, g));
                    if (!d.isDone())
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
        CompletableFuture!(V) d = cast(CompletableFuture!(V))dep;
        CompletableFuture!(T) a = cast(CompletableFuture!(T))src;
        CompletableFuture!(U) b = cast(CompletableFuture!(U))snd;
        BiFunction!(T, U, V) f = fn;

        if (d is null || f is null || a is null || !a.isDone()
            || b is null || !b.isDone()
            || !d.biApply!(T, U)(a, b, f, mode > 0 ? null : this))
            return null;

        dep = null; src = null; snd = null; fn = null;
        return d.postFire(a, b, mode);
    }
}

    
final class BiAccept(T, U) : BiCompletion {
    BiConsumer!(T, U) fn;

    this(Executor executor, CompletableFuture!(void) dep,
             CompletableFuture!T src, CompletableFuture!U snd,
             BiConsumer!(T, U) fn) {
        super(executor, dep, src, snd); this.fn = fn;
    }

    final override CompletableFuture!(void) tryFire(int mode) {
        CompletableFuture!(void) d = cast(CompletableFuture!(void))dep;
        CompletableFuture!T a = cast(CompletableFuture!(T))src;
        CompletableFuture!U b = cast(CompletableFuture!(U))snd;
        BiConsumer!(T, U) f = fn;
        if (d is null || f is null
            || a is null || !a.isDone()
            || b is null || !b.isDone()
            || !d.biAccept!(T, U)(a, b, f, mode > 0 ? null : this))
            return null;
        dep = null; src = null; snd = null; fn = null;
        return d.postFire(a, b, mode);
    }
}


final class BiRun(T, U) : BiCompletion {
    Runnable fn;

    this(Executor executor, CompletableFuture!(void) dep,
          CompletableFuture!(T) src, CompletableFuture!(U) snd,
          Runnable fn) {
        super(executor, dep, src, snd); this.fn = fn;
    }

    final override CompletableFuture!(void) tryFire(int mode) {
        CompletableFuture!(void) d = cast(CompletableFuture!(void))dep;
        CompletableFuture!(T) a = cast(CompletableFuture!(T))src;
        CompletableFuture!(U) b = cast(CompletableFuture!(U))snd;
        Runnable f = fn;
        if (d is null || f is null
            || a is null || !a.isDone()
            || b is null || !b.isDone()
            || !d.biRun(a, b, f, mode > 0 ? null : this))
            return null;

        dep = null; src = null; snd = null; fn = null;
        return d.postFire(a, b, mode);
    }
}

    
final class BiRelay : BiCompletion { // for And
    this(CompletableFuture!(void) dep,
            AbstractCompletableFuture src, AbstractCompletableFuture snd) {
        super(null, dep, src, snd);
    }

    final override CompletableFuture!(void) tryFire(int mode) {
        CompletableFuture!(void) d = cast(CompletableFuture!(void))dep;
        AbstractCompletableFuture a;
        AbstractCompletableFuture b;
        Throwable x;

        if (d is null || (a = src) is null || !a.isDone()
            || (b = snd) is null || !b.isDone())
            return null;

        if (!d.isDone()) {
            AltResult ar = a.altResult;
            AltResult ars = b.altResult;
            if(ar !is null && (x = ar.ex) !is null){
                d.completeThrowable(x, ar);
            } else if(ars !is null && (x = ars.ex) !is null){
                d.completeThrowable(x, ars);
            }
            else
                d.completeNull();
        }
        src = null; snd = null; dep = null;
        return d.postFire(a, b, mode);
    }
}

    
final class OrApply(T, U : T, V) : BiCompletion {

static if(is(T == void)) {
    alias FunctionT(V) = Func!(V);
} else {
    alias FunctionT(V) = Func1!(T, V);
}

    FunctionT!(V) fn;

    this(Executor executor, CompletableFuture!(V) dep,
            CompletableFuture!(T) src, CompletableFuture!(U) snd,
            FunctionT!(V) fn) {
        super(executor, dep, src, snd); this.fn = fn;
    }

    final override CompletableFuture!(V) tryFire(int mode) {
        CompletableFuture!(V) d = cast(CompletableFuture!(V))dep;
        CompletableFuture!(T) a = cast(CompletableFuture!(T))src;
        CompletableFuture!(U) b = cast(CompletableFuture!(U))snd;
        Throwable x; 
        FunctionT!(V) f = fn;
        
        if (d is null || f is null || a is null || b is null
            || (!a.isDone() && !b.isDone()))
            return null;

        T t;
        AltResult ar;
        if(a.isDone()) {
            t = a.result;
            ar = a.altResult;
        } else if(b.isDone()) {
            t = b.result;
            ar = b.altResult;
        } else {
            warning("unhandled status");
        }
            
        tryComplete: if (!d.isDone()) {
            try {
                if (mode <= 0 && !claim())
                    return null;
                
                if (ar !is null) {
                    if ((x = ar.ex) !is null) {
                        d.completeThrowable(x, ar);
                        goto tryComplete;
                    }
                }
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
static if(is(T == void)) {

    alias ConsumerT = Action;  

} else {

    alias ConsumerT = Consumer!(T);
}

    ConsumerT fn;
    this(Executor executor, CompletableFuture!(void) dep,
             CompletableFuture!(T) src, CompletableFuture!(U) snd,
             ConsumerT fn) {
        super(executor, dep, src, snd); this.fn = fn;
    }

    final override CompletableFuture!(void) tryFire(int mode) {
        CompletableFuture!(void) d = cast(CompletableFuture!(void))dep;
        CompletableFuture!(T) a = cast(CompletableFuture!(T))src;
        CompletableFuture!(U) b = cast(CompletableFuture!(U))snd;
        Object r; Throwable x; 
        ConsumerT f = fn;

        if (d is null || f is null || a is null || b is null
            || (!a.isDone() && !b.isDone()))
            return null;

static if(is(T == void)) {
        AltResult ar;
        if(a.isDone()) {
            ar = a.altResult;
        } else if(b.isDone()) {
            ar = b.altResult;
        } else {
            warning("unhandled status");
        }
} else {
        T t;
        AltResult ar;
        if(a.isDone()) {
            t = a.result;
            ar = a.altResult;
        } else if(b.isDone()) {
            t = b.result;
            ar = b.altResult;
        } else {
            warning("unhandled status");
        }
}


        tryComplete: if (!d.isDone()) {
            try {
                if (mode <= 0 && !claim())
                    return null;

                if (ar !is null) {
                    if ((x = ar.ex) !is null) {
                        d.completeThrowable(x, ar);
                        goto tryComplete;
                    }
                    r = null;
                }
static if(is(T == void)) {
                f();
} else {
                f(t);
}
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

    this(Executor executor, CompletableFuture!(void) dep,
          AbstractCompletableFuture src, AbstractCompletableFuture snd,
          Runnable fn) {
        super(executor, dep, src, snd); this.fn = fn;
    }

    final override CompletableFuture!(void) tryFire(int mode) {
        CompletableFuture!(void) d = cast(CompletableFuture!(void))dep;
        AbstractCompletableFuture a;
        AbstractCompletableFuture b;
        Throwable x; Runnable f = fn;
        if (d is null || f is null
            || (a = src) is null || (b = snd) is null
            || (!a.isDone() && !b.isDone()))
            return null;

        if (!d._isDone) {
            try {
                if (mode <= 0 && !claim())
                    return null;
                else {
                    AltResult ar;
                    if(a.isDone())
                        ar = a.altResult;
                    else if(b.isDone) 
                        ar = b.altResult;

                    if (ar !is null && (x = ar.ex) !is null)
                        d.completeThrowable(x, ar);
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

static class AnyOf(T) : Completion {
    CompletableFuture!(T) dep; 
    CompletableFuture!(T) src;
    CompletableFuture!(T)[] srcs;

    this(CompletableFuture!(T) dep, CompletableFuture!(T) src,
          CompletableFuture!(T)[] srcs) {
        this.dep = dep; this.src = src; this.srcs = srcs;
    }

    final override CompletableFuture!(T) tryFire(int mode) {
        // assert mode != ASYNC;
        CompletableFuture!(T) d = dep; 
        CompletableFuture!(T) a = src;
        CompletableFuture!(T)[] as = srcs;
        if (d is null || a is null || !a.isDone()
            || as is null)
            return null;

        dep = null; src = null; srcs = null;
        bool r=false;
        if(a.isFaulted())
            r = d.completeValue(a.altResult);
        else
            r = d.completeValue(a.result);
        if (r) {
            foreach (AbstractCompletableFuture b; as)
                if (b !is a)
                    b.cleanStack();
            if (mode < 0)
                return d;
            else
                d.postComplete();
        }
        return null;
    }

    final override bool isLive() {
        CompletableFuture!(T) d;
        return (d = dep) !is null && !d.isDone();
    }
}


/* ------------- Zero-input Async forms -------------- */


final class AsyncSupply(T) : ForkJoinTask!(void), Runnable, 
            AsynchronousCompletionTask {
        
    CompletableFuture!(T) dep; 
    Supplier!(T) fn;

    this(CompletableFuture!(T) dep, Supplier!(T) fn) {
        this.dep = dep; this.fn = fn;
    }

    // final override void getRawResult() { return null; }
    // final override void setRawResult(void v) {}
    final override bool exec() { run(); return false; }

    void run() {
        CompletableFuture!(T) d; Supplier!(T) f;
        if ((d = dep) !is null && (f = fn) !is null) {
            dep = null; fn = null;
            if (!d._isDone) {
                try {
static if(is(T == void)) {
                    f();
                    d.completeValue();
} else {
                    d.completeValue(f());
}                    
                } catch (Throwable ex) {
                    d.completeThrowable(ex);
                }
            }
            d.postComplete();
        }
    }
}


   
final class AsyncRun : ForkJoinTask!(void), Runnable, AsynchronousCompletionTask {
    CompletableFuture!(void) dep; Action fn;
    
    this(CompletableFuture!(void) dep, Action fn) {
        this.dep = dep; this.fn = fn;
    }

    // final override void getRawResult() { return null; }
    // final override void setRawResult(void v) {}
    final override bool exec() { run(); return false; }

    void run() {
        CompletableFuture!(void) d; Action f;
        if ((d = dep) !is null && (f = fn) !is null) {
            dep = null; fn = null;
            if (!d.isDone) {
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
    Duration remaining;              // remaining wait time if timed
    MonoTime deadline;           // non-zero if timed
    bool interruptible;
    bool interrupted;
    Thread thread;

    this(bool interruptible, Duration remaining, MonoTime deadline) {
        this.thread = Thread.getThis();
        this.interruptible = interruptible;
        this.remaining = remaining;
        this.deadline = deadline;
    }

    final override AbstractCompletableFuture tryFire(int ignore) {
        Thread w = thread; // no need to atomically claim
        if (w !is null) {
            thread = null;
            LockSupport.unpark(w);
        }
        return null;
    }

    bool isReleasable() {
        if (ThreadEx.interrupted())
            interrupted = true;
        return ((interrupted && interruptible) ||
                (deadline != MonoTime.zero &&
                 (remaining <= Duration.zero ||
                  (remaining = deadline - MonoTime.currTime) <= Duration.zero)) ||
                thread is null);
    }

    bool block() {
        while (!isReleasable()) {
            if (deadline == MonoTime.zero)
                LockSupport.park(this);
            else
                LockSupport.park(this, remaining);
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
    static ScheduledFuture!(void) delay(Runnable command, Duration delay) {
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
final class DelayedCompleter(U) : Runnable if(!is(U == void)) {
    CompletableFuture!(U) f;
    U u;

    this(CompletableFuture!(U) f, U u) { this.f = f; this.u = u; }

    void run() {
        if (f !is null) {
            f.complete(u);
        }
    }
}

final class DelayedCompleter(U) : Runnable if(is(U == void)) {
    CompletableFuture!(U) f;

    this(CompletableFuture!(U) f) { this.f = f; }

    void run() {
        if (f !is null) {
            f.complete();
        }
    }
}


/**
 * A subclass that just throws UOE for most non-CompletionStage methods.
 */
final class MinimalStage(T) : CompletableFuture!(T) {
    this() { }
    this(AltResult r) { super(r); }

    override CompletableFuture!(U) newIncompleteFuture(U)() {
        return new MinimalStage!(U)(); }
    override T get() {
        throw new UnsupportedOperationException(); }
    override T get(Duration timeout) {
        throw new UnsupportedOperationException(); }
    override T join() {
        throw new UnsupportedOperationException(); }
    override bool completeExceptionally(Throwable ex) {
        throw new UnsupportedOperationException(); }
    override bool cancel(bool mayInterruptIfRunning) {
        throw new UnsupportedOperationException(); }
    override void obtrudeException(Throwable ex) {
        throw new UnsupportedOperationException(); }
    override bool isDone() {
        throw new UnsupportedOperationException(); }
    override bool isCancelled() {
        throw new UnsupportedOperationException(); }
    override bool isCompletedExceptionally() {
        throw new UnsupportedOperationException(); }
    override int getNumberOfDependents() {
        throw new UnsupportedOperationException(); }
    override CompletableFuture!(T) completeAsync
        (Supplier!(T) supplier, Executor executor) {
        throw new UnsupportedOperationException(); }
    override CompletableFuture!(T) completeAsync
        (Supplier!(T) supplier) {
        throw new UnsupportedOperationException(); }
    override CompletableFuture!(T) orTimeout
        (Duration timeout) {
        throw new UnsupportedOperationException(); }

    override CompletableFuture!(T) toCompletableFuture() {
        if (isDone()) {
            if(isFaulted())
                return new CompletableFuture!(T)(this.altResult);
            else {
static if(is(T == void)) {
                return new CompletableFuture!(T)(true);
} else {
                return new CompletableFuture!(T)(this.result);
}
            }
        } else {
            CompletableFuture!(T) d = new CompletableFuture!T();
            unipush(new UniRelay!(T,T)(d, this));
            return d;
        }
    }

static if(is(T == void)) {

    this(bool r) { super(r); }

    override T getNow() {
        throw new UnsupportedOperationException(); }
    override bool complete() {
        throw new UnsupportedOperationException(); }

    override void obtrudeValue() {
        throw new UnsupportedOperationException(); }

    override CompletableFuture!(T) completeOnTimeout(Duration timeout) {
        throw new UnsupportedOperationException(); }

} else {

    this(T r) { super(r); }

    override T getNow(T valueIfAbsent) {
        throw new UnsupportedOperationException(); }
    override bool complete(T value) {
        throw new UnsupportedOperationException(); }

    override void obtrudeValue(T value) {
        throw new UnsupportedOperationException(); }

    override CompletableFuture!(T) completeOnTimeout(T value, Duration timeout) {
        throw new UnsupportedOperationException(); }
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
    return asyncSupplyStage!(U)(ASYNC_POOL, supplier);
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
    return asyncSupplyStage!(U)(screenExecutor(executor), supplier);
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
CompletableFuture!(void) runAsync(Runnable runnable) {
    if(runnable is null) 
        throw new NullPointerException();
    return asyncRunStage(ASYNC_POOL, { runnable.run(); });
}


CompletableFuture!(void) runAsync(Action act) {
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
CompletableFuture!(void) runAsync(Runnable runnable, Executor executor) {
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
    static if(is(U == class) || is(U == interface)) {
        if(value is null)
            return new CompletableFuture!(U)(NIL);
        else 
            return new CompletableFuture!(U)(value);
    } else {
        return new CompletableFuture!(U)(value);
    }
}    

/* ------------- Zero-input Async forms -------------- */

CompletableFuture!(U) asyncSupplyStage(U)(Executor e,
                                                 Supplier!(U) f) {
    if (f is null) throw new NullPointerException();
    CompletableFuture!(U) d = new CompletableFuture!(U)();
    e.execute(new AsyncSupply!(U)(d, f));
    return d;
}


CompletableFuture!(void) asyncRunStage(Executor e, Action f) {
    if (f is null) throw new NullPointerException();
    CompletableFuture!(void) d = new CompletableFuture!(void)();
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
CompletableFuture!(void) allOf(T)(CompletableFuture!T[] cfs...) {
    return andTree!(T)(cfs, 0, cast(int)cfs.length - 1);
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
static CompletableFuture!(U) anyOf(U)(CompletableFuture!(U)[] cfs...) {
    int n; 
    if ((n = cast(int)cfs.length) <= 1)
        return (n == 0)
            ? new CompletableFuture!(U)()
            : uniCopyStage!(U, U)(cfs[0]);

    foreach(CompletableFuture!(U) cf; cfs) {
        if (cf.isDone()) {
            if(cf.isFaulted())
                return new CompletableFuture!(U)(encodeRelay(cf.altResult));
            else
                return new CompletableFuture!(U)(cf.result);
        }
    }

    cfs = cfs.dup;
    CompletableFuture!(U) d = new CompletableFuture!U();
    foreach (CompletableFuture!(U) cf;  cfs)
        cf.unipush(new AnyOf!(U)(d, cf, cfs));
    // If d was completed while we were adding completions, we should
    // clean the stack of any sources that may have had completions
    // pushed on their stack after d was completed.
    if (d._isDone)
        for (size_t i = 0, len = cfs.length; i < len; i++)
            if (cfs[i]._isDone)
                for (i++; i < len; i++)
                    if (!cfs[i]._isDone)
                        cfs[i].cleanStack();
    return d;
}


/** Recursively constructs a tree of completions. */
private CompletableFuture!(void) andTree(T)(CompletableFuture!T[] cfs,
                                       int lo, int hi) {
    CompletableFuture!(void) d = new CompletableFuture!(void)();
    if (lo > hi) // empty
        d.completeNull!false();
    else {
        AbstractCompletableFuture a, b; 
        Object r, s, z; 
        Throwable x;

        int mid = (lo + hi) >>> 1;
        if ((a = (lo == mid ? cfs[lo] :
                  andTree!(T)(cfs, lo, mid))) is null ||
            (b = (lo == hi ? a : (hi == mid+1) ? cfs[hi] :
                  andTree!(T)(cfs, mid+1, hi))) is null)
            throw new NullPointerException();

        if (!a.isDone() || !b.isDone())
            a.bipush(b, new BiRelay(d, a, b));
        else {
            AltResult ar = a.altResult;
            AltResult ars = b.altResult;
            if(ar !is null && (x = ar.ex) !is null){
                d.completeThrowable!false(x, ar);
            } else if(ars !is null && (x = ars.ex) !is null){
                d.completeThrowable!false(x, ars);
            } else {
                d.completeNull!false();
            }
        }
    }
    return d;
}

/**
 * Returns the encoding of the given (non-null) exception as a
 * wrapped CompletionException unless it is one already.
 */
private AltResult encodeThrowable(Throwable x) {
    CompletionException ex = cast(CompletionException)x;
    if(ex is null) {
        return new AltResult(new CompletionException(x));
    } else {
        return new AltResult(x);
    }
}

/**
 * Returns the encoding of the given (non-null) exception as a
 * wrapped CompletionException unless it is one already.  May
 * return the given Object r (which must have been the result of a
 * source future) if it is equivalent, i.e. if this is a simple
 * relay of an existing CompletionException.
 */
private AltResult encodeThrowable(Throwable x, AltResult r) {
    CompletionException cex = cast(CompletionException)x;
    if (cex is null)
        x = new CompletionException(x);
    else {
        if (r !is null && x is r.ex)
            return r;
    }
    return new AltResult(x);
}

private CompletableFuture!(U) uniCopyStage(U, T : U)(CompletableFuture!(T) src) {
    CompletableFuture!(U) d = newIncompleteFuture!(U)();// src.newIncompleteFuture();
    if (src._isDone) {
        if(src.isFaulted())
            d.completeValue!false(src.altResult);
        else {
static if(is(T == void)) {
            d.completeValue!false();
} else {
            d.completeValue!false(src.result);
}            
        }
    }
    else
        src.unipush(new UniRelay!(U, T)(d, src));
    return d;
}

/**
 * Returns the encoding of a copied outcome; if exceptional,
 * rewraps as a CompletionException, else returns argument.
 */
private AltResult encodeRelay(AltResult ar) {
    Throwable x;

    if (ar !is null && (x = ar.ex) !is null) {
        CompletionException cex = cast(CompletionException)x;
        if(cex is null) {
            ar = new AltResult(new CompletionException(x));
        }
    }
    return ar;
}

/**
 * Reports result using Future.get conventions.
 */
private V reportGet(V)(V r, AltResult ar) if(!is(V == void)) {
    if (ar is null) // by convention below, null means interrupted
        throw new InterruptedException();

    if (ar !is null) {
        Throwable x, cause;
        if ((x = ar.ex) is null){
            warning("to check");
            return V.init;
        }
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

private void reportGet(AltResult ar) {
    if (ar is null) // by convention below, null means interrupted
        throw new InterruptedException();

    if (ar !is null) {
        Throwable x, cause;
        if ((x = ar.ex) is null){
            warning("to check");
            return;
        }
        CancellationException cex = cast(CancellationException)x;
        if (cex !is null)
            throw cex;
        CompletionException cex2 = cast(CompletionException)x;
        if (cex2 !is null &&
            (cause = x.next) !is null)
            x = cause;
        throw new ExecutionException(x);
    }
}


/**
 * Decodes outcome to return result or throw unchecked exception.
 */
private V reportJoin(V)(V r, AltResult ar) if(!is(V == void)) {
    if (ar !is null) {
        Throwable x;
        if ((x = ar.ex) is null) {
            warning("to check");
            return V.init;
        }
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


private void reportJoin(AltResult ar) {
    if (ar !is null) {
        Throwable x;
        if ((x = ar.ex) is null) {
            warning("need to check");
            return;
        }
        CancellationException cex = cast(CancellationException)x;
        if (cex !is null)
            throw cex;
        CompletionException cex2 = cast(CompletionException)x;
        if (cex2 !is null)
            throw cex2;
        throw new CompletionException(x);
    }
}

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