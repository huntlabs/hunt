module hunt.collection.AbstractDeque;

import hunt.collection.AbstractCollection;
import hunt.collection.AbstractQueue;
import hunt.collection.Collection;
import hunt.collection.Deque;
import hunt.collection.Queue;
import hunt.Exceptions;
import hunt.Object;

import core.time;


/**
*/
abstract class AbstractDeque(E) : AbstractQueue!(E), Deque!(E) {


    /**
     * {@inheritDoc}
     */
    override
    void addFirst(E e) {
        if (!offerFirst(e)) {
            throw new IllegalStateException("Deque full");
        }
    }

    /**
     * {@inheritDoc}
     */
    override
    void addLast(E e) {
        if (!offerLast(e)) {
            throw new IllegalStateException("Deque full");
        }
    }

    /**
     * {@inheritDoc}
     */
    override
    bool add(E e) {
        addLast(e);
        return true;
    }

    /**
     * {@inheritDoc}
     */
    override
    bool offer(E e) {
        return offerLast(e);
    }

    /**
     * Links the provided element as the last in the queue, waiting until there
     * is space to do so if the queue is full.
     *
     * <p>This method is equivalent to {@link #putLast(Object)}.
     *
     * @param e element to link
     *
     * @throws NullPointerException if e is null
     * @throws InterruptedException if the thread is interrupted whilst waiting
     *         for space
     */
    void put(E e){
        putLast(e);
    }

    /**
     * Links the provided element as the last in the queue, waiting up to the
     * specified time to do so if the queue is full.
     * <p>
     * This method is equivalent to {@link #offerLast(Object, long, TimeUnit)}
     *
     * @param e         element to link
     * @param timeout   length of time to wait
     * @param unit      units that timeout is expressed in
     *
     * @return {@code true} if successful, otherwise {@code false}
     *
     * @throws NullPointerException if e is null
     * @throws InterruptedException if the thread is interrupted whilst waiting
     *         for space
     */
    bool offer(E e, Duration timeout) {
        return offerLast(e, timeout);
    }

    /**
     * Retrieves and removes the head of the queue represented by this deque.
     * This method differs from {@link #poll poll} only in that it throws an
     * exception if this deque is empty.
     *
     * <p>This method is equivalent to {@link #removeFirst() removeFirst}.
     *
     * @return the head of the queue represented by this deque
     * @throws NoSuchElementException if this deque is empty
     */
    override
    E remove() {
        return removeFirst();
    }

    /**
     * {@inheritDoc}
     */
    override
    E removeFirst() {
        E x = pollFirst();
        if (x is null) {
            throw new NoSuchElementException();
        }
        return x;
    }

    /**
     * {@inheritDoc}
     */
    override
    E removeLast() {
        E x = pollLast();
        if (x is null) {
            throw new NoSuchElementException();
        }
        return x;
    }

    /**
     * Removes the first occurrence of the specified element from this deque.
     * If the deque does not contain the element, it is unchanged.
     * More formally, removes the first element {@code e} such that
     * {@code o == e} (if such an element exists).
     * Returns {@code true} if this deque contained the specified element
     * (or equivalently, if this deque changed as a result of the call).
     *
     * <p>This method is equivalent to
     * {@link #removeFirstOccurrence(Object) removeFirstOccurrence}.
     *
     * @param o element to be removed from this deque, if present
     * @return {@code true} if this deque changed as a result of the call
     */
    override
    bool remove(E o) {
        return removeFirstOccurrence(o);
    }

    override
    E poll() {
        return pollFirst();
    }

    /**
     * Unlinks the first element in the queue, waiting until there is an element
     * to unlink if the queue is empty.
     *
     * <p>This method is equivalent to {@link #takeFirst()}.
     *
     * @return the unlinked element
     * @throws InterruptedException if the current thread is interrupted
     */
    E take() {
        return takeFirst();
    }

    /**
     * Unlinks the first element in the queue, waiting up to the specified time
     * to do so if the queue is empty.
     *
     * <p>This method is equivalent to {@link #pollFirst(long, TimeUnit)}.
     *
     * @param timeout   length of time to wait
     * @param unit      units that timeout is expressed in
     *
     * @return the unlinked element
     * @throws InterruptedException if the current thread is interrupted
     */
    E poll(Duration timeout) {
        return pollFirst(timeout);
    }

    /**
     * Retrieves, but does not remove, the head of the queue represented by
     * this deque.  This method differs from {@link #peek peek} only in that
     * itempty.
     *
     * <p>This method is equivalent to {@link #getFirst() getFirst}.
     *
     * @return the head of the queue represented by this deque
     * @throws NoSuchElementException if this deque is empty
     */
    override
    E element() {
        return getFirst();
    }

    override
    E peek() {
        return peekFirst();
    }


    override bool contains(E o) {
        throw new NotSupportedException();
    }

    // Stack methods

    /**
     * {@inheritDoc}
     */
    override
    void push(E e) {
        addFirst(e);
    }

    /**
     * {@inheritDoc}
     */
    override
    E pop() {
        return removeFirst();
    }


    bool offerFirst(E e) {
        throw new NotSupportedException();
    }

    bool offerLast(E e) {
        throw new NotSupportedException();
    }
    
    bool offerLast(E e, Duration timeout) {
        throw new NotSupportedException();
    }

    E pollFirst() {
        throw new NotSupportedException();
    }

    E pollFirst(Duration timeout) {
        throw new NotSupportedException();
    }

    E pollLast() {
        throw new NotSupportedException();
    }
    
    E getFirst() {
        throw new NotSupportedException();
    }

    E takeFirst() {
        throw new NotSupportedException();
    }

    E getLast() {
        throw new NotSupportedException();
    }

    E peekFirst() {
        throw new NotSupportedException();
    }

    void putLast(E e) {
        throw new NotSupportedException();
    }

    E peekLast() {
        throw new NotSupportedException();
    }

    bool removeFirstOccurrence(E o) {
        throw new NotSupportedException();
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

    override string toString() {
        return super.toString();
    }
}
