module hunt.concurrency.ThreadLocalRandom;

import hunt.concurrency.atomic.AtomicHelper;
import hunt.util.DateTime;
import std.datetime;


/**
 * A random number generator isolated to the current thread.  Like the
 * global {@link java.util.Random} generator used by the {@link
 * java.lang.Math} class, a {@code ThreadLocalRandom} is initialized
 * with an internally generated seed that may not otherwise be
 * modified. When applicable, use of {@code ThreadLocalRandom} rather
 * than shared {@code Random} objects in concurrent programs will
 * typically encounter much less overhead and contention.  Use of
 * {@code ThreadLocalRandom} is particularly appropriate when multiple
 * tasks (for example, each a {@link ForkJoinTask}) use random numbers
 * in parallel in thread pools.
 *
 * <p>Usages of this class should typically be of the form:
 * {@code ThreadLocalRandom.current().nextX(...)} (where
 * {@code X} is {@code Int}, {@code Long}, etc).
 * When all usages are of this form, it is never possible to
 * accidentally share a {@code ThreadLocalRandom} across multiple threads.
 *
 * <p>This class also provides additional commonly used bounded random
 * generation methods.
 *
 * <p>Instances of {@code ThreadLocalRandom} are not cryptographically
 * secure.  Consider instead using {@link java.security.SecureRandom}
 * in security-sensitive applications. Additionally,
 * default-constructed instances do not use a cryptographically random
 * seed unless the {@linkplain System#getProperty system property}
 * {@code java.util.secureRandomSeed} is set to {@code true}.
 *
 * @author Doug Lea
 */
class ThreadLocalRandom {
    // These fields are used to build the high-performance PRNGs in the
    // concurrent code, and we can not risk accidental false sharing.    
    /** The current seed for a ThreadLocalRandom */
    static long threadLocalRandomSeed = 0;

    /** Probe hash value; nonzero if threadLocalRandomSeed initialized */
    static int threadLocalRandomProbe = 0;

    /** Secondary seed isolated from public ThreadLocalRandom sequence */
    static int threadLocalRandomSecondarySeed = 0;

    static shared long seeder = 0;
    
    /** Generates per-thread initialization/probe field */
    private static shared int probeGenerator = 0;

    /**
     * The seed increment.
     */
    private enum long GAMMA = 0x9e3779b97f4a7c15L;

    /**
     * The increment for generating probe values.
     */
    private enum int PROBE_INCREMENT = 0x9e3779b9;

    /**
     * The increment of seeder per new instance.
     */
    private enum long SEEDER_INCREMENT = 0xbb67ae8584caa73bL;

    /**
     * The least non-zero value returned by nextDouble(). This value
     * is scaled by a random value of 53 bits to produce a result.
     */
    private enum double DOUBLE_UNIT = 0x1.0p-53;  // 1.0  / (1L << 53)
    private enum float  FLOAT_UNIT  = 0x1.0p-24f; // 1.0f / (1 << 24)

    // IllegalArgumentException messages
    enum string BAD_BOUND = "bound must be positive";
    enum string BAD_RANGE = "bound must be greater than origin";
    enum string BAD_SIZE  = "size must be non-negative";    

    shared static this() {
        seeder = mix64(DateTimeHelper.currentTimeMillis()) ^
                         mix64(Clock.currStdTime()*100);
    }

    private static long mix64(long z) {
        z = (z ^ (z >>> 33)) * 0xff51afd7ed558ccdL;
        z = (z ^ (z >>> 33)) * 0xc4ceb9fe1a85ec53L;
        return z ^ (z >>> 33);
    }

    private static int mix32(long z) {
        z = (z ^ (z >>> 33)) * 0xff51afd7ed558ccdL;
        return cast(int)(((z ^ (z >>> 33)) * 0xc4ceb9fe1a85ec53L) >>> 32);
    }

    /**
     * Initialize Thread fields for the current thread.  Called only
     * when Thread.threadLocalRandomProbe is zero, indicating that a
     * thread local seed value needs to be generated. Note that even
     * though the initialization is purely thread-local, we need to
     * rely on (static) atomic generators to initialize the values.
     */
    static final void localInit() {
        int p = AtomicHelper.increment(probeGenerator, PROBE_INCREMENT);
        int probe = (p == 0) ? 1 : p; // skip 0
        long seed = mix64(AtomicHelper.getAndAdd(seeder, SEEDER_INCREMENT));
        threadLocalRandomSeed = seed;
        threadLocalRandomProbe = probe;
    }

    /**
     * Returns the probe value for the current thread without forcing
     * initialization. Note that invoking ThreadLocalRandom.current()
     * can be used to force initialization on zero return.
     */
    static int getProbe() {
        return threadLocalRandomProbe;
    }

    /**
     * Pseudo-randomly advances and records the given probe value for the
     * given thread.
     */
    static int advanceProbe(int probe) {
        probe ^= probe << 13;   // xorshift
        probe ^= probe >>> 17;
        probe ^= probe << 5;
        threadLocalRandomProbe = probe;
        return probe;
    }    

    /**
     * Returns the pseudo-randomly initialized or updated secondary seed.
     */
    static int nextSecondarySeed() {
        int r;
        if ((r = threadLocalRandomSecondarySeed) != 0) {
            r ^= r << 13;   // xorshift
            r ^= r >>> 17;
            r ^= r << 5; 
        }
        else if ((r = mix32(AtomicHelper.getAndAdd(seeder, SEEDER_INCREMENT))) == 0)
            r = 1; // avoid zero
        threadLocalRandomSecondarySeed = r;
        return r;
    }
}