
module hunt.time.format.Parsed;

import hunt.time.temporal.ChronoField;

import hunt.time.DateTimeException;
import hunt.time.Instant;
import hunt.time.LocalDate;
import hunt.time.LocalTime;
import hunt.time.Period;
import hunt.time.ZoneId;
import hunt.time.ZoneOffset;
import hunt.time.chrono.ChronoLocalDate;
import hunt.time.chrono.ChronoLocalDateTime;
import hunt.time.chrono.ChronoZonedDateTime;
import hunt.time.chrono.Chronology;
import hunt.time.temporal.ChronoField;
import hunt.time.temporal.TemporalAccessor;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.TemporalQueries;
import hunt.time.temporal.TemporalQuery;
import hunt.time.temporal.UnsupportedTemporalTypeException;
import hunt.time.temporal.ValueRange;

import hunt.container.HashMap;
import hunt.container.Iterator;
import hunt.container.Map;
import std.conv;
import hunt.string.StringBuilder;
import hunt.container.Set;
import hunt.lang;
import hunt.time.format.ResolverStyle;

/**
 * A store of parsed data.
 * !(p)
 * This class is used during parsing to collect the data. Part of the parsing process
 * involves handling optional blocks and multiple copies of the data get created to
 * support the necessary backtracking.
 * !(p)
 * Once parsing is completed, this class can be used as the resultant {@code TemporalAccessor}.
 * In most cases, it is only exposed once the fields have been resolved.
 *
 * @implSpec
 * This class is a mutable context intended for use from a single thread.
 * Usage of the class is thread-safe within standard parsing as a new instance of this class
 * is automatically created for each parse and parsing is single-threaded
 *
 * @since 1.8
 */
final class Parsed : TemporalAccessor
{
    // some fields are accessed using package scope from DateTimeParseContext

    /**
     * The parsed fields.
     */
    Map!(TemporalField, Long) fieldValues;
    /**
     * The parsed zone.
     */
    ZoneId zone;
    /**
     * The parsed chronology.
     */
    Chronology chrono;
    /**
     * Whether a leap-second is parsed.
     */
    bool leapSecond;
    /**
     * The resolver style to use.
     */
    private ResolverStyle resolverStyle;
    /**
     * The resolved date.
     */
    private ChronoLocalDate date;
    /**
     * The resolved time.
     */
    private LocalTime time;
    /**
     * The excess period from time-only parsing.
     */
    Period excessDays;

    /**
     * Creates an instance.
     */
    this()
    {
        fieldValues = new HashMap!(TemporalField, Long)();
        excessDays = Period.ZERO;
    }

    /**
     * Creates a copy.
     */
    Parsed copy()
    {
        // only copy fields used _in parsing stage
        Parsed cloned = new Parsed();
        cloned.fieldValues.putAll(this.fieldValues);
        cloned.zone = this.zone;
        cloned.chrono = this.chrono;
        cloned.leapSecond = this.leapSecond;
        return cloned;
    }

    //-----------------------------------------------------------------------
    override public bool isSupported(TemporalField field)
    {
        if (fieldValues.containsKey(field) || (date !is null
                && date.isSupported(field)) || (time !is null && time.isSupported(field)))
        {
            return true;
        }
        return field !is null && ((cast(ChronoField)(field) !is null) == false)
            && field.isSupportedBy(this);
    }

    override public long getLong(TemporalField field)
    {
        assert(field, "field");
        Long value = fieldValues.get(field);
        if (value !is null)
        {
            return value.longValue();
        }
        if (date !is null && date.isSupported(field))
        {
            return date.getLong(field);
        }
        if (time !is null && time.isSupported(field))
        {
            return time.getLong(field);
        }
        if (cast(ChronoField)(field) !is null)
        {
            throw new UnsupportedTemporalTypeException("Unsupported field: " ~ typeid(field).name);
        }
        return field.getFrom(this);
    }

