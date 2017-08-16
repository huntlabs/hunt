





import kiss.aio.AsynchronousServerSocketChannel;
import kiss.aio.AsynchronousSocketChannel;
import kiss.aio.AsynchronousChannelThreadGroup;
import kiss.aio.CompletionHandle;
import kiss.aio.ByteBuffer;
import std.socket;
import std.stdio;
import core.thread;
import std.parallelism;
import std.string;
import std.conv;

import std.stdio;
import std.experimental.logger.core;



class WriteHandle : WriteCompletionHandle {
	this(TcpServer master)
	{
		_master = master;
	}
	//WriteCompletionHandle 
	void completed(void* attachment, size_t count , ByteBuffer buffer )
	{
        if (_master._needClose) {
            _master._client.close();
        }
        // log("write = ",cast(string)(buffer.getExsitBuffer()));
	}
	void failed(void* attachment)
	{

	}
private:
	TcpServer _master;
}



class ReadHandle : ReadCompletionHandle {
	this(TcpServer master)
	{
		_master = master;
	}
	//ReadCompletionHandle 
	override void completed(void* attachment, size_t count , ByteBuffer buffer)
	{
        string readBufer = cast(string)(buffer.getCurBuffer());
        
        if (indexOf(readBufer, "HTTP/1.1") >= 0)
            _master._needClose = false;
        else
            _master._needClose = true;
        
        // log("read = ",readBufer);
        string s = "HTTP/1.1 200 OK\r\nContent-Length: 13\r\nConnection: Keep-Alive\r\nContent-Type: text/plain\r\nServer: Kiss\r\nDate: Wed, 17 Apr 2013 12:00:00 GMT\r\n\r\nHello, World!";
        _master.doWrite(cast(byte[])s);

	}
	override void failed(void* attachment)
	{
        // writeln("read failed");
	}
private:
	TcpServer _master;
}




class TcpServer  {

public:

    this(AsynchronousSocketChannel client)
    {

        _readHandle = new ReadHandle(this);
		_writeHandle = new WriteHandle(this);
        _client = client;
        bufferRead = ByteBuffer.allocate(200);
        bufferWrite = ByteBuffer.allocate(200);

        _needClose = false;

        bufferRead.clear();
        _client.read(bufferRead, _readHandle, null);

    }
    ~this()
    {

    }

   
   void doWrite(byte[] data)
    {
		bufferWrite.clear();
		bufferWrite.put(data);
        _client.write(bufferWrite, _writeHandle, null);	
    }

    void doWrite()
    {
        _client.write(bufferWrite, _writeHandle, null);	
    }

    AsynchronousSocketChannel _client;


public:
    bool _needClose;

private:
    ReadHandle _readHandle;
	WriteHandle _writeHandle;
    ByteBuffer bufferRead;
	ByteBuffer bufferWrite;
}



class TcpAccept : AcceptCompletionHandle {
public:
    this(string ip, ushort port, AsynchronousChannelThreadGroup group)
    {
    
        //socket listen 
        AsynchronousServerSocketChannel serverSocket = AsynchronousServerSocketChannel.open(group);
        serverSocket.bind(ip, port);
        serverSocket.accept(null, this);
    }
    override void completed(void* attachment, AsynchronousSocketChannel result)
    {
        TcpServer client = new TcpServer(result);
        
        
    }
    override void failed(void* attachment)
    {
        writeln("server accept failed ");
    }

}


void testTimer() {
    import kiss.aio.AsynchronousChannelSelector;
    import kiss.util.Timer;

    AsynchronousChannelSelector selector = new AsynchronousChannelSelector(10);
    Timer timer = Timer.create(selector);
    timer.start(2000, (int timerid) {
        writeln("timer callback~~~~~~");
    }, 3);
    selector.start();
    selector.wait();
}

void testServer() {
    int threadNum = totalCPUs;
    AsynchronousChannelThreadGroup group = AsynchronousChannelThreadGroup.open(5,threadNum);
    for(int i = 0; i < threadNum; i++)
    {
        TcpAccept accept = new TcpAccept("0.0.0.0",20001,group);
    }
    writeln("please open http://0.0.0.0:20001/ on your browser");
    group.start();
    group.wait();
}

void main()
{
    testServer();
}