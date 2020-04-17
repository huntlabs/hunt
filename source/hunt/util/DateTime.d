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

module hunt.util.DateTime;

import core.atomic;
import core.stdc.time;
import core.thread : Thread;
import std.datetime;
import std.format : formattedWrite;
import std.string;


short monthToShort(Month month) {
    short resultMonth;
    switch (month) {
    case Month.jan:
        resultMonth = 1;
        break;
    case Month.feb:
        resultMonth = 2;
        break;
    case Month.mar:
        resultMonth = 3;
        break;
    case Month.apr:
        resultMonth = 4;
        break;
    case Month.may:
        resultMonth = 5;
        break;
    case Month.jun:
        resultMonth = 6;
        break;
    case Month.jul:
        resultMonth = 7;
        break;
    case Month.aug:
        resultMonth = 8;
        break;
    case Month.sep:
        resultMonth = 9;
        break;
    case Month.oct:
        resultMonth = 10;
        break;
    case Month.nov:
        resultMonth = 11;
        break;
    case Month.dec:
        resultMonth = 12;
        break;
    default:
        resultMonth = 0;
        break;
    }

    return resultMonth;
}

string dayAsString(DayOfWeek day) {
    final switch (day) with (DayOfWeek) {
    case mon:
        return "Mon";
    case tue:
        return "Tue";
    case wed:
        return "Wed";
    case thu:
        return "Thu";
    case fri:
        return "Fri";
    case sat:
        return "Sat";
    case sun:
        return "Sun";
    }
}

string monthAsString(Month month) {
    final switch (month) with (Month) {
    case jan:
        return "Jan";
    case feb:
        return "Feb";
    case mar:
        return "Mar";
    case apr:
        return "Apr";
    case may:
        return "May";
    case jun:
        return "Jun";
    case jul:
        return "Jul";
    case aug:
        return "Aug";
    case sep:
        return "Sep";
    case oct:
        return "Oct";
    case nov:
        return "Nov";
    case dec:
        return "Dec";
    }
}

enum TimeUnit : string {
    Year = "years",
    Month = "months",
    Week = "weeks",
    Day = "days",
    Hour = "hours",
    Second = "seconds",
    Millisecond = "msecs",
    Microsecond = "usecs",
    HectoNanosecond = "hnsecs",
    Nanosecond = "nsecs"
}

// return unix timestamp
long time() {
    return DateTime.timestamp;
}

// return formated time string from timestamp
string date(string format, long timestamp = 0) {
    import std.datetime : SysTime;
    import std.conv : to;

    long newTimestamp = timestamp > 0 ? timestamp : time();

    string timeString;

    SysTime st = SysTime.fromUnixTime(newTimestamp);

    // format to ubyte
    foreach (c; format) {
        switch (c) {
        case 'Y':
            timeString ~= st.year.to!string;
            break;
        case 'y':
            timeString ~= (st.year.to!string)[2 .. $];
            break;
        case 'm':
            short month = monthToShort(st.month);
            timeString ~= month < 10 ? "0" ~ month.to!string : month.to!string;
            break;
        case 'd':
            timeString ~= st.day < 10 ? "0" ~ st.day.to!string : st.day.to!string;
            break;
        case 'H':
            timeString ~= st.hour < 10 ? "0" ~ st.hour.to!string : st.hour.to!string;
            break;
        case 'i':
            timeString ~= st.minute < 10 ? "0" ~ st.minute.to!string : st.minute.to!string;
            break;
        case 's':
            timeString ~= st.second < 10 ? "0" ~ st.second.to!string : st.second.to!string;
            break;
        default:
            timeString ~= c;
            break;
        }
    }

    return timeString;
}


deprecated("Using DateTime instead.")
alias DateTimeHelper = DateTime;

/**
 * 
 */
