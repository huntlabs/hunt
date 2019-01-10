module hunt.concurrency.exception;

import hunt.Exceptions;

class CompletionException : Exception
{
    mixin BasicExceptionCtors;
}

// class ConcurrentModificationException : RuntimeException
// {
//     mixin BasicExceptionCtors;
// }

class RejectedExecutionException : RuntimeException
{
    mixin BasicExceptionCtors;
}
