import kiss.aio.AsyncTcpBase;

import kiss.event.Poll;
import std.conv;
import std.stdio;


class MyHttpChannel : AsyncTcpBase
{
	this(Group poll)
	{
		readBuff = new byte[1024];
		super(poll);
	}

	override protected bool onEstablished()
	{
		writeln("MyHttpChannel connected");
		return super.onEstablished();
	}
	
	override protected bool doRead(byte[] buffer , int len)
	{
		writeln("MyHttpChannel doRead");
		string http_content = "HTTP/1.0 200 OK\r\nServer: kiss\r\nContent-Type: text/plain\r\nContent-Length: 10\r\n\r\nhelloworld";
		doWrite(cast(byte[])http_content , this , 
			delegate void(Object o){
				writeln("MyHttpChannel dowrite finish");
				close();
			}
			);
		return true;
	}
	
	override protected  bool onClose() {
		writeln("MyHttpChannel onClose");
		return super.onClose();
	}
	
}

int main()
{

	import kiss.event.GroupPoll;
	import kiss.aio.AsyncTcpBase;
	import kiss.aio.AsyncTcpClient;
	import kiss.aio.AsyncTcpServer;

	auto poll = new GroupPoll!();
	auto server = new AsyncTcpServer!MyHttpChannel(poll);
	server.open("0.0.0.0" , 81);

	poll.start();
	poll.wait();

	return 0;
}




