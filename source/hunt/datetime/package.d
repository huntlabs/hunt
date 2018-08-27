module hunt.datetime;

public import hunt.datetime.format;


import std.datetime;

class TimeUnits
{
    enum  Year =  "years";
    enum  Month =  "months";
    enum  Week =  "weeks";
    enum  Day =  "days";
    enum  Hour =  "hours";
    enum  Second =  "seconds";
    enum  Millisecond =  "msecs";
    enum  Microsecond =  "usecs";
    enum  HectoNanosecond =  "hnsecs";
    enum  Nanosecond =  "nsecs";

}

class DateTimeHelper
{
    static long currentTimeMillis()
    {
        return convert!(TimeUnits.HectoNanosecond, TimeUnits.Millisecond)(Clock.currStdTime);
    }
}