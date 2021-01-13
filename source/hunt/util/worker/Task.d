module hunt.util.worker.Task;

enum TaskStatus : ubyte {
    Ready,
    Processing,
    Done
}

/**
 * 
 */
abstract class Task {
    protected TaskStatus _status;

    this() {
        _status = TaskStatus.Ready;
    }

    TaskStatus status() {
        return _status;
    }

    void execute();
}