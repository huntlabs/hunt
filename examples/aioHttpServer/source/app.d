





import kiss.aio.AsynchronousServerSocketChannel;
import kiss.aio.AsynchronousSocketChannel;
import kiss.aio.AsynchronousChannelThreadGroup;
import kiss.aio.CompletionHandle;
import kiss.aio.ByteBuffer;
import std.socket;
import std.stdio;
import core.thread;



class WriteHandle : WriteCompletionHandle{
	this(TcpServer master)
	{
		_master = master;
	}
	//WriteCompletionHandle 
	void completed(size_t count , ByteBuffer buffer, void* attachment)
	{

        // _master._client.close();
        _master.doRead();

	}
	void failed(void* attachment)
	{
		writeln("server write failed!",_master._client.getFd());
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
	override void completed(size_t count , ByteBuffer buffer,void* attachment)
	{
        writeln("server read ", cast(string)buffer.getCurBuffer());
        string s = "HTTP/1.1 200 OK\r\nServer: kissAIO\r\nConnection: close\r\nContent-Type: text/plain\r\nContent-Length: 10\r\n\r\nhelloworld";
        _master.doWrite(cast(byte[])s);

	}
	override void failed(void* attachment)
	{
		writeln("server read failed!",_master._client.getFd());
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
       
      

        clientCount = 0;

        //socket listen 
        AsynchronousServerSocketChannel serverSocket = AsynchronousServerSocketChannel.open(group);
        serverSocket.bind(ip, port);
        serverSocket.accept(null, this);
    }
    override void completed(AsynchronousSocketChannel result , void* attachment)
    {
        TcpServer client = new TcpServer(result);
        client.doRead();
        addClient(client);

    }
    override void failed(void* attachment)
    {
        writeln("server accept failed ");
    }


    void addClient(TcpServer client)
    {
        clientCount ++;
    }
   

private:

    int clientCount;

}



void main()
{
    int threadNum = 4;
    AsynchronousChannelThreadGroup group = AsynchronousChannelThreadGroup.open(10,threadNum);
    for(int i = 0; i < threadNum; i++)
    {
        TcpAccept accept = new TcpAccept("0.0.0.0",20000,group);
    }
    group.start();
    group.wait();
}