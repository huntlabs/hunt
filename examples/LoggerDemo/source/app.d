import std.stdio;
import kiss.util.logger;

void main()
{
	LogConf conf;
	//conf.disableConsole = true;
	//conf.level = 1;
	logLoadConf(conf);
	logDebug("test" , " test1 " , "test2" , conf);
	logDebugf("%s %s %d %d " , "test" , "test1" , 12 ,13);
	logInfo("info");
}
