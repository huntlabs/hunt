module hunt.time.Constants;

/**
*/
struct TimeConstant {
    
    /**
     * Hours per day.
     */
    enum int HOURS_PER_DAY = 24;
    /**
     * Minutes per hour.
     */
    enum int MINUTES_PER_HOUR = 60;
    /**
     * Minutes per day.
     */
    enum int MINUTES_PER_DAY = MINUTES_PER_HOUR * HOURS_PER_DAY;
    /**
     * Seconds per minute.
     */
    enum int SECONDS_PER_MINUTE = 60;
    /**
     * Seconds per hour.
     */
    enum int SECONDS_PER_HOUR = SECONDS_PER_MINUTE * MINUTES_PER_HOUR;
    /**
     * Seconds per day.
     */
    enum int SECONDS_PER_DAY = SECONDS_PER_HOUR * HOURS_PER_DAY;
    /**
     * Milliseconds per day.
     */
    enum long MILLIS_PER_DAY = SECONDS_PER_DAY * 1000L;
    /**
     * Microseconds per day.
     */
    enum long MICROS_PER_DAY = SECONDS_PER_DAY * 1000_000L;
    /**
     * Nanos per millisecond.
     */
    enum long NANOS_PER_MILLI = 1000_000L;
    /**
     * Nanos per second.
     */
    enum long NANOS_PER_SECOND =  1000_000_000L;
    /**
     * Nanos per minute.
     */
    enum long NANOS_PER_MINUTE = NANOS_PER_SECOND * SECONDS_PER_MINUTE;
    /**
     * Nanos per hour.
     */
    enum long NANOS_PER_HOUR = NANOS_PER_MINUTE * MINUTES_PER_HOUR;
    /**
     * Nanos per day.
     */
    enum long NANOS_PER_DAY = NANOS_PER_HOUR * HOURS_PER_DAY;
}


/**
*/
struct MonthCode {
    /**
     * The month of January with 31 days.
     * This has the numeric value of {@code 1}.
     */
    enum JANUARY = 1;
    /**
     * The month of February with 28 days, or 29 _in a leap year.
     * This has the numeric value of {@code 2}.
     */
    enum FEBRUARY = 2;
    /**
     * The month of March with 31 days.
     * This has the numeric value of {@code 3}.
     */
    enum MARCH = 3;
    /**
     * The month of April with 30 days.
     * This has the numeric value of {@code 4}.
     */
    enum APRIL = 4;
    /**
     * The month of May with 31 days.
     * This has the numeric value of {@code 5}.
     */
    enum MAY = 5;
    /**
     * The month of June with 30 days.
     * This has the numeric value of {@code 6}.
     */
    enum JUNE = 6;
    /**
     * The month of July with 31 days.
     * This has the numeric value of {@code 7}.
     */
    enum JULY = 7;
    /**
     * The month of August with 31 days.
     * This has the numeric value of {@code 8}.
     */
    enum AUGUST = 8;
    /**
     * The month of September with 30 days.
     * This has the numeric value of {@code 9}.
     */
    enum SEPTEMBER = 9;
    /**
     * The month of October with 31 days.
     * This has the numeric value of {@code 10}.
     */
    enum OCTOBER = 10;
    /**
     * The month of November with 30 days.
     * This has the numeric value of {@code 11}.
     */
    enum NOVEMBER = 11;
    /**
     * The month of December with 31 days.
     * This has the numeric value of {@code 12}.
     */
    enum DECEMBER = 12;
}

/**
*/
struct MonthName {
    /**
     * The month of January with 31 days.
     * This has the numeric value of {@code 1}.
     */
    enum JANUARY = "JANUARY";
    /**
     * The month of February with 28 days, or 29 _in a leap year.
     * This has the numeric value of {@code 2}.
     */
    enum FEBRUARY = "FEBRUARY";
    /**
     * The month of March with 31 days.
     * This has the numeric value of {@code 3}.
     */
    enum MARCH = "MARCH";
    /**
     * The month of April with 30 days.
     * This has the numeric value of {@code 4}.
     */
    enum APRIL = "APRIL";
    /**
     * The month of May with 31 days.
     * This has the numeric value of {@code 5}.
     */
    enum MAY = "MAY";
    /**
     * The month of June with 30 days.
     * This has the numeric value of {@code 6}.
     */
    enum JUNE = "JUNE";
    /**
     * The month of July with 31 days.
     * This has the numeric value of {@code 7}.
     */
    enum JULY = "JULY";
    /**
     * The month of August with 31 days.
     * This has the numeric value of {@code 8}.
     */
    enum AUGUST = "AUGUST";
    /**
     * The month of September with 30 days.
     * This has the numeric value of {@code 9}.
     */
    enum SEPTEMBER = "SEPTEMBER";
    /**
     * The month of October with 31 days.
     * This has the numeric value of {@code 10}.
     */
    enum OCTOBER = "OCTOBER";
    /**
     * The month of November with 30 days.
     * This has the numeric value of {@code 11}.
     */
    enum NOVEMBER = "NOVEMBER";
    /**
     * The month of December with 31 days.
     * This has the numeric value of {@code 12}.
     */
    enum DECEMBER = "DECEMBER";
}