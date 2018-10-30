module hunt.concurrent.thread.ThreadEx;

import core.thread;

alias Thread = ThreadEx;
alias StdThread = core.thread.Thread;

/**
*/
class ThreadEx : StdThread {

    this( void function() fn, size_t sz = 0 ) @safe pure nothrow @nogc {
        super(fn, sz);
    }

    this( void delegate() dg, size_t sz = 0 ) @safe pure nothrow @nogc {
        super(dg, sz);
    }

    static ThreadEx getThis() {
        return cast(ThreadEx)StdThread.getThis();
    }
}