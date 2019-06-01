/**
 Buffer handling for iopipe.

Copyright: Copyright Steven Schveighoffer 2011-.
License:   Boost License 1.0. (See accompanying file LICENSE_1_0.txt or copy
           at http://www.boost.org/LICENSE_1_0.txt)
Authors:   Steven Schveighoffer, Dmitry Olshansky
See_also: 
    https://github.com/schveiguy/iopipe/blob/master/source/iopipe/buffer.d
 */
module hunt.collection.RingBuffer;

version (Posix): 


// A ringbuffer works by mmapping the same block to 2 consecutive memory pages.
// The type allocated MUST be a power of 2
import std.math : isPowerOf2;

/**
 * A RingBuffer uses the underlying memory management system to avoid any
 * copying of data (unless expanding).
 *
 * It works by using the OS's mechanisms that map memory (mmap or VirtualAlloc)
 * to map the same region to 2 consecutive addresses. This allows one to use a
 * buffer simply as an array, even when the data wraps around the end of the
 * buffer.
 *
 * Like AllocatedBuffer, the growth is limited to doubling, but this has an
 * extra restriction that the buffer must be a multiple of the page size. Note
 * that this does NOT add any memory to the GC, so do not store GC pointers in
 * this buffer.
 *
 * Unlike AllocatedBuffer, this buffer is NOT copyable, so it must be
 * refcounted if you are to pass it around. See rbufd which does this
 * automatically for you. The reason for this is that it must unmap the memory
 * on destruction.
 *
 * Params:
 *    T = The type of the elements the buffer will use. Must be sized as a power of 2.
 *    floorSize = The size that can be freely allocated before growth is
 *      restricted to 2x. Note that the OS imposes a floor size of one page in
 *      addition to this.
 */
struct RingBuffer(T, size_t floorSize = 8192) if (isPowerOf2(T.sizeof))
{
    @disable this(this); // we can't copy RingBuffer because otherwise it will deallocate the memory
    /**
     * Give bytes back to the buffer from the front of the buffer.
     * These bytes can be removed in this operation or further operations and
     * should no longer be used.
     *
     * Params: elements = number of elements to release.
     */
    void releaseFront(size_t elements)
    {
        assert(released + elements <= valid);
        released += elements;
        auto half = buffer.length / 2;
        if(released >= half)
        {
            released -= half;
            valid -= half;
        }
    }

    /**
     * Give bytes back to the buffer from the back of the buffer.
     * These bytes can be removed in this operation or further operations and
     * should no longer be used.
     *
     * Params: elements = number of elements to release.
     */
    void releaseBack(size_t elements)
    {
        assert(released + elements <= valid);
        valid -= elements;
    }

    /**
     * The window of currently valid data.
     */
    T[] window()
    {
        assert(released <= buffer.length && valid <= buffer.length);
        return buffer.ptr[released .. valid];
    }

    /**
     * Returns: The number of unused elements that can be extended without
     * needing to reallocate the buffer.
     */
    size_t avail()
    {
        return buffer.length / 2 - (valid - released);
    }

    /**
     * Returns: The total number of elements currently managed.
     */
    size_t capacity()
    {
        return buffer.length / 2;
    }

