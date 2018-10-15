module hunt.lang.common;



/**
 * An action.
 */
alias Action = void delegate();

/**
 * A one-argument action.
 */
alias Action1(T) = void delegate(T t);

/**
 * A two-argument action.
 */
alias Action2(T1, T2) = void delegate(T1 t1, T2 t2);

/**
 * A three-argument action.
 */
alias Action3(T1, T2, T3) = void delegate(T1 t1, T2 t2, T3 t3);

/**
 * A four-argument action.
 */
alias Action4(T1, T2, T3, T4) = void delegate(T1 t1, T2 t2, T3 t3, T4 t4);

/**
 * A five-argument action.
 */
alias Action5(T1, T2, T3, T4, T5) = void delegate(T1 t1, T2 t2, T3 t3, T4 t4, T5 t5);

/**
 * A six-argument action.
 */
alias Action6(T1, T2, T3, T4, T5, T6) = void delegate(T1 t1, T2 t2, T3 t3, T4 t4, T5 t5, T6 t6);


/**
 * A vector-argument action.
 */
alias ActionN(T) = void delegate(T[] args...);


/**
 *  Represents a function.
 */
alias Func(R) = R delegate();

/**
 *  Represents a function with one argument.
 */
alias Func1(T1, R) = R delegate(T1 t1);

/**
 *  Represents a function with two arguments.
 */
alias Func2(T1, T2, R) = R delegate(T1 t1, T2 t2);

/**
 *  Represents a function with three arguments.
 */
alias Func3(T1, T2, T3, R) = R delegate(T1 t1, T2 t2, T3 t3);

/**
 *  Represents a function with four arguments.
 */
alias Func4(T1, T2, T3, T4, R) = R delegate(T1 t1, T2 t2, T3 t3, T4 t4);

/**
 * Represents a function with five arguments.
 */
alias Func5(T1, T2, T3, T4, T5, R) = R delegate(T1 t1, T2 t2, T3 t3, T4 t4, T5 t5);

/**
 * Represents a function with six arguments.
 */
alias Func6(T1, T2, T3, T4, T5, T6, R) = R delegate(T1 t1, T2 t2, T3 t3, T4 t4, T5 t5, T6 t6);

alias FuncN(T, R) = R delegate(T[] args...);

/**
 * Represents an operation that accepts a single input argument and returns no
 * result. Unlike most other functional interfaces, {@code Consumer} is expected
 * to operate via side-effects.
 *
 */
alias Consumer = Action1;
// alias Consumer(T) = void delegate(T t);

/**
*/
alias Function = Func1;
// alias Function(T, U) = U delegate(T);

/**
 * Represents a supplier of results.
 *
 * <p>There is no requirement that a new or distinct result be returned each
 * time the supplier is invoked.
 *
 */
alias Supplier = Func;
// alias Supplier(T) = T delegate();

/**
*/
alias Predicate(T) = bool delegate(T t);

/**
 * Represents an operation that accepts two input arguments and returns no
 * result.  This is the two-arity specialization of {@link Consumer}.
 * Unlike most other functional interfaces, {@code BiConsumer} is expected
 * to operate via side-effects.
 *
 * <p>This is a <a href="package-summary.html">functional interface</a>
 * whose functional method is {@link #accept(Object, Object)}.
 *
 * @param <T> the type of the first argument to the operation
 * @param <U> the type of the second argument to the operation
 *
 * @see Consumer
 */
alias BiConsumer = Action2;
// alias BiConsumer(T, U) = void delegate(T t, U u);



/**
 * Represents a function that accepts two arguments and produces a result.
 * This is the two-arity specialization of {@link Function}.
 *
 * <p>This is a <a href="package-summary.html">functional interface</a>
 * whose functional method is {@link #apply(Object, Object)}.
 *
 * @param <T> the type of the first argument to the function
 * @param <U> the type of the second argument to the function
 * @param <R> the type of the result of the function
 *
 * @see Function
 */
alias BiFunction = Func2; 
//  alias BiFunction(T, U, R) = R delegate(T t, U u);

