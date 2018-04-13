module kiss.log;

import std.concurrency;
import std.parallelism;
import std.traits;
import std.array;
import std.string;
import std.stdio;
import std.datetime;
import std.format;
import std.range;
import std.conv;
import std.regex;
import std.path;
import std.typecons;
import std.file;
import std.algorithm.iteration;
import core.thread;

private:

enum LogLevel
{
	LOG_DEBUG,
	LOG_INFO,
	LOG_WARNING,
	LOG_ERROR,
	LOG_FATAL
};


class SizeBaseRollover
{

	import std.path;
	import std.string;
	import std.typecons;

	string	path;
	string  dir;
	string 	baseName;
	string 	ext;
	string 	activeFilePath;




	/**
	 * Max size of one file
	 */
	uint maxSize;
	
	
	/**
	 * Max number of working files
	 */
	uint maxHistory;

	this(string fileName , string size , uint maxNum )
	{
		path = fileName;
		auto fileInfo = parseConfigFilePath(fileName);
		dir = fileInfo[0];
		baseName = fileInfo[1];
		ext = fileInfo[2];

		activeFilePath = path;
		maxSize = extractSize(size);

		maxHistory = maxNum;
	}

	auto parseConfigFilePath(string rawConfigFile)
	{
		string configFile = buildNormalizedPath(rawConfigFile);
		
		immutable dir = configFile.dirName;
		string fullBaseName = std.path.baseName(configFile);
		auto ldotPos = fullBaseName.lastIndexOf(".");
		immutable ext = (ldotPos > 0)?fullBaseName[ldotPos+1..$]:"log";
		immutable baseName = (ldotPos > 0)?fullBaseName[0..ldotPos]:fullBaseName;
		
		return tuple(dir, baseName, ext);
	}

	uint extractSize(string size)
	{
		import std.uni : toLower;
		import std.uni : toUpper;
		import std.conv;
		
		uint nsize = 0;
		auto n = matchAll(size, regex(`\d*`));
		if (!n.empty && (n.hit.length != 0))
		{
			nsize = to!int(n.hit);
			auto m = matchAll(size, regex(`\D{1}`));
			if (!m.empty && (m.hit.length != 0))
			{
				switch(m.hit.toUpper)
				{
					case "K":
						nsize *= KB;
						break;
					case "M":
						nsize *= MB;
						break;
					case "G":
						nsize *= GB;
						break;
					case "T":
						nsize *= TB;
						break;
					case "P":
						nsize *= PB;
						break;
					default:
						throw new Exception("In Logger configuration uncorrect number: " ~ size);
				}
			}
		}
		return nsize;
	}

	enum KB = 1024;
	enum MB = KB*1024;
	enum GB = MB*1024;
	enum TB = GB*1024;
	enum PB = TB*1024;
	
	/**
	 * Scan work directory
	 * save needed files to pool
 	 */
	string[] scanDir()
	{
		import std.algorithm.sorting:sort;
		import std.algorithm;
		bool tc(string s)
		{
			static import std.path;
			auto base = std.path.baseName(s);
			auto m = matchAll(base, regex(baseName ~ `\d*\.` ~ ext));
			if (m.empty || (m.hit != base))
			{
				return false;
			}
			return true;
		}
		
		return std.file.dirEntries(dir, SpanMode.shallow)
			.filter!(a => a.isFile)
				.map!(a => a.name)
				.filter!(a => tc(a))
				.array
				.sort!("a < b")
				.array;
	}
	
	
	/**
	 * Do files rolling by size
	 */

		bool roll(string msg)
		{
			auto filePool = scanDir();
			if (filePool.length == 0)
			{
				return false;
			}
			if ((getSize(filePool[0]) + msg.length) >= maxSize)
			{
				//if ((filePool.front.getSize == 0) throw
				if (filePool.length >= maxHistory)
				{
					std.file.remove(filePool[$-1]);
					filePool = filePool[0..$-1];
				}
				//carry(filePool);
				return true;
			}
			return false;
		}
	
	
	/**
	 * Rename log files
	 */

	void carry()
	{
		import std.conv;
		import std.path;
		
		auto filePool = scanDir();
		foreach_reverse(ref file; filePool)
		{
			auto newFile = dir ~ dirSeparator ~ baseName ~ to!string(extractNum(file)+1) ~ "." ~ ext;
			std.file.rename(file, newFile);
			file = newFile;
		}
	}
	
	
	/**
	 * Extract number from file name
	 */
	uint extractNum(string file)
	{
		import std.conv;
		
		uint num = 0;
		try
		{
			static import std.path;
			import std.string;
			auto fch = std.path.baseName(file).chompPrefix(baseName);
			auto m = matchAll(fch, regex(`\d*`));
			
			if (!m.empty && m.hit.length > 0)
			{
				num = to!uint(m.hit);
			}
		}
		catch (Exception e)
		{
			throw new Exception("Uncorrect log file name: " ~ file ~ "  -> " ~ e.msg);
		}
		return num;
	}

}


