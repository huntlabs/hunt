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

module hunt.system.Memory;

import core.atomic;
import core.memory;

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

version(useSysctlbyname)
    private extern(C) int sysctlbyname(
        const char *, void *, size_t *, void *, size_t
    ) @nogc nothrow;

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
size_t pageSize() @safe pure nothrow @nogc {
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
