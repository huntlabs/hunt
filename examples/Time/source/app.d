import std.stdio;
import hunt.logging;
// import hunt.time.Init;
// import hunt.time;
import test.TestLocalDateTime;
import std.string;
import core.thread;

import test.TestLocalTime;

void main()
{
	trace("Test Time.");

	// auto localTime = LocalTime.now()/* LocalTime.of(15,48,30,111) */;

	// writeln("LocalTime now : %s".format(localTime));

	// Thread.sleep( dur!("seconds")( 5 ) ); 

	// writeln("LocalTime now : %s".format(LocalTime.now()));

	// auto localDate = LocalDate.now();

	// writeln("LocalDate now : %s".format(localDate));

	// auto localDateTime = LocalDateTime.now();

	// writeln("LocalDateTime now : %s".format(localDateTime));

	// writeln("System.currentTimeMillis : ",System.currentTimeMillis());

	// writeln("Clock.currTime : ",std.datetime.Clock.currTime());


	TestLocalTime.test();

	import core.thread;
	// thread_joinAll();

}
