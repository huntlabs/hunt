module hunt.collection.ArrayList;

import std.algorithm;
import std.array;
import std.conv;
import std.traits;

import hunt.exception;
import hunt.collection.array;
import hunt.collection.AbstractList;
import hunt.collection.Collection;
import hunt.collection.List;
import hunt.util.Comparator;

/**
*/
class ArrayList(E) : AbstractList!E {

    // private enum long serialVersionUID = 8683452581122892189L;

    /**
     * Default initial capacity.
     */
    private enum int DEFAULT_CAPACITY = 10;

    /**
     * Shared empty array instance used for empty instances.
     */
    private enum Object[] EMPTY_ELEMENTDATA = [];

    /**
     * Shared empty array instance used for default sized empty instances. We
     * distinguish this from EMPTY_ELEMENTDATA to know how much to inflate when
     * first element is added.
     */
    private enum Object[] DEFAULTCAPACITY_EMPTY_ELEMENTDATA = [];

    
    protected Array!(E) _array;

    /**
     * Constructs an empty list with the specified initial capacity.
     *
     * @param  initialCapacity  the initial capacity of the list
     * @throws Exception if the specified initial capacity
     *         is negative
     */
    this(int initialCapacity) {
        _array.reserve(initialCapacity);
        super();
        // if (initialCapacity > 0) {
        //     this._array = new Object[initialCapacity];
        // } else if (initialCapacity == 0) {
        //     this._array = EMPTY_ELEMENTDATA;
        // } else {
        //     throw new Exception("Illegal Capacity: "+
        //                                        initialCapacity);
        // }
    }

    /**
     * Constructs an empty list with an initial capacity of ten.
     */
    this() {
        // this._array = DEFAULTCAPACITY_EMPTY_ELEMENTDATA;
        _array.reserve(16);
        super();
    }

    /**
     * Constructs a list containing the elements of the specified
     * collection, in the order they are returned by the collection's
     * iterator.
     *
     * @param c the collection whose elements are to be placed into this list
     * @throws NullPointerException if the specified collection is null
     */
     this(ref Array!E arr) {
         _array = arr;
     }

     this(E[] arr) {
         _array.insertBack(arr);
     }

    this(Collection!E c) {
        foreach(E e; c) {
            _array.insertBack(e);
        }
    }

    /**
     * Trims the capacity of this <tt>ArrayList</tt> instance to be the
     * list's current size.  An application can use this operation to minimize
     * the storage of an <tt>ArrayList</tt> instance.
     */
    // void trimToSize() {
    //     modCount++;
    //     if (size < _array.length) {
    //         _array = (size == 0)
    //           ? EMPTY_ELEMENTDATA
    //           : Arrays.copyOf(_array, size);
    //     }
    // }

    /**
     * Increases the capacity of this <tt>ArrayList</tt> instance, if
     * necessary, to ensure that it can hold at least the number of elements
     * specified by the minimum capacity argument.
     *
     * @param   minCapacity   the desired minimum capacity
     */
    // void ensureCapacity(int minCapacity) {
    //     int minExpand = (_array != DEFAULTCAPACITY_EMPTY_ELEMENTDATA)
    //         // any size if not default element table
    //         ? 0
    //         // larger than default for default empty table. It's already
    //         // supposed to be at default size.
    //         : DEFAULT_CAPACITY;

    //     if (minCapacity > minExpand) {
    //         ensureExplicitCapacity(minCapacity);
    //     }
    // }

    // private void ensureCapacityInternal(int minCapacity) {
    //     if (_array == DEFAULTCAPACITY_EMPTY_ELEMENTDATA) {
    //         minCapacity = std.algorithm.max(DEFAULT_CAPACITY, minCapacity);
    //     }

    //     ensureExplicitCapacity(minCapacity);
    // }

    // private void ensureExplicitCapacity(int minCapacity) {
    //     modCount++;

