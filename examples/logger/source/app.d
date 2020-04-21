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
import hunt.logging.Logger;
import hunt.util.DateTime;

void main() {
	DateTime.startClock();

	//setLoggingLevel(LogLevel.LOG_DEBUG);
	LogConf conf;
	conf.disableConsole = true;
	conf.level = LogLevel.LOG_DEBUG;
	// conf.fileName = "test.log";
	logLoadConf(conf);

	logDebug("test", " test1 ", "test2", conf);
	logDebugf("%s %s %d %d ", "test", "test1", 12, 13);
	trace("trace");
	logInfo("info");
	warning("warning");
	error("error");
	error("Chinese message: 错误");
}
