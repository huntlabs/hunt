module hunt.datetime;

public import hunt.datetime.format;
import std.datetime;

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

class DateTimeHelper {
    static long currentTimeMillis() {
        return convert!(TimeUnit.HectoNanosecond, TimeUnit.Millisecond)(Clock.currStdTime);
    }
}
