import std.stdio;

import core.thread;
import core.time;

import hunt.logging.ConsoleLogger;
import hunt.util.worker;


class TestTask : Task {

	this(size_t id) {
		this.id = id;
	}


	override void doExecute() {
		infof("Task %d is running.", id);
		Thread.sleep(1.seconds);
		infof("Task %d is done.", id);
	}
}


void main(string[] args) {

	MemoryTaskQueue memoryQueue = new MemoryTaskQueue();
	Worker worker = new Worker(memoryQueue);

	worker.run();

	foreach(size_t index; 0.. 10) {
		tracef("push task %d", index);
		memoryQueue.push(new TestTask(index));
		Thread.sleep(500.msecs);
	}

}