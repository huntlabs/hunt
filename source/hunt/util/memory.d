module hunt.util.memory;

import core.atomic;
import core.memory;

// import core.sync.condition;
// import core.thread;

// import std.functional;
// import std.meta;
// import std.range.primitives;
import std.traits;

version (OSX) {
    version = useSysctlbyname;
}
else version (FreeBSD) {
    version = useSysctlbyname;
}
else version (DragonFlyBSD) {
    version = useSysctlbyname;
}
else version (NetBSD) {
    version = useSysctlbyname;
}

/*
(For now public undocumented with reserved name.)

A lazily initialized global constant. The underlying value is a shared global
statically initialized to `outOfBandValue` which must not be a legit value of
the constant. Upon the first call the situation is detected and the global is
initialized by calling `initializer`. The initializer is assumed to be pure
(even if not marked as such), i.e. return the same value upon repeated calls.
For that reason, no special precautions are taken so `initializer` may be called
more than one time leading to benign races on the cached value.

In the quiescent state the cost of the function is an atomic load from a global.

Params:
    T = The type of the pseudo-constant (may be qualified)
    outOfBandValue = A value that cannot be valid, it is used for initialization
    initializer = The function performing initialization; must be `nothrow`

Returns:
    The lazily initialized value
*/
@property pure T __lazilyInitializedConstant(T, alias outOfBandValue, alias initializer)()
        if (is(Unqual!T : T) && is(typeof(initializer()) : T) && is(typeof(outOfBandValue) : T)) {
    static T impl() nothrow {
        // Thread-local cache
        static Unqual!T tls = outOfBandValue;
        auto local = tls;
        // Shortest path, no atomic operations
        if (local != outOfBandValue)
            return local;
        // Process-level cache
        static shared Unqual!T result = outOfBandValue;
        // Initialize both process-level cache and tls
        local = atomicLoad(result);
        if (local == outOfBandValue) {
            local = initializer();
            atomicStore(result, local);
        }
        tls = local;
        return local;
    }

    // import std.traits : SetFunctionAttributes;
    alias Fun = SetFunctionAttributes!(typeof(&impl), "D",
            functionAttributes!(typeof(&impl)) | FunctionAttribute.pure_);
    auto purified = (() @trusted => cast(Fun)&impl)();
    return purified();
}

/**
The total number of CPU cores available on the current machine, as reported by
the operating system.
*/
alias totalCPUs = __lazilyInitializedConstant!(immutable(uint), uint.max, totalCPUsImpl);

uint totalCPUsImpl() @nogc nothrow @trusted {
    version (Windows) {
        // BUGS:  Only works on Windows 2000 and above.
        import core.sys.windows.windows : SYSTEM_INFO, GetSystemInfo;
        import std.algorithm.comparison : max;

        SYSTEM_INFO si;
        GetSystemInfo(&si);
        return max(1, cast(uint) si.dwNumberOfProcessors);
    }
    else version (linux) {
        import core.sys.posix.unistd : _SC_NPROCESSORS_ONLN, sysconf;

        return cast(uint) sysconf(_SC_NPROCESSORS_ONLN);
    }
    else version (Solaris) {
        import core.sys.posix.unistd : _SC_NPROCESSORS_ONLN, sysconf;

        return cast(uint) sysconf(_SC_NPROCESSORS_ONLN);
    }
    else version (useSysctlbyname) {
        version (OSX) {
            auto nameStr = "machdep.cpu.core_count\0".ptr;
        }
        else version (FreeBSD) {
            auto nameStr = "hw.ncpu\0".ptr;
        }
        else version (DragonFlyBSD) {
            auto nameStr = "hw.ncpu\0".ptr;
        }
        else version (NetBSD) {
            auto nameStr = "hw.ncpu\0".ptr;
        }

        uint result;
        size_t len = result.sizeof;
        sysctlbyname(nameStr, &result, &len, null, 0);
        return result;
    }
    else {
        static assert(0, "Don't know how to get N CPUs on this OS.");
    }
}

/**
*/
size_t getPageSize() @safe pure nothrow @nogc {
    return _pageSize;
}

static immutable size_t _pageSize;

shared static this() {
    version (Windows) {
        import core.sys.windows.winbase;

        SYSTEM_INFO info;
        GetSystemInfo(&info);

        _pageSize = info.dwPageSize;
        assert(_pageSize < int.max);
    }
    else version (Posix) {
        import core.sys.posix.unistd;

        _pageSize = cast(size_t) sysconf(_SC_PAGESIZE);
    }
    else {
        static assert(0, "unimplemented");
    }
}

