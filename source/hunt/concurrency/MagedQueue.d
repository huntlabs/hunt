module hunt.concurrency.MagedQueue;

import core.sync.semaphore : Semaphore;
import core.sync.condition;
import core.sync.mutex : Mutex;
import core.atomic;

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

private static class Cons(T) {
    public Cons!T nxt;
    public T value;
}

/** blocking multi-producer multi-consumer queue  */
class MagedBlockingQueue(T) : Queue!T {
    private Cons!T head;
    private Cons!T tail;
    private Mutex head_lock;
    private Mutex tail_lock;
    private shared bool isWaking = false;

    /** Wait queue for waiting takes */
    private Condition notEmpty;

    this() {
        auto n = new Cons!T();
        this.head = this.tail = n;
        this.head_lock = new Mutex();
        this.tail_lock = new Mutex();
        notEmpty = new Condition(head_lock);
    }

    void enqueue(T t) {
        auto end = new Cons!T();
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

    void wakeup() {
        this.head_lock.lock();
        scope (exit)
            this.head_lock.unlock();
        if(isWaking)
            return;
        // cas(isWaking, false, true);
        atomicStore(isWaking, true);
        notEmpty.notify();
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
}

/** non-blocking multi-producer multi-consumer queue  */
class MagedNonBlockingQueue(T) : Queue!T {
    private shared(Cons!T) head;
    private shared(Cons!T) tail;

    this() {
        shared n = new Cons!T();
        this.head = this.tail = n;
    }

    void enqueue(T t) {
        shared end = new Cons!T();
        end.value = t;
        while (true) {
            auto tl = tail;
            auto cur = tl.nxt;
            if (cur !is null) {
                // obsolete tail, try update
                cas(&this.tail, tl, cur);
                continue;
            }
            shared(Cons!T) dummy = null;
            if (cas(&tl.nxt, dummy, end)) {
                // successfull enqueued new end node
                break;
            }
        }
    }

    T dequeue() {
        T e = void;
        while (!tryDequeue(e)) {
        }
        // tryDequeue(e);
        return e;
    }

    bool tryDequeue(out T e) {
        auto dummy = this.head;
        auto tl = this.tail;
        auto nxt = dummy.nxt;
        if (dummy is tl) {
            if (nxt is null) { /* queue empty */
                return false;
            } else { /* tail is obsolete */
                cas(&this.tail, tl, nxt);
            }
        } else {
            if (cas(&this.head, dummy, nxt)) {
                e = nxt.value;
                return true;
            }
        }
        return false;
    }
}
