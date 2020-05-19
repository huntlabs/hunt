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

module hunt.io.channel.Common;

import hunt.io.IoError;
import hunt.io.ByteBuffer;
import hunt.io.SimpleQueue;
import hunt.util.TaskPool;
import hunt.Functions;
import hunt.system.Memory;

import core.atomic;
import std.socket;


alias DataReceivedHandler = void delegate(ByteBuffer buffer);
alias AcceptHandler = void delegate(Socket socket);
alias ErrorEventHandler = Action1!(IoError);

alias ConnectionHandler = void delegate(bool isSucceeded);
alias UdpDataHandler = void delegate(const(ubyte)[] data, Address addr);

@property TaskPool workerPool() @trusted {
    import std.concurrency : initOnce;

    __gshared TaskPool pool;
    return initOnce!pool({
        auto p = new TaskPool(defaultPoolThreads);
        p.isDaemon = true;
        return p;
    }());
}

// __gshared bool useWorkerThread = false;

private shared uint _defaultPoolThreads = 0;

/**
These properties get and set the number of worker threads in the `TaskPool`
instance returned by `taskPool`.  The default value is `totalCPUs` - 1.
Calling the setter after the first call to `taskPool` does not changes
number of worker threads in the instance returned by `taskPool`.
*/
@property uint defaultPoolThreads() @trusted {
    const local = atomicLoad(_defaultPoolThreads);
    return local < uint.max ? local : totalCPUs - 1;
}

/// Ditto
@property void defaultPoolThreads(uint newVal) @trusted {
    atomicStore(_defaultPoolThreads, newVal);
}


/**
*/
interface Channel {

}



enum ChannelType : ubyte {
    Accept = 0,
    TCP,
    UDP,
    Timer,
    Event,
    File,
    None
}

enum ChannelFlag : ushort {
    None = 0,
    Read,
    Write,

    OneShot = 8,
    ETMode = 16
}

final class UdpDataObject {
    Address addr;
    ubyte[] data;
}

final class BaseTypeObject(T) {
    T data;
}



version (HUNT_IO_WORKERPOOL) {
    alias WritingBufferQueue = MagedNonBlockingQueue!ByteBuffer;
} else {
    alias WritingBufferQueue = SimpleQueue!ByteBuffer;
}

// alias WritingBufferQueue = MagedNonBlockingQueue!ByteBuffer;
// alias WritingBufferQueue = SimpleQueue!ByteBuffer;
// alias WritingBufferQueue = MagedBlockingQueue!ByteBuffer;

/**
*/
Address createAddress(AddressFamily family = AddressFamily.INET,
        ushort port = InternetAddress.PORT_ANY) {
    if (family == AddressFamily.INET6) {
        // addr = new Internet6Address(port); // bug on windows
        return new Internet6Address("::", port);
    } else
        return new InternetAddress(port);
}
