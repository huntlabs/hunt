module hunt.container.LinkedList;

import hunt.container.AbstractList;
import hunt.container.AbstractSequentialList;
import hunt.container.Collection;
import hunt.container.Deque;
import hunt.container.List;

import hunt.util.exception;

import std.conv;
import std.container;
import std.range;



/**
 * Doubly-linked list implementation of the {@code List} and {@code Deque}
 * interfaces.  Implements all optional list operations, and permits all
 * elements (including {@code null}).
 *
 * <p>All of the operations perform as could be expected for a doubly-linked
 * list.  Operations that index into the list will traverse the list from
 * the beginning or the end, whichever is closer to the specified index.
 *
 * <p><strong>Note that this implementation is not synchronized.</strong>
 * If multiple threads access a linked list concurrently, and at least
 * one of the threads modifies the list structurally, it <i>must</i> be
 * synchronized externally.  (A structural modification is any operation
 * that adds or deletes one or more elements; merely setting the value of
 * an element is not a structural modification.)  This is typically
 * accomplished by synchronizing on some object that naturally
 * encapsulates the list.
 *
 * If no such object exists, the list should be "wrapped" using the
 * {@link Collections#synchronizedList Collections.synchronizedList}
 * method.  This is best done at creation time, to prevent accidental
 * unsynchronized access to the list:<pre>
 *   List list = Collections.synchronizedList(new LinkedList(...));</pre>
 *
 * <p>The iterators returned by this class's {@code iterator} and
 * {@code listIterator} methods are <i>fail-fast</i>: if the list is
 * structurally modified at any time after the iterator is created, in
 * any way except through the Iterator's own {@code remove} or
 * {@code add} methods, the iterator will throw a {@link
 * ConcurrentModificationException}.  Thus, in the face of concurrent
 * modification, the iterator fails quickly and cleanly, rather than
 * risking arbitrary, non-deterministic behavior at an undetermined
 * time in the future.
 *
 * <p>Note that the fail-fast behavior of an iterator cannot be guaranteed
 * as it is, generally speaking, impossible to make any hard guarantees in the
 * presence of unsynchronized concurrent modification.  Fail-fast iterators
 * throw {@code ConcurrentModificationException} on a best-effort basis.
 * Therefore, it would be wrong to write a program that depended on this
 * exception for its correctness:   <i>the fail-fast behavior of iterators
 * should be used only to detect bugs.</i>
 *
 * <p>This class is a member of the
 * <a href="{@docRoot}/../technotes/guides/collections/index.html">
 * Java Collections Framework</a>.
 *
 * @author  Josh Bloch
 * @see     List
 * @see     ArrayList
 * @since 1.2
 * @param !E the type of elements held in this collection
 */

class LinkedList(E) : AbstractSequentialList!E,  Deque!E //, Cloneable
{
    DList!E _dlist;
    int _size = 0;

    /**
     * Constructs an empty list.
     */
    this() {
    }

//     /**
//      * Constructs a list containing the elements of the specified
//      * collection, in the order they are returned by the collection's
//      * iterator.
//      *
//      * @param  c the collection whose elements are to be placed into this list
//      * @throws NullPointerException if the specified collection is null
//      */
//     this(Collection!E c) {
//         this();
//         addAll(c);
//     }

    /**
     * Links e as first element.
     */
    private void linkFirst(E e) {
        _dlist.insertFront(e);
        _size++;
        modCount++;
    }

    /**
     * Links e as last element.
     */
    void linkLast(E e) {
        _dlist.insertBack(e);
        _size++;
        modCount++;
    }

    /**
     * Inserts element e before non-null Node succ.
     */
    // void linkBefore(E e, Node!E succ) {
    //     // assert succ !is null;
    //     final Node!E pred = succ.prev;
    //     final Node!E newNode = new Node<>(pred, e, succ);
    //     succ.prev = newNode;
    //     if (pred is null)
    //         first = newNode;
    //     else
    //         pred.next = newNode;
    //     _size++;
    //     modCount++;
    // }

    /**
     * Unlinks non-null first node f.
     */
    private E unlinkFirst() {
        E element = _dlist.front;
        _dlist.removeFront();
        _size--;
        modCount++;
        return element;
    }

