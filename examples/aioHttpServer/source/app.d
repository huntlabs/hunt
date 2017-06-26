





import kiss.aio.AsynchronousServerSocketChannel;
import kiss.aio.AsynchronousSocketChannel;
import kiss.aio.AsynchronousChannelThreadGroup;
import kiss.aio.CompletionHandle;
import kiss.aio.ByteBuffer;
import std.socket;
import std.stdio;
import core.thread;
import std.parallelism;


class WriteHandle : WriteCompletionHandle{
	this(TcpServer master)
	{
		_master = master;
	}
	//WriteCompletionHandle 
	void completed(void* attachment, size_t count , ByteBuffer buffer )
	{
        _master._client.close();
	}
	void failed(void* attachment)
	{

	}
private:
	TcpServer _master;
}



class ReadHandle : ReadCompletionHandle{
	this(TcpServer master)
	{
		_master = master;
	}
	//ReadCompletionHandle 
	override void completed(void* attachment, size_t count , ByteBuffer buffer)
	{
        // string s = "HTTP/1.1 200 OK\r\nServer: kissAIO\r\nConnection: close\r\nContent-Type: text/plain\r\nContent-Length: 10\r\n\r\nhelloworld";
        string s = "HTTP/1.1 200 OK\r\nContent-Length: 15\r\n\r\nContent-Type: text/plain; charset=UTF-8\r\nServer: KissAio\r\nDate: Wed, 17 Apr 2013 12:00:00 GMT\r\n\rHello, World!";
        _master.doWrite(cast(byte[])s);

	}
	override void failed(void* attachment)
	{

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

    }
    ~this()
    {

    }

    void doRead()
    {
        bufferRead.clear();
        _client.read(bufferRead, _readHandle, null);
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

private:
    ReadHandle _readHandle;
	WriteHandle _writeHandle;
    ByteBuffer bufferRead;
	ByteBuffer bufferWrite;
}



class TcpAccept : AcceptCompletionHandle{
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
        client.doRead();
        
    }
    override void failed(void* attachment)
    {
        writeln("server accept failed ");
    }
}




void main()
{
    int threadNum = totalCPUs;
    AsynchronousChannelThreadGroup group = AsynchronousChannelThreadGroup.open(10,threadNum);
    for(int i = 0; i < threadNum; i++)
    {
        TcpAccept accept = new TcpAccept("0.0.0.0",20001,group);
    }
    writeln("please open http://0.0.0.0:20001/ on your browser");
    group.start();
    group.wait();
}
