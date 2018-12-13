
module hunt.time.zone.TzdbZoneRulesProvider;

// import jdk.internal.util.StaticProperty;

import hunt.io.ByteArrayInputStream;
import hunt.io.BufferedInputStream;
import hunt.io.DataInputStream;
import hunt.lang.String;
import hunt.io.FileInputStream;
// import hunt.io.StreamCorruptedException;
import hunt.time.zone.ZoneRulesException;
import hunt.container;
import hunt.time.util;
import hunt.time.zone.ZoneRulesProvider;
import hunt.time.zone.ZoneRules;
import hunt.time.zone.Ser;

import std.conv;
import std.file;
import std.path;
import std.stdio;

/**
 * Loads time-zone rules for 'TZDB'.
 *
 * @since 1.8
 */
final class TzdbZoneRulesProvider : ZoneRulesProvider {

    mixin MakeServiceLoader!ZoneRulesProvider;
    /**
     * All the regions that are available.
     */
    private List!(string) regionIds;
    /**
     * Version Id of this tzdb rules
     */
    private string versionId;
    /**
     * Region to rules mapping
     */
    private  Map!(string, Object) regionToRules ;



    /**
     * Creates an instance.
     * Created by the {@code ServiceLoader}.
     *
     * @throws ZoneRulesException if unable to load
     */
    public this() {
        regionIds = new ArrayList!string();

        regionToRules = new HashMap!(string, Object)();
        //@gxc load timezone database
        try {
            string resourcePath = dirName(thisExePath()) ~ "/resources";
            string resourceName = buildPath(resourcePath, "tzdb.dat");
            if(!exists(resourceName)) {
                import hunt.logging;
                version(HUNT_DEBUG) warningf("File does not exist: %s", resourceName);
            } else {
                File f = File(resourceName,"r");
                scope(exit) f.close();
                DataInputStream dis = new DataInputStream(
                     new BufferedInputStream(new FileInputStream(f)));
                load(dis);
            }
        } catch (Exception ex) {
            throw new ZoneRulesException("Unable to load TZDB time-zone rules", ex);
        } 
       

    }

    override
    protected Set!(string) provideZoneIds() {
        return new HashSet!(string)(regionIds);
    }

    override
    protected ZoneRules provideRules(string zoneId, bool forCaching) {
        // forCaching flag is ignored because this is not a dynamic provider
        auto obj = regionToRules.get(zoneId);
        if (obj is null) {
            throw new ZoneRulesException("Unknown time-zone ID: " ~ zoneId);
        }
        try {
            if (cast(String)(obj) !is null) {
                byte[] bytes = cast(byte[]) ((cast(String)obj).get());
                DataInputStream dis = new DataInputStream(new ByteArrayInputStream(bytes));
                obj = Ser.read(dis);
                regionToRules.put(zoneId, obj);
            }
            return cast(ZoneRules) obj;
        } catch (Exception ex) {
            throw new ZoneRulesException("Invalid binary time-zone data: TZDB:" ~ zoneId ~ ", version: " ~ versionId, ex);
        }
    }

    override
    protected NavigableMap!(string, ZoneRules) provideVersions(string zoneId) {
        TreeMap!(string, ZoneRules) map = new TreeMap!(string, ZoneRules)();
        ZoneRules rules = getRules(zoneId, false);
        if (rules !is null) {
            map.put(versionId, rules);
        }
        return map;
    }

    /**
     * Loads the rules from a DateInputStream, often _in a jar file.
     *
     * @param dis  the DateInputStream to load, not null
     * @ if an error occurs
     */
    private void load(DataInputStream dis)  {
        if (dis.readByte() != 1) {
            throw new Exception("File format not recognised");
        }
        // group
        string groupId = dis.readUTF();
        if (("TZDB" == groupId) == false) {
            throw new Exception("File format not recognised");
        }
        // versions
        int versionCount = dis.readShort();
        for (int i = 0; i < versionCount; i++) {
            versionId = dis.readUTF();
        }
        // regions
        int regionCount = dis.readShort();
        string[] regionArray = new string[regionCount];
        for (int i = 0; i < regionCount; i++) {
            regionArray[i] = dis.readUTF();
        }
        regionIds = new ArrayList!string();
        foreach(d ; regionArray)
            regionIds.add(d);
        // rules
        int ruleCount = dis.readShort();
        Object[] ruleArray = new Object[ruleCount];
        for (int i = 0; i < ruleCount; i++) {
            byte[] bytes = new byte[dis.readShort()];
            dis.readFully(bytes);
            ruleArray[i] = new String(cast(string)bytes);
        }
        // link version-region-rules
        for (int i = 0; i < versionCount; i++) {
            int versionRegionCount = dis.readShort();
            regionToRules.clear();
            for (int j = 0; j < versionRegionCount; j++) {
                string region = regionArray[dis.readShort()];
                auto rule = ruleArray[dis.readShort() & 0xffff];
                regionToRules.put(region, rule);
            }
        }
    }

    override
    public string toString() {
        return "TZDB[" ~ versionId ~ "]";
    }
}
