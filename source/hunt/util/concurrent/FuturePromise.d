module hunt.util.concurrent.FuturePromise;

import hunt.util.concurrent.Future;
import hunt.util.concurrent.Promise;

import hunt.util.exception;
import std.format;
import std.datetime;

import core.thread;
import hunt.logging;

/**
*/
class FuturePromise(T) : Future!T, Promise!T {
	private __gshared static Exception COMPLETED;
    private bool _done;	
    private Exception _cause;
	private T _result;
	private string _id;

    shared static this() {
        COMPLETED = new Exception("");
    }

    this() {
    }

    string id() { return _id; }
	void id(string id) { _id = id; }
    
	void succeeded(T result) {
		if (!_done) {
            _done = true;
			_result = result;
			_cause = COMPLETED;
		}
	}

	
	void failed(Exception cause) {
        if (!_done) {
            _done = true;
			_cause = cause;
		}
	}
	
	bool cancel(bool mayInterruptIfRunning) {
        if (!_done) {
            _done = true;
			_result = T.init;
			_cause = new CancellationException("");
			return true;
		}
		return false;
	}

	
	bool isCancelled() {
		if (_done) {
			try {
				// _latch.await();
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
		// if(!_done)
		// 	throw new ExecutionException("Not done yet.");
		while(!_done) {
			version(HuntDebugMode) warning("Waiting for a promise...");
			// FIXME: Needing refactor or cleanup -@zxp at 9/10/2018, 2:11:03 PM
			// 
			Thread.sleep(20.msecs);
		}
		version(HuntDebugMode) info("Got a promise");
		
		if(_cause is null) {
			warning("no cause!");
			new ExecutionException("no cause!");
		}

		if (_cause is COMPLETED)
			return _result;
		CancellationException c = cast(CancellationException) _cause;
		if (c !is null)
			throw c;
		throw new ExecutionException(_cause.msg);
	}

    T get(Duration timeout) {
		MonoTime before = MonoTime.currTime;
		while(!_done) {
			version(HuntDebugMode) warning("Waiting for a promise...");
			// FIXME: Needing refactor or cleanup -@zxp at 9/10/2018, 2:15:52 PM
			// 
			Thread.sleep(20.msecs);
			Duration timeElapsed = MonoTime.currTime - before;
			if(timeElapsed > timeout)
				break;
		}
		version(HuntDebugMode) infof("promise status: isDone=%s", _done);
		if(!_done)
			throw new TimeoutException();

		if (_cause == COMPLETED)
			return _result;
		
		TimeoutException t = cast(TimeoutException) _cause;
		if (t !is null)
			throw t;
			
		CancellationException c = cast(CancellationException) _cause;
		if (c !is null)
			throw c;

		throw new ExecutionException(_cause.msg);        
    }
	
    override
	string toString() {
		return format("FutureCallback@%x{%b,%b,%s}", toHash(), _done, _cause == COMPLETED, _result);
	}
}