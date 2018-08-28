/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.cn
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
import std.stdio;

import hunt.common;

import hunt.logging;
import core.thread;
import core.time;
import hunt.util.timer;

version (NativeTimer)
{
	void main()
	{
		int count1 = 10;
		int count2 = 6;

		void onTimerTick(Object sender)
		{
			trace("Countdown[1]: ", count1--);
			if (count1 == 0)
			{
				ITimer timer = cast(ITimer) sender;
				timer.stop();
			}
			else if (count1 == 5)
			{
				trace("reset timer1's interval to 2 secondes");
				ITimer timer = cast(ITimer) sender;
				timer.reset(2.seconds);
			}
		}

		new HuntNativeTimer(1.seconds).onTick(&onTimerTick).start();

		new HuntNativeTimer().interval(2.seconds).onTick(delegate void(Object sender) {
			trace("Countdown[2]: ", count2--);
			if (count2 == 0)
			{
				ITimer timer = cast(ITimer) sender;
				timer.stop();
			}
		}).start();

		writeln("\r\nHit return to exit. \r\n");
		getchar();
	}

}
else
{

	import hunt.event;

	void main()
	{
		EventLoop loop = new EventLoop();

		bool isTimer1Running = true;
		bool isTimer2Running = true;

		void checkTimer()
		{
			if (isTimer1Running || isTimer2Running)
				return;

			writeln("\r\nAll timers stopped (hit return to exit)");
			getchar();
			loop.stop();
			// FIXME: noticed by zxp @ 4/16/2018, 1:47:45 PM
			// core.exception.InvalidMemoryOperationError@src/core/exception.d(696): Invalid memory operation

		}

		int count1 = 10;
		void onTimerTick(Object sender)
		{
			trace("Countdown[1]: ", count1--);
			if (count1 == 0)
			{
				ITimer timer = cast(ITimer) sender;
				timer.stop();
				isTimer1Running = false;
				checkTimer();
			}
			else if (count1 == 5)
			{
				trace("reset the timer1's interval to 2 secondes");
				ITimer timer = cast(ITimer) sender;
				timer.reset(2.seconds);
			}
		}

		new HuntTimer(loop, 1.seconds).onTick(&onTimerTick).start();

		int count2 = 5;
		new HuntTimer(loop).interval(2.seconds).onTick(delegate void(Object sender) {
			trace("Countdown[2]: ", count2--);
			if (count2 == 0)
			{
				ITimer timer = cast(ITimer) sender;
				timer.stop();
				isTimer2Running = false;
				checkTimer();
			}
		}).start();

		loop.run();
	}
}
