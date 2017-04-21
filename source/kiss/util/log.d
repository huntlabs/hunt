module kiss.util.log;
import std.string;

import std.stdio;
import std.datetime;


immutable string PRINT_COLOR_NONE  = "\033[m";
immutable string PRINT_COLOR_RED   =  "\033[0;32;31m";
immutable string PRINT_COLOR_GREEN  = "\033[0;32;32m";



//#define PRINT_COLOR_YELLOW 	   "\033[1;33m"
//#define PRINT_COLOR_BLUE         "\033[0;32;34m"
//#define PRINT_COLOR_WHITE        "\033[1;37m"
//#define PRINT_COLOR_CYAN         "\033[0;36m"
//#define PRINT_COLOR_PURPLE       "\033[0;35m"
//#define PRINT_COLOR_BROWN        "\033[0;33m"
//#define PRINT_COLOR_DARY_GRAY    "\033[1;30m"
//#define PRINT_COLOR_LIGHT_RED    "\033[1;31m"
//#define PRINT_COLOR_LIGHT_GREEN  "\033[1;32m"
//#define PRINT_COLOR_LIGHT_BLUE   "\033[1;34m"
//#define PRINT_COLOR_LIGHT_CYAN   "\033[1;36m"
//#define PRINT_COLOR_LIGHT_PURPLE "\033[1;35m"
//#define PRINT_COLOR_LIGHT_GRAY   "\033[0;37m"

private string convTostr(string msg , string file , size_t line)
{
	import std.conv;
	return msg ~ " - " ~ file ~ ":" ~ to!string(line);	
}


void log_kiss(string msg , string type ,  string file = __FILE__ , size_t line = __LINE__)
{

	string time_prior = format("%-27s", Clock.currTime.toISOExtString());
	version(Posix)
	{
		string prior;
		string suffix;
		if(type == "error" || type == "fatal" ||  type == "critical")
		{
			prior = PRINT_COLOR_RED;
			suffix = PRINT_COLOR_NONE;
		}
		else if(type == "warning" || type == "info")
		{
			prior = PRINT_COLOR_GREEN;
			suffix = PRINT_COLOR_NONE;
		}
		msg = time_prior ~ " [" ~ type  ~ "] " ~ msg ;
		msg = convTostr(msg , file , line);
		msg = prior ~ msg ~ suffix;
	}
	else
	{
		msg =   time_prior ~ " [" ~ type  ~ "] " ~ msg ;
		msg = convTostr(msg , file , line);
	}
	writeln(msg);
}


version(onyxLog)
{
	import onyx.log;
	import onyx.bundle;

	__gshared Log g_log;

	bool load_log_conf(immutable string logConfPath)
	{
		if(g_log is null)
		{
			auto bundle = new immutable Bundle(logConfPath);
			createLoggers(bundle);
			g_log = getLogger("logger");
		}
		return true;
	}

	void log_debug(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		if(g_log !is null )
			g_log.debug_(convTostr(msg , file , line));
		log_kiss(msg , "debug" , file , line);
	}

	void log_info(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		if(g_log !is null)
			g_log.info(convTostr(msg , file , line));
		log_kiss(msg , "info" , file , line);
	}

	void log_warning(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		if(g_log !is null)
			g_log.warning(convTostr(msg , file , line));
		log_kiss(msg , "warning" , file , line);
	}

	void log_error(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		if(g_log !is null)
			g_log.error(convTostr(msg , file , line));
		log_kiss(msg , "error" , file , line);
	}

	void log_critical(string msg ,string file = __FILE__ , size_t line = __LINE__)
	{
		if(g_log !is null)
			g_log.critical(convTostr(msg , file , line));
		log_kiss(msg , "critical" , file , line);
	}

	void log_fatal(string msg ,string file = __FILE__ , size_t line = __LINE__)
	{
		if(g_log !is null)
			g_log.fatal(convTostr(msg , file , line));
		log_kiss(msg , "fatal" , file , line);
	}

}
else
{
	bool load_log_conf(immutable string logConfPath)
	{
		return true;
	}
	void log_debug(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		log_kiss(msg , "debug" , file , line);
	}
	void log_info(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		log_kiss(msg , "info" , file , line);
	}
	void log_warning(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		log_kiss(msg , "warning" , file , line);
	}
	void log_error(string msg , string file = __FILE__ , size_t line = __LINE__)
	{
		log_kiss(msg , "error" ,  file , line);
	}
	void log_critical(string msg ,string file = __FILE__ , size_t line = __LINE__)
	{
		log_kiss(msg , "critical" , file , line);
	}
	void log_fatal(string msg ,string file = __FILE__ , size_t line = __LINE__)
	{
		log_kiss(msg , "fatal" ,  file , line);
	}

}

unittest
{
	import kiss.util.log;
	
	load_log_conf("default.conf");
	
	log_debug("debug");
	log_info("info");
	log_error("errro");
}