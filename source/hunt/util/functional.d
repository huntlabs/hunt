module hunt.util.functional;

/**
*/
alias Function(T, U) = U delegate(T);

/**
 * A one-argument action.
 */
template Action1(T)
{
    alias Action1 = void delegate(T t);
}


/**
 * A two-argument action.
 */
template Action2(T1, T2)
{
    alias Action2 = void delegate(T1 t1, T2 t2);
}

/**
 * A three-argument action.
 */
template Action3(T1, T2, T3)
{
    alias Action3 = void delegate(T1 t1, T2 t2, T3 t3);
}

/**
 * A four-argument action.
 */
template Action4(T1, T2, T3, T4)
{
    alias Action4 = void delegate(T1 t1, T2 t2, T3 t3, T4 t4);
}

/**
 * A five-argument action.
 */
template Action5(T1, T2, T3, T4, T5)
{
    alias Action5 = void delegate(T1 t1, T2 t2, T3 t3, T4 t4, T5 t5);
}


/**
 * A six-argument action.
 */
template Action6(T1, T2, T3, T4, T5, T6)
{
    alias Action6 = void delegate(T1 t1, T2 t2, T3 t3, T4 t4, T5 t5, T6 t6);
}



/**
 * A vector-argument action.
 */
template ActionN(T)
{
    alias ActionN = void delegate(T[] args...);
}

/**
 *  Represents a function with one argument.
 */
template Func1(T1, R)
{
    alias Func1 = R delegate(T1 t1);
}

/**
 *  Represents a function with four arguments.
 */
template Func4(T1, T2, T3, T4, R)
{
    alias Func4 = R delegate(T1 t1, T2 t2, T3 t3, T4 t4);
}

/**
 * Represents a function with five arguments.
 */
template Func5(T1, T2, T3, T4, T5, R)
{
    alias Func5 = R delegate(T1 t1, T2 t2, T3 t3, T4 t4, T5 t5);
}

/**
 * Represents a function with six arguments.
 */
template Func6(T1, T2, T3, T4, T5, T6, R)
{
    alias Func6 = R delegate(T1 t1, T2 t2, T3 t3, T4 t4, T5 t5, T6 t6);
}




/**
 * Represents a supplier of results.
 *
 * <p>There is no requirement that a new or distinct result be returned each
 * time the supplier is invoked.
 *
 */
template Supplier(T)
{
    alias Supplier = T delegate();
}

/**
 * Represents an operation that accepts a single input argument and returns no
 * result. Unlike most other functional interfaces, {@code Consumer} is expected
 * to operate via side-effects.
 *
 */
template Consumer(T)
{
    alias Consumer = void delegate(T t);
}


template Predicate(T)
{
    alias Predicate = bool delegate(T t);
}

  
/**
 * <p>
 * A callback abstraction that handles completed/failed events of asynchronous
 * operations.
 * </p>
 * <p>
 * <p>
 * Semantically this is equivalent to an optimise Promise&lt;Void&gt;, but
 * callback is a more meaningful name than EmptyPromise
 * </p>
 */
interface Callback {
    /**
     * Instance of Adapter that can be used when the callback methods need an
     * empty implementation without incurring in the cost of allocating a new
     * Adapter object.
     */
    __gshared Callback NOOP;

    shared static this()
    {
        NOOP = new NoopCallback();
    }

    /**
     * <p>
     * Callback invoked when the operation completes.
     * </p>
     *
     * @see #failed(Throwable)
     */
    void succeeded();

    /**
     * <p>
     * Callback invoked when the operation fails.
     * </p>
     *
     * @param x the reason for the operation failure
     */
    void failed(Exception x);

    /**
     * @return True if the callback is known to never block the caller
     */
    bool isNonBlocking();
}


/**
*/
class NestedCallback : Callback {
        private Callback callback;

        this(Callback callback) {
            this.callback = callback;
        }

        this(NestedCallback nested) {
            this.callback = nested.callback;
        }

        Callback getCallback() {
            return callback;
        }
        
        void succeeded() {
            callback.succeeded();
        }
        
        void failed(Exception x) {
            callback.failed(x);
        }

        bool isNonBlocking() {
            return callback.isNonBlocking();
        }
    }

/**
 * <p>
 * A callback abstraction that handles completed/failed events of asynchronous
 * operations.
 * </p>
 * <p>
 * <p>
 * Semantically this is equivalent to an optimise Promise&lt;Void&gt;, but
 * callback is a more meaningful name than EmptyPromise
 * </p>
 */
class NoopCallback : Callback {
    /**
     * <p>
     * Callback invoked when the operation completes.
     * </p>
     *
     * @see #failed(Throwable)
     */
    void succeeded() {
    }

    /**
     * <p>
     * Callback invoked when the operation fails.
     * </p>
     *
     * @param x the reason for the operation failure
     */
    void failed(Exception x) {
    }

    /**
     * @return True if the callback is known to never block the caller
     */
    bool isNonBlocking() {
        return false;
    }
}