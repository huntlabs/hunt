module kiss.sys.syscall.arch.x86_64;

version(D_InlineAsm_X86_64):
@nogc:
nothrow:

size_t syscall(size_t ident)
{
    size_t ret;

    synchronized asm @nogc nothrow
    {
        mov RAX, ident;
        syscall;
        mov ret, RAX;
    }
    return ret;
}

size_t syscall(size_t ident, size_t n)
{
    size_t ret;

    synchronized asm @nogc nothrow
    {
        mov RAX, ident;
        mov RDI, n[RBP];
        syscall;
        mov ret, RAX;
    }
    return ret;
}

size_t syscall(size_t ident, size_t n, size_t arg1)
{
    size_t ret;

    synchronized asm @nogc nothrow
    {
        mov RAX, ident;
        mov RDI, n[RBP];
        mov RSI, arg1[RBP];
        syscall;
        mov ret, RAX;
    }
    return ret;
}

size_t syscall(size_t ident, size_t n, size_t arg1, size_t arg2)
{
    size_t ret;

    synchronized asm @nogc nothrow
    {
        mov RAX, ident;
        mov RDI, n[RBP];
        mov RSI, arg1[RBP];
        mov RDX, arg2[RBP];
        syscall;
        mov ret, RAX;
    }
    return ret;
}

size_t syscall(size_t ident, size_t n, size_t arg1, size_t arg2, size_t arg3)
{
    size_t ret;

    synchronized asm @nogc nothrow
    {
        mov RAX, ident;
        mov RDI, n[RBP];
        mov RSI, arg1[RBP];
        mov RDX, arg2[RBP];
        mov R10, arg3[RBP];
        syscall;
        mov ret, RAX;
    }
    return ret;
}

size_t syscall(size_t ident, size_t n, size_t arg1, size_t arg2, size_t arg3, size_t arg4)
{
    size_t ret;

    synchronized asm @nogc nothrow
    {
        mov RAX, ident;
        mov RDI, n[RBP];
        mov RSI, arg1[RBP];
        mov RDX, arg2[RBP];
        mov R10, arg3[RBP];
        mov R8, arg4[RBP];
        syscall;
        mov ret, RAX;
    }
    return ret;
}

size_t syscall(size_t ident, size_t n, size_t arg1, size_t arg2, size_t arg3, size_t arg4, size_t arg5)
{
    size_t ret;

    synchronized asm @nogc nothrow
    {
        mov RAX, ident;
        mov RDI, n[RBP];
        mov RSI, arg1[RBP];
        mov RDX, arg2[RBP];
        mov R10, arg3[RBP];
        mov R8, arg4[RBP];
        mov R9, arg5[RBP];
        syscall;
        mov ret, RAX;
    }
    return ret;
}