    //     // overflow-conscious code
    //     if (minCapacity - _array.length > 0)
    //         grow(minCapacity);
    // }

    /**
     * The maximum size of array to allocate.
     * Some VMs reserve some header words in an array.
     * Attempts to allocate larger arrays may result in
     * OutOfMemoryError: Requested array size exceeds VM limit
     */
    private enum int MAX_ARRAY_SIZE = int.max - 8;



    /**
     * Returns the number of elements in this list.
     *
     * @return the number of elements in this list
     */
    override int size() {
        return cast(int)_array.length;
    }

    /**
     * Returns <tt>true</tt> if this list contains no elements.
     *
     * @return <tt>true</tt> if this list contains no elements
     */
    override bool isEmpty() {
        return _array.empty;
    }

    /**
     * Returns <tt>true</tt> if this list contains the specified element.
     * More formally, returns <tt>true</tt> if and only if this list contains
     * at least one element <tt>e</tt> such that
     * <tt>(o==null&nbsp;?&nbsp;e==null&nbsp;:&nbsp;o.equals(e))</tt>.
     *
     * @param o element whose presence in this list is to be tested
     * @return <tt>true</tt> if this list contains the specified element
     */
    override bool contains(E o) const{
        return _array[].canFind(o);
    }


    /**
     * Returns a shallow copy of this <tt>ArrayList</tt> instance.  (The
     * elements themselves are not copied.)
     *
     * @return a clone of this <tt>ArrayList</tt> instance
     */
    // Object clone() {

    // }

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
     * @return an array containing all of the elements in this list in
     *         proper sequence
     */
    override E[] toArray() {
        return _array.array;
    }

    

    // Positional Access Operations

    // 
    E elementData(int index) {
        return _array[index];
    }

    /**
     * Returns the element at the specified position in this list.
     *
     * @param  index index of the element to return
     * @return the element at the specified position in this list
     * @throws IndexOutOfBoundsException {@inheritDoc}
     */
    override E get(int index) {
        rangeCheck(index);

        return cast(E)_array[index];
    }

    /**
     * Replaces the element at the specified position in this list with
     * the specified element.
     *
     * @param index index of the element to replace
     * @param element element to be stored at the specified position
     * @return the element previously at the specified position
     * @throws IndexOutOfBoundsException {@inheritDoc}
     */
    override E set(int index, E element) {
        rangeCheck(index);

        E oldValue = _array[index];
        _array[index] = element;
        return oldValue;
    }

    /**
     * Appends the specified element to the end of this list.
     *
     * @param e element to be appended to this list
     * @return <tt>true</tt> (as specified by {@link Collection#add})
     */
    // bool add(E e) {
    //     ensureCapacityInternal(size + 1);  // Increments modCount!!
    //     _array[size++] = e;
    //     return true;
    // }
    override bool add(E e) {
        return _array.insertBack(e) >=0;
    }

    /**
     * Inserts the specified element at the specified position in this
     * list. Shifts the element currently at that position (if any) and
     * any subsequent elements to the right (adds one to their indices).
     *
     * @param index index at which the specified element is to be inserted
     * @param element element to be inserted
     * @throws IndexOutOfBoundsException {@inheritDoc}
     */
    override void add(int index, E element) {
        if(_array.length == 0)
            _array.insertBack(element) ;
        else {
            if(index <= 0) 
                index = 1;
            _array.insertAfter(_array[index-1 .. index], element);
        }
    }

    alias add = AbstractList!(E).add;

    /**
     * Removes the element at the specified position in this list.
     * Shifts any subsequent elements to the left (subtracts one from their
     * indices).
     *
     * @param index the index of the element to be removed
     * @return the element that was removed from the list
     * @throws IndexOutOfBoundsException {@inheritDoc}
     */
    override E removeAt(int index) {
        E oldValue = _array[index];
        _array.linearRemove(_array[index .. index+1]);
        return oldValue;
    }

