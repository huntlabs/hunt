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

module hunt.concurrency.atomic.AtomicHelper;

import core.atomic;

class AtomicHelper {
    static void store(T)(ref T stuff, T newVal) {
        core.atomic.atomicStore(*(cast(shared)&stuff), newVal);
    }

    static T load(T)(ref T val) {
        return core.atomic.atomicLoad(*(cast(shared)&val));
    }

    static bool compareAndSet(T, V1, V2)(ref T stuff, V1 testVal, lazy V2 newVal) {
        return core.atomic.cas(cast(shared)&stuff, cast(shared)testVal, cast(shared)newVal);
    }

    static T increment(T, U)(ref T stuff, U delta = 1) if (__traits(isIntegral, T)) {
        return core.atomic.atomicOp!("+=")(stuff, delta);
    }

    static T decrement(T, U)(ref T stuff, U delta = 1) if (__traits(isIntegral, T)) {
        return core.atomic.atomicOp!("-=")(stuff, delta);
    }

    static T getAndAdd(T, U)(ref T stuff, U delta) {
        T v = increment(stuff, delta);
        return v - delta;
    }

    static T getAndSet(T, U)(ref T stuff, U newValue) {
        
        //TODO: Tasks pending completion -@zxp at 12/16/2018, 11:15:45 AM
        // exchange
        // https://issues.dlang.org/show_bug.cgi?id=15007
        T v = stuff;
        store(stuff, newValue);
        return v;
    }

    static T getAndIncrement(T)(ref T stuff) {
        return getAndAdd(stuff, 1);
    }

    static T getAndDecrement(T)(ref T stuff) {
        return getAndAdd(stuff, -1);
    }
}

