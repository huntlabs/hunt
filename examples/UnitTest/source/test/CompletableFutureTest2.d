module test.CompletableFutureTest2;

import hunt.concurrency.atomic;
import hunt.concurrency.thread;
import hunt.concurrency.CompletableFuture;
import hunt.concurrency.Executors;
import hunt.concurrency.ExecutorService;
import hunt.concurrency.Exceptions;
import hunt.concurrency.ThreadFactory;

import hunt.Assert;
import hunt.collection.ArrayList;
import hunt.collection.List;
import hunt.Exceptions;
import hunt.Functions;
import hunt.logging.ConsoleLogger;

import hunt.text.StringBuilder;
import hunt.util.Common;
import hunt.util.DateTime;
import hunt.util.UnitTest;

import core.atomic;
import core.thread;
import core.time;

import std.algorithm;
import std.array;
import std.ascii;
import std.conv;
import std.random;
import std.string;


/**
http://www.importnew.com/28319.html
https://mahmoudanouti.wordpress.com/2018/01/26/20-examples-of-using-javas-completablefuture/
https://github.com/manouti/completablefuture-examples
https://colobu.com/2018/03/12/20-Examples-of-Using-Java%E2%80%99s-CompletableFuture/
*/
class CompletableFutureTest2 {

    __gshared ExecutorService executor;

    void initilizeExecutor() {
            executor = Executors.newFixedThreadPool(3, new class ThreadFactory {
            int count = 1;

            ThreadEx newThread(Runnable runnable) {
                count++;
                return new ThreadEx(runnable, "custom-executor-" ~ count.to!string());
            }
        });
    }


    // @Test
    // void completedFutureExample() {
    //     CompletableFuture!string cf = completedFuture("message");
    //     assertTrue(cf.isDone());
    //     assertEquals("message", cf.getNow(null));
    // }

    // @Test
    // void runAsyncExample() {
    //     CompletableFuture!Void cf = runAsync(() {
    //         info("running...");
    //         assertTrue(Thread.getThis().isDaemon());
    //         randomSleep();
    //     });
    //     assertFalse(cf.isDone());
    //     sleepEnough();
    //     assertTrue(cf.isDone());
    // }

    // @Test
    // void thenApplyExample() {
    //     CompletableFuture!string cf = completedFuture("message")
    //         .thenApply!(string)( (s) {
    //             // assertFalse(Thread.getThis().isDaemon());
    //             trace(s);
    //             return s.toUpper();
    //         });
    //     string value = cf.getNow(null);
    //     trace(value);
    //     assertEquals("MESSAGE", value);
    // }

    // @Test
    // void thenApplyAsyncExample() {
    //     CompletableFuture!string cf = completedFuture("message")
    //         .thenApplyAsync!(string)((s) {
    //             assertTrue(Thread.getThis().isDaemon());
    //             randomSleep();
    //             return s.toUpper();
    //         });
    //     assertNull(cf.getNow(null));

    //     // void doTest() {
    //         assertEquals("MESSAGE", cf.join());
    //     // }

    //     // ThreadEx thread = new ThreadEx(&doTest);
    //     // thread.start();
    // }

    // @Test
    // void thenApplyAsyncWithExecutorExample() {
        // initilizeExecutor();
    //     CompletableFuture!string cf = completedFuture("message")
    //         .thenApplyAsync!(string)((s) {
    //             assertTrue(ThreadEx.currentThread().name().startsWith("custom-executor-"));
    //             trace("isDaemon: ", Thread.getThis().isDaemon());
    //             assertFalse(Thread.getThis().isDaemon());
    //             randomSleep();
    //             return s.toUpper();
    //         }, executor);

    //     assertNull(cf.getNow(null));

    //     void doTest() {
    //         assertEquals("MESSAGE", cf.join());
    //     }

    //     ThreadEx thread = new ThreadEx(&doTest);
    //     thread.start();
    // }

    // @Test
    // void thenAcceptExample() {
    //     StringBuilder result = new StringBuilder();
    //     completedFuture("thenAccept message")
    //             .thenAccept( (s) { 
    //                 trace(s);
    //                 result.append(s); 
    //             });

    //     assertTrue("Result was empty", result.length() > 0);
    // }

    // @Test
    // void thenAcceptAsyncExample() {
    //     void doTest() {
    //         StringBuilder result = new StringBuilder();
    //         CompletableFuture!Void cf = completedFuture("thenAcceptAsync message")
    //                 .thenAcceptAsync( (s) { 
    //                     trace(s);
    //                     result.append(s); 
    //                 });
                    