    /**
     * Removes the first occurrence of the specified element from this list,
     * if it is present.  If the list does not contain the element, it is
     * unchanged.  More formally, removes the element with the lowest index
     * <tt>i</tt> such that
     * <tt>(o==null&nbsp;?&nbsp;get(i)==null&nbsp;:&nbsp;o.equals(get(i)))</tt>
     * (if such an element exists).  Returns <tt>true</tt> if this list
     * contained the specified element (or equivalently, if this list
     * changed as a result of the call).
     *
     * @param o element to be removed from this list, if present
     * @return <tt>true</tt> if this list contained the specified element
     */
    override bool remove(E o)
    {
        int index = indexOf(o);
        if(index < 0)   return false;
        _array.linearRemove(_array[index .. index+1]);
        return true;
    }

    override int indexOf(E o) {
        for(size_t i=0; i<_array.length; i++)
        {
            static if(is(E == class))
            {
                if(_array[i] is o) return cast(int)i;
            }
            else
            {
                if(_array[i] == o) return cast(int)i;
            }
        }

        return -1;
    }

    override int lastIndexOf(E o) {
        for(size_t i=_array.length -1; i>=0; i--) {
            if(_array[i] == o) return cast(int)i;
        }

        return -1;
    }


    override int opApply(scope int delegate(ref E) dg) {
        if(dg is null)
            throw new NullPointerException();
            
        int result = 0;
        foreach(E v; _array) {
            result = dg(v);
            if(result != 0) return result;
        }
        return result;
    }


    /*
     * Private remove method that skips bounds checking and does not
     * return the value removed.
     */
    // private void fastRemove(int index) {
    //     modCount++;
    //     int numMoved = size - index - 1;
    //     if (numMoved > 0)
    //         System.arraycopy(_array, index+1, _array, index,
    //                          numMoved);
    //     _array[--size] = null; // clear to let GC do its work
    // }

    /**
     * Removes all of the elements from this list.  The list will
     * be empty after this call returns.
     */
    override void clear() {
        _array.clear();
    }

    /**
     * Appends all of the elements in the specified collection to the end of
     * this list, in the order that they are returned by the
     * specified collection's Iterator.  The behavior of this operation is
     * undefined if the specified collection is modified while the operation
     * is in progress.  (This implies that the behavior of this call is
     * undefined if the specified collection is this list, and this
     * list is nonempty.)
     *
     * @param c collection containing elements to be added to this list
     * @return <tt>true</tt> if this list changed as a result of the call
     * @throws NullPointerException if the specified collection is null
     */
    // bool addAll(Collection<E> c) {
    //     Object[] a = c.toArray();
    //     int numNew = a.length;
    //     ensureCapacityInternal(size + numNew);  // Increments modCount
    //     System.arraycopy(a, 0, _array, size, numNew);
    //     size += numNew;
    //     return numNew != 0;
    // }

    /**
     * Inserts all of the elements in the specified collection into this
     * list, starting at the specified position.  Shifts the element
     * currently at that position (if any) and any subsequent elements to
     * the right (increases their indices).  The new elements will appear
     * in the list in the order that they are returned by the
     * specified collection's iterator.
     *
     * @param index index at which to insert the first element from the
     *              specified collection
     * @param c collection containing elements to be added to this list
     * @return <tt>true</tt> if this list changed as a result of the call
     * @throws IndexOutOfBoundsException {@inheritDoc}
     * @throws NullPointerException if the specified collection is null
     */
    // bool addAll(int index, Collection<E> c) {
    //     rangeCheckForAdd(index);

    //     Object[] a = c.toArray();
    //     int numNew = a.length;
    //     ensureCapacityInternal(size + numNew);  // Increments modCount

    //     int numMoved = size - index;
    //     if (numMoved > 0)
    //         System.arraycopy(_array, index, _array, index + numNew,
    //                          numMoved);

    //     System.arraycopy(a, 0, _array, index, numNew);
    //     size += numNew;
    //     return numNew != 0;
    // }

