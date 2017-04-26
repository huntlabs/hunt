









import kiss.aio.AsynchronousSocketChannel;
import kiss.aio.CompletionHandle;
import kiss.aio.AsynchronousChannelThreadGroup;
import kiss.aio.ByteBuffer;

import std.stdio;

import core.thread;

class ReadHandle : ReadCompletionHandle{
	this(Client master)
	{
		_master = master;
	}
	//ReadCompletionHandle 
	override void completed(size_t count , ByteBuffer buffer,void* attachment)
	{
		writeln("client read success! " , cast(string)buffer.getCurBuffer());
	}
	override void failed(void* attachment)
	{
		writeln("client read failed!" ,_master._client.getFd());
	}
private:
	Client _master;
}


class WriteHandle : WriteCompletionHandle{
	this(Client master)
	{
		_master = master;
	}
	//WriteCompletionHandle 
	void completed(size_t count , ByteBuffer buffer, void* attachment)
	{
		writeln("client write success! ", cast(string)buffer.getExsitBuffer());
	}
	void failed(void* attachment)
	{
		writeln("client write failed!",_master._client.getFd());
	}
private:
	Client _master;
}


class ConnectHandle : ConnectCompletionHandle{
	this(Client master)
	{
		_master = master;
	}
	//ConnectCompletionHandle 
	void completed( void* attachment)
	{
		writeln("client connect success! ",_master._client.getFd());
		_master.doRead();
	}
	void failed(void* attachment)
	{
		writeln("client connect failed! ",_master._client.getFd());
		_master.destroy();
	}
private:
	Client _master;
}



class Client 
{

public:
	this(string ip, ushort port, AsynchronousChannelThreadGroup group)
	{
		bufferRead = ByteBuffer.allocate(1024);
        bufferWrite = ByteBuffer.allocate(1024);

		_readHandle = new ReadHandle(this);
		_writeHandle = new WriteHandle(this);
		_connetHandle = new ConnectHandle(this);

		_client = AsynchronousSocketChannel.open(group, group.getIOSelector());
		_client.connect(ip, port, _connetHandle, null);
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
	
private:
	ReadHandle _readHandle;
	WriteHandle _writeHandle;
	ConnectHandle _connetHandle;
	
	AsynchronousSocketChannel _client;
	ByteBuffer bufferRead;
	ByteBuffer bufferWrite;
	
}


void main()
{
	AsynchronousChannelThreadGroup group = AsynchronousChannelThreadGroup.open();
	Client clinet1 = new Client("0.0.0.0", 20000, group);
	Client clinet2 = new Client("0.0.0.0", 20000, group);
	Client clinet3 = new Client("0.0.0.0", 20000, group);
	Client clinet4 = new Client("0.0.0.0", 20000, group);
	Client clinet5 = new Client("0.0.0.0", 20000, group);

	new Thread({
		while(true)
		{
			Thread.sleep(2.seconds);
			clinet1.doWrite(cast(byte[])"echo");
			// clinet2.doWrite(cast(byte[])"echo");
		}
	}).start();


	group.start();
	group.wait();

}