    /**
     * Unlinks non-null last node l.
     */
    private E unlinkLast() {
        E element = _dlist.back;
        _dlist.removeBack;
        _size--;
        modCount++;
        return element;
    }


    /**
     * Returns the first element in this list.
     *
     * @return the first element in this list
     * @throws NoSuchElementException if this list is empty
     */
    E getFirst() {
        return _dlist.front;
    }

    /**
     * Returns the last element in this list.
     *
     * @return the last element in this list
     * @throws NoSuchElementException if this list is empty
     */
    E getLast() {
        return _dlist.back;
    }

    /**
     * Removes and returns the first element from this list.
     *
     * @return the first element from this list
     * @throws NoSuchElementException if this list is empty
     */
    E removeFirst() {
        if(_size<=0)  return E.init;
        return unlinkFirst();
    }

    /**
     * Removes and returns the last element from this list.
     *
     * @return the last element from this list
     * @throws NoSuchElementException if this list is empty
     */
    E removeLast() {
        if(_size<=0) return E.init;
        return unlinkLast();
    }

    /**
     * Inserts the specified element at the beginning of this list.
     *
     * @param e the element to add
     */
    void addFirst(E e) {
        linkFirst(e);
    }

    /**
     * Appends the specified element to the end of this list.
     *
     * <p>This method is equivalent to {@link #add}.
     *
     * @param e the element to add
     */
    void addLast(E e) {
        linkLast(e);
    }

    /**
     * Returns {@code true} if this list contains the specified element.
     * More formally, returns {@code true} if and only if this list contains
     * at least one element {@code e} such that
     * <tt>(o==null&nbsp;?&nbsp;e==null&nbsp;:&nbsp;o.equals(e))</tt>.
     *
     * @param o element whose presence in this list is to be tested
     * @return {@code true} if this list contains the specified element
     */
    override bool contains(E o) {
        return indexOf(o) != -1;
    }

    /**
     * Returns the number of elements in this list.
     *
     * @return the number of elements in this list
     */
    override int size() {
        return _size;
    }

    /**
     * Appends the specified element to the end of this list.
     *
     * <p>This method is equivalent to {@link #addLast}.
     *
     * @param e element to be appended to this list
     * @return {@code true} (as specified by {@link Collection#add})
     */
    override bool add(E e) {
        linkLast(e);
        return true;
    }

    /**
     * Removes the first occurrence of the specified element from this list,
     * if it is present.  If this list does not contain the element, it is
     * unchanged.  More formally, removes the element with the lowest index
     * {@code i} such that
     * <tt>(o==null&nbsp;?&nbsp;get(i)==null&nbsp;:&nbsp;o.equals(get(i)))</tt>
     * (if such an element exists).  Returns {@code true} if this list
     * contained the specified element (or equivalently, if this list
     * changed as a result of the call).
     *
     * @param o element to be removed from this list, if present
     * @return {@code true} if this list contained the specified element
     */
    override bool remove(E o) {
        // auto range = _dlist[];
        // for ( ; !range.empty; range.popFront())
        // {
        //     if (range.front == o)
        //     {
        //         list.stableLinearRemove(take(range, 1));
        //         return true;
        //     }
        // }

        _size--;
        modCount++;
        // list.stableLinearRemove(take(range, 1));
        return _dlist.linearRemoveElement(o);
        // return true;
    }