    /*@SuppressWarnings("unchecked")*/
    /* override */ public R query(R)(TemporalQuery!(R) query)
    {
        if (query == TemporalQueries.zoneId())
        {
            return cast(R) zone;
        }
        else if (query == TemporalQueries.chronology())
        {
            return cast(R) chrono;
        }
        else if (query == TemporalQueries.localDate())
        {
            return cast(R)(date !is null ? LocalDate.from(date) : null);
        }
        else if (query == TemporalQueries.localTime())
        {
            return cast(R) time;
        }
        else if (query == TemporalQueries.offset())
        {
            Long offsetSecs = fieldValues.get(ChronoField.OFFSET_SECONDS);
            if (offsetSecs !is null)
            {
                return cast(R) ZoneOffset.ofTotalSeconds(offsetSecs.intValue());
            }
            if (cast(ZoneOffset)(zone) !is null)
            {
                return cast(R) zone;
            }
            return query.queryFrom(this);
        }
        else if (query == TemporalQueries.zone())
        {
            return query.queryFrom(this);
        }
        else if (query == TemporalQueries.precision())
        {
            return null; // not a complete date/time
        }
        // inline TemporalAccessor.super.query(query) as an optimization
        // non-JDK classes are not permitted to make this optimization
        return query.queryFrom(this);
    }

    //-----------------------------------------------------------------------
    /**
     * Resolves the fields _in this context.
     *
     * @param resolverStyle  the resolver style, not null
     * @param resolverFields  the fields to use for resolving, null for all fields
     * @return this, for method chaining
     * @throws DateTimeException if resolving one field results _in a value for
     *  another field that is _in conflict
     */
    TemporalAccessor resolve(ResolverStyle resolverStyle, Set!(TemporalField) resolverFields)
    {
        if (resolverFields !is null)
        {
            // fieldValues.keySet().retainAll(resolverFields);
            foreach (k; resolverFields)
                if (!fieldValues.containsKey(k))
                    fieldValues.remove(k);
        }
        this.resolverStyle = resolverStyle;
        resolveFields();
        resolveTimeLenient();
        crossCheck();
        resolvePeriod();
        resolveFractional();
        resolveInstant();
        return this;
    }

    //-----------------------------------------------------------------------
    private void resolveFields()
    {
        // resolve ChronoField
        resolveInstantFields();
        resolveDateFields();
        resolveTimeFields();

        // if any other fields, handle them
        // any lenient date resolution should return epoch-day
        if (fieldValues.size() > 0)
        {
            int changedCount = 0;
            outer: while (changedCount < 50)
            {
                foreach (TemporalField k, Long v; fieldValues)
                {
                    TemporalField targetField = k;
                    TemporalAccessor resolvedObject = targetField.resolve(fieldValues,
                            this, resolverStyle);
                    if (resolvedObject !is null)
                    {
                        if (cast(ChronoZonedDateTime!ChronoLocalDate)(resolvedObject) !is null)
                        {
                            ChronoZonedDateTime!(ChronoLocalDate) czdt = cast(
                                    ChronoZonedDateTime!(ChronoLocalDate)) resolvedObject;
                            if (zone is null)
                            {
                                zone = czdt.getZone();
                            }
                            else if ((zone == czdt.getZone()) == false)
                            {
                                throw new DateTimeException(
                                        "ChronoZonedDateTime must use the effective parsed zone: " ~ typeid(zone)
                                        .name);
                            }
                            resolvedObject = czdt.toLocalDateTime();
                        }
                        if (cast(ChronoLocalDateTime!ChronoLocalDate)(resolvedObject) !is null)
                        {
                            ChronoLocalDateTime!(ChronoLocalDate) cldt = cast(
                                    ChronoLocalDateTime!(ChronoLocalDate)) resolvedObject;
                            updateCheckConflict(cldt.toLocalTime(), Period.ZERO);
                            updateCheckConflict(cldt.toLocalDate());
                            changedCount++;
                            continue outer; // have to restart to avoid concurrent modification
                        }
                        if (cast(ChronoLocalDate)(resolvedObject) !is null)
                        {
                            updateCheckConflict(cast(ChronoLocalDate) resolvedObject);
                            changedCount++;
                            continue outer; // have to restart to avoid concurrent modification
                        }
                        if (cast(LocalTime)(resolvedObject) !is null)
                        {
                            updateCheckConflict(cast(LocalTime) resolvedObject, Period.ZERO);
                            changedCount++;
                            continue outer; // have to restart to avoid concurrent modification
                        }
                        throw new DateTimeException("Method resolve() can only return ChronoZonedDateTime, "
                                ~ "ChronoLocalDateTime, ChronoLocalDate or LocalTime");
                    }
                    else if (fieldValues.containsKey(targetField) == false)
                    {
                        changedCount++;
                        continue outer; // have to restart to avoid concurrent modification
                    }
                }
                break;
            }
            if (changedCount == 50)
            { // catch infinite loops
                throw new DateTimeException(
                        "One of the parsed fields has an incorrectly implemented resolve method");
            }
            // if something changed then have to redo ChronoField resolve
            if (changedCount > 0)
            {
                resolveInstantFields();
                resolveDateFields();
                resolveTimeFields();
            }
        }
    }

