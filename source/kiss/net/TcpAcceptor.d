


module kiss.net.TcpAcceptor;

import kiss.aio.CompletionHandle;
import kiss.aio.AsynchronousSocketChannel;
import kiss.aio.AsynchronousChannelSelector;
import kiss.aio.AsynchronousServerSocketChannel;


class TcpAcceptor : AcceptCompletionHandle {
public:
    this(string ip, ushort port, AsynchronousChannelSelector sel) {
        _acceptor = AsynchronousServerSocketChannel.open(sel);
        _acceptor.bind(ip, port);
        _acceptor.accept(null, this);
    }
    abstract void onAcceptCompleted(void* attachment, AsynchronousSocketChannel result);
    abstract void onAcceptFailed(void* attachment);
protected:

    AsynchronousServerSocketChannel _acceptor;
}