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



interface AcceptCompletionHandle 
{
    void completed(void* attachment, AsynchronousSocketChannel result);
    void failed(void* attachment);
}

interface ConnectCompletionHandle 
{
    void completed(void* attachment);
    void failed(void* attachment);
}

interface ReadCompletionHandle 
{
    void completed(void* attachment, size_t count , ByteBuffer buffer);
    void failed(void* attachment);
}

interface WriteCompletionHandle 
{
    void completed(void* attachment, size_t count , ByteBuffer buffer);
    void failed(void* attachment);
}


interface CompletionHandle {
    void completed(AIOEventType eventType, void* attachment, void* p1 = null, void* p2 = null);
    void failed(AIOEventType eventType, void* attachment);
}
