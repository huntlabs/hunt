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

module hunt.Functions;


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

// alias Action1 = ActionN;
// alias Action2 = ActionN;
// alias Action3 = ActionN;
// alias Action4 = ActionN;
// alias Action5 = ActionN;
// alias Action6 = ActionN;

/**
 * A vector-argument action.
 */
// alias ActionN(T) = void delegate(T);

template ActionN(T...) if(T.length > 0)  {
    alias ActionN = void delegate(T);
}

/**
 *  Represents a function.
 */
alias Func(R) = R delegate();

alias Func(T, R) = R delegate(T);
alias Func(T1, T2, R) = R delegate(T1, T2);
alias Func(T1, T2, T3, R) = R delegate(T1, T2, T3);
alias Func(T1, T2, T3, T4, R) = R delegate(T1, T2, T3, T4);
alias Func(T1, T2, T3, T4, T5, R) = R delegate(T1, T2, T3, T4, T5);
alias Func(T1, T2, T3, T4, T5, T6, R) = R delegate(T1, T2, T3, T4, T5, T6);

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

// alias FuncN(T, R) = R delegate(T[] args...);


// template Function(R, T...) {
//     alias Function = R delegate(T);
// }

/**
*/
class EventArgs {

}


alias EventHandler = ActionN!(Object, EventArgs); 
alias SimpleEventHandler = Action;
alias SimpleActionHandler = ActionN!(Object);

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



size_t hashCode(T)(T[] a...) {
    if (a is null)
        return 0;

    size_t result = 1;

    foreach (T element ; a)
        result = 31 * result + (element == T.init ? 0 : hashOf(element));

    return result;
}


bool hasKey(K, V)(V[K] arr, K key) {
    auto v = key in arr;
    return v !is null;
}

unittest {
    string[int] arr;
    arr[1001] = "1001";
    arr[1002] = "1002";

    assert(arr.hasKey(1001));
    assert(!arr.hasKey(1003));
}