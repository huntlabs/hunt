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

module kiss.aio.WriteBufferData;

import kiss.aio.CompletionHandle;
import kiss.aio.ByteBuffer;


class AsynchronousSelectionKey {
	void* handle;
	void* attchment;
	ByteBuffer obj;
}


class WriteBufferData {
    AsynchronousSelectionKey key;
	WriteBufferData _next;
}

class WriteBufferDataQueue
{
	WriteBufferData  front() nothrow{
		return _frist;
	}

	bool empty() nothrow{
		return _frist is null;
	}

	void enQueue(WriteBufferData wsite) nothrow
	in{
		assert(wsite);
	}body{
		_count++;
		if(_last){
			_last._next = wsite;
		} else {
			_frist = wsite;
		}
		wsite._next = null;
		_last = wsite;
	}

	WriteBufferData deQueue() nothrow
	in{
		assert(_frist && _last);
	}body{
		_count--;
		WriteBufferData  wsite = _frist;
		_frist = _frist._next;
		if(_frist is null)
			_last = null;
		return wsite;
	}

public :
	long _count = 0;
private:
	WriteBufferData  _last = null;
	WriteBufferData  _frist = null;

}



