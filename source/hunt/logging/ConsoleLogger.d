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

module hunt.logging.ConsoleLogger;

import hunt.concurrency.thread.Helper;

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

version (Windows)
{
    import core.sys.windows.wincon;
    import core.sys.windows.winbase;
    import core.sys.windows.windef;
    import hunt.system.WindowsHelper;

}

version (Posix)
{
    enum PRINT_COLOR_NONE = "\033[m";
    enum PRINT_COLOR_RED = "\033[0;32;31m";
    enum PRINT_COLOR_GREEN = "\033[0;32;32m";
    enum PRINT_COLOR_YELLOW = "\033[1;33m";
}

version (Android)
{
    import core.stdc.stdarg : va_end, va_list, va_start;
    import core.sys.posix.sys.types;

extern (C):
@system:
nothrow:
@nogc:

    enum
    {
        AASSET_MODE_UNKNOWN,
        AASSET_MODE_RANDOM,
        AASSET_MODE_STREAMING,
        AASSET_MODE_BUFFER
    }

    struct AAssetManager;
    struct AAssetDir;
    struct AAsset;

    AAssetDir* AAssetManager_openDir(AAssetManager* mgr, const(char)* dirName);
    AAsset* AAssetManager_open(AAssetManager* mgr, const(char)* filename, int mode);
    const(char)* AAssetDir_getNextFileName(AAssetDir* assetDir);
    void AAssetDir_rewind(AAssetDir* assetDir);
    void AAssetDir_close(AAssetDir* assetDir);
    int AAsset_read(AAsset* asset, void* buf, size_t count);
    off_t AAsset_seek(AAsset* asset, off_t offset, int whence);
    void AAsset_close(AAsset* asset);
    const(void)* AAsset_getBuffer(AAsset* asset);
    off_t AAsset_getLength(AAsset* asset);
    off_t AAsset_getRemainingLength(AAsset* asset);
    int AAsset_openFileDescriptor(AAsset* asset, off_t* outStart, off_t* outLength);
    int AAsset_isAllocated(AAsset* asset);

    enum android_LogPriority
    {
        ANDROID_LOG_UNKNOWN,
        ANDROID_LOG_DEFAULT,
        ANDROID_LOG_VERBOSE,
        ANDROID_LOG_DEBUG,
        ANDROID_LOG_INFO,
        ANDROID_LOG_WARN,
        ANDROID_LOG_ERROR,
        ANDROID_LOG_FATAL,
        ANDROID_LOG_SILENT
    }

    int __android_log_write(int prio, const(char)* tag, const(char)* text);
    int __android_log_print(int prio, const(char)* tag, const(char)* fmt, ...);
    int __android_log_vprint(int prio, const(char)* tag, const(char)* fmt, va_list ap);
    void __android_log_assert(const(char)* cond, const(char)* tag, const(char)* fmt, ...);

    enum LOG_TAG = "HUNT";

}

enum LogLevel
{
    Trace = 0,
    Info = 1,
    Warning = 2,
    Error = 3,
    Fatal = 4,
    Off = 5
}

/**
*/
class ConsoleLogger
{
    private __gshared LogLevel g_logLevel = LogLevel.Trace;
    private enum traceLevel = toString(LogLevel.Trace);
    private enum infoLevel = toString(LogLevel.Info);
    private enum warningLevel = toString(LogLevel.Warning);
    private enum errorLevel = toString(LogLevel.Error);
    private enum fatalLevel = toString(LogLevel.Fatal);
    private enum offlLevel = toString(LogLevel.Off);

    static void setLogLevel(LogLevel level)
    {
        g_logLevel = level;
    }

