import kiss.aio.AsyncTcpBase;

import kiss.event.Poll;
import std.conv;
import std.stdio;



class EchoBase : AsyncTcpBase
{
	this(Group poll)
	{
		readBuff = new byte[1024];
		super(poll);
	}

	override protected bool doRead(byte[] buffer , int len)
	{
		doWrite(buffer[0 .. len] , null , null);
		return true;
	}

}

int main()
{

	import kiss.event.GroupPoll;
	import kiss.aio.AsyncTcpBase;
	import kiss.aio.AsyncTcpClient;
	import kiss.aio.AsyncTcpServer;

	auto poll = new GroupPoll!();
	auto server = new AsyncTcpServer!EchoBase(poll);
	server.open("0.0.0.0" , 82);

	poll.start();
	poll.wait();


	return 0;
}




