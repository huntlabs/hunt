module hunt.datetime;

public import hunt.datetime.format;

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

/**
*/
class DateTimeHelper {
    static long currentTimeMillis() {
        return convert!(TimeUnit.HectoNanosecond, TimeUnit.Millisecond)(Clock.currStdTime);
    }

    static string getDateAsGMT() {
        return cast(string)*httpDate;
    }

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
            bufs[index].clear();
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
                Thread.sleep(250.msecs);
            }
        });
    }

    shared static ~this() {
        stopClock();
        dateThread.join();
    }

    private static size_t updateDate(Output, D)(ref Output sink, D date) {
        return formattedWrite(sink, "%s, %02s %s %04s %02s:%02s:%02s GMT", dayAsString(date.dayOfWeek),
                date.day, monthAsString(date.month), date.year, date.hour,
                date.minute, date.second);
    }
}
