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

module hunt.event.selector.IOCP;

// dfmt off
version (HAVE_IOCP) : 
// dfmt on

import hunt.event.selector.Selector;
import hunt.io.channel.Common;
import hunt.io.channel;
import hunt.event.timer;
import hunt.logging.ConsoleLogger;
import hunt.system.Error;
import hunt.io.channel.iocp.AbstractStream;
import core.sys.windows.windows;
import std.conv;
import std.socket;
import hunt.concurrency.TaskPool;
import std.container : DList;


/**
 * 
 */
class AbstractSelector : Selector {

    this(size_t number, size_t divider,TaskPool pool = null, size_t maxChannels = 1500) {
        _taskPool = pool;
        super(number, divider, maxChannels);
        _iocpHandle = CreateIoCompletionPort(INVALID_HANDLE_VALUE, null, 0, 0);
        if (_iocpHandle is null)
            errorf("CreateIoCompletionPort failed: %d\n", GetLastError());
        _timer.init();
        _stopEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
    }

    ~this() {
        // import std.socket;
        // std.socket.close(_iocpHandle);
    }

    override bool register(AbstractChannel channel) {
        assert(channel !is null);
        ChannelType ct = channel.type;
        auto fd = channel.handle;
        version (HUNT_IO_DEBUG)
            tracef("register, channel(fd=%d, type=%s)", fd, ct);

        if (ct == ChannelType.Timer) {
            AbstractTimer timerChannel = cast(AbstractTimer) channel;
            assert(timerChannel !is null);
            if (!timerChannel.setTimerOut())
                return false;
            _timer.timeWheel().addNewTimer(timerChannel.timer, timerChannel.wheelSize());
        } else if (ct == ChannelType.TCP
                || ct == ChannelType.Accept || ct == ChannelType.UDP) {
            version (HUNT_IO_DEBUG)
                trace("Run CreateIoCompletionPort on socket: ", fd);

            // _event.setNext(channel);
            CreateIoCompletionPort(cast(HANDLE) fd, _iocpHandle,
                    cast(size_t)(cast(void*) channel), 0);

            //cast(AbstractStream)channel)
        } else {
            warningf("Can't register a channel: %s", ct);
        }

        auto stream = cast(AbstractStream)channel;
        if (stream !is null && !stream.isClient()) {
            stream.beginRead();
        }

        return true;
    }

    override bool deregister(AbstractChannel channel) {
        // FIXME: Needing refactor or cleanup -@Administrator at 8/28/2018, 3:28:18 PM
        // https://stackoverflow.com/questions/6573218/removing-a-handle-from-a-i-o-completion-port-and-other-questions-about-iocp
        version(HUNT_IO_DEBUG) 
        tracef("deregister (fd=%d)", channel.handle);

        // IocpContext _data;
        // _data.channel = channel;
        // _data.operation = IocpOperation.close;
        // PostQueuedCompletionStatus(_iocpHandle, 0, 0, &_data.overlapped);
        //(cast(AbstractStream)channel).stopAction();
        //WaitForSingleObject
        return true;
    }

    // void weakUp() {
    //     IocpContext _data;
    //     // _data.channel = _event;
    //     _data.operation = IocpOperation.event;

    //     // PostQueuedCompletionStatus(_iocpHandle, 0, 0, &_data.overlapped);
    //     PostQueuedCompletionStatus(_iocpHandle, 0, 0, null);
    // }

    override void onLoop(long timeout = -1) {
        _timer.init();
        super.onLoop(timeout);
    }

    protected override int doSelect(long t) {
        auto timeout = _timer.doWheel();
        OVERLAPPED* overlapped;
        ULONG_PTR key = 0;
        DWORD bytes = 0;
        IocpContext* ev;

        while( WAIT_OBJECT_0 != WaitForSingleObject(_stopEvent , 0))
        {
            const int ret = GetQueuedCompletionStatus(_iocpHandle, &bytes, &key,
                    &overlapped, INFINITE);

            //IocpContext* ev = cast(IocpContext*) overlapped;
            ev = cast(IocpContext *)( cast(PCHAR)(overlapped) - cast(ULONG_PTR)(&(cast(IocpContext*)0).overlapped));
            if (ret == 0) {

                DWORD dwErr = GetLastError();
                if (WAIT_TIMEOUT == dwErr)
                {
                    continue;
                }
                else
                {
                    AbstractChannel channel = ev.channel;
                    if (channel !is null && !channel.isClosed())
                    {
                        channel.close();
                    }
                    continue;
                }
            }
            //else if (ev is null || ev.channel is null)
            //    warning("ev is null or ev.watche is null");
            else {
                if (0 == bytes && (ev.operation == IocpOperation.read || ev.operation == IocpOperation.write))
                {
                    AbstractChannel channel = ev.channel;
                    if (channel !is null && !channel.isClosed())
                    {
                        channel.close();
                    }
                    continue;
                }else
                {
                    AbstractChannel channel = ev.channel;
                    _array[channel] ~= overlapped;
                    handleChannelEvent(ev.operation, ev.channel, bytes);
                }
            }
        }
        return 0;
    }

    private void handleChannelEvent(IocpOperation op, AbstractChannel channel, DWORD bytes) {

        version (HUNT_IO_DEBUG)
            infof("ev.operation: %s, fd=%d", op, channel.handle);

        switch (op) {
            case IocpOperation.accept:
                channel.onRead();
                break;
            case IocpOperation.connect:
                onSocketRead(channel, 0);
                (cast(AbstractStream)channel).beginRead();
                break;
            case IocpOperation.read:
                onSocketRead(channel, bytes);
                break;
            case IocpOperation.write:
                onSocketWrite(channel, bytes);
                break;
            case IocpOperation.event:
                channel.onRead();
                break;
            case IocpOperation.close:
                break;
            default:
                warning("unsupported operation type: ", op);
            break;
        }
    }

    override void stop() {
        super.stop();
        // weakUp();
        PostQueuedCompletionStatus(_iocpHandle, 0, 0, null);
    }

    void handleTimer() {

    }

    // override void dispose() {

    // }

    private void onSocketRead(AbstractChannel channel, size_t len) {
        debug if (channel is null) {
            warning("channel is null");
            return;
        }

        if (channel is null)
        {
            warning("channel is null");
            return;
        }

        // (cast(AbstractStream)channel).setBusyWrite(false);

        if (len == 0 || channel.isClosed) {
            version (HUNT_IO_DEBUG)
               infof("channel [fd=%d] closed %d  %d", channel.handle, channel.isClosed, len);
            //channel.close();
            return;
        }

        AbstractSocketChannel socketChannel = cast(AbstractSocketChannel) channel;
        // assert(socketChannel !is null, "The type of channel is: " ~ typeid(channel).name);
        if (socketChannel is null) {
            warning("The channel socket is null: ");
        } else {
            socketChannel.setRead(len);
            channel.onRead();
        }
    }

    private void onSocketWrite(AbstractChannel channel, size_t len) {
        debug if (channel is null) {
            warning("channel is null");
            return;
        }
        AbstractStream client = cast(AbstractStream) channel;
        // assert(client !is null, "The type of channel is: " ~ typeid(channel).name);
        if (client is null) {
            warning("The channel socket is null: ");
            return;
        }
        client.onWriteDone(len); // Notify the client about how many bytes actually sent.
    }

    public void  rmEventArray(AbstractChannel channel)
    {
        _array.remove(channel);
    }

private:
    HANDLE _iocpHandle;
    CustomTimer _timer;
    HANDLE _stopEvent;
    OVERLAPPED*[] [AbstractChannel] _array ;
    TaskPool _taskPool;
}
