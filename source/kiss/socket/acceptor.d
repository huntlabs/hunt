module kiss.socket.acceptor;

import kiss.event;
import std.socket;

final class Acceptor : ReadTransport
{
    void listen(Address addr);
    Address listen(){return null;}
    void bind(){}
protected:
    override void onRead(Watcher watcher) nothrow{

    }

    override void onClose(Watcher watcher) nothrow{

    }

private:
    AcceptorWatcher _watcher;
}
