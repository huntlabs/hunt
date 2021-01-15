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
    // private WorkerThread[] _availableThreads;

    private TaskQueue _taskQueue;
    private bool _isRunning = false;

    this(TaskQueue taskQueue, size_t size = 8) {
        _taskQueue = taskQueue;
        _size = size;

        version(HUNT_DEBUG) {
            infof("Worker size: %d", size);
        }

        initialize();
    }

    private void initialize() {
        _workerThreads = new WorkerThread[_size];
        // _availableThreads = new WorkerThread[_size];
        
        foreach(size_t index; 0 .. _size) {
            WorkerThread thread = new WorkerThread(index);
            thread.start();

            _workerThreads[index] = thread;
            // _availableThreads[index] = thread;
        }
    }

    void inspect() {
        foreach(WorkerThread th; _workerThreads) {
            tracef("Thread: %s,  state: %s", th.name, th.state());
        }

        // info("===============Available threads");

        // foreach(WorkerThread th; _availableThreads) {
        //     if(th !is null)
        //     tracef("Thread: %s,  state: %s", th.name, th.state());
        // }
    }

    void put(Task task) {
        _taskQueue.push(task);
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
            // _availableThreads[index] = null;
        }
    }

    // void setWorkerThreadAvailable(size_t index) nothrow {
    //     _availableThreads[index] = _workerThreads[index];
    // }

    private WorkerThread findIdleThread() {
        foreach(size_t index; 0 .. _size) {
            WorkerThread thread = _workerThreads[index];
            version(HUNT_IO_DEBUG) {
                tracef("Thread: %s, state: %s", thread.name, thread.state);
            }

            if(!thread.isBusy)
                return thread;
            // if(thread !is null) {
            //     _availableThreads[index] = null;
            //     return thread;
            // }
        }

        return null;
    } 

    private void doRun() {
        while(_isRunning) {
            try {
                version(HUNT_IO_DEBUG) info("running...");
                Task task = _taskQueue.pop();
                if(task is null) {
                    version(HUNT_IO_DEBUG) {
                        warning("A null task popped!");
                        inspect();
                    }
                    continue;
                }

                WorkerThread workerThread;
                
                do {
                    workerThread = findIdleThread();
                    if(workerThread is null) {
                        warning("All worker threads are busy!");
                        // return;
                        Thread.sleep(1.seconds);
                    }
                } while(workerThread is null);

                workerThread.attatch(task);

            } catch(Exception ex) {
                warning(ex);
            }
        }

        version(HUNT_IO_DEBUG) warning("Done!");

    }

}

