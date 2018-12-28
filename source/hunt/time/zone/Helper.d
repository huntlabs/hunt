module hunt.time.zone.Helper;

import hunt.time.zone.ZoneRulesProvider;
// import hunt.time.zone.TzdbZoneRulesProvider;

import hunt.container.Set;
import hunt.container.HashSet;

class ZoneRulesHelper {
    private __gshared Set!(string) ZONE_IDS;

    /**
     * Gets the set of available zone IDs.
     * !(p)
     * These IDs are the string form of a {@link ZoneId}.
     *
     * @return the unmodifiable set of zone IDs, not null
     */
    public static Set!(string) getAvailableZoneIds() {
        if(ZONE_IDS is null) {
            ZONE_IDS = new HashSet!(string)();
            foreach(data; ZoneRulesProvider.ZONES.keySet()) {
                ZONE_IDS.add(data);
            }
            
        }
        return ZONE_IDS;
    }    
}