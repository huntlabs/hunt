/*
 * Kiss - A refined core library for D programming language.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.cn
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
module kiss.util.thread;

import core.thread;

version (Posix)
{
    import core.sys.posix.sys.types : pid_t;
    import kiss.sys.syscall;

    pid_t getTid()
    {
        version(FreeBSD)
        {
            /*
            long tid;
            syscall(SYS_thr_self, &tid);

            return cast(pid_t)tid;
	    */
            return cast(pid_t)syscall(SYS_thr_self);
        }
        else version(OSX)
        {
            return cast(pid_t)syscall(SYS_thread_selfid);
        }
        else version(linux)
        {
            return cast(pid_t)syscall(__NR_gettid);
        }
        else
        {
            return 0;
        }
    }
}
else 
{
    ThreadID getTid()
    {
        return Thread.getThis.id;
    }
}

