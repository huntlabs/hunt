module kiss.sys.syscall;

@system:
version(Posix):

extern (C) nothrow @nogc size_t syscall(size_t ident, ...);

version(linux) public import kiss.sys.syscall.os.linux;
else version(OSX) public import kiss.sys.syscall.os.osx;
else version(FreeBSD) public import kiss.sys.syscall.os.freebsd;
else static assert(false, "Not supoorted your OS.");
