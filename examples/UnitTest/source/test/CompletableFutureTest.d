module test.CompletableFutureTest;

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
import hunt.Float;
import hunt.String;
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
*/
class CompletableFutureTest {

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
    //     CompletableFuture!String cf = completedFuture(new String("message"));
    //     assertTrue(cf.isDone());
    //     assertEquals(new String("message"), cf.getNow(null));
    // }

    // @Test
    // void runAsyncExample() {
    //     CompletableFuture!void cf = runAsync(() {
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
    //     CompletableFuture!String cf = completedFuture(new String("message"))
    //         .thenApply!(String)( delegate String (String s) {
    //             // assertFalse(Thread.getThis().isDaemon());
    //             trace(s.toString());
    //             return s.toUpperCase();
    //         });
    //     String value = cf.getNow(null);
    //     trace(value.toString());
    //     assertEquals(new String("MESSAGE"), value);
    // }

    // @Test
    // void thenApplyAsyncExample() {
    //     void doTest() {
    //         CompletableFuture!String cf = completedFuture(new String("message"))
    //             .thenApplyAsync!(String)(delegate String (String s) {
    //                 assertTrue(Thread.getThis().isDaemon());
    //                 randomSleep();
    //                 return s.toUpperCase();
    //             });
    //         assertNull(cf.getNow(null));
    //         assertEquals(new String("MESSAGE"), cf.join());
    //     }

    //     ThreadEx thread = new ThreadEx(&doTest);
    //     thread.start();
    // }

    // @Test
    // void thenApplyAsyncWithExecutorExample() {
        // initilizeExecutor();
    //     void doTest() {
    //         CompletableFuture!String cf = completedFuture(new String("message"))
    //             .thenApplyAsync!(String)(delegate String (String s) {
    //                 assertTrue(ThreadEx.currentThread().name().startsWith("custom-executor-"));
    //                 trace("isDaemon: ", Thread.getThis().isDaemon());
    //                 assertFalse(Thread.getThis().isDaemon());
    //                 randomSleep();
    //                 return s.toUpperCase();
    //             }, executor);
    //         assertNull(cf.getNow(null));
    //         assertEquals(new String("MESSAGE"), cf.join());
    //     }

    //     ThreadEx thread = new ThreadEx(&doTest);
    //     thread.start();
    // }

    // @Test
    // void thenAcceptExample() {
    //     StringBuilder result = new StringBuilder();
    //     completedFuture(new String("thenAccept message"))
    //             .thenAccept( (s) { 
    //                 trace(s.value);
    //                 result.append(s.value); 
    //             });
    //     assertTrue("Result was empty", result.length() > 0);
    // }


    // @Test
    // void thenAcceptAsyncExample() {
    //     void doTest() {
    //         StringBuilder result = new StringBuilder();
    //         CompletableFuture!void cf = completedFuture(new String("thenAcceptAsync message"))
    //                 .thenAcceptAsync( (s) { 
    //                     trace(s.value);
    //                     result.append(s.value); 
    //                 });
    //         cf.join();
    //         assertTrue("Result was empty", result.length() > 0);
    //     }

    //     ThreadEx thread = new ThreadEx(&doTest);
    //     thread.start();
    // }

    // @Test
    // void completeExceptionallyExample() {
    //     CompletableFuture!String cf = completedFuture(new String("message"))
    //         .thenApplyAsync!(String)(delegate String (String s) { 
    //                 trace(s.value);
    //                 return s.toUpperCase();
    //             },
    //             delayedExecutor(1.seconds));
    //     CompletableFuture!String exceptionHandler = cf.handle!(String)(delegate String (String s, Throwable th) { 
    //             return (th !is null) ? new String("message upon cancel") : new String(""); 
    //         });

    //     cf.completeExceptionally(new RuntimeException("completed exceptionally"));

    //     assertTrue("Was not completed exceptionally", cf.isCompletedExceptionally());
    //     try {
    //         cf.join();
    //         fail("Should have thrown an exception");
    //     } catch (CompletionException ex) { // just for testing
    //         assertEquals("completed exceptionally", ex.next().msg);
    //     }

    //     assertEquals("message upon cancel", exceptionHandler.join().value);
    // }

    @Test
    void cancelExample() {
        CompletableFuture!String cf = completedFuture(new String("message"))
            .thenApplyAsync!(String)(delegate String (String s) { 
                    trace(s.value);
                    return s.toUpperCase();
                },
                delayedExecutor(1.seconds));
        CompletableFuture!String cf2 = cf.exceptionally(throwable => new String("canceled message"));
        assertTrue("Was not canceled", cf.cancel(true));
        assertTrue("Was not completed exceptionally", cf.isCompletedExceptionally());
        assertEquals("canceled message", cf2.join().value);
    }

