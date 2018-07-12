module kiss.sys.syscall;

@system:
version(Posix):

extern (C) nothrow @nogc size_t syscall(size_t ident);
extern (C) nothrow @nogc size_t syscall(size_t ident, size_t arg0);
extern (C) nothrow @nogc size_t syscall(size_t ident, size_t arg0, size_t arg1);
extern (C) nothrow @nogc size_t syscall(size_t ident, size_t arg0, size_t arg1, size_t arg2);
extern (C) nothrow @nogc size_t syscall(size_t ident, size_t arg0, size_t arg1, size_t arg2, size_t arg3);
extern (C) nothrow @nogc size_t syscall(size_t ident, size_t arg0, size_t arg1, size_t arg2, size_t arg3, size_t arg4);
extern (C) nothrow @nogc size_t syscall(size_t ident, size_t arg0, size_t arg1, size_t arg2, size_t arg3, size_t arg4, size_t arg5);

version(D_InlineAsm_X86_64)
{
    version(linux) public import kiss.sys.syscall.os.linux;
    else version(OSX) public import kiss.sys.syscall.os.osx;
    else version(FreeBSD) public import kiss.sys.syscall.os.freebsd;
    else static assert(false, "Not supoorted your OS.");
}
else static assert(false, "syscall only supoorted for x86_64.");
