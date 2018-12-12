
module hunt.time.Ser;

import hunt.io.Externalizable;
import hunt.lang.exception;
// import hunt.io.InvalidClassException;
import hunt.io.ObjectInput;
import hunt.io.ObjectOutput;
// import hunt.io.StreamCorruptedException;
import hunt.time.Duration;
import hunt.time.Instant;
import hunt.time.LocalDate;
import hunt.time.LocalDateTime;
import hunt.time.LocalTime;
import hunt.time.ZoneRegion;
import hunt.time.ZoneOffset;
import hunt.time.ZonedDateTime;
import hunt.time.OffsetTime;
import hunt.time.OffsetDateTime;
import hunt.time.Year;
import hunt.time.YearMonth;
import hunt.time.MonthDay;
import hunt.time.Period;

/**
 * The shared serialization delegate for this package.
 *
 * @implNote
 * This class wraps the object being serialized, and takes a byte representing the type of the class to
 * be serialized.  This byte can also be used for versioning the serialization format.  In this case another
 * byte flag would be used _in order to specify an alternative version of the type format.
 * For example {@code LOCAL_DATE_TYPE_VERSION_2 = 21}.
 * !(p)
 * In order to serialize the object it writes its byte and then calls back to the appropriate class where
 * the serialization is performed.  In order to deserialize the object it read _in the type byte, switching
 * _in order to select which class to call back into.
 * !(p)
 * The serialization format is determined on a per class basis.  In the case of field based classes each
 * of the fields is written _out with an appropriate size format _in descending order of the field's size.  For
 * example _in the case of {@link LocalDate} year is written before month.  Composite classes, such as
 * {@link LocalDateTime} are serialized as one object.
 * !(p)
 * This class is mutable and should be created once per serialization.
 *
 * @serial include
 * @since 1.8
 */
final class Ser : Externalizable {

    /**
     * Serialization version.
     */
    private enum long serialVersionUID = -7683839454370182990L;

    enum byte DURATION_TYPE = 1;
    enum byte INSTANT_TYPE = 2;
    enum byte LOCAL_DATE_TYPE = 3;
    enum byte LOCAL_TIME_TYPE = 4;
    enum byte LOCAL_DATE_TIME_TYPE = 5;
    enum byte ZONE_DATE_TIME_TYPE = 6;
    enum byte ZONE_REGION_TYPE = 7;
    enum byte ZONE_OFFSET_TYPE = 8;
    enum byte OFFSET_TIME_TYPE = 9;
    enum byte OFFSET_DATE_TIME_TYPE = 10;
    enum byte YEAR_TYPE = 11;
    enum byte YEAR_MONTH_TYPE = 12;
    enum byte MONTH_DAY_TYPE = 13;
    enum byte PERIOD_TYPE = 14;

    /** The type being serialized. */
    private byte type;
    /** The object being serialized. */
    private Object object;

    /**
     * Constructor for deserialization.
     */
    public this() {
    }

    /**
     * Creates an instance for serialization.
     *
     * @param type  the type
     * @param object  the object
     */
    this(byte type, Object object) {
        this.type = type;
        this.object = object;
    }

    //-----------------------------------------------------------------------
    /**
     * Implements the {@code Externalizable} interface to write the object.
     * @serialData
     *
     * Each serializable class is mapped to a type that is the first byte
     * _in the stream.  Refer to each class {@code writeReplace}
     * serialized form for the value of the type and sequence of values for the type.
     * !(ul)
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.Duration">Duration.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.Instant">Instant.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.LocalDate">LocalDate.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.LocalDateTime">LocalDateTime.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.LocalTime">LocalTime.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.MonthDay">MonthDay.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.OffsetTime">OffsetTime.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.OffsetDateTime">OffsetDateTime.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.Period">Period.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.Year">Year.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.YearMonth">YearMonth.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.ZoneId">ZoneId.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.ZoneOffset">ZoneOffset.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.ZonedDateTime">ZonedDateTime.writeReplace</a>
     * </ul>
     *
     * @param _out  the data stream to write to, not null
     */
    override
    public void writeExternal(ObjectOutput _out) /*throws IOException*/ {
        writeInternal(type, object, _out);
    }

