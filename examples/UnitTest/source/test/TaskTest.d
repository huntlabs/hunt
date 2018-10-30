module test.TaskTest;

// import std.stdio;
// import hunt.concurrent.parallelism;
// import std.array;
// import core.thread;
// import hunt.logging.ConsoleLogger;

// /* Prints the first letter of 'id' every half a second. It
//  * arbitrarily returns the value 1 to simulate functions that
//  * do calculations. This result will be used later in main. 
//  */
// int anOperation(string id, int duration) {
//     ConsoleLogger.tracef("%s will take %s seconds", id, duration);

//     foreach (i; 0 .. (duration * 2)) {
//         Thread.sleep(500.msecs); /* half a second */
//         if (taskSender !is null && taskSender.done) {
//             break; // cancelled
//         }
//         write(id.front);
//         stdout.flush();
//     }
//     writeln();

//     return 1;
// }

// __gshared AbstractTask* taskSender;

// int simpleOperation(string id, int duration) {
//     ConsoleLogger.tracef("%s will take %s seconds", id, duration);

//     foreach (i; 0 .. (duration * 2)) {
//         Thread.sleep(500.msecs); /* half a second */
//         write(id.front);
//         stdout.flush();
//     }
//     writeln();

//     return 1;
// }

// void testTask() {
//     /* Construct a task object that will execute
//      * anOperation(). The function parameters that are
//      * specified here are passed to the task function as its
//      * function parameters. */
//     auto theTask = task!anOperation("theTask", 10);
//     // Task!(anOperation, string, int)*
//     taskSender = &theTask.base;

//     // theTask.job();
//     theTask.then(delegate string(int r) {
//         ConsoleLogger.trace("success with: ", r);
//         return "success";
//     }, (err) { ConsoleLogger.warning("failed for: ", err.msg); });

//     ConsoleLogger.trace("main thread");

//     /* Start the task object */
//     // theTask.executeInNewThread();
//     taskPool.put(theTask);

//     /* As 'theTask' continues executing, 'anOperation()' is
//      * being called again, this time directly in main. */
//     immutable result = simpleOperation("main's call", 3);

//     // ConsoleLogger.trace("cancelling task");
//     // theTask.cancel();
//     // ConsoleLogger.trace("cancelled task");

//     /* At this point we are sure that the operation that has
//      * been started directly from within main has been
//      * completed, because it has been started by a regular
//      * function call, not as a task. */

//     /* On the other hand, it is not certain at this point
//      * whether 'theTask' has completed its operations
//      * yet. yieldForce() waits for the task to complete its
//      * operations; it returns only when the task has been
//      * completed. Its return value is the return value of
//      * the task function, i.e. anOperation(). */

//     try {
//         immutable taskResult = theTask.yieldForce();
//         writefln("\nAll finished; the result is: result=%d, taskResult=%d.", result, taskResult);
//     }
//     catch (TaskCancelledException t) {
//         writefln("\nAll finished with cancellation: %s.", t.msg);
//     }
//     catch (Throwable t) {
//         writefln("\nAll finished with exception: %s.", t.msg);
//     }
// }
