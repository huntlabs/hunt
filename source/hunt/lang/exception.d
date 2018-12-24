module hunt.lang.exception;

import core.exception;
import std.exception;

void implementationMissing(string name = __FUNCTION__, string file = __FILE__, int line = __LINE__)(
        bool canThrow = true) {
    if (canThrow)
        throw new Exception("Implementation missing: " ~ name, file, line);
    else {
        version (HUNT_DEBUG) {
            import hunt.logging;

            warningf("Implementation missing %s, in %s:%d", name, file, line);
        }
        else {
            import std.stdio;

            stderr.writefln("======> Implementation missing %s, in %s:%d", name, file, line);
        }
    }
}

mixin template ExceptionBuild(string name, string parent = "") {
    import std.exception;

    enum buildStr = "class " ~ name ~ "Exception : " ~ parent ~ "Exception { \n\t"
        ~ "mixin basicExceptionCtors;\n }";
    mixin(buildStr);
}

mixin template BasicExceptionCtors() {
    this(size_t line = __LINE__, string file = __FILE__) @nogc @safe pure nothrow {
        super("", file, line, null);
    }

    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) @nogc @safe pure nothrow {
        super(msg, file, line, next);
    }

    this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__) @nogc @safe pure nothrow {
        super(msg, file, line, next);
    }

    this(Throwable next, string file = __FILE__, size_t line = __LINE__) @nogc @safe pure nothrow {
        super(next.msg, file, line, next);
    }

    // mixin basicExceptionCtors;
}

class NotImplementedException : Exception {
    mixin BasicExceptionCtors;
}

class NotSupportedException : Exception {
    mixin BasicExceptionCtors;
}

class IllegalArgumentException : Exception {
    mixin BasicExceptionCtors;
}

class RuntimeException : Exception {
    this(Exception ex) {
        super("", ex);
    }

    /++
        Params:
            msg  = The message for the exception.
            file = The file where the exception occurred.
            line = The line number where the exception occurred.
            next = The previous exception in the chain of exceptions, if any.
    +/
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) @nogc @safe pure nothrow {
        super(msg, file, line, next);
    }

    /++
        Params:
            msg  = The message for the exception.
            next = The previous exception in the chain of exceptions.
            file = The file where the exception occurred.
            line = The line number where the exception occurred.
    +/
    this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__) @nogc @safe pure nothrow {
        super(msg, file, line, next);
    }
    // mixin BasicExceptionCtors;
}

class ExecutionException : Exception {
    mixin BasicExceptionCtors;
}

class InterruptedException : Exception {
    mixin BasicExceptionCtors;
}

class ParseException : Exception {
    // mixin BasicExceptionCtors;

    /**
     * Constructs a ParseException with the specified detail message and
     * offset.
     * A detail message is a String that describes this particular exception.
     *
     * @param s the detail message
     * @param errorOffset the position where the error is found while parsing.
     */
    public this(string s, int errorOffset=-1) {
        super(s);
        this.errorOffset = errorOffset;
    }

    /**
     * Returns the position where the error was found.
     *
     * @return the position where the error was found
     */
    public int getErrorOffset () {
        return errorOffset;
    }

    //============ privates ============
    /**
     * The zero-based character offset into the string being parsed at which
     * the error was found during parsing.
     * @serial
     */
    private int errorOffset;
}

class TimeoutException : Exception {
    mixin BasicExceptionCtors;
}

class FileNotFoundException : Exception {
    mixin BasicExceptionCtors;
}

class IOException : Exception {
    mixin BasicExceptionCtors;
}

class ClosedChannelException : IOException {
    mixin BasicExceptionCtors;
}

class EOFException : IOException {
    mixin BasicExceptionCtors;
}

class MalformedURLException : IOException {
    mixin BasicExceptionCtors;
}

class InterruptedIOException : IOException {
    mixin BasicExceptionCtors;
}

class RemoteException : IOException {
    mixin BasicExceptionCtors;
}

class URISyntaxException : IOException {
    mixin BasicExceptionCtors;
}