    private void updateCheckConflict(TemporalField targetField,
            TemporalField changeField, Long changeValue)
    {
        Long old = fieldValues.put(changeField, changeValue);
        if (old !is null && old.longValue() != changeValue.longValue())
        {
            throw new DateTimeException("Conflict found: " ~ changeField.toString ~ " " ~ old.toString ~ " differs from "
                    ~ changeField.toString ~ " " ~ changeValue.toString
                    ~ " while resolving  " ~ targetField.toString);
        }
    }

    //-----------------------------------------------------------------------
    private void resolveInstantFields()
    {
        // resolve parsed instant seconds to date and time if zone available
        if (fieldValues.containsKey(ChronoField.INSTANT_SECONDS))
        {
            if (zone !is null)
            {
                resolveInstantFields0(zone);
            }
            else
            {
                Long offsetSecs = fieldValues.get(ChronoField.OFFSET_SECONDS);
                if (offsetSecs !is null)
                {
                    ZoneOffset offset = ZoneOffset.ofTotalSeconds(offsetSecs.intValue());
                    resolveInstantFields0(offset);
                }
            }
        }
    }

    private void resolveInstantFields0(ZoneId selectedZone)
    {
        Instant instant = Instant.ofEpochSecond(
                fieldValues.remove(ChronoField.INSTANT_SECONDS).longValue());
        ChronoZonedDateTime!(ChronoLocalDate) zdt = chrono.zonedDateTime(instant, selectedZone);
        updateCheckConflict(zdt.toLocalDate());
        updateCheckConflict(ChronoField.INSTANT_SECONDS, ChronoField.SECOND_OF_DAY,
                new Long(cast(long) zdt.toLocalTime().toSecondOfDay()));
    }

    //-----------------------------------------------------------------------
    private void resolveDateFields()
    {
        updateCheckConflict(chrono.resolveDate(fieldValues, resolverStyle));
    }

    private void updateCheckConflict(ChronoLocalDate cld)
    {
        if (date !is null)
        {
            if (cld !is null && (date == cld) == false)
            {
                throw new DateTimeException(
                        "Conflict found: Fields resolved to two different dates: "
                        ~ date.toString ~ " " ~ cld.toString);
            }
        }
        else if (cld !is null)
        {
            if ((chrono == cld.getChronology()) == false)
            {
                throw new DateTimeException(
                        "ChronoLocalDate must use the effective parsed chronology: "
                        ~ chrono.toString);
            }
            date = cld;
        }
    }

