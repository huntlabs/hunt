module hunt.system.syscall;

@system:
version(Posix):

extern (C) nothrow @nogc size_t syscall(size_t ident, ...);

version(D_InlineAsm_X86_64)
{
    version(linux) public import hunt.system.syscall.os.linux;
    else version(OSX) public import hunt.system.syscall.os.osx;
    else version(FreeBSD) public import hunt.system.syscall.os.freebsd;
    else static assert(false, "Not supoorted your OS.");
}
else static assert(false, "The syscall() only supoorted for x86_64.");
