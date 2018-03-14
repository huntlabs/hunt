module kiss.net.TcpStream;

import kiss.event;
public import kiss.net.struct_;

import std.experimental.logger;
import std.exception;

debug __gshared int streamCounter = 0;


deprecated("Using TcpStream instead.")
{
    alias TCPSocket = TcpStream;
    alias TcpStreamClient = TcpStream;
}

//No-Thread-safe
@trusted class TcpStream : Transport
{
    private Socket m_socket;

	//for client side
	this(EventLoop loop,AddressFamily amily = AddressFamily.INET)
    {
        _loop = loop;
        _watcher = cast(TcpStreamWatcher)loop.createWatcher(WatcherType.TCP);
        _watcher.setFamily(amily);
        _watcher.watcher(this);
        m_socket = _watcher.socket;

		_isClientSide = true;
		_isConnected = false;
        _family = amily;
	}

	//for server side
    this(EventLoop loop,Socket socket)
    {
        _loop = loop;
        _watcher = cast(TcpStreamWatcher)loop.createWatcher(WatcherType.TCP);
        _watcher.setSocket(socket);
        _watcher.watcher(this);
        m_socket = socket;

		_isClientSide = false;
		_isConnected = true;


        debug synchronized{
        streamCounter++;
        _watcher.number = streamCounter;
        }

    }

	bool connect(Address addr)
	{
		bool watch_ = watch();
		if(watch_){
			watch_ = watch_ && eventLoop.connect(_watcher,addr);
		}
		return watch_;
	}
    
    bool reconnect(Address addr) {
        _watcher = null;
        _watcher = cast(TcpStreamWatcher)_loop.createWatcher(WatcherType.TCP);
        _watcher.setFamily(_family);
        _watcher.watcher(this);
        m_socket = _watcher.socket;
        return connect(addr);
    }

    mixin TransportSocketOption;

    TcpStream setCloseHandle(CloseCallBack cback){
        _closeBack = cback;
        return this;
    }
    TcpStream setReadHandle(TcpReadCallBack cback){
        _readBack = cback;
        return this;
    }

	TcpStream setConnectHandle(TcpConnectCallBack cback){
		_connectBack = cback;
		return this;
	}

	bool isConnected() nothrow {return _isConnected;}

    override bool watched(){
        return _watcher.active;
    }

    override bool watch() {
        debug trace("watcher fd=", typeid(_watcher));
        return _loop.register(_watcher);
    }

    override void close(){
        if(_watcher.active)
            onClose(_watcher);
        else
        {
            debug warningf("The watcher(fd=%d) has already been closed", _watcher.fd);
        }
    }

    TcpStream write(StreamWriteBuffer data){
		if(!_isConnected)
			throw new Exception("The Client is not connect!");  

        if(_watcher.active){
            _writeQueue.enQueue(data);
            onWrite(_watcher);
        } else {
            warningf("The watcher(fd=%d) is down!", _watcher.fd);
            data.doFinish();
        }
        return this;
    }

    final EventLoop eventLoop(){return _loop;}

protected:
	bool			_isClientSide ;
	bool			_isConnected;		//if server side always true.
	TcpConnectCallBack _connectBack;
    TcpStreamWatcher _watcher;
    CloseCallBack _closeBack;
    TcpReadCallBack _readBack;
    WriteBufferQueue _writeQueue;

    override void onRead(Watcher watcher) nothrow{
        catchAndLogException((){
            bool canRead =  true;
            debug trace("start to read");
            while(canRead && watcher.active)
            {
                debug trace("reading...");

                canRead = _loop.read(watcher,(Object obj) nothrow {
                    collectException((){
                        auto buffer = cast(TcpStreamWatcher.UbyteArrayObject)obj;
                        if(buffer is null){
                            warning("buffer is null. The watcher will be closed.");
                            watcher.close(); 
                            return;
                        }
                        _readBack(buffer.data);
                    }());
                });

                if(watcher.isError){
                    errorf("Socket error on read: fd=%d, message: %s", watcher.fd, watcher.erroString); 
                    canRead = false;
                    watcher.close();
                }
            }
        }());
    }

    override void onClose(Watcher watcher) nothrow{

		if(!_isConnected){
			collectExceptionMsg(eventLoop.deregister(watcher));
			if(_connectBack)
				_connectBack(false);
			return;
		}
		_isConnected = false;

        catchAndLogException((){
            debug infof("onClose=>watcher[%d].fd=%d, active=%s", watcher.number, 
                watcher.fd, watcher.active);
            watcher.close();
            while(!_writeQueue.empty){
                StreamWriteBuffer buffer = _writeQueue.deQueue();
                buffer.doFinish();
            }

            if(_closeBack)
                _closeBack();
        }());
    }

    override void onWrite(Watcher watcher) nothrow{

		if(!_isConnected){
			_isConnected = true;
			if(_connectBack)
				_connectBack(true);
			return;
		}

        catchAndLogException((){
            bool canWrite = true;

            debug trace("start to write");

            while(canWrite && watcher.active && !_writeQueue.empty) //  && !_writeQueue.empty
            {
                debug trace("writting...");

                StreamWriteBuffer buffer = _writeQueue.front();
                const(ubyte[]) data = buffer.sendData();
                if(data.length == 0){
                    buffer.doFinish();
                    continue;
                }

                debug infof("onWrite=>streamCounter[%d], data length=%d", 
                    watcher.number,  data.length );
                
                size_t writedSize;
                canWrite = _loop.write(_watcher,data,writedSize);
                debug trace("writedSize=", writedSize);
                if(writedSize == 0 && data.length>0)
                {
                    warning("No data written!");
                    break;
                }

                if(buffer.popSize(writedSize)){
                    buffer.doFinish();
                    if(watcher.active)
                    _writeQueue.deQueue();
                }

                if(watcher.isError){
                    errorf("Socket error on write: fd=%d, message=%s", watcher.fd, watcher.erroString); 
                    canWrite = false;
                    watcher.close();
                }
            }
        }());
    }

private:
    EventLoop _loop;
    AddressFamily _family;
}
