module hunt.concurrent.exception;

import hunt.lang.exception;

class CompletionException : Exception
{
    mixin BasicExceptionCtors;
}

class ConcurrentModificationException : RuntimeException
{
    mixin BasicExceptionCtors;
}

class RejectedExecutionException : RuntimeException
{
    mixin BasicExceptionCtors;
}
