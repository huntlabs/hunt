import kiss.aio.AsyncTcpBase;

import kiss.event.Poll;
import std.conv;
import std.stdio;
import std.string;
import std.conv;
import std.experimental.logger;

class MyHttpChannel : AsyncTcpBase
{
	this(Group poll)
	{
		//request must small than 2048.
		readBuff = new byte[2048];
		super(poll);
	}

	override protected bool onEstablished()
	{
		writeln("MyHttpChannel connected");
		return super.onEstablished();
	}

	bool is_request_finish(ref bool finish, ref string url , ref string strbody)
	{
		import std.typecons : No;

		string str = cast(string)_readbuffer[0 .. _index];
		long header_pos = indexOf(str , "\r\n\r\n");

		if( header_pos == -1)
		{
			finish = false;
			return true;
		}

		string strlength = "content-length: ";
		int intlength = 0;
		long pos = indexOf(str , strlength , 0 , No.caseSensitive);
		if( pos != -1)
		{
			long left = indexOf(str , "\r\n" , pos);
			if(pos == -1)
				return false;

			strlength = cast(string)_readbuffer[pos + strlength.length .. left];
			intlength = to!int(strlength);
		}
		 
		log(LogLevel.info , "length : " ~ to!string(intlength) ~ "header : " ~ to!string(header_pos));

		if(header_pos + 4 + intlength == _index)
		{
			finish = true;
		}
		else
		{
			finish = false;
			return true;
		}

		long pos_url = indexOf(str , "\r\n");
		if(pos_url == -1)
			return false;

		auto strs = split(cast(string)_readbuffer[0 .. pos_url]);
		if(strs.length < 3)
			return false;

		url = strs[1];
		strbody = cast(string)_readbuffer[pos + 4 .. _index];

		return true;
	}


	bool process_request(string url , string strbody)
	{
		string http_content = "HTTP/1.0 200 OK\r\nServer: kiss\r\nContent-Type: text/plain\r\nContent-Length: 10\r\n\r\nhelloworld";
		return doWrite(cast(byte[])http_content , null , 
						delegate void(Object o){
						close();
						});
			
	}


	override protected bool doRead(byte[] buffer , int len)
	{

		_index += len;
		bool finish ;
		string strurl;
		string strbody;

		log(LogLevel.info , "index : " ~ to!string(_index));

		if(!is_request_finish(finish , strurl , strbody))
		{
			log(LogLevel.info  , "parse http request error");
			return false;
		}

		if(finish)
		{
			_index = 0;
			return process_request(strurl , strbody);
		}
		else if(_index == _readbuffer.length)
		{
			log(LogLevel.info , "not a http request or buffer is full");
			return false;
		}


		return true;
	}
	
	override protected  bool onClose() {
		writeln("MyHttpChannel onClose");
		return super.onClose();
	}

	private int _index ;
	
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





