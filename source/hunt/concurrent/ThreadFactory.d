/*
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.  Oracle designates this
 * particular file as subject to the "Classpath" exception as provided
 * by Oracle in the LICENSE file that accompanied this code.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 *
 * You should have received a copy of the GNU General Public License version
 * 2 along with this work; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
 * or visit www.oracle.com if you need additional information or have any
 * questions.
 */

/*
 * This file is available under and governed by the GNU General Public
 * License version 2 only, as published by the Free Software Foundation.
 * However, the following notice accompanied the original version of this
 * file:
 *
 * Written by Doug Lea with assistance from members of JCP JSR-166
 * Expert Group and released to the public domain, as explained at
 * http://creativecommons.org/publicdomain/zero/1.0/
 */

module hunt.concurrent.ThreadFactory;

import hunt.concurrent.atomic.AtomicHelper;
import hunt.concurrent.thread.ThreadEx;

import hunt.lang.common;

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

    
    Thread newThread(Action dg ) {
        int n = AtomicHelper.getAndIncrement(threadNumber);

        Thread t = new ThreadEx(dg);
        t.name = namePrefix ~ n.to!string();
        t.isDaemon = false;
        t.priority = Thread.PRIORITY_DEFAULT;

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