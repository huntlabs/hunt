
module hunt.time.format.DateTimeFormatter;

import hunt.time.temporal.ChronoField;

import hunt.lang.exception;
// import hunt.text.FieldPosition;
// import hunt.text.Format;
// import hunt.text.ParseException;
// import hunt.text.ParsePosition;
import hunt.time.DateTimeException;
import hunt.time.Period;
import hunt.time.ZoneId;
import hunt.time.ZoneOffset;
import hunt.time.chrono.ChronoLocalDateTime;
import hunt.time.chrono.Chronology;
import hunt.time.chrono.IsoChronology;
import hunt.time.format.DateTimeFormatterBuilder;
import hunt.time.temporal.ChronoField;
import hunt.time.temporal.IsoFields;
import hunt.time.temporal.TemporalAccessor;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.TemporalQuery;
import std.algorithm.searching;
import hunt.container;
import hunt.lang;
import hunt.time.util.Locale;
import hunt.time.text.ParsePosition;
import hunt.time.format.DateTimeParseException;
import hunt.time.format.DateTimeParseContext;
import hunt.time.format.Parsed;
import hunt.time.format.SignStyle;
import hunt.time.format.DateTimePrintContext;
import hunt.string.StringBuilder;
import std.conv;
import hunt.time.util.QueryHelper;

// import sun.util.locale.provider.TimeZoneNameUtility;