__gshared KissLogger g_logger = null;


version(Posix){

version(linux){
	version(X86_64) // X86_64
	{
		enum __NR_gettid = 186;
		
	}
	else
	{
		enum __NR_gettid = 224;
	}
}

version(OSX)
{
		enum __NR_gettid = 372;
}


import core.sys.posix.sys.types : pid_t;
extern (C) nothrow @nogc pid_t syscall(int d);
int getTid()
{
	return syscall(__NR_gettid);
}
}
class KissLogger
{
	/*void log(string file = __FILE__ , size_t line = __LINE__ , string func = __FUNCTION__ , A ...)(LogLevel level , lazy A args)
	{
		write(level , toFormat(func , logFormat(args) , file , line , level));
	}

	void logf(string file = __FILE__ , size_t line = __LINE__ , string func = __FUNCTION__ , A ...)(LogLevel level , lazy A args)
	{
		write(level , toFormat(func , logFormatf(args) , file , line , level));
	}*/

	void write(LogLevel level , string msg)
	{
		if(level >= _conf.level)
		{
			//#1 console 
			//check if enableConsole or appender == AppenderConsole
			
			if( _conf.fileName == "" || 
				!_conf.disableConsole)
			{
				writeFormatColor(level , msg);
			}
			
			//#2 file
			if (_conf.fileName != "")
			{
				send(_tid , msg);
			}
		}
	}

	this(LogConf conf)
	{
		_conf = conf;
		
		if(conf.fileName != "")
		{
			createPath(conf.fileName);
			_file = File(conf.fileName , "a");
			_rollover = new SizeBaseRollover(conf.fileName , _conf.maxSize , _conf.maxNum);
		}

		immutable void *data = cast(immutable void *)this;
		_tid = spawn(&KissLogger.worker , data);
	}

protected:

	static void worker(immutable void *ptr)
	{
		KissLogger logger = cast(KissLogger)ptr;
		bool flag = true;
		while(flag)
		{
			bool timeout = receiveTimeout(10.msecs , 
				(string msg){

					logger.saveMsg(msg);
					
				},
				(OwnerTerminated e){ flag = false;},
				(Variant any){}
				);
		}
	}

	void saveMsg(string msg)
	{
		try{

			if (!_file.name.exists)
			{
				_file = File(_rollover.activeFilePath, "w");
			}
			else if (_rollover.roll(msg))
			{
				_file.detach();
				_rollover.carry();
				_file = File(_rollover.activeFilePath, "w");
			}
			else if (!_file.isOpen())
			{
				_file.open("a");
			}
			_file.writeln(msg);
			_file.flush();

		}
		catch(Throwable e)
		{
			writeln(e.toString());
		}

	}


	static void createPath(string fileFullName)
	{
		import std.path:dirName;
		import std.file:mkdirRecurse;
		import std.file:exists;
		
		string dir = dirName(fileFullName);
		
		if ((dir.length != 0) && (!exists(dir)))
		{
			mkdirRecurse(dir);
		}
	}

	static string toString(LogLevel level)
	{
		string l;
		final switch (level) with(LogLevel)
		{
			case LOG_DEBUG:
				l = "debug";
				break;
			case LOG_INFO:
				l = "info";
				break;
			case LOG_WARNING:
				l = "warning";
				break;
			case LOG_ERROR:
				l = "error";
				break;
			case LOG_FATAL:
				l = "fatal";
				break;			
		}
		return l;
	}

	static string logFormatf(A ...)(A args)
	{
		auto strings = appender!string();
		formattedWrite(strings, args);
		return strings.data;
	}
	
	
	static string logFormat(A ...)(A args)
	{
		auto w = appender!string();
		foreach (arg; args)
		{
			alias A = typeof(arg);
			static if (isAggregateType!A || is(A == enum))
			{
				import std.format : formattedWrite;
				
				formattedWrite(w, "%s", arg);
			}
			else static if (isSomeString!A)
			{
				put(w, arg);
			}
			else static if (isIntegral!A)
			{
				import std.conv : toTextRange;
				
				toTextRange(arg, w);
			}
			else static if (isBoolean!A)
			{
				put(w, arg ? "true" : "false");
			}
			else static if (isSomeChar!A)
			{
				put(w, arg);
			}
			else
			{
				import std.format : formattedWrite;
				
				// Most general case
				formattedWrite(w, "%s", arg);
			}
		}
		return w.data;
	}



