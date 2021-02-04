module hunt.util.queue.SimpleQueue;

import hunt.logging.ConsoleLogger;
import hunt.util.queue.Queue;

import core.atomic;
import core.sync.condition;
import core.sync.mutex;
import core.time;

import core.thread;

import std.container.slist;



    shared int incomingCounter = 0;
    shared int notifyCounter = 0;
    shared int outgoingCounter2 = 0;

/**
 * It's a thread-safe queue
 */
class SimpleQueue2(T) : Queue!(T) {
    private SList!T _list;
    private Mutex _headLock;
    private Duration _timeout;
    private bool _isWaiting = false;

    shared int _incomings = 0;
    shared int _outgoings = 0;

    /** Wait queue for waiting takes */
    private Condition _notEmpty;

    this(Duration timeout = 10.seconds) {
        _timeout = timeout;
        _headLock = new Mutex();
        _notEmpty = new Condition(_headLock);
    }

    override bool isEmpty() {
        return _list.empty();
    }

    size_t size() {
        version (HUNT_METRIC) {
            return _incomings - _outgoings;
        } else {
            throw new Exception("Unimplemented");
        }
    }

    override T pop() {
        _headLock.lock();
        scope (exit) {
            _headLock.unlock();
        }

        if(isEmpty()) {
            _isWaiting = true;
            bool v = _notEmpty.wait(_timeout);
            _isWaiting = false;
            if(!v) {
                version (HUNT_IO_DEBUG) {
                    tracef("Timeout in %s. pop: %d, put: %d", _timeout, _outgoings, _incomings);
                }
                return T.init;
            }
        }

        version (HUNT_METRIC) {
            atomicOp!("+=")(_outgoings, 1);
        }

        T item = _list.front();
        _list.removeFront();

        return item;
    }

    override void push(T item) {
        _headLock.lock();
        scope (exit)
            _headLock.unlock();

        version (HUNT_METRIC) {
            uint id = atomicOp!("+=")(_incomings, 1);
        }

        _list.insert(item);

        if(_isWaiting)
            _notEmpty.notify();
    }


version (HUNT_METRIC) {
    override void inspect() {
        tracef("incomings: %d, outgoings: %d, size: %d", _incomings, _outgoings, size());
    }
}   
}



class SimpleQueue(T) : Queue!(T) {
    private SList!T _list;
    private Mutex _headLock;
    private Duration _timeout;
    private bool _isWaiting = false;

    shared int _incomings = 0;
    shared int _outgoings = 0;

    /** Wait queue for waiting takes */
    private Condition _notEmpty;

    this(Duration timeout = 10.seconds) {
        _timeout = timeout;
        _headLock = new Mutex();
        _notEmpty = new Condition(_headLock);
    }

    override bool isEmpty() {
        // _headLock.lock();
        // scope (exit)
        //     _headLock.unlock();

        return _list.empty();
    }

    size_t size() {
        version (HUNT_METRIC) {
            return _incomings - _outgoings;
        } else {
            throw new Exception("Unimplemented");
        }
    }

    override T pop() {
        _headLock.lock();
        scope (exit) {
            _headLock.unlock();
        }
        atomicOp!("+=")(outgoingCounter2, 1);

        if(isEmpty()) {
            _isWaiting = true;
            bool v = _notEmpty.wait(_timeout);
            _isWaiting = false;
            if(!v) {
                version (HUNT_IO_DEBUG) {
                    tracef("Timeout in %s. pop: %d, put: %d", _timeout, _outgoings, _incomings);
                }
                return T.init;
            }
        }

        version (HUNT_METRIC) {
            atomicOp!("+=")(_outgoings, 1);
        }

        T item = _list.front();
        _list.removeFront();

        return item;
    }

