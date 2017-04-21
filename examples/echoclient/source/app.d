/*
 * Kiss - A simple base net library
 *
 * Copyright (C) 2017 Shanghai Putao Technology Co., Ltd 
 *
 * Developer: putao's Dlang team
 *
 * Licensed under the Apache-2.0 License.
 *
 */

import kiss.aio.AsyncTcpBase;

import kiss.event.Poll;
import kiss.time.Timer;
import kiss.aio.AsyncTcpClient;
import kiss.util.Log;

import std.string;

class EchoClient : AsyncTcpClient
{
	this(Group poll)
	{
		readBuff = new byte[1024];
		super(poll);
	}

	override bool onEstablished()
	{
		log_info( "onEstablished");
		_echo_time = poll.addTimer(this , 5000 , WheelType.WHEEL_PERIODIC);
		return super.onEstablished();
	}

	override protected bool doRead(byte[] buffer , int len)
	{
		log_info( "client1 server return back:" ~ cast(string)buffer[0..len]);
		return true;
	}

	override bool onTimer(TimerFd fd , ulong ticks)
	{
		if(fd == _echo_time)
		{
			if( doWrite(cast(byte[])"hello world" , null , null) < 0)
				return false;
			return true;
		}
		else
		{
			return super.onTimer(fd , ticks);
		}
	}

	override bool onClose()
	{
		if(_echo_time !is null)
		{
			poll.delTimer(_echo_time);
			_echo_time = null;
		}

		return super.onClose();
	}

	private TimerFd _echo_time;

}



class EchoClient2 : AsyncTcpClient
{
	this(Group poll)
	{
		readBuff = new byte[1024];
		super(poll);
	}

	override protected bool doRead(byte[] buffer , int len)
	{
		log_info("server return back:" ~ cast(string)buffer[0..len]);
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


	//client 1 for timeout send msg.
	auto client = new  EchoClient(poll);
	client.open("127.0.0.1" , 82);

	auto client2 = new EchoClient2(poll);
	client2.open("127.0.0.1" , 82);


	poll.start();

	do
	{
		string str = strip(readln());
		if(str == "exit")
			break;		
		client2.doWrite(cast(byte[])str , null , null);
	}while(1);

	poll.stop();
	poll.wait();


	client.destroy();
	client2.destroy();



	return 0;
}




