/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2018-2019 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

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
