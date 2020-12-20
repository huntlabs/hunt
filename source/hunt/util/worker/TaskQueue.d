module hunt.util.worker.TaskQueue;

import hunt.util.worker.Task;

/**
 * 
 */
interface TaskQueue {

    bool isEmpty();

    Task pop();

    void push(Task task);
}