    //         cf.join();
    //         info("result is: ", result.toString());
    //         assertTrue("Result was empty", result.length() > 0);
    //     }

    //     ThreadEx thread = new ThreadEx(&doTest);
    //     thread.start();
    // }

    // @Test
    // void completeExceptionallyExample() {
    //     CompletableFuture!string cf = completedFuture("message")
    //         .thenApplyAsync!(string)((s) { 
    //                 trace(s);
    //                 return s.toUpper();
    //             },
    //             delayedExecutor(1.seconds));
    //     CompletableFuture!string exceptionHandler = cf.handle!(string)((s, th) { 
    //             return (th !is null) ? "message upon cancel" : ""; 
    //         });

    //     cf.completeExceptionally(new RuntimeException("completed exceptionally"));

    //     assertTrue("Was not completed exceptionally", cf.isCompletedExceptionally());

    //     try {
    //         cf.join();
    //         fail("Should have thrown an exception");
    //     } catch (CompletionException ex) { // just for testing
    //         assertEquals("completed exceptionally", ex.next().msg);
    //     }

    //     assertEquals("message upon cancel", exceptionHandler.join());
    // }

    // @Test
    // void cancelExample() {
    //     CompletableFuture!string cf = completedFuture("message")
    //         .thenApplyAsync!(string)((string s) { 
    //                 trace(s);
    //                 return s.toUpper();
    //             },
    //             delayedExecutor(1.seconds));
    //     CompletableFuture!string cf2 = cf.exceptionally(throwable => "canceled message");
    //     assertTrue("Was not canceled", cf.cancel(true));
    //     assertTrue("Was not completed exceptionally", cf.isCompletedExceptionally());
    //     assertEquals("canceled message", cf2.join());
    //     trace("test done");
    // }

    // @Test
    // void applyToEitherExample() {
    //     // void doTest() {
    //         string original = "Message";
    //         CompletableFuture!string cf1 = completedFuture(original)
    //                 .thenApplyAsync!(string)(s => delayedUpperCase(s));

    //         CompletableFuture!string cf2 = cf1.applyToEither!(string)(
    //                 completedFuture(original).thenApplyAsync!(string)(s => delayedLowerCase(s)),
    //                 s => (s ~ " from applyToEither"));

    //         assertTrue(cf2.join().endsWith(" from applyToEither"));trace("test done");
    //         trace("test done");
    //     // }

    //     // ThreadEx thread = new ThreadEx(&doTest);
    //     // thread.start();
    // }


    // @Test
    // void acceptEitherExample() {
    //     string original = "Message";
    //     StringBuilder result = new StringBuilder();
    //     CompletableFuture!Void cf = completedFuture(original)
    //             .thenApplyAsync!(string)(s => delayedUpperCase(s))
    //             .acceptEither(
    //                 completedFuture(original).thenApplyAsync!(string)( (s) { 
    //                     info("incoming: ", s);
    //                     return delayedLowerCase(s);
    //                 }),
    //                 (s) { 
    //                     info("incoming: ", s);
    //                     result.append(s).append("acceptEither"); 
    //                 }
    //             );

    //     void doTest() {
    //         info("waiting for the result...");
    //         cf.join();
    //         infof("done with: %s", result.toString());
    //         assertTrue("Result was empty", result.toString().endsWith("acceptEither"));
    //     }
        
    //     ThreadEx thread = new ThreadEx(&doTest);
    //     thread.start();
    // }

    // @Test
    // void runAfterBothExample() {
    //     string original = "Message";
    //     StringBuilder result = new StringBuilder();
    //     completedFuture(original).thenApply!(string)( (s) {
    //             trace(s);
    //             return s.toUpper();
    //         }).runAfterBoth!(string)(
    //             completedFuture(original).thenApply!(string)((s) {
    //                 trace(s);
    //                 return s.toLower();
    //             }),

    //             () {
    //                 result.append("done");
    //                 trace("appending done.");
    //             });
        
    //     tracef("running done. The result is: %s", result.toString());
    //     assertTrue("Result was empty", result.length() > 0);
    // }

    // @Test
    // void thenAcceptBothExample() {
    //     string original = "Message";
    //     StringBuilder result = new StringBuilder();
    //     completedFuture(original).thenApply!(string)( (s) {
    //             trace(s);
    //             return s.toUpper();
    //         }).thenAcceptBoth!(string)(
    //             completedFuture(original).thenApply!(string)((s) {
    //                 trace(s);
    //                 return s.toLower();
    //             }),

