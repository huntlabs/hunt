module hunt.util.concurrent.CompletableFuture;

import hunt.util.concurrent.Future;
import hunt.util.concurrent.Promise;

import hunt.util.exception;

/**
    * <p>A CompletableFuture that is also a Promise.</p>
    *
    * @param <S> the type of the result
    */
class Completable(S) : CompletableFuture!S , Promise!S {
    override
    void succeeded(S result) {
        complete(result);
    }

    override
    void failed(Exception x) {
        completeExceptionally(x);
    }
}



/**
*/
class CompletableFuture(T)
{

        /**
     * If not already completed, sets the value returned by {@link
     * #get()} and related methods to the given value.
     *
     * @param value the result value
     * @return {@code true} if this invocation caused this CompletableFuture
     * to transition to a completed state, else {@code false}
     */
    bool complete(T value) {
        completeValue(value);
        postComplete();
        return false;
    }

    private T result; 
    private bool m_isDone;

    this()
    {
    }

    this(T r)
    {
        completeValue(r);
    }

    //this(Supplier!T supplier)
    //{
    //    assert(supplier !is null);
    //    this.supplier = supplier;
    //    m_isDone = false;
    //}

    bool isDone()
    {
        return m_isDone;
    }

    T get()
    {
        return result;
    }    

    void cancel() {
        if(m_cancelled)
            return;
        m_cancelled = true;
        postComplete();
    }

    bool isCancelled()
    {
        return m_cancelled;
    }
    private bool m_cancelled;

    bool completeExceptionally(Throwable ex) {
        if (ex is null) throw new NullPointerException("");
        // bool triggered = internalComplete(new AltResult(ex));
        altResult = ex;
        postComplete();
        return false;
    }

    private Throwable altResult;

    private void completeValue(T r)
    {
        result = r;
        m_isDone = true;
    }

    /**
    * Pops and tries to trigger all reachable dependents.  Call only
    * when known to be done.
    */
    private void postComplete() {
        /*
        * On each step, variable f holds current dependents to pop
        * and run.  It is extended along only one path at a time,
        * pushing others to avoid unbounded recursion.
        */
        // debug writeln("postComplete in thread ", Thread.getThis().id);
        m_isDone = true;
    }

  /* ------------- Encoding and decoding outcomes -------------- */

    // static  class AltResult { // See above
    //     Throwable ex;        // null only for NIL
    //     this(Throwable x) { this.ex = x; }
    // }

}
