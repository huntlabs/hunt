module hunt.util.queue.Queue;

/**
 * 
 */
abstract class Queue(T) {

    bool isEmpty();

    T pop();

    void push(T task);

    void clear();

}