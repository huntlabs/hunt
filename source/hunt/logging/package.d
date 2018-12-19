module hunt.logging;

version(HUNT_DEBUG) {
    public import hunt.logging.ConsoleLogger;
} else {
    public import hunt.logging.Logger;
}

public import hunt.logging.helper;
