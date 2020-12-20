import std.stdio;

import core.thread;
import core.time;

import hunt.logging.ConsoleLogger;
import hunt.util.worker;


class TestTask : Task {
	private size_t _index;

	this(size_t index) {
		_index = index;
	}

	size_t index() {
		return _index;
	}

	void execute() {
		infof("Task %d is running.", index);
		Thread.sleep(1.seconds);
		infof("Task %d is done.", index);
	}
}


void main(string[] args) {

	MemoryQueue memoryQueue = new MemoryQueue();
	Worker worker = new Worker(memoryQueue);

	worker.run();

	foreach(size_t index; 0.. 10) {
		tracef("push task %d", index);
		memoryQueue.push(new TestTask(index));
		Thread.sleep(500.msecs);
	}

}