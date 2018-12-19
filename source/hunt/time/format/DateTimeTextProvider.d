
module hunt.time.format.DateTimeTextProvider;

import hunt.time.temporal.ChronoField;

import hunt.time.chrono.Chronology;
import hunt.time.chrono.IsoChronology;
import hunt.time.chrono.JapaneseChronology;
import hunt.time.temporal.IsoFields;
import hunt.time.temporal.TemporalField;
// import hunt.util.AbstractMap.SimpleImmutableEntry;
import hunt.container.ArrayList;
import hunt.time.util.Calendar;
import hunt.container.Collections;
import hunt.util.Comparator;
// import hunt.container.Iterator;
import hunt.container.List;
import hunt.time.util.Locale;
// import hunt.util.Map.MapEntry;
// import hunt.util.ResourceBundle;
import hunt.container;
import hunt.time.format.TextStyle;
import hunt.lang;
// import hunt.concurrent.ConcurrentMap;
import hunt.lang.exception;
import hunt.time.util.common;
// import sun.util.locale.provider.CalendarDataUtility;
// import sun.util.locale.provider.LocaleProviderAdapter;
// import sun.util.locale.provider.LocaleResources;

/**
 * A provider to obtain the textual form of a date-time field.
 *
 * @implSpec
 * Implementations must be thread-safe.
 * Implementations should cache the textual information.
 *
 * @since 1.8
 */
class DateTimeTextProvider {

    /** Cache. */
    // private static final ConcurrentMap!(MapEntry!(TemporalField, Locale), Object) CACHE = new ConcurrentHashMap!()(16, 0.75f, 2);
    //__gshared Map!(MapEntry!(TemporalField, Locale), Object) CACHE;

    /** Comparator. */
    //__gshared Comparator!(MapEntry!(string, Long)) COMPARATOR;

    // Singleton instance
    //__gshared DateTimeTextProvider INSTANCE;

    // shared static this()
    // {
        // CACHE = new HashMap!(MapEntry!(TemporalField, Locale), Object)(16, 0.75f/* , 2 */);
        // COMPARATOR = new class Comparator!(MapEntry!(string, Long)){
        // override
        // public int compare(MapEntry!(string, Long) obj1, MapEntry!(string, Long) obj2) {
        //     return cast(int)(obj2.getKey().length - obj1.getKey().length);  // longest to shortest
        // }
        // };

        mixin(MakeGlobalVar!(Comparator!(MapEntry!(string, Long)))("COMPARATOR",`new class Comparator!(MapEntry!(string, Long)){
        override
        public int compare(MapEntry!(string, Long) obj1, MapEntry!(string, Long) obj2) {
            return cast(int)(obj2.getKey().length - obj1.getKey().length);  // longest to shortest
        }
        }`));

        // INSTANCE = new DateTimeTextProvider();
        mixin(MakeGlobalVar!(DateTimeTextProvider)("INSTANCE",`new DateTimeTextProvider()`));
    // }

    this() {}

    /**
     * Gets the provider of text.
     *
     * @return the provider, not null
     */
    static DateTimeTextProvider getInstance() {
        return INSTANCE;
    }

    /**
     * Gets the text for the specified field, locale and style
     * for the purpose of formatting.
     * !(p)
     * The text associated with the value is returned.
     * The null return value should be used if there is no applicable text, or
     * if the text would be a numeric representation of the value.
     *
     * @param field  the field to get text for, not null
     * @param value  the field value to get text for, not null
     * @param style  the style to get text for, not null
     * @param locale  the locale to get text for, not null
     * @return the text for the field value, null if no text found
     */
    public string getText(TemporalField field, long value, TextStyle style, Locale locale) {
        Object store = findStore(field, locale);
        if (cast(LocaleStore)(store) !is null) {
            return (cast(LocaleStore) store).getText(value, style);
        }
        return null;
    }

