
module hunt.time.ZoneRegion;

import hunt.io.DataInput;
import hunt.io.DataOutput;
import hunt.lang.exception;

//import hunt.io.ObjectInputStream;
import hunt.io.common;
import hunt.time.zone.ZoneRules;
import hunt.time.zone.ZoneRulesException;
import hunt.time.zone.ZoneRulesProvider;
import hunt.time.ZoneId;
import hunt.time.DateTimeException;
import hunt.time.Ser;
import hunt.string.common;
/**
 * A geographical region where the same time-zone rules apply.
 * !(p)
 * Time-zone information is categorized as a set of rules defining when and
 * how the offset from UTC/Greenwich changes. These rules are accessed using
 * identifiers based on geographical regions, such as countries or states.
 * The most common region classification is the Time Zone Database (TZDB),
 * which defines regions such as 'Europe/Paris' and 'Asia/Tokyo'.
 * !(p)
 * The region identifier, modeled by this class, is distinct from the
 * underlying rules, modeled by {@link ZoneRules}.
 * The rules are defined by governments and change frequently.
 * By contrast, the region identifier is well-defined and long-lived.
 * This separation also allows rules to be shared between regions if appropriate.
 *
 * @implSpec
 * This class is immutable and thread-safe.
 *
 * @since 1.8
 */
final class ZoneRegion : ZoneId , Serializable {

    /**
     * Serialization version.
     */
    private enum  long serialVersionUID = 8386373296231747096L;
    /**
     * The time-zone ID, not null.
     */
    private  string id;
    /**
     * The time-zone rules, null if zone ID was loaded leniently.
     */
    private  /*transient*/ ZoneRules rules;

    /**
     * Obtains an instance of {@code ZoneId} from an identifier.
     *
     * @param zoneId  the time-zone ID, not null
     * @param checkAvailable  whether to check if the zone ID is available
     * @return the zone ID, not null
     * @throws DateTimeException if the ID format is invalid
     * @throws ZoneRulesException if checking availability and the ID cannot be found
     */
    static ZoneRegion ofId(string zoneId, bool checkAvailable) {
        assert(zoneId, "zoneId");
        checkName(zoneId);
        ZoneRules rules = null;
        try {
            // always attempt load for better behavior after deserialization
            rules = ZoneRulesProvider.getRules(zoneId, true);
        } catch (ZoneRulesException ex) {
            if (checkAvailable) {
                throw ex;
            }
        }
        return new ZoneRegion(zoneId, rules);
    }

    /**
     * Checks that the given string is a legal ZondId name.
     *
     * @param zoneId  the time-zone ID, not null
     * @throws DateTimeException if the ID format is invalid
     */
    private static void checkName(string zoneId) {
        auto n = zoneId.length;
        if (n < 2) {
           throw new DateTimeException("Invalid ID for region-based ZoneId, invalid format: " ~ zoneId);
        }
        for (int i = 0; i < n; i++) {
            char c = zoneId.charAt(i);
            if (c >= 'a' && c <= 'z') continue;
            if (c >= 'A' && c <= 'Z') continue;
            if (c == '/' && i != 0) continue;
            if (c >= '0' && c <= '9' && i != 0) continue;
            if (c == '~' && i != 0) continue;
            if (c == '.' && i != 0) continue;
            if (c == '_' && i != 0) continue;
            if (c == '+' && i != 0) continue;
            if (c == '-' && i != 0) continue;
            throw new DateTimeException("Invalid ID for region-based ZoneId, invalid format: " ~ zoneId);
        }
    }

    //-------------------------------------------------------------------------
    /**
     * Constructor.
     *
     * @param id  the time-zone ID, not null
     * @param rules  the rules, null for lazy lookup
     */
    this(string id, ZoneRules rules) {
        this.id = id;
        this.rules = rules;
    }

    //-----------------------------------------------------------------------
    override
    public string getId() {
        return id;
    }

    override
    public ZoneRules getRules() {
        // additional query for group provider when null allows for possibility
        // that the provider was updated after the ZoneId was created
        return (rules !is null ? rules : ZoneRulesProvider.getRules(id, false));
    }

    //-----------------------------------------------------------------------
    /**
     * Writes the object using a
     * <a href="{@docRoot}/serialized-form.html#hunt.time.Ser">dedicated serialized form</a>.
     * @serialData
     * !(pre)
     *  _out.writeByte(7);  // identifies a ZoneId (not ZoneOffset)
     *  _out.writeUTF(zoneId);
     * </pre>
     *
     * @return the instance of {@code Ser}, not null
     */
    private Object writeReplace() {
        return new Ser(Ser.ZONE_REGION_TYPE, this);
    }

    /**
     * Defend against malicious streams.
     *
     * @param s the stream to read
     * @throws InvalidObjectException always
     */
     ///@gxc
    // private void readObject(ObjectInputStream s) /*throws InvalidObjectException*/ {
    //     throw new InvalidObjectException("Deserialization via serialization delegate");
    // }

    override
    void write(DataOutput _out) /*throws IOException*/ {
        _out.writeByte(Ser.ZONE_REGION_TYPE);
        writeExternal(_out);
    }

    void writeExternal(DataOutput _out) /*throws IOException*/ {
        _out.writeUTF(id);
    }

    static ZoneId readExternal(DataInput _in) /*throws IOException*/ {
        string id = _in.readUTF();
        return ZoneId.of(id, false);
    }

}
