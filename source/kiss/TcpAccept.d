


module kiss.TcpAccept;

import kiss.aio.CompletionHandle;
import kiss.aio.AsynchronousSocketChannel;
import kiss.aio.AsynchronousChannelThreadGroup;
import kiss.aio.AsynchronousServerSocketChannel;


class TcpAccept : AcceptCompletionHandle {
public:
    this(string ip, ushort port, AsynchronousChannelThreadGroup group) {
        _acceptor = AsynchronousServerSocketChannel.open(group);
        _acceptor.bind(ip, port);
        _acceptor.accept(null, this);
    }
    abstract void acceptCompleted(void* attachment, AsynchronousSocketChannel result);
    abstract void acceptFailed(void* attachment);
protected:

    AsynchronousServerSocketChannel _acceptor;
}