/**
 * Formatter for printing and parsing date-time objects.
 * !(p)
 * This class provides the main application entry point for printing and parsing
 * and provides common implementations of {@code DateTimeFormatter}:
 * !(ul)
 * !(li)Using predefined constants, such as {@link #ISO_LOCAL_DATE}</li>
 * !(li)Using pattern letters, such as {@code uuuu-MMM-dd}</li>
 * !(li)Using localized styles, such as {@code long} or {@code medium}</li>
 * </ul>
 * !(p)
 * More complex formatters are provided by
 * {@link DateTimeFormatterBuilder DateTimeFormatterBuilder}.
 *
 * !(p)
 * The main date-time classes provide two methods - one for formatting,
 * {@code format(DateTimeFormatter formatter)}, and one for parsing,
 * {@code parse(string text, DateTimeFormatter formatter)}.
 * !(p)For example:
 * !(blockquote)!(pre)
 *  LocalDate date = LocalDate.now();
 *  string text = date.format(formatter);
 *  LocalDate parsedDate = LocalDate.parse(text, formatter);
 * </pre></blockquote>
 * !(p)
 * In addition to the format, formatters can be created with desired Locale,
 * Chronology, ZoneId, and DecimalStyle.
 * !(p)
 * The {@link #withLocale withLocale} method returns a new formatter that
 * overrides the locale. The locale affects some aspects of formatting and
 * parsing. For example, the {@link #ofLocalizedDate ofLocalizedDate} provides a
 * formatter that uses the locale specific date format.
 * !(p)
 * The {@link #withChronology withChronology} method returns a new formatter
 * that overrides the chronology. If overridden, the date-time value is
 * converted to the chronology before formatting. During parsing the date-time
 * value is converted to the chronology before it is returned.
 * !(p)
 * The {@link #withZone withZone} method returns a new formatter that overrides
 * the zone. If overridden, the date-time value is converted to a ZonedDateTime
 * with the requested ZoneId before formatting. During parsing the ZoneId is
 * applied before the value is returned.
 * !(p)
 * The {@link #withDecimalStyle withDecimalStyle} method returns a new formatter that
 * overrides the {@link DecimalStyle}. The DecimalStyle symbols are used for
 * formatting and parsing.
 * !(p)
 * Some applications may need to use the older {@link Format java.text.Format}
 * class for formatting. The {@link #toFormat()} method returns an
 * implementation of {@code java.text.Format}.
 *
 * <h3 id="predefined">Predefined Formatters</h3>
 * <table class="striped" style="text-align:left">
 * !(caption)Predefined Formatters</caption>
 * !(thead)
 * !(tr)
 * <th scope="col">Formatter</th>
 * <th scope="col">Description</th>
 * <th scope="col">Example</th>
 * </tr>
 * </thead>
 * !(tbody)
 * !(tr)
 * <th scope="row">{@link #ofLocalizedDate ofLocalizedDate(dateStyle)} </th>
 * !(td) Formatter with date style from the locale </td>
 * !(td) '2011-12-03'</td>
 * </tr>
 * !(tr)
 * <th scope="row"> {@link #ofLocalizedTime ofLocalizedTime(timeStyle)} </th>
 * !(td) Formatter with time style from the locale </td>
 * !(td) '10:15:30'</td>
 * </tr>
 * !(tr)
 * <th scope="row"> {@link #ofLocalizedDateTime ofLocalizedDateTime(dateTimeStyle)} </th>
 * !(td) Formatter with a style for date and time from the locale</td>
 * !(td) '3 Jun 2008 11:05:30'</td>
 * </tr>
 * !(tr)
 * <th scope="row"> {@link #ofLocalizedDateTime ofLocalizedDateTime(dateStyle,timeStyle)}
 * </th>
 * !(td) Formatter with date and time styles from the locale </td>
 * !(td) '3 Jun 2008 11:05'</td>
 * </tr>
 * !(tr)
 * <th scope="row"> {@link #BASIC_ISO_DATE}</th>
 * !(td)Basic ISO date </td> !(td)'20111203'</td>
 * </tr>
 * !(tr)
 * <th scope="row"> {@link #ISO_LOCAL_DATE}</th>
 * !(td) ISO Local Date </td>
 * !(td)'2011-12-03'</td>
 * </tr>
 * !(tr)
 * <th scope="row"> {@link #ISO_OFFSET_DATE}</th>
 * !(td) ISO Date with offset </td>
 * !(td)'2011-12-03+01:00'</td>
 * </tr>
 * !(tr)
 * <th scope="row"> {@link #ISO_DATE}</th>
 * !(td) ISO Date with or without offset </td>
 * !(td) '2011-12-03+01:00'; '2011-12-03'</td>
 * </tr>
 * !(tr)
 * <th scope="row"> {@link #ISO_LOCAL_TIME}</th>
 * !(td) Time without offset </td>
 * !(td)'10:15:30'</td>
 * </tr>
 * !(tr)
 * <th scope="row"> {@link #ISO_OFFSET_TIME}</th>
 * !(td) Time with offset </td>
 * !(td)'10:15:30+01:00'</td>
 * </tr>
 * !(tr)
 * <th scope="row"> {@link #ISO_TIME}</th>
 * !(td) Time with or without offset </td>
 * !(td)'10:15:30+01:00'; '10:15:30'</td>
 * </tr>
 * !(tr)
 * <th scope="row"> {@link #ISO_LOCAL_DATE_TIME}</th>
 * !(td) ISO Local Date and Time </td>
 * !(td)'2011-12-03T10:15:30'</td>
 * </tr>
 * !(tr)
 * <th scope="row"> {@link #ISO_OFFSET_DATE_TIME}</th>
 * !(td) Date Time with Offset
 * </td>!(td)'2011-12-03T10:15:30+01:00'</td>
 * </tr>
 * !(tr)
 * <th scope="row"> {@link #ISO_ZONED_DATE_TIME}</th>
 * !(td) Zoned Date Time </td>
 * !(td)'2011-12-03T10:15:30+01:00[Europe/Paris]'</td>
 * </tr>
 * !(tr)
 * <th scope="row"> {@link #ISO_DATE_TIME}</th>
 * !(td) Date and time with ZoneId </td>
 * !(td)'2011-12-03T10:15:30+01:00[Europe/Paris]'</td>
 * </tr>
 * !(tr)
 * <th scope="row"> {@link #ISO_ORDINAL_DATE}</th>
 * !(td) Year and day of year </td>
 * !(td)'2012-337'</td>
 * </tr>
 * !(tr)
 * <th scope="row"> {@link #ISO_WEEK_DATE}</th>
 * !(td) Year and Week </td>
 * !(td)'2012-W48-6'</td></tr>
 * !(tr)
 * <th scope="row"> {@link #ISO_INSTANT}</th>
 * !(td) Date and Time of an Instant </td>
 * !(td)'2011-12-03T10:15:30Z' </td>
 * </tr>
 * !(tr)
 * <th scope="row"> {@link #RFC_1123_DATE_TIME}</th>
 * !(td) RFC 1123 / RFC 822 </td>
 * !(td)'Tue, 3 Jun 2008 11:05:30 GMT'</td>
 * </tr>
 * </tbody>
 * </table>
 *
 * <h3 id="patterns">Patterns for Formatting and Parsing</h3>
 * Patterns are based on a simple sequence of letters and symbols.
 * A pattern is used to create a Formatter using the
 * {@link #ofPattern(string)} and {@link #ofPattern(string, Locale)} methods.
 * For example,
 * {@code "d MMM uuuu"} will format 2011-12-03 as '3&nbsp;Dec&nbsp;2011'.
 * A formatter created from a pattern can be used as many times as necessary,
 * it is immutable and is thread-safe.
 * !(p)
 * For example:
 * !(blockquote)!(pre)
 *  LocalDate date = LocalDate.now();
 *  DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy MM dd");
 *  string text = date.format(formatter);
 *  LocalDate parsedDate = LocalDate.parse(text, formatter);
 * </pre></blockquote>
 * !(p)
 * All letters 'A' to 'Z' and 'a' to 'z' are reserved as pattern letters. The
 * following pattern letters are defined:
 * <table class="striped">
 * !(caption)Pattern Letters and Symbols</caption>
 * !(thead)
 *  !(tr)<th scope="col">Symbol</th>   <th scope="col">Meaning</th>         <th scope="col">Presentation</th> <th scope="col">Examples</th>
 * </thead>
 * !(tbody)
 *   !(tr)<th scope="row">G</th>       !(td)era</td>                         !(td)text</td>              !(td)AD; Anno Domini; A</td>
 *   !(tr)<th scope="row">u</th>       !(td)year</td>                        !(td)year</td>              !(td)2004; 04</td>
 *   !(tr)<th scope="row">y</th>       !(td)year-of-era</td>                 !(td)year</td>              !(td)2004; 04</td>
 *   !(tr)<th scope="row">D</th>       !(td)day-of-year</td>                 !(td)number</td>            !(td)189</td>
 *   !(tr)<th scope="row">M/L</th>     !(td)month-of-year</td>               !(td)number/text</td>       !(td)7; 07; Jul; July; J</td>
 *   !(tr)<th scope="row">d</th>       !(td)day-of-month</td>                !(td)number</td>            !(td)10</td>
 *   !(tr)<th scope="row">g</th>       !(td)modified-julian-day</td>         !(td)number</td>            !(td)2451334</td>
 *
 *   !(tr)<th scope="row">Q/q</th>     !(td)quarter-of-year</td>             !(td)number/text</td>       !(td)3; 03; Q3; 3rd quarter</td>
 *   !(tr)<th scope="row">Y</th>       !(td)week-based-year</td>             !(td)year</td>              !(td)1996; 96</td>
 *   !(tr)<th scope="row">w</th>       !(td)week-of-week-based-year</td>     !(td)number</td>            !(td)27</td>
 *   !(tr)<th scope="row">W</th>       !(td)week-of-month</td>               !(td)number</td>            !(td)4</td>
 *   !(tr)<th scope="row">E</th>       !(td)day-of-week</td>                 !(td)text</td>              !(td)Tue; Tuesday; T</td>
 *   !(tr)<th scope="row">e/c</th>     !(td)localized day-of-week</td>       !(td)number/text</td>       !(td)2; 02; Tue; Tuesday; T</td>
 *   !(tr)<th scope="row">F</th>       !(td)day-of-week-_in-month</td>        !(td)number</td>            !(td)3</td>
 *
 *   !(tr)<th scope="row">a</th>       !(td)am-pm-of-day</td>                !(td)text</td>              !(td)PM</td>
 *   !(tr)<th scope="row">h</th>       !(td)clock-hour-of-am-pm (1-12)</td>  !(td)number</td>            !(td)12</td>
 *   !(tr)<th scope="row">K</th>       !(td)hour-of-am-pm (0-11)</td>        !(td)number</td>            !(td)0</td>
 *   !(tr)<th scope="row">k</th>       !(td)clock-hour-of-day (1-24)</td>    !(td)number</td>            !(td)24</td>
 *
 *   !(tr)<th scope="row">H</th>       !(td)hour-of-day (0-23)</td>          !(td)number</td>            !(td)0</td>
 *   !(tr)<th scope="row">m</th>       !(td)minute-of-hour</td>              !(td)number</td>            !(td)30</td>
 *   !(tr)<th scope="row">s</th>       !(td)second-of-minute</td>            !(td)number</td>            !(td)55</td>
 *   !(tr)<th scope="row">S</th>       !(td)fraction-of-second</td>          !(td)fraction</td>          !(td)978</td>
 *   !(tr)<th scope="row">A</th>       !(td)milli-of-day</td>                !(td)number</td>            !(td)1234</td>
 *   !(tr)<th scope="row">n</th>       !(td)nano-of-second</td>              !(td)number</td>            !(td)987654321</td>
 *   !(tr)<th scope="row">N</th>       !(td)nano-of-day</td>                 !(td)number</td>            !(td)1234000000</td>
 *
 *   !(tr)<th scope="row">V</th>       !(td)time-zone ID</td>                !(td)zone-id</td>           !(td)America/Los_Angeles; Z; -08:30</td>
 *   !(tr)<th scope="row">v</th>       !(td)generic time-zone name</td>      !(td)zone-name</td>         !(td)Pacific Time; PT</td>
 *   !(tr)<th scope="row">z</th>       !(td)time-zone name</td>              !(td)zone-name</td>         !(td)Pacific Standard Time; PST</td>
 *   !(tr)<th scope="row">O</th>       !(td)localized zone-offset</td>       !(td)offset-O</td>          !(td)GMT+8; GMT+08:00; UTC-08:00</td>
 *   !(tr)<th scope="row">X</th>       !(td)zone-offset 'Z' for zero</td>    !(td)offset-X</td>          !(td)Z; -08; -0830; -08:30; -083015; -08:30:15</td>
 *   !(tr)<th scope="row">x</th>       !(td)zone-offset</td>                 !(td)offset-x</td>          !(td)+0000; -08; -0830; -08:30; -083015; -08:30:15</td>
 *   !(tr)<th scope="row">Z</th>       !(td)zone-offset</td>                 !(td)offset-Z</td>          !(td)+0000; -0800; -08:00</td>
 *
 *   !(tr)<th scope="row">p</th>       !(td)pad next</td>                    !(td)pad modifier</td>      !(td)1</td>
 *
 *   !(tr)<th scope="row">'</th>       !(td)escape for text</td>             !(td)delimiter</td>         !(td)</td>
 *   !(tr)<th scope="row">''</th>      !(td)single quote</td>                !(td)literal</td>           !(td)'</td>
 *   !(tr)<th scope="row">[</th>       !(td)optional section start</td>      !(td)</td>                  !(td)</td>
 *   !(tr)<th scope="row">]</th>       !(td)optional section end</td>        !(td)</td>                  !(td)</td>
 *   !(tr)<th scope="row">#</th>       !(td)reserved for future use</td>     !(td)</td>                  !(td)</td>
 *   !(tr)<th scope="row">{</th>       !(td)reserved for future use</td>     !(td)</td>                  !(td)</td>
 *   !(tr)<th scope="row">}</th>       !(td)reserved for future use</td>     !(td)</td>                  !(td)</td>
 * </tbody>
 * </table>
 * !(p)
 * The count of pattern letters determines the format.
 * !(p)
 * !(b)Text</b>: The text style is determined based on the number of pattern
 * letters used. Less than 4 pattern letters will use the
 * {@link TextStyle#SHORT short form}. Exactly 4 pattern letters will use the
 * {@link TextStyle#FULL full form}. Exactly 5 pattern letters will use the
 * {@link TextStyle#NARROW narrow form}.
 * Pattern letters 'L', 'c', and 'q' specify the stand-alone form of the text styles.
 * !(p)
 * !(b)Number</b>: If the count of letters is one, then the value is output using
 * the minimum number of digits and without padding. Otherwise, the count of digits
 * is used as the width of the output field, with the value zero-padded as necessary.
 * The following pattern letters have constraints on the count of letters.
 * Only one letter of 'c' and 'F' can be specified.
 * Up to two letters of 'd', 'H', 'h', 'K', 'k', 'm', and 's' can be specified.
 * Up to three letters of 'D' can be specified.
 * !(p)
 * !(b)Number/Text</b>: If the count of pattern letters is 3 or greater, use the
 * Text rules above. Otherwise use the Number rules above.
 * !(p)
 * !(b)Fraction</b>: Outputs the nano-of-second field as a fraction-of-second.
 * The nano-of-second value has nine digits, thus the count of pattern letters
 * is from 1 to 9. If it is less than 9, then the nano-of-second value is
 * truncated, with only the most significant digits being output.
 * !(p)
 * !(b)Year</b>: The count of letters determines the minimum field width below
 * which padding is used. If the count of letters is two, then a
 * {@link DateTimeFormatterBuilder#appendValueReduced reduced} two digit form is
 * used. For printing, this outputs the rightmost two digits. For parsing, this
 * will parse using the base value of 2000, resulting _in a year within the range
 * 2000 to 2099 inclusive. If the count of letters is less than four (but not
 * two), then the sign is only output for negative years as per
 * {@link SignStyle#NORMAL}. Otherwise, the sign is output if the pad width is
 * exceeded, as per {@link SignStyle#EXCEEDS_PAD}.
 * !(p)
 * !(b)ZoneId</b>: This outputs the time-zone ID, such as 'Europe/Paris'. If the
 * count of letters is two, then the time-zone ID is output. Any other count of
 * letters throws {@code IllegalArgumentException}.
 * !(p)
 * !(b)Zone names</b>: This outputs the display name of the time-zone ID. If the
 * pattern letter is 'z' the output is the daylight savings aware zone name.
 * If there is insufficient information to determine whether DST applies,
 * the name ignoring daylight savings time will be used.
 * If the count of letters is one, two or three, then the short name is output.
 * If the count of letters is four, then the full name is output.
 * Five or more letters throws {@code IllegalArgumentException}.
 * !(p)
 * If the pattern letter is 'v' the output provides the zone name ignoring
 * daylight savings time. If the count of letters is one, then the short name is output.
 * If the count of letters is four, then the full name is output.
 * Two, three and five or more letters throw {@code IllegalArgumentException}.
 * !(p)
 * !(b)Offset X and x</b>: This formats the offset based on the number of pattern
 * letters. One letter outputs just the hour, such as '+01', unless the minute
 * is non-zero _in which case the minute is also output, such as '+0130'. Two
 * letters outputs the hour and minute, without a colon, such as '+0130'. Three
 * letters outputs the hour and minute, with a colon, such as '+01:30'. Four
 * letters outputs the hour and minute and optional second, without a colon,
 * such as '+013015'. Five letters outputs the hour and minute and optional
 * second, with a colon, such as '+01:30:15'. Six or more letters throws
 * {@code IllegalArgumentException}. Pattern letter 'X' (upper case) will output
 * 'Z' when the offset to be output would be zero, whereas pattern letter 'x'
 * (lower case) will output '+00', '+0000', or '+00:00'.
 * !(p)
 * !(b)Offset O</b>: This formats the localized offset based on the number of
 * pattern letters. One letter outputs the {@linkplain TextStyle#SHORT short}
 * form of the localized offset, which is localized offset text, such as 'GMT',
 * with hour without leading zero, optional 2-digit minute and second if
 * non-zero, and colon, for example 'GMT+8'. Four letters outputs the
 * {@linkplain TextStyle#FULL full} form, which is localized offset text,
 * such as 'GMT, with 2-digit hour and minute field, optional second field
 * if non-zero, and colon, for example 'GMT+08:00'. Any other count of letters
 * throws {@code IllegalArgumentException}.
 * !(p)
 * !(b)Offset Z</b>: This formats the offset based on the number of pattern
 * letters. One, two or three letters outputs the hour and minute, without a
 * colon, such as '+0130'. The output will be '+0000' when the offset is zero.
 * Four letters outputs the {@linkplain TextStyle#FULL full} form of localized
 * offset, equivalent to four letters of Offset-O. The output will be the
 * corresponding localized offset text if the offset is zero. Five
 * letters outputs the hour, minute, with optional second if non-zero, with
 * colon. It outputs 'Z' if the offset is zero.
 * Six or more letters throws {@code IllegalArgumentException}.
 * !(p)
 * !(b)Optional section</b>: The optional section markers work exactly like
 * calling {@link DateTimeFormatterBuilder#optionalStart()} and
 * {@link DateTimeFormatterBuilder#optionalEnd()}.
 * !(p)
 * !(b)Pad modifier</b>: Modifies the pattern that immediately follows to be
 * padded with spaces. The pad width is determined by the number of pattern
 * letters. This is the same as calling
 * {@link DateTimeFormatterBuilder#padNext(int)}.
 * !(p)
 * For example, 'ppH' outputs the hour-of-day padded on the left with spaces to
 * a width of 2.
 * !(p)
 * Any unrecognized letter is an error. Any non-letter character, other than
 * '[', ']', '{', '}', '#' and the single quote will be output directly.
 * Despite this, it is recommended to use single quotes around all characters
 * that you want to output directly to ensure that future changes do not break
 * your application.
 *
 * <h3 id="resolving">Resolving</h3>
 * Parsing is implemented as a two-phase operation.
 * First, the text is parsed using the layout defined by the formatter, producing
 * a {@code Map} of field to value, a {@code ZoneId} and a {@code Chronology}.
 * Second, the parsed data is !(em)resolved</em>, by validating, combining and
 * simplifying the various fields into more useful ones.
 * !(p)
 * Five parsing methods are supplied by this class.
 * Four of these perform both the parse and resolve phases.
 * The fifth method, {@link #parseUnresolved(string, ParsePosition)},
 * only performs the first phase, leaving the result unresolved.
 * As such, it is essentially a low-level operation.
 * !(p)
 * The resolve phase is controlled by two parameters, set on this class.
 * !(p)
 * The {@link ResolverStyle} is an enum that offers three different approaches,
 * strict, smart and lenient. The smart option is the default.
 * It can be set using {@link #withResolverStyle(ResolverStyle)}.
 * !(p)
 * The {@link #withResolverFields(TemporalField...)} parameter allows the
 * set of fields that will be resolved to be filtered before resolving starts.
 * For example, if the formatter has parsed a year, month, day-of-month
 * and day-of-year, then there are two approaches to resolve a date:
 * (year + month + day-of-month) and (year + day-of-year).
 * The resolver fields allows one of the two approaches to be selected.
 * If no resolver fields are set then both approaches must result _in the same date.
 * !(p)
 * Resolving separate fields to form a complete date and time is a complex
 * process with behaviour distributed across a number of classes.
 * It follows these steps:
 * !(ol)
 * !(li)The chronology is determined.
 * The chronology of the result is either the chronology that was parsed,
 * or if no chronology was parsed, it is the chronology set on this class,
 * or if that is null, it is {@code IsoChronology}.
 * !(li)The {@code ChronoField} date fields are resolved.
 * This is achieved using {@link Chronology#resolveDate(Map, ResolverStyle)}.
 * Documentation about field resolution is located _in the implementation
 * of {@code Chronology}.
 * !(li)The {@code ChronoField} time fields are resolved.
 * This is documented on {@link ChronoField} and is the same for all chronologies.
 * !(li)Any fields that are not {@code ChronoField} are processed.
 * This is achieved using {@link TemporalField#resolve(Map, TemporalAccessor, ResolverStyle)}.
 * Documentation about field resolution is located _in the implementation
 * of {@code TemporalField}.
 * !(li)The {@code ChronoField} date and time fields are re-resolved.
 * This allows fields _in step four to produce {@code ChronoField} values
 * and have them be processed into dates and times.
 * !(li)A {@code LocalTime} is formed if there is at least an hour-of-day available.
 * This involves providing default values for minute, second and fraction of second.
 * !(li)Any remaining unresolved fields are cross-checked against any
 * date and/or time that was resolved. Thus, an earlier stage would resolve
 * (year + month + day-of-month) to a date, and this stage would check that
 * day-of-week was valid for the date.
 * !(li)If an {@linkplain #parsedExcessDays() excess number of days}
 * was parsed then it is added to the date if a date is available.
 * !(li) If a second-based field is present, but {@code LocalTime} was not parsed,
 * then the resolver ensures that milli, micro and nano second values are
 * available to meet the contract of {@link ChronoField}.
 * These will be set to zero if missing.
 * !(li)If both date and time were parsed and either an offset or zone is present,
 * the field {@link ChronoField#INSTANT_SECONDS} is created.
 * If an offset was parsed then the offset will be combined with the
 * {@code LocalDateTime} to form the instant, with any zone ignored.
 * If a {@code ZoneId} was parsed without an offset then the zone will be
 * combined with the {@code LocalDateTime} to form the instant using the rules
 * of {@link ChronoLocalDateTime#atZone(ZoneId)}.
 * </ol>
 *
 * @implSpec
 * This class is immutable and thread-safe.
 *
 * @since 1.8
 */
