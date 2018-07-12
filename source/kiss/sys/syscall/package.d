module kiss.sys.syscall;

@system:

version(D_InlineAsm_X86_64)
{
    version(linux) import kiss.sys.syscall.os.linux;
    else version(OSX) import kiss.sys.syscall.os.osx;
    else version(FreeBSD) import kiss.sys.syscall.os.freebsd;
    else static assert(false, "Not supoorted your OS.");

    import kiss.sys.syscall.arch.x86_64;
}
else static assert(false, "syscall only supoorted for x86_64.");

unittest
{
    assert(syscall(GETPID) > 0);
}

