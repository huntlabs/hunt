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

import std.stdio;

import hunt.event.timer.Common;
import hunt.Exceptions;
import hunt.logging;
import hunt.util.Timer;
import hunt.util.DateTime;

import core.thread;
import core.time;

version (NativeTimer) {
	void main() {
		int count1 = 10;
		int count2 = 6;

		void onTimerTick(Object sender) {
			trace("Countdown[1]: ", count1--);
			if (count1 == 0) {
				ITimer timer = cast(ITimer) sender;
				timer.stop();
			}
			else if (count1 == 5) {
				trace("reset timer1's interval to 2 secondes");
				ITimer timer = cast(ITimer) sender;
				timer.reset(2.seconds);
			}
		}

		new NativeTimer(1.seconds).onTick(&onTimerTick).start();

		new NativeTimer().interval(2.seconds).onTick(delegate void(Object sender) {
			trace("Countdown[2]: ", count2--);
			if (count2 == 0) {
				ITimer timer = cast(ITimer) sender;
				timer.stop();
			}
		}).start();

		writeln("\r\nHit return to exit. \r\n");
		getchar();
	}

} else {

	import hunt.event;

	void main() {
		DateTimeHelper.startClock();
		EventLoop loop = new EventLoop();

		bool isTimer1Running = true;
		bool isTimer2Running = true;

		void checkTimer() {
			if (isTimer1Running || isTimer2Running)
				return;
// FIXME: Needing refactor or cleanup -@putao at 1/10/2019, 6:21:11 PM
// Can't exit on mac OS
			writeln("\r\nAll timers stopped (hit return to exit)");
			getchar();
			loop.stop();
		}

		int count1 = 10;
		void onTimerTick(Object sender) {
			trace("Countdown[1]: ", count1--);
			if (count1 == 0) {
				ITimer timer = cast(ITimer) sender;
				timer.stop();
				isTimer1Running = false;
				checkTimer();
			}
			else if (count1 == 5) {
				trace("reset the timer1's interval to 2 secondes");
				ITimer timer = cast(ITimer) sender;
				timer.reset(2.seconds);
			}
		}

		new Timer(loop, 1.seconds).onTick(&onTimerTick).start();

		int count2 = 5;
		new Timer(loop).interval(2.seconds).onTick(delegate void(Object sender) {
			trace("Countdown[2]: ", count2--);
			if (count2 == 0) {
				ITimer timer = cast(ITimer) sender;
				timer.stop();
				isTimer2Running = false;
				checkTimer();
			}
		}).start();

		loop.run(100);

		thread_joinAll();
	}
}
