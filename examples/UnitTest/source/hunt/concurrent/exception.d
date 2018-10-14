module hunt.concurrent.exception;

import hunt.util.exception;

class CompletionException : Exception
{
    mixin BasicExceptionCtors;
}

class ConcurrentModificationException : RuntimeException
{
    mixin BasicExceptionCtors;
}
