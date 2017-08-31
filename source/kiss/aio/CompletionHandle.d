/*
 * KISS - A refined core library for dlang
 *
 * Copyright (C) 2015-2017  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module kiss.aio.CompletionHandle;
import kiss.aio.AsynchronousSocketChannel;
import kiss.aio.ByteBuffer;
import kiss.aio.Event;

alias OnCloseHandle = void delegate();




interface AcceptCompletionHandle 
{
    void onAcceptCompleted(void* attachment, AsynchronousSocketChannel result);
    void onAcceptFailed(void* attachment);
}

interface ConnectCompletionHandle 
{
    void onConnectCompleted(void* attachment);
    void onConnectFailed(void* attachment);
}

interface ReadCompletionHandle 
{
    void onReadCompleted(void* attachment, size_t count , ByteBuffer buffer);
    void onReadFailed(void* attachment);
}

interface WriteCompletionHandle 
{
    void onWriteCompleted(void* attachment, size_t count , ByteBuffer buffer);
    void onWriteFailed(void* attachment);
}