    // @Test
    // void applyToEitherExample() {
    //     void doTest() {
    //         String original = new String("Message");
    //         CompletableFuture!String cf1 = completedFuture(original)
    //                 .thenApplyAsync!(String)(s => delayedUpperCase(s));

    //         CompletableFuture!String cf2 = cf1.applyToEither!(String)(
    //                 completedFuture(original).thenApplyAsync!(String)(s => delayedLowerCase(s)),
    //                 s => new String(s.value ~ " from applyToEither"));

    //         assertTrue(cf2.join().value.endsWith(" from applyToEither"));
    //     }

    //     ThreadEx thread = new ThreadEx(&doTest);
    //     thread.start();
    // }


    // @Test
    // void acceptEitherExample() {
    //     String original = new String("Message");
    //     StringBuilder result = new StringBuilder();
    //     CompletableFuture!void cf = completedFuture(original)
    //             .thenApplyAsync!(String)(s => delayedUpperCase(s))
    //             .acceptEither(
    //                 completedFuture(original).thenApplyAsync!(String)( (s) { 
    //                     info("incoming: ", s.value);
    //                     return delayedLowerCase(s);
    //                 }),
    //                 (s) { 
    //                     info("incoming: ", s.value);
    //                     result.append(s.value).append("acceptEither"); 
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
    //     String original = new String("Message");
    //     StringBuilder result = new StringBuilder();
    //     completedFuture(original).thenApply!(String)( (s) {
    //             trace(s.toString());
    //             return s.toUpperCase();
    //         }).runAfterBoth!(String)(
    //             completedFuture(original).thenApply!(String)((s) {
    //                 trace(s.toString());
    //                 return s.toLowerCase();
    //             }),

    //             () {
    //                 result.append("done");
    //                 trace("appending done.");
    //             });
        
    //     trace("running done.");
    //     assertTrue("Result was empty", result.length() > 0);
    // }

    // @Test
    // void thenAcceptBothExample() {
    //     String original = new String("Message");
    //     StringBuilder result = new StringBuilder();
    //     completedFuture(original).thenApply!(String)( (s) {
    //             trace(s.toString());
    //             return s.toUpperCase();
    //         }).thenAcceptBoth!(String)(
    //             completedFuture(original).thenApply!(String)((s) {
    //                 trace(s.toString());
    //                 return s.toLowerCase();
    //             }),

    //             (s1, s2) { 
    //                 result.append(s1.value ~ s2.value); 
    //                 trace("appending done.");
    //             });
    //     trace("running done.");
    //     assertEquals("MESSAGEmessage", result.toString());
    // }

    // @Test
    // void thenCombineExample() {
    //     String original = new String("Message");
    //     CompletableFuture!String cf = completedFuture(original)
    //             .thenApply!(String)( (s) { 
    //                 trace(s.toString());
    //                 return delayedUpperCase(s); 
    //             }).thenCombine!(String, String)(completedFuture(original).thenApply!(String)( (s) { 
    //                     info("incoming: ", s.value);
    //                     return delayedLowerCase(s);
    //                 }),
    //                 delegate String (String s1, String s2) { 
    //                     trace("running...");
    //                     return new String(s1.value ~ s2.value); 
    //             });
    //     trace("running done.");
    //     assertEquals("MESSAGEmessage", cf.getNow(null).value);
    // }

    // @Test
    // void thenCombineAsyncExample() {
    //     String original = new String("Message");
    //     CompletableFuture!String cf = completedFuture(original)
    //             .thenApplyAsync!(String)( (s) { 
    //                 trace(s.toString());
    //                 return delayedUpperCase(s); 
    //             })
    //             .thenCombine!(String, String)(completedFuture(original).thenApplyAsync!(String)( (s) { 
    //                     info("incoming: ", s.value);
    //                     return delayedLowerCase(s);
    //                 }),
    //                 delegate String (String s1, String s2) { 
    //                     trace("running...");
    //                     return new String(s1.value ~ s2.value); 
    //             });
    //     void doTest() {
    //         trace("running done.");
    //         assertEquals("MESSAGEmessage", cf.join().value);
    //     }
        
    //     ThreadEx thread = new ThreadEx(&doTest);
    //     thread.start();
    // }

