
module hunt.time.chrono.AbstractChronology;

import hunt.time.temporal.ChronoField;
import hunt.time.temporal.ChronoUnit;
import hunt.time.temporal.TemporalAdjusters;

import hunt.io.DataInput;
import hunt.io.DataOutput;
import hunt.lang.exception;

//import hunt.io.ObjectInputStream;
// import hunt.io.ObjectStreamException;
import hunt.io.Serializable;
import hunt.time.DateTimeException;
import hunt.time.DayOfWeek;
import hunt.time.format.ResolverStyle;
import hunt.time.temporal.ChronoField;
import hunt.time.temporal.TemporalAdjusters;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.ValueRange;
import hunt.time.util;
import hunt.util.Comparator;
import hunt.container.HashSet;
import hunt.container.List;
import hunt.time.util.Locale;
import hunt.container.Map;

import hunt.time.util.ServiceLoader;
import hunt.container.Set;
import hunt.container.HashMap;
import hunt.time.chrono.Chronology;
import hunt.time.chrono.ChronoLocalDate;
import hunt.lang;
import hunt.time.chrono.IsoChronology;
import hunt.time.chrono.Era;
import std.conv;
import hunt.time.chrono.Ser;

public abstract class AbstractChronology : Chronology {

    /**
     * Map of available calendars by ID.
     */
    // private static final ConcurrentHashMap!(string, Chronology) CHRONOS_BY_ID = new ConcurrentHashMap!(string, Chronology)();
     __gshared HashMap!(string, Chronology) CHRONOS_BY_ID;

    /**
     * Map of available calendars by calendar type.
     */
    //  __gshared ConcurrentHashMap!(string, Chronology) CHRONOS_BY_TYPE = new ConcurrentHashMap!(string, Chronology)();
     __gshared HashMap!(string, Chronology) CHRONOS_BY_TYPE;


    // shared static this()
    // {
    //     CHRONOS_BY_ID = new HashMap!(string, Chronology)();
    //     CHRONOS_BY_TYPE = new HashMap!(string, Chronology)();
    // }
    /**
     * Register a Chronology by its ID and type for lookup by {@link #of(string)}.
     * Chronologies must not be registered until they are completely constructed.
     * Specifically, not _in the constructor of Chronology.
     *
     * @param chrono the chronology to register; not null
     * @return the already registered Chronology if any, may be null
     */
    static Chronology registerChrono(Chronology chrono) {
        return registerChrono(chrono, chrono.getId());
    }

    /**
     * Register a Chronology by ID and type for lookup by {@link #of(string)}.
     * Chronos must not be registered until they are completely constructed.
     * Specifically, not _in the constructor of Chronology.
     *
     * @param chrono the chronology to register; not null
     * @param id the ID to register the chronology; not null
     * @return the already registered Chronology if any, may be null
     */
    static Chronology registerChrono(Chronology chrono, string id) {
        Chronology prev = CHRONOS_BY_ID.putIfAbsent(id, chrono);
        if (prev is null) {
            string type = chrono.getCalendarType();
            if (type !is null) {
                CHRONOS_BY_TYPE.putIfAbsent(type, chrono);
            }
        }
        return prev;
    }