class DateTime {
    /**
     * Returns the current time in milliseconds.  Note that
     * while the unit of time of the return value is a millisecond,
     * the granularity of the value depends on the underlying
     * operating system and may be larger.  For example, many
     * operating systems measure time in units of tens of
     * milliseconds.
     *
     * <p> See the description of the class {@code Date} for
     * a discussion of slight discrepancies that may arise between
     * "computer time" and coordinated universal time (UTC).
     *
     * @return  the difference, measured in milliseconds, between
     *          the current time and midnight, January 1, 1970 UTC.
     */
    static long currentTimeMillis() @trusted @property {
        return currentTime!(TimeUnit.Millisecond)();
    }

    static long currentTimeNsecs() @trusted @property {
        return currentTime!(TimeUnit.Nanosecond)();
    }

    static long currentUnixTime() @trusted @property {
        return currentTime!(TimeUnit.Second)();
    }

    alias currentTimeSecond = currentUnixTime;

    /**
    */
    static long currentTime(TimeUnit targetUnit)() @trusted @property {
        version (Windows) {
            import core.sys.windows.winbase;
            import core.sys.windows.winnt;

            /**
                http://www.frenk.com/2009/12/convert-filetime-to-unix-timestamp/
                https://stackoverflow.com/questions/10849717/what-is-the-significance-of-january-1-1601
                https://stackoverflow.com/questions/1090869/why-is-1-1-1970-the-epoch-time
                https://www.unixtimestamp.com/
            */
            FILETIME fileTime;
            GetSystemTimeAsFileTime(&fileTime);
            ULARGE_INTEGER date, adjust;
            date.HighPart = fileTime.dwHighDateTime;
            date.LowPart = fileTime.dwLowDateTime;

            // 100-nanoseconds = milliseconds * 10000
            adjust.QuadPart = 11644473600000 * 10000;

            // removes the diff between 1970 and 1601
            date.QuadPart -= adjust.QuadPart;

            // converts back from 100-nanoseconds to milliseconds
            return convert!(TimeUnit.HectoNanosecond, targetUnit)(date.QuadPart);

        } else version (Posix) {
                import core.sys.posix.signal : timespec;
            version (OSX) {
                import core.sys.posix.sys.time : gettimeofday, timeval;

                timeval tv = void;
                // Posix gettimeofday called with a valid timeval address
                // and a null second parameter doesn't fail.
                gettimeofday(&tv, null);
                return convert!(TimeUnit.Second, targetUnit)(tv.tv_sec) + 
                    convert!(TimeUnit.Microsecond, targetUnit)(tv.tv_usec);

            } else version (linux) {
                    import core.sys.linux.time : CLOCK_REALTIME_COARSE;
                    import core.sys.posix.time : clock_gettime, CLOCK_REALTIME;

                    timespec ts = void;
                    immutable error = clock_gettime(CLOCK_REALTIME, &ts);
                    // Posix clock_gettime called with a valid address and valid clock_id is only
                    // permitted to fail if the number of seconds does not fit in time_t. If tv_sec
                    // is long or larger overflow won't happen before 292 billion years A.D.
                    static if (ts.tv_sec.max < long.max) {
                        if (error)
                            throw new TimeException("Call to clock_gettime() failed");
                    }
                    return convert!(TimeUnit.Second, targetUnit)(ts.tv_sec) + 
                        convert!(TimeUnit.Nanosecond, targetUnit)(ts.tv_nsec);

            } else version (FreeBSD) {
                import core.sys.freebsd.time : clock_gettime, CLOCK_REALTIME;

                timespec ts = void;
                immutable error = clock_gettime(CLOCK_REALTIME, &ts);
                // Posix clock_gettime called with a valid address and valid clock_id is only
                // permitted to fail if the number of seconds does not fit in time_t. If tv_sec
                // is long or larger overflow won't happen before 292 billion years A.D.
                static if (ts.tv_sec.max < long.max) {
                    if (error)
                        throw new TimeException("Call to clock_gettime() failed");
                }
                return convert!(TimeUnit.Second, targetUnit)(ts.tv_sec) + 
                        convert!(TimeUnit.Nanosecond, targetUnit)(ts.tv_nsec);
            } else version (NetBSD) {
                import core.sys.netbsd.time : clock_gettime, CLOCK_REALTIME;

                timespec ts = void;
                immutable error = clock_gettime(CLOCK_REALTIME, &ts);
                // Posix clock_gettime called with a valid address and valid clock_id is only
                // permitted to fail if the number of seconds does not fit in time_t. If tv_sec
                // is long or larger overflow won't happen before 292 billion years A.D.
                static if (ts.tv_sec.max < long.max) {
                    if (error)
                        throw new TimeException("Call to clock_gettime() failed");
                }
                return convert!(TimeUnit.Second, targetUnit)(ts.tv_sec) + 
                    convert!(TimeUnit.Nanosecond, targetUnit)(ts.tv_nsec);
            } else version (DragonFlyBSD) {
                import core.sys.dragonflybsd.time : clock_gettime, CLOCK_REALTIME;

                timespec ts = void;
                immutable error = clock_gettime(CLOCK_REALTIME, &ts);
                // Posix clock_gettime called with a valid address and valid clock_id is only
                // permitted to fail if the number of seconds does not fit in time_t. If tv_sec
                // is long or larger overflow won't happen before 292 billion years A.D.
                static if (ts.tv_sec.max < long.max) {
                    if (error)
                        throw new TimeException("Call to clock_gettime() failed");
                }
                return convert!(TimeUnit.Second, targetUnit)(ts.tv_sec) + 
                    convert!(TimeUnit.Nanosecond, targetUnit)(ts.tv_nsec);
            } else version (Solaris) {
                import core.sys.solaris.time : clock_gettime, CLOCK_REALTIME;

                timespec ts = void;
                immutable error = clock_gettime(CLOCK_REALTIME, &ts);
                // Posix clock_gettime called with a valid address and valid clock_id is only
                // permitted to fail if the number of seconds does not fit in time_t. If tv_sec
                // is long or larger overflow won't happen before 292 billion years A.D.
                static if (ts.tv_sec.max < long.max) {
                    if (error)
                        throw new TimeException("Call to clock_gettime() failed");
                }
                return convert!(TimeUnit.Second, targetUnit)(ts.tv_sec) + 
                    convert!(TimeUnit.Nanosecond, targetUnit)(ts.tv_nsec);
            } else
                static assert(0, "Unsupported OS");
        } else
            static assert(0, "Unsupported OS");
    }

