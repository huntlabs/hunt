import std.stdio;

import kiss.event;
import kiss.net.TcpListener;
import kiss.net.TcpStream;
import kiss.net.Timer;

import std.datetime;
import std.exception;

void main()
{
	EventLoop loop = new EventLoop();

	Timer timer = new Timer(loop);
	timer.setTimerHandle(() @trusted nothrow{
		catchAndLogException(() {

			writeln("The current time is ", Clock.currTime.toString);
		}());
	}).start(1000);
	loop.join;
}
