module kiss.time.itimer;

import kiss.time.timer;
import std.experimental.logger;

import std.exception;

import std.stdio;
import core.time;
import std.conv;


const int		WHEEL_BITS1		=		8;
const int		WHEEL_BITS2		=		6;
const int		WHEEL_SIZE1		=		(1 << WHEEL_BITS1);
const int		WHEEL_SIZE2		=		(1 << WHEEL_BITS2);
const int		WHEEL_MASK1		=		(WHEEL_SIZE1 - 1);
const int		WHEEL_MASK2		=		(WHEEL_SIZE2 - 1);
const int		WHEEL_NUM		=		5;

alias uint32_t = uint;
alias uint64_t = ulong;
alias int64_t = long;


final class stNodeLink
{
	stNodeLink 			_prev;
	stNodeLink 			_next;	
	WheelType			_type;
	uint64_t			_interval;
	uint64_t			_tick;			
	Timer				_tm;
	this( Timer tm, uint64_t interval ,WheelType type) 
	{ 
		_tm = tm;
		_interval = interval;
		_type = type;

		_prev = _next = this;
	}

};


final private class stWheel
{
	stNodeLink[] _spokes;
	uint32_t _spokeindex = 0;


	this(uint32_t n)
	{
		while(n--)
			_spokes ~= new stNodeLink(null , 0 , WheelType.WHEEL_ONESHOT);
	}
	~this()
	{
		_spokes.destroy();
	}
};





final class WheelTimer
{
	stWheel[WHEEL_NUM] 		_st;
	static immutable  uint64_t 	_tick_per_mill;
	uint64_t				_checktime;

	static this()
	{
		_tick_per_mill= MonoTime.currTime.ticksPerSecond() / 1000; 	
	}

	static uint64_t now()
	{
		return MonoTime.currTime.ticks() / _tick_per_mill;
	}

	~this()
	{
		for(int i = 0 ; i < WHEEL_NUM ; i++)
			_st[i].destroy();
	}

	this()
	{
		_st[0] = new stWheel(WHEEL_SIZE1);
		_st[1] = new stWheel(WHEEL_SIZE2);
		_st[2] = new stWheel(WHEEL_SIZE2);
		_st[3] = new stWheel(WHEEL_SIZE2);
		_st[4] = new stWheel(WHEEL_SIZE2);

		_checktime = now();
	}



	void del(stNodeLink st)
	{
		st._prev._next = st._next;
		st._next._prev = st._prev;
		delete st;
	}





	void add(stNodeLink st , bool isCasade = false)
	{
		stNodeLink spoke;
		uint64_t now = now();
		int64_t interval = 0;
		if(isCasade == false)
		{	
			st._tick = now + st._interval;
			interval = st._interval;
		}
		else
		{
			interval = st._tick - now;
		}

		uint64_t threshold1 = WHEEL_SIZE1;
		uint64_t threshold2 = 1 << (WHEEL_BITS1 + WHEEL_BITS2);
		uint64_t threshold3 = 1 << (WHEEL_BITS1 + 2 * WHEEL_BITS2);
		uint64_t threshold4 = 1 << (WHEEL_BITS1 + 3 * WHEEL_BITS2);
		uint32_t index;
	
		if (interval < threshold1) {
			if(interval < 0)
				interval = 0;
			index = (interval + _st[0]._spokeindex) & WHEEL_MASK1;
			spoke = _st[0]._spokes[index];

		} else if (interval < threshold2) {
			index = ((interval - threshold1 + _st[1]._spokeindex * threshold1) >> WHEEL_BITS1) & WHEEL_MASK2;
			spoke = _st[1]._spokes [ index];

		} else if (interval < threshold3) {
			index = ((interval - threshold2 + _st[2]._spokeindex * threshold2) >> (WHEEL_BITS1 + WHEEL_BITS2)) & WHEEL_MASK2;
			spoke = _st[2]._spokes [ index];

		} else if (interval < threshold4) {
			index = ((interval - threshold3 + _st[3]._spokeindex * threshold3) >> (WHEEL_BITS1 + 2 * WHEEL_BITS2)) & WHEEL_MASK2;
			spoke = _st[3]._spokes [ index];

		} else {
			index = ((interval - threshold4 + _st[4]._spokeindex * threshold4) >> (WHEEL_BITS1 + 3 * WHEEL_BITS2)) & WHEEL_MASK2;
			spoke = _st[4]._spokes [ index];
		
		}

		st._prev = spoke._prev;
		spoke._prev._next = st;
		st._next = spoke;
		spoke._prev = st;	

	}
	void poll()
	{
		uint64_t now = now();
		int64_t loopnum = now - _checktime;
		stWheel wheel =  _st[0];
		for(uint32_t i = 0 ; i < loopnum ; ++i)
		{
			stNodeLink spoke = wheel._spokes [wheel._spokeindex];
			stNodeLink link = spoke._next;
			stNodeLink tmp;
			//clear all
			spoke._next = spoke._prev = spoke;
			while(link != spoke){
				tmp = link._next;
				link._next = link._prev = link;
					
				if(link._tm.onTimer(link ,_checktime) && 
					link._type == WheelType.WHEEL_PERIODIC)
				{
					add(link);
				}
				link = tmp;
			}
			if( ++wheel._spokeindex >= wheel._spokes.length)
			{
				wheel._spokeindex = 0;
				Cascade(1);
			}
			_checktime++;
		}
	}



	uint32_t Cascade(uint32_t wheelindex)
	{
		if (wheelindex < 1 || wheelindex >= WHEEL_NUM) {
			return 0;
		}
		stWheel wheel =  _st[wheelindex];
		int casnum = 0;

		stNodeLink spoke = wheel._spokes[wheel._spokeindex++];
		stNodeLink link = spoke._next;
		stNodeLink tmp;
		//clear all
		spoke._next = spoke._prev = spoke;
		while (link != spoke) {
			tmp = link._next;
			link._next = link._prev = link;
			if (link._tick <= _checktime) {
				if(link._tm.onTimer(link , _checktime) && 
					link._type == WheelType.WHEEL_PERIODIC)
				{
					log(LogLevel.info , "interval:" ~ to!string(link._interval));
					add(link);
				}
			} 
			else {
				add(link , true);
				++casnum;
			}
			link = tmp;
		}
		
		if (wheel._spokeindex >= wheel._spokes.length) {
			wheel._spokeindex = 0;
			casnum += Cascade(++wheelindex);
		}
		return casnum;
	}
}


