module test.ForkJoinPoolTest;

import hunt.concurrency.ForkJoinPool;
import hunt.concurrency.ForkJoinTask;

import hunt.logging.ConsoleLogger;
import hunt.util.Common;
import hunt.util.DateTime;
import hunt.util.UnitTest;

import hunt.system.Memory;

import std.conv;

class ForkJoinPoolTest {

    void testBasic() {

        int nThreads = totalCPUs;
        int[] numbers = new int[1000];

        for (int i = 0; i < numbers.length; i++) {
            numbers[i] = i;
        }

        ForkJoinPool forkJoinPool = new ForkJoinPool(nThreads);
        long result = forkJoinPool.invoke(new Sum(numbers, 0, cast(int)numbers.length));
        assert(result == 499500, result.to!string());
    }
}

class Sum : RecursiveTask!long {
    int low;
    int high;
    int[] array;

    this(int[] array, int low, int high) {
        this.array = array;
        this.low = low;
        this.high = high;
    }

    override protected long compute() {

        if (high - low <= 10) {
            long sum = 0;

            for (int i = low; i < high; ++i)
                sum += array[i];
            return sum;
        } else {
            int mid = low + (high - low) / 2;
            Sum left = new Sum(array, low, mid);
            Sum right = new Sum(array, mid, high);
            left.fork();
            long rightResult = right.compute();
            long leftResult = left.join();
            return leftResult + rightResult;
        }
    }
}
