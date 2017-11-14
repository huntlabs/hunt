module kiss.socket.acceptor;

import kiss.event.base;
import kiss.event.loop;
import kiss.event.watcher;
import std.socket;


final class TCPSocket : Transport
{
    
    void setClose(){}
    void setData(){}

    void write(){}

protected:
    override void onRead(Watcher watcher) nothrow{
        try{
            _loop.read(watcher,_readCallBack);
        } catch(Exception e){

        }
    }

    override void onClose(Watcher watcher) nothrow{
        try{
            _loop.close(watcher);
        } catch(Exception e){

        }
    }

    override void onWrite(Watcher watcher) nothrow{

    }

private:
    TcpSocketWatcher _watcher;
    ReadCallBack _readCallBack;
    EventLoop _loop;
}