import hunt.time.format.DecimalStyle;
import hunt.time.format.ResolverStyle;
import hunt.time.format.FormatStyle;
import hunt.time.format.DateTimeFormatterBuilder;

public final class DateTimeFormatter {

    /**
     * The printer and/or parser to use, not null.
     */
    private  DateTimeFormatterBuilder.CompositePrinterParser printerParser;
    /**
     * The locale to use for formatting, not null.
     */
    private  Locale locale;
    /**
     * The symbols to use for formatting, not null.
     */
    private  DecimalStyle decimalStyle;
    /**
     * The resolver style to use, not null.
     */
    private  ResolverStyle resolverStyle;
    /**
     * The fields to use _in resolving, null for all fields.
     */
    private  Set!(TemporalField) resolverFields;
    /**
     * The chronology to use for formatting, null for no override.
     */
    private  Chronology chrono;
    /**
     * The zone to use for formatting, null for no override.
     */
    private  ZoneId zone;

    //-----------------------------------------------------------------------
    /**
     * Creates a formatter using the specified pattern.
     * !(p)
     * This method will create a formatter based on a simple
     * <a href="#patterns">pattern of letters and symbols</a>
     * as described _in the class documentation.
     * For example, {@code d MMM uuuu} will format 2011-12-03 as '3 Dec 2011'.
     * !(p)
     * The formatter will use the {@link Locale#getDefault(Locale.Category) default FORMAT locale}.
     * This can be changed using {@link DateTimeFormatter#withLocale(Locale)} on the returned formatter.
     * Alternatively use the {@link #ofPattern(string, Locale)} variant of this method.
     * !(p)
     * The returned formatter has no override chronology or zone.
     * It uses {@link ResolverStyle#SMART SMART} resolver style.
     *
     * @param pattern  the pattern to use, not null
     * @return the formatter based on the pattern, not null
     * @throws IllegalArgumentException if the pattern is invalid
     * @see DateTimeFormatterBuilder#appendPattern(string)
     */
    public static DateTimeFormatter ofPattern(string pattern) {
        return new DateTimeFormatterBuilder().appendPattern(pattern).toFormatter();
    }

