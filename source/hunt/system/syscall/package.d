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

module hunt.system.syscall;

@system:
version(Posix):

extern (C) nothrow @nogc size_t syscall(size_t ident, ...);

version(X86_64)
{
    version(linux) public import hunt.system.syscall.os.Linux;
    else version(OSX) public import hunt.system.syscall.os.OSX;
    else version(FreeBSD) public import hunt.system.syscall.os.FreeBSD;
    else static assert(false, "Not supoorted OS.");
}
else version(AArch64)
{
    version(linux) public import hunt.system.syscall.os.Linux;
    else version(OSX) public import hunt.system.syscall.os.OSX;
    else version(FreeBSD) public import hunt.system.syscall.os.FreeBSD;
    else static assert(false, "Not supoorted OS.");
}
else static assert(false, "The syscall() only supoorted for [x86_64,AArch64].");
