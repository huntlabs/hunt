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

module hunt.concurrency.LinkedBlockingQueue;

import hunt.concurrency.atomic.AtomicHelper;
import hunt.concurrency.Helpers;
import hunt.concurrency.BlockingQueue;

import hunt.collection.AbstractQueue;
import hunt.collection.Collection;
import hunt.collection.Iterator;
import hunt.util.DateTime;
import hunt.Exceptions;
import hunt.Functions;
import hunt.Object;

// import core.atomic;
import core.sync.mutex;
import core.sync.condition;
import core.time;

import hunt.logging.ConsoleLogger;

/**
 * An optionally-bounded {@linkplain BlockingQueue blocking queue} based on
 * linked nodes.
 * This queue orders elements FIFO (first-in-first-out).
 * The <em>head</em> of the queue is that element that has been on the
 * queue the longest time.
 * The <em>tail</em> of the queue is that element that has been on the
 * queue the shortest time. New elements
 * are inserted at the tail of the queue, and the queue retrieval
 * operations obtain elements at the head of the queue.
 * Linked queues typically have higher throughput than array-based queues but
 * less predictable performance in most concurrent applications.
 *
 * <p>The optional capacity bound constructor argument serves as a
 * way to prevent excessive queue expansion. The capacity, if unspecified,
 * is equal to {@link Integer#MAX_VALUE}.  Linked nodes are
 * dynamically created upon each insertion unless this would bring the
 * queue above capacity.
 *
 * <p>This class and its iterator implement all of the <em>optional</em>
 * methods of the {@link Collection} and {@link Iterator} interfaces.
 *
 * <p>This class is a member of the
 * <a href="{@docRoot}/java.base/java/util/package-summary.html#CollectionsFramework">
 * Java Collections Framework</a>.
 *
 * @since 1.5
 * @author Doug Lea
 * @param (E) the type of elements held in this queue
 */
class LinkedBlockingQueue(E) : AbstractQueue!(E), BlockingQueue!(E) {

    /*
     * A variant of the "two lock queue" algorithm.  The putLock gates
     * entry to put (and offer), and has an associated condition for
     * waiting puts.  Similarly for the takeLock.  The "count" field
     * that they both rely on is maintained as an atomic to avoid
     * needing to get both locks in most cases. Also, to minimize need
     * for puts to get takeLock and vice-versa, cascading notifies are
     * used. When a put notices that it has enabled at least one take,
     * it signals taker. That taker in turn signals others if more
     * items have been entered since the signal. And symmetrically for
     * takes signalling puts. Operations such as remove(Object) and
     * iterators acquire both locks.
     *
     * Visibility between writers and readers is provided as follows:
     *
     * Whenever an element is enqueued, the putLock is acquired and
     * count updated.  A subsequent reader guarantees visibility to the
     * enqueued Node by either acquiring the putLock (via fullyLock)
     * or by acquiring the takeLock, and then reading n = atomicLoad(count);
     * this gives visibility to the first n items.
     *
     * To implement weakly consistent iterators, it appears we need to
     * keep all Nodes GC-reachable from a predecessor dequeued Node.
     * That would cause two problems:
     * - allow a rogue Iterator to cause unbounded memory retention
     * - cause cross-generational linking of old Nodes to new Nodes if
     *   a Node was tenured while live, which generational GCs have a
     *   hard time dealing with, causing repeated major collections.
     * However, only non-deleted Nodes need to be reachable from
     * dequeued Nodes, and reachability does not necessarily have to
     * be of the kind understood by the GC.  We use the trick of
     * linking a Node that has just been dequeued to itself.  Such a
     * self-link implicitly means to advance to head.next.
     */

    /**
     * Linked list node class.
     */
    static class Node(E) {
        E item;

        /**
         * One of:
         * - the real successor Node
         * - this Node, meaning the successor is head.next
         * - null, meaning there is no successor (this is the last node)
         */
        Node!(E) next;

        this(E x) { item = x; }
    }

    /** The capacity bound, or int.max if none */
    private int capacity;

    /** Current number of elements */
    private shared(int) count;

    /**
     * Head of linked list.
     * Invariant: head.item is null
     */
    private Node!(E) head;

    /**
     * Tail of linked list.
     * Invariant: last.next is null
     */
    private Node!(E) last;

