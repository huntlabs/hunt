/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.net
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.event.selector.iocp;

// dfmt off
version (Windows) : 
// dfmt on

import hunt.event.core;
import hunt.event.socket;
import hunt.event.timer;
import hunt.logging;
import hunt.sys.error;

import core.sys.windows.windows;
import std.conv;

/**
*/
class AbstractSelector : Selector {
    this() {
        _iocpHandle = CreateIoCompletionPort(INVALID_HANDLE_VALUE, null, 0, 0);
        if (_iocpHandle is null)
            errorf("CreateIoCompletionPort failed: %d\n", GetLastError());
        _event = new EventChannel(this);
        _timer.init();
    }

    ~this() {
        // import std.socket;
        // std.socket.close(_iocpHandle);
    }

    override bool register(AbstractChannel channel) {
        assert(channel !is null);
        ChannelType ct = channel.type;
        auto fd = channel.handle;
        version (HUNT_DEBUG)
            tracef("register, channel(fd=%d, type=%s)", fd, ct);

        if (ct == ChannelType.Timer) {
            AbstractTimer timerChannel = cast(AbstractTimer) channel;
            assert(timerChannel !is null);
            if (!timerChannel.setTimerOut())
                return false;
            _timer.timeWheel().addNewTimer(timerChannel.timer, timerChannel.wheelSize());
        } else if (ct == ChannelType.TCP
                || ct == ChannelType.Accept || ct == ChannelType.UDP) {
            version (HUNT_DEBUG)
                trace("Run CreateIoCompletionPort on socket: ", fd);

            _event.setNext(channel);
            CreateIoCompletionPort(cast(HANDLE) fd, _iocpHandle,
                    cast(size_t)(cast(void*) channel), 0);
        } else {
            warningf("Can't register a channel: %s", ct);
        }
        return true;
    }

    override bool reregister(AbstractChannel channel) {
        throw new LoopException("IOCP does not support reregister!");
    }

    override bool deregister(AbstractChannel channel) {
        // FIXME: Needing refactor or cleanup -@Administrator at 8/28/2018, 3:28:18 PM
        // https://stackoverflow.com/questions/6573218/removing-a-handle-from-a-i-o-completion-port-and-other-questions-about-iocp
        //tracef("deregister (fd=%d)", channel.handle);

        // IocpContext _data;
        // _data.channel = channel;
        // _data.operation = IocpOperation.close;
        // PostQueuedCompletionStatus(_iocpHandle, 0, 0, &_data.overlapped);

        return true;
    }

    void weakUp() {
        IocpContext _data;
        _data.channel = _event;
        _data.operation = IocpOperation.event;

        // PostQueuedCompletionStatus(_iocpHandle, 0, 0, &_data.overlapped);
        PostQueuedCompletionStatus(_iocpHandle, 0, 0, null);
    }

    override void onLoop(scope void delegate() weakup, long timeout = -1) {
        _timer.init();
        super.onLoop(weakup, timeout);
    }

    override protected int doSelect(long t) {
        auto timeout = _timer.doWheel();
        OVERLAPPED* overlapped;
        ULONG_PTR key = 0;
        DWORD bytes = 0;

        // const int ret = GetQueuedCompletionStatus(_iocpHandle, &bytes,
        //         &key, &overlapped, INFINITE);
        // tracef("GetQueuedCompletionStatus, ret=%d", ret);

        // trace("timeout=", timeout);
        const int ret = GetQueuedCompletionStatus(_iocpHandle, &bytes, &key,
                &overlapped, timeout);

        IocpContext* ev = cast(IocpContext*) overlapped;
        if (ret == 0) {
            const auto erro = GetLastError();
            // About ERROR_OPERATION_ABORTED
            // https://stackoverflow.com/questions/7228703/the-i-o-operation-has-been-aborted-because-of-either-a-thread-exit-or-an-applica
            if (erro == WAIT_TIMEOUT || erro == ERROR_OPERATION_ABORTED) // 
                return ret;
            
            debug errorf("error occurred, code=%d, message: %s", erro, getErrorMessage(erro));
            assert(ev !is null);
            // if (ev !is null) {
            AbstractChannel channel = ev.channel;
            if (channel !is null && !channel.isClosed())
                channel.close();
            // }
        } else if (ev is null || ev.channel is null)
            warning("ev is null or ev.watche is null");
        else
            handleIocpOperation(ev.operation, ev.channel, bytes);
        return ret;
    }

    private void handleIocpOperation(IocpOperation op, AbstractChannel channel, DWORD bytes) {

        version (HUNT_DEBUG)
            info("ev.operation: ", op);

        switch (op) {
        case IocpOperation.accept:
            channel.onRead();
            break;
        case IocpOperation.connect:
            onSocketRead(channel, 0);
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
            warning("close: ",);
            break;
        default:
            warning("unsupported operation type: ", op);
            break;
        }
    }

    override void stop() {
        super.stop();
        weakUp();
    }

    void handleTimer() {

    }

    override void dispose() {

    }

    private void onSocketRead(AbstractChannel channel, size_t len) {
        debug if (channel is null) {
            warning("channel is null");
            return;
        }

        if (len == 0 || channel.isClosed) {
            version (HUNT_DEBUG)
                info("channel closed");
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

private:
    HANDLE _iocpHandle;
    EventChannel _event;
    CustomTimer _timer;
}