/**
 * A class implements the <code>Cloneable</code> interface to
 * indicate to the {@link java.lang.Object#clone()} method that it
 * is legal for that method to make a
 * field-for-field copy of instances of that class.
 * <p>
 * Invoking Object's clone method on an instance that does not implement the
 * <code>Cloneable</code> interface results in the exception
 * <code>CloneNotSupportedException</code> being thrown.
 * <p>
 * By convention, classes that implement this interface should override
 * <tt>Object.clone</tt> (which is protected) with a method.
 * See {@link java.lang.Object#clone()} for details on overriding this
 * method.
 * <p>
 * Note that this interface does <i>not</i> contain the <tt>clone</tt> method.
 * Therefore, it is not possible to clone an object merely by virtue of the
 * fact that it implements this interface.  Even if the clone method is invoked
 * reflectively, there is no guarantee that it will succeed.
 */
interface Cloneable {
}


interface Comparable(T) {
    // int compareTo(T o);
    int opCmp(T o);
}


interface Runnable {
    /**
     * When an object implementing interface <code>Runnable</code> is used
     * to create a thread, starting the thread causes the object's
     * <code>run</code> method to be called in that separately executing
     * thread.
     * <p>
     * The general contract of the method <code>run</code> is that it may
     * take any action whatsoever.
     */
    void run();
}


/**
 * A task that returns a result and may throw an exception.
 * Implementors define a single method with no arguments called
 * {@code call}.
 *
 * <p>The {@code Callable} interface is similar to {@link
 * java.lang.Runnable}, in that both are designed for classes whose
 * instances are potentially executed by another thread.  A
 * {@code Runnable}, however, does not return a result and cannot
 * throw a checked exception.
 *
 * <p>The {@link Executors} class contains utility methods to
 * convert from other common forms to {@code Callable} classes.
 *
 * @see Executor
 * @author Doug Lea
 * @param <V> the result type of method {@code call}
 */
interface Callable(V) {
    /**
     * Computes a result, or throws an exception if unable to do so.
     *
     * @return computed result
     * @throws Exception if unable to compute a result
     */
    V call();
}


/**
 * An object that may hold resources (such as file or socket handles)
 * until it is closed. The {@link #close()} method of an {@code AutoCloseable}
 * object is called automatically when exiting a {@code
 * try}-with-resources block for which the object has been declared in
 * the resource specification header. This construction ensures prompt
 * release, avoiding resource exhaustion exceptions and errors that
 * may otherwise occur.
 *
 * @apiNote
 * <p>It is possible, and in fact common, for a base class to
 * implement AutoCloseable even though not all of its subclasses or
 * instances will hold releasable resources.  For code that must operate
 * in complete generality, or when it is known that the {@code AutoCloseable}
 * instance requires resource release, it is recommended to use {@code
 * try}-with-resources constructions. However, when using facilities such as
 * {@link java.util.stream.Stream} that support both I/O-based and
 * non-I/O-based forms, {@code try}-with-resources blocks are in
 * general unnecessary when using non-I/O-based forms.
 *
 * @author Josh Bloch
 */
interface AutoCloseable {
    /**
     * Closes this resource, relinquishing any underlying resources.
     * This method is invoked automatically on objects managed by the
     * {@code try}-with-resources statement.
     *
     * <p>While this interface method is declared to throw {@code
     * Exception}, implementers are <em>strongly</em> encouraged to
     * declare concrete implementations of the {@code close} method to
     * throw more specific exceptions, or to throw no exception at all
     * if the close operation cannot fail.
     *
     * <p> Cases where the close operation may fail require careful
     * attention by implementers. It is strongly advised to relinquish
     * the underlying resources and to internally <em>mark</em> the
     * resource as closed, prior to throwing the exception. The {@code
     * close} method is unlikely to be invoked more than once and so
     * this ensures that the resources are released in a timely manner.
     * Furthermore it reduces problems that could arise when the resource
     * wraps, or is wrapped, by another resource.
     *
     * <p><em>Implementers of this interface are also strongly advised
     * to not have the {@code close} method throw {@link
     * InterruptedException}.</em>
     *
     * This exception interacts with a thread's interrupted status,
     * and runtime misbehavior is likely to occur if an {@code
     * InterruptedException} is {@linkplain Throwable#addSuppressed
     * suppressed}.
     *
     * More generally, if it would cause problems for an
     * exception to be suppressed, the {@code AutoCloseable.close}
     * method should not throw it.
     *
     * <p>Note that unlike the {@link java.io.Closeable#close close}
     * method of {@link java.io.Closeable}, this {@code close} method
     * is <em>not</em> required to be idempotent.  In other words,
     * calling this {@code close} method more than once may have some
     * visible side effect, unlike {@code Closeable.close} which is
     * required to have no effect if called more than once.
     *
     * However, implementers of this interface are strongly encouraged
     * to make their {@code close} methods idempotent.
     *
     * @throws Exception if this resource cannot be closed
     */
    void close();
}