    static void writeInternal(byte type, Object object, ObjectOutput _out) /*throws IOException*/ {
        _out.writeByte(type);
        switch (type) {
            case DURATION_TYPE:
                (cast(Duration) object).writeExternal(_out);
                break;
            case INSTANT_TYPE:
                (cast(Instant) object).writeExternal(_out);
                break;
            case LOCAL_DATE_TYPE:
                (cast(LocalDate) object).writeExternal(_out);
                break;
            case LOCAL_DATE_TIME_TYPE:
                (cast(LocalDateTime) object).writeExternal(_out);
                break;
            case LOCAL_TIME_TYPE:
                (cast(LocalTime) object).writeExternal(_out);
                break;
            case ZONE_REGION_TYPE:
                (cast(ZoneRegion) object).writeExternal(_out);
                break;
            case ZONE_OFFSET_TYPE:
                (cast(ZoneOffset) object).writeExternal(_out);
                break;
            case ZONE_DATE_TIME_TYPE:
                (cast(ZonedDateTime) object).writeExternal(_out);
                break;
            case OFFSET_TIME_TYPE:
                (cast(OffsetTime) object).writeExternal(_out);
                break;
            case OFFSET_DATE_TIME_TYPE:
                (cast(OffsetDateTime) object).writeExternal(_out);
                break;
            case YEAR_TYPE:
                (cast(Year) object).writeExternal(_out);
                break;
            case YEAR_MONTH_TYPE:
                (cast(YearMonth) object).writeExternal(_out);
                break;
            case MONTH_DAY_TYPE:
                (cast(MonthDay) object).writeExternal(_out);
                break;
            case PERIOD_TYPE:
                (cast(Period) object).writeExternal(_out);
                break;
            default:
                throw new InvalidClassException("Unknown serialized type");
        }
    }

    //-----------------------------------------------------------------------
    /**
     * Implements the {@code Externalizable} interface to read the object.
     * @serialData
     *
     * The streamed type and parameters defined by the type's {@code writeReplace}
     * method are read and passed to the corresponding static factory for the type
     * to create a new instance.  That instance is returned as the de-serialized
     * {@code Ser} object.
     *
     * !(ul)
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.Duration">Duration</a> - {@code Duration.ofSeconds(seconds, nanos);}
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.Instant">Instant</a> - {@code Instant.ofEpochSecond(seconds, nanos);}
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.LocalDate">LocalDate</a> - {@code LocalDate.of(year, month, day);}
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.LocalDateTime">LocalDateTime</a> - {@code LocalDateTime.of(date, time);}
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.LocalTime">LocalTime</a> - {@code LocalTime.of(hour, minute, second, nano);}
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.MonthDay">MonthDay</a> - {@code MonthDay.of(month, day);}
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.OffsetTime">OffsetTime</a> - {@code OffsetTime.of(time, offset);}
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.OffsetDateTime">OffsetDateTime</a> - {@code OffsetDateTime.of(dateTime, offset);}
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.Period">Period</a> - {@code Period.of(years, months, days);}
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.Year">Year</a> - {@code Year.of(year);}
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.YearMonth">YearMonth</a> - {@code YearMonth.of(year, month);}
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.ZonedDateTime">ZonedDateTime</a> - {@code ZonedDateTime.ofLenient(dateTime, offset, zone);}
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.ZoneId">ZoneId</a> - {@code ZoneId.of(id);}
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.ZoneOffset">ZoneOffset</a> - {@code (offsetByte == 127 ? ZoneOffset.ofTotalSeconds(_in.readInt()) : ZoneOffset.ofTotalSeconds(offsetByte * 900));}
     * </ul>
     *
     * @param _in  the data to read, not null
     */
    public void readExternal(ObjectInput _in) /*throws IOException, ClassNotFoundException*/ {
        type = _in.readByte();
        object = readInternal(type, _in);
    }

    static Object read(ObjectInput _in) /*throws IOException, ClassNotFoundException*/{
        byte type = _in.readByte();
        return readInternal(type, _in);
    }

    private static Object readInternal(byte type, ObjectInput _in) /*throws IOException, ClassNotFoundException*/ {
        switch (type) {
            case DURATION_TYPE: return Duration.readExternal(_in);
            case INSTANT_TYPE: return Instant.readExternal(_in);
            case LOCAL_DATE_TYPE: return LocalDate.readExternal(_in);
            case LOCAL_DATE_TIME_TYPE: return LocalDateTime.readExternal(_in);
            case LOCAL_TIME_TYPE: return LocalTime.readExternal(_in);
            case ZONE_DATE_TIME_TYPE: return ZonedDateTime.readExternal(_in);
            case ZONE_OFFSET_TYPE: return ZoneOffset.readExternal(_in);
            case ZONE_REGION_TYPE: return ZoneRegion.readExternal(_in);
            case OFFSET_TIME_TYPE: return OffsetTime.readExternal(_in);
            case OFFSET_DATE_TIME_TYPE: return OffsetDateTime.readExternal(_in);
            case YEAR_TYPE: return Year.readExternal(_in);
            case YEAR_MONTH_TYPE: return YearMonth.readExternal(_in);
            case MONTH_DAY_TYPE: return MonthDay.readExternal(_in);
            case PERIOD_TYPE: return Period.readExternal(_in);
            default:
                throw new Exception("Unknown serialized type");
        }
    }

    /**
     * Returns the object that will replace this one.
     *
     * @return the read object, should never be null
     */
    private Object readResolve() {
         return object;
    }

}
