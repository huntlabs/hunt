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

module hunt.concurrency.CountingCallback;

import hunt.util.Common;
import core.atomic;
import std.format;


/**
 * <p>
 * A callback wrapper that succeeds the wrapped callback when the count is
 * reached, or on first failure.
 * </p>
 * <p>
 * This callback is particularly useful when an async operation is split into
 * multiple parts, for example when an original byte buffer that needs to be
 * written, along with a callback, is split into multiple byte buffers, since it
 * allows the original callback to be wrapped and notified only when the last
 * part has been processed.
 * </p>
 * <p>
 * Example:
 * </p>
 * 
 * <pre>
 * void process(EndPoint endPoint, ByteBuffer buffer, Callback callback) {
 * 	ByteBuffer[] buffers = split(buffer);
 * 	CountCallback countCallback = new CountCallback(callback, buffers.length);
 * 	endPoint.write(countCallback, buffers);
 * }
 * </pre>
 */
class CountingCallback : NestedCallback {
	private shared(int) count;

	this(Callback callback, int count) {
		super(callback);
		this.count = count;
	}

	override
	void succeeded() {
		// Forward success on the last success.
		while (true) {
			int current = count;

			// Already completed ?
			if (current == 0)
				return;

			// if (count.compareAndSet(current, current - 1)) 
            if(count == current)
            {
                count = current - 1;
				if (current == 1)
					super.succeeded();
				return;
			}
		}
	}

	override
	void failed(Exception failure) {
		// Forward failure on the first failure.
		while (true) {
			int current = count;

			// Already completed ?
			if (current == 0)
				return;

			// if (count.compareAndSet(current, 0)) 
             if(count == current)
            {
                count = 0;
				super.failed(failure);
				return;
			}
		}
	}

	override
	string toString() {
		return format("%s@%d", typeof(this).stringof, toHash());
	}
}