    /** Lock held by take, poll, etc */
    private Mutex takeLock;

    /** Wait queue for waiting takes */
    private Condition notEmpty;

    /** Lock held by put, offer, etc */
    private Mutex putLock;

    /** Wait queue for waiting puts */
    private Condition notFull;

    private void initilize() {
        takeLock = new Mutex();
        putLock = new Mutex();
        notEmpty = new Condition(takeLock);
        notFull = new Condition(putLock);
    }

    /**
     * Signals a waiting take. Called only from put/offer (which do not
     * otherwise ordinarily lock takeLock.)
     */
    private void signalNotEmpty() {
        Mutex takeLock = this.takeLock;
        takeLock.lock();
        // scope(exit) takeLock.unlock();
        try {
            notEmpty.notify();
        } finally {
            takeLock.unlock();
        }
    }

    /**
     * Signals a waiting put. Called only from take/poll.
     */
    private void signalNotFull() {
        Mutex putLock = this.putLock;
        putLock.lock();
        try {
            notFull.notify();
        } finally {
            putLock.unlock();
        }
    }

    /**
     * Links node at end of queue.
     *
     * @param node the node
     */
    private void enqueue(Node!(E) node) {
        // assert putLock.isHeldByCurrentThread();
        // assert last.next is null;
        last = last.next = node;
    }

    /**
     * Removes a node from head of queue.
     *
     * @return the node
     */
    private E dequeue() {
        // assert takeLock.isHeldByCurrentThread();
        // assert head.item is null;
        Node!(E) h = head;
        Node!(E) first = h.next;
        h.next = h; // help GC
        head = first;
        E x = first.item;
        first.item = E.init;
        return x;
    }

    /**
     * Locks to prevent both puts and takes.
     */
    void fullyLock() {
        putLock.lock();
        takeLock.lock();
    }

    /**
     * Unlocks to allow both puts and takes.
     */
    void fullyUnlock() {
        takeLock.unlock();
        putLock.unlock();
    }

    /**
     * Creates a {@code LinkedBlockingQueue} with a capacity of
     * {@link Integer#MAX_VALUE}.
     */
    this() {
        this(int.max);
    }

    /**
     * Creates a {@code LinkedBlockingQueue} with the given (fixed) capacity.
     *
     * @param capacity the capacity of this queue
     * @throws IllegalArgumentException if {@code capacity} is not greater
     *         than zero
     */
    this(int capacity) {
        if (capacity <= 0) throw new IllegalArgumentException();
        this.capacity = capacity;
        last = head = new Node!(E)(E.init);
        initilize();
    }

    /**
     * Creates a {@code LinkedBlockingQueue} with a capacity of
     * {@link Integer#MAX_VALUE}, initially containing the elements of the
     * given collection,
     * added in traversal order of the collection's iterator.
     *
     * @param c the collection of elements to initially contain
     * @throws NullPointerException if the specified collection or any
     *         of its elements are null
     */
    this(Collection!(E) c) {
        this(int.max);
        Mutex putLock = this.putLock;
        putLock.lock(); // Never contended, but necessary for visibility
        try {
            int n = 0;
            foreach (E e ; c) {
                static if(is(E == class) || is(E == string)) {
                    if (e is null) throw new NullPointerException();
                }
                if (n == capacity)
                    throw new IllegalStateException("Queue full");
                enqueue(new Node!(E)(e));
                ++n;
            }
            count = n;
        } finally {
            putLock.unlock();
        }
    }

    // this doc comment is overridden to remove the reference to collections
    // greater in size than int.max
    /**
     * Returns the number of elements in this queue.
     *
     * @return the number of elements in this queue
     */
    override int size() {
        return count;
    }

    // this doc comment is a modified copy of the inherited doc comment,
    // without the reference to unlimited queues.
    /**
     * Returns the number of additional elements that this queue can ideally
     * (in the absence of memory or resource constraints) accept without
     * blocking. This is always equal to the initial capacity of this queue
     * less the current {@code size} of this queue.
     *
     * <p>Note that you <em>cannot</em> always tell if an attempt to insert
     * an element will succeed by inspecting {@code remainingCapacity}
     * because it may be the case that another thread is about to
     * insert or remove an element.
     */
    int remainingCapacity() {
        return capacity - count;
    }

    override bool add(E e) {
        return super.add(e);
    }

