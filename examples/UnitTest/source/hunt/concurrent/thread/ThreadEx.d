module hunt.concurrent.thread.ThreadEx;

import core.thread;

// alias Thread = ThreadEx;
// alias StdThread = core.thread.Thread;

import hunt.logging.ConsoleLogger;
/**
*/
class ThreadEx : Thread {

    this( void function() fn, size_t sz = 0 ) @safe pure nothrow @nogc {
        super(fn, sz);
    }

    this( void delegate() dg, size_t sz = 0 ) @safe pure nothrow @nogc {
        super(dg, sz);
    }

    // private this() {
    //     super({});
    // }

    // static ThreadEx getThis() {
    //     // auto xx = StdThread.getThis();
    //     // ConsoleLogger.info(typeid(xx));
    //     return cast(ThreadEx)StdThread.getThis();
    // }
}

// static this() {
//     thread_setThis(new ThreadEx());
// }