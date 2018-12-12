
module hunt.time.format.DateTimeParseContext;

import hunt.time.ZoneId;
import hunt.time.chrono.Chronology;
import hunt.time.chrono.IsoChronology;
import hunt.time.temporal.TemporalAccessor;
import hunt.time.temporal.TemporalField;
import hunt.container.ArrayList;
import hunt.time.util.Locale;
import hunt.string.common;
import hunt.container.Set;
import hunt.time.util.Consumer;
import hunt.time.format.DateTimeFormatter;
import hunt.time.format.Parsed;
import hunt.time.format.DecimalStyle;
import hunt.time.format.ResolverStyle;
import hunt.lang;
import std.ascii;
/**
 * Context object used during date and time parsing.
 * !(p)
 * This class represents the current state of the parse.
 * It has the ability to store and retrieve the parsed values and manage optional segments.
 * It also provides key information to the parsing methods.
 * !(p)
 * Once parsing is complete, the {@link #toUnresolved()} is used to obtain the unresolved
 * result data. The {@link #toResolved()} is used to obtain the resolved result.
 *
 * @implSpec
 * This class is a mutable context intended for use from a single thread.
 * Usage of the class is thread-safe within standard parsing as a new instance of this class
 * is automatically created for each parse and parsing is single-threaded
 *
 * @since 1.8
 */
final class DateTimeParseContext {

    /**
     * The formatter, not null.
     */
    private DateTimeFormatter formatter;
    /**
     * Whether to parse using case sensitively.
     */
    private bool caseSensitive = true;
    /**
     * Whether to parse using strict rules.
     */
    private bool strict = true;
    /**
     * The list of parsed data.
     */
    private  ArrayList!(Parsed) parsed;
    /**
     * List of Consumers!(Chronology) to be notified if the Chronology changes.
     */
    private ArrayList!(Consumer!(Chronology)) chronoListeners = null;

     this()
    {
        parsed = new ArrayList!(Parsed)();
    }

    /**
     * Creates a new instance of the context.
     *
     * @param formatter  the formatter controlling the parse, not null
     */
    this(DateTimeFormatter formatter) {
        // super();
        parsed = new ArrayList!(Parsed)();
        this.formatter = formatter;
        parsed.add(new Parsed());
    }