    // @Test
    // void thenComposeExample() {
    //     String original = new String("Message");
    //     CompletableFuture!String cf = completedFuture(original).thenApply!(String)( (s) { 
    //             trace(s.toString());
    //             return delayedUpperCase(s); 
    //         })
    //         .thenCompose!(String)((upper) { 
    //             CompletableFuture!String cf2 = completedFuture(original).thenApply!(String)( (s) { 
    //                 info("incoming: ", s.value);
    //                 return delayedLowerCase(s);
    //             }).thenApply!(String)( (s) { 
    //                 info("incoming: ", s.value);
    //                 return new String(upper.value ~ s.value); 
    //             });
    //             info("running: ");
    //             return cf2;
    //         });
    //     trace("running done.");    
    //     assertEquals("MESSAGEmessage", cf.join().value);
    // }

    // @Test
    // void anyOfExample() {
    //     StringBuilder result = new StringBuilder();
    //     string[] messages = ["a", "b", "c"];
    //     CompletableFuture!(String)[] futures = messages
    //             .map!((msg) {
    //                 trace(msg);
    //                 return completedFuture(new String(msg)).thenApply!String((s) { 
    //                     return delayedUpperCase(s); 
    //                 });
    //             }).array;

    //     anyOf!(String)(futures).whenComplete((res, th) {
    //         if(th is null) {
    //             trace(res);
    //             assertTrue(isUpperCase(cast(String) res));
    //             result.append((cast(String)res).value);
    //         }
    //     });

    //     trace("running done.");  
    //     assertTrue("Result was empty", result.length() > 0);
    // }    

    // @Test
    // void allOfExample() {
    //     StringBuilder result = new StringBuilder();
    //     string[] messages = ["a", "b", "c"];
    //     CompletableFuture!(String)[] futures = messages
    //             .map!((msg) {
    //                 trace(msg);
    //                 return completedFuture(new String(msg)).thenApply!String((s) { 
    //                     return delayedUpperCase(s); 
    //                 });
    //             }).array;

    //     allOf!(String)(futures).whenComplete((res, th) {
    //         if(th is null) {
    //             foreach(CompletableFuture!(String) cf; futures) {
    //                 String v = cf.getNow(null);
    //                 trace(v);
    //                 assertTrue(isUpperCase(v));
    //             }
    //             result.append("done");
    //         }
    //     });

    //     trace("running done.");  
    //     assertTrue("Result was empty", result.length() > 0);
    // }

    // @Test
    // void allOfAsyncExample() {
    //     StringBuilder result = new StringBuilder();
    //     string[] messages = ["a", "b", "c"];
    //     CompletableFuture!(String)[] futures = messages
    //             .map!((msg) {
    //                 trace(msg);
    //                 return completedFuture(new String(msg)).thenApplyAsync!String((s) { 
    //                     return delayedUpperCase(s); 
    //                 });
    //             }).array;

    //     CompletableFuture!void allOf = allOf!(String)(futures).whenComplete((res, th) {
    //         if(th is null) {
    //             foreach(CompletableFuture!(String) cf; futures) {
    //                 String v = cf.getNow(null);
    //                 trace(v);
    //                 assertTrue(isUpperCase(v));
    //             }
    //             result.append("done");
    //         }
    //     });

    //     void doTest() {
    //         allOf.join();
    //         trace("running done.");  
    //         assertTrue("Result was empty", result.length() > 0);
    //     }
        
    //     ThreadEx thread = new ThreadEx(&doTest);
    //     thread.start();
    // }

    private static String delayedUpperCase(String s) {
        randomSleep();
        return s.toUpperCase();
    }

    private static String delayedLowerCase(String s) {
        randomSleep();
        return s.toLowerCase();
    }


    private static bool isUpperCase(String s) {
        string str = s.value;
        for (size_t i = 0; i < s.length; i++) {
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
            Thread.sleep(r.msecs);
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


class RealLifeCompletableFutureExample {

    void testMain() {
        
        MonoTime start = MonoTime.currTime();

        CompletableFuture!(List!Car) cf = cars().thenCompose!(List!Car)( (cs) {
            CompletableFuture!(Car)[] updatedCars = cs.toArray()
                .map!( (car) {
                    return rating(car.manufacturerId).thenApply!(Car)( (r) {
                        trace(r);
                        car.setRating(r.value());
                        return car;
                    });
                }).array;

            CompletableFuture!void done = allOf!(Car)(updatedCars);

            return done.thenApply!(List!Car)(() {

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

    static CompletableFuture!Float rating(int manufacturer) {
        return supplyAsync!Float(() {
            try {
                simulateDelay();
            } catch (InterruptedException e) {
                ThreadEx.currentThread().interrupt();
                throw new RuntimeException(e);
            }
            switch (manufacturer) {
            case 2:
                return new Float(4f);
            case 3:
                return new Float(4.1f);
            case 7:
                return new Float(4.2f);
            default:
                return new Float(5f);
            }
        }).exceptionally(th => new Float(-1f));
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