/**
 * Reference queues, to which registered reference objects are appended by the
 * garbage collector after the appropriate reachability changes are detected.
 *
 * @author   Mark Reinhold
 * @since    1.2
 */

class ReferenceQueue(T) {
    // TODO: Tasks pending completion -@zxp at 8/10/2018, 4:15:28 PM
    // 
    /**
     * Constructs a new reference-object queue.
     */
    this() {
    }

    // private static class Null<S> extends ReferenceQueue<S> {
    //     bool enqueue(Reference<S> r) {
    //         return false;
    //     }
    // }

    // static ReferenceQueue<Object> NULL = new Null<>();
    // static ReferenceQueue<Object> ENQUEUED = new Null<>();

    // static private class Lock { };
    // private Lock lock = new Lock();
    // private Reference<T> head = null;
    // private long queueLength = 0;

    // bool enqueue(Reference<T> r) { /* Called only by Reference class */
    //     synchronized (lock) {
    //         // Check that since getting the lock this reference hasn't already been
    //         // enqueued (and even then removed)
    //         ReferenceQueue<?> queue = r.queue;
    //         if ((queue == NULL) || (queue == ENQUEUED)) {
    //             return false;
    //         }
    //         assert queue == this;
    //         r.queue = ENQUEUED;
    //         r.next = (head is null) ? r : head;
    //         head = r;
    //         queueLength++;
    //         if (r instanceof FinalReference) {
    //             sun.misc.VM.addFinalRefCount(1);
    //         }
    //         lock.notifyAll();
    //         return true;
    //     }
    // }

    // @SuppressWarnings("unchecked")
    // private Reference<T> reallyPoll() {       /* Must hold lock */
    //     Reference<T> r = head;
    //     if (r !is null) {
    //         head = (r.next == r) ?
    //             null :
    //             r.next; // Unchecked due to the next field having a raw type in Reference
    //         r.queue = NULL;
    //         r.next = r;
    //         queueLength--;
    //         if (r instanceof FinalReference) {
    //             sun.misc.VM.addFinalRefCount(-1);
    //         }
    //         return r;
    //     }
    //     return null;
    // }

    // /**
    //  * Polls this queue to see if a reference object is available.  If one is
    //  * available without further delay then it is removed from the queue and
    //  * returned.  Otherwise this method immediately returns <tt>null</tt>.
    //  *
    //  * @return  A reference object, if one was immediately available,
    //  *          otherwise <code>null</code>
    //  */
    // Reference<T> poll() {
    //     if (head is null)
    //         return null;
    //     synchronized (lock) {
    //         return reallyPoll();
    //     }
    // }

    // /**
    //  * Removes the next reference object in this queue, blocking until either
    //  * one becomes available or the given timeout period expires.
    //  *
    //  * <p> This method does not offer real-time guarantees: It schedules the
    //  * timeout as if by invoking the {@link Object#wait(long)} method.
    //  *
    //  * @param  timeout  If positive, block for up to <code>timeout</code>
    //  *                  milliseconds while waiting for a reference to be
    //  *                  added to this queue.  If zero, block indefinitely.
    //  *
    //  * @return  A reference object, if one was available within the specified
    //  *          timeout period, otherwise <code>null</code>
    //  *
    //  * @throws  IllegalArgumentException
    //  *          If the value of the timeout argument is negative
    //  *
    //  * @throws  InterruptedException
    //  *          If the timeout wait is interrupted
    //  */
    // Reference<T> remove(long timeout)
    //     throws IllegalArgumentException, InterruptedException
    // {
    //     if (timeout < 0) {
    //         throw new IllegalArgumentException("Negative timeout value");
    //     }
    //     synchronized (lock) {
    //         Reference<T> r = reallyPoll();
    //         if (r !is null) return r;
    //         long start = (timeout == 0) ? 0 : System.nanoTime();
    //         for (;;) {
    //             lock.wait(timeout);
    //             r = reallyPoll();
    //             if (r !is null) return r;
    //             if (timeout != 0) {
    //                 long end = System.nanoTime();
    //                 timeout -= (end - start) / 1000_000;
    //                 if (timeout <= 0) return null;
    //                 start = end;
    //             }
    //         }
    //     }
    // }

    // /**
    //  * Removes the next reference object in this queue, blocking until one
    //  * becomes available.
    //  *
    //  * @return A reference object, blocking until one becomes available
    //  * @throws  InterruptedException  If the wait is interrupted
    //  */
    // Reference<T> remove() throws InterruptedException {
    //     return remove(0);
    // }

}
