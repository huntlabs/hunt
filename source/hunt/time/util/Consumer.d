module hunt.time.util.Consumer;


public interface Consumer(T) {

    /**
     * Performs this operation on the given argument.
     *
     * @param t the input argument
     */
    void accept(T t);

    /**
     * Returns a composed {@code Consumer} that performs, in sequence, this
     * operation followed by the {@code after} operation. If performing either
     * operation throws an exception, it is relayed to the caller of the
     * composed operation.  If performing this operation throws an exception,
     * the {@code after} operation will not be performed.
     *
     * @param after the operation to perform after this operation
     * @return a composed {@code Consumer} that performs in sequence this
     * operation followed by the {@code after} operation
     * @throws NullPointerException if {@code after} is null
     */
     Consumer!T andThen(R)(Consumer!R after) if(is(R : T)) {
        assert(after);
        return new class Consumer!T{
            void accept(T t){ accept(t); after.accept(t); }
        };
    }
}
