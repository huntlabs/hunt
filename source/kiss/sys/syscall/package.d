module kiss.sys.syscall;

@system:
version(Posix):

version(D_InlineAsm_X86_64)
{
    version(linux) public import kiss.sys.syscall.os.linux;
    else version(OSX) public import kiss.sys.syscall.os.osx;
    else version(FreeBSD) public import kiss.sys.syscall.os.freebsd;
    else static assert(false, "Not supoorted your OS.");

    public import kiss.sys.syscall.arch.x86_64;
}
else static assert(false, "syscall only supoorted for x86_64.");