    /**
     * Appends all of the elements in the specified collection to the end of
     * this list, in the order that they are returned by the specified
     * collection's iterator.  The behavior of this operation is undefined if
     * the specified collection is modified while the operation is in
     * progress.  (Note that this will occur if the specified collection is
     * this list, and it's nonempty.)
     *
     * @param c collection containing elements to be added to this list
     * @return {@code true} if this list changed as a result of the call
     * @throws NullPointerException if the specified collection is null
     */
    override bool addAll(Collection!E c) {

        bool modified = c.size() > 0;
        foreach (E e ; c) {
            linkLast(e);
        }
        return modified;

        // return addAll(_size, c);
    }

//     /**
//      * Inserts all of the elements in the specified collection into this
//      * list, starting at the specified position.  Shifts the element
//      * currently at that position (if any) and any subsequent elements to
//      * the right (increases their indices).  The new elements will appear
//      * in the list in the order that they are returned by the
//      * specified collection's iterator.
//      *
//      * @param index index at which to insert the first element
//      *              from the specified collection
//      * @param c collection containing elements to be added to this list
//      * @return {@code true} if this list changed as a result of the call
//      * @throws IndexOutOfBoundsException {@inheritDoc}
//      * @throws NullPointerException if the specified collection is null
//      */

bool addAll(int index, Collection!E c) {
    throw new NotImplementedException();
}
//     bool addAll(int index, Collection<? extends E> c) {
//         checkPositionIndex(index);

//         Object[] a = c.toArray();
//         int numNew = a.length;
//         if (numNew == 0)
//             return false;

//         Node!E pred, succ;
//         if (index == _size) {
//             succ = null;
//             pred = last;
//         } else {
//             succ = node(index);
//             pred = succ.prev;
//         }

//         for (Object o : a) {
//             @SuppressWarnings("unchecked") E e = (E) o;
//             Node!E newNode = new Node<>(pred, e, null);
//             if (pred is null)
//                 first = newNode;
//             else
//                 pred.next = newNode;
//             pred = newNode;
//         }

//         if (succ is null) {
//             last = pred;
//         } else {
//             pred.next = succ;
//             succ.prev = pred;
//         }

//         _size += numNew;
//         modCount++;
//         return true;
//     }

    /**
     * Removes all of the elements from this list.
     * The list will be empty after this call returns.
     */
    override void clear() {
        _dlist.clear();
        _size = 0;
        modCount++;
    }


    // Positional Access Operations

    /**
     * Returns the element at the specified position in this list.
     *
     * @param index index of the element to return
     * @return the element at the specified position in this list
     * @throws IndexOutOfBoundsException {@inheritDoc}
     */
    override E get(int index) {
        checkElementIndex(index);

        int i=0;
        foreach(v; _dlist)
        {
            if(i == index)
                return v;
            i++;
        }
        return E.init;
    }

    /**
     * Replaces the element at the specified position in this list with the
     * specified element.
     *
     * @param index index of the element to replace
     * @param element element to be stored at the specified position
     * @return the element previously at the specified position
     * @throws IndexOutOfBoundsException {@inheritDoc}
     */
    override E set(int index, E element) {
        checkElementIndex(index);

        int i= 0;
        auto range = _dlist[];
        range.popFrontN(index);
        E oldVal = range.front;
        range.front = element;

        // for ( ; !range.empty; range.popFront())
        // {
        //     if(i == index)
        //     {
        //         oldVal = range.front;
        //         range.front = element;
        //         break;
        //     }
        //     i++;
        // }

        return oldVal;
    }

    /**
     * Inserts the specified element at the specified position in this list.
     * Shifts the element currently at that position (if any) and any
     * subsequent elements to the right (adds one to their indices).
     *
     * @param index index at which the specified element is to be inserted
     * @param element element to be inserted
     * @throws IndexOutOfBoundsException {@inheritDoc}
     */
    override void add(int index, E element) {
        checkPositionIndex(index);

        if (index == _size)
            linkLast(element);
        else
        {
            auto range = _dlist[];
            range.popFrontN(index);
            _dlist.insertBefore(range, element);
            _size++;
            modCount++;
        }
            // linkBefore(element, node(index));
    }

    /**
     * Removes the element at the specified position in this list.  Shifts any
     * subsequent elements to the left (subtracts one from their indices).
     * Returns the element that was removed from the list.
     *
     * @param index the index of the element to be removed
     * @return the element previously at the specified position
     * @throws IndexOutOfBoundsException {@inheritDoc}
     */
     E removeAt(int index) {
        checkElementIndex(index);
        auto range = _dlist[];
        range.popFrontN(index);
        auto temp = take(range, 1);
        _dlist.linearRemove(temp);

        _size--;
        modCount++;
        return temp.front;
    }

    /**
     * Tells if the argument is the index of an existing element.
     */
    private bool isElementIndex(int index) {
        return index >= 0 && index < _size;
    }

    /**
     * Tells if the argument is the index of a valid position for an
     * iterator or an add operation.
     */
    private bool isPositionIndex(int index) {
        return index >= 0 && index <= _size;
    }

