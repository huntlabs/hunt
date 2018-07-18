module hunt.util.exception;

import std.exception;
import core.exception;

import std.stdio;

void implementationMissing(string file = __FILE__, int line = __LINE__ )(bool canThrow=true)
{
    if(canThrow)
        throw new core.exception.AssertError("Implementation missing", file, line);
    else
    {
        writefln("Implementation missing, in %s:%d", file, line);
    }
}

class NotImplementedException: Exception
{
    mixin basicExceptionCtors;
}

class NotSupportedException: Exception
{
    mixin basicExceptionCtors;
}

class IllegalArgumentException: Exception
{
    mixin basicExceptionCtors;
}

class RuntimeException : Exception
{
    this(Exception ex)
    {
        super("", ex);
    }

    /++
        Params:
            msg  = The message for the exception.
            file = The file where the exception occurred.
            line = The line number where the exception occurred.
            next = The previous exception in the chain of exceptions, if any.
    +/
    this(string msg, string file = __FILE__, size_t line = __LINE__,
         Throwable next = null) @nogc @safe pure nothrow
    {
        super(msg, file, line, next);
    }

    /++
        Params:
            msg  = The message for the exception.
            next = The previous exception in the chain of exceptions.
            file = The file where the exception occurred.
            line = The line number where the exception occurred.
    +/
    this(string msg, Throwable next, string file = __FILE__,
         size_t line = __LINE__) @nogc @safe pure nothrow
    {
        super(msg, file, line, next);
    }
    // mixin basicExceptionCtors;
}


class TimeoutException: Exception
{
    mixin basicExceptionCtors;
}

class InterruptedException: Exception
{
    mixin basicExceptionCtors;
}

class ExecutionException: Exception
{
    mixin basicExceptionCtors;
}

class URISyntaxException : IOException
{
    mixin basicExceptionCtors;
}


class IOException : Exception
{
    mixin basicExceptionCtors;
}


class MalformedURLException : IOException
{
    mixin basicExceptionCtors;
}


class CommonRuntimeException : RuntimeException
{
    mixin basicExceptionCtors;
}


class IndexOutOfBoundsException : RuntimeException
{
    mixin basicExceptionCtors;
}

class ReadOnlyBufferException : RuntimeException
{
    mixin basicExceptionCtors;
}

class BufferUnderflowException : RuntimeException
{
    mixin basicExceptionCtors;
}

class BufferOverflowException : RuntimeException
{
    mixin basicExceptionCtors;
}

class UnsupportedOperationException : RuntimeException
{
    mixin basicExceptionCtors;
}



class NoSuchElementException : RuntimeException
{
    // this()
    // {
    //     super("");
    // }
    mixin basicExceptionCtors;
}

class NumberFormatException : IllegalArgumentException
{
    mixin basicExceptionCtors;
}


class NullPointerException : RuntimeException
{
    mixin basicExceptionCtors;
}

class EofException : RuntimeException
{
    mixin basicExceptionCtors;
}

class ClosedChannelException : IOException
{
    mixin basicExceptionCtors;
}

class EOFException : IOException
{
    mixin basicExceptionCtors;
}


class SecureNetException: RuntimeException
{
    mixin basicExceptionCtors;
}


class IllegalStateException : Exception
{
    mixin basicExceptionCtors;
}


class InvalidMarkException : IllegalStateException
{
    mixin basicExceptionCtors;
}

class WritePendingException : IllegalStateException
{
    mixin basicExceptionCtors;
}


class CancellationException : IllegalStateException
{
    mixin basicExceptionCtors;
}