    /**
     * Creates a copy of this context.
     * This retains the case sensitive and strict flags.
     */
    DateTimeParseContext copy() {
        DateTimeParseContext newContext = new DateTimeParseContext(formatter);
        newContext.caseSensitive = caseSensitive;
        newContext.strict = strict;
        return newContext;
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the locale.
     * !(p)
     * This locale is used to control localization _in the parse except
     * where localization is controlled by the DecimalStyle.
     *
     * @return the locale, not null
     */
    Locale getLocale() {
        return formatter.getLocale();
    }

    /**
     * Gets the DecimalStyle.
     * !(p)
     * The DecimalStyle controls the numeric parsing.
     *
     * @return the DecimalStyle, not null
     */
    DecimalStyle getDecimalStyle() {
        return formatter.getDecimalStyle();
    }

    /**
     * Gets the effective chronology during parsing.
     *
     * @return the effective parsing chronology, not null
     */
    Chronology getEffectiveChronology() {
        Chronology chrono = currentParsed().chrono;
        if (chrono is null) {
            chrono = formatter.getChronology();
            if (chrono is null) {
                chrono = IsoChronology.INSTANCE;
            }
        }
        return chrono;
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if parsing is case sensitive.
     *
     * @return true if parsing is case sensitive, false if case insensitive
     */
    bool isCaseSensitive() {
        return caseSensitive;
    }

    /**
     * Sets whether the parsing is case sensitive or not.
     *
     * @param caseSensitive  changes the parsing to be case sensitive or not from now on
     */
    void setCaseSensitive(bool caseSensitive) {
        this.caseSensitive = caseSensitive;
    }

    //-----------------------------------------------------------------------
    /**
     * Helper to compare two {@code CharSequence} instances.
     * This uses {@link #isCaseSensitive()}.
     *
     * @param cs1  the first character sequence, not null
     * @param offset1  the offset into the first sequence, valid
     * @param cs2  the second character sequence, not null
     * @param offset2  the offset into the second sequence, valid
     * @param length  the length to check, valid
     * @return true if equal
     */
    bool subSequenceEquals(string cs1, int offset1, string cs2, int offset2, int length) {
        if (offset1 + length > cs1.length || offset2 + length > cs2.length) {
            return false;
        }
        if (isCaseSensitive()) {
            for (int i = 0; i < length; i++) {
                char ch1 = cs1.charAt(offset1 + i);
                char ch2 = cs2.charAt(offset2 + i);
                if (ch1 != ch2) {
                    return false;
                }
            }
        } else {
            for (int i = 0; i < length; i++) {
                char ch1 = cs1.charAt(offset1 + i);
                char ch2 = cs2.charAt(offset2 + i);
                if (ch1 != ch2 && toUpper(ch1) != toUpper(ch2) &&
                        toLower(ch1) != toLower(ch2)) {
                    return false;
                }
            }
        }
        return true;
    }

    /**
     * Helper to compare two {@code char}.
     * This uses {@link #isCaseSensitive()}.
     *
     * @param ch1  the first character
     * @param ch2  the second character
     * @return true if equal
     */
    bool charEquals(char ch1, char ch2) {
        if (isCaseSensitive()) {
            return ch1 == ch2;
        }
        return charEqualsIgnoreCase(ch1, ch2);
    }

    /**
     * Compares two characters ignoring case.
     *
     * @param c1  the first
     * @param c2  the second
     * @return true if equal
     */
    static bool charEqualsIgnoreCase(char c1, char c2) {
        return c1 == c2 ||
                toUpper(c1) == toUpper(c2) ||
                toLower(c1) == toLower(c2);
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if parsing is strict.
     * !(p)
     * Strict parsing requires exact matching of the text and sign styles.
     *
     * @return true if parsing is strict, false if lenient
     */
    bool isStrict() {
        return strict;
    }

    /**
     * Sets whether parsing is strict or lenient.
     *
     * @param strict  changes the parsing to be strict or lenient from now on
     */
    void setStrict(bool strict) {
        this.strict = strict;
    }

    //-----------------------------------------------------------------------
    /**
     * Starts the parsing of an optional segment of the input.
     */
    void startOptional() {
        parsed.add(currentParsed().copy());
    }

    /**
     * Ends the parsing of an optional segment of the input.
     *
     * @param successful  whether the optional segment was successfully parsed
     */
    void endOptional(bool successful) {
        if (successful) {
            parsed.removeAt(parsed.size() - 2);
        } else {
            parsed.removeAt(parsed.size() - 1);
        }
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the currently active temporal objects.
     *
     * @return the current temporal objects, not null
     */
    private Parsed currentParsed() {
        return parsed.get(parsed.size() - 1);
    }

    /**
     * Gets the unresolved result of the parse.
     *
     * @return the result of the parse, not null
     */
    Parsed toUnresolved() {
        return currentParsed();
    }

    /**
     * Gets the resolved result of the parse.
     *
     * @return the result of the parse, not null
     */
    TemporalAccessor toResolved(ResolverStyle resolverStyle, Set!(TemporalField) resolverFields) {
        Parsed parsed = currentParsed();
        parsed.chrono = getEffectiveChronology();
        parsed.zone = (parsed.zone !is null ? parsed.zone : formatter.getZone());
        return parsed.resolve(resolverStyle, resolverFields);
    }


    //-----------------------------------------------------------------------
    /**
     * Gets the first value that was parsed for the specified field.
     * !(p)
     * This searches the results of the parse, returning the first value found
     * for the specified field. No attempt is made to derive a value.
     * The field may have an _out of range value.
     * For example, the day-of-month might be set to 50, or the hour to 1000.
     *
     * @param field  the field to query from the map, null returns null
     * @return the value mapped to the specified field, null if field was not parsed
     */
    Long getParsed(TemporalField field) {
        return currentParsed().fieldValues.get(field);
    }

    /**
     * Stores the parsed field.
     * !(p)
     * This stores a field-value pair that has been parsed.
     * The value stored may be _out of range for the field - no checks are performed.
     *
     * @param field  the field to set _in the field-value map, not null
     * @param value  the value to set _in the field-value map
     * @param errorPos  the position of the field being parsed
     * @param successPos  the position after the field being parsed
     * @return the new position
     */
    int setParsedField(TemporalField field, long value, int errorPos, int successPos) {
        assert(field, "field");
        Long old = currentParsed().fieldValues.put(field, new Long(value));
        return (old !is null && old.longValue() != value) ? ~errorPos : successPos;
    }

    /**
     * Stores the parsed chronology.
     * !(p)
     * This stores the chronology that has been parsed.
     * No validation is performed other than ensuring it is not null.
     * !(p)
     * The list of listeners is copied and cleared so that each
     * listener is called only once.  A listener can add itself again
     * if it needs to be notified of future changes.
     *
     * @param chrono  the parsed chronology, not null
     */
    void setParsed(Chronology chrono) {
        assert(chrono, "chrono");
        currentParsed().chrono = chrono;
        if (chronoListeners !is null && !chronoListeners.isEmpty()) {
            // @SuppressWarnings({"rawtypes", "unchecked"})
            Consumer!(Chronology)[] listeners = new Consumer!(Chronology)[1];

            foreach(c ; chronoListeners)
                listeners ~= c;
            // Consumer!(Chronology)[] listeners = chronoListeners.toArray(tmp);
            chronoListeners.clear();
            foreach(Consumer!(Chronology) l ; listeners) {
                l.accept(chrono);
            }
        }
    }

    /**
     * Adds a Consumer!(Chronology) to the list of listeners to be notified
     * if the Chronology changes.
     * @param listener a Consumer!(Chronology) to be called when Chronology changes
     */
    void addChronoChangedListener(Consumer!(Chronology) listener) {
        if (chronoListeners is null) {
            chronoListeners = new ArrayList!(Consumer!(Chronology))();
        }
        chronoListeners.add(listener);
    }

    /**
     * Stores the parsed zone.
     * !(p)
     * This stores the zone that has been parsed.
     * No validation is performed other than ensuring it is not null.
     *
     * @param zone  the parsed zone, not null
     */
    void setParsed(ZoneId zone) {
        assert(zone, "zone");
        currentParsed().zone = zone;
    }

    /**
     * Stores the parsed leap second.
     */
    void setParsedLeapSecond() {
        currentParsed().leapSecond = true;
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a string version of the context for debugging.
     *
     * @return a string representation of the context data, not null
     */
    override
    public string toString() {
        return currentParsed().toString();
    }

}