    //             (s1, s2) { 
    //                 result.append(s1 ~ s2); 
    //                 trace("appending done.");
    //             });
    //     trace("running done.");
    //     assertEquals("MESSAGEmessage", result.toString());
    // }

    // @Test
    // void thenCombineExample() {
    //     string original = "Message";
    //     CompletableFuture!string cf = completedFuture(original)
    //             .thenApply!(string)( (s) { 
    //                 trace(s);
    //                 return delayedUpperCase(s); 
    //             }).thenCombine!(string, string)(completedFuture(original).thenApply!(string)( (s) { 
    //                     info("incoming: ", s);
    //                     return delayedLowerCase(s);
    //                 }),
    //                 (string s1, string s2) { 
    //                     trace("running...");
    //                     return (s1 ~ s2); 
    //             });
    //     tracef("running done. The result is: %s", result.toString());
    //     assertEquals("MESSAGEmessage", cf.getNow(null));
    // }

    // @Test
    // void thenCombineAsyncExample() {
    //     string original = "Message";
    //     CompletableFuture!string cf = completedFuture(original)
    //             .thenApplyAsync!(string)( (s) { 
    //                 trace(s);
    //                 return delayedUpperCase(s); 
    //             })
    //             .thenCombine!(string, string)(completedFuture(original).thenApplyAsync!(string)( (s) { 
    //                     info("incoming: ", s);
    //                     return delayedLowerCase(s);
    //                 }),
    //                 (string s1, string s2) { 
    //                     trace("running...");
    //                     return (s1 ~ s2); 
    //             });

    //     void doTest() {
    //         string v = cf.join();
    //         tracef("running done. The result is: %s", v);
    //         assertEquals("MESSAGEmessage", v);
    //     }
        
    //     ThreadEx thread = new ThreadEx(&doTest);
    //     thread.start();
    // }

    // @Test
    // void thenComposeExample() {
    //     string original = "Message";
    //     CompletableFuture!string cf = completedFuture(original).thenApply!(string)( (s) { 
    //             trace(s);
    //             return delayedUpperCase(s); 
    //         })
    //         .thenCompose!(string)((upper) { 
    //             CompletableFuture!string cf2 = completedFuture(original).thenApply!(string)( (s) { 
    //                 info("incoming: ", s);
    //                 return delayedLowerCase(s);
    //             }).thenApply!(string)( (s) { 
    //                 info("incoming: ", s);
    //                 return (upper ~ s); 
    //             });
    //             info("running: ");
    //             return cf2;
    //         });
    //     trace("running done.");    
    //     assertEquals("MESSAGEmessage", cf.join());
    // }

    // @Test
    // void anyOfExample() {
    //     StringBuilder result = new StringBuilder();
    //     string[] messages = ["a", "b", "c"];
    //     CompletableFuture!(string)[] futures = messages
    //             .map!((msg) {
    //                 trace(msg);
    //                 return completedFuture((msg)).thenApply!string((s) { 
    //                     return delayedUpperCase(s); 
    //                 });
    //             }).array;

    //     anyOf!(string)(futures).whenComplete((res, th) {
    //         if(th is null) {
    //             trace(res);
    //             assertTrue(isUpperCase(res));
    //             result.append(res);
    //         }
    //     });

    //     infof("running done. The result is: %s", result.toString());
    //     assertTrue("Result was empty", result.length() > 0);
    // }    

    // @Test
    // void allOfExample() {
    //     StringBuilder result = new StringBuilder();
    //     string[] messages = ["a", "b", "c"];
    //     CompletableFuture!(string)[] futures = messages
    //             .map!((msg) {
    //                 trace(msg);
    //                 return completedFuture((msg)).thenApply!string((s) { 
    //                     return delayedUpperCase(s); 
    //                 });
    //             }).array;

    //     allOf!(string)(futures).whenComplete((res, th) {
    //         if(th is null) {
    //             foreach(CompletableFuture!(string) cf; futures) {
    //                 string v = cf.getNow(null);
    //                 trace(v);
    //                 assertTrue(isUpperCase(v));
    //             }
    //             result.append("done");
    //         }
    //     });

    //     infof("running done. The result is: %s", result.toString());
    //     assertTrue("Result was empty", result.length() > 0);
    // }

