module hunt.util.concurrency.worker.TaskQueue;

import hunt.util.concurrency.worker.Task;

/**
 * 
 */
interface TaskQueue {

    bool isEmpty();

    Task pop();

    void push(Task task);
}
