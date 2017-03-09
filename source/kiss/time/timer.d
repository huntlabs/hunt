module kiss.time.timer;


alias TimerFd = Object;

enum WheelType{
	WHEEL_ONESHOT,
	WHEEL_PERIODIC,
};

interface Timer
{
	bool onTimer(TimerFd fd , ulong ticks);
}
