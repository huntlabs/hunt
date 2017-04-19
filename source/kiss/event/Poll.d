module kiss.event.Poll;

import kiss.event.Event;

import kiss.time.timer;


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