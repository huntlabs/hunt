





import kiss.aio.AsynchronousServerSocketChannel;
import kiss.aio.AsynchronousSocketChannel;
import kiss.aio.AsynchronousChannelThreadGroup;
import kiss.aio.CompletionHandle;
import kiss.aio.ByteBuffer;
import std.socket;
import std.stdio;
import core.thread;
import kiss.aio.task;






class WriteHandle : WriteCompletionHandle{
	this(TcpClient master)
	{
		_master = master;
	}
	//WriteCompletionHandle 
	void completed(size_t count , ByteBuffer buffer, void* attachment)
	{
        writeln("client write completed");
        _master.doRead();

	}
	void failed(void* attachment)
	{
		writeln("client write failed!");
	}
private:
	TcpClient _master;
}


class ReadHandle : ReadCompletionHandle{
	this(TcpClient master)
	{
		_master = master;
	}
	//ReadCompletionHandle 
	override void completed(size_t count , ByteBuffer buffer,void* attachment)
	{
        writeln("client recv:",cast(string)buffer.getCurBuffer());
        // string s = "HTTP/1.1 200 OK\r\nServer: kissAIO\r\nConnection: close\r\nContent-Type: text/plain\r\nContent-Length: 10\r\n\r\nhelloworld";
        // _master._client.close();

	}
	override void failed(void* attachment)
	{
		writeln("client read failed!");
	}
private:
	TcpClient _master;
}



class TcpClient : ConnectCompletionHandle {
    this(string ip, int port, AsynchronousChannelThreadGroup group)
    {
        _client = AsynchronousSocketChannel.open(group, group.getWorkSelector());
        _client.connect( ip,  cast(ushort)port,  cast(ConnectCompletionHandle)this, cast(void*)null);
        _writeHandle = new WriteHandle(this);

        _readHandle = new ReadHandle(this);
    }

    void completed( void* attachment) {

    }
    void failed(void* attachment)
    {

    }

    void doWrite(byte[] data)
    {

        ByteBuffer bufferWrite = ByteBuffer.allocate(1024);
		bufferWrite.put(data);
        _client.write(bufferWrite, _writeHandle, null);	
    }


    void doRead()
    {
        ByteBuffer bufferRead = ByteBuffer.allocate(200);
        _client.read(bufferRead, _readHandle, null);
    }

    void hello()
    {
        writeln("hello");
        doWrite(cast(byte[])"hello");
    }

    void sayHello ()
    {
        _client.addTask(newTask(&hello));
    }


private:
    AsynchronousSocketChannel _client;
    
    ReadHandle _readHandle;
    WriteHandle _writeHandle;
}







void main()
{
    int threadNum = 1;
    AsynchronousChannelThreadGroup group = AsynchronousChannelThreadGroup.open(10,threadNum);
    // for(int i = 0; i < threadNum; i++)
    // {
        TcpClient accept = new TcpClient("0.0.0.0",20000,group);
    // }

    new Thread({
        Thread.sleep(3.seconds);
        int index = 5;
        while(index --)
        {
            Thread.sleep(1.seconds);
            accept.sayHello();
        }

    }).start();

    group.start();
    group.wait();
}