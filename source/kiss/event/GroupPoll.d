module kiss.event.GroupPoll;

import kiss.event.Epoll;
import kiss.event.Poll;
import kiss.event.select;

import std.random;
import std.parallelism;
import core.thread;
import std.conv;

import kiss.util.log;

version (linux)
{
	alias DefaultPoll = Epoll;
}
else
{
	alias DefaultPoll = select;
}

class GroupPoll(T = DefaultPoll) : Group
{
	// accept_numbers must >= 1 
	this(int timeout = 10, int accept_numbers = 1, int work_numbers = totalCPUs - 1)
	{
		_works_num = work_numbers;
		_accepts_num = accept_numbers;

		assert(accept_numbers >= 1);
		assert(work_numbers >= 0);
		assert(timeout > 0);

		while (accept_numbers--)
			_accept_polls ~= new T(timeout);

		while (work_numbers--)
			_works_polls ~= new T(timeout);

	}

	~this()
	{
		_accept_polls.destroy();
		_works_polls.destroy();
	}

	Poll work_next()
	{
		if (_works_polls.length == 0)
		{
			return accept_next();
		}
		long r = ++_works_index % _works_num;
		return _works_polls[cast(size_t) r];
	}

	Poll accept_next()
	{
		long r = ++_accepts_index % _accepts_num;
		return _accept_polls[cast(size_t) r];
	}

	void start()
	{
		foreach (ref t; _accept_polls)
			t.start();

		foreach (ref t; _works_polls)
			t.start();

	}

	void stop()
	{
		foreach (ref t; _accept_polls)
			t.stop();

		foreach (ref t; _works_polls)
			t.stop();
	}

	void wait()
	{
		foreach (ref t; _accept_polls)
			t.wait();

		foreach (ref t; _works_polls)
			t.wait();

	}

	private Poll[] _accept_polls;
	private Poll[] _works_polls;
	private int _works_index;
	private int _accepts_index;
	private int _works_num;
	private int _accepts_num;

}