    //-----------------------------------------------------------------------
    private void resolveTimeFields()
    {
        // simplify fields
        if (fieldValues.containsKey(ChronoField.CLOCK_HOUR_OF_DAY))
        {
            // lenient allows anything, smart allows 0-24, strict allows 1-24
            long ch = fieldValues.remove(ChronoField.CLOCK_HOUR_OF_DAY).longValue();
            if (resolverStyle == ResolverStyle.STRICT
                    || (resolverStyle == ResolverStyle.SMART && ch != 0))
            {
                ChronoField.CLOCK_HOUR_OF_DAY.checkValidValue(ch);
            }
            updateCheckConflict(ChronoField.CLOCK_HOUR_OF_DAY,
                    ChronoField.HOUR_OF_DAY, ch == 24 ? new Long(0) : new Long(ch));
        }
        if (fieldValues.containsKey(ChronoField.CLOCK_HOUR_OF_AMPM))
        {
            // lenient allows anything, smart allows 0-12, strict allows 1-12
            long ch = fieldValues.remove(ChronoField.CLOCK_HOUR_OF_AMPM).longValue();
            if (resolverStyle == ResolverStyle.STRICT
                    || (resolverStyle == ResolverStyle.SMART && ch != 0))
            {
                ChronoField.CLOCK_HOUR_OF_AMPM.checkValidValue(ch);
            }
            updateCheckConflict(ChronoField.CLOCK_HOUR_OF_AMPM,
                    ChronoField.HOUR_OF_AMPM, ch == 12 ? new Long(0) : new Long(ch));
        }
        if (fieldValues.containsKey(ChronoField.AMPM_OF_DAY)
                && fieldValues.containsKey(ChronoField.HOUR_OF_AMPM))
        {
            long ap = fieldValues.remove(ChronoField.AMPM_OF_DAY).longValue();
            long hap = fieldValues.remove(ChronoField.HOUR_OF_AMPM).longValue();
            if (resolverStyle == ResolverStyle.LENIENT)
            {
                updateCheckConflict(ChronoField.AMPM_OF_DAY, ChronoField.HOUR_OF_DAY,
                        new Long(Math.addExact(Math.multiplyExact(ap, 12), hap)));
            }
            else
            { // STRICT or SMART
                ChronoField.AMPM_OF_DAY.checkValidValue(ap);
                ChronoField.HOUR_OF_AMPM.checkValidValue(ap);
                updateCheckConflict(ChronoField.AMPM_OF_DAY,
                        ChronoField.HOUR_OF_DAY, new Long(ap * 12 + hap));
            }
        }
        if (fieldValues.containsKey(ChronoField.NANO_OF_DAY))
        {
            long nod = fieldValues.remove(ChronoField.NANO_OF_DAY).longValue();
            if (resolverStyle != ResolverStyle.LENIENT)
            {
                ChronoField.NANO_OF_DAY.checkValidValue(nod);
            }
            updateCheckConflict(ChronoField.NANO_OF_DAY,
                    ChronoField.HOUR_OF_DAY, new Long(nod / 3600_000_000_000L));
            updateCheckConflict(ChronoField.NANO_OF_DAY,
                    ChronoField.MINUTE_OF_HOUR, new Long((nod / 60_000_000_000L) % 60));
            updateCheckConflict(ChronoField.NANO_OF_DAY,
                    ChronoField.SECOND_OF_MINUTE, new Long((nod / 1_000_000_000L) % 60));
            updateCheckConflict(ChronoField.NANO_OF_DAY,
                    ChronoField.NANO_OF_SECOND, new Long(nod % 1_000_000_000L));
        }
        if (fieldValues.containsKey(ChronoField.MICRO_OF_DAY))
        {
            long cod = fieldValues.remove(ChronoField.MICRO_OF_DAY).longValue();
            if (resolverStyle != ResolverStyle.LENIENT)
            {
                ChronoField.MICRO_OF_DAY.checkValidValue(cod);
            }
            updateCheckConflict(ChronoField.MICRO_OF_DAY,
                    ChronoField.SECOND_OF_DAY, new Long(cod / 1_000_000L));
            updateCheckConflict(ChronoField.MICRO_OF_DAY,
                    ChronoField.MICRO_OF_SECOND, new Long(cod % 1_000_000L));
        }
        if (fieldValues.containsKey(ChronoField.MILLI_OF_DAY))
        {
            long lod = fieldValues.remove(ChronoField.MILLI_OF_DAY).longValue();
            if (resolverStyle != ResolverStyle.LENIENT)
            {
                ChronoField.MILLI_OF_DAY.checkValidValue(lod);
            }
            updateCheckConflict(ChronoField.MILLI_OF_DAY,
                    ChronoField.SECOND_OF_DAY, new Long(lod / 1_000));
            updateCheckConflict(ChronoField.MILLI_OF_DAY,
                    ChronoField.MILLI_OF_SECOND, new Long(lod % 1_000));
        }
        if (fieldValues.containsKey(ChronoField.SECOND_OF_DAY))
        {
            long sod = fieldValues.remove(ChronoField.SECOND_OF_DAY).longValue();
            if (resolverStyle != ResolverStyle.LENIENT)
            {
                ChronoField.SECOND_OF_DAY.checkValidValue(sod);
            }
            updateCheckConflict(ChronoField.SECOND_OF_DAY,
                    ChronoField.HOUR_OF_DAY, new Long(sod / 3600));
            updateCheckConflict(ChronoField.SECOND_OF_DAY,
                    ChronoField.MINUTE_OF_HOUR, new Long((sod / 60) % 60));
            updateCheckConflict(ChronoField.SECOND_OF_DAY,
                    ChronoField.SECOND_OF_MINUTE, new Long(sod % 60));
        }
        if (fieldValues.containsKey(ChronoField.MINUTE_OF_DAY))
        {
            long mod = fieldValues.remove(ChronoField.MINUTE_OF_DAY).longValue();
            if (resolverStyle != ResolverStyle.LENIENT)
            {
                ChronoField.MINUTE_OF_DAY.checkValidValue(mod);
            }
            updateCheckConflict(ChronoField.MINUTE_OF_DAY,
                    ChronoField.HOUR_OF_DAY, new Long(mod / 60));
            updateCheckConflict(ChronoField.MINUTE_OF_DAY,
                    ChronoField.MINUTE_OF_HOUR, new Long(mod % 60));
        }

        // combine partial second fields strictly, leaving lenient expansion to later
        if (fieldValues.containsKey(ChronoField.NANO_OF_SECOND))
        {
            long nos = fieldValues.get(ChronoField.NANO_OF_SECOND).longValue();
            if (resolverStyle != ResolverStyle.LENIENT)
            {
                ChronoField.NANO_OF_SECOND.checkValidValue(nos);
            }
            if (fieldValues.containsKey(ChronoField.MICRO_OF_SECOND))
            {
                long cos = fieldValues.remove(ChronoField.MICRO_OF_SECOND).longValue();
                if (resolverStyle != ResolverStyle.LENIENT)
                {
                    ChronoField.MICRO_OF_SECOND.checkValidValue(cos);
                }
                nos = cos * 1000 + (nos % 1000);
                updateCheckConflict(ChronoField.MICRO_OF_SECOND,
                        ChronoField.NANO_OF_SECOND, new Long(nos));
            }
            if (fieldValues.containsKey(ChronoField.MILLI_OF_SECOND))
            {
                long los = fieldValues.remove(ChronoField.MILLI_OF_SECOND).longValue();
                if (resolverStyle != ResolverStyle.LENIENT)
                {
                    ChronoField.MILLI_OF_SECOND.checkValidValue(los);
                }
                updateCheckConflict(ChronoField.MILLI_OF_SECOND,
                        ChronoField.NANO_OF_SECOND, new Long(los * 1_000_000L + (nos % 1_000_000L)));
            }
        }

        // convert to time if all four fields available (optimization)
        if (fieldValues.containsKey(ChronoField.HOUR_OF_DAY) && fieldValues.containsKey(ChronoField.MINUTE_OF_HOUR)
                && fieldValues.containsKey(ChronoField.SECOND_OF_MINUTE)
                && fieldValues.containsKey(ChronoField.NANO_OF_SECOND))
        {
            long hod = fieldValues.remove(ChronoField.HOUR_OF_DAY).longValue();
            long moh = fieldValues.remove(ChronoField.MINUTE_OF_HOUR).longValue();
            long som = fieldValues.remove(ChronoField.SECOND_OF_MINUTE).longValue();
            long nos = fieldValues.remove(ChronoField.NANO_OF_SECOND).longValue();
            resolveTime(hod, moh, som, nos);
        }
    }

