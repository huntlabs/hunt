module hunt.logging.ConsoleLogger;

import hunt.concurrent.thread.Helper;

import core.stdc.stdlib;
import core.runtime;
import core.thread;

import std.stdio;
import std.datetime;
import std.format;
import std.range;
import std.conv;
import std.regex;
import std.typecons;
import std.traits;
import std.string;

// ThreadID getTid()
// {
//     return Thread.getThis.id;
// }

version (Windows) {
    import core.sys.windows.wincon;
    import core.sys.windows.winbase;
    import core.sys.windows.windef;

    private __gshared HANDLE g_hout;
    
    shared static this() {
        g_hout = GetStdHandle(STD_OUTPUT_HANDLE);
        SetConsoleTextAttribute(g_hout, FOREGROUND_GREEN | FOREGROUND_RED | FOREGROUND_BLUE);
    }

    void resetConsoleColor() {
        SetConsoleTextAttribute(g_hout, FOREGROUND_GREEN | FOREGROUND_RED | FOREGROUND_BLUE);
    }
}

version (Posix) {
    enum PRINT_COLOR_NONE = "\033[m";
    enum PRINT_COLOR_RED = "\033[0;32;31m";
    enum PRINT_COLOR_GREEN = "\033[0;32;32m";
    enum PRINT_COLOR_YELLOW = "\033[1;33m";
}

enum LogLevel {
    Trace = 0,
    Info = 1,
    Warning = 2,
    Error = 3,
    Fatal = 4,
    Off = 5
}

/**
*/
class ConsoleLogger {
    private __gshared LogLevel g_logLevel = LogLevel.Trace;
    private enum traceLevel = toString(LogLevel.Trace);
    private enum infoLevel = toString(LogLevel.Info);
    private enum warningLevel = toString(LogLevel.Warning);
    private enum errorLevel = toString(LogLevel.Error);
    private enum fatalLevel = toString(LogLevel.Fatal);
    private enum offlLevel = toString(LogLevel.Off);

    static void setLogLevel(LogLevel level) {
        g_logLevel = level;
    }

