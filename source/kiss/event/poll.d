module kiss.event.Poll;

import kiss.event.Event;

import kiss.time.timer;


interface Poll
{
	bool addEvent(Event event , int fd , IOEventType type);
	bool delEvent(Event event , int fd , IOEventType type);
	bool modEvent(Event event , int fd , IOEventType type);

	bool poll(int milltimeout);
	bool run(int milltimeout = 10);
	bool stop();

	TimerFd addTimer(Timer timer , ulong interval , WheelType type);
	void delTimer(TimerFd fd);
	
}