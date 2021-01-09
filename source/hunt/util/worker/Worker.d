module hunt.util.worker.Worker;

import hunt.util.worker.Task;
import hunt.util.worker.TaskQueue;
import hunt.util.worker.WorkerThread;

import core.thread;
import core.sync.condition;
import core.sync.mutex;
import std.conv; 

import hunt.logging.ConsoleLogger;


/**
 * 
 */
class Worker {

    private size_t _size;

    private WorkerThread[] _workerThreads;
    private WorkerThread[] _availableThreads;

    private TaskQueue _taskQueue;
    private bool _isRunning = false;

    this(TaskQueue taskQueue, size_t size = 8) {
        _taskQueue = taskQueue;
        _size = size;

        initialize();
    }

    private void initialize() {
        _workerThreads = new WorkerThread[_size];
        _availableThreads = new WorkerThread[_size];
        
        foreach(size_t index; 0 .. _size) {
            WorkerThread thread = new WorkerThread(this, index);
            thread.start();

            _workerThreads[index] = thread;
            _availableThreads[index] = thread;
        }
    }

    void run() {
        if(_isRunning)
            return;
        _isRunning = true;

        // doRun() 
        import std.parallelism;

        auto t = task(&doRun);
        t.executeInNewThread();
    }

    void stop() {
        _isRunning = false;
        foreach(size_t index; 0 .. _size) {
            _workerThreads[index].stop();
            _availableThreads[index] = null;
        }
    }

    void setWorkerThreadAvailable(size_t index) nothrow {
        _availableThreads[index] = _workerThreads[index];
    }

    private WorkerThread findIdleThread() {
        foreach(size_t index; 0 .. _size) {
            WorkerThread thread = _availableThreads[index];
            if(thread !is null) {
                _availableThreads[index] = null;
                return thread;
            }
        }

        return null;
    } 

    private void doRun() {
        while(_isRunning) {
            try {
                version(HUNT_IO_DEBUG) trace("running...");
                Task task = _taskQueue.pop();

                WorkerThread workerThread = findIdleThread();
                if(workerThread is null) {
                    warning("No available worker thread found.");
                    return;
                }

                workerThread.attatch(task);
            } catch(Exception ex) {
                warning(ex);
            }
        }

        version(HUNT_IO_DEBUG) warning("Done!");

    }

}

