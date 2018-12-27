module hunt.time.zone.ZoneRules;

import hunt.io.DataInput;
import hunt.io.DataOutput;
import hunt.lang.exception;

//import hunt.io.ObjectInputStream;
import hunt.io.common;
import hunt.time.Duration;
import hunt.time.Instant;
import hunt.time.LocalDate;
import hunt.time.LocalDateTime;
import hunt.time.ZoneOffset;
// import hunt.time.Year;
import hunt.container.ArrayList;
import hunt.time.zone.Ser;
import hunt.container.Collections;
import hunt.container.List;
import hunt.lang;
import hunt.container.HashMap;
import hunt.time.zone.ZoneOffsetTransitionRule;
import hunt.time.zone.ZoneOffsetTransition;
import hunt.string.common;
import hunt.util.Arrays;
import hunt.time.util.common;

/**
 * The rules defining how the zone offset varies for a single time-zone.
 * !(p)
 * The rules model all the historic and future transitions for a time-zone.
 * {@link ZoneOffsetTransition} is used for known transitions, typically historic.
 * {@link ZoneOffsetTransitionRule} is used for future transitions that are based
 * on the result of an algorithm.
 * !(p)
 * The rules are loaded via {@link ZoneRulesProvider} using a {@link ZoneId}.
 * The same rules may be shared internally between multiple zone IDs.
 * !(p)
 * Serializing an instance of {@code ZoneRules} will store the entire set of rules.
 * It does not store the zone ID as it is not part of the state of this object.
 * !(p)
 * A rule implementation may or may not store full information about historic
 * and future transitions, and the information stored is only as accurate as
 * that supplied to the implementation by the rules provider.
 * Applications should treat the data provided as representing the best information
 * available to the implementation of this rule.
 *
 * @implSpec
 * This class is immutable and thread-safe.
 *
 * @since 1.8
 */

import std.algorithm.searching;

public final class ZoneRules : Serializable
{

    /**
     * Serialization version.
     */
    // private enum long serialVersionUID = 3044319355680032515L;
    /**
     * The last year to have its transitions cached.
     */
    private enum int LAST_CACHED_YEAR = 2100;

    /**
     * The transitions between standard offsets (epoch seconds), sorted.
     */
    private long[] standardTransitions;
    /**
     * The standard offsets.
     */
    private ZoneOffset[] standardOffsets;
    /**
     * The transitions between instants (epoch seconds), sorted.
     */
    private long[] savingsInstantTransitions;
    /**
     * The transitions between local date-times, sorted.
     * This is a paired array, where the first entry is the start of the transition
     * and the second entry is the end of the transition.
     */
    private LocalDateTime[] savingsLocalTransitions;
    /**
     * The wall offsets.
     */
    private ZoneOffset[] wallOffsets;
    /**
     * The last rule.
     */
    private ZoneOffsetTransitionRule[] lastRules;
    /**
     * The map of recent transitions.
     */
    // private  /*transient*/ ConcurrentMap!(Integer, ZoneOffsetTransition[]) lastRulesCache =
    //             new ConcurrentHashMap!(Integer, ZoneOffsetTransition[])();
    private  /*transient*/ HashMap!(Integer, ZoneOffsetTransition[]) lastRulesCache = new HashMap!(Integer,
            ZoneOffsetTransition[])();
    /**
     * The zero-length long array.
     */
    //__gshared long[] EMPTY_LONG_ARRAY;
    /**
     * The zero-length lastrules array.
     */
    //__gshared ZoneOffsetTransitionRule[] EMPTY_LASTRULES;
    /**
     * The zero-length ldt array.
     */
    //__gshared LocalDateTime[] EMPTY_LDT_ARRAY;

    // shared static this()
    // {
        // EMPTY_LONG_ARRAY = new long[0];
        mixin(MakeGlobalVar!(long[])("EMPTY_LONG_ARRAY",`new long[0]`));
        // EMPTY_LASTRULES =
        // new ZoneOffsetTransitionRule[0];
        mixin(MakeGlobalVar!(ZoneOffsetTransitionRule[])("EMPTY_LASTRULES",`new ZoneOffsetTransitionRule[0]`));

        // EMPTY_LDT_ARRAY = new LocalDateTime[0];
        mixin(MakeGlobalVar!(LocalDateTime[])("EMPTY_LDT_ARRAY",`new LocalDateTime[0]`));

    // }

    /**
     * Obtains an instance of a ZoneRules.
     *
     * @param baseStandardOffset  the standard offset to use before legal rules were set, not null
     * @param baseWallOffset  the wall offset to use before legal rules were set, not null
     * @param standardOffsetTransitionList  the list of changes to the standard offset, not null
     * @param transitionList  the list of transitions, not null
     * @param lastRules  the recurring last rules, size 16 or less, not null
     * @return the zone rules, not null
     */
    public static ZoneRules of(ZoneOffset baseStandardOffset, ZoneOffset baseWallOffset,
            List!(ZoneOffsetTransition) standardOffsetTransitionList,
            List!(ZoneOffsetTransition) transitionList, List!(ZoneOffsetTransitionRule) lastRules)
    {
        assert(baseStandardOffset, "baseStandardOffset");
        assert(baseWallOffset, "baseWallOffset");
        assert(standardOffsetTransitionList, "standardOffsetTransitionList");
        assert(transitionList, "transitionList");
        assert(lastRules, "lastRules");
        return new ZoneRules(baseStandardOffset, baseWallOffset,
                standardOffsetTransitionList, transitionList, lastRules);
    }

