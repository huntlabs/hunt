import std.stdio;

import core.thread;
import core.time;

import std.parallelism;

// import std.experimental.logger;

import hunt.logging;
// import hunt.util.worker;


// class TestTask : Task {

// 	this(size_t id) {
// 		this.id = id;
// 	}


// 	override void doExecute() {
// 		infof("Task %d is running.", id);
// 		Thread.sleep(1.seconds);
// 		infof("Task %d is done.", id);
// 	}
// }


// void main1(string[] args) {

// 	MemoryTaskQueue memoryQueue = new MemoryTaskQueue();
// 	Worker worker = new Worker(memoryQueue);

// 	// scope(exit) {
// 	// 	worker.stop();
// 	// }

// 	worker.run();

// 	foreach(size_t index; 0.. 10) {
// 		tracef("push task %d", index);
// 		memoryQueue.push(new TestTask(index));
// 		Thread.sleep(500.msecs);
// 	}

// 	warning("Press any to exit");
// 	// getchar();
// 	worker.stop();
// }



void main() {
	// testThread();
	testTaskPool();
}

void testTaskPool() {

    // enum Total = 15;  // It's Ok when Total <= 15
    enum Total = 16;  // It's blocked by Thread.sleep(dur) when Total >= 16;

    for(size_t group = 0; group<Total; group++) {
		
		auto testTask = task(() {
				tracef("testing...");
				
				try {
					useTaskPool(); 	// bug test
					// useThread(); 		// It's always ok
				} catch(Exception ex) {
					warning(ex);
				}

				Duration dur = 10.seconds;
				infof("Sleeping %s", dur);
				Thread.sleep(dur);
				infof("awake now");
				tracef("testing done");
		});

		taskPool.put(testTask);
    }

    warning("press any key to close");
    getchar();	
}


void useThread() {
	Thread th = new Thread(&doSomething);
	th.start();
}

void useTaskPool() {
	auto testTask = task(&doSomething);
	taskPool.put(testTask);
}

void testTaskPool1() {

    int[] pa = new int[20];

    for(size_t index = 0; index<pa.length; index++) {
        pa[index] = cast(int)index;
    }
    
    foreach(int group; parallel(pa)) {
        foreach(int index; 0..1) {
            tracef("testing: %d => %d ...", group, index);
            
            try {
				useTaskPool(); // bug
				// useThread(); // ok
            } catch(Exception ex) {
                infof("group: %d", group);
                warning(ex);
            }

			Duration dur = 10.seconds;
			infof("Sleeping %s", dur);
            Thread.sleep(dur);
			infof("awake now");

            tracef("testing done: %d => %d", group, index);
        }
    }

    warning("press any key to close");
    getchar();	
}


void testThread() {

    Thread[] testThreads = new Thread[20];

    for(size_t group = 0; group<testThreads.length; group++) {
        Thread th = new Thread(() {
			foreach(int index; 0..1) {
				tracef("testing: %d => %d ...", group, index);
				
				try {
					useTaskPool(); // OK
				} catch(Exception ex) {
					infof("group: %d", group);
					warning(ex);
				}

				Thread.sleep(10.seconds);

				tracef("testing done: %d => %d", group, index);
			}
		});

		th.start();

		testThreads[group] = th;
    }
    
    warning("press any key to close");

	for(size_t group = 0; group<testThreads.length; group++) {
		testThreads[group].join();
	}

    getchar();	
}


void doSomething() {
	info("executing...");
	Thread.sleep(2.seconds);
}