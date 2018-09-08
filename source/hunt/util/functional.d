module hunt.util.functional;

public import std.functional;
public import std.traits;
import std.typecons;
import std.typetuple;

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
alias Action2(T1, T2) = void delegate(T1 t1, T2 t2);

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
alias Supplier(T) = T delegate();

/**
 * Represents an operation that accepts a single input argument and returns no
 * result. Unlike most other functional interfaces, {@code Consumer} is expected
 * to operate via side-effects.
 *
 */
alias Consumer(T) = void delegate(T t);

alias Predicate(T) = bool delegate(T t);

  
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


pragma(inline) auto bind(T, Args...)(T fun, Args args) if (isCallable!(T))
{
    alias FUNTYPE = Parameters!(fun);
    static if (is(Args == void))
    {
        static if (isDelegate!T)
            return fun;
        else
            return toDelegate(fun);
    }
    else static if (FUNTYPE.length > args.length)
    {
        alias DTYPE = FUNTYPE[args.length .. $];
        return delegate(DTYPE ars) {
            TypeTuple!(FUNTYPE) value;
            value[0 .. args.length] = args[];
            value[args.length .. $] = ars[];
            return fun(value);
        };
    }
    else
    {
        return delegate() { return fun(args); };
    }
}

unittest
{

    import std.stdio;
    import core.thread;

    class AA
    {
        void show(int i)
        {
            writeln("i = ", i); // the value is not(0,1,2,3), it all is 2.
        }

        void show(int i, int b)
        {
            b += i * 10;
            writeln("b = ", b); // the value is not(0,1,2,3), it all is 2.
        }

        void aa()
        {
            writeln("aaaaaaaa ");
        }

        void dshow(int i, string str, double t)
        {
            writeln("i = ", i, "   str = ", str, "   t = ", t);
        }
    }

    void listRun(int i)
    {
        writeln("i = ", i);
    }

    void listRun2(int i, int b)
    {
        writeln("i = ", i, "  b = ", b);
    }

    void list()
    {
        writeln("bbbbbbbbbbbb");
    }

    void dooo(Thread[] t1, Thread[] t2, AA a)
    {
        foreach (i; 0 .. 4)
        {
            auto th = new Thread(bind!(void delegate(int, int))(&a.show, i, i));
            t1[i] = th;
            auto th2 = new Thread(bind(&listRun, (i + 10)));
            t2[i] = th2;
        }
    }

    //  void main()
    {
        auto tdel = bind(&listRun);
        tdel(9);
        bind(&listRun2, 4)(5);
        bind(&listRun2, 40, 50)();

        AA a = new AA();
        bind(&a.dshow, 5, "hahah")(20.05);

        Thread[4] _thread;
        Thread[4] _thread2;
        // AA a = new AA();

        dooo(_thread, _thread2, a);

        foreach (i; 0 .. 4)
        {
            _thread[i].start();
        }

        foreach (i; 0 .. 4)
        {
            _thread2[i].start();
        }

    }
}
