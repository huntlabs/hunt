
module hunt.time.zone.Ser;

import hunt.io.DataInput;
import hunt.io.DataOutput;
import hunt.io.Externalizable;
import hunt.lang.exception;
// import hunt.io.InvalidClassException;
import hunt.io.ObjectInput;
import hunt.io.ObjectOutput;
// import hunt.io.StreamCorruptedException;
import hunt.time.ZoneOffset;
import hunt.time.zone.ZoneRules;
import hunt.time.zone.ZoneOffsetTransition;
import hunt.time.zone.ZoneOffsetTransitionRule;
/**
 * The shared serialization delegate for this package.
 *
 * @implNote
 * This class is mutable and should be created once per serialization.
 *
 * @serial include
 * @since 1.8
 */
final class Ser : Externalizable {

    /**
     * Serialization version.
     */
    private enum long serialVersionUID = -8885321777449118786L;

    /** Type for ZoneRules. */
    enum byte ZRULES = 1;
    /** Type for ZoneOffsetTransition. */
    enum byte ZOT = 2;
    /** Type for ZoneOffsetTransition. */
    enum byte ZOTRULE = 3;

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
     *
     * !(ul)
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.zone.ZoneRules">ZoneRules.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.zone.ZoneOffsetTransition">ZoneOffsetTransition.writeReplace</a>
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.zone.ZoneOffsetTransitionRule">ZoneOffsetTransitionRule.writeReplace</a>
     * </ul>
     *
     * @param _out  the data stream to write to, not null
     */
    override
    public void writeExternal(ObjectOutput _out) /*throws IOException*/ {
        writeInternal(type, object, _out);
    }

    static void write(Object object, DataOutput _out) /*throws IOException*/ {
        writeInternal(ZRULES, object, _out);
    }

    private static void writeInternal(byte type, Object object, DataOutput _out) /*throws IOException*/ {
        _out.writeByte(type);
        switch (type) {
            case ZRULES:
                (cast(ZoneRules) object).writeExternal(_out);
                break;
            case ZOT:
                (cast(ZoneOffsetTransition) object).writeExternal(_out);
                break;
            case ZOTRULE:
                (cast(ZoneOffsetTransitionRule) object).writeExternal(_out);
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
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.zone.ZoneRules">ZoneRules</a>
     * - {@code ZoneRules.of(standardTransitions, standardOffsets, savingsInstantTransitions, wallOffsets, lastRules);}
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.zone.ZoneOffsetTransition">ZoneOffsetTransition</a>
     * - {@code ZoneOffsetTransition of(LocalDateTime.ofEpochSecond(epochSecond), offsetBefore, offsetAfter);}
     * !(li)<a href="{@docRoot}/serialized-form.html#hunt.time.zone.ZoneOffsetTransitionRule">ZoneOffsetTransitionRule</a>
     * - {@code ZoneOffsetTransitionRule.of(month, dom, dow, time, timeEndOfDay, timeDefinition, standardOffset, offsetBefore, offsetAfter);}
     * </ul>
     * @param _in  the data to read, not null
     */
    override
    public void readExternal(ObjectInput _in) /*throws IOException, ClassNotFoundException */{
        type = _in.readByte();
        object = readInternal(type, _in);
    }

    static Object read(DataInput _in) /*throws IOException, ClassNotFoundException*/ {
        byte type = _in.readByte();
        return readInternal(type, _in);
    }

    private static Object readInternal(byte type, DataInput _in) /*throws IOException, ClassNotFoundException*/ {
        switch (type) {
            case ZRULES:
                return ZoneRules.readExternal(_in);
            case ZOT:
                return ZoneOffsetTransition.readExternal(_in);
            case ZOTRULE:
                return ZoneOffsetTransitionRule.readExternal(_in);
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

    //-----------------------------------------------------------------------
    /**
     * Writes the state to the stream.
     *
     * @param offset  the offset, not null
     * @param _out  the output stream, not null
     * @throws IOException if an error occurs
     */
    static void writeOffset(ZoneOffset offset, DataOutput _out) /*throws IOException*/ {
        int offsetSecs = offset.getTotalSeconds();
        int offsetByte = offsetSecs % 900 == 0 ? offsetSecs / 900 : 127;  // compress to -72 to +72
        _out.writeByte(offsetByte);
        if (offsetByte == 127) {
            _out.writeInt(offsetSecs);
        }
    }

    /**
     * Reads the state from the stream.
     *
     * @param _in  the input stream, not null
     * @return the created object, not null
     * @throws IOException if an error occurs
     */
    static ZoneOffset readOffset(DataInput _in) /*throws IOException*/ {
        int offsetByte = _in.readByte();
        return (offsetByte == 127 ? ZoneOffset.ofTotalSeconds(_in.readInt()) : ZoneOffset.ofTotalSeconds(offsetByte * 900));
    }

    //-----------------------------------------------------------------------
    /**
     * Writes the state to the stream.
     *
     * @param epochSec  the epoch seconds, not null
     * @param _out  the output stream, not null
     * @throws IOException if an error occurs
     */
    static void writeEpochSec(long epochSec, DataOutput _out) /*throws IOException*/ {
        if (epochSec >= -4575744000L && epochSec < 10413792000L && epochSec % 900 == 0) {  // quarter hours between 1825 and 2300
            int store = cast(int) ((epochSec + 4575744000L) / 900);
            _out.writeByte((store >>> 16) & 255);
            _out.writeByte((store >>> 8) & 255);
            _out.writeByte(store & 255);
        } else {
            _out.writeByte(255);
            _out.writeLong(epochSec);
        }
    }

    /**
     * Reads the state from the stream.
     *
     * @param _in  the input stream, not null
     * @return the epoch seconds, not null
     * @throws IOException if an error occurs
     */
    static long readEpochSec(DataInput _in) /*throws IOException*/ {
        int hiByte = _in.readByte() & 255;
        if (hiByte == 255) {
            return _in.readLong();
        } else {
            int midByte = _in.readByte() & 255;
            int loByte = _in.readByte() & 255;
            long tot = ((hiByte << 16) + (midByte << 8) + loByte);
            return (tot * 900) - 4575744000L;
        }
    }

}