    /**
     * Obtains an instance of ZoneRules that has fixed zone rules.
     *
     * @param offset  the offset this fixed zone rules is based on, not null
     * @return the zone rules, not null
     * @see #isFixedOffset()
     */
    public static ZoneRules of(ZoneOffset offset)
    {
        assert(offset, "offset");
        return new ZoneRules(offset);
    }

    /**
     * Creates an instance.
     *
     * @param baseStandardOffset  the standard offset to use before legal rules were set, not null
     * @param baseWallOffset  the wall offset to use before legal rules were set, not null
     * @param standardOffsetTransitionList  the list of changes to the standard offset, not null
     * @param transitionList  the list of transitions, not null
     * @param lastRules  the recurring last rules, size 16 or less, not null
     */
    this(ZoneOffset baseStandardOffset, ZoneOffset baseWallOffset,
            List!(ZoneOffsetTransition) standardOffsetTransitionList,
            List!(ZoneOffsetTransition) transitionList, List!(ZoneOffsetTransitionRule) lastRules)
    {
        // super();

        // convert standard transitions

        this.standardTransitions = new long[standardOffsetTransitionList.size()];

        this.standardOffsets = new ZoneOffset[standardOffsetTransitionList.size() + 1];
        this.standardOffsets[0] = baseStandardOffset;
        for (int i = 0; i < standardOffsetTransitionList.size(); i++)
        {
            this.standardTransitions[i] = standardOffsetTransitionList.get(i).toEpochSecond();
            this.standardOffsets[i + 1] = standardOffsetTransitionList.get(i).getOffsetAfter();
        }

        // convert savings transitions to locals
        List!(LocalDateTime) localTransitionList = new ArrayList!(LocalDateTime)();
        List!(ZoneOffset) localTransitionOffsetList = new ArrayList!(ZoneOffset)();
        localTransitionOffsetList.add(baseWallOffset);
        foreach (ZoneOffsetTransition trans; transitionList)
        {
            if (trans.isGap())
            {
                localTransitionList.add(trans.getDateTimeBefore());
                localTransitionList.add(trans.getDateTimeAfter());
            }
            else
            {
                localTransitionList.add(trans.getDateTimeAfter());
                localTransitionList.add(trans.getDateTimeBefore());
            }
            localTransitionOffsetList.add(trans.getOffsetAfter());
        }
        // this.savingsLocalTransitions = new LocalDateTime[localTransitionList.size()];
        // foreach (data; localTransitionList)
        //     this.savingsLocalTransitions ~= data;
        // this.wallOffsets = new ZoneOffset[localTransitionOffsetList.size()];
        // foreach (data; localTransitionOffsetList)
        // {
        //     this.wallOffsets ~= data;
        // }

        this.savingsLocalTransitions = localTransitionList.toArray();
        this.wallOffsets = localTransitionOffsetList.toArray();
        // convert savings transitions to instants
        this.savingsInstantTransitions = new long[transitionList.size()];
        for (int i = 0; i < transitionList.size(); i++)
        {
            this.savingsInstantTransitions[i] = transitionList.get(i).toEpochSecond();
        }

        // last rules
        if (lastRules.size() > 16)
        {
            throw new IllegalArgumentException("Too many transition rules");
        }
        // this.lastRules = new ZoneOffsetTransitionRule[lastRules.size()];
        // foreach (data; lastRules)
        //     this.lastRules ~= data;
        this.lastRules = lastRules.toArray();
    }

    /**
     * Constructor.
     *
     * @param standardTransitions  the standard transitions, not null
     * @param standardOffsets  the standard offsets, not null
     * @param savingsInstantTransitions  the standard transitions, not null
     * @param wallOffsets  the wall offsets, not null
     * @param lastRules  the recurring last rules, size 15 or less, not null
     */
    private this(long[] standardTransitions, ZoneOffset[] standardOffsets,
            long[] savingsInstantTransitions, ZoneOffset[] wallOffsets,
            ZoneOffsetTransitionRule[] lastRules)
    {
        // super();

        this.standardTransitions = standardTransitions;
        this.standardOffsets = standardOffsets;
        this.savingsInstantTransitions = savingsInstantTransitions;
        this.wallOffsets = wallOffsets;
        this.lastRules = lastRules;

        if (savingsInstantTransitions.length == 0)
        {
            this.savingsLocalTransitions = EMPTY_LDT_ARRAY;
        }
        else
        {
            // convert savings transitions to locals
            List!(LocalDateTime) localTransitionList = new ArrayList!(LocalDateTime)();
            for (int i = 0; i < savingsInstantTransitions.length; i++)
            {
                ZoneOffset before = wallOffsets[i];
                ZoneOffset after = wallOffsets[i + 1];
                ZoneOffsetTransition trans = new ZoneOffsetTransition(savingsInstantTransitions[i],
                        before, after);
                if (trans.isGap())
                {
                    localTransitionList.add(trans.getDateTimeBefore());
                    localTransitionList.add(trans.getDateTimeAfter());
                }
                else
                {
                    localTransitionList.add(trans.getDateTimeAfter());
                    localTransitionList.add(trans.getDateTimeBefore());
                }
            }
            // this.savingsLocalTransitions = new LocalDateTime[localTransitionList.size()];
            // foreach (data; localTransitionList)
            //     this.savingsLocalTransitions ~= data;
            this.savingsLocalTransitions = localTransitionList.toArray();
        }
    }

