/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.cn
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
import std.stdio;
import hunt.logging;

void main()
{
	setLoggingLevel(LogLevel.LOG_DEBUG);
	LogConf conf;
	conf.disableConsole = true;
	conf.level = LogLevel.LOG_WARNING;
	conf.fileName = "test.log";
	logLoadConf(conf);

	logDebug("test" , " test1 " , "test2" , conf);
	logDebugf("%s %s %d %d " , "test" , "test1" , 12 ,13);
	logInfo("info");
}
