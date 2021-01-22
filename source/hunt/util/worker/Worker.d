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
        
        foreach(size_t index; 0 .. _size) {
            WorkerThread thread = new WorkerThread(index);
            thread.start();

            _workerThreads[index] = thread;
        }
    }

    void inspect() {

        _taskQueue.inspect();

        foreach(WorkerThread th; _workerThreads) {
            
            Task task = th.task();

            if(th.state() == WorkerThreadState.Busy) {
                if(task is null) {
                    warning("A dead worker thread detected: %s, %s", th.name, th.state());
                } else {
                    tracef("Thread: %s,  state: %s, lifeTime: %s", th.name, th.state(), task.lifeTime());
                }
            } else {
                if(task is null) {
                    tracef("Thread: %s,  state: %s", th.name, th.state());
                } else {
                    tracef("Thread: %s,  state: %s", th.name, th.state(), task.executionTime);
                }
            }
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
        foreach(size_t index, WorkerThread thread; _workerThreads) {
            version(HUNT_IO_DEBUG) {
                tracef("Thread: %s, state: %s", thread.name, thread.state);
            }

            if(thread.isIdle())
                return thread;
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
                bool isAttatched = false;
                
                do {
                    workerThread = findIdleThread();
                    if(workerThread is null) {
                        // version(HUNT_IO_DEBUG) 
                        // warning("All worker threads are busy!");
                        trace("All worker threads are busy!");

                        // FIXME: Needing refactor or cleanup -@zhangxueping at 2021-01-21T11:24:11+08:00
                        // 
                        // Thread.sleep(1.seconds);
                        // Thread.sleep(10.msecs);
                    } else {
                        isAttatched = workerThread.attatch(task);
                    }
                } while(!isAttatched && _isRunning);

            } catch(Exception ex) {
                warning(ex);
            }
        }

        version(HUNT_IO_DEBUG) warning("Done!");

    }

}