    private void resolveTimeLenient()
    {
        // leniently create a time from incomplete information
        // done after everything else as it creates information from nothing
        // which would break updateCheckConflict(field)

        if (time is null)
        {
            // NANO_OF_SECOND merged with MILLI/MICRO above
            if (fieldValues.containsKey(ChronoField.MILLI_OF_SECOND))
            {
                long los = fieldValues.remove(ChronoField.MILLI_OF_SECOND).longValue();
                if (fieldValues.containsKey(ChronoField.MICRO_OF_SECOND))
                {
                    // merge milli-of-second and micro-of-second for better error message
                    long cos = los * 1_000 + (fieldValues.get(ChronoField.MICRO_OF_SECOND)
                            .longValue() % 1_000);
                    updateCheckConflict(ChronoField.MILLI_OF_SECOND,
                            ChronoField.MICRO_OF_SECOND, new Long(cos));
                    fieldValues.remove(ChronoField.MICRO_OF_SECOND);
                    fieldValues.put(ChronoField.NANO_OF_SECOND, new Long(cos * 1_000L));
                }
                else
                {
                    // convert milli-of-second to nano-of-second
                    fieldValues.put(ChronoField.NANO_OF_SECOND, new Long(los * 1_000_000L));
                }
            }
            else if (fieldValues.containsKey(ChronoField.MICRO_OF_SECOND))
            {
                // convert micro-of-second to nano-of-second
                long cos = fieldValues.remove(ChronoField.MICRO_OF_SECOND).longValue();
                fieldValues.put(ChronoField.NANO_OF_SECOND, new Long(cos * 1_000L));
            }

            // merge hour/minute/second/nano leniently
            Long hod = fieldValues.get(ChronoField.HOUR_OF_DAY);
            if (hod !is null)
            {
                Long moh = fieldValues.get(ChronoField.MINUTE_OF_HOUR);
                Long som = fieldValues.get(ChronoField.SECOND_OF_MINUTE);
                Long nos = fieldValues.get(ChronoField.NANO_OF_SECOND);

                // check for invalid combinations that cannot be defaulted
                if ((moh is null && (som !is null || nos !is null))
                        || (moh !is null && som is null && nos !is null))
                {
                    return;
                }

                // default as necessary and build time
                long mohVal = (moh !is null ? moh.longValue() : 0);
                long somVal = (som !is null ? som.longValue() : 0);
                long nosVal = (nos !is null ? nos.longValue() : 0);
                resolveTime(hod.longValue(), mohVal, somVal, nosVal);
                fieldValues.remove(ChronoField.HOUR_OF_DAY);
                fieldValues.remove(ChronoField.MINUTE_OF_HOUR);
                fieldValues.remove(ChronoField.SECOND_OF_MINUTE);
                fieldValues.remove(ChronoField.NANO_OF_SECOND);
            }
        }

        // validate remaining
        if (resolverStyle != ResolverStyle.LENIENT && fieldValues.size() > 0)
        {
            foreach (TemporalField k, Long v; fieldValues)
            {
                TemporalField field = k;
                if (cast(ChronoField)(field) !is null && field.isTimeBased())
                {
                    (cast(ChronoField) field).checkValidValue(v.longValue());
                }
            }
        }
    }

