module hunt.system.WindowsHelper;

// dfmt off
version (Windows):
// dfmt on

import std.exception;
import std.windows.charset;

import core.sys.windows.wincon;
import core.sys.windows.winbase;
import core.sys.windows.windef;
import core.stdc.stdio;

struct ConsoleHelper {
    private __gshared HANDLE g_hout;
    enum defaultColor = FOREGROUND_GREEN | FOREGROUND_RED | FOREGROUND_BLUE;

    shared static this() {
        g_hout = GetStdHandle(STD_OUTPUT_HANDLE);
        resetColor();
    }

    static HANDLE getHandle() nothrow {
        return g_hout;
    }

    static void resetColor() nothrow {
        SetConsoleTextAttribute(g_hout, defaultColor);
    }

    static void setTextAttribute(ushort attr) nothrow {
        SetConsoleTextAttribute(g_hout, attr);
    }

    static void write(lazy string msg) nothrow {
        try {
            printf("%s\n", toMBSz(msg));
        } catch(Exception ex) {
            collectException( {
                setTextAttribute(FOREGROUND_RED);
                write(ex); 
                setTextAttribute(defaultColor);
            }());
        }
    }

    static void writeWithAttribute(lazy string msg, ushort attr = defaultColor) nothrow {
        setTextAttribute(attr);
        try {
            printf("%s\n", toMBSz(msg));
            if ((attr & defaultColor) != defaultColor)
                resetColor();
        } catch(Exception ex) {
            collectException( {
                setTextAttribute(FOREGROUND_RED);
                write(ex); 
                setTextAttribute(defaultColor);
            }());
        }
    }
}

