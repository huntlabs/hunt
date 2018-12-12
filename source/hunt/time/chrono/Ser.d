
module hunt.time.chrono.Ser;

import hunt.io.Externalizable;
import hunt.lang.exception;
// import hunt.io.InvalidClassException;
import hunt.io.ObjectInput;
import hunt.io.ObjectOutput;
// import hunt.io.StreamCorruptedException;
import hunt.time.LocalDate;
import hunt.time.LocalDateTime;
import hunt.time.chrono.AbstractChronology;
import hunt.time.chrono.JapaneseDate;
import hunt.time.chrono.JapaneseEra;
import hunt.time.chrono.HijrahDate;
import hunt.time.chrono.MinguoDate;
import hunt.time.chrono.ThaiBuddhistDate;
import hunt.time.chrono.ChronoPeriodImpl;
import hunt.time.chrono.ChronoLocalDateTimeImpl;
import hunt.time.chrono.ChronoZonedDateTimeImpl;
import hunt.time.chrono.ChronoLocalDate;
/**
 * The shared serialization delegate for this package.
 *
 * @implNote
 * This class wraps the object being serialized, and takes a byte representing the type of the class to
 * be serialized.  This byte can also be used for versioning the serialization format.  In this case another
 * byte flag would be used _in order to specify an alternative version of the type format.
 * For example {@code CHRONO_TYPE_VERSION_2 = 21}
 * !(p)
 * In order to serialize the object it writes its byte and then calls back to the appropriate class where
 * the serialization is performed.  In order to deserialize the object it read _in the type byte, switching
 * _in order to select which class to call back into.
 * !(p)
 * The serialization format is determined on a per class basis.  In the case of field based classes each
 * of the fields is written _out with an appropriate size format _in descending order of the field's size.  For
 * example _in the case of {@link LocalDate} year is written before month.  Composite classes, such as
 * {@link LocalDateTime} are serialized as one object.  Enum classes are serialized using the index of their
 * element.
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
    private enum long serialVersionUID = -6103370247208168577L;

    enum byte CHRONO_TYPE = 1;
    enum byte CHRONO_LOCAL_DATE_TIME_TYPE = 2;
    enum byte CHRONO_ZONE_DATE_TIME_TYPE = 3;
    enum byte JAPANESE_DATE_TYPE = 4;
    enum byte JAPANESE_ERA_TYPE = 5;
    enum byte HIJRAH_DATE_TYPE = 6;
    enum byte MINGUO_DATE_TYPE = 7;
    enum byte THAIBUDDHIST_DATE_TYPE = 8;
    enum byte CHRONO_PERIOD_TYPE = 9;

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
     * Each serializable class is mapped to a type that is the first byte
     * _in the stream.  Refer to each class {@code writeReplace}
     * serialized form for the value of the type and sequence of values for the type.
     * !(ul)
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.chrono.HijrahChronology">HijrahChronology.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.chrono.IsoChronology">IsoChronology.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.chrono.JapaneseChronology">JapaneseChronology.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.chrono.MinguoChronology">MinguoChronology.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.chrono.ThaiBuddhistChronology">ThaiBuddhistChronology.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.chrono.ChronoLocalDateTimeImpl">ChronoLocalDateTime.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.chrono.ChronoZonedDateTimeImpl">ChronoZonedDateTime.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.chrono.JapaneseDate">JapaneseDate.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.chrono.JapaneseEra">JapaneseEra.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.chrono.HijrahDate">HijrahDate.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.chrono.MinguoDate">MinguoDate.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.chrono.ThaiBuddhistDate">ThaiBuddhistDate.writeReplace</a>
     * </ul>
     *
     * @param _out  the data stream to write to, not null
     */
    override
    public void writeExternal(ObjectOutput _out) /*throws IOException*/ {
        writeInternal(type, object, _out);
    }

    private static void writeInternal(byte type, Object object, ObjectOutput _out) /*throws IOException*/ {
        _out.writeByte(type);
        switch (type) {
            case CHRONO_TYPE:
                (cast(AbstractChronology) object).writeExternal(_out);
                break;
            case CHRONO_LOCAL_DATE_TIME_TYPE:
                (cast(ChronoLocalDateTimeImpl!(ChronoLocalDate)) object).writeExternal(_out);
                break;
            case CHRONO_ZONE_DATE_TIME_TYPE:
                (cast(ChronoZonedDateTimeImpl!(ChronoLocalDate)) object).writeExternal(_out);
                break;
            // case JAPANESE_DATE_TYPE:
            //     (cast(JapaneseDate) object).writeExternal(_out);
            //     break;
            // case JAPANESE_ERA_TYPE:
            //     (cast(JapaneseEra) object).writeExternal(_out);
            //     break;
            // case HIJRAH_DATE_TYPE:
            //     (cast(HijrahDate) object).writeExternal(_out);
            //     break;
            // case MINGUO_DATE_TYPE:
            //     (cast(MinguoDate) object).writeExternal(_out);
            //     break;
            // case THAIBUDDHIST_DATE_TYPE:
            //     (cast(ThaiBuddhistDate) object).writeExternal(_out);
            //     break;
            case CHRONO_PERIOD_TYPE:
                (cast(ChronoPeriodImpl) object).writeExternal(_out);
                break;
            default:
                throw new InvalidClassException("Unknown serialized type");
        }
    }

    //-----------------------------------------------------------------------
    /**
     * Implements the {@code Externalizable} interface to read the object.
     * @serialData
     * The streamed type and parameters defined by the type's {@code writeReplace}
     * method are read and passed to the corresponding static factory for the type
     * to create a new instance.  That instance is returned as the de-serialized
     * {@code Ser} object.
     *
     * !(ul)
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.chrono.HijrahChronology">HijrahChronology</a> - Chronology.of(id)
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.chrono.IsoChronology">IsoChronology</a> - Chronology.of(id)
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.chrono.JapaneseChronology">JapaneseChronology</a> - Chronology.of(id)
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.chrono.MinguoChronology">MinguoChronology</a> - Chronology.of(id)
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.chrono.ThaiBuddhistChronology">ThaiBuddhistChronology</a> - Chronology.of(id)
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.chrono.ChronoLocalDateTimeImpl">ChronoLocalDateTime</a> - date.atTime(time)
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.chrono.ChronoZonedDateTimeImpl">ChronoZonedDateTime</a> - dateTime.atZone(offset).withZoneSameLocal(zone)
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.chrono.JapaneseDate">JapaneseDate</a> - JapaneseChronology.INSTANCE.date(year, month, dayOfMonth)
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.chrono.JapaneseEra">JapaneseEra</a> - JapaneseEra.of(eraValue)
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.chrono.HijrahDate">HijrahDate</a> - HijrahChronology chrono.date(year, month, dayOfMonth)
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.chrono.MinguoDate">MinguoDate</a> - MinguoChronology.INSTANCE.date(year, month, dayOfMonth)
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.chrono.ThaiBuddhistDate">ThaiBuddhistDate</a> - ThaiBuddhistChronology.INSTANCE.date(year, month, dayOfMonth)
     * </ul>
     *
     * @param _in  the data stream to read from, not null
     */
    override
    public void readExternal(ObjectInput _in) /*throws IOException, ClassNotFoundException*/ {
        type = _in.readByte();
        object = readInternal(type, _in);
    }

    static Object read(ObjectInput _in) /*throws IOException, ClassNotFoundException*/ {
        byte type = _in.readByte();
        return readInternal(type, _in);
    }

    private static Object readInternal(byte type, ObjectInput _in) /*throws IOException, ClassNotFoundException */{
        switch (type) {
            case CHRONO_TYPE: return cast(Object)(AbstractChronology.readExternal(_in));
            case CHRONO_LOCAL_DATE_TIME_TYPE: return cast(Object)(ChronoLocalDateTimeImpl!(ChronoLocalDate).readExternal(_in));
            case CHRONO_ZONE_DATE_TIME_TYPE: return cast(Object)(ChronoZonedDateTimeImpl!(ChronoLocalDate).readExternal(_in));
            // case JAPANESE_DATE_TYPE:  return JapaneseDate.readExternal(_in);
            // case JAPANESE_ERA_TYPE: return JapaneseEra.readExternal(_in);
            // case HIJRAH_DATE_TYPE: return HijrahDate.readExternal(_in);
            // case MINGUO_DATE_TYPE: return MinguoDate.readExternal(_in);
            // case THAIBUDDHIST_DATE_TYPE: return ThaiBuddhistDate.readExternal(_in);
            case CHRONO_PERIOD_TYPE: return cast(Object)(ChronoPeriodImpl.readExternal(_in));
            default: throw new Exception("Unknown serialized type");
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
