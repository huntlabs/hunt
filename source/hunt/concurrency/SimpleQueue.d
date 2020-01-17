module hunt.concurrency.SimpleQueue;

import hunt.Exceptions;
import hunt.logging.ConsoleLogger;

import core.thread;
import core.sync.semaphore : Semaphore;
import core.sync.condition;
import core.sync.mutex : Mutex;
import core.atomic;

import std.datetime;

// ported from https://github.com/qznc/d-queues

/** Implementations based on the paper
    "Simple, fast, and practical non-blocking and blocking concurrent queue algorithms"
    by Maged and Michael. "*/

/** Basic interface for all queues implemented here.
    Is an input and output range. 
*/
interface Queue(T) {
    /** Atomically put one element into the queue. */
    void enqueue(T t);

    /** Atomically take one element from the queue.
      Wait blocking or spinning. */
    T dequeue();

    /**
      If at least one element is in the queue,
      atomically take one element from the queue
      store it into e, and return true.
      Otherwise return false; */
    bool tryDequeue(out T e);
}

private class QueueNode(T) {
    QueueNode!T nxt;
    T value;

    this() {} 

    this(T value) {
        this.value = value;
    }
}

/** blocking multi-producer multi-consumer queue  */
class BlockingQueue(T) : Queue!T {
    private QueueNode!T head;
    private QueueNode!T tail;
    private Mutex head_lock;
    private Mutex tail_lock;
    private shared bool isWaking = false;

    /** Wait queue for waiting takes */
    private Condition notEmpty;

    this() {
        auto n = new QueueNode!T();
        this.head = this.tail = n;
        this.head_lock = new Mutex();
        this.tail_lock = new Mutex();
        notEmpty = new Condition(head_lock);
    }

    void enqueue(T t) {
        auto end = new QueueNode!T();
        this.tail_lock.lock();
        scope (exit)
            this.tail_lock.unlock();
        auto tl = this.tail;
        this.tail = end;
        tl.value = t;
        atomicFence();
        tl.nxt = end; // accessible to dequeue
        notEmpty.notify();
    }

    T dequeue() {
        this.head_lock.lock();
        scope (exit)
            this.head_lock.unlock();
        while (true) { // FIXME non-blocking!
            auto hd = this.head;
            auto scnd = hd.nxt;
            if (scnd !is null) {
                this.head = scnd;
                return hd.value;
            } else {
                if(isWaking)
                    return T.init;
                notEmpty.wait();
            }
        }
        assert(0);
    }

    bool tryDequeue(out T e) {
        this.head_lock.lock();
        scope (exit)
            this.head_lock.unlock();
        auto hd = this.head;
        auto scnd = hd.nxt;
        if (scnd !is null) {
            this.head = scnd;
            e = hd.value;
            return true;
        }
        return false;
    }

    bool isEmpty() {
        return this.head.nxt is null;
    }

    void clear() {
        this.head_lock.lock();
        scope (exit)
            this.head_lock.unlock();
        
        auto n = new QueueNode!T();
        this.head = this.tail = n;
    }

    void wakeup() {
        if(cas(&isWaking, false, true))
            notEmpty.notify();
    }
}

/** non-blocking multi-producer multi-consumer queue  */
class NonBlockingQueue(T) : Queue!T {
    private shared(QueueNode!T) head;
    private shared(QueueNode!T) tail;
    private shared bool isWaking = false;

    this() {
        shared n = new QueueNode!T();
        this.head = this.tail = n;
    }

    void enqueue(T t) {
        shared end = new QueueNode!T();
        end.value = cast(shared)t;
        while (true) {
            auto tl = tail;
            auto cur = tl.nxt;
            if (cur !is null) {
                // obsolete tail, try update
                cas(&this.tail, tl, cur);
                continue;
            }
            shared(QueueNode!T) dummy = null;
            if (cas(&tl.nxt, dummy, end)) {
                // successfull enqueued new end node
                break;
            }
        }
    }

    T dequeue() {
        T e = void;
        while (!tryDequeue(e)) {
            Thread.yield();
        }
        // tryDequeue(e);
        return e;
    }

    bool tryDequeue(out T e) {
        auto dummy = this.head;
        auto tl = this.tail;
        auto nxt = dummy.nxt;

        if(nxt is null)
            return false;
        
        if (cas(&this.head, dummy, nxt)) {
            e = cast(T)nxt.value;
            return true;
        }
        return tryDequeue(e);
    }

    bool isEmpty() {
        return this.head.nxt is null;
    }

    void clear() {        
        shared n = new QueueNode!T();
        this.head = this.tail = n;
    }
}


/**
 * 
 */
class SimpleQueue(T) : Queue!T {
    private QueueNode!T head;
    private QueueNode!T tail;

    this() {
        auto n = new QueueNode!T();
        this.head = this.tail = n;
    }

    void enqueue(T t) {
        auto end = new QueueNode!T(t);
        
        auto tl = this.tail;
        this.tail = end;
        tl.nxt = end; // acces
    }

    T dequeue() {
        T e = void;
        while (!tryDequeue(e)) {
            Thread.yield();
            version(HUNT_DANGER_DEBUG) warning("Running here");
        }
        return e;
    }

    T dequeue(Duration timeout) {
        T e = void;
        auto start = Clock.currTime;
        bool r = tryDequeue(e);
        while (!r && Clock.currTime < start + timeout) {
            debug {
                Duration dur = Clock.currTime - start;
                if(dur > 15.seconds) {
                    warningf("There is no element available in %s", dur);
                }
            }
            Thread.yield();
            r = tryDequeue(e);
        }

        if (!r) {
            throw new TimeoutException("Timeout in " ~ timeout.toString());
        }
        return e;
    }


    bool tryDequeue(out T e) {
        auto nxt = this.head.nxt;
        if(nxt is null)
            return false;
        
        this.head = nxt;
        e = cast(T)nxt.value;
        return true;
    }


    bool isEmpty() {
        return this.head.nxt is null;
    }

    void clear() {        
        auto n = new QueueNode!T();
        this.head = this.tail = n;
    }
}