    /**
     * Removes from this list all of the elements whose index is between
     * {@code fromIndex}, inclusive, and {@code toIndex}, exclusive.
     * Shifts any succeeding elements to the left (reduces their index).
     * This call shortens the list by {@code (toIndex - fromIndex)} elements.
     * (If {@code toIndex==fromIndex}, this operation has no effect.)
     *
     * @throws IndexOutOfBoundsException if {@code fromIndex} or
     *         {@code toIndex} is out of range
     *         ({@code fromIndex < 0 ||
     *          fromIndex >= size() ||
     *          toIndex > size() ||
     *          toIndex < fromIndex})
     */
    protected void removeRange(int fromIndex, int toIndex) {
        _array.linearRemove(_array[fromIndex..toIndex]);
    }

    /**
     * Checks if the given index is in range.  If not, throws an appropriate
     * runtime exception.  This method does *not* check if the index is
     * negative: It is always used immediately prior to an array access,
     * which throws an ArrayIndexOutOfBoundsException if index is negative.
     */
    private void rangeCheck(int index) {
        if (index >= _array.length)
            throw new IndexOutOfBoundsException(outOfBoundsMsg(index));
    }

    /**
     * A version of rangeCheck used by add and addAll.
     */
    private void rangeCheckForAdd(int index) {
        if (index > _array.length || index < 0)
            throw new IndexOutOfBoundsException(outOfBoundsMsg(index));
    }

    /**
     * Constructs an IndexOutOfBoundsException detail message.
     * Of the many possible refactorings of the error handling code,
     * this "outlining" performs best with both server and client VMs.
     */
    private string outOfBoundsMsg(int index) {
        return "Index: "~index.to!string()~", Size: " ~ to!string(size());
    }

    /**
     * Removes from this list all of its elements that are contained in the
     * specified collection.
     *
     * @param c collection containing elements to be removed from this list
     * @return {@code true} if this list changed as a result of the call
     * @throws ClassCastException if the class of an element of this list
     *         is incompatible with the specified collection
     * (<a href="Collection.html#optional-restrictions">optional</a>)
     * @throws NullPointerException if this list contains a null element and the
     *         specified collection does not permit null elements
     * (<a href="Collection.html#optional-restrictions">optional</a>),
     *         or if the specified collection is null
     * @see Collection#contains(Object)
     */
    // bool removeAll(Collection<?> c) {
    //     Objects.requireNonNull(c);
    //     return batchRemove(c, false);
    // }

    /**
     * Retains only the elements in this list that are contained in the
     * specified collection.  In other words, removes from this list all
     * of its elements that are not contained in the specified collection.
     *
     * @param c collection containing elements to be retained in this list
     * @return {@code true} if this list changed as a result of the call
     * @throws ClassCastException if the class of an element of this list
     *         is incompatible with the specified collection
     * (<a href="Collection.html#optional-restrictions">optional</a>)
     * @throws NullPointerException if this list contains a null element and the
     *         specified collection does not permit null elements
     * (<a href="Collection.html#optional-restrictions">optional</a>),
     *         or if the specified collection is null
     * @see Collection#contains(Object)
     */
    // bool retainAll(Collection!E c) {
    //     assert(c !is null);
    //     // return batchRemove(c, true);

    //     _array[].remove!(x => !c.canFind(x));
    //     return true;
    // }

    // private bool batchRemove(Collection<?> c, bool complement) {
    //     final Object[] _array = this._array;
    //     int r = 0, w = 0;
    //     bool modified = false;
    //     try {
    //         for (; r < size; r++)
    //             if (c.contains(_array[r]) == complement)
    //                 _array[w++] = _array[r];
    //     } finally {
    //         // Preserve behavioral compatibility with AbstractCollection,
    //         // even if c.contains() throws.
    //         if (r != size) {
    //             System.arraycopy(_array, r,
    //                              _array, w,
    //                              size - r);
    //             w += size - r;
    //         }
    //         if (w != size) {
    //             // clear to let GC do its work
    //             for (int i = w; i < size; i++)
    //                 _array[i] = null;
    //             modCount += size - w;
    //             size = w;
    //             modified = true;
    //         }
    //     }
    //     return modified;
    // }