class AsynchronousCloseException : ClosedChannelException {
    mixin BasicExceptionCtors;
}

class CommonRuntimeException : RuntimeException {
    mixin BasicExceptionCtors;
}

class IndexOutOfBoundsException : RuntimeException {
    mixin BasicExceptionCtors;
}

class NegativeArraySizeException : RuntimeException {
    mixin BasicExceptionCtors;
}

class ReadOnlyBufferException : RuntimeException {
    mixin BasicExceptionCtors;
}

class BufferUnderflowException : RuntimeException {
    mixin BasicExceptionCtors;
}

class BufferOverflowException : RuntimeException {
    mixin BasicExceptionCtors;
}

class UnsupportedOperationException : RuntimeException {
    mixin BasicExceptionCtors;
}

class NoSuchElementException : RuntimeException {
    // this()
    // {
    //     super("");
    // }
    mixin BasicExceptionCtors;
}

class NumberFormatException : IllegalArgumentException {
    mixin BasicExceptionCtors;
}

class NullPointerException : RuntimeException {
    mixin BasicExceptionCtors;
}

class EofException : RuntimeException {
    mixin BasicExceptionCtors;
}

class SecureNetException : RuntimeException {
    mixin BasicExceptionCtors;
}

class ArithmeticException : RuntimeException {
    mixin BasicExceptionCtors;
}

class ArrayIndexOutOfBoundsException : IndexOutOfBoundsException {
    mixin BasicExceptionCtors;
}

class IllegalStateException : Exception {
    mixin BasicExceptionCtors;
}

class InvalidMarkException : IllegalStateException {
    mixin BasicExceptionCtors;
}

class WritePendingException : IllegalStateException {
    mixin BasicExceptionCtors;
}

class CancellationException : IllegalStateException {
    mixin BasicExceptionCtors;
}

class OutOfMemoryError : Error {
    // this(string msg, Throwable nextInChain = null)
    // {
    //     super(msg, nextInChain);
    // }

    mixin BasicExceptionCtors;
}

class GeneralSecurityException : Exception {
    mixin BasicExceptionCtors;
}

class CertificateException : GeneralSecurityException {
    mixin BasicExceptionCtors;
}

class NoSuchAlgorithmException : GeneralSecurityException {
    mixin BasicExceptionCtors;
}

class ConcurrentModificationException : RuntimeException {
    mixin BasicExceptionCtors;
}

class InternalError : Exception {
    mixin BasicExceptionCtors;
}

class CRLException : GeneralSecurityException {
    mixin BasicExceptionCtors;
}

class NoSuchProviderException : Exception {
    mixin BasicExceptionCtors;
}

class CertificateNotYetValidException : Exception {
    mixin BasicExceptionCtors;
}

class CertificateExpiredException : Exception {
    mixin BasicExceptionCtors;
}

class SignatureException : Exception {
    mixin BasicExceptionCtors;
}

class CertificateEncodingException : Exception {
    mixin BasicExceptionCtors;
}

class ParsingException : Exception {
    mixin BasicExceptionCtors;
}

class CertificateParsingException : ParsingException {
    mixin BasicExceptionCtors;
}

class InvalidKeyException : Exception {
    mixin BasicExceptionCtors;
}

class KeyStoreException : Exception {
    mixin BasicExceptionCtors;
}

class UnrecoverableKeyException : Exception {
    mixin BasicExceptionCtors;
}

class KeyManagementException : Exception {
    mixin BasicExceptionCtors;
}

class StringIndexOutOfBoundsException : Exception {
    mixin BasicExceptionCtors;
}

class IllegalThreadStateException : IllegalArgumentException {
    mixin BasicExceptionCtors;
}

class IllegalMonitorStateException : RuntimeException {
    mixin BasicExceptionCtors;
}

class NestedRuntimeException : Exception {
    mixin BasicExceptionCtors;
}

class InvalidClassException : Exception {
    mixin BasicExceptionCtors;
}

class InvalidObjectException : Exception {
    mixin BasicExceptionCtors;
}

class ClassCastException : Exception {
    mixin BasicExceptionCtors;
}