    /**
     * Constructs an IndexOutOfBoundsException detail message.
     * Of the many possible refactorings of the error handling code,
     * this "outlining" performs best with both server and client VMs.
     */
    private string outOfBoundsMsg(int index) {
        return "Index: " ~ index.to!string() ~ ", Size: " ~ _size.to!string();
    }

    private void checkElementIndex(int index) {
        if (!isElementIndex(index))
            throw new IndexOutOfBoundsException(outOfBoundsMsg(index));
    }

    private void checkPositionIndex(int index) {
        if (!isPositionIndex(index))
            throw new IndexOutOfBoundsException(outOfBoundsMsg(index));
    }

    /**
     * Returns the (non-null) Node at the specified element index.
     */
     
//     Node!E node(int index) {
//         // assert isElementIndex(index);

//         if (index < (_size >> 1)) {
//             Node!E x = first;
//             for (int i = 0; i < index; i++)
//                 x = x.next;
//             return x;
//         } else {
//             Node!E x = last;
//             for (int i = _size - 1; i > index; i--)
//                 x = x.prev;
//             return x;
//         }
//     }

    // Search Operations

    /**
     * Returns the index of the first occurrence of the specified element
     * in this list, or -1 if this list does not contain the element.
     * More formally, returns the lowest index {@code i} such that
     * <tt>(o==null&nbsp;?&nbsp;get(i)==null&nbsp;:&nbsp;o.equals(get(i)))</tt>,
     * or -1 if there is no such index.
     *
     * @param o element to search for
     * @return the index of the first occurrence of the specified element in
     *         this list, or -1 if this list does not contain the element
     */
    override int indexOf(E o) {
        int index = 0;
        foreach(v; _dlist)
        {
            static if( is(E == class))
            {
                if(v == o)
                    return index;
            }
            else
            {
                if(v == o)
                    return index;
            }
            index++;
        }
        return -1;
    }

    /**
     * Returns the index of the last occurrence of the specified element
     * in this list, or -1 if this list does not contain the element.
     * More formally, returns the highest index {@code i} such that
     * <tt>(o==null&nbsp;?&nbsp;get(i)==null&nbsp;:&nbsp;o.equals(get(i)))</tt>,
     * or -1 if there is no such index.
     *
     * @param o element to search for
     * @return the index of the last occurrence of the specified element in
     *         this list, or -1 if this list does not contain the element
     */
    override int lastIndexOf(E o) {
        int index = _size;
        auto range = _dlist[];
        for(; !range.empty; range.popBack())
        {
            index--;
            if(range.back == o)
                return index;
        }
        return -1;
    }

    // Queue operations.

    /**
     * Retrieves, but does not remove, the head (first element) of this list.
     *
     * @return the head of this list, or {@code null} if this list is empty
     * @since 1.5
     */
    E peek() {        
        return getFirst();
    }

    /**
     * Retrieves, but does not remove, the head (first element) of this list.
     *
     * @return the head of this list
     * @throws NoSuchElementException if this list is empty
     * @since 1.5
     */
    E element() {
        return getFirst();
    }

    /**
     * Retrieves and removes the head (first element) of this list.
     *
     * @return the head of this list, or {@code null} if this list is empty
     * @since 1.5
     */
    E poll() {
        return removeFirst();
    }

    /**
     * Retrieves and removes the head (first element) of this list.
     *
     * @return the head of this list
     * @throws NoSuchElementException if this list is empty
     * @since 1.5
     */
    E remove() {
        return removeFirst();
    }

    /**
     * Adds the specified element as the tail (last element) of this list.
     *
     * @param e the element to add
     * @return {@code true} (as specified by {@link Queue#offer})
     * @since 1.5
     */
    bool offer(E e) {
        return add(e);
    }

    // Deque operations
    /**
     * Inserts the specified element at the front of this list.
     *
     * @param e the element to insert
     * @return {@code true} (as specified by {@link Deque#offerFirst})
     * @since 1.6
     */
    bool offerFirst(E e) {
        addFirst(e);
        return true;
    }

