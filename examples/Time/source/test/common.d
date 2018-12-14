module test.common;


enum DO_TEST = `
    logInfo("BEGIN ----------------" ~ __FUNCTION__ ~ "--------------------");
    scope(success) logInfo("END   ----------------" ~ __FUNCTION__ ~ "----------OK----------");
    scope(failure) logError("END   ----------------" ~ __FUNCTION__ ~ "----------FAIL----------");`;