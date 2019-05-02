/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2018-2019 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.concurrency.ThreadFactory;

import hunt.concurrency.atomic.AtomicHelper;
import hunt.concurrency.thread.ThreadEx;

import hunt.Functions;
import hunt.util.Common;

import core.thread;
import std.conv;

/**
 * An object that creates new threads on demand.  Using thread factories
 * removes hardwiring of calls to {@link Thread#Thread(Runnable) new Thread},
 * enabling applications to use special thread subclasses, priorities, etc.
 *
 * <p>
 * The simplest implementation of this interface is just:
 * <pre> {@code
 * class SimpleThreadFactory implements ThreadFactory {
 *   public Thread newThread(Runnable r) {
 *     return new Thread(r);
 *   }
 * }}</pre>
 *
 * The {@link Executors#defaultThreadFactory} method provides a more
 * useful simple implementation, that sets the created thread context
 * to known values before returning it.
 * @since 1.5
 * @author Doug Lea
 */
interface ThreadFactory {

    /**
     * Returns a default thread factory used to create new threads.
     * This factory creates all new threads used by an Executor in the
     * same {@link ThreadGroupEx}. If there is a {@link
     * java.lang.SecurityManager}, it uses the group of {@link
     * System#getSecurityManager}, else the group of the thread
     * invoking this {@code defaultThreadFactory} method. Each new
     * thread is created as a non-daemon thread with priority set to
     * the smaller of {@code Thread.PRIORITY_DEFAULT} and the maximum
     * priority permitted in the thread group.  New threads have names
     * accessible via {@link Thread#getName} of
     * <em>pool-N-thread-M</em>, where <em>N</em> is the sequence
     * number of this factory, and <em>M</em> is the sequence number
     * of the thread created by this factory.
     * @return a thread factory
     */
    static ThreadFactory defaultThreadFactory() {
        return new DefaultThreadFactory();
    }

    /**
     * Constructs a new {@code Thread}.  Implementations may also initialize
     * priority, name, daemon status, {@code ThreadGroupEx}, etc.
     *
     * @param r a runnable to be executed by new thread instance
     * @return constructed thread, or {@code null} if the request to
     *         create a thread is rejected
     */
    final Thread newThread(Runnable r) {
        return newThread({ r.run(); });
    }

    Thread newThread(Action dg );
}


/**
 * The default thread factory.
 */
private class DefaultThreadFactory : ThreadFactory {
    private static shared(int) poolNumber = 1;
    private ThreadGroupEx group;
    private shared(int) threadNumber = 1;
    private string namePrefix;

    this() {
        // SecurityManager s = System.getSecurityManager();
        // group = (s !is null) ? s.getThreadGroup() :
        //                       Thread.getThis().getThreadGroup();
        int n = AtomicHelper.getAndIncrement(poolNumber);
        namePrefix = "pool-" ~ n.to!string() ~ "-thread-";
    }

    
    ThreadEx newThread(Action dg ) {
        int n = AtomicHelper.getAndIncrement(threadNumber);

        ThreadEx t = new ThreadEx(dg);
        t.name = namePrefix ~ n.to!string();
        t.isDaemon = false;
        // version(Posix) {
        //     t.priority = Thread.PRIORITY_DEFAULT;
        // }

        return t;
    }
}


/**
 * Thread factory capturing access control context and class loader.
 */
// private class PrivilegedThreadFactory : DefaultThreadFactory {
//     // AccessControlContext acc;
//     // ClassLoader ccl;

//     this() {
//         super();
//         SecurityManager sm = System.getSecurityManager();
//         if (sm !is null) {
//             // Calls to getContextClassLoader from this class
//             // never trigger a security check, but we check
//             // whether our callers have this permission anyways.
//             sm.checkPermission(SecurityConstants.GET_CLASSLOADER_PERMISSION);

//             // Fail fast
//             sm.checkPermission(new RuntimePermission("setContextClassLoader"));
//         }
//         this.acc = AccessController.getContext();
//         this.ccl = Thread.getThis().getContextClassLoader();
//     }

//     Thread newThread(Runnable r) {
//         return super.newThread(new Runnable() {
//             void run() {
//                 AccessController.doPrivileged(new PrivilegedAction<>() {
//                     Void run() {
//                         Thread.getThis().setContextClassLoader(ccl);
//                         r.run();
//                         return null;
//                     }
//                 }, acc);
//             }
//         });
//     }
// }