    /**
     * Inserts the specified element at the end of this list.
     *
     * @param e the element to insert
     * @return {@code true} (as specified by {@link Deque#offerLast})
     * @since 1.6
     */
    bool offerLast(E e) {
        addLast(e);
        return true;
    }

    /**
     * Retrieves, but does not remove, the first element of this list,
     * or returns {@code null} if this list is empty.
     *
     * @return the first element of this list, or {@code null}
     *         if this list is empty
     * @since 1.6
     */
    E peekFirst() {
        return getFirst();
     }

    /**
     * Retrieves, but does not remove, the last element of this list,
     * or returns {@code null} if this list is empty.
     *
     * @return the last element of this list, or {@code null}
     *         if this list is empty
     * @since 1.6
     */
    E peekLast() {
        return getLast();
    }

    /**
     * Retrieves and removes the first element of this list,
     * or returns {@code null} if this list is empty.
     *
     * @return the first element of this list, or {@code null} if
     *     this list is empty
     * @since 1.6
     */
    E pollFirst() {
        return removeFirst();
    }

    /**
     * Retrieves and removes the last element of this list,
     * or returns {@code null} if this list is empty.
     *
     * @return the last element of this list, or {@code null} if
     *     this list is empty
     * @since 1.6
     */
    E pollLast() {
        return removeLast();
    }

    /**
     * Pushes an element onto the stack represented by this list.  In other
     * words, inserts the element at the front of this list.
     *
     * <p>This method is equivalent to {@link #addFirst}.
     *
     * @param e the element to push
     * @since 1.6
     */
    void push(E e) {
        addFirst(e);
    }

    /**
     * Pops an element from the stack represented by this list.  In other
     * words, removes and returns the first element of this list.
     *
     * <p>This method is equivalent to {@link #removeFirst()}.
     *
     * @return the element at the front of this list (which is the top
     *         of the stack represented by this list)
     * @throws NoSuchElementException if this list is empty
     * @since 1.6
     */
    E pop() {
        return removeFirst();
    }

    /**
     * Removes the first occurrence of the specified element in this
     * list (when traversing the list from head to tail).  If the list
     * does not contain the element, it is unchanged.
     *
     * @param o element to be removed from this list, if present
     * @return {@code true} if the list contained the specified element
     * @since 1.6
     */
    bool removeFirstOccurrence(E o) {
        return remove(o);
    }

    /**
     * Removes the last occurrence of the specified element in this
     * list (when traversing the list from head to tail).  If the list
     * does not contain the element, it is unchanged.
     *
     * @param o element to be removed from this list, if present
     * @return {@code true} if the list contained the specified element
     * @since 1.6
     */
    // bool removeLastOccurrence(E o) {

    //     // if (o is null) {
    //     //     for (Node!E x = last; x !is null; x = x.prev) {
    //     //         if (x.item is null) {
    //     //             unlink(x);
    //     //             return true;
    //     //         }
    //     //     }
    //     // } else {
    //     //     for (Node!E x = last; x !is null; x = x.prev) {
    //     //         if (o.equals(x.item)) {
    //     //             unlink(x);
    //     //             return true;
    //     //         }
    //     //     }
    //     // }
    //     // return false;
    // }


//     @SuppressWarnings("unchecked")
//     private LinkedList!E superClone() {
//         try {
//             return (LinkedList!E) super.clone();
//         } catch (CloneNotSupportedException e) {
//             throw new InternalError(e);
//         }
//     }

//     /**
//      * Returns a shallow copy of this {@code LinkedList}. (The elements
//      * themselves are not cloned.)
//      *
//      * @return a shallow copy of this {@code LinkedList} instance
//      */
//     // Object clone() {
//     //     LinkedList!E clone = superClone();

//     //     // Put clone into "virgin" state
//     //     clone.first = clone.last = null;
//     //     clone.size = 0;
//     //     clone.modCount = 0;

//     //     // Initialize clone with our elements
//     //     for (Node!E x = first; x !is null; x = x.next)
//     //         clone.add(x.item);

//     //     return clone;
//     // }

