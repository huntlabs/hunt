module hunt.time.util.QueryHelper;
import hunt.time.chrono;
import hunt.time.Clock;
import hunt.time.DateTimeException;
import hunt.time.DayOfWeek;
import hunt.time.Duration;
import hunt.time.format;
import hunt.time.Instant;
import hunt.time.LocalDate;
import hunt.time.LocalDateTime;
import hunt.time.LocalTime;
import hunt.time.Month;
import hunt.time.MonthDay;
import hunt.time.OffsetDateTime;
import hunt.time.OffsetTime;
import hunt.time.Period;
import hunt.time.Ser;
import hunt.time.temporal;
import hunt.time.Year;
import hunt.time.YearMonth;
// import hunt.time.zone;
import hunt.time.ZonedDateTime;
import hunt.time.ZoneId;
import hunt.time.ZoneOffset;
import hunt.time.ZoneRegion;

import std.stdio;
import std.conv;
import std.exception;

class QueryHelper
{
    static R query(R)(TemporalAccessor t, TemporalQuery!(R) param)
    {
        auto typeinfo = typeid(cast(Object) t);
        // writeln("test : ", typeinfo);
        if (typeinfo == typeid(DayOfWeek))
        {
            return (cast(DayOfWeek) t).query!R(param);
        }
        else if (typeinfo == typeid(Parsed))
        {
            return (cast(Parsed) t).query!R(param);
        }
        else if (typeinfo == typeid(Instant))
        {
            return (cast(Instant) t).query!R(param);
        }
        else if (typeinfo == typeid(LocalDate))
        {
            return (cast(LocalDate) t).query!R(param);
        }
        else if (typeinfo == typeid(LocalDateTime))
        {
            return (cast(LocalDateTime) t).query!R(param);
        }
        else if (typeinfo == typeid(LocalTime))
        {
            return (cast(LocalTime) t).query!R(param);
        }
        else if (typeinfo == typeid(Month))
        {
            return (cast(Month) t).query!R(param);
        }
        else if (typeinfo == typeid(MonthDay))
        {
            return (cast(MonthDay) t).query!R(param);
        }
        else if (typeinfo == typeid(OffsetDateTime))
        {
            return (cast(OffsetDateTime) t).query!R(param);
        }
        else if (typeinfo == typeid(OffsetTime))
        {
            return (cast(OffsetTime) t).query!R(param);
        }
        else if (typeinfo == typeid(Year))
        {
            return (cast(Year) t).query!R(param);
        }
        else if (typeinfo == typeid(YearMonth))
        {
            return (cast(YearMonth) t).query!R(param);
        }
        else if (typeinfo == typeid(ZonedDateTime))
        {
            return (cast(ZonedDateTime) t).query!R(param);
        }
        else if (typeinfo == typeid(ZoneOffset))
        {
            return (cast(ZoneOffset) t).query!R(param);
        }
        else if (typeinfo == typeid(AnonymousClass1))
        {
            return (cast(AnonymousClass1) t).query!R(param);
        }
        else if (typeinfo == typeid(AnonymousClass2))
        {
            return (cast(AnonymousClass2) t).query!R(param);
        }
        else if (typeinfo == typeid(AnonymousClass3))
        {
            return (cast(AnonymousClass3) t).query!R(param);
        }
        else if (t !is null)
        {
            throw new Exception("unsurpport TemporalAccessor : " ~ typeinfo.name);
        }
        return R.init;
    }
}

class AnonymousClass1 : TemporalAccessor
{
    override public bool isSupported(TemporalField field)
    {
        return false;
    }

    override public long getLong(TemporalField field)
    {
        throw new UnsupportedTemporalTypeException("Unsupported field: " ~ field.toString);
    }
    /*@SuppressWarnings("unchecked")*/
    // override
    public R query(R)(TemporalQuery!(R) query)
    {
        if (query == TemporalQueries.chronology())
        {
            return cast(R) /* Chronology. */ this;
        }
        return  /* TemporalAccessor. */ super_query(query);
    }

    R super_query(R)(TemporalQuery!(R) query)
    {
        if (query == TemporalQueries.zoneId() || query == TemporalQueries.chronology()
                || query == TemporalQueries.precision())
        {
            return null;
        }
        return query.queryFrom(this);
    }

    override ValueRange range(TemporalField field)
    {
        if (cast(ChronoField)(field) !is null)
        {
            if (isSupported(field))
            {
                return field.range();
            }
            throw new UnsupportedTemporalTypeException("Unsupported field: " ~ field.toString);
        }
        assert(field, "field");
        return field.rangeRefinedBy(this);
    }

