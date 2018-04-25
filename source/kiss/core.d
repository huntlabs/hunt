module kiss.core;
import core.time;

version (FreeBSD)
{
    version = Kqueue;
}
version (OpenBSD)
{
    version = Kqueue;
}
version (NetBSD)
{
    version = Kqueue;
}
version (OSX)
{
    version = Kqueue;
}

/**
*/
class EventArgs
{

}
alias EventHandler = void delegate(Object sender, EventArgs args);
alias SimpleEventHandler = void delegate();
alias ErrorEventHandler = void delegate(string message);


alias TickedEventHandler = void delegate(Object sender);


/**
*/
interface ITimer {
    
    /// 
	bool isActive();

	/// in ms
	size_t interval();

	/// ditto
	ITimer interval(size_t v);
	
	/// ditto
	ITimer interval(Duration duration);

	///
	ITimer onTick(TickedEventHandler handler);

	/// immediately: true to call first event immediately
	/// once: true to call timed event only once
	void start(bool immediately = false, bool once = false);
	
	void start(uint interval);

	void stop();

	void reset(bool immediately = false, bool once = false);

	void reset(size_t interval);

	void reset(Duration duration);
}

bool isCompilerVersionAbove(int ver)
{
    return __VERSION__ >= ver;
}

bool isCompilerVersionBelow(int ver)
{
    return __VERSION__ <= ver;
}