module hunt.util.concurrent.FuturePromise;

import hunt.util.concurrent.Future;
import hunt.util.concurrent.Promise;

import hunt.util.exception;
import std.format;
import std.datetime;

class FuturePromise(C) : Future!C, Promise!C
{
	private static Exception COMPLETED;
    private bool _done;	
    private Exception _cause;
	private C _result;

    static this()
    {
        COMPLETED = new Exception("");
    }

    this()
    {
		// FIXME: Needing refactor or cleanup -@zxp at 7/18/2018, 5:43:37 PM
		// 
        // _cause = COMPLETED;
    }
    
	void succeeded(C result) {
		if (!_done) {
            _done = true;
			_result = result;
			_cause = COMPLETED;
			// _latch.countDown();
		}
	}

	
	void failed(Exception cause) {
        if (!_done) {
            _done = true;
			_cause = cause;
			// _latch.countDown();
		}
	}

	
	bool cancel(bool mayInterruptIfRunning) {
        if (!_done) {
            _done = true;
			_result = C.init;
			_cause = new CancellationException("");
			// _latch.countDown();
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
		return _done; // && _latch.getCount() == 0;
	}

    C get(){
		// _latch.await();
		if(!_done)
			throw new ExecutionException("Not done yet.");
			
		if (_cause is COMPLETED)
			return _result;
		if (typeid(_cause) == typeid(CancellationException))
			throw cast(CancellationException) _cause;
		throw new ExecutionException(_cause.msg);
	}


    C get(long timeout, Duration unit)
    {
		// if (!_latch.await(timeout, unit))
		// 	throw new TimeoutException();
		if(!_done)
			throw new ExecutionException("Not done yet.");

		if (_cause == COMPLETED)
			return _result;
        if (typeid(_cause) == typeid(TimeoutException))
			throw cast(TimeoutException) _cause;
		if (typeid(_cause) == typeid(CancellationException))
			throw cast(CancellationException) _cause;
		throw new ExecutionException(_cause.msg);        
    }
	
    override
	string toString() {
		return format("FutureCallback@%x{%b,%b,%s}", toHash(), _done, _cause == COMPLETED, _result);
	}
}