    static void trace(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow {
        writeFormatColor(LogLevel.Trace, layout!(file, line, func)(logFormat(args), traceLevel));
    }

    static void tracef(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow {
        writeFormatColor(LogLevel.Trace, layout!(file, line, func)(logFormatf(args), traceLevel));
    }

    static void info(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow {
        writeFormatColor(LogLevel.Info, layout!(file, line, func)(logFormat(args), infoLevel));
    }

    static void infof(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow {
        writeFormatColor(LogLevel.Info, layout!(file, line, func)(logFormatf(args), infoLevel));
    }

    static void warning(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow {
        writeFormatColor(LogLevel.Warning, layout!(file, line,
                func)(logFormat(args), warningLevel));
    }

    static void warningf(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow {
        writeFormatColor(LogLevel.Warning, layout!(file, line,
                func)(logFormatf(args), warningLevel));
    }

    static void error(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow {
        writeFormatColor(LogLevel.Error, layout!(file, line, func)(logFormat(args), errorLevel));
    }

    static void errorf(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow {
        writeFormatColor(LogLevel.Error, layout!(file, line, func)(logFormatf(args), errorLevel));
    }

    static void fatal(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow {
        writeFormatColor(LogLevel.Fatal, layout!(file, line, func)(logFormat(args), fatalLevel));
    }

    static void fatalf(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow {
        writeFormatColor(LogLevel.Fatal, layout!(file, line, func)(logFormatf(args), fatalLevel));
    }

    private static string logFormatf(A...)(A args) {
        Appender!string buffer;
        formattedWrite(buffer, args);
        return buffer.data;
    }

    private static string logFormat(A...)(A args) {
        auto w = appender!string();
        foreach (arg; args) {
            alias A = typeof(arg);
            static if (isAggregateType!A || is(A == enum)) {
                import std.format : formattedWrite;

                formattedWrite(w, "%s", arg);
            }
            else static if (isSomeString!A) {
                put(w, arg);
            }
            else static if (isIntegral!A) {
                import std.conv : toTextRange;

                toTextRange(arg, w);
            }
            else static if (isBoolean!A) {
                put(w, arg ? "true" : "false");
            }
            else static if (isSomeChar!A) {
                put(w, arg);
            }
            else {
                import std.format : formattedWrite;

                // Most general case
                formattedWrite(w, "%s", arg);
            }
        }
        return w.data;
    }

    private static string layout(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__)(string msg, string level) {
        enum lineNum = std.conv.to!string(line);
        string time_prior = Clock.currTime.toString();
        string tid = std.conv.to!string(getTid());

        // writeln(func);
        string fun = func;
        ptrdiff_t index = lastIndexOf(func, '.');
        if (index != -1) {
            if(func[index -1] != ')') {
                ptrdiff_t idx = lastIndexOf(func, '.', index);
                if (idx != -1)
                    index = idx;
            }
            fun = func[index + 1 .. $];
        }

        return time_prior ~ " | " ~ tid ~ " | " ~ level ~ " | " ~ fun ~ " | " ~ msg
            ~ " | " ~ file ~ ":" ~ lineNum;
    }

    // private static string defaultLayout(string context, string msg, string level)
    // {
    //     string time_prior = Clock.currTime.toString();
    //     string tid = std.conv.to!string(getTid());

    //     return time_prior ~ " | " ~ tid ~ " | " ~ level ~ context ~ msg;
    // }

    static string toString(LogLevel level) nothrow {
        string r;
        final switch (level) with (LogLevel) {
        case Trace:
            r = "trace";
            break;
        case Info:
            r = "info";
            break;
        case Warning:
            r = "warning";
            break;
        case Error:
            r = "error";
            break;
        case Fatal:
            r = "fatal";
            break;
        case Off:
            r = "off";
            break;
        }
        return r;
    }

    private static void writeFormatColor(LogLevel level, lazy string msg) nothrow {
        if (level < g_logLevel)
            return;

        version (Posix) {
            string prior_color;
            switch (level) with (LogLevel) {
            case Error:
            case Fatal:
                prior_color = PRINT_COLOR_RED;
                break;
            case Warning:
                prior_color = PRINT_COLOR_YELLOW;
                break;
            case Info:
                prior_color = PRINT_COLOR_GREEN;
                break;
            default:
                prior_color = string.init;
            }
            import std.exception;
            collectException(writeln(prior_color ~ msg ~ PRINT_COLOR_NONE));
            
        }
        else version (Windows) {
            import std.windows.charset;
            import core.stdc.stdio;

            enum defaultColor = FOREGROUND_GREEN | FOREGROUND_RED | FOREGROUND_BLUE;

            ushort color;
            switch (level) with (LogLevel) {
            case Error:
            case Fatal:
                color = FOREGROUND_RED;
                break;
            case Warning:
                color = FOREGROUND_GREEN | FOREGROUND_RED;
                break;
            case Info:
                color = FOREGROUND_GREEN;
                break;
            default:
                color = defaultColor;
            }

            SetConsoleTextAttribute(g_hout, color);
            
            try {
                printf("%s\n", toMBSz(msg));
            } catch (Exception) {
            }

            if (color != defaultColor)
                SetConsoleTextAttribute(g_hout, defaultColor);
        }
    }
}


alias trace = ConsoleLogger.trace;
alias tracef = ConsoleLogger.tracef;
alias info = ConsoleLogger.info;
alias infof = ConsoleLogger.infof;
alias warning = ConsoleLogger.warning;
alias warningf = ConsoleLogger.warningf;
alias error = ConsoleLogger.error;
alias errorf = ConsoleLogger.errorf;
// alias critical = ConsoleLogger.critical;
// alias criticalf = ConsoleLogger.criticalf;