    static void trace(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow
    {
        writeFormatColor(LogLevel.Trace, layout!(file, line, func)(logFormat(args), traceLevel));
    }

    static void tracef(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow
    {
        writeFormatColor(LogLevel.Trace, layout!(file, line, func)(logFormatf(args), traceLevel));
    }

    static void info(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow
    {
        writeFormatColor(LogLevel.Info, layout!(file, line, func)(logFormat(args), infoLevel));
    }

    static void infof(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow
    {
        writeFormatColor(LogLevel.Info, layout!(file, line, func)(logFormatf(args), infoLevel));
    }

    static void warning(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow
    {
        writeFormatColor(LogLevel.Warning, layout!(file, line,
                func)(logFormat(args), warningLevel));
    }

    static void warningf(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow
    {
        writeFormatColor(LogLevel.Warning, layout!(file, line,
                func)(logFormatf(args), warningLevel));
    }

    static void error(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow
    {
        writeFormatColor(LogLevel.Error, layout!(file, line, func)(logFormat(args), errorLevel));
    }

    static void errorf(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow
    {
        writeFormatColor(LogLevel.Error, layout!(file, line, func)(logFormatf(args), errorLevel));
    }

    static void fatal(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow
    {
        writeFormatColor(LogLevel.Fatal, layout!(file, line, func)(logFormat(args), fatalLevel));
    }

    static void fatalf(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__, A...)(lazy A args) nothrow
    {
        writeFormatColor(LogLevel.Fatal, layout!(file, line, func)(logFormatf(args), fatalLevel));
    }

    private static string logFormatf(A...)(A args)
    {
        Appender!string buffer;
        formattedWrite(buffer, args);
        return buffer.data;
    }

    private static string logFormat(A...)(A args)
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

    private static string layout(string file = __FILE__, size_t line = __LINE__,
            string func = __FUNCTION__)(string msg, string level)
    {
        enum lineNum = std.conv.to!string(line);
        string time_prior = Clock.currTime.toString();
        string tid = std.conv.to!string(getTid());

        // writeln(func);
        string fun = func;
        ptrdiff_t index = lastIndexOf(func, '.');
        if (index != -1)
        {
            if (func[index - 1] != ')')
            {
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

    static string toString(LogLevel level) nothrow
    {
        string r;
        final switch (level) with (LogLevel)
        {
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

    private static void writeFormatColor(LogLevel level, lazy string msg) nothrow
    {
        if (level < g_logLevel)
            return;

        import std.exception;

        version (Posix)
        {
            version (Android)
            {
                string prior_color;
                switch (level) with (LogLevel)
                {
                case Error:
                case Fatal:
                    prior_color = PRINT_COLOR_RED;
                    collectException(__android_log_write(android_LogPriority.ANDROID_LOG_ERROR,
                            LOG_TAG, toStringz(prior_color ~ msg ~ PRINT_COLOR_NONE)));
                    break;
                case Warning:
                    prior_color = PRINT_COLOR_YELLOW;
                    collectException(__android_log_write(android_LogPriority.ANDROID_LOG_WARN,
                            LOG_TAG, toStringz(prior_color ~ msg ~ PRINT_COLOR_NONE)));
                    break;
                case Info:
                    prior_color = PRINT_COLOR_GREEN;
                    collectException(__android_log_write(android_LogPriority.ANDROID_LOG_INFO,
                            LOG_TAG, toStringz(prior_color ~ msg ~ PRINT_COLOR_NONE)));
                    break;
                default:
                    prior_color = string.init;
                    collectException(__android_log_write(android_LogPriority.ANDROID_LOG_INFO,
                            LOG_TAG, toStringz(prior_color ~ msg ~ PRINT_COLOR_NONE)));
                }
                // collectException(writeln(prior_color ~ msg ~ PRINT_COLOR_NONE));

            }
            else
            {
                string prior_color;
                switch (level) with (LogLevel)
                {
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
                collectException(writeln(prior_color ~ msg ~ PRINT_COLOR_NONE));
            }

        }
        else version (Windows)
        {
            enum defaultColor = FOREGROUND_GREEN | FOREGROUND_RED | FOREGROUND_BLUE;

            ushort color;
            switch (level) with (LogLevel)
            {
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

            collectException(ConsoleHelper.writeWithAttribute(msg, color));
        }
        else
        {
            assert(false, "Unsupported OS.");
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

alias logDebug = trace;
alias logDebugf = tracef;
alias logInfo = info;
alias logInfof = infof;
alias logWarning = warning;
alias logWarningf = warningf;
alias logError = error;
alias logErrorf = errorf;