    /**
     * Gets the text for the specified chrono, field, locale and style
     * for the purpose of formatting.
     * !(p)
     * The text associated with the value is returned.
     * The null return value should be used if there is no applicable text, or
     * if the text would be a numeric representation of the value.
     *
     * @param chrono  the Chronology to get text for, not null
     * @param field  the field to get text for, not null
     * @param value  the field value to get text for, not null
     * @param style  the style to get text for, not null
     * @param locale  the locale to get text for, not null
     * @return the text for the field value, null if no text found
     */
    public string getText(Chronology chrono, TemporalField field, long value,
                                    TextStyle style, Locale locale) {
        if (chrono == IsoChronology.INSTANCE
                || !(cast(ChronoField)(field) !is null)) {
            return getText(field, value, style, locale);
        }

        int fieldIndex;
        int fieldValue;
        if (field == ChronoField.ERA) {
            fieldIndex = Calendar.ERA;
            ///@gxc
            /* if (chrono == JapaneseChronology.INSTANCE) {
                if (value == -999) {
                    fieldValue = 0;
                } else {
                    fieldValue = cast(int) value + 2;
                }
            } else */ {
                fieldValue = cast(int) value;
            }
        } else if (field == ChronoField.MONTH_OF_YEAR) {
            fieldIndex = Calendar.MONTH;
            fieldValue = cast(int) value - 1;
        } else if (field == ChronoField.DAY_OF_WEEK) {
            fieldIndex = Calendar.DAY_OF_WEEK;
            fieldValue = cast(int) value + 1;
            if (fieldValue > 7) {
                fieldValue = Calendar.SUNDAY;
            }
        } else if (field == ChronoField.AMPM_OF_DAY) {
            fieldIndex = Calendar.AM_PM;
            fieldValue = cast(int) value;
        } else {
            return null;
        }
        // return CalendarDataUtility.retrieveJavaTimeFieldValueName(
        //         chrono.getCalendarType(), fieldIndex, fieldValue, style.toCalendarStyle(), locale); ///@gxc
        return null;
    }

    /**
     * Gets an iterator of text to field for the specified field, locale and style
     * for the purpose of parsing.
     * !(p)
     * The iterator must be returned _in order from the longest text to the shortest.
     * !(p)
     * The null return value should be used if there is no applicable parsable text, or
     * if the text would be a numeric representation of the value.
     * Text can only be parsed if all the values for that field-style-locale combination are unique.
     *
     * @param field  the field to get text for, not null
     * @param style  the style to get text for, null for all parsable text
     * @param locale  the locale to get text for, not null
     * @return the iterator of text to field pairs, _in order from longest text to shortest text,
     *  null if the field or style is not parsable
     */
    public Iterator!(MapEntry!(string, Long)) getTextIterator(TemporalField field, TextStyle style, Locale locale) {
        Object store = findStore(field, locale);
        if (cast(LocaleStore)(store) !is null) {
            return (cast(LocaleStore) store).getTextIterator(style);
        }
        return null;
    }

    /**
     * Gets an iterator of text to field for the specified chrono, field, locale and style
     * for the purpose of parsing.
     * !(p)
     * The iterator must be returned _in order from the longest text to the shortest.
     * !(p)
     * The null return value should be used if there is no applicable parsable text, or
     * if the text would be a numeric representation of the value.
     * Text can only be parsed if all the values for that field-style-locale combination are unique.
     *
     * @param chrono  the Chronology to get text for, not null
     * @param field  the field to get text for, not null
     * @param style  the style to get text for, null for all parsable text
     * @param locale  the locale to get text for, not null
     * @return the iterator of text to field pairs, _in order from longest text to shortest text,
     *  null if the field or style is not parsable
     */
    public Iterator!(MapEntry!(string, Long)) getTextIterator(Chronology chrono, TemporalField field,
                                                         TextStyle style, Locale locale) {
        if (chrono == IsoChronology.INSTANCE
                || !(cast(ChronoField)(field) !is null)) {
            return getTextIterator(field, style, locale);
        }

        int fieldIndex;
        auto f = cast(ChronoField)field;
        {
        if( f == ChronoField.ERA)
        {
            fieldIndex = Calendar.ERA;
        }
            
        if( f == ChronoField.MONTH_OF_YEAR)
        {
            fieldIndex = Calendar.MONTH;
        }
            
        if( f == ChronoField.DAY_OF_WEEK)
        {
            fieldIndex = Calendar.DAY_OF_WEEK;
        }
            
        if( f == ChronoField.AMPM_OF_DAY)
        {
            fieldIndex = Calendar.AM_PM;
        }
        }

        int calendarStyle = (style is null) ? Calendar.ALL_STYLES : style.toCalendarStyle();
        Map!(string, Integer) map = null/* CalendarDataUtility.retrieveJavaTimeFieldValueNames( ///@gxc
                chrono.getCalendarType(), fieldIndex, calendarStyle, locale) */;
        if (map is null) {
            return null;
        }
        // List!(MapEntry!(string, Long)) list = new ArrayList!(MapEntry!(string, Long))(map.size());
        // switch (fieldIndex) {
        // case Calendar.ERA:
        //     foreach(string k , Integer v ; map) {
        //         int era = v.intValue();
        //         if (chrono == JapaneseChronology.INSTANCE) {
        //             if (era == 0) {
        //                 era = -999;
        //             } else {
        //                 era -= 2;
        //             }
        //         }
        //         list.add(createEntry(k, cast(long)era));
        //     }
        //     break;
        // case Calendar.MONTH:
        //     foreach(string k , Integer v ; map) {
        //         list.add(createEntry(k, cast(long)(v.intValue() + 1)));
        //     }
        //     break;
        // case Calendar.DAY_OF_WEEK:
        //     foreach(string k , Integer v ; map) {
        //         list.add(createEntry(k, cast(long)toWeekDay(v.intValue)));
        //     }
        //     break;
        // default:
        //     foreach(string k , Integer v ; map) {
        //         list.add(createEntry(k, cast(long)v.intValue));
        //     }
        //     break;
        // }
        // return list.iterator();
        return null;
    }