    /**
     * Add more data to the window of currently valid data. To avoid expensive
     * reallocation, use avail to tune this call.
     *
     * Params: request = The number of additional elements to add to the valid window.
     * Returns: The number of elements that were actually added to the valid
     * window. Note that this may be less than the request if more elements
     * could not be attained from the OS.
     */
    size_t extend(size_t request)
    {
        import std.algorithm.mutation : copy;
        import std.algorithm.comparison : max, min;
        import core.sys.posix.unistd;
        version (Posix) import core.sys.posix.sys.mman;
        version (FreeBSD) import core.sys.freebsd.sys.mman : MAP_FIXED, MAP_SHARED, MAP_ANON;
        version (NetBSD) import core.sys.netbsd.sys.mman : MAP_FIXED, MAP_SHARED, MAP_ANON;
        version (linux) import core.sys.linux.sys.mman : MAP_FIXED, MAP_SHARED, MAP_ANON;
        version (OSX) import core.sys.darwin.sys.mman : MAP_FIXED, MAP_SHARED, MAP_ANON;
        import core.sys.posix.fcntl;


        // check to see if we can "move" the data for free.
        auto validElems = valid - released;
        if(validElems == 0)
            valid = released = 0;


        // we should never have to move data
        immutable cap = buffer.length / 2;
        assert(valid + cap - released <= buffer.length);
        if(cap - validElems >= request)
        {
            // buffer has enough free space to accomodate.
            valid += request;
            return request;
        }


        // otherwise, we must allocate/extend a new buffer
        // limit growth to 2x.
        immutable maxBufSize = max(cap * 2, floorSize);

        // copy and allocate a new buffer
        auto oldLen = buffer.length;
        // grow by at least 1.4, but not more than maxBufSize
        request = min(request, maxBufSize - validElems);
        auto fullSize = max(validElems + request, oldLen * 14 / 10, floorSize) * T.sizeof;
        // round up to PAGESIZE
        fullSize = (fullSize + PAGESIZE - 1) / PAGESIZE * PAGESIZE;

        // mmap space to reserve the address space. We won't actually wire this
        // to any memory until we open the shared memory and map it.
        auto addr = mmap(null, fullSize * 2, PROT_NONE, MAP_SHARED | MAP_ANON, -1, 0);
        if(addr == MAP_FAILED)
            return 0;

        // attempt to make a name that won't conflict with other processes.
        // This is really sucky, but is required on posix systems, even though
        // we aren't really sharing memory.
        enum basename = "/iopipe_map_";
        char[basename.length + 8 + 1] shm_name = void;
        shm_name[0 .. basename.length] = basename;
        shm_name[basename.length .. $-1] = 'A';
        // get the process id
        import std.process: thisProcessID;
        uint pid = thisProcessID();
        auto idx = basename.length;
        while(pid)
        {
            shm_name[idx++] = cast(char)('A' + (pid & 0x0f));
            pid >>= 4;
        }
        shm_name[$-1] = 0;

        import std.conv: octal;
        import std.exception;
        int shfd = -1;
        idx = 0;
        while(shfd < 0)
        {
            // try 4 times to make this happen, if it doesn't, give up and
            // return 0. This helps solve any possible race conditions with
            // other threads. It's not perfect, but it should work reasonably
            // well.
            if(idx++ > 4)
            {
                munmap(addr, fullSize * 2);
                return 0;
            }
            shfd = shm_open(shm_name.ptr, O_RDWR | O_CREAT | O_EXCL, octal!"600");
            // immediately remove the name link, we don't really want to share anything here.
            shm_unlink(shm_name.ptr);
        }

        // after this function, we don't need the file descriptor.
        scope(exit) close(shfd);

        // create enough memory to hold the entire buffer.
        if(ftruncate(shfd, fullSize) < 0)
        {
            munmap(addr, fullSize * 2);
            return 0;
        }

        // map the shared memory into the reserved space twice, each half sees
        // the same memory.
        if(mmap(addr, fullSize, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_FIXED, shfd, 0) == MAP_FAILED)
        {
            munmap(addr, fullSize * 2);
            return 0;
        }
        if(mmap(addr + fullSize, fullSize, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_FIXED, shfd, 0) == MAP_FAILED)
        {
            munmap(addr, fullSize * 2);
            return 0;
        }
        auto newbuf = cast(T[])(addr[0 .. fullSize * 2]);
        if (validElems > 0) {
            copy(buffer[released .. valid], newbuf[0 .. validElems]);
        }
        valid = validElems + request;
        assert(valid <= newbuf.length / 2);
        released = 0;
        if(buffer.length)
            munmap(buffer.ptr, buffer.length * T.sizeof); // unmap the original memory
        buffer = newbuf;

        return request;
    }

    ~this()
    {
        if(buffer.ptr)
        {
            version (Posix)
            {
                import core.sys.posix.sys.mman;
                munmap(buffer.ptr, buffer.length * T.sizeof);
            }
        }
    }

private:
    // Note: the buffer is 2 mmaps to the same memory page.
    T[] buffer;
    // We will only ever use 1/2 of the buffer at the most, 
    size_t valid;
    size_t released;
}

unittest
{
    RingBuffer!(ubyte, 8192) buf;
    assert(buf.extend(4096) == 4096);
    assert(buf.avail == 8192 - 4096);
    assert(buf.capacity == 8192);
    buf.window[0] = 0;
    assert(buf.buffer.length == 8192 * 2);

    assert(buf.extend(4096) == 4096);
    assert(buf.avail == 0);
    assert(buf.capacity == 8192);

    buf.releaseFront(4096);
    assert(buf.avail == 4096);
    assert(buf.capacity == 8192);
    assert(buf.extend(4096) == 4096);
    assert(buf.avail == 0);
    assert(buf.capacity == 8192);
    import std.algorithm : copy, map, equal;
    import std.range : iota;
    iota(8192).map!(a => cast(ubyte)a).copy(buf.window);
    assert(equal(iota(8192).map!(a => cast(ubyte)a), buf.window));
    buf.releaseFront(4096);
    assert(equal(iota(4096, 8192).map!(a => cast(ubyte)a), buf.window));
    assert(buf.released == 0); // assure we wrap around
    assert(buf.extend(8192) == 8192);
    assert(equal(iota(4096, 8192).map!(a => cast(ubyte)a), buf.window[0 .. 4096]));
}

package static immutable size_t PAGESIZE;

// unfortunately, this is the only way to do it for now. Copied from
// core.thread
shared static this()
{
    version (Windows)
    {
        import core.sys.windows.windows;
        SYSTEM_INFO info;
        GetSystemInfo(&info);

        PAGESIZE = info.dwPageSize;
        assert(PAGESIZE < int.max);
    }
    else version (Posix)
    {
        import core.sys.posix.unistd;
        PAGESIZE = cast(size_t)sysconf(_SC_PAGESIZE);
    }
    else
    {
        static assert(0, "unimplemented");
    }
}