    @Test
    void allOfAsyncExample() {
        StringBuilder result = new StringBuilder();
        string[] messages = ["a", "b", "c"];
        CompletableFuture!(string)[] futures = messages
                .map!((msg) {
                    trace(msg);
                    return completedFuture((msg)).thenApplyAsync!string((s) { 
                        return delayedUpperCase(s); 
                    });
                }).array;

        CompletableFuture!Void allOf = allOf!(string)(futures).whenComplete((res, th) {
            if(th is null) {
                foreach(CompletableFuture!(string) cf; futures) {
                    string v = cf.getNow(null);
                    trace(v);
                    assertTrue(isUpperCase(v));
                }
                result.append("done");
            }
        });

        // void doTest() {
            allOf.join();
            infof("running done. The result is: %s", result.toString());
            assertTrue("Result was empty", result.length() > 0);
        // }
        
        // ThreadEx thread = new ThreadEx(&doTest);
        // thread.start();
    }

    private static string delayedUpperCase(string s) {
        randomSleep();
        return s.toUpper();
    }

    private static string delayedLowerCase(string s) {
        randomSleep();
        return s.toLower();
    }


    private static bool isUpperCase(string str) {
        for (size_t i = 0; i < str.length; i++) {
            if (isLower(str[i])) {
                return false;
            }
        }
        return true;
    }

    private static void randomSleep() {
        try {
            int r = uniform(0, 1000);
            tracef("sleeping %d msecs", r);
            Thread.sleep((r*10).msecs);
            trace("waked up now");
        } catch (InterruptedException e) {
            // ...
            warning(e.toString());
        }
    }

    private static void sleepEnough() {
        try {
            trace("sleeping 2 secondes");
            Thread.sleep(2.seconds);
            trace("waked up now");
        } catch (InterruptedException e) {
            // ...
        }
    }
}



class Car {
	int id;
	int manufacturerId;
	string model;
	int year;
	float rating;

	this(int id, int manufacturerId, string model, int year) {
		this.id = id;
		this.manufacturerId = manufacturerId;
		this.model = model;
		this.year = year;
	}

	void setRating(float rating) {
		this.rating = rating;
	}

	override
	string toString() {
		return "Car (id=" ~ id.to!string() ~ ", manufacturerId=" 
            ~ manufacturerId.to!string() ~ ", model=" ~ model 
            ~ ", year=" ~ year.to!string()
				~ ", rating=" ~ rating.to!string();
	}
}


class RealLifeCompletableFutureExample2 {

    void testMain() {
        
        MonoTime start = MonoTime.currTime();

        CompletableFuture!(List!Car) cf = cars().thenCompose!(List!Car)( (cs) {
            CompletableFuture!(Car)[] updatedCars = cs.toArray()
                .map!( (car) {
                    return rating(car.manufacturerId).thenApply!(Car)( (r) {
                        trace(r);
                        car.setRating(r);
                        return car;
                    });
                }).array;

            CompletableFuture!Void done = allOf!(Car)(updatedCars);

            return done.thenApply!(List!Car)((v) {

                    List!Car carList = new ArrayList!Car();
                    Car[] cs = updatedCars.map!((f) { 
                            return f; 
                        }).map!((f) { return f.join(); }).array;
                    
                    foreach(Car c; cs) {
                        carList.add(c);
                    }

                    return carList;
                });

        }).whenComplete((cars, th) {
            if (th is null) {
                foreach(Car c; cars) {
                    trace(c.toString());
                }
            } else {
                throw new RuntimeException(th);
            }
        });


        void doTest() {
            cf.join();
            MonoTime end = MonoTime.currTime();
            infof("Took %s", end - start);
        }
        
        ThreadEx thread = new ThreadEx(&doTest);
        thread.start(); 
    }

    static CompletableFuture!float rating(int manufacturer) {
        return supplyAsync!float(() {
            try {
                simulateDelay();
            } catch (InterruptedException e) {
                ThreadEx.currentThread().interrupt();
                throw new RuntimeException(e);
            }
            switch (manufacturer) {
            case 2:
                return 4f;
            case 3:
                return 4.1f;
            case 7:
                return 4.2f;
            default:
                return 5f;
            }
        }).exceptionally(th => -1f);
    }

    static CompletableFuture!(List!Car) cars() {
        List!Car carList = new ArrayList!Car();
        carList.add(new Car(1, 3, "Fiesta", 2017));
        carList.add(new Car(2, 7, "Camry", 2014));
        carList.add(new Car(3, 2, "M2", 2008));
        return supplyAsync!(List!Car)(() => carList);
    }

    private static void simulateDelay() {
        Thread.sleep(5.seconds);
    }
}