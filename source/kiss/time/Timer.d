/*
 * Kiss - A simple base net library
 *
 * Copyright (C) 2017 Shanghai Putao Technology Co., Ltd 
 *
 * Developer: putao's Dlang team
 *
 * Licensed under the Apache-2.0 License.
 *
 */
module kiss.time.Timer;


alias TimerFd = Object;

enum WheelType{
	WHEEL_ONESHOT,
	WHEEL_PERIODIC,
};

interface Timer
{
	bool onTimer(TimerFd fd , ulong ticks);
}