    static string getTimeAsGMT() {
        return cast(string)*timingValue;
    }

    alias getDateAsGMT = getTimeAsGMT;

    static shared long timestamp;

    static void startClock() {
        if (cas(&_isClockRunning, false, true)) {
            dateThread.start();

        }
    }

    static void stopClock() @nogc {
        atomicStore(_isClockRunning, false);
    }

    private static shared const(char)[]* timingValue;
    private __gshared Thread dateThread;
    private static shared bool _isClockRunning = false;

    shared static this() {
        import std.array;

        Appender!(char[])[2] bufs;
        const(char)[][2] targets;

        void tick(size_t index) {
            bufs[index].clear();
            timestamp = core.stdc.time.time(null);
            auto date = Clock.currTime!(ClockType.coarse)(UTC());
            size_t sz = updateDate(bufs[index], date);
            targets[index] = bufs[index].data;
            atomicStore(timingValue, cast(shared)&targets[index]);
        }

        tick(0);

        dateThread = new Thread({
            size_t cur = 1;
            while (_isClockRunning) {
                tick(cur);
                cur = 1 - cur;
                Thread.sleep(1.seconds);
            }
        });

        dateThread.isDaemon = true;
        // FIXME: Needing refactor or cleanup -@zxp at 12/30/2018, 10:10:09 AM
        // 
        // It's not a good idea to launch another thread in shared static this().
        // https://issues.dlang.org/show_bug.cgi?id=19492
        // startClock();
    }

    shared static ~this() @nogc {
        if (cas(&_isClockRunning, true, false)) {
            // dateThread.join();
        }
    }

    private static size_t updateDate(Output, D)(ref Output sink, D date) {
        return formattedWrite(sink, "%s, %02s %s %04s %02s:%02s:%02s GMT", dayAsString(date.dayOfWeek),
                date.day, monthAsString(date.month), date.year, date.hour,
                date.minute, date.second);
    }

}
