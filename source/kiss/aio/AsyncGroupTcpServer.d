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
module kiss.aio.AsyncGroupTcpServer;

import kiss.aio.AsyncTcpServer;
import kiss.event.Poll;

class AsyncGroupTcpServer(T)
{
	this(Group group)
	{
		// Constructor code
		auto polls = group.polls();
		for(int i = 0 ; i < polls.length ; i++)
		{
			_servers ~= new AsyncTcpServer!T(polls[i]);
		}
	}

	bool open(string ipaddr, ushort port ,int back_log = 1024 ,  bool breuse = true)
	{

		for(int i = 0 ; i < _servers.length ; i++)
		{	
			if(!_servers[i].open(ipaddr , port , back_log , breuse))
				return false;
		}
		return true;
	}

	void close()
	{
		for(int i = 0 ; i < _servers.length ; i++)
		{
			_servers[i].close();
		}
	}

	AsyncTcpServer!T[] _servers;
}