    private void resolveTime(long hod, long moh, long som, long nos)
    {
        if (resolverStyle == ResolverStyle.LENIENT)
        {
            long totalNanos = Math.multiplyExact(hod, 3600_000_000_000L);
            totalNanos = Math.addExact(totalNanos, Math.multiplyExact(moh, 60_000_000_000L));
            totalNanos = Math.addExact(totalNanos, Math.multiplyExact(som, 1_000_000_000L));
            totalNanos = Math.addExact(totalNanos, nos);
            int excessDays = cast(int) Math.floorDiv(totalNanos, 86400_000_000_000L); // safe int cast
            long nod = Math.floorMod(totalNanos, 86400_000_000_000L);
            updateCheckConflict(LocalTime.ofNanoOfDay(nod), Period.ofDays(excessDays));
        }
        else
        { // STRICT or SMART
            int mohVal = ChronoField.MINUTE_OF_HOUR.checkValidIntValue(moh);
            int nosVal = ChronoField.NANO_OF_SECOND.checkValidIntValue(nos);
            // handle 24:00 end of day
            if (resolverStyle == ResolverStyle.SMART && hod == 24
                    && mohVal == 0 && som == 0 && nosVal == 0)
            {
                updateCheckConflict(LocalTime.MIDNIGHT, Period.ofDays(1));
            }
            else
            {
                int hodVal = ChronoField.HOUR_OF_DAY.checkValidIntValue(hod);
                int somVal = ChronoField.SECOND_OF_MINUTE.checkValidIntValue(som);
                updateCheckConflict(LocalTime.of(hodVal, mohVal, somVal, nosVal), Period.ZERO);
            }
        }
    }

    private void resolvePeriod()
    {
        // add whole days if we have both date and time
        if (date !is null && time !is null && excessDays.isZero() == false)
        {
            date = date.plus(excessDays);
            excessDays = Period.ZERO;
        }
    }

    private void resolveFractional()
    {
        // ensure fractional seconds available as ChronoField requires
        // resolveTimeLenient() will have merged MICRO_OF_SECOND/MILLI_OF_SECOND to NANO_OF_SECOND
        if (time is null && (fieldValues.containsKey(ChronoField.INSTANT_SECONDS)
                || fieldValues.containsKey(ChronoField.SECOND_OF_DAY)
                || fieldValues.containsKey(ChronoField.SECOND_OF_MINUTE)))
        {
            if (fieldValues.containsKey(ChronoField.NANO_OF_SECOND))
            {
                long nos = fieldValues.get(ChronoField.NANO_OF_SECOND).longValue();
                fieldValues.put(ChronoField.MICRO_OF_SECOND, new Long(nos / 1000));
                fieldValues.put(ChronoField.MILLI_OF_SECOND, new Long(nos / 1000000));
            }
            else
            {
                fieldValues.put(ChronoField.NANO_OF_SECOND, new Long(0L));
                fieldValues.put(ChronoField.MICRO_OF_SECOND, new Long(0L));
                fieldValues.put(ChronoField.MILLI_OF_SECOND, new Long(0L));
            }
        }
    }

