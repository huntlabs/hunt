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
	private shared bool _done = false;
	private bool _isResultAvaliable = false;
	private Exception _cause;
	private string _id;
	shared static this() {
		COMPLETED = new Exception("");
	}

	this() {
	}

	string id() {
		return _id;
	}

	void id(string id) {
		_id = id;
	}

static if(is(T == void)) {
	
	/**
	 * TODO: 
	 * 	1) keep this operation atomic
	 * 	2) return a flag to indicate whether this option is successful.
	 */
	void succeeded() {
		if (cas(&_done, false, true)) {
			_cause = COMPLETED;
			_isResultAvaliable = true;
		} else {
			warning("This promise has been done, and can't be set again.");
		}
	}

} else {

	/**
	 * TODO: 
	 * 	1) keep this operation atomic
	 * 	2) return a flag to indicate whether this option is successful.
	 */
	void succeeded(T result) {
		if (cas(&_done, false, true)) {
			_result = result;
			_cause = COMPLETED;
			_isResultAvaliable = true;
		} else {
			warning("This promise has been done, and can't be set again.");
		}
	}
	private T _result;
}

	/**
	 * TODO: 
	 * 	1) keep this operation atomic
	 * 	2) return a flag to indicate whether this option is successful.
	 */
	void failed(Exception cause) {
		if (cas(&_done, false, true)) {
			_cause = cause;
			_isResultAvaliable = true;
		} else {
			warning("This promise has been done, and can't be set again.");
		}
	}

	bool cancel(bool mayInterruptIfRunning) {
		if (cas(&_done, false, true)) {
			static if(!is(T == void)) {
				_result = T.init;
			}
			_cause = new CancellationException("");
			_isResultAvaliable = true;
			// _doneCondition.notifyAll();
			return true;
		}
		return false;
	}

	bool isCancelled() {
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
		// waitting for the result
		version (HUNT_DEBUG) info("Waiting for a promise...");
		while(!_isResultAvaliable) {
            Thread.yield();
			version(HUNT_DANGER_DEBUG) trace("Waiting for a promise");
		}

		version (HUNT_DEBUG) info("Got a promise");
		assert(_cause !is null);

		if (_cause is COMPLETED) {
			static if(is(T == void)) {
				return;
			} else {
				return _result;
			}
		}

		CancellationException c = cast(CancellationException) _cause;
		if (c !is null) {
			version(HUNT_DEBUG) info("A promise cancelled.");
			throw c;
		}
		
		debug warning("Get a exception in a promise: ", _cause.msg);
		version (HUNT_DEBUG) warning(_cause);
		throw new ExecutionException(_cause);
	}

	T get(Duration timeout) {
		// waitting for the result
		if(!_isResultAvaliable) {
			version (HUNT_DEBUG) {
				infof("Waiting for a promise in %s...", timeout);
			}
            auto start = Clock.currTime;
            while (!_isResultAvaliable && Clock.currTime < start + timeout) {
                Thread.yield();
            }

			if (!_isResultAvaliable) {
				debug warningf("Timeout for a promise in %s...", timeout);
				failed(new TimeoutException("Timeout in " ~ timeout.toString()));
            }

			version (HUNT_DEBUG) {
				auto dur = Clock.currTime - start;
				if(dur > 5.seconds) {
					warningf("Got a promise in %s", dur);
				} else {
					// infof("Got a promise in %s", dur);
				}
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