    /**
     * Inserts the specified element at the tail of this queue, waiting if
     * necessary for space to become available.
     *
     * @throws InterruptedException {@inheritDoc}
     * @throws NullPointerException {@inheritDoc}
     */
    void put(E e) {
        static if(is(E == class) || is(E == string)) {
            if (e is null) throw new NullPointerException();
        }
        int c;
        Node!(E) node = new Node!(E)(e);
        Mutex putLock = this.putLock;
        putLock.lock();
        try {
            /*
             * Note that count is used in wait guard even though it is
             * not protected by lock. This works because count can
             * only decrease at this point (all other puts are shut
             * out by lock), and we (or some other waiting put) are
             * signalled if it ever changes from capacity. Similarly
             * for all other uses of count in other wait guards.
             */
            while (count == capacity) {
                notFull.wait();
            }
            enqueue(node);
            c = AtomicHelper.getAndIncrement(count);
            if (c + 1 < capacity)
                notFull.notify();
        } finally {
            putLock.unlock();
        }
        if (c == 0)
            signalNotEmpty();
    }

    /**
     * Inserts the specified element at the tail of this queue, waiting if
     * necessary up to the specified wait time for space to become available.
     *
     * @return {@code true} if successful, or {@code false} if
     *         the specified waiting time elapses before space is available
     * @throws InterruptedException {@inheritDoc}
     * @throws NullPointerException {@inheritDoc}
     */
    bool offer(E e, Duration timeout) {
        static if(is(E == class) || is(E == string)) {
            if (e is null) throw new NullPointerException();
        }

        int c;
        Mutex putLock = this.putLock;
        putLock.lock();
        try {
            while (count == capacity) {
                // if (nanos <= 0L)
                //     return false;
                // nanos = notFull.wait(nanos);
                if(!notFull.wait(timeout)) return false;
            }
            enqueue(new Node!(E)(e));
            c = AtomicHelper.getAndIncrement(count);
            if (c + 1 < capacity)
                notFull.notify();
        } finally {
            putLock.unlock();
        }
        if (c == 0)
            signalNotEmpty();
        return true;
    }

    /**
     * Inserts the specified element at the tail of this queue if it is
     * possible to do so immediately without exceeding the queue's capacity,
     * returning {@code true} upon success and {@code false} if this queue
     * is full.
     * When using a capacity-restricted queue, this method is generally
     * preferable to method {@link BlockingQueue#add add}, which can fail to
     * insert an element only by throwing an exception.
     *
     * @throws NullPointerException if the specified element is null
     */
    bool offer(E e) {
        static if(is(E == class) || is(E == string)) {
            if (e is null) throw new NullPointerException();
        }
        // int count = this.count;
        if (count  == capacity)
            return false;
        int c;
        Node!(E) node = new Node!(E)(e);
        Mutex putLock = this.putLock;
        putLock.lock();
        try {
            if (count == capacity)
                return false;
            enqueue(node);
            c = AtomicHelper.getAndIncrement(count);
            if (c + 1 < capacity)
                notFull.notify();
        } finally {
            putLock.unlock();
        }
        
        if (c == 0)
            signalNotEmpty();
        return true;
    }

    E take() {
        E x;
        int c;
        Mutex takeLock = this.takeLock;
        takeLock.lock();
        try {
            while (count == 0) {
                notEmpty.wait();
            }
            x = dequeue();
            c = AtomicHelper.getAndDecrement(count);
            if (c > 1)
                notEmpty.notify();
        } finally {
            takeLock.unlock();
        }
        if (c == capacity)
            signalNotFull();
        return x;
    }

    E poll(Duration timeout) {
        E x;
        int c;
        // int count = this.count;
        Mutex takeLock = this.takeLock;
        takeLock.lock();
        try {
            while (count == 0) {
                if(!notFull.wait(timeout)) return E.init;
            }
            x = dequeue();
            c = AtomicHelper.getAndDecrement(count);
            if (c > 1)
                notEmpty.notify();
        } finally {
            takeLock.unlock();
        }
        if (c == capacity)
            signalNotFull();
        return x;
    }

