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
module kiss.event.Poll;

import kiss.event.Event;
import kiss.time.Timer;


interface Poll
{
	bool addEvent(Event event , int fd , IOEventType type);
	bool delEvent(Event event , int fd , IOEventType type);
	bool modEvent(Event event , int fd , IOEventType type);

	bool poll(int milltimeout);

	TimerFd addTimer(Timer timer , ulong interval , WheelType type);
	void delTimer(TimerFd fd);

	// thread 
	void start();
	void stop();
	void wait();
}


interface Group
{
	Poll[] polls();
	void start();
	void stop();	
	void wait();	
}