	static string toFormat(string func , string msg , string file , size_t line , LogLevel level)
	{
		string time_prior = format("%-27s", Clock.currTime.toISOExtString());

		version(Posix)
		{
	
		
			string tid = to!string(getTid());

		}
		else
		{
			string tid = to!string(Thread.getThis.id);
		}

		string[] funcs = func.split(".");
		string myFunc;
		if( funcs.length > 0 )
			myFunc =  funcs[$ - 1];
		else
			myFunc = func;

		return time_prior ~ " (" ~ tid ~ ") ["  ~ toString(level) ~ "] " ~ myFunc ~ " - " ~ msg ~ " - " ~ file ~  ":" ~ to!string(line);
	}





protected:
	
	LogConf 			_conf;
	Tid					_tid;
	File				_file;
	SizeBaseRollover	_rollover;
version(Posix)
{
	static string PRINT_COLOR_NONE  = "\033[m";
	static string PRINT_COLOR_RED   =  "\033[0;32;31m";
	static string PRINT_COLOR_GREEN  = "\033[0;32;32m";
	static string PRINT_COLOR_YELLOW = "\033[1;33m";
}





	static void writeFormatColor(LogLevel level , string msg)
	{
		version(Posix)
		{
			string prior_color;
			switch(level) with(LogLevel)
			{

				case LOG_ERROR:
				case LOG_FATAL:
					prior_color = PRINT_COLOR_RED;
					break;
				case LOG_WARNING:
					prior_color = PRINT_COLOR_YELLOW;
					break;
				case LOG_INFO:
					prior_color = PRINT_COLOR_GREEN;
					break;
				default:
					prior_color = string.init;
			}

			writeln(prior_color ~ msg ~ PRINT_COLOR_NONE);
		}
		else
		{
			version(Windows)
			{

				import core.sys.windows.wincon;
				import core.sys.windows.winbase;
				import core.sys.windows.windef;

				
				__gshared HANDLE g_hout;
				if(g_hout !is null)
					g_hout = GetStdHandle(STD_OUTPUT_HANDLE);
			}
			ushort color ;
			switch(level) with(LogLevel)
			{
				case LOG_ERROR:
				case LOG_FATAL:
					color = FOREGROUND_RED;
					break;
				case LOG_WARNING:
					color = FOREGROUND_GREEN|FOREGROUND_RED;
					break;
				case LOG_INFO:
					color = FOREGROUND_GREEN;
					break;
				default:
					color = FOREGROUND_GREEN|FOREGROUND_RED|FOREGROUND_BLUE;
			}

			SetConsoleTextAttribute(g_hout ,color);
			writeln(msg);
			SetConsoleTextAttribute(g_hout , FOREGROUND_GREEN|FOREGROUND_RED|FOREGROUND_BLUE);

		}
	}


}


string code(string func , LogLevel level ,  bool f = false)()
{
	return 
"void " ~ func ~ `(string file = __FILE__ , size_t line = __LINE__ , string func = __FUNCTION__ , A ...)(lazy A args)
	{
		if(g_logger is null)
			KissLogger.writeFormatColor(` ~ level.stringof ~` , KissLogger.toFormat(func , KissLogger.logFormat`~(f ? "f" : "")~`(args) , file , line , `~ level.stringof ~`));
		else
			g_logger.write(` ~ level.stringof ~` , KissLogger.toFormat(func , KissLogger.logFormat`~(f ? "f" : "")~`(args) , file , line ,`~level.stringof~` ));
	}`;
}


public:

struct LogConf
{
	int 		level;				// 0 debug 1 info 2 warning 3 error 4 fatal
	bool		disableConsole;			
	
	string 		fileName = "./kiss.log";
	string		maxSize = "2MB";
	uint		maxNum  = 5;
}

void logLoadConf(LogConf conf)
{
	g_logger = new KissLogger(conf);
}

mixin(code!("logDebug" , LogLevel.LOG_DEBUG));
mixin(code!("logDebugf" , LogLevel.LOG_DEBUG , true));
mixin(code!("logInfo" , LogLevel.LOG_INFO));
mixin(code!("logInfof" , LogLevel.LOG_INFO , true));
mixin(code!("logWarning" , LogLevel.LOG_WARNING));
mixin(code!("logWarningf" , LogLevel.LOG_WARNING , true));
mixin(code!("logError" , LogLevel.LOG_ERROR));
mixin(code!("logErrorf" , LogLevel.LOG_ERROR , true));
mixin(code!("logFatal" , LogLevel.LOG_FATAL));
mixin(code!("logFatalf" , LogLevel.LOG_FATAL , true));





unittest{
	LogConf conf;
	//conf.disableConsole = true;
	//conf.level = 1;
	logLoadConf(conf);
	logDebug("test" , " test1 " , "test2" , conf);
	logDebugf("%s %s %d %d " , "test" , "test1" , 12 ,13);
	logInfo("info");
}