    /**
     * Save the state of the <tt>ArrayList</tt> instance to a stream (that
     * is, serialize it).
     *
     * @serialData The length of the array backing the <tt>ArrayList</tt>
     *             instance is emitted (int), followed by all of its elements
     *             (each an <tt>Object</tt>) in the proper order.
     */
    // private void writeObject(java.io.ObjectOutputStream s)
    //     throws java.io.IOException{
    //     // Write out element count, and any hidden stuff
    //     int expectedModCount = modCount;
    //     s.defaultWriteObject();

    //     // Write out size as capacity for behavioural compatibility with clone()
    //     s.writeInt(size);

    //     // Write out all elements in the proper order.
    //     for (int i=0; i<size; i++) {
    //         s.writeObject(_array[i]);
    //     }

    //     if (modCount != expectedModCount) {
    //         throw new ConcurrentModificationException();
    //     }
    // }

    /**
     * Reconstitute the <tt>ArrayList</tt> instance from a stream (that is,
     * deserialize it).
     */
    // private void readObject(java.io.ObjectInputStream s)
    //     throws java.io.IOException, ClassNotFoundException {
    //     _array = EMPTY_ELEMENTDATA;

    //     // Read in size, and any hidden stuff
    //     s.defaultReadObject();

    //     // Read in capacity
    //     s.readInt(); // ignored

    //     if (size > 0) {
    //         // be like clone(), allocate array based upon size not capacity
    //         ensureCapacityInternal(size);

    //         Object[] a = _array;
    //         // Read in all elements in the proper order.
    //         for (int i=0; i<size; i++) {
    //             a[i] = s.readObject();
    //         }
    //     }
    // }


    /**
     * Returns a view of the portion of this list between the specified
     * {@code fromIndex}, inclusive, and {@code toIndex}, exclusive.  (If
     * {@code fromIndex} and {@code toIndex} are equal, the returned list is
     * empty.)  The returned list is backed by this list, so non-structural
     * changes in the returned list are reflected in this list, and vice-versa.
     * The returned list supports all of the optional list operations.
     *
     * <p>This method eliminates the need for explicit range operations (of
     * the sort that commonly exist for arrays).  Any operation that expects
     * a list can be used as a range operation by passing a subList view
     * instead of a whole list.  For example, the following idiom
     * removes a range of elements from a list:
     * <pre>
     *      list.subList(from, to).clear();
     * </pre>
     * Similar idioms may be constructed for {@link #indexOf(Object)} and
     * {@link #lastIndexOf(Object)}, and all of the algorithms in the
     * {@link Collections} class can be applied to a subList.
     *
     * <p>The semantics of the list returned by this method become undefined if
     * the backing list (i.e., this list) is <i>structurally modified</i> in
     * any way other than via the returned list.  (Structural modifications are
     * those that change the size of this list, or otherwise perturb it in such
     * a fashion that iterations in progress may yield incorrect results.)
     *
     * @throws IndexOutOfBoundsException {@inheritDoc}
     * @throws Exception {@inheritDoc}
     */
    // List<E> subList(int fromIndex, int toIndex) {
    //     subListRangeCheck(fromIndex, toIndex, size);
    //     return new SubList(this, 0, fromIndex, toIndex);
    // }

    // static void subListRangeCheck(int fromIndex, int toIndex, int size) {
    //     if (fromIndex < 0)
    //         throw new IndexOutOfBoundsException("fromIndex = " ~ fromIndex);
    //     if (toIndex > size)
    //         throw new IndexOutOfBoundsException("toIndex = " ~ toIndex);
    //     if (fromIndex > toIndex)
    //         throw new Exception("fromIndex(" ~ fromIndex +
    //                                            ") > toIndex(" ~ toIndex ~ ")");
    // }

