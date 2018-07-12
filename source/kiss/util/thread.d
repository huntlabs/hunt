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
	version (linux)
	{
		version (X86_64) // X86_64
		{
			enum __NR_gettid = 186;
		}
		else
		{
			enum __NR_gettid = 224;
		}
	}
    else version (FreeBSD)
	{
		enum __NR_gettid = 224;
	}
    else version (OSX)
	{
		enum __NR_gettid = 372;
	}
    else
        static assert(false, "__NR_gettid undefined");

	import core.sys.posix.sys.types : pid_t;

	extern (C) nothrow @nogc pid_t syscall(int d);
	pid_t getTid()
	{
		return syscall(__NR_gettid);
	}
}
else 
{
    ThreadID getTid()
	{
		return Thread.getThis.id;
	}
}
