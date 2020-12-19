module hunt.util.concurrency.TaskQueue;

import hunt.util.concurrency.Task;

/**
 * 
 */
interface TaskQueue {

    bool isEmpty();

    Task pop();

    void push(Task task);
}