    /**
     * Returns an array containing all of the elements in this list
     * in proper sequence (from first to last element).
     *
     * <p>The returned array will be "safe" in that no references to it are
     * maintained by this list.  (In other words, this method must allocate
     * a new array).  The caller is thus free to modify the returned array.
     *
     * <p>This method acts as bridge between array-based and collection-based
     * APIs.
     *
     * @return an array containing all of the elements in this list
     *         in proper sequence
     */
    override E[] toArray() {
        // E[] result = new E[_size];
        // int i = 0;
        // for (Node!E x = first; x !is null; x = x.next)
        //     result[i++] = x.item;
        return _dlist[].array;
    }

//     /**
//      * Returns an array containing all of the elements in this list in
//      * proper sequence (from first to last element); the runtime type of
//      * the returned array is that of the specified array.  If the list fits
//      * in the specified array, it is returned therein.  Otherwise, a new
//      * array is allocated with the runtime type of the specified array and
//      * the size of this list.
//      *
//      * <p>If the list fits in the specified array with room to spare (i.e.,
//      * the array has more elements than the list), the element in the array
//      * immediately following the end of the list is set to {@code null}.
//      * (This is useful in determining the length of the list <i>only</i> if
//      * the caller knows that the list does not contain any null elements.)
//      *
//      * <p>Like the {@link #toArray()} method, this method acts as bridge between
//      * array-based and collection-based APIs.  Further, this method allows
//      * precise control over the runtime type of the output array, and may,
//      * under certain circumstances, be used to save allocation costs.
//      *
//      * <p>Suppose {@code x} is a list known to contain only strings.
//      * The following code can be used to dump the list into a newly
//      * allocated array of {@code string}:
//      *
//      * <pre>
//      *     string[] y = x.toArray(new string[0]);</pre>
//      *
//      * Note that {@code toArray(new Object[0])} is identical in function to
//      * {@code toArray()}.
//      *
//      * @param a the array into which the elements of the list are to
//      *          be stored, if it is big enough; otherwise, a new array of the
//      *          same runtime type is allocated for this purpose.
//      * @return an array containing the elements of the list
//      * @throws ArrayStoreException if the runtime type of the specified array
//      *         is not a supertype of the runtime type of every element in
//      *         this list
//      * @throws NullPointerException if the specified array is null
//      */
//     @SuppressWarnings("unchecked")
//     <T> T[] toArray(T[] a) {
//         if (a.length < _size)
//             a = (T[])java.lang.reflect.Array.newInstance(
//                                 a.getClass().getComponentType(), _size);
//         int i = 0;
//         Object[] result = a;
//         for (Node!E x = first; x !is null; x = x.next)
//             result[i++] = x.item;

//         if (a.length > _size)
//             a[_size] = null;

//         return a;
//     }

//     private static final long serialVersionUID = 876323262645176354L;

//     /**
//      * Saves the state of this {@code LinkedList} instance to a stream
//      * (that is, serializes it).
//      *
//      * @serialData The size of the list (the number of elements it
//      *             contains) is emitted (int), followed by all of its
//      *             elements (each an Object) in the proper order.
//      */
//     private void writeObject(java.io.ObjectOutputStream s)
//         throws java.io.IOException {
//         // Write out any hidden serialization magic
//         s.defaultWriteObject();

//         // Write out size
//         s.writeInt(_size);

//         // Write out all elements in the proper order.
//         for (Node!E x = first; x !is null; x = x.next)
//             s.writeObject(x.item);
//     }

//     /**
//      * Reconstitutes this {@code LinkedList} instance from a stream
//      * (that is, deserializes it).
//      */
//     @SuppressWarnings("unchecked")
//     private void readObject(java.io.ObjectInputStream s)
//         throws java.io.IOException, ClassNotFoundException {
//         // Read in any hidden serialization magic
//         s.defaultReadObject();

//         // Read in size
//         int _size = s.readInt();

//         // Read in all elements in the proper order.
//         for (int i = 0; i < _size; i++)
//             linkLast((E)s.readObject());
//     }


    
        override int opApply(scope int delegate(ref E) dg)
        {
            int result = 0;
            foreach(E v; _dlist)
            {
                result = dg(v);
                if(result != 0) return result;
            }
            return result;
        }
}

unittest{
        LinkedList!(string) arrl = new LinkedList!(string)();
        arrl.add("2");
        arrl.add("1");
}