    private Object findStore(TemporalField field, Locale locale) {
        // MapEntry!(TemporalField, Locale) key = createEntry(field, locale);
        // Object store = CACHE.get(key);
        // if (store is null) {
        //     store = createStore(field, locale);
        //     CACHE.putIfAbsent(key, store);
        //     store = CACHE.get(key);
        // }
        // return store;
        return null;
    }

    private static int toWeekDay(int calWeekDay) {
        if (calWeekDay == Calendar.SUNDAY) {
            return 7;
        } else {
            return calWeekDay - 1;
        }
    }

    private Object createStore(TemporalField field, Locale locale) {
        // Map!(TextStyle, Map!(Long, string)) styleMap = new HashMap!(TextStyle, Map!(Long, string))();
        // if (field == ChronoField.ERA) {
        //     foreach(TextStyle textStyle ; TextStyle.values()) {
        //         if (textStyle.isStandalone()) {
        //             // Stand-alone isn't applicable to era names.
        //             continue;
        //         }
        //         Map!(string, Integer) displayNames = CalendarDataUtility.retrieveJavaTimeFieldValueNames(
        //                 "gregory", Calendar.ERA, textStyle.toCalendarStyle(), locale);
        //         if (displayNames !is null) {
        //             Map!(Long, string) map = new HashMap!()();
        //             foreach(MapEntry!(string, Integer) entry ; displayNames.entrySet()) {
        //                 map.put(cast(long) entry.getValue(), entry.getKey());
        //             }
        //             if (!map.isEmpty()) {
        //                 styleMap.put(textStyle, map);
        //             }
        //         }
        //     }
        //     return new LocaleStore(styleMap);
        // }

        // if (field == ChronoField.MONTH_OF_YEAR) {
        //     foreach(TextStyle textStyle ; TextStyle.values()) {
        //         Map!(Long, string) map = new HashMap!()();
        //         // Narrow names may have duplicated names, such as "J" for January, June, July.
        //         // Get names one by one _in that case.
        //         if ((textStyle.equals(TextStyle.NARROW) ||
        //                 textStyle.equals(TextStyle.NARROW_STANDALONE))) {
        //             for (int month = Calendar.JANUARY; month <= Calendar.DECEMBER; month++) {
        //                 string name;
        //                 name = CalendarDataUtility.retrieveJavaTimeFieldValueName(
        //                         "gregory", Calendar.MONTH,
        //                         month, textStyle.toCalendarStyle(), locale);
        //                 if (name is null) {
        //                     break;
        //                 }
        //                 map.put((month + 1L), name);
        //             }
        //         } else {
        //             Map!(string, Integer) displayNames = CalendarDataUtility.retrieveJavaTimeFieldValueNames(
        //                     "gregory", Calendar.MONTH, textStyle.toCalendarStyle(), locale);
        //             if (displayNames !is null) {
        //                 foreach(MapEntry!(string, Integer) entry ; displayNames.entrySet()) {
        //                     map.put(cast(long)(entry.getValue() + 1), entry.getKey());
        //                 }
        //             } else {
        //                 // Although probability is very less, but if other styles have duplicate names.
        //                 // Get names one by one _in that case.
        //                 for (int month = Calendar.JANUARY; month <= Calendar.DECEMBER; month++) {
        //                     string name;
        //                     name = CalendarDataUtility.retrieveJavaTimeFieldValueName(
        //                             "gregory", Calendar.MONTH, month, textStyle.toCalendarStyle(), locale);
        //                     if (name is null) {
        //                         break;
        //                     }
        //                     map.put((month + 1L), name);
        //                 }
        //             }
        //         }
        //         if (!map.isEmpty()) {
        //             styleMap.put(textStyle, map);
        //         }
        //     }
        //     return new LocaleStore(styleMap);
        // }

        // if (field == ChronoField.DAY_OF_WEEK) {
        //     foreach(TextStyle textStyle ; TextStyle.values()) {
        //         Map!(Long, string) map = new HashMap!()();
        //         // Narrow names may have duplicated names, such as "S" for Sunday and Saturday.
        //         // Get names one by one _in that case.
        //         if ((textStyle.equals(TextStyle.NARROW) ||
        //                 textStyle.equals(TextStyle.NARROW_STANDALONE))) {
        //             for (int wday = Calendar.SUNDAY; wday <= Calendar.SATURDAY; wday++) {
        //                 string name;
        //                 name = CalendarDataUtility.retrieveJavaTimeFieldValueName(
        //                         "gregory", Calendar.DAY_OF_WEEK,
        //                         wday, textStyle.toCalendarStyle(), locale);
        //                 if (name is null) {
        //                     break;
        //                 }
        //                 map.put(cast(long)toWeekDay(wday), name);
        //             }
        //         } else {
        //             Map!(string, Integer) displayNames = CalendarDataUtility.retrieveJavaTimeFieldValueNames(
        //                     "gregory", Calendar.DAY_OF_WEEK, textStyle.toCalendarStyle(), locale);
        //             if (displayNames !is null) {
        //                 foreach(MapEntry!(string, Integer) entry ; displayNames.entrySet()) {
        //                     map.put(cast(long)toWeekDay(entry.getValue()), entry.getKey());
        //                 }
        //             } else {
        //                 // Although probability is very less, but if other styles have duplicate names.
        //                 // Get names one by one _in that case.
        //                 for (int wday = Calendar.SUNDAY; wday <= Calendar.SATURDAY; wday++) {
        //                     string name;
        //                     name = CalendarDataUtility.retrieveJavaTimeFieldValueName(
        //                             "gregory", Calendar.DAY_OF_WEEK, wday, textStyle.toCalendarStyle(), locale);
        //                     if (name is null) {
        //                         break;
        //                     }
        //                     map.put(cast(long)toWeekDay(wday), name);
        //                 }
        //             }
        //         }
        //         if (!map.isEmpty()) {
        //             styleMap.put(textStyle, map);
        //         }
        //     }
        //     return new LocaleStore(styleMap);
        // }

        // if (field == ChronoField.AMPM_OF_DAY) {
        //     foreach(TextStyle textStyle ; TextStyle.values()) {
        //         if (textStyle.isStandalone()) {
        //             // Stand-alone isn't applicable to AM/PM.
        //             continue;
        //         }
        //         Map!(string, Integer) displayNames = CalendarDataUtility.retrieveJavaTimeFieldValueNames(
        //                 "gregory", Calendar.AM_PM, textStyle.toCalendarStyle(), locale);
        //         if (displayNames !is null) {
        //             Map!(Long, string) map = new HashMap!()();
        //             foreach(MapEntry!(string, Integer) entry ; displayNames.entrySet()) {
        //                 map.put(cast(long) entry.getValue(), entry.getKey());
        //             }
        //             if (!map.isEmpty()) {
        //                 styleMap.put(textStyle, map);
        //             }
        //         }
        //     }
        //     return new LocaleStore(styleMap);
        // }

        // if (field == IsoFields.QUARTER_OF_YEAR) {
        //     // The order of keys must correspond to the TextStyle.values() order.
        //     final string[] keys = {
        //         "QuarterNames",
        //         "standalone.QuarterNames",
        //         "QuarterAbbreviations",
        //         "standalone.QuarterAbbreviations",
        //         "QuarterNarrows",
        //         "standalone.QuarterNarrows",
        //     };
        //     for (int i = 0; i < keys.length; i++) {
        //         string[] names = getLocalizedResource(keys[i], locale);
        //         if (names !is null) {
        //             Map!(Long, string) map = new HashMap!()();
        //             for (int q = 0; q < names.length; q++) {
        //                 map.put(cast(long) (q + 1), names[q]);
        //             }
        //             styleMap.put(TextStyle.values()[i], map);
        //         }
        //     }
        //     return new LocaleStore(styleMap);
        // }

        return null;  // null marker for map
    }

