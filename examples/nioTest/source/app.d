


import kiss.aio.ServerSocketChannel;
import kiss.aio.SocketChannel;
import kiss.aio.Selector;
import kiss.aio.SelectionKey;
import kiss.aio.ByteBuffer;
import std.stdio;
import std.socket;
import core.thread;


void createClient()
{
	Selector selector = Selector.open();
	SocketChannel sk = SocketChannel.open(); 
	sk.configureBlocking(false);
	sk.connect("0.0.0.0",60001);
	sk.register(selector,SelectionKey.OP_CONNECT);

	new Thread({
		int num = 0;
		while(true)
		{
			//writeln("client selector num =",num);
			num = selector.select(1000);
			if (num <= 0)
				continue;
			for(int i = 0; i < num ; i++) {
				SelectionKey key = selector.selectorKeys[i];
				if (key.isReadable())
				{

				}
				if (key.isWritable())
				{

					key.interestOps(SelectionKey.OP_READ);
				}
				if (key.isConnectable())
				{
					writeln("client isConnectable");
					ByteBuffer buffer = ByteBuffer.allocate(100);
					writeln("client say : hello server!");
					string s = "hello server!";
					byte[] b = cast(byte[])s;
					buffer.put(b);
					key.channel.write(buffer);
					key.interestOps(SelectionKey.OP_READ);
				}
			}
		}
	}).start();
}


void serverTest()
{
	Selector selector = Selector.open();
	ServerSocketChannel listenerChannel = ServerSocketChannel.open(); 
	listenerChannel.socket().bind("0.0.0.0",60001);
	listenerChannel.configureBlocking(false);
	listenerChannel.register(selector, SelectionKey.OP_ACCEPT);


	while(true)
	{
		int num = selector.select(0);
		for(int i = 0; i < num; i++) {
			SelectionKey key = selector.selectorKeys[i];
			if (key.isAcceptable())
			{
				SocketChannel clientChannel = (cast(ServerSocketChannel)(key.channel())).accept();
				clientChannel.configureBlocking(false);
				clientChannel.register(key.selector(), SelectionKey.OP_WRITE, ByteBuffer.allocate(200));
			}
			if (key.isWritable())
			{
				string s = "HTTP/1.0 200 OK\r\nServer: kiss\r\nContent-Type: text/plain\r\nContent-Length: 10\r\n\r\nhelloworld";
				ByteBuffer buf = ByteBuffer.allocate(200);
				buf.put(cast(byte[])s);
				key.channel().write(buf);
				key.channel().close();

			}
		}
	}


	// int index = 0;
	// int num;
	// while(true)
	// {

	// 	index++;
	// 	if (index == 3)
	// 		createClient();

	// 	num = selector.select(1000);
	// 	if (num == 0)
	// 		continue;
		

	// 	for(int i = 0; i < num; i++) {
	// 		SelectionKey key = selector.selectorKeys[i];
	// 		if (key.isAcceptable())
	// 		{
	// 			writeln("key.isAcceptable");
	// 			SocketChannel clientChannel = (cast(ServerSocketChannel)(key.channel())).accept();
	// 			clientChannel.configureBlocking(false);
	// 			clientChannel.register(key.selector(), SelectionKey.OP_READ, ByteBuffer.allocate(100));
	// 		}
	// 		if (key.isReadable())
	// 		{
	// 			writeln("key.isReadable");
	// 			SocketChannel clientChannel = cast(SocketChannel)(key.channel());
	// 			key.attachment().clear();
	// 			long len = clientChannel.read(key.attachment());
	// 			writeln("len = ",len);
	// 			if (len > 0)
	// 			{	
	// 				byte[] buffer = key.attachment().getCurBuffer();
	// 				string s = cast(string)buffer;
	// 				writeln("server recv :" ~ s);
	// 				key.interestOps(SelectionKey.OP_WRITE);
	// 			}

	// 		}
	// 		if (key.isValid() && key.isWritable())
	// 		{
	// 			writeln("key.isWritable");
	// 			key.interestOps(SelectionKey.OP_READ);
	// 		}
	// 	}
	// }
}



void main()
{
	serverTest();
	
	
}