    private void resolveInstant()
    {
        // add instant seconds if we have date, time and zone
        // Offset (if present) will be given priority over the zone.
        if (date !is null && time !is null)
        {
            Long offsetSecs = fieldValues.get(ChronoField.OFFSET_SECONDS);
            if (offsetSecs !is null)
            {
                ZoneOffset offset = ZoneOffset.ofTotalSeconds(offsetSecs.intValue());
                long instant = date.atTime(time).atZone(offset).toEpochSecond();
                fieldValues.put(ChronoField.INSTANT_SECONDS, new Long(instant));
            }
            else
            {
                if (zone !is null)
                {
                    long instant = date.atTime(time).atZone(zone).toEpochSecond();
                    fieldValues.put(ChronoField.INSTANT_SECONDS, new Long(instant));
                }
            }
        }
    }

    private void updateCheckConflict(LocalTime timeToSet, Period periodToSet)
    {
        if (time !is null)
        {
            if ((time == timeToSet) == false)
            {
                throw new DateTimeException(
                        "Conflict found: Fields resolved to different times: "
                        ~ time.toString ~ " " ~ timeToSet.toString);
            }
            if (excessDays.isZero() == false && periodToSet.isZero() == false
                    && (excessDays == periodToSet) == false)
            {
                throw new DateTimeException("Conflict found: Fields resolved to different excess periods: "
                        ~ excessDays.toString ~ " " ~ periodToSet.toString);
            }
            else
            {
                excessDays = periodToSet;
            }
        }
        else
        {
            time = timeToSet;
            excessDays = periodToSet;
        }
    }

    //-----------------------------------------------------------------------
    private void crossCheck()
    {
        // only cross-check date, time and date-time
        // avoid object creation if possible
        if (date !is null)
        {
            crossCheck(date);
        }
        if (time !is null)
        {
            crossCheck(time);
            if (date !is null && fieldValues.size() > 0)
            {
                crossCheck(date.atTime(time));
            }
        }
    }

    private void crossCheck(TemporalAccessor target)
    {
        // for (Iterator!(MapEntry!(TemporalField, Long)) it = fieldValues.entrySet().iterator(); it.hasNext(); ) {
        //     Entry!(TemporalField, Long) entry = it.next();
        //     TemporalField field = entry.getKey();
        //     if (target.isSupported(field)) {
        //         long val1;
        //         try {
        //             val1 = target.getLong(field);
        //         } catch (Exception ex) {
        //             continue;
        //         }
        //         long val2 = entry.getValue();
        //         if (val1 != val2) {
        //             throw new DateTimeException("Conflict found: Field " ~ field.toString ~ " " ~ val1.to!string +
        //                     " differs from " ~ field.toString ~ " " ~ val2.to!string ~ " derived from " ~ target.toString);
        //         }
        //         it.remove();
        //     }
        // }

        foreach (TemporalField k, Long v; fieldValues)
        {

            TemporalField field = k;
            if (target.isSupported(field))
            {
                long val1;
                try
                {
                    val1 = target.getLong(field);
                }
                catch (Exception ex)
                {
                    continue;
                }
                long val2 = v.longValue();
                if (val1 != val2)
                {
                    throw new DateTimeException("Conflict found: Field " ~ field.toString ~ " " ~ val1.to!string
                            ~ " differs from " ~ field.toString ~ " "
                            ~ val2.to!string ~ " derived from " ~ target.toString);
                }
                fieldValues.remove(k);
            }
        }
    }

    //-----------------------------------------------------------------------
    override public string toString()
    {
        StringBuilder buf = new StringBuilder(64);
        buf.append(fieldValues.toString).append(',').append(chrono.toString);
        if (zone !is null)
        {
            buf.append(',').append(zone.toString);
        }
        if (date !is null || time !is null)
        {
            buf.append(" resolved to ");
            if (date !is null)
            {
                buf.append(date.toString);
                if (time !is null)
                {
                    buf.append('T').append(time.toString);
                }
            }
            else
            {
                buf.append(time.toString);
            }
        }
        return buf.toString();
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

}
