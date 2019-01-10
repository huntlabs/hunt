module hunt.system.syscall;

@system:
version(Posix):

extern (C) nothrow @nogc size_t syscall(size_t ident, ...);

version(D_InlineAsm_X86_64)
{
    version(linux) public import hunt.system.syscall.os.Linux;
    else version(OSX) public import hunt.system.syscall.os.OSX;
    else version(FreeBSD) public import hunt.system.syscall.os.FreeBSD;
    else static assert(false, "Not supoorted OS.");
}
else static assert(false, "The syscall() only supoorted for x86_64.");
