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

module hunt.io.FileDescriptor;

import hunt.util.Common;
import hunt.Exceptions;

import std.container.array;
/**
 * Instances of the file descriptor class serve as an opaque handle
 * to the underlying machine-specific structure representing an
 * open file, an open socket, or another source or sink of bytes.
 * The main practical use for a file descriptor is to create a
 * {@link FileInputStream} or {@link FileOutputStream} to contain it.
 *
 * <p>Applications should not create their own file descriptors.
 *
 * @author  Pavani Diwanji
 */
final class FileDescriptor {

    private int fd;

    private long handle;

    private Closeable parent;
    private Array!Closeable otherParents;
    private bool closed;

    /**
     * Constructs an (invalid) FileDescriptor
     * object.
     */
    this() {
        fd = -1;
        handle = -1;
    }

    shared static this() {
        // initIDs();
    }

    // Set up JavaIOFileDescriptorAccess in SharedSecrets
    // static {
    //     sun.misc.SharedSecrets.setJavaIOFileDescriptorAccess(
    //         new sun.misc.JavaIOFileDescriptorAccess() {
    //             void set(FileDescriptor obj, int fd) {
    //                 obj.fd = fd;
    //             }

    //             int get(FileDescriptor obj) {
    //                 return obj.fd;
    //             }

    //             void setHandle(FileDescriptor obj, long handle) {
    //                 obj.handle = handle;
    //             }

    //             long getHandle(FileDescriptor obj) {
    //                 return obj.handle;
    //             }
    //         }
    //     );
    // }

    /**
     * A handle to the standard input stream. Usually, this file
     * descriptor is not used directly, but rather via the input stream
     * known as {@code System.in}.
     *
     * @see     java.lang.System#in
     */
    // __gshared FileDescriptor inHandle = standardStream(0);

    /**
     * A handle to the standard output stream. Usually, this file
     * descriptor is not used directly, but rather via the output stream
     * known as {@code System.out}.
     * @see     java.lang.System#out
     */
    // __gshared FileDescriptor outHandle = standardStream(1);

    /**
     * A handle to the standard error stream. Usually, this file
     * descriptor is not used directly, but rather via the output stream
     * known as {@code System.err}.
     *
     * @see     java.lang.System#err
     */
    // static final FileDescriptor err = standardStream(2);

    /**
     * Tests if this file descriptor object is valid.
     *
     * @return  {@code true} if the file descriptor object represents a
     *          valid, open file, socket, or other active I/O connection;
     *          {@code false} otherwise.
     */
    bool valid() {
        return ((handle != -1) || (fd != -1));
    }

    /**
     * Force all system buffers to synchronize with the underlying
     * device.  This method returns after all modified data and
     * attributes of this FileDescriptor have been written to the
     * relevant device(s).  In particular, if this FileDescriptor
     * refers to a physical storage medium, such as a file in a file
     * system, sync will not return until all in-memory modified copies
     * of buffers associated with this FileDesecriptor have been
     * written to the physical medium.
     *
     * sync is meant to be used by code that requires physical
     * storage (such as a file) to be in a known state  For
     * example, a class that provided a simple transaction facility
     * might use sync to ensure that all changes to a file caused
     * by a given transaction were recorded on a storage medium.
     *
     * sync only affects buffers downstream of this FileDescriptor.  If
     * any in-memory buffering is being done by the application (for
     * example, by a BufferedOutputStream object), those buffers must
     * be flushed into the FileDescriptor (for example, by invoking
     * OutputStream.flush) before that data will be affected by sync.
     *
     * @exception SyncFailedException
     *        Thrown when the buffers cannot be flushed,
     *        or because the system cannot guarantee that all the
     *        buffers have been synchronized with physical media.
     */
    void sync() {        
        implementationMissing(false);
    }

    /* This routine initializes JNI field offsets for the class */
    private static void initIDs() {
        implementationMissing(false);
    }

    private static long set(int d) {
        implementationMissing(false);
        return 0;
    }

    private static FileDescriptor standardStream(int fd) {
        FileDescriptor desc = new FileDescriptor();
        desc.handle = set(fd);
        return desc;
    }

    /*
     * Package private methods to track referents.
     * If multiple streams point to the same FileDescriptor, we cycle
     * through the list of all referents and call close()
     */

    /**
     * Attach a Closeable to this FD for tracking.
     * parent reference is added to otherParents when
     * needed to make closeAll simpler.
     */
    void attach(Closeable c) {
        if (parent is null) {
            // first caller gets to do this
            parent = c;
        } else if (otherParents.length == 0) {
            // otherParents = new ArrayList<>();
            otherParents.insertBack(parent);
            otherParents.insertBack(c);
        } else {
            otherParents.insertBack(c);
        }
    }

    /**
     * Cycle through all Closeables sharing this FD and call
     * close() on each one.
     *
     * The caller closeable gets to call close0().
     */
    void closeAll(Closeable releaser) {
        if (!closed) {
            closed = true;
            IOException ioe = null;
            try {
                Closeable c = releaser;
                foreach (Closeable referent ; otherParents) {
                    try {
                        referent.close();
                    } catch(IOException x) {
                        if (ioe is null) {
                            ioe = x;
                        } else {
                            ioe.next = x;
                        }
                    }
                }
            } catch(IOException ex) {
                /*
                 * If releaser close() throws IOException
                 * add other exceptions as suppressed.
                 */
                if (ioe !is null)
                    ex.next = ioe;
                ioe = ex;
            } finally {
                if (ioe !is null)
                    throw ioe;
            }
        }
    }
}
