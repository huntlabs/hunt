/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2018-2019 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.concurrency.FuturePromise;

import hunt.concurrency.Future;
import hunt.concurrency.Promise;

import hunt.Exceptions;
import hunt.logging.ConsoleLogger;

import core.atomic;
import core.sync.condition;
import core.sync.mutex;
import core.thread;
import std.format;
import std.datetime;

/**
 * 
 */
class FuturePromise(T) : Future!T, Promise!T {
	private __gshared Exception COMPLETED;
	private shared bool _done;
	private Exception _cause;
	private string _id;
	private Mutex _doneLocker;
	private Condition _doneCondition;

	shared static this() {
		COMPLETED = new Exception("");
	}

	this() {
		_doneLocker = new Mutex();
		_doneCondition = new Condition(_doneLocker);
	}

	string id() {
		return _id;
	}

	void id(string id) {
		_id = id;
	}

static if(is(T == void)) {
		
	void succeeded() {
		_doneLocker.lock();
		scope (exit)
			_doneLocker.unlock();

		if (cas(&_done, false, true)) {
			_cause = COMPLETED;
			_doneCondition.notifyAll();
		}
	}

} else {

	private T _result;

	void succeeded(T result) {
		_doneLocker.lock();
		scope (exit)
			_doneLocker.unlock();
		if (cas(&_done, false, true)) {
			_result = result;
			_cause = COMPLETED;
			_doneCondition.notifyAll();
		}
	}

}

	void failed(Exception cause) {
		_doneLocker.lock();
		scope (exit)
			_doneLocker.unlock();
		if (cas(&_done, false, true)) {
			_cause = cause;
			_doneCondition.notifyAll();
		}
	}

	bool cancel(bool mayInterruptIfRunning) {
		_doneLocker.lock();
		scope (exit)
			_doneLocker.unlock();

		if (cas(&_done, false, true)) {
			static if(!is(T == void)) {
				_result = T.init;
			}
			_cause = new CancellationException("");
			_doneCondition.notifyAll();
			return true;
		}
		return false;
	}

	bool isCancelled() {
		_doneLocker.lock();
		scope (exit)
			_doneLocker.unlock();

		if (_done) {
			try {
				// _latch.await();
				// TODO: Tasks pending completion -@zhangxueping at 2019-12-26T15:18:42+08:00
				// 
			} catch (InterruptedException e) {
				throw new RuntimeException(e.msg);
			}
			return typeid(_cause) == typeid(CancellationException);
		}
		return false;
	}

	bool isDone() {
		return _done;
	}

	T get() {
		if (!_done) {
			_doneLocker.lock();
			scope (exit)
				_doneLocker.unlock();
				
			if(!_done) {
				version (HUNT_DEBUG)
					info("Waiting for a promise...");
				_doneCondition.wait();
			}
		}
		version (HUNT_DEBUG) info("Got a promise");

		if (_cause is null) {
			version (HUNT_DEBUG) warning("no cause!");
			new ExecutionException("no cause!");
		}

		if (_cause is COMPLETED) {
			static if(is(T == void)) {
				return;
			} else {
				return _result;
			}
		}

		CancellationException c = cast(CancellationException) _cause;
		if (c !is null) throw c;
		
		version (HUNT_DEBUG) warning(_cause.msg);
		version (HUNT_DEBUG_MORE) warning(_cause);
		throw new ExecutionException(_cause);
	}

	T get(Duration timeout) {
		version (HUNT_DEBUG)
			infof("promise status: isDone=%s", _done);
		if (!_done) {
			_doneLocker.lock();
			scope (exit)
				_doneLocker.unlock();

			if(!_done) {
				version (HUNT_DEBUG)
					infof("Waiting for a promise in %s...", timeout);
				if (!_doneCondition.wait(timeout))
					throw new TimeoutException("Timeout in " ~ timeout.toString());
			}
		}

		if (_cause is COMPLETED) {
			static if(is(T == void)) {
				return;
			} else {
				return _result;
			}
		}

		TimeoutException t = cast(TimeoutException) _cause;
		if (t !is null)
			throw t;

		CancellationException c = cast(CancellationException) _cause;
		if (c !is null)
			throw c;

		throw new ExecutionException(_cause.msg);
	}

	override string toString() {
		static if(is(T == void)) {
			return format("FutureCallback@%x{%b, %b, void}", toHash(), _done, _cause is COMPLETED);
		} else {
			return format("FutureCallback@%x{%b, %b, %s}", toHash(), _done, _cause is COMPLETED, _result);
		}
	}
}