    override void push(T item) {
        _headLock.lock();
        scope (exit)
            _headLock.unlock();

        uint xx = atomicOp!("+=")(incomingCounter, 1);
        version (HUNT_METRIC) {
            uint id = atomicOp!("+=")(_incomings, 1);
        }

        _list.insert(item);

        if(_isWaiting) {
            atomicOp!("+=")(notifyCounter, 1);
            _notEmpty.notify();
        }
    }


version (HUNT_METRIC) {
    override void inspect() {
        tracef("SimpleQueue2 => incomings: %d, outgoings: %d, size: %d", _incomings, _outgoings, size());
    }
}   
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
class SimpleQueue22(T) : Queue!T {
    private QueueNode!T head;
    private QueueNode!T tail;
    private Mutex head_lock;
    private Mutex tail_lock;
    private shared bool isWaking = false;

    /** Wait queue for waiting takes */
    private Condition notEmpty;
    private Duration _timeout;

    shared int _incomings = 0;
    shared int _incomings2 = 0;
    shared int _outgoings = 0;

    this(Duration timeout = 10.seconds) {
        auto n = new QueueNode!T();
        this.head = this.tail = n;
        this.head_lock = new Mutex();
        this.tail_lock = new Mutex();
        notEmpty = new Condition(head_lock);
        _timeout = timeout;
    }
    
    size_t size() {
        version (HUNT_METRIC) {
            return _incomings - _outgoings;
        } else {
            throw new Exception("Unimplemented");
        }
    }
    
    override void push(T t) {
        
        uint xx = atomicOp!("+=")(incomingCounter, 1);

        // warningf("incomingCounter=%d", xx);

        version (HUNT_METRIC) {
            uint id = atomicOp!("+=")(_incomings, 1);
        }

        auto end = new QueueNode!T();
        this.tail_lock.lock();
        scope (exit) {
            
        version (HUNT_METRIC) {
             atomicOp!("+=")(_incomings2, 1);
        }
            this.tail_lock.unlock();
        }


        auto tl = this.tail;
        this.tail = end;
        tl.value = t;
        atomicFence();
        tl.nxt = end; // accessible to dequeue
        notEmpty.notify();
    }

    override T pop() {
        this.head_lock.lock();
        scope (exit)
            this.head_lock.unlock();


        while (true) { // FIXME non-blocking!
            auto hd = this.head;
            auto scnd = hd.nxt;
            if (scnd !is null) {
        version (HUNT_METRIC) {
            atomicOp!("+=")(_outgoings, 1);
        }
                this.head = scnd;
                return hd.value;
            } else {
                if(isWaking)
                    return T.init;
                bool r = notEmpty.wait(_timeout);
                if(!r) return T.init;
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

    override bool isEmpty() {
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

version (HUNT_METRIC) {
    override void inspect() {
        tracef("incomings: %d, %d, outgoings: %d, size: %d", _incomings, _incomings2, _outgoings, size());
    }
}    
}



/** non-blocking multi-producer multi-consumer queue  */
class SimpleQueue3(T) : Queue!T {
    private shared(QueueNode!T) head;
    private shared(QueueNode!T) tail;
    private shared bool isWaking = false;


    shared int _incomings = 0;
    shared int _incomings2 = 0;
    shared int _outgoings = 0;

    this() {
        shared n = new QueueNode!T();
        this.head = this.tail = n;
    }

    size_t size() {
        version (HUNT_METRIC) {
            return _incomings - _outgoings;
        } else {
            throw new Exception("Unimplemented");
        }
    }

    override void push(T t) {
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

    override T pop() {
        T e = void;
        while (!tryDequeue(e)) {
            Thread.yield();
        }
        // tryDequeue(e);
        return e;
    }

    bool tryDequeue(out T e) nothrow {
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

    override bool isEmpty() {
        return this.head.nxt is null;
    }

    void clear() {        
        shared n = new QueueNode!T();
        this.head = this.tail = n;
    }

version (HUNT_METRIC) {
    override void inspect() {
        tracef("incomings: %d, %d, outgoings: %d, size: %d", _incomings, _incomings2, _outgoings, size());
    }
}       
}