    override int get(TemporalField field)
    {
        ValueRange range = range(field);
        if (range.isIntValue() == false)
        {
            throw new UnsupportedTemporalTypeException(
                    "Invalid field " ~ field.toString ~ " for get() method, use getLong() instead");
        }
        long value = getLong(field);
        if (range.isValidValue(value) == false)
        {
            throw new DateTimeException(
                    "Invalid value for " ~ field.toString ~ " (valid values "
                    ~ range.toString ~ "): " ~ value.to!string);
        }
        return cast(int) value;
    }

    override string toString()
    {
        return super.toString();
    }
}

class AnonymousClass2 : TemporalAccessor
{
    private ChronoLocalDate effectiveDate;
    private TemporalAccessor temporal;
    private Chronology effectiveChrono;
    private ZoneId effectiveZone;

    this(ChronoLocalDate cld, TemporalAccessor t,Chronology ec,ZoneId ez)
    {
        effectiveDate = cld;
        temporal = t;
        effectiveChrono = ec;
        effectiveZone = ez;
    }

    override public bool isSupported(TemporalField field)
    {
        if (effectiveDate !is null && field.isDateBased())
        {
            return effectiveDate.isSupported(field);
        }
        return temporal.isSupported(field);
    }

    override public ValueRange range(TemporalField field)
    {
        if (effectiveDate !is null && field.isDateBased())
        {
            return effectiveDate.range(field);
        }
        return temporal.range(field);
    }

    override public long getLong(TemporalField field)
    {
        if (effectiveDate !is null && field.isDateBased())
        {
            return effectiveDate.getLong(field);
        }
        return temporal.getLong(field);
    }
    /*@SuppressWarnings("unchecked")*/
    /* override */
    public R query(R)(TemporalQuery!(R) query)
    {
        if (query == TemporalQueries.chronology())
        {
            return cast(R) effectiveChrono;
        }
        if (query == TemporalQueries.zoneId())
        {
            return cast(R) effectiveZone;
        }
        if (query == TemporalQueries.precision())
        {
            return QueryHelper.query!R(temporal, query);
        }
        return query.queryFrom(this);
    }

    override public string toString()
    {
        return temporal.toString ~ (effectiveChrono !is null ? " with chronology " ~ effectiveChrono.toString
                : "") ~ (effectiveZone !is null ? " with zone " ~ effectiveZone.toString : "");
    }

    override int get(TemporalField field)
    {
        ValueRange range = range(field);
        if (range.isIntValue() == false)
        {
            throw new UnsupportedTemporalTypeException(
                    "Invalid field " ~ field.toString ~ " for get() method, use getLong() instead");
        }
        long value = getLong(field);
        if (range.isValidValue(value) == false)
        {
            throw new DateTimeException(
                    "Invalid value for " ~ field.toString ~ " (valid values "
                    ~ range.toString ~ "): " ~ value.to!string);
        }
        return cast(int) value;
    }
}

class AnonymousClass3 : TemporalAccessor
{
    override public bool isSupported(TemporalField field)
    {
        return false;
    }

    override public long getLong(TemporalField field)
    {
        throw new UnsupportedTemporalTypeException("Unsupported field: " ~ typeid(field).name);
    }
    /*@SuppressWarnings("unchecked")*/
    /* override */ public R query(R)(TemporalQuery!(R) query)
    {
        if (query == TemporalQueries.zoneId())
        {
            return cast(R) /* ZoneId. */ this;
        }
        return  /* TemporalAccessor. */ super_query(query);
    }

    R super_query(R)(TemporalQuery!(R) query)
    {
        if (query == TemporalQueries.zoneId() || query == TemporalQueries.chronology()
                || query == TemporalQueries.precision())
        {
            return null;
        }
        return query.queryFrom(this);
    }

    override ValueRange range(TemporalField field)
    {
        if (cast(ChronoField)(field) !is null)
        {
            if (isSupported(field))
            {
                return field.range();
            }
            throw new UnsupportedTemporalTypeException("Unsupported field: " ~ field.toString);
        }
        assert(field, "field");
        return field.rangeRefinedBy(this);
    }

    override int get(TemporalField field)
    {
        ValueRange range = range(field);
        if (range.isIntValue() == false)
        {
            throw new UnsupportedTemporalTypeException(
                    "Invalid field " ~ field.toString ~ " for get() method, use getLong() instead");
        }
        long value = getLong(field);
        if (range.isValidValue(value) == false)
        {
            throw new DateTimeException(
                    "Invalid value for " ~ field.toString ~ " (valid values "
                    ~ range.toString ~ "): " ~ value.to!string);
        }
        return cast(int) value;
    }

    override string toString()
    {
        return super.toString();
    }
}
