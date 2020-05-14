module hunt.io.worker.WorkerGroupObject;

import hunt.io.worker.WorkerGroup;
import hunt.io.channel;
import hunt.system.Memory;

__gshared WorkerGroup!AbstractStream gWorkerGroup = null;


void startWorkerGroup(size_t threadSize = (totalCPUs - 1))
{
    gWorkerGroup = new WorkerGroup!AbstractStream(threadSize);
    gWorkerGroup.run();
}
