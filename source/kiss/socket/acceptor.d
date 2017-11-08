module kiss.socket.acceptor;

import kiss.event.base;
import kiss.event.loop;
import kiss.event.watcher;
import std.socket;

final class Acceptor : ReadTransport
{
    void listen(Address addr);
    Address listen(){return null;}
    void bind(){}
protected:
    override void onRead(Watcher watcher){

    }

    override void onClose(Watcher watcher){

    }

private:
    AcceptorWatcher _watcher;
}