    static if (isOrderingComparable!E) {
    override void sort(bool isAscending = true) {
        
            // https://issues.dlang.org/show_bug.cgi?id=15304
            // std.algorithm.sort(_array[]);
            
            int expectedModCount = modCount;
            if(isAscending)
                std.algorithm.sort!(lessThan!E)(_array[]);
            else
                std.algorithm.sort!(greaterthan!E)(_array[]);
                
            if (modCount != expectedModCount)
                throw new ConcurrentModificationException();
            modCount++;
        } 
    }


    override void sort(Comparator!E c) {
        int expectedModCount = modCount;
        std.algorithm.sort!((a, b) => c.compare(a, b) < 0)(_array[]);

        if (modCount != expectedModCount)
            throw new ConcurrentModificationException();
        modCount++;
    }

}

/**
 * Lazy List creation.
 * <p>
 * A List helper class that attempts to avoid unnecessary List creation. If a
 * method needs to create a List to return, but it is expected that this will
 * either be empty or frequently contain a single item, then using LazyList will
 * avoid additional object creations by using {@link Collections#EMPTY_LIST} or
 * {@link Collections#singletonList(Object)} where possible.
 * </p>
 * <p>
 * LazyList works by passing an opaque representation of the list in and out of
 * all the LazyList methods. This opaque object is either null for an empty
 * list, an Object for a list with a single entry or an {@link ArrayList} for a
 * list of items.
 * </p>
 * <strong>Usage</strong>
 * 
 * <pre>
 * Object lazylist = null;
 * while (loopCondition) {
 * 	Object item = getItem();
 * 	if (item.isToBeAdded())
 * 		lazylist = LazyList.add(lazylist, item);
 * }
 * return LazyList.getList(lazylist);
 * </pre>
 *
 * An ArrayList of default size is used as the initial LazyList.
 *
 * @see java.util.List
 */
class LazyList
{
    // this(){

    // }

	/**
	 * Add an item to a LazyList
	 * 
	 * @param list
	 *            The list to add to or null if none yet created.
	 * @param item
	 *            The item to add.
	 * @return The lazylist created or added to.
	 */
    static Object add(Object list, Object item) {
		if (list is null) {
			if (typeid(item) == typeid(List!Object) || item is null) {
				List!Object l = new ArrayList!Object();
				l.add(item);
				return cast(Object)l;
			}

			return item;
		}

		if (typeid(list) == typeid(List!Object)) {
			(cast(List!Object) list).add(item);
			return list;
		}

		List!Object l = new ArrayList!Object();
		l.add(list);
		l.add(item);
		return cast(Object)l;
	}

    	/**
	 * Get the real List from a LazyList.
	 * 
	 * @param list
	 *            A LazyList returned from LazyList.add(Object) or null
	 * @param nullForEmpty
	 *            If true, null is returned instead of an empty list.
	 * @return The List of added items, which may be null, an EMPTY_LIST or a
	 *         SingletonList.
	 * @param <E>
	 *            the list entry type
	 */
	static List!E getList(E)(Object list, bool nullForEmpty) {
		if (list is null) {
			if (nullForEmpty)
				return null;
			return  new EmptyList!E(); // Collections.emptyList();
		}
        List!E r = cast(List!E) list;
		if (r !is null)
			return r;

		// return (List<E>) Collections.singletonList(list);
        auto l = new ArrayList!E();
        l.add(cast(E)list);
        return l;
	}


	/**
	 * The size of a lazy List
	 * 
	 * @param list
	 *            A LazyList returned from LazyList.add(Object) or null
	 * @return the size of the list.
	 */
	static int size(T)(List!(T) list) {
		if (list is null)
			return 0;
		return list.size();
	}

}