    E poll() {
        // int count = this.count;
        if (count == 0)
            throw new NoSuchElementException();

        E x;
        int c;
        Mutex takeLock = this.takeLock;
        takeLock.lock();
        try {
            if (count == 0)
                return E.init;
            x = dequeue();
            c = AtomicHelper.getAndDecrement(count);
            if (c > 1)
                notEmpty.notify();
        } finally {
            takeLock.unlock();
        }
        if (c == capacity)
            signalNotFull();
        return x;
    }

    E peek() {
        // if (atomicLoad(count) == 0)
        //     return E.init;
        
        if (count == 0)
            throw new NoSuchElementException();

        Mutex takeLock = this.takeLock;
        takeLock.lock();
        try {
            return (count > 0) ? head.next.item : E.init;
        } finally {
            takeLock.unlock();
        }
    }

    /**
     * Unlinks interior Node p with predecessor pred.
     */
    private void unlink(Node!(E) p, Node!(E) pred) {
        // assert putLock.isHeldByCurrentThread();
        // assert takeLock.isHeldByCurrentThread();
        // p.next is not changed, to allow iterators that are
        // traversing p to maintain their weak-consistency guarantee.
        p.item = E.init;
        pred.next = p.next;
        if (last == p)
            last = pred;
        if (AtomicHelper.getAndDecrement(count) == capacity)
            notFull.notify();
    }

    /**
     * Removes a single instance of the specified element from this queue,
     * if it is present.  More formally, removes an element {@code e} such
     * that {@code o.equals(e)}, if this queue contains one or more such
     * elements.
     * Returns {@code true} if this queue contained the specified element
     * (or equivalently, if this queue changed as a result of the call).
     *
     * @param o element to be removed from this queue, if present
     * @return {@code true} if this queue changed as a result of the call
     */
    override bool remove(E o) {
        static if(is(E == class) || is(E == string)) {
            if (o is null) return false;
        }

        fullyLock();
        try {
            for (Node!(E) pred = head, p = pred.next;
                 p !is null;
                 pred = p, p = p.next) {
                if (o == p.item) {
                    unlink(p, pred);
                    return true;
                }
            }
            return false;
        } finally {
            fullyUnlock();
        }
    }

    /**
     * Returns {@code true} if this queue contains the specified element.
     * More formally, returns {@code true} if and only if this queue contains
     * at least one element {@code e} such that {@code o.equals(e)}.
     *
     * @param o object to be checked for containment in this queue
     * @return {@code true} if this queue contains the specified element
     */
    override bool contains(E o) {
        static if(is(E == class) || is(E == string)) {
            if (o is null) return false;
        }
        fullyLock();
        try {
            for (Node!(E) p = head.next; p !is null; p = p.next)
                if (o == p.item)
                    return true;
            return false;
        } finally {
            fullyUnlock();
        }
    }

    /**
     * Returns an array containing all of the elements in this queue, in
     * proper sequence.
     *
     * <p>The returned array will be "safe" in that no references to it are
     * maintained by this queue.  (In other words, this method must allocate
     * a new array).  The caller is thus free to modify the returned array.
     *
     * <p>This method acts as bridge between array-based and collection-based
     * APIs.
     *
     * @return an array containing all of the elements in this queue
     */
    override E[] toArray() {
        fullyLock();
        try {
            int size = count;
            E[] a = new E[size];
            int k = 0;
            for (Node!(E) p = head.next; p !is null; p = p.next)
                a[k++] = p.item;
            return a;
        } finally {
            fullyUnlock();
        }
    }

    /**
     * Returns an array containing all of the elements in this queue, in
     * proper sequence; the runtime type of the returned array is that of
     * the specified array.  If the queue fits in the specified array, it
     * is returned therein.  Otherwise, a new array is allocated with the
     * runtime type of the specified array and the size of this queue.
     *
     * <p>If this queue fits in the specified array with room to spare
     * (i.e., the array has more elements than this queue), the element in
     * the array immediately following the end of the queue is set to
     * {@code null}.
     *
     * <p>Like the {@link #toArray()} method, this method acts as bridge between
     * array-based and collection-based APIs.  Further, this method allows
     * precise control over the runtime type of the output array, and may,
     * under certain circumstances, be used to save allocation costs.
     *
     * <p>Suppose {@code x} is a queue known to contain only strings.
     * The following code can be used to dump the queue into a newly
     * allocated array of {@code string}:
     *
     * <pre> {@code string[] y = x.toArray(new string[0]);}</pre>
     *
     * Note that {@code toArray(new Object[0])} is identical in function to
     * {@code toArray()}.
     *
     * @param a the array into which the elements of the queue are to
     *          be stored, if it is big enough; otherwise, a new array of the
     *          same runtime type is allocated for this purpose
     * @return an array containing all of the elements in this queue
     * @throws ArrayStoreException if the runtime type of the specified array
     *         is not a supertype of the runtime type of every element in
     *         this queue
     * @throws NullPointerException if the specified array is null
     */

