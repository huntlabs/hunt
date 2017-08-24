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
    void acceptCompleted(void* attachment, AsynchronousSocketChannel result);
    void acceptFailed(void* attachment);
}

interface ConnectCompletionHandle 
{
    void connectCompleted(void* attachment);
    void connectFailed(void* attachment);
}

interface ReadCompletionHandle 
{
    void readCompleted(void* attachment, size_t count , ByteBuffer buffer);
    void readFailed(void* attachment);
}

interface WriteCompletionHandle 
{
    void writeCompleted(void* attachment, size_t count , ByteBuffer buffer);
    void writeFailed(void* attachment);
}


interface CompletionHandle {
    void completed(AIOEventType eventType, void* attachment, void* p1 = null, void* p2 = null);
    void failed(AIOEventType eventType, void* attachment);
}