    /**
     * Helper method to create an immutable entry.
     *
     * @param text  the text, not null
     * @param field  the field, not null
     * @return the entry, not null
     */
    private static  MapEntry!(A, B) createEntry(A,B)(A text, B field) {
        return new SimpleImmutableEntry!()(text, field);
    }

    /**
     * Returns the localized resource of the given key and locale, or null
     * if no localized resource is available.
     *
     * @param key  the key of the localized resource, not null
     * @param locale  the locale, not null
     * @return the localized resource, or null if not available
     * @throws NullPointerException if key or locale is null
     */
    /*@SuppressWarnings("unchecked")*/
    static T getLocalizedResource(T)(string key, Locale locale) {
        ///@gxc
        // LocaleResources lr = LocaleProviderAdapter.getResourceBundleBased()
        //                             .getLocaleResources(
        //                                 CalendarDataUtility.findRegionOverride(locale));
        // ResourceBundle rb = lr.getJavaTimeFormatData();
        // return rb.containsKey(key) ? cast(T) rb.getObject(key) : null;
        implementationMissing(false);
        return T.init;        
    }

    /**
     * Stores the text for a single locale.
     * !(p)
     * Some fields have a textual representation, such as day-of-week or month-of-year.
     * These textual representations can be captured _in this class for printing
     * and parsing.
     * !(p)
     * This class is immutable and thread-safe.
     */
    static final class LocaleStore {
        /**
         * Map of value to text.
         */
        private  Map!(TextStyle, Map!(Long, string)) valueTextMap;
        /**
         * Parsable data.
         */
        private  Map!(TextStyle, List!(MapEntry!(string, Long))) parsable;

