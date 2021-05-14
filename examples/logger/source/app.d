/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2018-2019 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

import std.stdio;
// import hunt.logging.Logger;
import hunt.logging.ConsoleLogger;
import hunt.util.DateTime;
import std.datetime;

// void main() {
// 	hunt.util.DateTime.DateTime.startClock();

// 	//setLoggingLevel(LogLevel.LOG_DEBUG);
// 	LogConf conf;
// 	conf.disableConsole = true;
// 	conf.level = LogLevel.LOG_DEBUG;
// 	conf.fileName = "test.log";
// 	conf.maxSize = "2K";
// 	conf.maxNum = 10;
// 	logLoadConf(conf);

// 	import std.json;
// 	setLogLayout((string time_prior, string tid, string level, string myFunc, 
// 				string msg, string file, size_t line) {
		
// 		SysTime now = Clock.currTime;

// 		std.datetime.DateTime dt ;

// 		JSONValue jv;
// 		jv["timestamp"] = (cast(std.datetime.DateTime)now).toISOExtString();
// 		jv["msecs"] = now.fracSecs.total!("msecs");
// 		jv["level"] = level;
// 		jv["file"] = file;
// 		jv["module"] = myFunc;
// 		jv["funcName"] = myFunc;
// 		jv["line"] = line;
// 		jv["thread"] = tid;
// 		jv["threadName"] = tid;
// 		jv["process"] = 523;
// 		jv["message"] = msg;
// 		return jv.toPrettyString();
// 	});

// 	import core.thread;
// 	import core.time;

// 	while(true) {
// 		logDebugf("%s %s %d %d ", "test", "test1", 12, 13);
// 		Thread.sleep(500.msecs);
// 	}

// 	// logDebug("test", " test1 ", "test2", conf);
// 	// logDebugf("%s %s %d %d ", "test", "test1", 12, 13);
// 	// trace("trace");
// 	// logInfo("info");
// 	// warning("warning");
// 	// error("error");
// 	// error("Chinese message: 错误");
// }


void main() {
	hunt.util.DateTime.DateTime.startClock();


	import std.json;
	setLogLayout((string time_prior, string tid, string level, string myFunc, 
				string msg, string file, size_t line) {
		
		SysTime now = Clock.currTime;

		std.datetime.DateTime dt ;

		JSONValue jv;
		jv["timestamp"] = dt.toISOExtString();
		jv["level"] = level;
		jv["file"] = file;
		jv["module"] = myFunc;
		jv["funcName"] = myFunc;
		jv["line"] = line;
		jv["thread"] = tid;
		jv["message"] = msg;
		return jv.toPrettyString();
	});


	logDebugf("%s %s %d %d ", "test", "test1", 12, 13);
	trace("trace");
	logInfo("info");
	warning("warning");
	error("error");
	error("Chinese message: 错误");
}