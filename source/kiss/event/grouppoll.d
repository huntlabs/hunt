module kiss.event.GroupPoll;

import kiss.event.Epoll;
import kiss.event.Poll;

import std.random;
import std.parallelism;
import core.thread;

import std.experimental.logger;

import std.conv;









class GroupPoll(T = Epoll) : Group
{
	this(int timeout = 10 , int accept_numbers = 1 , int work_numbers = 0)
	{
		while(accept_numbers--)
			_accept_polls ~= new T(timeout);
			
		int work;
		if(work_numbers == 0)
		{
			work = totalCPUs;
		}
		else
		{
			work = work_numbers;
		}

		while(work--)
			_works_polls ~= new T(timeout);
			
	

	}

	~this()
	{
		 _accept_polls.destroy();
		 _works_polls.destroy();
	}


	Poll work_next()
	{
		int r = uniform(0 , cast(int)_works_polls.length);
		return _works_polls[r];
	}

	Poll accept_next()
	{
		int r = uniform(0 , cast(int)_accept_polls.length);
		return _accept_polls[r];
	}


	void start()
	{
		foreach(ref t ; _accept_polls)
			t.start();


		foreach(ref t ; _works_polls)
			t.start();

	}

	void stop()
	{
		foreach(ref t ; _accept_polls)
			t.stop();

		foreach(ref t; _works_polls)
			t.stop();
	}

	void wait()
	{
		foreach(ref t ; _accept_polls)
			t.wait();

		foreach(ref t ; _works_polls)
			t.wait();

	}

	private Poll[] 		_accept_polls;
	private Poll[]		_works_polls;

}