    /**
     * Creates a formatter using the specified pattern and locale.
     * !(p)
     * This method will create a formatter based on a simple
     * <a href="#patterns">pattern of letters and symbols</a>
     * as described _in the class documentation.
     * For example, {@code d MMM uuuu} will format 2011-12-03 as '3 Dec 2011'.
     * !(p)
     * The formatter will use the specified locale.
     * This can be changed using {@link DateTimeFormatter#withLocale(Locale)} on the returned formatter.
     * !(p)
     * The returned formatter has no override chronology or zone.
     * It uses {@link ResolverStyle#SMART SMART} resolver style.
     *
     * @param pattern  the pattern to use, not null
     * @param locale  the locale to use, not null
     * @return the formatter based on the pattern, not null
     * @throws IllegalArgumentException if the pattern is invalid
     * @see DateTimeFormatterBuilder#appendPattern(string)
     */
    public static DateTimeFormatter ofPattern(string pattern, Locale locale) {
        return new DateTimeFormatterBuilder().appendPattern(pattern).toFormatter(locale);
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a locale specific date format for the ISO chronology.
     * !(p)
     * This returns a formatter that will format or parse a date.
     * The exact format pattern used varies by locale.
     * !(p)
     * The locale is determined from the formatter. The formatter returned directly by
     * this method will use the {@link Locale#getDefault(Locale.Category) default FORMAT locale}.
     * The locale can be controlled using {@link DateTimeFormatter#withLocale(Locale) withLocale(Locale)}
     * on the result of this method.
     * !(p)
     * Note that the localized pattern is looked up lazily.
     * This {@code DateTimeFormatter} holds the style required and the locale,
     * looking up the pattern required on demand.
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#SMART SMART} resolver style.
     *
     * @param dateStyle  the formatter style to obtain, not null
     * @return the date formatter, not null
     */
    public static DateTimeFormatter ofLocalizedDate(FormatStyle dateStyle) {
        assert(dateStyle, "dateStyle");
        return new DateTimeFormatterBuilder().appendLocalized(dateStyle, null)
                .toFormatter(ResolverStyle.SMART, IsoChronology.INSTANCE);
    }

    /**
     * Returns a locale specific time format for the ISO chronology.
     * !(p)
     * This returns a formatter that will format or parse a time.
     * The exact format pattern used varies by locale.
     * !(p)
     * The locale is determined from the formatter. The formatter returned directly by
     * this method will use the {@link Locale#getDefault(Locale.Category) default FORMAT locale}.
     * The locale can be controlled using {@link DateTimeFormatter#withLocale(Locale) withLocale(Locale)}
     * on the result of this method.
     * !(p)
     * Note that the localized pattern is looked up lazily.
     * This {@code DateTimeFormatter} holds the style required and the locale,
     * looking up the pattern required on demand.
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#SMART SMART} resolver style.
     * The {@code FULL} and {@code LONG} styles typically require a time-zone.
     * When formatting using these styles, a {@code ZoneId} must be available,
     * either by using {@code ZonedDateTime} or {@link DateTimeFormatter#withZone}.
     *
     * @param timeStyle  the formatter style to obtain, not null
     * @return the time formatter, not null
     */
    public static DateTimeFormatter ofLocalizedTime(FormatStyle timeStyle) {
        assert(timeStyle, "timeStyle");
        return new DateTimeFormatterBuilder().appendLocalized(null, timeStyle)
                .toFormatter(ResolverStyle.SMART, IsoChronology.INSTANCE);
    }

    /**
     * Returns a locale specific date-time formatter for the ISO chronology.
     * !(p)
     * This returns a formatter that will format or parse a date-time.
     * The exact format pattern used varies by locale.
     * !(p)
     * The locale is determined from the formatter. The formatter returned directly by
     * this method will use the {@link Locale#getDefault(Locale.Category) default FORMAT locale}.
     * The locale can be controlled using {@link DateTimeFormatter#withLocale(Locale) withLocale(Locale)}
     * on the result of this method.
     * !(p)
     * Note that the localized pattern is looked up lazily.
     * This {@code DateTimeFormatter} holds the style required and the locale,
     * looking up the pattern required on demand.
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#SMART SMART} resolver style.
     * The {@code FULL} and {@code LONG} styles typically require a time-zone.
     * When formatting using these styles, a {@code ZoneId} must be available,
     * either by using {@code ZonedDateTime} or {@link DateTimeFormatter#withZone}.
     *
     * @param dateTimeStyle  the formatter style to obtain, not null
     * @return the date-time formatter, not null
     */
    public static DateTimeFormatter ofLocalizedDateTime(FormatStyle dateTimeStyle) {
        assert(dateTimeStyle, "dateTimeStyle");
        return new DateTimeFormatterBuilder().appendLocalized(dateTimeStyle, dateTimeStyle)
                .toFormatter(ResolverStyle.SMART, IsoChronology.INSTANCE);
    }

    /**
     * Returns a locale specific date and time format for the ISO chronology.
     * !(p)
     * This returns a formatter that will format or parse a date-time.
     * The exact format pattern used varies by locale.
     * !(p)
     * The locale is determined from the formatter. The formatter returned directly by
     * this method will use the {@link Locale#getDefault() default FORMAT locale}.
     * The locale can be controlled using {@link DateTimeFormatter#withLocale(Locale) withLocale(Locale)}
     * on the result of this method.
     * !(p)
     * Note that the localized pattern is looked up lazily.
     * This {@code DateTimeFormatter} holds the style required and the locale,
     * looking up the pattern required on demand.
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#SMART SMART} resolver style.
     * The {@code FULL} and {@code LONG} styles typically require a time-zone.
     * When formatting using these styles, a {@code ZoneId} must be available,
     * either by using {@code ZonedDateTime} or {@link DateTimeFormatter#withZone}.
     *
     * @param dateStyle  the date formatter style to obtain, not null
     * @param timeStyle  the time formatter style to obtain, not null
     * @return the date, time or date-time formatter, not null
     */
    public static DateTimeFormatter ofLocalizedDateTime(FormatStyle dateStyle, FormatStyle timeStyle) {
        assert(dateStyle, "dateStyle");
        assert(timeStyle, "timeStyle");
        return new DateTimeFormatterBuilder().appendLocalized(dateStyle, timeStyle)
                .toFormatter(ResolverStyle.SMART, IsoChronology.INSTANCE);
    }

    //-----------------------------------------------------------------------
    /**
     * The ISO date formatter that formats or parses a date without an
     * offset, such as '2011-12-03'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 extended local date format.
     * The format consists of:
     * !(ul)
     * !(li)Four digits or more for the {@link ChronoField#YEAR year}.
     * Years _in the range 0000 to 9999 will be pre-padded by zero to ensure four digits.
     * Years outside that range will have a prefixed positive or negative symbol.
     * !(li)A dash
     * !(li)Two digits for the {@link ChronoField#MONTH_OF_YEAR month-of-year}.
     *  This is pre-padded by zero to ensure two digits.
     * !(li)A dash
     * !(li)Two digits for the {@link ChronoField#DAY_OF_MONTH day-of-month}.
     *  This is pre-padded by zero to ensure two digits.
     * </ul>
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    public __gshared DateTimeFormatter ISO_LOCAL_DATE ;
  
    //-----------------------------------------------------------------------
    /**
     * The ISO date formatter that formats or parses a date with an
     * offset, such as '2011-12-03+01:00'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 extended offset date format.
     * The format consists of:
     * !(ul)
     * !(li)The {@link #ISO_LOCAL_DATE}
     * !(li)The {@link ZoneOffset#getId() offset ID}. If the offset has seconds then
     *  they will be handled even though this is not part of the ISO-8601 standard.
     *  Parsing is case insensitive.
     * </ul>
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    public __gshared DateTimeFormatter ISO_OFFSET_DATE ;
 
    //-----------------------------------------------------------------------
    /**
     * The ISO date formatter that formats or parses a date with the
     * offset if available, such as '2011-12-03' or '2011-12-03+01:00'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 extended date format.
     * The format consists of:
     * !(ul)
     * !(li)The {@link #ISO_LOCAL_DATE}
     * !(li)If the offset is not available then the format is complete.
     * !(li)The {@link ZoneOffset#getId() offset ID}. If the offset has seconds then
     *  they will be handled even though this is not part of the ISO-8601 standard.
     *  Parsing is case insensitive.
     * </ul>
     * !(p)
     * As this formatter has an optional element, it may be necessary to parse using
     * {@link DateTimeFormatter#parseBest}.
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    public __gshared DateTimeFormatter ISO_DATE ;
    

    //-----------------------------------------------------------------------
    /**
     * The ISO time formatter that formats or parses a time without an
     * offset, such as '10:15' or '10:15:30'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 extended local time format.
     * The format consists of:
     * !(ul)
     * !(li)Two digits for the {@link ChronoField#HOUR_OF_DAY hour-of-day}.
     *  This is pre-padded by zero to ensure two digits.
     * !(li)A colon
     * !(li)Two digits for the {@link ChronoField#MINUTE_OF_HOUR minute-of-hour}.
     *  This is pre-padded by zero to ensure two digits.
     * !(li)If the second-of-minute is not available then the format is complete.
     * !(li)A colon
     * !(li)Two digits for the {@link ChronoField#SECOND_OF_MINUTE second-of-minute}.
     *  This is pre-padded by zero to ensure two digits.
     * !(li)If the nano-of-second is zero or not available then the format is complete.
     * !(li)A decimal point
     * !(li)One to nine digits for the {@link ChronoField#NANO_OF_SECOND nano-of-second}.
     *  As many digits will be output as required.
     * </ul>
     * !(p)
     * The returned formatter has no override chronology or zone.
     * It uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    public __gshared DateTimeFormatter ISO_LOCAL_TIME ;
    
    //-----------------------------------------------------------------------
    /**
     * The ISO time formatter that formats or parses a time with an
     * offset, such as '10:15+01:00' or '10:15:30+01:00'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 extended offset time format.
     * The format consists of:
     * !(ul)
     * !(li)The {@link #ISO_LOCAL_TIME}
     * !(li)The {@link ZoneOffset#getId() offset ID}. If the offset has seconds then
     *  they will be handled even though this is not part of the ISO-8601 standard.
     *  Parsing is case insensitive.
     * </ul>
     * !(p)
     * The returned formatter has no override chronology or zone.
     * It uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    public __gshared DateTimeFormatter ISO_OFFSET_TIME ;
    

    //-----------------------------------------------------------------------
    /**
     * The ISO time formatter that formats or parses a time, with the
     * offset if available, such as '10:15', '10:15:30' or '10:15:30+01:00'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 extended offset time format.
     * The format consists of:
     * !(ul)
     * !(li)The {@link #ISO_LOCAL_TIME}
     * !(li)If the offset is not available then the format is complete.
     * !(li)The {@link ZoneOffset#getId() offset ID}. If the offset has seconds then
     *  they will be handled even though this is not part of the ISO-8601 standard.
     *  Parsing is case insensitive.
     * </ul>
     * !(p)
     * As this formatter has an optional element, it may be necessary to parse using
     * {@link DateTimeFormatter#parseBest}.
     * !(p)
     * The returned formatter has no override chronology or zone.
     * It uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    public __gshared DateTimeFormatter ISO_TIME ;
    
    //-----------------------------------------------------------------------
    /**
     * The ISO date-time formatter that formats or parses a date-time without
     * an offset, such as '2011-12-03T10:15:30'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 extended offset date-time format.
     * The format consists of:
     * !(ul)
     * !(li)The {@link #ISO_LOCAL_DATE}
     * !(li)The letter 'T'. Parsing is case insensitive.
     * !(li)The {@link #ISO_LOCAL_TIME}
     * </ul>
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    public __gshared DateTimeFormatter ISO_LOCAL_DATE_TIME ;
 

    //-----------------------------------------------------------------------
    /**
     * The ISO date-time formatter that formats or parses a date-time with an
     * offset, such as '2011-12-03T10:15:30+01:00'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 extended offset date-time format.
     * The format consists of:
     * !(ul)
     * !(li)The {@link #ISO_LOCAL_DATE_TIME}
     * !(li)The {@link ZoneOffset#getId() offset ID}. If the offset has seconds then
     *  they will be handled even though this is not part of the ISO-8601 standard.
     *  The offset parsing is lenient, which allows the minutes and seconds to be optional.
     *  Parsing is case insensitive.
     * </ul>
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    public __gshared DateTimeFormatter ISO_OFFSET_DATE_TIME ;


    //-----------------------------------------------------------------------
    /**
     * The ISO-like date-time formatter that formats or parses a date-time with
     * offset and zone, such as '2011-12-03T10:15:30+01:00[Europe/Paris]'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * a format that extends the ISO-8601 extended offset date-time format
     * to add the time-zone.
     * The section _in square brackets is not part of the ISO-8601 standard.
     * The format consists of:
     * !(ul)
     * !(li)The {@link #ISO_OFFSET_DATE_TIME}
     * !(li)If the zone ID is not available or is a {@code ZoneOffset} then the format is complete.
     * !(li)An open square bracket '['.
     * !(li)The {@link ZoneId#getId() zone ID}. This is not part of the ISO-8601 standard.
     *  Parsing is case sensitive.
     * !(li)A close square bracket ']'.
     * </ul>
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    public __gshared DateTimeFormatter ISO_ZONED_DATE_TIME ;

    //-----------------------------------------------------------------------
    /**
     * The ISO-like date-time formatter that formats or parses a date-time with
     * the offset and zone if available, such as '2011-12-03T10:15:30',
     * '2011-12-03T10:15:30+01:00' or '2011-12-03T10:15:30+01:00[Europe/Paris]'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 extended local or offset date-time format, as well as the
     * extended non-ISO form specifying the time-zone.
     * The format consists of:
     * !(ul)
     * !(li)The {@link #ISO_LOCAL_DATE_TIME}
     * !(li)If the offset is not available to format or parse then the format is complete.
     * !(li)The {@link ZoneOffset#getId() offset ID}. If the offset has seconds then
     *  they will be handled even though this is not part of the ISO-8601 standard.
     * !(li)If the zone ID is not available or is a {@code ZoneOffset} then the format is complete.
     * !(li)An open square bracket '['.
     * !(li)The {@link ZoneId#getId() zone ID}. This is not part of the ISO-8601 standard.
     *  Parsing is case sensitive.
     * !(li)A close square bracket ']'.
     * </ul>
     * !(p)
     * As this formatter has an optional element, it may be necessary to parse using
     * {@link DateTimeFormatter#parseBest}.
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    public __gshared DateTimeFormatter ISO_DATE_TIME ;


    //-----------------------------------------------------------------------
    /**
     * The ISO date formatter that formats or parses the ordinal date
     * without an offset, such as '2012-337'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 extended ordinal date format.
     * The format consists of:
     * !(ul)
     * !(li)Four digits or more for the {@link ChronoField#YEAR year}.
     * Years _in the range 0000 to 9999 will be pre-padded by zero to ensure four digits.
     * Years outside that range will have a prefixed positive or negative symbol.
     * !(li)A dash
     * !(li)Three digits for the {@link ChronoField#DAY_OF_YEAR day-of-year}.
     *  This is pre-padded by zero to ensure three digits.
     * !(li)If the offset is not available to format or parse then the format is complete.
     * !(li)The {@link ZoneOffset#getId() offset ID}. If the offset has seconds then
     *  they will be handled even though this is not part of the ISO-8601 standard.
     *  Parsing is case insensitive.
     * </ul>
     * !(p)
     * As this formatter has an optional element, it may be necessary to parse using
     * {@link DateTimeFormatter#parseBest}.
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    public __gshared DateTimeFormatter ISO_ORDINAL_DATE ;

    //-----------------------------------------------------------------------
    /**
     * The ISO date formatter that formats or parses the week-based date
     * without an offset, such as '2012-W48-6'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 extended week-based date format.
     * The format consists of:
     * !(ul)
     * !(li)Four digits or more for the {@link IsoFields#WEEK_BASED_YEAR week-based-year}.
     * Years _in the range 0000 to 9999 will be pre-padded by zero to ensure four digits.
     * Years outside that range will have a prefixed positive or negative symbol.
     * !(li)A dash
     * !(li)The letter 'W'. Parsing is case insensitive.
     * !(li)Two digits for the {@link IsoFields#WEEK_OF_WEEK_BASED_YEAR week-of-week-based-year}.
     *  This is pre-padded by zero to ensure three digits.
     * !(li)A dash
     * !(li)One digit for the {@link ChronoField#DAY_OF_WEEK day-of-week}.
     *  The value run from Monday (1) to Sunday (7).
     * !(li)If the offset is not available to format or parse then the format is complete.
     * !(li)The {@link ZoneOffset#getId() offset ID}. If the offset has seconds then
     *  they will be handled even though this is not part of the ISO-8601 standard.
     *  Parsing is case insensitive.
     * </ul>
     * !(p)
     * As this formatter has an optional element, it may be necessary to parse using
     * {@link DateTimeFormatter#parseBest}.
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    public __gshared DateTimeFormatter ISO_WEEK_DATE ;


    //-----------------------------------------------------------------------
    /**
     * The ISO instant formatter that formats or parses an instant _in UTC,
     * such as '2011-12-03T10:15:30Z'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 instant format.
     * When formatting, the instant will always be suffixed by 'Z' to indicate UTC.
     * The second-of-minute is always output.
     * The nano-of-second outputs zero, three, six or nine digits as necessary.
     * When parsing, the behaviour of {@link DateTimeFormatterBuilder#appendOffsetId()}
     * will be used to parse the offset, converting the instant to UTC as necessary.
     * The time to at least the seconds field is required.
     * Fractional seconds from zero to nine are parsed.
     * The localized decimal style is not used.
     * !(p)
     * This is a special case formatter intended to allow a human readable form
     * of an {@link hunt.time.Instant}. The {@code Instant} class is designed to
     * only represent a point _in time and internally stores a value _in nanoseconds
     * from a fixed epoch of 1970-01-01Z. As such, an {@code Instant} cannot be
     * formatted as a date or time without providing some form of time-zone.
     * This formatter allows the {@code Instant} to be formatted, by providing
     * a suitable conversion using {@code ZoneOffset.UTC}.
     * !(p)
     * The format consists of:
     * !(ul)
     * !(li)The {@link #ISO_OFFSET_DATE_TIME} where the instant is converted from
     *  {@link ChronoField#INSTANT_SECONDS} and {@link ChronoField#NANO_OF_SECOND}
     *  using the {@code UTC} offset. Parsing is case insensitive.
     * </ul>
     * !(p)
     * The returned formatter has no override chronology or zone.
     * It uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    public __gshared DateTimeFormatter ISO_INSTANT ;

    //-----------------------------------------------------------------------
    /**
     * The ISO date formatter that formats or parses a date without an
     * offset, such as '20111203'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 basic local date format.
     * The format consists of:
     * !(ul)
     * !(li)Four digits for the {@link ChronoField#YEAR year}.
     *  Only years _in the range 0000 to 9999 are supported.
     * !(li)Two digits for the {@link ChronoField#MONTH_OF_YEAR month-of-year}.
     *  This is pre-padded by zero to ensure two digits.
     * !(li)Two digits for the {@link ChronoField#DAY_OF_MONTH day-of-month}.
     *  This is pre-padded by zero to ensure two digits.
     * !(li)If the offset is not available to format or parse then the format is complete.
     * !(li)The {@link ZoneOffset#getId() offset ID} without colons. If the offset has
     *  seconds then they will be handled even though this is not part of the ISO-8601 standard.
     *  The offset parsing is lenient, which allows the minutes and seconds to be optional.
     *  Parsing is case insensitive.
     * </ul>
     * !(p)
     * As this formatter has an optional element, it may be necessary to parse using
     * {@link DateTimeFormatter#parseBest}.
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    public __gshared DateTimeFormatter BASIC_ISO_DATE ;

    //-----------------------------------------------------------------------
    /**
     * The RFC-1123 date-time formatter, such as 'Tue, 3 Jun 2008 11:05:30 GMT'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * most of the RFC-1123 format.
     * RFC-1123 updates RFC-822 changing the year from two digits to four.
     * This implementation requires a four digit year.
     * This implementation also does not handle North American or military zone
     * names, only 'GMT' and offset amounts.
     * !(p)
     * The format consists of:
     * !(ul)
     * !(li)If the day-of-week is not available to format or parse then jump to day-of-month.
     * !(li)Three letter {@link ChronoField#DAY_OF_WEEK day-of-week} _in English.
     * !(li)A comma
     * !(li)A space
     * !(li)One or two digits for the {@link ChronoField#DAY_OF_MONTH day-of-month}.
     * !(li)A space
     * !(li)Three letter {@link ChronoField#MONTH_OF_YEAR month-of-year} _in English.
     * !(li)A space
     * !(li)Four digits for the {@link ChronoField#YEAR year}.
     *  Only years _in the range 0000 to 9999 are supported.
     * !(li)A space
     * !(li)Two digits for the {@link ChronoField#HOUR_OF_DAY hour-of-day}.
     *  This is pre-padded by zero to ensure two digits.
     * !(li)A colon
     * !(li)Two digits for the {@link ChronoField#MINUTE_OF_HOUR minute-of-hour}.
     *  This is pre-padded by zero to ensure two digits.
     * !(li)If the second-of-minute is not available then jump to the next space.
     * !(li)A colon
     * !(li)Two digits for the {@link ChronoField#SECOND_OF_MINUTE second-of-minute}.
     *  This is pre-padded by zero to ensure two digits.
     * !(li)A space
     * !(li)The {@link ZoneOffset#getId() offset ID} without colons or seconds.
     *  An offset of zero uses "GMT". North American zone names and military zone names are not handled.
     * </ul>
     * !(p)
     * Parsing is case insensitive.
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#SMART SMART} resolver style.
     */
    public __gshared DateTimeFormatter RFC_1123_DATE_TIME ;
    // shared static this()
    // {
    // //      ISO_LOCAL_DATE = new DateTimeFormatter();
   
    // //  ISO_OFFSET_DATE = new DateTimeFormatter();
 
    // //  ISO_DATE = new DateTimeFormatter();
    
    // //  ISO_LOCAL_TIME = new DateTimeFormatter();
   
    // //  ISO_OFFSET_TIME = new DateTimeFormatter();
    
    // //  ISO_TIME = new DateTimeFormatter();
   
    // //  ISO_LOCAL_DATE_TIME = new DateTimeFormatter();
 
    // //  ISO_OFFSET_DATE_TIME = new DateTimeFormatter();

    // //  ISO_ZONED_DATE_TIME = new DateTimeFormatter();

    // //  ISO_DATE_TIME = new DateTimeFormatter();

    // //  ISO_ORDINAL_DATE = new DateTimeFormatter();

    // //  ISO_WEEK_DATE = new DateTimeFormatter();
    
    // //  ISO_INSTANT = new DateTimeFormatter();
    
    // //  BASIC_ISO_DATE = new DateTimeFormatter();
    
    // //  RFC_1123_DATE_TIME = new DateTimeFormatter();

    //  PARSED_EXCESS_DAYS = new class TemporalQuery!(Period){
    //     Period queryFrom(TemporalAccessor t)
    //     {
    //         if (cast(Parsed)(t) !is null) {
    //         return (cast(Parsed) t).excessDays;
    //         } else {
    //             return Period.ZERO;
    //         }
    //     }
    //     };

    //     PARSED_LEAP_SECOND = new class TemporalQuery!(Boolean) {
    //         Boolean queryFrom(TemporalAccessor t)
    //         {
    //             if (cast(Parsed)(t) !is null) {
    //                 return new Boolean((cast(Parsed) t).leapSecond);
    //             } else {
    //                 return Boolean.FALSE;
    //             }
    //         }
    //     };
    // }
    // static this(){

    //     BASIC_ISO_DATE = new DateTimeFormatterBuilder()
    //             .parseCaseInsensitive()
    //             .appendValue(ChronoField.YEAR, 4)
    //             .appendValue(ChronoField.MONTH_OF_YEAR, 2)
    //             .appendValue(ChronoField.DAY_OF_MONTH, 2)
    //             .optionalStart()
    //             .parseLenient()
    //             .appendOffset("+HHMMss", "Z")
    //             .parseStrict()
    //             .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);

    //     ISO_INSTANT = new DateTimeFormatterBuilder()
    //             .parseCaseInsensitive()
    //             .appendInstant()
    //             .toFormatter(ResolverStyle.STRICT, null);

    //     ISO_WEEK_DATE = new DateTimeFormatterBuilder()
    //             .parseCaseInsensitive()
    //             .appendValue(IsoFields.WEEK_BASED_YEAR, 4, 10, SignStyle.EXCEEDS_PAD)
    //             .appendLiteral("-W")
    //             .appendValue(IsoFields.WEEK_OF_WEEK_BASED_YEAR, 2)
    //             .appendLiteral('-')
    //             .appendValue(ChronoField.DAY_OF_WEEK, 1)
    //             .optionalStart()
    //             .appendOffsetId()
    //             .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);

    //     ISO_ORDINAL_DATE = new DateTimeFormatterBuilder()
    //             .parseCaseInsensitive()
    //             .appendValue(ChronoField.YEAR, 4, 10, SignStyle.EXCEEDS_PAD)
    //             .appendLiteral('-')
    //             .appendValue(ChronoField.DAY_OF_YEAR, 3)
    //             .optionalStart()
    //             .appendOffsetId()
    //             .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);

    //     ISO_DATE_TIME = new DateTimeFormatterBuilder()
    //             .append(ISO_LOCAL_DATE_TIME)
    //             .optionalStart()
    //             .appendOffsetId()
    //             .optionalStart()
    //             .appendLiteral('[')
    //             .parseCaseSensitive()
    //             .appendZoneRegionId()
    //             .appendLiteral(']')
    //             .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);

    //     ISO_ZONED_DATE_TIME = new DateTimeFormatterBuilder()
    //             .append(ISO_OFFSET_DATE_TIME)
    //             .optionalStart()
    //             .appendLiteral('[')
    //             .parseCaseSensitive()
    //             .appendZoneRegionId()
    //             .appendLiteral(']')
    //             .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);

    //     ISO_OFFSET_DATE_TIME = new DateTimeFormatterBuilder()
    //             .parseCaseInsensitive()
    //             .append(ISO_LOCAL_DATE_TIME)
    //             .parseLenient()
    //             .appendOffsetId()
    //             .parseStrict()
    //             .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);

    //     ISO_LOCAL_DATE_TIME = new DateTimeFormatterBuilder()
    //             .parseCaseInsensitive()
    //             .append(ISO_LOCAL_DATE)
    //             .appendLiteral('T')
    //             .append(ISO_LOCAL_TIME)
    //             .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);

    //     ISO_TIME = new DateTimeFormatterBuilder()
    //             .parseCaseInsensitive()
    //             .append(ISO_LOCAL_TIME)
    //             .optionalStart()
    //             .appendOffsetId()
    //             .toFormatter(ResolverStyle.STRICT, null);

    //     ISO_OFFSET_TIME = new DateTimeFormatterBuilder()
    //             .parseCaseInsensitive()
    //             .append(ISO_LOCAL_TIME)
    //             .appendOffsetId()
    //             .toFormatter(ResolverStyle.STRICT, null);

    //     ISO_LOCAL_TIME = new DateTimeFormatterBuilder()
    //             .appendValue(ChronoField.HOUR_OF_DAY, 2)
    //             .appendLiteral(':')
    //             .appendValue(ChronoField.MINUTE_OF_HOUR, 2)
    //             .optionalStart()
    //             .appendLiteral(':')
    //             .appendValue(ChronoField.SECOND_OF_MINUTE, 2)
    //             .optionalStart()
    //             .appendFraction(ChronoField.NANO_OF_SECOND, 0, 9, true)
    //             .toFormatter(ResolverStyle.STRICT, null);

    //     ISO_DATE = new DateTimeFormatterBuilder()
    //             .parseCaseInsensitive()
    //             .append(ISO_LOCAL_DATE)
    //             .optionalStart()
    //             .appendOffsetId()
    //             .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);

    //     ISO_OFFSET_DATE = new DateTimeFormatterBuilder()
    //             .parseCaseInsensitive()
    //             .append(ISO_LOCAL_DATE)
    //             .appendOffsetId()
    //             .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);

    //     ISO_LOCAL_DATE = new DateTimeFormatterBuilder()
    //             .appendValue(ChronoField.YEAR, 4, 10, SignStyle.EXCEEDS_PAD)
    //             .appendLiteral('-')
    //             .appendValue(ChronoField.MONTH_OF_YEAR, 2)
    //             .appendLiteral('-')
    //             .appendValue(ChronoField.DAY_OF_MONTH, 2)
    //             .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);
    //     // manually code maps to ensure correct data always used
    //     // (locale data can be changed by application code)
    //     Map!(Long, string) dow = new HashMap!(Long, string)();
    //     dow.put(new Long(1L), "Mon");
    //     dow.put(new Long(2L), "Tue");
    //     dow.put(new Long(3L), "Wed");
    //     dow.put(new Long(4L), "Thu");
    //     dow.put(new Long(5L), "Fri");
    //     dow.put(new Long(6L), "Sat");
    //     dow.put(new Long(7L), "Sun");
    //     Map!(Long, string) moy = new HashMap!(Long, string)();
    //     moy.put(new Long(1L), "Jan");
    //     moy.put(new Long(2L), "Feb");
    //     moy.put(new Long(3L), "Mar");
    //     moy.put(new Long(4L), "Apr");
    //     moy.put(new Long(5L), "May");
    //     moy.put(new Long(6L), "Jun");
    //     moy.put(new Long(7L), "Jul");
    //     moy.put(new Long(8L), "Aug");
    //     moy.put(new Long(9L), "Sep");
    //     moy.put(new Long(10L), "Oct");
    //     moy.put(new Long(11L), "Nov");
    //     moy.put(new Long(12L), "Dec");
    //     RFC_1123_DATE_TIME = new DateTimeFormatterBuilder()
    //             .parseCaseInsensitive()
    //             .parseLenient()
    //             .optionalStart()
    //             .appendText(ChronoField.DAY_OF_WEEK, dow)
    //             .appendLiteral(", ")
    //             .optionalEnd()
    //             .appendValue(ChronoField.DAY_OF_MONTH, 1, 2, SignStyle.NOT_NEGATIVE)
    //             .appendLiteral(' ')
    //             .appendText(ChronoField.MONTH_OF_YEAR, moy)
    //             .appendLiteral(' ')
    //             .appendValue(ChronoField.YEAR, 4)  // 2 digit year not handled
    //             .appendLiteral(' ')
    //             .appendValue(ChronoField.HOUR_OF_DAY, 2)
    //             .appendLiteral(':')
    //             .appendValue(ChronoField.MINUTE_OF_HOUR, 2)
    //             .optionalStart()
    //             .appendLiteral(':')
    //             .appendValue(ChronoField.SECOND_OF_MINUTE, 2)
    //             .optionalEnd()
    //             .appendLiteral(' ')
    //             .appendOffset("+HHMM", "GMT")  // should handle UT/Z/EST/EDT/CST/CDT/MST/MDT/PST/MDT
    //             .toFormatter(ResolverStyle.SMART, IsoChronology.INSTANCE);
    // }

    //-----------------------------------------------------------------------
    /**
     * A query that provides access to the excess days that were parsed.
     * !(p)
     * This returns a singleton {@linkplain TemporalQuery query} that provides
     * access to additional information from the parse. The query always returns
     * a non-null period, with a zero period returned instead of null.
     * !(p)
     * There are two situations where this query may return a non-zero period.
     * !(ul)
     * !(li)If the {@code ResolverStyle} is {@code LENIENT} and a time is parsed
     *  without a date, then the complete result of the parse consists of a
     *  {@code LocalTime} and an excess {@code Period} _in days.
     *
     * !(li)If the {@code ResolverStyle} is {@code SMART} and a time is parsed
     *  without a date where the time is 24:00:00, then the complete result of
     *  the parse consists of a {@code LocalTime} of 00:00:00 and an excess
     *  {@code Period} of one day.
     * </ul>
     * !(p)
     * In both cases, if a complete {@code ChronoLocalDateTime} or {@code Instant}
     * is parsed, then the excess days are added to the date part.
     * As a result, this query will return a zero period.
     * !(p)
     * The {@code SMART} behaviour handles the common "end of day" 24:00 value.
     * Processing _in {@code LENIENT} mode also produces the same result:
     * !(pre)
     *  Text to parse        Parsed object                         Excess days
     *  "2012-12-03T00:00"   LocalDateTime.of(2012, 12, 3, 0, 0)   ZERO
     *  "2012-12-03T24:00"   LocalDateTime.of(2012, 12, 4, 0, 0)   ZERO
     *  "00:00"              LocalTime.of(0, 0)                    ZERO
     *  "24:00"              LocalTime.of(0, 0)                    Period.ofDays(1)
     * </pre>
     * The query can be used as follows:
     * !(pre)
     *  TemporalAccessor parsed = formatter.parse(str);
     *  LocalTime time = parsed.query(LocalTime.from);
     *  Period extraDays = parsed.query(DateTimeFormatter.parsedExcessDays());
     * </pre>
     * @return a query that provides access to the excess days that were parsed
     */
    public static final TemporalQuery!(Period) parsedExcessDays() {
        return PARSED_EXCESS_DAYS;
    }
    __gshared TemporalQuery!(Period) PARSED_EXCESS_DAYS;

    /**
     * A query that provides access to whether a leap-second was parsed.
     * !(p)
     * This returns a singleton {@linkplain TemporalQuery query} that provides
     * access to additional information from the parse. The query always returns
     * a non-null bool, true if parsing saw a leap-second, false if not.
     * !(p)
     * Instant parsing handles the special "leap second" time of '23:59:60'.
     * Leap seconds occur at '23:59:60' _in the UTC time-zone, but at other
     * local times _in different time-zones. To avoid this potential ambiguity,
     * the handling of leap-seconds is limited to
     * {@link DateTimeFormatterBuilder#appendInstant()}, as that method
     * always parses the instant with the UTC zone offset.
     * !(p)
     * If the time '23:59:60' is received, then a simple conversion is applied,
     * replacing the second-of-minute of 60 with 59. This query can be used
     * on the parse result to determine if the leap-second adjustment was made.
     * The query will return {@code true} if it did adjust to remove the
     * leap-second, and {@code false} if not. Note that applying a leap-second
     * smoothing mechanism, such as UTC-SLS, is the responsibility of the
     * application, as follows:
     * !(pre)
     *  TemporalAccessor parsed = formatter.parse(str);
     *  Instant instant = parsed.query(Instant::from);
     *  if (parsed.query(DateTimeFormatter.parsedLeapSecond())) {
     *    // validate leap-second is correct and apply correct smoothing
     *  }
     * </pre>
     * @return a query that provides access to whether a leap-second was parsed
     */
    public static final TemporalQuery!(Boolean) parsedLeapSecond() {
        return PARSED_LEAP_SECOND;
    }
    __gshared TemporalQuery!(Boolean) PARSED_LEAP_SECOND;

    //-----------------------------------------------------------------------
    /**
     * Constructor.
     *
     * @param printerParser  the printer/parser to use, not null
     * @param locale  the locale to use, not null
     * @param decimalStyle  the DecimalStyle to use, not null
     * @param resolverStyle  the resolver style to use, not null
     * @param resolverFields  the fields to use during resolving, null for all fields
     * @param chrono  the chronology to use, null for no override
     * @param zone  the zone to use, null for no override
     */
    this(DateTimeFormatterBuilder.CompositePrinterParser printerParser,
            Locale locale, DecimalStyle decimalStyle,
            ResolverStyle resolverStyle, Set!(TemporalField) resolverFields,
            Chronology chrono, ZoneId zone) {
        this.printerParser = printerParser;
        this.resolverFields = resolverFields;
        this.locale = locale;
        this.decimalStyle = decimalStyle;
        this.resolverStyle = resolverStyle;
        this.chrono = chrono;
        this.zone = zone;
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the locale to be used during formatting.
     * !(p)
     * This is used to lookup any part of the formatter needing specific
     * localization, such as the text or localized pattern.
     *
     * @return the locale of this formatter, not null
     */
    public Locale getLocale() {
        return locale;
    }

    /**
     * Returns a copy of this formatter with a new locale.
     * !(p)
     * This is used to lookup any part of the formatter needing specific
     * localization, such as the text or localized pattern.
     * !(p)
     * The locale is stored as passed _in, without further processing.
     * If the locale has <a href="../../util/Locale.html#def_locale_extension">
     * Unicode extensions</a>, they may be used later _in text
     * processing. To set the chronology, time-zone and decimal style from
     * unicode extensions, see {@link #localizedBy localizedBy()}.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param locale  the new locale, not null
     * @return a formatter based on this formatter with the requested locale, not null
     * @see #localizedBy(Locale)
     */
    public DateTimeFormatter withLocale(Locale locale) {
        if (this.locale == (locale)) {
            return this;
        }
        return new DateTimeFormatter(printerParser, locale, decimalStyle, resolverStyle, resolverFields, chrono, zone);
    }

    /**
     * Returns a copy of this formatter with localized values of the locale,
     * calendar, region, decimal style and/or timezone, that supercede values _in
     * this formatter.
     * !(p)
     * This is used to lookup any part of the formatter needing specific
     * localization, such as the text or localized pattern. If the locale contains the
     * "ca" (calendar), "nu" (numbering system), "rg" (region override), and/or
     * "tz" (timezone)
     * <a href="../../util/Locale.html#def_locale_extension">Unicode extensions</a>,
     * the chronology, numbering system and/or the zone are overridden. If both "ca"
     * and "rg" are specified, the chronology from the "ca" extension supersedes the
     * implicit one from the "rg" extension. Same is true for the "nu" extension.
     * !(p)
     * Unlike the {@link #withLocale withLocale} method, the call to this method may
     * produce a different formatter depending on the order of method chaining with
     * other withXXXX() methods.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param locale  the locale, not null
     * @return a formatter based on this formatter with localized values of
     *      the calendar, decimal style and/or timezone, that supercede values _in this
     *      formatter.
     * @see #withLocale(Locale)
     * @since 10
     */
     ///@gxc
    // public DateTimeFormatter localizedBy(Locale locale) {
    //     if (this.locale == (locale)) {
    //         return this;
    //     }

    //     // Check for decimalStyle/chronology/timezone _in locale object
    //     Chronology c = locale.getUnicodeLocaleType("ca") !is null ?
    //                    Chronology.ofLocale(locale) : chrono;
    //     DecimalStyle ds = locale.getUnicodeLocaleType("nu") !is null ?
    //                    DecimalStyle.of(locale) : decimalStyle;
    //     string tzType = locale.getUnicodeLocaleType("tz");
    //     ZoneId z  = tzType !is null ?
    //                 TimeZoneNameUtility.convertLDMLShortID(tzType)
    //                     .map(ZoneId.of)
    //                     .orElse(zone) :
    //                 zone;
    //     return new DateTimeFormatter(printerParser, locale, ds, resolverStyle, resolverFields, c, z);
    // }

    //-----------------------------------------------------------------------
    /**
     * Gets the DecimalStyle to be used during formatting.
     *
     * @return the locale of this formatter, not null
     */
    public DecimalStyle getDecimalStyle() {
        return decimalStyle;
    }

    /**
     * Returns a copy of this formatter with a new DecimalStyle.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param decimalStyle  the new DecimalStyle, not null
     * @return a formatter based on this formatter with the requested DecimalStyle, not null
     */
    public DateTimeFormatter withDecimalStyle(DecimalStyle decimalStyle) {
        if (this.decimalStyle == (decimalStyle)) {
            return this;
        }
        return new DateTimeFormatter(printerParser, locale, decimalStyle, resolverStyle, resolverFields, chrono, zone);
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the overriding chronology to be used during formatting.
     * !(p)
     * This returns the override chronology, used to convert dates.
     * By default, a formatter has no override chronology, returning null.
     * See {@link #withChronology(Chronology)} for more details on overriding.
     *
     * @return the override chronology of this formatter, null if no override
     */
    public Chronology getChronology() {
        return chrono;
    }

    /**
     * Returns a copy of this formatter with a new override chronology.
     * !(p)
     * This returns a formatter with similar state to this formatter but
     * with the override chronology set.
     * By default, a formatter has no override chronology, returning null.
     * !(p)
     * If an override is added, then any date that is formatted or parsed will be affected.
     * !(p)
     * When formatting, if the temporal object contains a date, then it will
     * be converted to a date _in the override chronology.
     * Whether the temporal contains a date is determined by querying the
     * {@link ChronoField#EPOCH_DAY EPOCH_DAY} field.
     * Any time or zone will be retained unaltered unless overridden.
     * !(p)
     * If the temporal object does not contain a date, but does contain one
     * or more {@code ChronoField} date fields, then a {@code DateTimeException}
     * is thrown. In all other cases, the override chronology is added to the temporal,
     * replacing any previous chronology, but without changing the date/time.
     * !(p)
     * When parsing, there are two distinct cases to consider.
     * If a chronology has been parsed directly from the text, perhaps because
     * {@link DateTimeFormatterBuilder#appendChronologyId()} was used, then
     * this override chronology has no effect.
     * If no zone has been parsed, then this override chronology will be used
     * to interpret the {@code ChronoField} values into a date according to the
     * date resolving rules of the chronology.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param chrono  the new chronology, null if no override
     * @return a formatter based on this formatter with the requested override chronology, not null
     */
    public DateTimeFormatter withChronology(Chronology chrono) {
        if (this.chrono !is null && (this.chrono == chrono)) {
            return this;
        }
        return new DateTimeFormatter(printerParser, locale, decimalStyle, resolverStyle, resolverFields, chrono, zone);
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the overriding zone to be used during formatting.
     * !(p)
     * This returns the override zone, used to convert instants.
     * By default, a formatter has no override zone, returning null.
     * See {@link #withZone(ZoneId)} for more details on overriding.
     *
     * @return the override zone of this formatter, null if no override
     */
    public ZoneId getZone() {
        return zone;
    }

    /**
     * Returns a copy of this formatter with a new override zone.
     * !(p)
     * This returns a formatter with similar state to this formatter but
     * with the override zone set.
     * By default, a formatter has no override zone, returning null.
     * !(p)
     * If an override is added, then any instant that is formatted or parsed will be affected.
     * !(p)
     * When formatting, if the temporal object contains an instant, then it will
     * be converted to a zoned date-time using the override zone.
     * Whether the temporal is an instant is determined by querying the
     * {@link ChronoField#INSTANT_SECONDS INSTANT_SECONDS} field.
     * If the input has a chronology then it will be retained unless overridden.
     * If the input does not have a chronology, such as {@code Instant}, then
     * the ISO chronology will be used.
     * !(p)
     * If the temporal object does not contain an instant, but does contain
     * an offset then an additional check is made. If the normalized override
     * zone is an offset that differs from the offset of the temporal, then
     * a {@code DateTimeException} is thrown. In all other cases, the override
     * zone is added to the temporal, replacing any previous zone, but without
     * changing the date/time.
     * !(p)
     * When parsing, there are two distinct cases to consider.
     * If a zone has been parsed directly from the text, perhaps because
     * {@link DateTimeFormatterBuilder#appendZoneId()} was used, then
     * this override zone has no effect.
     * If no zone has been parsed, then this override zone will be included _in
     * the result of the parse where it can be used to build instants and date-times.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param zone  the new override zone, null if no override
     * @return a formatter based on this formatter with the requested override zone, not null
     */
    public DateTimeFormatter withZone(ZoneId zone) {
        if ((this.zone == zone)) {
            return this;
        }
        return new DateTimeFormatter(printerParser, locale, decimalStyle, resolverStyle, resolverFields, chrono, zone);
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the resolver style to use during parsing.
     * !(p)
     * This returns the resolver style, used during the second phase of parsing
     * when fields are resolved into dates and times.
     * By default, a formatter has the {@link ResolverStyle#SMART SMART} resolver style.
     * See {@link #withResolverStyle(ResolverStyle)} for more details.
     *
     * @return the resolver style of this formatter, not null
     */
    public ResolverStyle getResolverStyle() {
        return resolverStyle;
    }

    /**
     * Returns a copy of this formatter with a new resolver style.
     * !(p)
     * This returns a formatter with similar state to this formatter but
     * with the resolver style set. By default, a formatter has the
     * {@link ResolverStyle#SMART SMART} resolver style.
     * !(p)
     * Changing the resolver style only has an effect during parsing.
     * Parsing a text string occurs _in two phases.
     * Phase 1 is a basic text parse according to the fields added to the builder.
     * Phase 2 resolves the parsed field-value pairs into date and/or time objects.
     * The resolver style is used to control how phase 2, resolving, happens.
     * See {@code ResolverStyle} for more information on the options available.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param resolverStyle  the new resolver style, not null
     * @return a formatter based on this formatter with the requested resolver style, not null
     */
    public DateTimeFormatter withResolverStyle(ResolverStyle resolverStyle) {
        assert(resolverStyle, "resolverStyle");
        if ((this.resolverStyle == resolverStyle)) {
            return this;
        }
        return new DateTimeFormatter(printerParser, locale, decimalStyle, resolverStyle, resolverFields, chrono, zone);
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the resolver fields to use during parsing.
     * !(p)
     * This returns the resolver fields, used during the second phase of parsing
     * when fields are resolved into dates and times.
     * By default, a formatter has no resolver fields, and thus returns null.
     * See {@link #withResolverFields(Set)} for more details.
     *
     * @return the immutable set of resolver fields of this formatter, null if no fields
     */
    public Set!(TemporalField) getResolverFields() {
        return resolverFields;
    }

    /**
     * Returns a copy of this formatter with a new set of resolver fields.
     * !(p)
     * This returns a formatter with similar state to this formatter but with
     * the resolver fields set. By default, a formatter has no resolver fields.
     * !(p)
     * Changing the resolver fields only has an effect during parsing.
     * Parsing a text string occurs _in two phases.
     * Phase 1 is a basic text parse according to the fields added to the builder.
     * Phase 2 resolves the parsed field-value pairs into date and/or time objects.
     * The resolver fields are used to filter the field-value pairs between phase 1 and 2.
     * !(p)
     * This can be used to select between two or more ways that a date or time might
     * be resolved. For example, if the formatter consists of year, month, day-of-month
     * and day-of-year, then there are two ways to resolve a date.
     * Calling this method with the arguments {@link ChronoField#YEAR YEAR} and
     * {@link ChronoField#DAY_OF_YEAR DAY_OF_YEAR} will ensure that the date is
     * resolved using the year and day-of-year, effectively meaning that the month
     * and day-of-month are ignored during the resolving phase.
     * !(p)
     * In a similar manner, this method can be used to ignore secondary fields that
     * would otherwise be cross-checked. For example, if the formatter consists of year,
     * month, day-of-month and day-of-week, then there is only one way to resolve a
     * date, but the parsed value for day-of-week will be cross-checked against the
     * resolved date. Calling this method with the arguments {@link ChronoField#YEAR YEAR},
     * {@link ChronoField#MONTH_OF_YEAR MONTH_OF_YEAR} and
     * {@link ChronoField#DAY_OF_MONTH DAY_OF_MONTH} will ensure that the date is
     * resolved correctly, but without any cross-check for the day-of-week.
     * !(p)
     * In implementation terms, this method behaves as follows. The result of the
     * parsing phase can be considered to be a map of field to value. The behavior
     * of this method is to cause that map to be filtered between phase 1 and 2,
     * removing all fields other than those specified as arguments to this method.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param resolverFields  the new set of resolver fields, null if no fields
     * @return a formatter based on this formatter with the requested resolver style, not null
     */
     ///@gxc
    // public DateTimeFormatter withResolverFields(TemporalField[] resolverFields...) {
    //     Set!(TemporalField) fields = null;
    //     if (resolverFields !is null) {
    //         // Set.of cannot be used because it is hostile to nulls and duplicate elements
    //         auto hs = new HashSet!TemporalField();
    //         foreach( t ; resolverFields)
    //             hs.add(t);
    //         fields = Collections.unmodifiableSet(hs);
    //     }
    //     if ((this.resolverFields == fields)) {
    //         return this;
    //     }
    //     return new DateTimeFormatter(printerParser, locale, decimalStyle, resolverStyle, fields, chrono, zone);
    // }

    /**
     * Returns a copy of this formatter with a new set of resolver fields.
     * !(p)
     * This returns a formatter with similar state to this formatter but with
     * the resolver fields set. By default, a formatter has no resolver fields.
     * !(p)
     * Changing the resolver fields only has an effect during parsing.
     * Parsing a text string occurs _in two phases.
     * Phase 1 is a basic text parse according to the fields added to the builder.
     * Phase 2 resolves the parsed field-value pairs into date and/or time objects.
     * The resolver fields are used to filter the field-value pairs between phase 1 and 2.
     * !(p)
     * This can be used to select between two or more ways that a date or time might
     * be resolved. For example, if the formatter consists of year, month, day-of-month
     * and day-of-year, then there are two ways to resolve a date.
     * Calling this method with the arguments {@link ChronoField#YEAR YEAR} and
     * {@link ChronoField#DAY_OF_YEAR DAY_OF_YEAR} will ensure that the date is
     * resolved using the year and day-of-year, effectively meaning that the month
     * and day-of-month are ignored during the resolving phase.
     * !(p)
     * In a similar manner, this method can be used to ignore secondary fields that
     * would otherwise be cross-checked. For example, if the formatter consists of year,
     * month, day-of-month and day-of-week, then there is only one way to resolve a
     * date, but the parsed value for day-of-week will be cross-checked against the
     * resolved date. Calling this method with the arguments {@link ChronoField#YEAR YEAR},
     * {@link ChronoField#MONTH_OF_YEAR MONTH_OF_YEAR} and
     * {@link ChronoField#DAY_OF_MONTH DAY_OF_MONTH} will ensure that the date is
     * resolved correctly, but without any cross-check for the day-of-week.
     * !(p)
     * In implementation terms, this method behaves as follows. The result of the
     * parsing phase can be considered to be a map of field to value. The behavior
     * of this method is to cause that map to be filtered between phase 1 and 2,
     * removing all fields other than those specified as arguments to this method.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param resolverFields  the new set of resolver fields, null if no fields
     * @return a formatter based on this formatter with the requested resolver style, not null
     */
     ///@gxc
    // public DateTimeFormatter withResolverFields(Set!(TemporalField) resolverFields) {
    //     if (Objects == (this.resolverFields, resolverFields)) {
    //         return this;
    //     }
    //     if (resolverFields !is null) {
    //         resolverFields = Collections.unmodifiableSet(new HashSet!()(resolverFields));
    //     }
    //     return new DateTimeFormatter(printerParser, locale, decimalStyle, resolverStyle, resolverFields, chrono, zone);
    // }

    //-----------------------------------------------------------------------
    /**
     * Formats a date-time object using this formatter.
     * !(p)
     * This formats the date-time to a string using the rules of the formatter.
     *
     * @param temporal  the temporal object to format, not null
     * @return the formatted string, not null
     * @throws DateTimeException if an error occurs during formatting
     */
    public string format(TemporalAccessor temporal) {
        StringBuilder buf = new StringBuilder(32);
        formatTo(temporal, buf);
        return buf.toString();
    }

    //-----------------------------------------------------------------------
    /**
     * Formats a date-time object to an {@code Appendable} using this formatter.
     * !(p)
     * This outputs the formatted date-time to the specified destination.
     * {@link Appendable} is a general purpose interface that is implemented by all
     * key character output classes including {@code StringBuffer}, {@code StringBuilder},
     * {@code PrintStream} and {@code Writer}.
     * !(p)
     * Although {@code Appendable} methods throw an {@code IOException}, this method does not.
     * Instead, any {@code IOException} is wrapped _in a runtime exception.
     *
     * @param temporal  the temporal object to format, not null
     * @param appendable  the appendable to format to, not null
     * @throws DateTimeException if an error occurs during formatting
     */
    public void formatTo(TemporalAccessor temporal, Appendable appendable) {
        assert(temporal, "temporal");
        assert(appendable, "appendable");
        try {
            DateTimePrintContext context = new DateTimePrintContext(temporal, this);
            if (cast(StringBuilder)(appendable) !is null) {
                printerParser.format(context, cast(StringBuilder) appendable);
            } else {
                // buffer output to avoid writing to appendable _in case of error
                StringBuilder buf = new StringBuilder(32);
                printerParser.format(context, buf);
                appendable.append(buf.toString);
            }
        } catch (IOException ex) {
            throw new DateTimeException(ex.msg, ex);
        }
    }

    //-----------------------------------------------------------------------
    /**
     * Fully parses the text producing a temporal object.
     * !(p)
     * This parses the entire text producing a temporal object.
     * It is typically more useful to use {@link #parse(string, TemporalQuery)}.
     * The result of this method is {@code TemporalAccessor} which has been resolved,
     * applying basic validation checks to help ensure a valid date-time.
     * !(p)
     * If the parse completes without reading the entire length of the text,
     * or a problem occurs during parsing or merging, then an exception is thrown.
     *
     * @param text  the text to parse, not null
     * @return the parsed temporal object, not null
     * @throws DateTimeParseException if unable to parse the requested result
     */
    public TemporalAccessor parse(string text) {
        assert(text, "text");
        try {
            return parseResolved0(text, null);
        } catch (DateTimeParseException ex) {
            throw ex;
        } catch (RuntimeException ex) {
            throw createError(text, ex);
        }
    }

    /**
     * Parses the text using this formatter, providing control over the text position.
     * !(p)
     * This parses the text without requiring the parse to start from the beginning
     * of the string or finish at the end.
     * The result of this method is {@code TemporalAccessor} which has been resolved,
     * applying basic validation checks to help ensure a valid date-time.
     * !(p)
     * The text will be parsed from the specified start {@code ParsePosition}.
     * The entire length of the text does not have to be parsed, the {@code ParsePosition}
     * will be updated with the index at the end of parsing.
     * !(p)
     * The operation of this method is slightly different to similar methods using
     * {@code ParsePosition} on {@code java.text.Format}. That class will return
     * errors using the error index on the {@code ParsePosition}. By contrast, this
     * method will throw a {@link DateTimeParseException} if an error occurs, with
     * the exception containing the error index.
     * This change _in behavior is necessary due to the increased complexity of
     * parsing and resolving dates/times _in this API.
     * !(p)
     * If the formatter parses the same field more than once with different values,
     * the result will be an error.
     *
     * @param text  the text to parse, not null
     * @param position  the position to parse from, updated with length parsed
     *  and the index of any error, not null
     * @return the parsed temporal object, not null
     * @throws DateTimeParseException if unable to parse the requested result
     * @throws IndexOutOfBoundsException if the position is invalid
     */
    public TemporalAccessor parse(string text, ParsePosition position) {
        assert(text, "text");
        assert(position, "position");
        try {
            return parseResolved0(text, position);
        } catch (DateTimeParseException  ex) {
            throw ex;
        } catch (RuntimeException ex) {
            throw createError(text, ex);
        }
    }

    //-----------------------------------------------------------------------
    /**
     * Fully parses the text producing an object of the specified type.
     * !(p)
     * Most applications should use this method for parsing.
     * It parses the entire text to produce the required date-time.
     * The query is typically a method reference to a {@code from(TemporalAccessor)} method.
     * For example:
     * !(pre)
     *  LocalDateTime dt = parser.parse(str, LocalDateTime.from);
     * </pre>
     * If the parse completes without reading the entire length of the text,
     * or a problem occurs during parsing or merging, then an exception is thrown.
     *
     * @param !(T) the type of the parsed date-time
     * @param text  the text to parse, not null
     * @param query  the query defining the type to parse to, not null
     * @return the parsed date-time, not null
     * @throws DateTimeParseException if unable to parse the requested result
     */
    public  T parse(T)(string text, TemporalQuery!(T) query) {
        assert(text, "text");
        assert(query, "query");
        try {
            return QueryHelper.query!T(parseResolved0(text, null),query);
        } catch (DateTimeParseException ex) {
            throw ex;
        } catch (RuntimeException ex) {
            throw createError(text, ex);
        }
    }

    /**
     * Fully parses the text producing an object of one of the specified types.
     * !(p)
     * This parse method is convenient for use when the parser can handle optional elements.
     * For example, a pattern of 'uuuu-MM-dd HH.mm[ VV]' can be fully parsed to a {@code ZonedDateTime},
     * or partially parsed to a {@code LocalDateTime}.
     * The queries must be specified _in order, starting from the best matching full-parse option
     * and ending with the worst matching minimal parse option.
     * The query is typically a method reference to a {@code from(TemporalAccessor)} method.
     * !(p)
     * The result is associated with the first type that successfully parses.
     * Normally, applications will use {@code instanceof} to check the result.
     * For example:
     * !(pre)
     *  TemporalAccessor dt = parser.parseBest(str, ZonedDateTime::from, LocalDateTime.from);
     *  if (cast(ZonedDateTime)(dt) !is null) {
     *   ...
     *  } else {
     *   ...
     *  }
     * </pre>
     * If the parse completes without reading the entire length of the text,
     * or a problem occurs during parsing or merging, then an exception is thrown.
     *
     * @param text  the text to parse, not null
     * @param queries  the queries defining the types to attempt to parse to,
     *  must implement {@code TemporalAccessor}, not null
     * @return the parsed date-time, not null
     * @throws IllegalArgumentException if less than 2 types are specified
     * @throws DateTimeParseException if unable to parse the requested result
     */
    public TemporalAccessor parseBest(string text, TemporalQuery!(Object)[] queries...) {
        assert(text, "text");
        assert(queries, "queries");
        if (queries.length < 2) {
            throw new IllegalArgumentException("At least two queries must be specified");
        }
        try {
            TemporalAccessor resolved = parseResolved0(text, null);
            foreach(TemporalQuery!(Object) query ; queries) {
                try {
                    return cast(TemporalAccessor) (QueryHelper.query!Object(resolved,query)); ///@gxc
                } catch (RuntimeException ex) {
                    // continue
                }
            }
            throw new DateTimeException("Unable to convert parsed text using any of the specified queries");
        } catch (DateTimeParseException ex) {
            throw ex;
        } catch (RuntimeException ex) {
            throw createError(text, ex);
        }
    }

    private DateTimeParseException createError(string text, RuntimeException ex) {
        string abbr;
        if (text.length > 64) {
            abbr = text[0 .. 64] ~ "...";
        } else {
            abbr = text/* .toString() */;
        }
        return new DateTimeParseException("Text '" ~ abbr ~ "' could not be parsed: " ~ ex.msg, text, 0, ex);
    }

    //-----------------------------------------------------------------------
    /**
     * Parses and resolves the specified text.
     * !(p)
     * This parses to a {@code TemporalAccessor} ensuring that the text is fully parsed.
     *
     * @param text  the text to parse, not null
     * @param position  the position to parse from, updated with length parsed
     *  and the index of any error, null if parsing whole string
     * @return the resolved result of the parse, not null
     * @throws DateTimeParseException if the parse fails
     * @throws DateTimeException if an error occurs while resolving the date or time
     * @throws IndexOutOfBoundsException if the position is invalid
     */
    private TemporalAccessor parseResolved0( string text,  ParsePosition position) {
        ParsePosition pos = (position !is null ? position : new ParsePosition(0));
        DateTimeParseContext context = parseUnresolved0(text, pos);
        if (context is null || pos.getErrorIndex() >= 0 || (position is null && pos.getIndex() < text.length)) {
            string abbr;
            if (text.length > 64) {
                abbr = text[0 .. 64] ~ "...";
            } else {
                abbr = text/* .toString() */;
            }
            if (pos.getErrorIndex() >= 0) {
                throw new DateTimeParseException("Text '" ~ abbr ~ "' could not be parsed at index " ~
                        pos.getErrorIndex().to!string, text, pos.getErrorIndex());
            } else {
                throw new DateTimeParseException("Text '" ~ abbr ~ "' could not be parsed, unparsed text found at index " ~
                        pos.getIndex().to!string, text, pos.getIndex());
            }
        }
        return context.toResolved(resolverStyle, resolverFields);
    }

    /**
     * Parses the text using this formatter, without resolving the result, intended
     * for advanced use cases.
     * !(p)
     * Parsing is implemented as a two-phase operation.
     * First, the text is parsed using the layout defined by the formatter, producing
     * a {@code Map} of field to value, a {@code ZoneId} and a {@code Chronology}.
     * Second, the parsed data is !(em)resolved</em>, by validating, combining and
     * simplifying the various fields into more useful ones.
     * This method performs the parsing stage but not the resolving stage.
     * !(p)
     * The result of this method is {@code TemporalAccessor} which represents the
     * data as seen _in the input. Values are not validated, thus parsing a date string
     * of '2012-00-65' would result _in a temporal with three fields - year of '2012',
     * month of '0' and day-of-month of '65'.
     * !(p)
     * The text will be parsed from the specified start {@code ParsePosition}.
     * The entire length of the text does not have to be parsed, the {@code ParsePosition}
     * will be updated with the index at the end of parsing.
     * !(p)
     * Errors are returned using the error index field of the {@code ParsePosition}
     * instead of {@code DateTimeParseException}.
     * The returned error index will be set to an index indicative of the error.
     * Callers must check for errors before using the result.
     * !(p)
     * If the formatter parses the same field more than once with different values,
     * the result will be an error.
     * !(p)
     * This method is intended for advanced use cases that need access to the
     * internal state during parsing. Typical application code should use
     * {@link #parse(string, TemporalQuery)} or the parse method on the target type.
     *
     * @param text  the text to parse, not null
     * @param position  the position to parse from, updated with length parsed
     *  and the index of any error, not null
     * @return the parsed text, null if the parse results _in an error
     * @throws DateTimeException if some problem occurs during parsing
     * @throws IndexOutOfBoundsException if the position is invalid
     */
    public TemporalAccessor parseUnresolved(string text, ParsePosition position) {
        DateTimeParseContext context = parseUnresolved0(text, position);
        if (context is null) {
            return null;
        }
        return context.toUnresolved();
    }

    private DateTimeParseContext parseUnresolved0(string text, ParsePosition position) {
        assert(text, "text");
        assert(position, "position");
        DateTimeParseContext context = new DateTimeParseContext(this);
        int pos = position.getIndex();
        pos = printerParser.parse(context, text, pos);
        if (pos < 0) {
            position.setErrorIndex(~pos);  // index not updated from input
            return null;
        }
        position.setIndex(pos);  // errorIndex not updated from input
        return context;
    }

    //-----------------------------------------------------------------------
    /**
     * Returns the formatter as a composite printer parser.
     *
     * @param optional  whether the printer/parser should be optional
     * @return the printer/parser, not null
     */
    DateTimeFormatterBuilder.CompositePrinterParser toPrinterParser(bool optional) {
        return printerParser.withOptional(optional);
    }

    /**
     * Returns this formatter as a {@code java.text.Format} instance.
     * !(p)
     * The returned {@link Format} instance will format any {@link TemporalAccessor}
     * and parses to a resolved {@link TemporalAccessor}.
     * !(p)
     * Exceptions will follow the definitions of {@code Format}, see those methods
     * for details about {@code IllegalArgumentException} during formatting and
     * {@code ParseException} or null during parsing.
     * The format does not support attributing of the returned format string.
     *
     * @return this formatter as a classic format instance, not null
     */
     ///@gxc
    // public Format toFormat() {
    //     return new ClassicFormat(this, null);
    // }

    /**
     * Returns this formatter as a {@code java.text.Format} instance that will
     * parse using the specified query.
     * !(p)
     * The returned {@link Format} instance will format any {@link TemporalAccessor}
     * and parses to the type specified.
     * The type must be one that is supported by {@link #parse}.
     * !(p)
     * Exceptions will follow the definitions of {@code Format}, see those methods
     * for details about {@code IllegalArgumentException} during formatting and
     * {@code ParseException} or null during parsing.
     * The format does not support attributing of the returned format string.
     *
     * @param parseQuery  the query defining the type to parse to, not null
     * @return this formatter as a classic format instance, not null
     */
     ///@gxc
    // public Format toFormat(TemporalQuery!(Object) parseQuery) {
    //     assert(parseQuery, "parseQuery");
    //     return new ClassicFormat(this, parseQuery);
    // }

    //-----------------------------------------------------------------------
    /**
     * Returns a description of the underlying formatters.
     *
     * @return a description of this formatter, not null
     */
    override
    public string toString() {
        string pattern = printerParser.toString();
        pattern = pattern.startsWith("[") ? pattern : pattern[1 .. pattern.length - 1];
        return pattern;
        // TODO: Fix tests to not depend on toString()
//        return "DateTimeFormatter[" ~ locale +
//                (chrono !is null ? "," ~ chrono : "") +
//                (zone !is null ? "," ~ zone : "") +
//                pattern ~ "]";
    }

    //-----------------------------------------------------------------------
    /**
     * Implements the classic Java Format API.
     * @serial exclude
     */
    // @SuppressWarnings("serial")  // not actually serializable
    ///@gxc
    // static class ClassicFormat : Format {
    //     /** The formatter. */
    //     private final DateTimeFormatter formatter;
    //     /** The type to be parsed. */
    //     private final TemporalQuery!(Object) parseType;
    //     /** Constructor. */
    //     public this(DateTimeFormatter formatter, TemporalQuery!(Object) parseType) {
    //         this.formatter = formatter;
    //         this.parseType = parseType;
    //     }

    //     override
    //     public StringBuffer format(Object obj, StringBuffer toAppendTo, FieldPosition pos) {
    //         assert(obj, "obj");
    //         assert(toAppendTo, "toAppendTo");
    //         assert(pos, "pos");
    //         if ((cast(TemporalAccessor)(obj) !is null) == false) {
    //             throw new IllegalArgumentException("Format target must implement TemporalAccessor");
    //         }
    //         pos.setBeginIndex(0);
    //         pos.setEndIndex(0);
    //         try {
    //             formatter.formatTo(cast(TemporalAccessor) obj, toAppendTo);
    //         } catch (RuntimeException ex) {
    //             throw new IllegalArgumentException(ex.getMessage(), ex);
    //         }
    //         return toAppendTo;
    //     }
    //     override
    //     public Object parseObject(string text) /* throws ParseException */ {
    //         assert(text, "text");
    //         try {
    //             if (parseType is null) {
    //                 return formatter.parseResolved0(text, null);
    //             }
    //             return formatter.parse(text, parseType);
    //         } catch (DateTimeParseException ex) {
    //             throw new ParseException(ex.getMessage(), ex.getErrorIndex());
    //         } catch (RuntimeException ex) {
    //             throw cast(ParseException) new ParseException(ex.getMessage(), 0).initCause(ex);
    //         }
    //     }
    //     override
    //     public Object parseObject(string text, ParsePosition pos) {
    //         assert(text, "text");
    //         DateTimeParseContext context;
    //         try {
    //             context = formatter.parseUnresolved0(text, pos);
    //         } catch (IndexOutOfBoundsException ex) {
    //             if (pos.getErrorIndex() < 0) {
    //                 pos.setErrorIndex(0);
    //             }
    //             return null;
    //         }
    //         if (context is null) {
    //             if (pos.getErrorIndex() < 0) {
    //                 pos.setErrorIndex(0);
    //             }
    //             return null;
    //         }
    //         try {
    //             TemporalAccessor resolved = context.toResolved(formatter.resolverStyle, formatter.resolverFields);
    //             if (parseType is null) {
    //                 return resolved;
    //             }
    //             return resolved.query(parseType);
    //         } catch (RuntimeException ex) {
    //             pos.setErrorIndex(0);
    //             return null;
    //         }
    //     }
    // }

}
