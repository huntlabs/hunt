/*
 * KISS - A refined core library for dlang
 *
 * Copyright (C) 2015-2017  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module kiss.aio.task;

import std.traits;

ReturnType!F run(F, Args...)(F fpOrDelegate, ref Args args)
{
	return fpOrDelegate(args);
}

@trusted class AbstractTask
{
	alias TaskFun = void function(AbstractTask);
	this(TaskFun fun)
	{
		_runTask = fun;
	}

	final void job(){
		if(_runTask)
			_runTask(this);
	}

private:
	TaskFun _runTask;

	AbstractTask next;
}


@trusted final class Task(alias fun,Args...) : AbstractTask
{
	static if (Args.length > 0){
		this(Args args){
			_args = args;
			super(&impl);
		}

		Args _args;
	} else {
		this(){
			super(&impl);
		}
		alias _args = void;
	}

	static void impl(AbstractTask myTask){
		auto  myCastedTask = cast(typeof(this)) myTask;
		if(myCastedTask is null) return;
		fun(myCastedTask._args);
	}
}


@trusted auto newTask(alias fun,Args...)(Args args){
	return new Task!(fun,Args)(args);
}

@trusted auto newTask(F, Args...)(F delegateOrFp, Args args)
	if (is(typeof(delegateOrFp(args))))
{
	return new Task!(run, F, Args)(delegateOrFp, args);
}


struct TaskQueue
{
	AbstractTask  front()nothrow{
		return _frist;
	}
	
	bool empty()nothrow{
		return _frist is null;
	}
	
	void enQueue(AbstractTask task) nothrow
	in{
		assert(task);
	}body{
		if(_last){
			_last.next = task;
		} else {
			_frist = task;
		}
		task.next = null;
		_last = task;
	}
	
	AbstractTask deQueue() nothrow
	in{
		assert(_frist && _last);
	}body{
		AbstractTask task = _frist;
		_frist = _frist.next;
		if(_frist is null)
			_last = null;
		return task;
	}
	
private:
	AbstractTask  _last = null;
	AbstractTask  _frist = null;
}