module hunt.container.Iterable;


/**
 * Implementing this interface allows an object to be the target of
 * the "for-each loop" statement. 
 * @param <T> the type of elements returned by the iterator
 */
interface Iterable(T) {
   int opApply(scope int delegate(ref T) dg);
}

interface Iterable(K, V) {
   int opApply(scope int delegate(ref K, ref V) dg);
}
