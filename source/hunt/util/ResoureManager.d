module hunt.util.ResoureManager;

import hunt.logging.ConsoleLogger;
import hunt.util.Closeable;

import core.memory;

private Closeable[] _closeableObjects;

void registerResoure(Closeable res) {
    assert(res !is null);
    _closeableObjects ~= res;
}

void collectResoure() nothrow {

    foreach (obj; _closeableObjects) {
        try {
            obj.close();
        } catch (Throwable t) {
            warning(t);
        }
    }
    _closeableObjects = null;

    GC.collect();
    GC.minimize();
}