    // !(T) T[] toArray(T[] a) {
    //     fullyLock();
    //     try {
    //         int size = atomicLoad(count);
    //         if (a.length < size)
    //             a = (T[])java.lang.reflect.Array.newInstance
    //                 (a.getClass().getComponentType(), size);

    //         int k = 0;
    //         for (Node!(E) p = head.next; p !is null; p = p.next)
    //             a[k++] = (T)p.item;
    //         if (a.length > k)
    //             a[k] = null;
    //         return a;
    //     } finally {
    //         fullyUnlock();
    //     }
    // }

    override string toString() {
        return Helpers.collectionToString(this);
    }

    /**
     * Atomically removes all of the elements from this queue.
     * The queue will be empty after this call returns.
     */
    override void clear() {
        fullyLock();
        try {
            for (Node!(E) p, h = head; (p = h.next) !is null; h = p) {
                h.next = h;
                p.item = E.init;
            }
            head = last;
            // assert head.item is null && head.next is null;
            int c = count;
            AtomicHelper.store(count, 0);
            if (c == capacity)
                notFull.notify();
        } finally {
            fullyUnlock();
        }
    }

    /**
     * @throws UnsupportedOperationException {@inheritDoc}
     * @throws ClassCastException            {@inheritDoc}
     * @throws NullPointerException          {@inheritDoc}
     * @throws IllegalArgumentException      {@inheritDoc}
     */
    int drainTo(Collection!(E) c) {
        return drainTo(c, int.max);
    }

    /**
     * @throws UnsupportedOperationException {@inheritDoc}
     * @throws ClassCastException            {@inheritDoc}
     * @throws NullPointerException          {@inheritDoc}
     * @throws IllegalArgumentException      {@inheritDoc}
     */
    int drainTo(Collection!(E) c, int maxElements) {
        // Objects.requireNonNull(c);
        if (c == this)
            throw new IllegalArgumentException();
        if (maxElements <= 0)
            return 0;
        bool canSignalNotFull = false;
        Mutex takeLock = this.takeLock;
        takeLock.lock();
        try {
            import std.algorithm : min;
            int n = min(maxElements, count);
            // count.get provides visibility to first n Nodes
            Node!(E) h = head;
            int i = 0;
            try {
                while (i < n) {
                    Node!(E) p = h.next;
                    c.add(p.item);
                    p.item = E.init;
                    h.next = h;
                    h = p;
                    ++i;
                }
                return n;
            } finally {
                // Restore invariants even if c.add() threw
                if (i > 0) {
                    // assert h.item is null;
                    head = h;
                    int ct = AtomicHelper.getAndAdd(count, i);
                    canSignalNotFull = ((ct - i) == capacity);
                }
            }
        } finally {
            takeLock.unlock();
            if (canSignalNotFull)
                signalNotFull();
        }
    }

    /**
     * Used for any element traversal that is not entirely under lock.
     * Such traversals must handle both:
     * - dequeued nodes (p.next == p)
     * - (possibly multiple) interior removed nodes (p.item is null)
     */
    Node!(E) succ(Node!(E) p) {
        if (p == (p = p.next))
            p = head.next;
        return p;
    }

    override int opApply(scope int delegate(ref E) dg) {
        if(dg is null)
            throw new NullPointerException();

        return forEachFrom(dg, null);
    }