    /**
     * Initialization of the maps from id and type to Chronology.
     * The ServiceLoader is used to find and register any implementations
     * of {@link hunt.time.chrono.AbstractChronology} found _in the bootclass loader.
     * The built-_in chronologies are registered explicitly.
     * Calendars configured via the Thread's context classloader are local
     * to that thread and are ignored.
     * <p>
     * The initialization is done only once using the registration
     * of the IsoChronology as the test and the final step.
     * Multiple threads may perform the initialization concurrently.
     * Only the first registration of each Chronology is retained by the
     * ConcurrentHashMap.
     * @return true if the cache was initialized
     */
    private static bool initCache() {
        if (CHRONOS_BY_ID.get("ISO") is null) {
            // Initialization is incomplete

            // Register built-_in Chronologies
            ///@gxc
            // registerChrono(HijrahChronology.INSTANCE);
            // registerChrono(JapaneseChronology.INSTANCE);
            // registerChrono(MinguoChronology.INSTANCE);
            // registerChrono(ThaiBuddhistChronology.INSTANCE);

            // Register Chronologies from the ServiceLoader
            // @SuppressWarnings("rawtypes")
            ServiceLoader!(AbstractChronology) loader;
            foreach( obj ; loader.objs) {
                AbstractChronology chrono = obj.ctor();
                string id = chrono.getId();
                if (id == ("ISO") || registerChrono(chrono) !is null) {
                    // Log the attempt to replace an existing Chronology
                    // PlatformLogger logger = PlatformLogger.getLogger("hunt.time.chrono");
                    import hunt.logging;
                    version(HUNT_DEBUG) logDebug("Ignoring duplicate Chronology, from ServiceLoader configuration "  ~ id);
                }
            }

            // finally, register IsoChronology to mark initialization is complete
            registerChrono(IsoChronology.INSTANCE);
            return true;
        }
        return false;
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code Chronology} from a locale.
     * !(p)
     * See {@link Chronology#ofLocale(Locale)}.
     *
     * @param locale  the locale to use to obtain the calendar system, not null
     * @return the calendar system associated with the locale, not null
     * @throws hunt.time.DateTimeException if the locale-specified calendar cannot be found
     */
    static Chronology ofLocale(Locale locale) {
        assert(locale, "locale");
        string type = locale.getUnicodeLocaleType("ca");
        if (type is null || "iso" == (type) || "iso8601" == (type)) {
            return IsoChronology.INSTANCE;
        }
        // Not pre-defined; lookup by the type
        do {
            Chronology chrono = CHRONOS_BY_TYPE.get(type);
            if (chrono !is null) {
                return chrono;
            }
            // If not found, do the initialization (once) and repeat the lookup
        } while (initCache());

        // Look for a Chronology using ServiceLoader of the Thread's ContextClassLoader
        // Application provided Chronologies must not be cached
        // @SuppressWarnings("rawtypes")
        ServiceLoader!(AbstractChronology) loader;
        foreach( obj ; loader.objs) {
            Chronology chrono  = obj.ctor();
            if (type == (chrono.getCalendarType())) {
                return chrono;
            }
        }
        throw new DateTimeException("Unknown calendar system: " ~ type);
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code Chronology} from a chronology ID or
     * calendar system type.
     * !(p)
     * See {@link Chronology#of(string)}.
     *
     * @param id  the chronology ID or calendar system type, not null
     * @return the chronology with the identifier requested, not null
     * @throws hunt.time.DateTimeException if the chronology cannot be found
     */
    static Chronology of(string id) {
        assert(id, "id");
        do {
            Chronology chrono = of0(id);
            if (chrono !is null) {
                return chrono;
            }
            // If not found, do the initialization (once) and repeat the lookup
        } while (initCache());

        // Look for a Chronology using ServiceLoader of the Thread's ContextClassLoader
        // Application provided Chronologies must not be cached
        // @SuppressWarnings("rawtypes")
        ServiceLoader!(AbstractChronology) loader;
        foreach(  obj ; loader.objs) {
            Chronology chrono = cast(Chronology)(obj.ctor());
            if (id == (chrono.getId()) || id == (chrono.getCalendarType())) {
                return chrono;
            }
        }
        throw new DateTimeException("Unknown chronology: " ~ id);
    }

    /**
     * Obtains an instance of {@code Chronology} from a chronology ID or
     * calendar system type.
     *
     * @param id  the chronology ID or calendar system type, not null
     * @return the chronology with the identifier requested, or {@code null} if not found
     */
    private static Chronology of0(string id) {
        Chronology chrono = CHRONOS_BY_ID.get(id);
        if (chrono is null) {
            chrono = CHRONOS_BY_TYPE.get(id);
        }
        return chrono;
    }

    /**
     * Returns the available chronologies.
     * !(p)
     * Each returned {@code Chronology} is available for use _in the system.
     * The set of chronologies includes the system chronologies and
     * any chronologies provided by the application via ServiceLoader
     * configuration.
     *
     * @return the independent, modifiable set of the available chronology IDs, not null
     */
    static Set!(Chronology) getAvailableChronologies() {
        initCache();       // force initialization
        HashSet!(Chronology) chronos = new HashSet!(Chronology)();
        foreach( value ;CHRONOS_BY_ID.values())
        {
            chronos.add(value);
        }

        /// Add _in Chronologies from the ServiceLoader configuration
        // @SuppressWarnings("rawtypes")
        ServiceLoader!(AbstractChronology) loader;
        foreach(  obj ; loader.objs) {
            Chronology chrono = obj.ctor();
            chronos.add(chrono);
        }
        return chronos;
    }

    //-----------------------------------------------------------------------
    /**
     * Creates an instance.
     */
    protected this() {
    }

    //-----------------------------------------------------------------------
    /**
     * Resolves parsed {@code ChronoField} values into a date during parsing.
     * <p>
     * Most {@code TemporalField} implementations are resolved using the
     * resolve method on the field. By contrast, the {@code ChronoField} class
     * defines fields that only have meaning relative to the chronology.
     * As such, {@code ChronoField} date fields are resolved here _in the
     * context of a specific chronology.
     * <p>
     * {@code ChronoField} instances are resolved by this method, which may
     * be overridden _in subclasses.
     * <ul>
     * <li>{@code EPOCH_DAY} - If present, this is converted to a date and
     *  all other date fields are then cross-checked against the date.
     * <li>{@code PROLEPTIC_MONTH} - If present, then it is split into the
     *  {@code YEAR} and {@code MONTH_OF_YEAR}. If the mode is strict or smart
     *  then the field is validated.
     * <li>{@code YEAR_OF_ERA} and {@code ERA} - If both are present, then they
     *  are combined to form a {@code YEAR}. In lenient mode, the {@code YEAR_OF_ERA}
     *  range is not validated, _in smart and strict mode it is. The {@code ERA} is
     *  validated for range _in all three modes. If only the {@code YEAR_OF_ERA} is
     *  present, and the mode is smart or lenient, then the last available era
     *  is assumed. In strict mode, no era is assumed and the {@code YEAR_OF_ERA} is
     *  left untouched. If only the {@code ERA} is present, then it is left untouched.
     * <li>{@code YEAR}, {@code MONTH_OF_YEAR} and {@code DAY_OF_MONTH} -
     *  If all three are present, then they are combined to form a date.
     *  In all three modes, the {@code YEAR} is validated.
     *  If the mode is smart or strict, then the month and day are validated.
     *  If the mode is lenient, then the date is combined _in a manner equivalent to
     *  creating a date on the first day of the first month _in the requested year,
     *  then adding the difference _in months, then the difference _in days.
     *  If the mode is smart, and the day-of-month is greater than the maximum for
     *  the year-month, then the day-of-month is adjusted to the last day-of-month.
     *  If the mode is strict, then the three fields must form a valid date.
     * <li>{@code YEAR} and {@code DAY_OF_YEAR} -
     *  If both are present, then they are combined to form a date.
     *  In all three modes, the {@code YEAR} is validated.
     *  If the mode is lenient, then the date is combined _in a manner equivalent to
     *  creating a date on the first day of the requested year, then adding
     *  the difference _in days.
     *  If the mode is smart or strict, then the two fields must form a valid date.
     * <li>{@code YEAR}, {@code MONTH_OF_YEAR}, {@code ALIGNED_WEEK_OF_MONTH} and
     *  {@code ALIGNED_DAY_OF_WEEK_IN_MONTH} -
     *  If all four are present, then they are combined to form a date.
     *  In all three modes, the {@code YEAR} is validated.
     *  If the mode is lenient, then the date is combined _in a manner equivalent to
     *  creating a date on the first day of the first month _in the requested year, then adding
     *  the difference _in months, then the difference _in weeks, then _in days.
     *  If the mode is smart or strict, then the all four fields are validated to
     *  their outer ranges. The date is then combined _in a manner equivalent to
     *  creating a date on the first day of the requested year and month, then adding
     *  the amount _in weeks and days to reach their values. If the mode is strict,
     *  the date is additionally validated to check that the day and week adjustment
     *  did not change the month.
     * <li>{@code YEAR}, {@code MONTH_OF_YEAR}, {@code ALIGNED_WEEK_OF_MONTH} and
     *  {@code DAY_OF_WEEK} - If all four are present, then they are combined to
     *  form a date. The approach is the same as described above for
     *  years, months and weeks _in {@code ALIGNED_DAY_OF_WEEK_IN_MONTH}.
     *  The day-of-week is adjusted as the next or same matching day-of-week once
     *  the years, months and weeks have been handled.
     * <li>{@code YEAR}, {@code ALIGNED_WEEK_OF_YEAR} and {@code ALIGNED_DAY_OF_WEEK_IN_YEAR} -
     *  If all three are present, then they are combined to form a date.
     *  In all three modes, the {@code YEAR} is validated.
     *  If the mode is lenient, then the date is combined _in a manner equivalent to
     *  creating a date on the first day of the requested year, then adding
     *  the difference _in weeks, then _in days.
     *  If the mode is smart or strict, then the all three fields are validated to
     *  their outer ranges. The date is then combined _in a manner equivalent to
     *  creating a date on the first day of the requested year, then adding
     *  the amount _in weeks and days to reach their values. If the mode is strict,
     *  the date is additionally validated to check that the day and week adjustment
     *  did not change the year.
     * <li>{@code YEAR}, {@code ALIGNED_WEEK_OF_YEAR} and {@code DAY_OF_WEEK} -
     *  If all three are present, then they are combined to form a date.
     *  The approach is the same as described above for years and weeks _in
     *  {@code ALIGNED_DAY_OF_WEEK_IN_YEAR}. The day-of-week is adjusted as the
     *  next or same matching day-of-week once the years and weeks have been handled.
     * </ul>
     * <p>
     * The default implementation is suitable for most calendar systems.
     * If {@link hunt.time.temporal.ChronoField#YEAR_OF_ERA} is found without an {@link hunt.time.temporal.ChronoField#ERA}
     * then the last era _in {@link #eras()} is used.
     * The implementation assumes a 7 day week, that the first day-of-month
     * has the value 1, that first day-of-year has the value 1, and that the
     * first of the month and year always exists.
     *
     * @param fieldValues  the map of fields to values, which can be updated, not null
     * @param resolverStyle  the requested type of resolve, not null
     * @return the resolved date, null if insufficient information to create a date
     * @throws hunt.time.DateTimeException if the date cannot be resolved, typically
     *  because of a conflict _in the input data
     */
    override
    public ChronoLocalDate resolveDate(Map!(TemporalField, Long) fieldValues, ResolverStyle resolverStyle) {
        // check epoch-day before inventing era
        if (fieldValues.containsKey(ChronoField.EPOCH_DAY)) {
            return dateEpochDay(fieldValues.remove(ChronoField.EPOCH_DAY).longValue());
        }

        // fix proleptic month before inventing era
        resolveProlepticMonth(fieldValues, resolverStyle);

        // invent era if necessary to resolve year-of-era
        ChronoLocalDate resolved = resolveYearOfEra(fieldValues, resolverStyle);
        if (resolved !is null) {
            return resolved;
        }

        // build date
        if (fieldValues.containsKey(ChronoField.YEAR)) {
            if (fieldValues.containsKey(ChronoField.MONTH_OF_YEAR)) {
                if (fieldValues.containsKey(ChronoField.DAY_OF_MONTH)) {
                    return resolveYMD(fieldValues, resolverStyle);
                }
                if (fieldValues.containsKey(ChronoField.ALIGNED_WEEK_OF_MONTH)) {
                    if (fieldValues.containsKey(ChronoField.ALIGNED_DAY_OF_WEEK_IN_MONTH)) {
                        return resolveYMAA(fieldValues, resolverStyle);
                    }
                    if (fieldValues.containsKey(ChronoField.DAY_OF_WEEK)) {
                        return resolveYMAD(fieldValues, resolverStyle);
                    }
                }
            }
            if (fieldValues.containsKey(ChronoField.DAY_OF_YEAR)) {
                return resolveYD(fieldValues, resolverStyle);
            }
            if (fieldValues.containsKey(ChronoField.ALIGNED_WEEK_OF_YEAR)) {
                if (fieldValues.containsKey(ChronoField.ALIGNED_DAY_OF_WEEK_IN_YEAR)) {
                    return resolveYAA(fieldValues, resolverStyle);
                }
                if (fieldValues.containsKey(ChronoField.DAY_OF_WEEK)) {
                    return resolveYAD(fieldValues, resolverStyle);
                }
            }
        }
        return null;
    }

    void resolveProlepticMonth(Map!(TemporalField, Long) fieldValues, ResolverStyle resolverStyle) {
        Long pMonth = fieldValues.remove(ChronoField.PROLEPTIC_MONTH);
        if (pMonth !is null) {
            if (resolverStyle != ResolverStyle.LENIENT) {
                ChronoField.PROLEPTIC_MONTH.checkValidValue(pMonth.longValue());
            }
            // first day-of-month is likely to be safest for setting proleptic-month
            // cannot add to year zero, as not all chronologies have a year zero
            ChronoLocalDate chronoDate = dateNow()
                    ._with(ChronoField.DAY_OF_MONTH, 1)._with(ChronoField.PROLEPTIC_MONTH, pMonth.longValue());
            addFieldValue(fieldValues, ChronoField.MONTH_OF_YEAR, chronoDate.get(ChronoField.MONTH_OF_YEAR));
            addFieldValue(fieldValues, ChronoField.YEAR, chronoDate.get(ChronoField.YEAR));
        }
    }

    ChronoLocalDate resolveYearOfEra(Map!(TemporalField, Long) fieldValues, ResolverStyle resolverStyle) {
        Long yoeLong = fieldValues.remove(ChronoField.YEAR_OF_ERA);
        if (yoeLong !is null) {
            Long eraLong = fieldValues.remove(ChronoField.ERA);
            int yoe;
            if (resolverStyle != ResolverStyle.LENIENT) {
                yoe = range(ChronoField.YEAR_OF_ERA).checkValidIntValue(yoeLong.longValue(), ChronoField.YEAR_OF_ERA);
            } else {
                yoe = Math.toIntExact(yoeLong.longValue());
            }
            if (eraLong !is null) {
                Era eraObj = eraOf(range(ChronoField.ERA).checkValidIntValue(eraLong.longValue(), ChronoField.ERA));
                addFieldValue(fieldValues, ChronoField.YEAR, prolepticYear(eraObj, yoe));
            } else {
                if (fieldValues.containsKey(ChronoField.YEAR)) {
                    int year = range(ChronoField.YEAR).checkValidIntValue(fieldValues.get(ChronoField.YEAR).longValue(), ChronoField.YEAR);
                    ChronoLocalDate chronoDate = dateYearDay(year, 1);
                    addFieldValue(fieldValues, ChronoField.YEAR, prolepticYear(chronoDate.getEra(), yoe));
                } else if (resolverStyle == ResolverStyle.STRICT) {
                    // do not invent era if strict
                    // reinstate the field removed earlier, no cross-check issues
                    fieldValues.put(ChronoField.YEAR_OF_ERA, yoeLong);
                } else {
                    List!(Era) eras = eras();
                    if (eras.isEmpty()) {
                        addFieldValue(fieldValues, ChronoField.YEAR, yoe);
                    } else {
                        Era eraObj = eras.get(eras.size() - 1);
                        addFieldValue(fieldValues, ChronoField.YEAR, prolepticYear(eraObj, yoe));
                    }
                }
            }
        } else if (fieldValues.containsKey(ChronoField.ERA)) {
            range(ChronoField.ERA).checkValidValue(fieldValues.get(ChronoField.ERA).longValue(), ChronoField.ERA);  // always validated
        }
        return null;
    }

    ChronoLocalDate resolveYMD(Map!(TemporalField, Long) fieldValues, ResolverStyle resolverStyle) {
        int y = range(ChronoField.YEAR).checkValidIntValue(fieldValues.remove(ChronoField.YEAR).longValue(), ChronoField.YEAR);
        if (resolverStyle == ResolverStyle.LENIENT) {
            long months = Math.subtractExact(fieldValues.remove(ChronoField.MONTH_OF_YEAR).longValue(), 1);
            long days = Math.subtractExact(fieldValues.remove(ChronoField.DAY_OF_MONTH).longValue(), 1);
            return date(y, 1, 1).plus(months, ChronoUnit.MONTHS).plus(days, ChronoUnit.DAYS);
        }
        int moy = range(ChronoField.MONTH_OF_YEAR).checkValidIntValue(fieldValues.remove(ChronoField.MONTH_OF_YEAR).longValue(), ChronoField.MONTH_OF_YEAR);
        ValueRange domRange = range(ChronoField.DAY_OF_MONTH);
        int dom = domRange.checkValidIntValue(fieldValues.remove(ChronoField.DAY_OF_MONTH).longValue(), ChronoField.DAY_OF_MONTH);
        if (resolverStyle == ResolverStyle.SMART) {  // previous valid
            try {
                return date(y, moy, dom);
            } catch (DateTimeException ex) {
                return date(y, moy, 1)._with(TemporalAdjusters.lastDayOfMonth());
            }
        }
        return date(y, moy, dom);
    }

    ChronoLocalDate resolveYD(Map!(TemporalField, Long) fieldValues, ResolverStyle resolverStyle) {
        int y = range(ChronoField.YEAR).checkValidIntValue(fieldValues.remove(ChronoField.YEAR).longValue(), ChronoField.YEAR);
        if (resolverStyle == ResolverStyle.LENIENT) {
            long days = Math.subtractExact(fieldValues.remove(ChronoField.DAY_OF_YEAR).longValue(), 1);
            return dateYearDay(y, 1).plus(days, ChronoUnit.DAYS);
        }
        int doy = range(ChronoField.DAY_OF_YEAR).checkValidIntValue(fieldValues.remove(ChronoField.DAY_OF_YEAR).longValue(), ChronoField.DAY_OF_YEAR);
        return dateYearDay(y, doy);  // smart is same as strict
    }

    ChronoLocalDate resolveYMAA(Map!(TemporalField, Long) fieldValues, ResolverStyle resolverStyle) {
        int y = range(ChronoField.YEAR).checkValidIntValue(fieldValues.remove(ChronoField.YEAR).longValue(), ChronoField.YEAR);
        if (resolverStyle == ResolverStyle.LENIENT) {
            long months = Math.subtractExact(fieldValues.remove(ChronoField.MONTH_OF_YEAR).longValue(), 1);
            long weeks = Math.subtractExact(fieldValues.remove(ChronoField.ALIGNED_WEEK_OF_MONTH).longValue(), 1);
            long days = Math.subtractExact(fieldValues.remove(ChronoField.ALIGNED_DAY_OF_WEEK_IN_MONTH).longValue(), 1);
            return date(y, 1, 1).plus(months, ChronoUnit.MONTHS).plus(weeks, ChronoUnit.WEEKS).plus(days, ChronoUnit.DAYS);
        }
        int moy = range(ChronoField.MONTH_OF_YEAR).checkValidIntValue(fieldValues.remove(ChronoField.MONTH_OF_YEAR).longValue(), ChronoField.MONTH_OF_YEAR);
        int aw = range(ChronoField.ALIGNED_WEEK_OF_MONTH).checkValidIntValue(fieldValues.remove(ChronoField.ALIGNED_WEEK_OF_MONTH).longValue(), ChronoField.ALIGNED_WEEK_OF_MONTH);
        int ad = range(ChronoField.ALIGNED_DAY_OF_WEEK_IN_MONTH).checkValidIntValue(fieldValues.remove(ChronoField.ALIGNED_DAY_OF_WEEK_IN_MONTH).longValue(), ChronoField.ALIGNED_DAY_OF_WEEK_IN_MONTH);
        ChronoLocalDate date = date(y, moy, 1).plus((aw - 1) * 7 + (ad - 1), ChronoUnit.DAYS);
        if (resolverStyle == ResolverStyle.STRICT && date.get(ChronoField.MONTH_OF_YEAR) != moy) {
            throw new DateTimeException("Strict mode rejected resolved date as it is _in a different month");
        }
        return date;
    }

    ChronoLocalDate resolveYMAD(Map!(TemporalField, Long) fieldValues, ResolverStyle resolverStyle) {
        int y = range(ChronoField.YEAR).checkValidIntValue(fieldValues.remove(ChronoField.YEAR).longValue(), ChronoField.YEAR);
        if (resolverStyle == ResolverStyle.LENIENT) {
            long months = Math.subtractExact(fieldValues.remove(ChronoField.MONTH_OF_YEAR).longValue(), 1);
            long weeks = Math.subtractExact(fieldValues.remove(ChronoField.ALIGNED_WEEK_OF_MONTH).longValue(), 1);
            long dow = Math.subtractExact(fieldValues.remove(ChronoField.DAY_OF_WEEK).longValue(), 1);
            return resolveAligned(date(y, 1, 1), months, weeks, dow);
        }
        int moy = range(ChronoField.MONTH_OF_YEAR).checkValidIntValue(fieldValues.remove(ChronoField.MONTH_OF_YEAR).longValue(), ChronoField.MONTH_OF_YEAR);
        int aw = range(ChronoField.ALIGNED_WEEK_OF_MONTH).checkValidIntValue(fieldValues.remove(ChronoField.ALIGNED_WEEK_OF_MONTH).longValue(), ChronoField.ALIGNED_WEEK_OF_MONTH);
        int dow = range(ChronoField.DAY_OF_WEEK).checkValidIntValue(fieldValues.remove(ChronoField.DAY_OF_WEEK).longValue(), ChronoField.DAY_OF_WEEK);
        ChronoLocalDate date = date(y, moy, 1).plus((aw - 1) * 7, ChronoUnit.DAYS)._with(TemporalAdjusters.nextOrSame(DayOfWeek.of(dow)));
        if (resolverStyle == ResolverStyle.STRICT && date.get(ChronoField.MONTH_OF_YEAR) != moy) {
            throw new DateTimeException("Strict mode rejected resolved date as it is _in a different month");
        }
        return date;
    }

    ChronoLocalDate resolveYAA(Map!(TemporalField, Long) fieldValues, ResolverStyle resolverStyle) {
        int y = range(ChronoField.YEAR).checkValidIntValue(fieldValues.remove(ChronoField.YEAR).longValue(), ChronoField.YEAR);
        if (resolverStyle == ResolverStyle.LENIENT) {
            long weeks = Math.subtractExact(fieldValues.remove(ChronoField.ALIGNED_WEEK_OF_YEAR).longValue(), 1);
            long days = Math.subtractExact(fieldValues.remove(ChronoField.ALIGNED_DAY_OF_WEEK_IN_YEAR).longValue(), 1);
            return dateYearDay(y, 1).plus(weeks, ChronoUnit.WEEKS).plus(days, ChronoUnit.DAYS);
        }
        int aw = range(ChronoField.ALIGNED_WEEK_OF_YEAR).checkValidIntValue(fieldValues.remove(ChronoField.ALIGNED_WEEK_OF_YEAR).longValue(), ChronoField.ALIGNED_WEEK_OF_YEAR);
        int ad = range(ChronoField.ALIGNED_DAY_OF_WEEK_IN_YEAR).checkValidIntValue(fieldValues.remove(ChronoField.ALIGNED_DAY_OF_WEEK_IN_YEAR).longValue(), ChronoField.ALIGNED_DAY_OF_WEEK_IN_YEAR);
        ChronoLocalDate date = dateYearDay(y, 1).plus((aw - 1) * 7 + (ad - 1), ChronoUnit.DAYS);
        if (resolverStyle == ResolverStyle.STRICT && date.get(ChronoField.YEAR) != y) {
            throw new DateTimeException("Strict mode rejected resolved date as it is _in a different year");
        }
        return date;
    }

    ChronoLocalDate resolveYAD(Map!(TemporalField, Long) fieldValues, ResolverStyle resolverStyle) {
        int y = range(ChronoField.YEAR).checkValidIntValue(fieldValues.remove(ChronoField.YEAR).longValue(), ChronoField.YEAR);
        if (resolverStyle == ResolverStyle.LENIENT) {
            long weeks = Math.subtractExact(fieldValues.remove(ChronoField.ALIGNED_WEEK_OF_YEAR).longValue(), 1);
            long dow = Math.subtractExact(fieldValues.remove(ChronoField.DAY_OF_WEEK).longValue(), 1);
            return resolveAligned(dateYearDay(y, 1), 0, weeks, dow);
        }
        int aw = range(ChronoField.ALIGNED_WEEK_OF_YEAR).checkValidIntValue(fieldValues.remove(ChronoField.ALIGNED_WEEK_OF_YEAR).longValue(), ChronoField.ALIGNED_WEEK_OF_YEAR);
        int dow = range(ChronoField.DAY_OF_WEEK).checkValidIntValue(fieldValues.remove(ChronoField.DAY_OF_WEEK).longValue(), ChronoField.DAY_OF_WEEK);
        ChronoLocalDate date = dateYearDay(y, 1).plus((aw - 1) * 7, ChronoUnit.DAYS)._with(TemporalAdjusters.nextOrSame(DayOfWeek.of(dow)));
        if (resolverStyle == ResolverStyle.STRICT && date.get(ChronoField.YEAR) != y) {
            throw new DateTimeException("Strict mode rejected resolved date as it is _in a different year");
        }
        return date;
    }

    ChronoLocalDate resolveAligned(ChronoLocalDate base, long months, long weeks, long dow) {
        ChronoLocalDate date = base.plus(months, ChronoUnit.MONTHS).plus(weeks, ChronoUnit.WEEKS);
        if (dow > 7) {
            date = date.plus((dow - 1) / 7, ChronoUnit.WEEKS);
            dow = ((dow - 1) % 7) + 1;
        } else if (dow < 1) {
            date = date.plus(Math.subtractExact(dow,  7) / 7, ChronoUnit.WEEKS);
            dow = ((dow + 6) % 7) + 1;
        }
        return date._with(TemporalAdjusters.nextOrSame(DayOfWeek.of(cast(int) dow)));
    }

    /**
     * Adds a field-value pair to the map, checking for conflicts.
     * !(p)
     * If the field is not already present, then the field-value pair is added to the map.
     * If the field is already present and it has the same value as that specified, no action occurs.
     * If the field is already present and it has a different value to that specified, then
     * an exception is thrown.
     *
     * @param field  the field to add, not null
     * @param value  the value to add, not null
     * @throws hunt.time.DateTimeException if the field is already present with a different value
     */
    void addFieldValue(Map!(TemporalField, Long) fieldValues, ChronoField field, long value) {
        Long old = fieldValues.get(field);  // check first for better error message
        if (old !is null && old.longValue() != value) {
            throw new DateTimeException("Conflict found: " ~ typeid(field).name ~ " " ~ old.to!string ~ " differs from " ~ typeid(field).name ~ " " ~ value.to!string);
        }
        fieldValues.put(field, new Long(value));
    }

    //-----------------------------------------------------------------------
    /**
     * Compares this chronology to another chronology.
     * !(p)
     * The comparison order first by the chronology ID string, then by any
     * additional information specific to the subclass.
     * It is "consistent with equals", as defined by {@link Comparable}.
     *
     * @implSpec
     * This implementation compares the chronology ID.
     * Subclasses must compare any additional state that they store.
     *
     * @param other  the other chronology to compare to, not null
     * @return the comparator value, negative if less, positive if greater
     */
    override
    public int compareTo(Chronology other) {
        return getId().compare(other.getId());
    }

    /**
     * Checks if this chronology is equal to another chronology.
     * <p>
     * The comparison is based on the entire state of the object.
     *
     * @implSpec
     * This implementation checks the type and calls
     * {@link #compareTo(hunt.time.chrono.Chronology)}.
     *
     * @param obj  the object to check, null returns false
     * @return true if this is equal to the other chronology
     */
    override
    public bool opEquals(Object obj) {
        if (this is obj) {
           return true;
        }
        if (cast(AbstractChronology)(obj) !is null) {
            return compareTo(cast(AbstractChronology) obj) == 0;
        }
        return false;
    }
    

    /**
     * A hash code for this chronology.
     * <p>
     * The hash code should be based on the entire state of the object.
     *
     * @implSpec
     * This implementation is based on the chronology ID and class.
     * Subclasses should add any additional state that they store.
     *
     * @return a suitable hash code
     */
    override
    public size_t toHash() @trusted nothrow {
        try
        {   
            return hashOf(typeid(this).name) ^ hashOf(getId());
        }
        catch(Exception e){}
        return int.init;
    }

    //-----------------------------------------------------------------------
    /**
     * Outputs this chronology as a {@code string}, using the chronology ID.
     *
     * @return a string representation of this chronology, not null
     */
    override
    public string toString() {
        return getId();
    }

    //-----------------------------------------------------------------------
    /**
     * Writes the Chronology using a
     * <a href="{@docRoot}/serialized-form.html#hunt.time.chrono.Ser">dedicated serialized form</a>.
     * <pre>
     *  _out.writeByte(1);  // identifies this as a Chronology
     *  _out.writeUTF(getId());
     * </pre>
     *
     * @return the instance of {@code Ser}, not null
     */
    Object writeReplace() {
        return new Ser(Ser.CHRONO_TYPE, this);
    }

    /**
     * Defend against malicious streams.
     *
     * @param s the stream to read
     * @throws java.io.InvalidObjectException always
     */
     ///@gxc
    // private void readObject(ObjectInputStream s) /*throws ObjectStreamException*/ {
    //     throw new InvalidObjectException("Deserialization via serialization delegate");
    // }

    void writeExternal(DataOutput _out) /*throws IOException*/ {
        _out.writeUTF(getId());
    }

    static Chronology readExternal(DataInput _in) /*throws IOException*/ {
        string id = _in.readUTF();
        return Chronology.of(id);
    }

}