    /**
     * Creates an instance of ZoneRules that has fixed zone rules.
     *
     * @param offset  the offset this fixed zone rules is based on, not null
     * @see #isFixedOffset()
     */
    private this(ZoneOffset offset)
    {
        this.standardOffsets = new ZoneOffset[1];
        this.standardOffsets[0] = offset;
        this.standardTransitions = EMPTY_LONG_ARRAY;
        this.savingsInstantTransitions = EMPTY_LONG_ARRAY;
        this.savingsLocalTransitions = EMPTY_LDT_ARRAY;
        this.wallOffsets = standardOffsets;
        this.lastRules = EMPTY_LASTRULES;
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

    /**
     * Writes the object using a
     * <a href="{@docRoot}/serialized-form.html#hunt.time.zone.Ser">dedicated serialized form</a>.
     * @serialData
     * <pre style="font-size:1.0em">{@code
     *
     *   _out.writeByte(1);  // identifies a ZoneRules
     *   _out.writeInt(standardTransitions.length);
     *   foreach(long trans ; standardTransitions) {
     *       Ser.writeEpochSec(trans, _out);
     *   }
     *   foreach(ZoneOffset offset ; standardOffsets) {
     *       Ser.writeOffset(offset, _out);
     *   }
     *   _out.writeInt(savingsInstantTransitions.length);
     *   foreach(long trans ; savingsInstantTransitions) {
     *       Ser.writeEpochSec(trans, _out);
     *   }
     *   foreach(ZoneOffset offset ; wallOffsets) {
     *       Ser.writeOffset(offset, _out);
     *   }
     *   _out.writeByte(lastRules.length);
     *   foreach(ZoneOffsetTransitionRule rule ; lastRules) {
     *       rule.writeExternal(_out);
     *   }
     * }
     * </pre>
     * !(p)
     * Epoch second values used for offsets are encoded _in a variable
     * length form to make the common cases put fewer bytes _in the stream.
     * <pre style="font-size:1.0em">{@code
     *
     *  static void writeEpochSec(long epochSec, DataOutput _out) throws IOException {
     *     if (epochSec >= -4575744000L && epochSec < 10413792000L && epochSec % 900 == 0) {  // quarter hours between 1825 and 2300
     *         int store = cast(int) ((epochSec + 4575744000L) / 900);
     *         _out.writeByte((store >>> 16) & 255);
     *         _out.writeByte((store >>> 8) & 255);
     *         _out.writeByte(store & 255);
     *      } else {
     *          _out.writeByte(255);
     *          _out.writeLong(epochSec);
     *      }
     *  }
     * }
     * </pre>
     * !(p)
     * ZoneOffset values are encoded _in a variable length form so the
     * common cases put fewer bytes _in the stream.
     * <pre style="font-size:1.0em">{@code
     *
     *  static void writeOffset(ZoneOffset offset, DataOutput _out) throws IOException {
     *     final int offsetSecs = offset.getTotalSeconds();
     *     int offsetByte = offsetSecs % 900 == 0 ? offsetSecs / 900 : 127;  // compress to -72 to +72
     *     _out.writeByte(offsetByte);
     *     if (offsetByte == 127) {
     *         _out.writeInt(offsetSecs);
     *     }
     * }
     *}
     * </pre>
     * @return the replacing object, not null
     */
    private Object writeReplace()
    {
        return new Ser(Ser.ZRULES, this);
    }

    /**
     * Writes the state to the stream.
     *
     * @param _out  the output stream, not null
     * @throws IOException if an error occurs
     */
    void writeExternal(DataOutput _out) /*throws IOException*/
    {
        _out.writeInt(cast(int)(standardTransitions.length));
        foreach (long trans; standardTransitions)
        {
            Ser.writeEpochSec(trans, _out);
        }
        foreach (ZoneOffset offset; standardOffsets)
        {
            Ser.writeOffset(offset, _out);
        }
        _out.writeInt(cast(int)(savingsInstantTransitions.length));
        foreach (long trans; savingsInstantTransitions)
        {
            Ser.writeEpochSec(trans, _out);
        }
        foreach (ZoneOffset offset; wallOffsets)
        {
            Ser.writeOffset(offset, _out);
        }
        _out.writeByte(cast(int)(lastRules.length));
        foreach (ZoneOffsetTransitionRule rule; lastRules)
        {
            rule.writeExternal(_out);
        }
    }

    /**
     * Reads the state from the stream.
     *
     * @param _in  the input stream, not null
     * @return the created object, not null
     * @throws IOException if an error occurs
     */
    static ZoneRules readExternal(DataInput _in) /*throws IOException, ClassNotFoundException*/
    {
        int stdSize = _in.readInt();
        long[] stdTrans = (stdSize == 0) ? EMPTY_LONG_ARRAY : new long[stdSize];
        for (int i = 0; i < stdSize; i++)
        {
            stdTrans[i] = Ser.readEpochSec(_in);
        }
        ZoneOffset[] stdOffsets = new ZoneOffset[stdSize + 1];
        for (int i = 0; i < stdOffsets.length; i++)
        {
            stdOffsets[i] = Ser.readOffset(_in);
        }
        int savSize = _in.readInt();
        long[] savTrans = (savSize == 0) ? EMPTY_LONG_ARRAY : new long[savSize];
        for (int i = 0; i < savSize; i++)
        {
            savTrans[i] = Ser.readEpochSec(_in);
        }
        ZoneOffset[] savOffsets = new ZoneOffset[savSize + 1];
        for (int i = 0; i < savOffsets.length; i++)
        {
            savOffsets[i] = Ser.readOffset(_in);
        }
        int ruleSize = _in.readByte();
        ZoneOffsetTransitionRule[] rules = (ruleSize == 0) ? EMPTY_LASTRULES
            : new ZoneOffsetTransitionRule[ruleSize];
        for (int i = 0; i < ruleSize; i++)
        {
            rules[i] = ZoneOffsetTransitionRule.readExternal(_in);
        }
        return new ZoneRules(stdTrans, stdOffsets, savTrans, savOffsets, rules);
    }

    /**
     * Checks of the zone rules are fixed, such that the offset never varies.
     *
     * @return true if the time-zone is fixed and the offset never changes
     */
    public bool isFixedOffset()
    {
        return savingsInstantTransitions.length == 0;
    }

    /**
     * Gets the offset applicable at the specified instant _in these rules.
     * !(p)
     * The mapping from an instant to an offset is simple, there is only
     * one valid offset for each instant.
     * This method returns that offset.
     *
     * @param instant  the instant to find the offset for, not null, but null
     *  may be ignored if the rules have a single offset for all instants
     * @return the offset, not null
     */
    public ZoneOffset getOffset(Instant instant)
    {
        if (savingsInstantTransitions.length == 0)
        {
            return standardOffsets[0];
        }
        long epochSec = instant.getEpochSecond();
        // check if using last rules
        if (lastRules.length > 0
                && epochSec > savingsInstantTransitions[savingsInstantTransitions.length - 1])
        {
            int year = findYear(epochSec, wallOffsets[wallOffsets.length - 1]);
            ZoneOffsetTransition[] transArray = findTransitionArray(year);
            ZoneOffsetTransition trans = null;
            for (int i = 0; i < transArray.length; i++)
            {
                trans = transArray[i];
                if (epochSec < trans.toEpochSecond())
                {
                    return trans.getOffsetBefore();
                }
            }
            return trans.getOffsetAfter();
        }

        // using historic rules
        import hunt.string.common;

        int index = Arrays.binarySearch(savingsInstantTransitions, epochSec);
        if (index == -1)
            index = -(cast(int)(savingsInstantTransitions.length)) - 1;
        if (index < 0)
        {
            // switch negative insert position to start of matched range
            index = -index - 2;
        }
        return wallOffsets[index + 1];
    }

    /**
     * Gets a suitable offset for the specified local date-time _in these rules.
     * !(p)
     * The mapping from a local date-time to an offset is not straightforward.
     * There are three cases:
     * !(ul)
     * !(li)Normal, with one valid offset. For the vast majority of the year, the normal
     *  case applies, where there is a single valid offset for the local date-time.</li>
     * !(li)Gap, with zero valid offsets. This is when clocks jump forward typically
     *  due to the spring daylight savings change from "winter" to "summer".
     *  In a gap there are local date-time values with no valid offset.</li>
     * !(li)Overlap, with two valid offsets. This is when clocks are set back typically
     *  due to the autumn daylight savings change from "summer" to "winter".
     *  In an overlap there are local date-time values with two valid offsets.</li>
     * </ul>
     * Thus, for any given local date-time there can be zero, one or two valid offsets.
     * This method returns the single offset _in the Normal case, and _in the Gap or Overlap
     * case it returns the offset before the transition.
     * !(p)
     * Since, _in the case of Gap and Overlap, the offset returned is a "best" value, rather
     * than the "correct" value, it should be treated with care. Applications that care
     * about the correct offset should use a combination of this method,
     * {@link #getValidOffsets(LocalDateTime)} and {@link #getTransition(LocalDateTime)}.
     *
     * @param localDateTime  the local date-time to query, not null, but null
     *  may be ignored if the rules have a single offset for all instants
     * @return the best available offset for the local date-time, not null
     */
    public ZoneOffset getOffset(LocalDateTime localDateTime)
    {
        Object info = getOffsetInfo(localDateTime);
        if (cast(ZoneOffsetTransition)(info) !is null)
        {
            return (cast(ZoneOffsetTransition) info).getOffsetBefore();
        }
        return cast(ZoneOffset) info;
    }

    /**
     * Gets the offset applicable at the specified local date-time _in these rules.
     * !(p)
     * The mapping from a local date-time to an offset is not straightforward.
     * There are three cases:
     * !(ul)
     * !(li)Normal, with one valid offset. For the vast majority of the year, the normal
     *  case applies, where there is a single valid offset for the local date-time.</li>
     * !(li)Gap, with zero valid offsets. This is when clocks jump forward typically
     *  due to the spring daylight savings change from "winter" to "summer".
     *  In a gap there are local date-time values with no valid offset.</li>
     * !(li)Overlap, with two valid offsets. This is when clocks are set back typically
     *  due to the autumn daylight savings change from "summer" to "winter".
     *  In an overlap there are local date-time values with two valid offsets.</li>
     * </ul>
     * Thus, for any given local date-time there can be zero, one or two valid offsets.
     * This method returns that list of valid offsets, which is a list of size 0, 1 or 2.
     * In the case where there are two offsets, the earlier offset is returned at index 0
     * and the later offset at index 1.
     * !(p)
     * There are various ways to handle the conversion from a {@code LocalDateTime}.
     * One technique, using this method, would be:
     * !(pre)
     *  List&lt;ZoneOffset&gt; validOffsets = rules.getOffset(localDT);
     *  if (validOffsets.size() == 1) {
     *    // Normal case: only one valid offset
     *    zoneOffset = validOffsets.get(0);
     *  } else {
     *    // Gap or Overlap: determine what to do from transition (which will be non-null)
     *    ZoneOffsetTransition trans = rules.getTransition(localDT);
     *  }
     * </pre>
     * !(p)
     * In theory, it is possible for there to be more than two valid offsets.
     * This would happen if clocks to be put back more than once _in quick succession.
     * This has never happened _in the history of time-zones and thus has no special handling.
     * However, if it were to happen, then the list would return more than 2 entries.
     *
     * @param localDateTime  the local date-time to query for valid offsets, not null, but null
     *  may be ignored if the rules have a single offset for all instants
     * @return the list of valid offsets, may be immutable, not null
     */
    public List!(ZoneOffset) getValidOffsets(LocalDateTime localDateTime)
    {
        // should probably be optimized
        Object info = getOffsetInfo(localDateTime);
        if (cast(ZoneOffsetTransition)(info) !is null)
        {
            return (cast(ZoneOffsetTransition) info).getValidOffsets();
        }
        return Collections.singletonList(cast(ZoneOffset) info);
    }

    /**
     * Gets the offset transition applicable at the specified local date-time _in these rules.
     * !(p)
     * The mapping from a local date-time to an offset is not straightforward.
     * There are three cases:
     * !(ul)
     * !(li)Normal, with one valid offset. For the vast majority of the year, the normal
     *  case applies, where there is a single valid offset for the local date-time.</li>
     * !(li)Gap, with zero valid offsets. This is when clocks jump forward typically
     *  due to the spring daylight savings change from "winter" to "summer".
     *  In a gap there are local date-time values with no valid offset.</li>
     * !(li)Overlap, with two valid offsets. This is when clocks are set back typically
     *  due to the autumn daylight savings change from "summer" to "winter".
     *  In an overlap there are local date-time values with two valid offsets.</li>
     * </ul>
     * A transition is used to model the cases of a Gap or Overlap.
     * The Normal case will return null.
     * !(p)
     * There are various ways to handle the conversion from a {@code LocalDateTime}.
     * One technique, using this method, would be:
     * !(pre)
     *  ZoneOffsetTransition trans = rules.getTransition(localDT);
     *  if (trans !is null) {
     *    // Gap or Overlap: determine what to do from transition
     *  } else {
     *    // Normal case: only one valid offset
     *    zoneOffset = rule.getOffset(localDT);
     *  }
     * </pre>
     *
     * @param localDateTime  the local date-time to query for offset transition, not null, but null
     *  may be ignored if the rules have a single offset for all instants
     * @return the offset transition, null if the local date-time is not _in transition
     */
    public ZoneOffsetTransition getTransition(LocalDateTime localDateTime)
    {
        Object info = getOffsetInfo(localDateTime);
        return (cast(ZoneOffsetTransition)(info) !is null ? cast(ZoneOffsetTransition) info : null);
    }

    private Object getOffsetInfo(LocalDateTime dt)
    {
        if (savingsInstantTransitions.length == 0)
        {
            return standardOffsets[0];
        }
        // check if using last rules
        if (lastRules.length > 0
                && dt.isAfter(savingsLocalTransitions[savingsLocalTransitions.length - 1]))
        {
            ZoneOffsetTransition[] transArray = findTransitionArray(dt.getYear());
            Object info = null;
            foreach (ZoneOffsetTransition trans; transArray)
            {
                info = findOffsetInfo(dt, trans);
                if (cast(ZoneOffsetTransition)(info) !is null || (info == trans.getOffsetBefore()))
                {
                    return info;
                }
            }
            return info;
        }

        // using historic rules
        int index = Arrays.binarySearch(savingsLocalTransitions, dt);
        if (index == -1)
        {
            // before first transition
            return wallOffsets[0];
        }
        if (index < 0)
        {
            // switch negative insert position to start of matched range
            index = -index - 2;
        }
        else if (index < savingsLocalTransitions.length - 1
                && (savingsLocalTransitions[index] == savingsLocalTransitions[index + 1]))
        {
            // handle overlap immediately following gap
            index++;
        }
        if ((index & 1) == 0)
        {
            // gap or overlap
            LocalDateTime dtBefore = savingsLocalTransitions[index];
            LocalDateTime dtAfter = savingsLocalTransitions[index + 1];
            ZoneOffset offsetBefore = wallOffsets[index / 2];
            ZoneOffset offsetAfter = wallOffsets[index / 2 + 1];
            if (offsetAfter.getTotalSeconds() > offsetBefore.getTotalSeconds())
            {
                // gap
                return new ZoneOffsetTransition(dtBefore, offsetBefore, offsetAfter);
            }
            else
            {
                // overlap
                return new ZoneOffsetTransition(dtAfter, offsetBefore, offsetAfter);
            }
        }
        else
        {
            // normal (neither gap or overlap)
            return wallOffsets[index / 2 + 1];
        }
    }

    /**
     * Finds the offset info for a local date-time and transition.
     *
     * @param dt  the date-time, not null
     * @param trans  the transition, not null
     * @return the offset info, not null
     */
    private Object findOffsetInfo(LocalDateTime dt, ZoneOffsetTransition trans)
    {
        LocalDateTime localTransition = trans.getDateTimeBefore();
        if (trans.isGap())
        {
            if (dt.isBefore(localTransition))
            {
                return trans.getOffsetBefore();
            }
            if (dt.isBefore(trans.getDateTimeAfter()))
            {
                return trans;
            }
            else
            {
                return trans.getOffsetAfter();
            }
        }
        else
        {
            if (dt.isBefore(localTransition) == false)
            {
                return trans.getOffsetAfter();
            }
            if (dt.isBefore(trans.getDateTimeAfter()))
            {
                return trans.getOffsetBefore();
            }
            else
            {
                return trans;
            }
        }
    }

    /**
     * Finds the appropriate transition array for the given year.
     *
     * @param year  the year, not null
     * @return the transition array, not null
     */
    private ZoneOffsetTransition[] findTransitionArray(int year)
    {
        Integer yearObj = new Integer(year); // should use Year class, but this saves a class load
        ZoneOffsetTransition[] transArray = lastRulesCache.get(yearObj);
        if (transArray !is null)
        {
            return transArray;
        }
        ZoneOffsetTransitionRule[] ruleArray = lastRules;
        transArray = new ZoneOffsetTransition[ruleArray.length];
        for (int i = 0; i < ruleArray.length; i++)
        {
            transArray[i] = ruleArray[i].createTransition(year);
        }
        if (year < LAST_CACHED_YEAR)
        {
            lastRulesCache.putIfAbsent(yearObj, transArray);
        }
        return transArray;
    }

    /**
     * Gets the standard offset for the specified instant _in this zone.
     * !(p)
     * This provides access to historic information on how the standard offset
     * has changed over time.
     * The standard offset is the offset before any daylight saving time is applied.
     * This is typically the offset applicable during winter.
     *
     * @param instant  the instant to find the offset information for, not null, but null
     *  may be ignored if the rules have a single offset for all instants
     * @return the standard offset, not null
     */
    public ZoneOffset getStandardOffset(Instant instant)
    {
        if (savingsInstantTransitions.length == 0)
        {
            return standardOffsets[0];
        }
        long epochSec = instant.getEpochSecond();
        int index = Arrays.binarySearch(standardTransitions, epochSec);
        if (index < 0)
        {
            // switch negative insert position to start of matched range
            index = -index - 2;
        }
        return standardOffsets[index + 1];
    }

    /**
     * Gets the amount of daylight savings _in use for the specified instant _in this zone.
     * !(p)
     * This provides access to historic information on how the amount of daylight
     * savings has changed over time.
     * This is the difference between the standard offset and the actual offset.
     * Typically the amount is zero during winter and one hour during summer.
     * Time-zones are second-based, so the nanosecond part of the duration will be zero.
     * !(p)
     * This default implementation calculates the duration from the
     * {@link #getOffset(hunt.time.Instant) actual} and
     * {@link #getStandardOffset(hunt.time.Instant) standard} offsets.
     *
     * @param instant  the instant to find the daylight savings for, not null, but null
     *  may be ignored if the rules have a single offset for all instants
     * @return the difference between the standard and actual offset, not null
     */
    public Duration getDaylightSavings(Instant instant)
    {
        if (savingsInstantTransitions.length == 0)
        {
            return Duration.ZERO;
        }
        ZoneOffset standardOffset = getStandardOffset(instant);
        ZoneOffset actualOffset = getOffset(instant);
        return Duration.ofSeconds(actualOffset.getTotalSeconds() - standardOffset.getTotalSeconds());
    }

    /**
     * Checks if the specified instant is _in daylight savings.
     * !(p)
     * This checks if the standard offset and the actual offset are the same
     * for the specified instant.
     * If they are not, it is assumed that daylight savings is _in operation.
     * !(p)
     * This default implementation compares the {@link #getOffset(hunt.time.Instant) actual}
     * and {@link #getStandardOffset(hunt.time.Instant) standard} offsets.
     *
     * @param instant  the instant to find the offset information for, not null, but null
     *  may be ignored if the rules have a single offset for all instants
     * @return the standard offset, not null
     */
    public bool isDaylightSavings(Instant instant)
    {
        return ((getStandardOffset(instant) == getOffset(instant)) == false);
    }

    /**
     * Checks if the offset date-time is valid for these rules.
     * !(p)
     * To be valid, the local date-time must not be _in a gap and the offset
     * must match one of the valid offsets.
     * !(p)
     * This default implementation checks if {@link #getValidOffsets(hunt.time.LocalDateTime)}
     * contains the specified offset.
     *
     * @param localDateTime  the date-time to check, not null, but null
     *  may be ignored if the rules have a single offset for all instants
     * @param offset  the offset to check, null returns false
     * @return true if the offset date-time is valid for these rules
     */
    public bool isValidOffset(LocalDateTime localDateTime, ZoneOffset offset)
    {
        return getValidOffsets(localDateTime).contains(offset);
    }

    /**
     * Gets the next transition after the specified instant.
     * !(p)
     * This returns details of the next transition after the specified instant.
     * For example, if the instant represents a point where "Summer" daylight savings time
     * applies, then the method will return the transition to the next "Winter" time.
     *
     * @param instant  the instant to get the next transition after, not null, but null
     *  may be ignored if the rules have a single offset for all instants
     * @return the next transition after the specified instant, null if this is after the last transition
     */
    public ZoneOffsetTransition nextTransition(Instant instant)
    {
        if (savingsInstantTransitions.length == 0)
        {
            return null;
        }
        long epochSec = instant.getEpochSecond();
        // check if using last rules
        if (epochSec >= savingsInstantTransitions[savingsInstantTransitions.length - 1])
        {
            if (lastRules.length == 0)
            {
                return null;
            }
            // search year the instant is _in
            int year = findYear(epochSec, wallOffsets[wallOffsets.length - 1]);
            ZoneOffsetTransition[] transArray = findTransitionArray(year);
            foreach (ZoneOffsetTransition trans; transArray)
            {
                if (epochSec < trans.toEpochSecond())
                {
                    return trans;
                }
            }
            // use first from following year
            if (year < 999_999_999/* Year.MAX_VALUE */)
            {
                transArray = findTransitionArray(year + 1);
                return transArray[0];
            }
            return null;
        }

        // using historic rules
        int index = Arrays.binarySearch(savingsInstantTransitions, epochSec);
        if (index < 0)
        {
            index = -index - 1; // switched value is the next transition
        }
        else
        {
            index += 1; // exact match, so need to add one to get the next
        }
        return new ZoneOffsetTransition(savingsInstantTransitions[index],
                wallOffsets[index], wallOffsets[index + 1]);
    }

    /**
     * Gets the previous transition before the specified instant.
     * !(p)
     * This returns details of the previous transition before the specified instant.
     * For example, if the instant represents a point where "summer" daylight saving time
     * applies, then the method will return the transition from the previous "winter" time.
     *
     * @param instant  the instant to get the previous transition after, not null, but null
     *  may be ignored if the rules have a single offset for all instants
     * @return the previous transition before the specified instant, null if this is before the first transition
     */
    public ZoneOffsetTransition previousTransition(Instant instant)
    {
        if (savingsInstantTransitions.length == 0)
        {
            return null;
        }
        long epochSec = instant.getEpochSecond();
        if (instant.getNano() > 0 && epochSec < Long.MAX_VALUE)
        {
            epochSec += 1; // allow rest of method to only use seconds
        }

        // check if using last rules
        long lastHistoric = savingsInstantTransitions[savingsInstantTransitions.length - 1];
        if (lastRules.length > 0 && epochSec > lastHistoric)
        {
            // search year the instant is _in
            ZoneOffset lastHistoricOffset = wallOffsets[wallOffsets.length - 1];
            int year = findYear(epochSec, lastHistoricOffset);
            ZoneOffsetTransition[] transArray = findTransitionArray(year);
            for (int i = cast(int)(transArray.length) - 1; i >= 0; i--)
            {
                if (epochSec > transArray[i].toEpochSecond())
                {
                    return transArray[i];
                }
            }
            // use last from preceding year
            int lastHistoricYear = findYear(lastHistoric, lastHistoricOffset);
            if (--year > lastHistoricYear)
            {
                transArray = findTransitionArray(year);
                return transArray[transArray.length - 1];
            }
            // drop through
        }

        // using historic rules
        int index = Arrays.binarySearch(savingsInstantTransitions, epochSec);
        if (index < 0)
        {
            index = -index - 1;
        }
        if (index <= 0)
        {
            return null;
        }
        return new ZoneOffsetTransition(savingsInstantTransitions[index - 1],
                wallOffsets[index - 1], wallOffsets[index]);
    }

    private int findYear(long epochSecond, ZoneOffset offset)
    {
        // inline for performance
        long localSecond = epochSecond + offset.getTotalSeconds();
        long localEpochDay = Math.floorDiv(localSecond, 86400);
        return LocalDate.ofEpochDay(localEpochDay).getYear();
    }

    /**
     * Gets the complete list of fully defined transitions.
     * !(p)
     * The complete set of transitions for this rules instance is defined by this method
     * and {@link #getTransitionRules()}. This method returns those transitions that have
     * been fully defined. These are typically historical, but may be _in the future.
     * !(p)
     * The list will be empty for fixed offset rules and for any time-zone where there has
     * only ever been a single offset. The list will also be empty if the transition rules are unknown.
     *
     * @return an immutable list of fully defined transitions, not null
     */
    public List!(ZoneOffsetTransition) getTransitions()
    {
        List!(ZoneOffsetTransition) list = new ArrayList!(ZoneOffsetTransition)();
        for (int i = 0; i < savingsInstantTransitions.length; i++)
        {
            list.add(new ZoneOffsetTransition(savingsInstantTransitions[i],
                    wallOffsets[i], wallOffsets[i + 1]));
        }
        return  /* Collections.unmodifiableList */ (list);
    }

    /**
     * Gets the list of transition rules for years beyond those defined _in the transition list.
     * !(p)
     * The complete set of transitions for this rules instance is defined by this method
     * and {@link #getTransitions()}. This method returns instances of {@link ZoneOffsetTransitionRule}
     * that define an algorithm for when transitions will occur.
     * !(p)
     * For any given {@code ZoneRules}, this list contains the transition rules for years
     * beyond those years that have been fully defined. These rules typically refer to future
     * daylight saving time rule changes.
     * !(p)
     * If the zone defines daylight savings into the future, then the list will normally
     * be of size two and hold information about entering and exiting daylight savings.
     * If the zone does not have daylight savings, or information about future changes
     * is uncertain, then the list will be empty.
     * !(p)
     * The list will be empty for fixed offset rules and for any time-zone where there is no
     * daylight saving time. The list will also be empty if the transition rules are unknown.
     *
     * @return an immutable list of transition rules, not null
     */
    public List!(ZoneOffsetTransitionRule) getTransitionRules()
    {
        auto l = new ArrayList!ZoneOffsetTransitionRule();
        foreach (item; lastRules)
        {
            l.add(item);
        }
        return l;
    }

    /**
     * Checks if this set of rules equals another.
     * !(p)
     * Two rule sets are equal if they will always result _in the same output
     * for any given input instant or local date-time.
     * Rules from two different groups may return false even if they are _in fact the same.
     * !(p)
     * This definition should result _in implementations comparing their entire state.
     *
     * @param otherRules  the other rules, null returns false
     * @return true if this rules is the same as that specified
     */
    override public bool opEquals(Object otherRules)
    {
        if (this == otherRules)
        {
            return true;
        }
        import std.algorithm : equal;

        if (cast(ZoneRules)(otherRules) !is null)
        {
            ZoneRules other = cast(ZoneRules) otherRules;
            return equal(standardTransitions, other.standardTransitions)
                && equal(standardOffsets, other.standardOffsets)
                && equal(savingsInstantTransitions,
                        other.savingsInstantTransitions) && equal(wallOffsets,
                        other.wallOffsets) && equal(lastRules, other.lastRules);
        }
        return false;
    }

    /**
     * Returns a suitable hash code given the definition of {@code #equals}.
     *
     * @return the hash code
     */
    override public size_t toHash() @trusted nothrow
    {
        return hashOf(standardTransitions) ^ hashOf(standardOffsets) ^ hashOf(
                savingsInstantTransitions) ^ hashOf(wallOffsets) ^ hashOf(lastRules);
    }

    /**
     * Returns a string describing this object.
     *
     * @return a string for debugging, not null
     */
    override public string toString()
    {
        return "ZoneRules[currentStandardOffset="
            ~ standardOffsets[standardOffsets.length - 1].toString ~ "]";
    }

}
