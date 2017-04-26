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



interface AcceptCompletionHandle 
{
    void completed(AsynchronousSocketChannel result , void* attachment);
    void failed(void* attachment);
}

interface ConnectCompletionHandle 
{
    void completed( void* attachment);
    void failed(void* attachment);
}

interface ReadCompletionHandle 
{
    void completed(size_t count , ByteBuffer buffer,void* attachment);
    void failed(void* attachment);
}

interface WriteCompletionHandle 
{
    void completed(size_t count , ByteBuffer buffer, void* attachment);
    void failed(void* attachment);
}