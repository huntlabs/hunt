module kiss.event.selector.iocp;

// dfmt off
version (Windows) : 

deprecated("Using AbstractSelector instead!")
alias IOCPLoop = AbstractSelector;

// dfmt on

import kiss.event.socket;

import kiss.event.core;
import kiss.event.socket.iocp;
import kiss.event.timer;

import core.sys.windows.windows;
import std.conv;
import std.experimental.logger;

/**
*/
class AbstractSelector : Selector
{
    this()
    {
        _IOCPFD = CreateIoCompletionPort(INVALID_HANDLE_VALUE, null, 0, 0);
        _event = new EventChannel(this);
        _timer.init();
    }

    ~this()
    {
        // .close(_IOCPFD);
    }

    override bool register(AbstractChannel watcher)
    {
        assert(watcher !is null);

        if (watcher.type == WatcherType.Timer)
        {
            AbstractTimer wt = cast(AbstractTimer) watcher;
            assert(wt !is null);
            if (wt is null || !wt.setTimerOut())
                return false;
            _timer.timeWheel().addNewTimer(wt.timer, wt.wheelSize());
        }
        else if (watcher.type == WatcherType.TCP
                || watcher.type == WatcherType.Accept || watcher.type == WatcherType.UDP)
        {
            version (KissDebugMode)
                trace("Run CreateIoCompletionPort on socket: ", watcher.handle);
            CreateIoCompletionPort(cast(HANDLE) watcher.handle, _IOCPFD,
                    cast(size_t)(cast(void*) watcher), 0);
        }

        version (KissDebugMode)
            infof("register, watcher(fd=%d, type=%s)", watcher.handle, watcher.type);
        _event.setNext(watcher);
        return true;
    }

    override bool reregister(AbstractChannel watcher)
    {
        throw new LoopException("The IOCP does not support reregister!");
    }

    override bool deregister(AbstractChannel watcher)
    {

        // IocpContext _data;
        // _data.watcher = watcher;
        // _data.operation = IocpOperation.close;
        // PostQueuedCompletionStatus(_IOCPFD, 0, 0, &_data.overlapped);

        return true;
    }

    void weakUp()
    {
        IocpContext _data;
        _data.watcher = _event;
        _data.operation = IocpOperation.event;

        PostQueuedCompletionStatus(_IOCPFD, 0, 0, &_data.overlapped);
    }

    void onLoop(scope void delegate() handler)
    {
        _runing = true;
        _timer.init();
        do
        {
            handler();
            auto timeout = _timer.doWheel();
            OVERLAPPED* overlapped;
            ULONG_PTR key = 0;
            DWORD bytes = 0;

            debug
            {
                // const int ret = GetQueuedCompletionStatus(_IOCPFD, &bytes,
                //         &key, &overlapped, INFINITE);
                // tracef("GetQueuedCompletionStatus, ret=%d", ret);

                // trace("timeout=", timeout);
                const int ret = GetQueuedCompletionStatus(_IOCPFD, &bytes,
                        &key, &overlapped, timeout);
            }
            else
            {
                const int ret = GetQueuedCompletionStatus(_IOCPFD, &bytes,
                        &key, &overlapped, timeout);
            }

            if (ret == 0)
            {
                const auto erro = GetLastError();
                if (erro == WAIT_TIMEOUT ) // || erro == ERROR_OPERATION_ABORTED
                    continue;

                error("error occurred, code=", erro);
                auto ev = cast(IocpContext*) overlapped;
                if (ev && ev.watcher)
                    ev.watcher.close();
                continue;
            }

            auto ev = cast(IocpContext*) overlapped;
            if (ev is null || ev.watcher is null)
            {
                warning("ev is null: ", ev is null);
                continue;
            }

            version (KissDebugMode)
                trace("ev.operation: ", ev.operation);

            switch (ev.operation)
            {
            case IocpOperation.accept:
                ev.watcher.onRead();
                break;
            case IocpOperation.connect:
                setStreamRead(ev.watcher, 0);
                break;
            case IocpOperation.read:
                setStreamRead(ev.watcher, bytes);
                break;
            case IocpOperation.write:
                setStreamWrite(ev.watcher, bytes);
                break;
            case IocpOperation.event:
                ev.watcher.onRead();
                break;
            case IocpOperation.close:
                warning("close: ");
                break;
            default:
                warning("unsupported type: ", ev.operation);
                break;
            }

        }
        while (_runing);
    }

    override void stop()
    {
        _runing = false;
        weakUp();
    }

    void handleTimer()
    {

    }

    void setStreamRead(AbstractChannel wt, size_t len)
    {
        AbstractStream io = cast(AbstractStream) wt;
        assert(io !is null, "The type of channel is: " ~ to!string(typeid(wt)));
        if (io is null)
        {
            warning("The channel socket is null: ", typeid(wt));
            return;
        }
        io.setRead(len);
        wt.onRead();
    }

    private void setStreamWrite(AbstractChannel wt, size_t len)
    {
        AbstractStream client = cast(AbstractStream) wt;
        assert(client !is null, "The type of channel is: " ~ to!string(typeid(wt)));

        client.onWriteDone(len); // Notify the client about how many bytes actually sent.
    }

    void dispose()
    {

    }

private:
    bool _runing;
    HANDLE _IOCPFD;
    EventChannel _event;
    CustomTimer _timer;
}