    /**
     * Runs action on each element found during a traversal starting at p.
     * If p is null, traversal starts at head.
     */
    private int forEachFrom(scope int delegate(ref E) action, Node!(E) p) {
        // Extract batches of elements while holding the lock; then
        // run the action on the elements while not
        const int batchSize = 64;       // max number of elements per batch
        E[] es = null;             // container for batch of elements
        int n, len = 0;
        int result = 0;
        do {
            fullyLock();
            try {
                if (es is null) {
                    if (p is null) p = head.next;
                    for (Node!(E) q = p; q !is null; q = succ(q))
                        static if(is(E == class) || is(E == string)) {
                            if (q.item !is null && ++len == batchSize)
                                break;
                        } else {
                            if (++len == batchSize)
                                break;
                        }
                    es = new E[len];
                }
                for (n = 0; p !is null && n < len; p = succ(p)) {
                    es[n] = p.item;
                    static if(is(E == class) || is(E == string)) {
                        if (es[n] !is null)
                            n++;
                    } else {
                        n++;
                    }
                }
            } finally {
                fullyUnlock();
            }

            for (int i = 0; i < n; i++) {
                E e = es[i];
                result = action(e);
                if(result != 0) return result;
            }
        } while (n > 0 && p !is null);

        return result;
    }

    /**
     * @throws NullPointerException {@inheritDoc}
     */
    override bool removeIf(Predicate!(E) filter) {
        // Objects.requireNonNull(filter);
        return bulkRemove(filter);
    }

    /**
     * @throws NullPointerException {@inheritDoc}
     */
    override bool removeAll(Collection!E c) {
        // Objects.requireNonNull(c);
        return bulkRemove(e => c.contains(e));
    }

    /**
     * @throws NullPointerException {@inheritDoc}
     */
    override bool retainAll(Collection!E c) {
        // Objects.requireNonNull(c);
        return bulkRemove(e => !c.contains(e));
    }

    /**
     * Returns the predecessor of live node p, given a node that was
     * once a live ancestor of p (or head); allows unlinking of p.
     */
    Node!(E) findPred(Node!(E) p, Node!(E) ancestor) {
        // assert p.item !is null;
        static if(is(E == class) || is(E == string)) {
            if (ancestor.item is null)
                ancestor = head;
        }
        // Fails with NPE if precondition not satisfied
        for (Node!(E) q; (q = ancestor.next) != p; )
            ancestor = q;
        return ancestor;
    }

    /** Implementation of bulk remove methods. */

    private bool bulkRemove(Predicate!(E) filter) {
        bool removed = false;
        Node!(E) p = null, ancestor = head;
        Node!(E)[] nodes = null;
        int n, len = 0;
        do {
            // 1. Extract batch of up to 64 elements while holding the lock.
            fullyLock();
            try {
                if (nodes is null) {  // first batch; initialize
                    p = head.next;
                    for (Node!(E) q = p; q !is null; q = succ(q)) {
                        static if(is(E == class) || is(E == string)) {
                            if (q.item !is null && ++len == 64)
                                break;
                        } else {
                            if (++len == 64)
                                break;
                        }
                    }
                    nodes = new Node!(E)[len];
                }
                for (n = 0; p !is null && n < len; p = succ(p))
                    nodes[n++] = p;
            } finally {
                fullyUnlock();
            }

            // 2. Run the filter on the elements while lock is free.
            long deathRow = 0L;       // "bitset" of size 64
            for (int i = 0; i < n; i++) {
                E e = nodes[i].item;
                static if(is(E == class) || is(E == string)) {
                    if (e !is null && filter(e)) deathRow |= 1L << i;
                } else {
                    if (filter(e)) deathRow |= 1L << i;
                }
            }

            // 3. Remove any filtered elements while holding the lock.
            if (deathRow != 0) {
                fullyLock();
                try {
                    for (int i = 0; i < n; i++) {
                        Node!(E) q;
                        static if(is(E == class) || is(E == string)) {
                            if ((deathRow & (1L << i)) != 0L
                                && (q = nodes[i]).item !is null) {
                                ancestor = findPred(q, ancestor);
                                unlink(q, ancestor);
                                removed = true;
                            }
                        } else {
                            if ((deathRow & (1L << i)) != 0L) {
                                q = nodes[i];
                                ancestor = findPred(q, ancestor);
                                unlink(q, ancestor);
                                removed = true;
                            }
                        }
                        nodes[i] = null; // help GC
                    }
                } finally {
                    fullyUnlock();
                }
            }
        } while (n > 0 && p !is null);
        return removed;
    }

    override bool opEquals(IObject o) {
        return opEquals(cast(Object) o);
    }
    
    override bool opEquals(Object o) {
        return super.opEquals(o);
    }

    override size_t toHash() @trusted nothrow {
        return super.toHash();
    }

}
