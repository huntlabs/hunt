module hunt.util.worker.TaskQueue;

import hunt.util.worker.Task;

/**
 * 
 */
abstract class TaskQueue {

    bool isEmpty();

    Task pop();

    void push(Task task);


version (HUNT_METRIC) {
    void inspect();
}    
    
}
