module hunt.util.exception;

import core.exception;
import std.exception;
import std.stdio;

void implementationMissing(string name = __FUNCTION__, string file = __FILE__, int line = __LINE__ )(bool canThrow=true)
{
    if(canThrow)
        throw new Exception("Implementation missing: " ~ name, file, line);
    else
    {

        import hunt.logging;
        // writefln("Implementation missing, in %s:%d", file, line);
        warningf("Implementation missing %s, in %s:%d", name, file, line);
    }
}


mixin template ExceptionBuild(string name, string parent = "")
{
    import std.exception;
	enum buildStr = "class " ~ name ~ "Exception : " ~ parent ~ "Exception { \n\t" ~ "mixin basicExceptionCtors;\n }";
	mixin(buildStr);
}

mixin template BasicExceptionCtors()
{
    this(size_t line = __LINE__, string file = __FILE__) @nogc @safe pure nothrow
    {
        super("", file, line, null);
    }

    this(string msg, string file = __FILE__, size_t line = __LINE__,
         Throwable next = null) @nogc @safe pure nothrow
    {
        super(msg, file, line, next);
    }

    this(string msg, Throwable next, string file = __FILE__,
         size_t line = __LINE__) @nogc @safe pure nothrow
    {
        super(msg, file, line, next);
    }
    
    this(Throwable next, string file = __FILE__,
         size_t line = __LINE__) @nogc @safe pure nothrow
    {
        super("", file, line, next);
    }
    
    // mixin basicExceptionCtors;
}


class NotImplementedException: Exception
{
    mixin BasicExceptionCtors;
}

class NotSupportedException: Exception
{
    mixin BasicExceptionCtors;
}

class IllegalArgumentException: Exception
{
    mixin BasicExceptionCtors;
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
    // mixin BasicExceptionCtors;
}


class TimeoutException: Exception
{
    mixin BasicExceptionCtors;
}

class InterruptedException: Exception
{
    mixin BasicExceptionCtors;
}

class ExecutionException: Exception
{
    mixin BasicExceptionCtors;
}

class URISyntaxException : IOException
{
    mixin BasicExceptionCtors;
}


class IOException : Exception
{
    mixin BasicExceptionCtors;
}


class MalformedURLException : IOException
{
    mixin BasicExceptionCtors;
}

class InterruptedIOException : IOException
{
    mixin BasicExceptionCtors;
}

class CommonRuntimeException : RuntimeException
{
    mixin BasicExceptionCtors;
}


class IndexOutOfBoundsException : RuntimeException
{
    mixin BasicExceptionCtors;
}

class ReadOnlyBufferException : RuntimeException
{
    mixin BasicExceptionCtors;
}

class BufferUnderflowException : RuntimeException
{
    mixin BasicExceptionCtors;
}

class BufferOverflowException : RuntimeException
{
    mixin BasicExceptionCtors;
}

class UnsupportedOperationException : RuntimeException
{
    mixin BasicExceptionCtors;
}


class NoSuchElementException : RuntimeException
{
    // this()
    // {
    //     super("");
    // }
    mixin BasicExceptionCtors;
}

class NumberFormatException : IllegalArgumentException
{
    mixin BasicExceptionCtors;
}


class NullPointerException : RuntimeException
{
    mixin BasicExceptionCtors;
}

class EofException : RuntimeException
{
    mixin BasicExceptionCtors;
}

class SecureNetException: RuntimeException
{
    mixin BasicExceptionCtors;
}

class ArithmeticException: RuntimeException
{
    mixin BasicExceptionCtors;
}

class ArrayIndexOutOfBoundsException: IndexOutOfBoundsException
{
    mixin BasicExceptionCtors;
}

class ClosedChannelException : IOException
{
    mixin BasicExceptionCtors;
}

class EOFException : IOException
{
    mixin BasicExceptionCtors;
}



class IllegalStateException : Exception
{
    mixin BasicExceptionCtors;
}


class InvalidMarkException : IllegalStateException
{
    mixin BasicExceptionCtors;
}

class WritePendingException : IllegalStateException
{
    mixin BasicExceptionCtors;
}


class CancellationException : IllegalStateException
{
    mixin BasicExceptionCtors;
}


class OutOfMemoryError : Error
{
    // this(string msg, Throwable nextInChain = null)
    // {
    //     super(msg, nextInChain);
    // }
    
    mixin BasicExceptionCtors;
}


class GeneralSecurityException : Exception
{
    mixin BasicExceptionCtors;
}


class CertificateException : GeneralSecurityException
{
    mixin BasicExceptionCtors;
}

class NoSuchAlgorithmException: GeneralSecurityException
{
    mixin BasicExceptionCtors;
}


class ConcurrentModificationException : Exception
{
    mixin BasicExceptionCtors;
}


class InternalError : Exception
{
    mixin BasicExceptionCtors;
}

class CRLException : GeneralSecurityException
{
    mixin BasicExceptionCtors;
}


class NoSuchProviderException : Exception
{
    mixin BasicExceptionCtors;
}


class CertificateNotYetValidException : Exception
{
    mixin BasicExceptionCtors;
}


class CertificateExpiredException : Exception
{
    mixin BasicExceptionCtors;
}

class SignatureException : Exception
{
    mixin BasicExceptionCtors;
}

class CertificateEncodingException : Exception
{
    mixin BasicExceptionCtors;
}

class ParsingException : Exception
{
    mixin BasicExceptionCtors;
}

class CertificateParsingException : ParsingException
{
    mixin BasicExceptionCtors;
}

class InvalidKeyException : Exception
{
    mixin BasicExceptionCtors;
}


class KeyStoreException : Exception
{
    mixin BasicExceptionCtors;
}


class UnrecoverableKeyException : Exception
{
    mixin BasicExceptionCtors;
}

class KeyManagementException : Exception
{
    mixin BasicExceptionCtors;
}