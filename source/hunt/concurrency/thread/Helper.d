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

module hunt.concurrency.thread.Helper;

import core.thread;

version (Posix) {
    import hunt.system.syscall;

    ThreadID getTid() {
        version(FreeBSD) {
            long tid;
            syscall(SYS_thr_self, &tid);
            return cast(ThreadID)tid;
        } else version(OSX) {
            return cast(ThreadID)syscall(SYS_thread_selfid);
        } else version(linux) {
            return cast(ThreadID)syscall(__NR_gettid);
        } else {
            return 0;
        }
    }
} else {
    import core.sys.windows.winbase: GetCurrentThreadId;
    ThreadID getTid() {
        return GetCurrentThreadId();
    }
}