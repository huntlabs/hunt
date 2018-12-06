module hunt.datetime.Helper;

import hunt.datetime.format;

import core.atomic;
import core.thread : Thread;
import std.datetime;
import std.format : formattedWrite;

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
    return DateTimeHelper.timestamp;
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

/**
*/
class DateTimeHelper {
    static long currentTimeMillis() {
        return convert!(TimeUnit.HectoNanosecond, TimeUnit.Millisecond)(Clock.currStdTime);
    }

    static string getDateAsGMT() {
        return cast(string)*httpDate;
    }

    static shared long timestamp;

    static void startClock() {
        if (!atomicLoad(_isClockRunning)) {
            atomicStore(_isClockRunning, true);
            dateThread.start();
        }
    }

    static void stopClock() {
        atomicStore(_isClockRunning, false);
    }

    private static shared const(char)[]* httpDate;
    private static __gshared Thread dateThread;
    private static shared bool _isClockRunning = false;

    shared static this() {
        import std.array;

        Appender!(char[])[2] bufs;
        const(char)[][2] targets;

        void tick(size_t index) {
            import core.stdc.time : time;

            bufs[index].clear();
            timestamp = time(null);
            auto date = Clock.currTime!(ClockType.coarse)(UTC());
            size_t sz = updateDate(bufs[index], date);
            targets[index] = bufs[index].data;
            atomicStore(httpDate, cast(shared)&targets[index]);
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
    }

    shared static ~this() {
        if (cas(&_isClockRunning, true, false)) {
            dateThread.join();
        }
    }

    private static size_t updateDate(Output, D)(ref Output sink, D date) {
        return formattedWrite(sink, "%s, %02s %s %04s %02s:%02s:%02s GMT", dayAsString(date.dayOfWeek),
                date.day, monthAsString(date.month), date.year, date.hour,
                date.minute, date.second);
    }
}