        /**
         * Constructor.
         *
         * @param valueTextMap  the map of values to text to store, assigned and not altered, not null
         */
        this(Map!(TextStyle, Map!(Long, string)) valueTextMap) {
            ////@gxc
            // this.valueTextMap = valueTextMap;
            // Map!(TextStyle, List!(MapEntry!(string, Long))) map = new HashMap!(TextStyle, List!(MapEntry!(string, Long)))();
            // List!(MapEntry!(string, Long)) allList = new ArrayList!(MapEntry!(string, Long))();
            // foreach(TextStyle k , Map!(Long, string) vtmEntry ; valueTextMap) {
            //     Map!(string, MapEntry!(string, Long)) reverse = new HashMap!(string, MapEntry!(string, Long))();
            //     foreach(Long k2 , string v2 ; vtmEntry.getValue()) {
            //         if (reverse.put(v2, createEntry(v2, k2)) !is null) {
            //             // TODO: BUG: this has no effect
            //             continue;  // not parsable, try next style
            //         }
            //     }
            //     List!(MapEntry!(string, Long)) list = new ArrayList!(MapEntry!(string, Long))(reverse.values());
            //     Collections.sort(list, COMPARATOR);
            //     map.put(vtmEntry.getKey(), list);
            //     allList.addAll(list);
            //     map.put(null, allList);
            // }
            // Collections.sort(allList, COMPARATOR);
            // this.parsable = map;
        }

        /**
         * Gets the text for the specified field value, locale and style
         * for the purpose of printing.
         *
         * @param value  the value to get text for, not null
         * @param style  the style to get text for, not null
         * @return the text for the field value, null if no text found
         */
        string getText(long value, TextStyle style) {
            Map!(Long, string) map = valueTextMap.get(style);
            return map !is null ? map.get(new Long(value)) : null;
        }

        /**
         * Gets an iterator of text to field for the specified style for the purpose of parsing.
         * !(p)
         * The iterator must be returned _in order from the longest text to the shortest.
         *
         * @param style  the style to get text for, null for all parsable text
         * @return the iterator of text to field pairs, _in order from longest text to shortest text,
         *  null if the style is not parsable
         */
        Iterator!(MapEntry!(string, Long)) getTextIterator(TextStyle style) {
            List!(MapEntry!(string, Long)) list = parsable.get(style);
            return list !is null ? cast(Iterator!(MapEntry!(string, Long)))(list.iterator()) : null;
        }
    }
}