interface Closeable : AutoCloseable
{
    
}



/**
 * An object to which {@code char} sequences and values can be appended.  The
 * {@code Appendable} interface must be implemented by any class whose
 * instances are intended to receive formatted output from a {@link
 * java.util.Formatter}.
 *
 * <p> The characters to be appended should be valid Unicode characters as
 * described in <a href="Character.html#unicode">Unicode Character
 * Representation</a>.  Note that supplementary characters may be composed of
 * multiple 16-bit {@code char} values.
 *
 * <p> Appendables are not necessarily safe for multithreaded access.  Thread
 * safety is the responsibility of classes that extend and implement this
 * interface.
 *
 * <p> Since this interface may be implemented by existing classes
 * with different styles of error handling there is no guarantee that
 * errors will be propagated to the invoker.
 *
 */
interface Appendable {

    /**
     * Appends the specified character sequence to this {@code Appendable}.
     *
     * <p> Depending on which class implements the character sequence
     * {@code csq}, the entire sequence may not be appended.  For
     * instance, if {@code csq} is a {@link java.nio.CharBuffer} then
     * the subsequence to append is defined by the buffer's position and limit.
     *
     * @param  csq
     *         The character sequence to append.  If {@code csq} is
     *         {@code null}, then the four characters {@code "null"} are
     *         appended to this Appendable.
     *
     * @return  A reference to this {@code Appendable}
     *
     * @throws  IOException
     *          If an I/O error occurs
     */
    Appendable append(string csq);

    /**
     * Appends a subsequence of the specified character sequence to this
     * {@code Appendable}.
     *
     * <p> An invocation of this method of the form {@code out.append(csq, start, end)}
     * when {@code csq} is not {@code null}, behaves in
     * exactly the same way as the invocation
     *
     * <pre>
     *     out.append(csq.subSequence(start, end)) </pre>
     *
     * @param  csq
     *         The character sequence from which a subsequence will be
     *         appended.  If {@code csq} is {@code null}, then characters
     *         will be appended as if {@code csq} contained the four
     *         characters {@code "null"}.
     *
     * @param  start
     *         The index of the first character in the subsequence
     *
     * @param  end
     *         The index of the character following the last character in the
     *         subsequence
     *
     * @return  A reference to this {@code Appendable}
     *
     * @throws  IndexOutOfBoundsException
     *          If {@code start} or {@code end} are negative, {@code start}
     *          is greater than {@code end}, or {@code end} is greater than
     *          {@code csq.length()}
     *
     * @throws  IOException
     *          If an I/O error occurs
     */
    // Appendable append(CharSequence csq, int start, int end);

    /**
     * Appends the specified character to this {@code Appendable}.
     *
     * @param  c
     *         The character to append
     *
     * @return  A reference to this {@code Appendable}
     *
     * @throws  IOException
     *          If an I/O error occurs
     */
    Appendable append(char c);
}


/**
 * A tagging interface that all event listener interfaces must extend.
 */
interface EventListener {
}



enum ByteOrder
{
    BigEndian,
    LittleEndian
}


size_t hashCode(T)(T[] a...) {
    if (a is null)
        return 0;

    size_t result = 1;

    foreach (T element ; a)
        result = 31 * result + (element == T.init ? 0 : hashOf(element));

    return result;
}


/**
*/
class CompilerHelper {

    static bool isGreater(int ver)
    {
        return __VERSION__ >= ver;
    }

    static bool isSmaller(int ver)
    {
        return __VERSION__ <= ver;
    }
}


/**
*/
class EventArgs
{

}

alias EventHandler = void delegate(Object sender, EventArgs args);
alias SimpleEventHandler = void delegate();
alias ErrorEventHandler = void delegate(string message);
alias TickedEventHandler = void delegate(Object sender);
