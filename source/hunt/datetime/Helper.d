module hunt.datetime.Helper;

import hunt.datetime.format;

import core.atomic;
import core.thread : Thread;
import std.datetime;
import std.format : formattedWrite;
import std.string;

enum TimeUnit : string {
    Year = "years",
    Month = "months",
    Week = "weeks",
    Day = "days",
    Hour = "hours",
    Second = "seconds",
    Millisecond = "msecs",
    Microsecond = "usecs",
    HectoNanosecond = "hnsecs",
    Nanosecond = "nsecs"
}

// return unix timestamp
long time() {
    return DateTimeHelper.timestamp;
}

// return formated time string from timestamp
string date(string format, long timestamp = 0) {
    import std.datetime : SysTime;
    import std.conv : to;

    long newTimestamp = timestamp > 0 ? timestamp : time();

    string timeString;

    SysTime st = SysTime.fromUnixTime(newTimestamp);

    // format to ubyte
    foreach (c; format) {
        switch (c) {
        case 'Y':
            timeString ~= st.year.to!string;
            break;
        case 'y':
            timeString ~= (st.year.to!string)[2 .. $];
            break;
        case 'm':
            short month = monthToShort(st.month);
            timeString ~= month < 10 ? "0" ~ month.to!string : month.to!string;
            break;
        case 'd':
            timeString ~= st.day < 10 ? "0" ~ st.day.to!string : st.day.to!string;
            break;
        case 'H':
            timeString ~= st.hour < 10 ? "0" ~ st.hour.to!string : st.hour.to!string;
            break;
        case 'i':
            timeString ~= st.minute < 10 ? "0" ~ st.minute.to!string : st.minute.to!string;
            break;
        case 's':
            timeString ~= st.second < 10 ? "0" ~ st.second.to!string : st.second.to!string;
            break;
        default:
            timeString ~= c;
            break;
        }
    }

    return timeString;
}

/**
*/
class DateTimeHelper {
    static long currentTimeMillis() {
        return convert!(TimeUnit.HectoNanosecond, TimeUnit.Millisecond)(Clock.currStdTime);
    }

    static string getTimeAsGMT() {
        return cast(string)*timingValue;
    }

    alias getDateAsGMT = getTimeAsGMT;

    static shared long timestamp;

    static void startClock() {
        if (cas(&_isClockRunning, false, true)) {
            dateThread.start();
        }
    }

    static void stopClock() {
        atomicStore(_isClockRunning, false);
    }

    private static shared const(char)[]* timingValue;
    private __gshared Thread dateThread;
    private static shared bool _isClockRunning = false;

    shared static this() {
        import std.array;

        Appender!(char[])[2] bufs;
        const(char)[][2] targets;

        void tick(size_t index) {
            import core.stdc.time : time;

            bufs[index].clear();
            timestamp = time(null);
            auto date = Clock.currTime!(ClockType.coarse)(UTC());
            size_t sz = updateDate(bufs[index], date);
            targets[index] = bufs[index].data;
            atomicStore(timingValue, cast(shared)&targets[index]);
        }

        tick(0);

        dateThread = new Thread({
            size_t cur = 1;
            while (_isClockRunning) {
                tick(cur);
                cur = 1 - cur;
                Thread.sleep(1.seconds);
            }
        });

        dateThread.isDaemon = true;
        // FIXME: Needing refactor or cleanup -@zxp at 12/30/2018, 10:10:09 AM
        // 
        // It's not a good idea to launch another thread in shared static this().
        // https://issues.dlang.org/show_bug.cgi?id=19492
        // startClock();
    }

    shared static ~this() {
        if (cas(&_isClockRunning, true, false)) {
            dateThread.join();
        }
    }

    private static size_t updateDate(Output, D)(ref Output sink, D date) {
        return formattedWrite(sink, "%s, %02s %s %04s %02s:%02s:%02s GMT", dayAsString(date.dayOfWeek),
                date.day, monthAsString(date.month), date.year, date.hour,
                date.minute, date.second);
    }

    static string getSystemTimeZoneId() {
        version (Posix) {
            return cast(string) fromStringz(findTZ_md(""));
        } else version (Windows) {
            return cast(string) fromStringz(findTZ_md(""));
        } else {
            // return "Asia/Shanghai";
            return "";
        }
    }
}

version (Posix) {
    import core.sys.posix.stdlib;
    import core.sys.posix.unistd;
    import core.sys.posix.fcntl;
    import core.stdc.errno;
    import core.sys.linux.unistd;
    import core.sys.posix.sys.stat;
    import core.sys.posix.dirent;
    import std.file;
    import core.stdc.string;
    import std.stdio;

    static const char* ETC_TIMEZONE_FILE = "/etc/timezone";
    static const char* ZONEINFO_DIR = "/usr/share/zoneinfo";
    static const char* DEFAULT_ZONEINFO_FILE = "/etc/localtime";
    enum int PATH_MAX = 1024;

    string RESTARTABLE(string _cmd, string _result) {
        string str;
        str ~= `do { 
                do { `;
        str ~= _result ~ "= " ~ _cmd ~ `; 
                } while((` ~ _result
            ~ `== -1) && (errno == EINTR)); 
            } while(0);`;
        return str;
    }

    static char* getPlatformTimeZoneID() {
        /* struct */
        stat_t statbuf;
        char* tz = null;
        FILE* fp;
        int fd;
        char* buf;
        size_t size;
        int res;

        /* #if defined(__linux__) */ /*
     * Try reading the /etc/timezone file for Debian distros. There's
     * no spec of the file format available. This parsing assumes that
     * there's one line of an Olson tzid followed by a '\n', no
     * leading or trailing spaces, no comments.
     */
        if ((fp = fopen(ETC_TIMEZONE_FILE, "r")) !is null) {
            char[256] line;

            if (fgets(line.ptr, (line.sizeof), fp) !is null) {
                char* p = strchr(line.ptr, '\n');
                if (p !is null) {
                    *p = '\0';
                }
                if (strlen(line.ptr) > 0) {
                    tz = strdup(line.ptr);
                }
            }
            /* (void) */
            fclose(fp);
            if (tz !is null) {
                return tz;
            }
        }
        /* #endif */ /* defined(__linux__) */

        /*
     * Next, try /etc/localtime to find the zone ID.
     */
        mixin(RESTARTABLE("lstat(DEFAULT_ZONEINFO_FILE, &statbuf)", "res"));
        if (res == -1) {
            return null;
        }

        /*
     * If it's a symlink, get the link name and its zone ID part. (The
     * older versions of timeconfig created a symlink as described in
     * the Red Hat man page. It was changed in 1999 to create a copy
     * of a zoneinfo file. It's no longer possible to get the zone ID
     * from /etc/localtime.)
     */
        if (S_ISLNK(statbuf.st_mode)) {
            char[PATH_MAX + 1] linkbuf;
            int len;

            if ((len = cast(int) readlink(DEFAULT_ZONEINFO_FILE, linkbuf.ptr,
                    cast(int)(linkbuf.sizeof) - 1)) == -1) {
                // /* jio_fprintf */writefln(stderr, cast(const char * ) "can't get a symlink of %s\n",
                //         DEFAULT_ZONEINFO_FILE);
                return null;
            }
            linkbuf[len] = '\0';
            tz = getZoneName(linkbuf.ptr);
            if (tz !is null) {
                tz = strdup(tz);
                return tz;
            }
        }

        /*
     * If it's a regular file, we need to find out the same zoneinfo file
     * that has been copied as /etc/localtime.
     * If initial symbolic link resolution failed, we should treat target
     * file as a regular file.
     */
        mixin(RESTARTABLE(`open(DEFAULT_ZONEINFO_FILE, O_RDONLY)`, "fd"));
        if (fd == -1) {
            return null;
        }

        mixin(RESTARTABLE(`fstat(fd, &statbuf)`, "res"));
        if (res == -1) {
            /* (void) */
            close(fd);
            return null;
        }
        size = cast(size_t) statbuf.st_size;
        buf = cast(char*) malloc(size);
        if (buf is null) {
            /* (void) */
            close(fd);
            return null;
        }

        mixin(RESTARTABLE(`cast(int)read(fd, buf, size)`, "res"));
        if (res != cast(int) size) {
            /* (void) */
            close(fd);
            free(cast(void*) buf);
            return null;
        }
        /* (void) */
        close(fd);

        tz = findZoneinfoFile(buf, size, ZONEINFO_DIR);
        free(cast(void*) buf);
        return tz;
    }

    char* findTZ_md(const char* java_home_dir) {
        char* tz;
        char* javatz = null;
        char* freetz = null;

        tz = getenv("TZ");

        if (tz is null || *tz == '\0') {
            tz = getPlatformTimeZoneID();
            freetz = tz;
        }
        // writeln("tz : ", tz, " freeTz : ", freetz);
        if (tz !is null) {
            /* Ignore preceding ':' */
            if (*tz == ':') {
                tz++;
            }
            // #if defined(__linux__)
            /* Ignore "posix/" prefix on Linux. */
            if (strncmp(tz, "posix/", 6) == 0) {
                tz += 6;
            }
            // #endif

            // #if defined(_AIX)
            //         /* On AIX do the platform to Java mapping. */
            //         javatz = mapPlatformToJavaTimezone(java_home_dir, tz);
            //         if (freetz !is  null) {
            //             free((void *) freetz);
            //         }
            // #else
            // #if defined(__solaris__)
            //         /* Solaris might use localtime, so handle it here. */
            //         if (strcmp(tz, "localtime") == 0) {
            //             javatz = getSolarisDefaultZoneID();
            //             if (freetz !is  null) {
            //                 free((void *) freetz);
            //             }
            //         } else
            // #endif
            if (freetz is null) {
                /* strdup if we are still working on getenv result. */
                javatz = strdup(tz);
            } else if (freetz != tz) {
                /* strdup and free the old buffer, if we moved the pointer. */
                javatz = strdup(tz);
                free(cast(void*) freetz);
            } else {
                /* we are good if we already work on a freshly allocated buffer. */
                javatz = tz;
            }
            // #endif
        }

        return javatz;
    }

    static char* getZoneName(char* str) {
        static const char* zidir = "zoneinfo/";

        char* pos = cast(char*) strstr(cast(const char*) str, zidir);
        if (pos is null) {
            return null;
        }
        return pos + strlen(zidir);
    }

    static char* getPathName(const char* dir, const char* name) {
        char* path;

        path = cast(char*) malloc(strlen(dir) + strlen(name) + 2);
        if (path is null) {
            return null;
        }
        return strcat(strcat(strcpy(path, dir), "/"), name);
    }

    static char* findZoneinfoFile(char* buf, size_t size, const char* dir) {
        DIR* dirp = null;
        /* struct */
        stat_t statbuf;
        /* struct */
        dirent* dp = null;
        char* pathname = null;
        int fd = -1;
        char* dbuf = null;
        char* tz = null;
        int res;

        dirp = opendir(dir);
        if (dirp is null) {
            return null;
        }

        while ((dp = readdir(dirp)) != null) {
            /*
         * Skip '.' and '..' (and possibly other .* files)
         */
            if (dp.d_name[0] == '.') {
                continue;
            }

            /*
         * Skip "ROC", "posixrules", and "localtime".
         */
            if ((strcmp(dp.d_name.ptr, "ROC") == 0) || (strcmp(dp.d_name.ptr,
                    "posixrules") == 0) || (strcmp(dp.d_name.ptr, "localtime") == 0)) {
                continue;
            }

            pathname = getPathName(dir, dp.d_name.ptr);
            if (pathname is null) {
                break;
            }
            mixin(RESTARTABLE(`stat(pathname, &statbuf)`, "res"));
            if (res == -1) {
                break;
            }

            if (S_ISDIR(statbuf.st_mode)) {
                tz = findZoneinfoFile(buf, size, pathname);
                if (tz != null) {
                    break;
                }
            } else if (S_ISREG(statbuf.st_mode) && cast(size_t) statbuf.st_size == size) {
                dbuf = cast(char*) malloc(size);
                if (dbuf is null) {
                    break;
                }
                mixin(RESTARTABLE(`open(pathname, O_RDONLY)`, "fd"));
                if (fd == -1) {
                    break;
                }
                mixin(RESTARTABLE(`cast(int)read(fd, dbuf, size)`, "res"));
                if (res != cast(ssize_t) size) {
                    break;
                }
                if (memcmp(buf, dbuf, size) == 0) {
                    tz = getZoneName(pathname);
                    if (tz != null) {
                        tz = strdup(tz);
                    }
                    break;
                }
                free(cast(void*) dbuf);
                dbuf = null;
                /* (void) */
                close(fd);
                fd = -1;
            }
            free(cast(void*) pathname);
            pathname = null;
        }

        if (dirp != null) {
            /* (void) */
            closedir(dirp);
        }
        if (pathname != null) {
            free(cast(void*) pathname);
        }
        if (fd != -1) {
            /* (void) */
            close(fd);
        }
        if (dbuf != null) {
            free(cast(void*) dbuf);
        }
        return tz;
    }
}

version (Windows) {
    import core.sys.windows.wtypes;
    import core.sys.windows.windows;
    import core.sys.windows.w32api;

    // import core.sys.windows.;
    import core.stdc.stdio;
    import core.stdc.stdlib;
    import core.stdc.string;
    import core.stdc.time;
    import core.stdc.wchar_;
    import core.sys.windows.winnls;
    import core.sys.windows.winbase;
    import std.string;

    enum int VALUE_UNKNOWN = 0;
    enum int VALUE_KEY = 1;
    enum int VALUE_MAPID = 2;
    enum int VALUE_GMTOFFSET = 3;

    enum int MAX_ZONE_CHAR = 256;
    enum int MAX_MAPID_LENGTH = 32;
    enum int MAX_REGION_LENGTH = 4;

    enum string NT_TZ_KEY = "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Time Zones";
    enum string WIN_TZ_KEY = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Time Zones";
    enum string WIN_CURRENT_TZ_KEY = "System\\CurrentControlSet\\Control\\TimeZoneInformation";

    struct TziValue {
        LONG bias;
        LONG stdBias;
        LONG dstBias;
        SYSTEMTIME stdDate;
        SYSTEMTIME dstDate;
    };

    /*
 * Registry key names
 */
    static string[] keyNames = [("StandardName"), ("StandardName"), ("Std"), ("Std")];

    /*
 * Indices to keyNames[]
 */
    enum STANDARD_NAME = 0;
    enum STD_NAME = 2;

    /*
 * Calls RegQueryValueEx() to get the value for the specified key. If
 * the platform is NT, 2000 or XP, it calls the Unicode
 * version. Otherwise, it calls the ANSI version and converts the
 * value to Unicode. In this case, it assumes that the current ANSI
 * Code Page is the same as the native platform code page (e.g., Code
 * Page 932 for the Japanese Windows systems.
 *
 * `keyIndex' is an index value to the keyNames in Unicode
 * (WCHAR). `keyIndex' + 1 points to its ANSI value.
 *
 * Returns the status value. ERROR_SUCCESS if succeeded, a
 * non-ERROR_SUCCESS value otherwise.
 */
    static LONG getValueInRegistry(HKEY hKey, int keyIndex, LPDWORD typePtr,
            LPBYTE buf, LPDWORD bufLengthPtr) {
        LONG ret;
        DWORD bufLength = *bufLengthPtr;
        char[MAX_ZONE_CHAR] val;
        DWORD valSize;
        int len;

        *typePtr = 0;
        ret = RegQueryValueExW(hKey, cast(WCHAR*) keyNames[keyIndex], null,
                typePtr, buf, bufLengthPtr);
        if (ret == ERROR_SUCCESS && *typePtr == REG_SZ) {
            return ret;
        }

        valSize = (val.sizeof);
        ret = RegQueryValueExA(hKey, cast(char*) keyNames[keyIndex + 1], null,
                typePtr, val.ptr, &valSize);
        if (ret != ERROR_SUCCESS) {
            return ret;
        }
        if (*typePtr != REG_SZ) {
            return ERROR_BADKEY;
        }

        len = MultiByteToWideChar(CP_ACP, MB_ERR_INVALID_CHARS,
                cast(LPCSTR) val, -1, cast(LPWSTR) buf, bufLength / (WCHAR.sizeof));
        if (len <= 0) {
            return ERROR_BADKEY;
        }
        return ERROR_SUCCESS;
    }

    /*
 * Produces custom name "GMT+hh:mm" from the given bias in buffer.
 */
    static void customZoneName(LONG bias, char* buffer) {
        LONG gmtOffset;
        int sign;

        if (bias > 0) {
            gmtOffset = bias;
            sign = -1;
        } else {
            gmtOffset = -bias;
            sign = 1;
        }
        if (gmtOffset != 0) {
            sprintf(buffer, "GMT%c%02d:%02d", ((sign >= 0) ? '+' : '-'),
                    gmtOffset / 60, gmtOffset % 60);
        } else {
            strcpy(buffer, "GMT");
        }
    }

    /*
 * Gets the current time zone entry in the "Time Zones" registry.
 */
    static int getWinTimeZone(char* winZoneName) {
        // DYNAMIC_TIME_ZONE_INFORMATION dtzi;
        DWORD timeType;
        DWORD bufSize;
        DWORD val;
        HANDLE hKey = null;
        LONG ret;
        ULONG valueType;

        /*
     * Get the dynamic time zone information so that time zone redirection
     * can be supported. (see JDK-7044727)
     */
        // timeType = GetDynamicTimeZoneInformation(&dtzi);
        // if (timeType == TIME_ZONE_ID_INVALID)
        // {
        //     goto err;
        // }

        /*
     * Make sure TimeZoneKeyName is available from the API call. If
     * DynamicDaylightTime is disabled, return a custom time zone name
     * based on the GMT offset. Otherwise, return the TimeZoneKeyName
     * value.
     */
        // if (dtzi.TimeZoneKeyName[0] != 0)
        // {
        //     if (dtzi.DynamicDaylightTimeDisabled)
        //     {
        //         customZoneName(dtzi.Bias, winZoneName);
        //         return VALUE_GMTOFFSET;
        //     }
        //     wcstombs(winZoneName, dtzi.TimeZoneKeyName, MAX_ZONE_CHAR);
        //     return VALUE_KEY;
        // }

        /*
     * If TimeZoneKeyName is not available, check whether StandardName
     * is available to fall back to the older API GetTimeZoneInformation.
     * If not, directly read the value from registry keys.
     */
        // if (dtzi.StandardName[0] == 0)
        // {
        //     ret = RegOpenKeyEx(HKEY_LOCAL_MACHINE, WIN_CURRENT_TZ_KEY, 0, KEY_READ, cast(PHKEY)&hKey);
        //     if (ret != ERROR_SUCCESS)
        //     {
        //         goto err;
        //     }

        //     /*
        //  * Determine if auto-daylight time adjustment is turned off.
        //  */
        //     bufSize = (val.sizeof);
        //     ret = RegQueryValueExA(hKey, "DynamicDaylightTimeDisabled", null,
        //             &valueType, cast(LPBYTE)&val, &bufSize);
        //     if (ret != ERROR_SUCCESS)
        //     {
        //         goto err;
        //     }
        //     /*
        //  * Return a custom time zone name if auto-daylight time adjustment
        //  * is disabled.
        //  */
        //     if (val == 1)
        //     {
        //         customZoneName(dtzi.Bias, winZoneName);
        //         /* (void) */
        //         RegCloseKey(hKey);
        //         return VALUE_GMTOFFSET;
        //     }

        //     bufSize = MAX_ZONE_CHAR;
        //     ret = RegQueryValueExA(hKey, "TimeZoneKeyName", null, &valueType,
        //             cast(LPBYTE) winZoneName, &bufSize);
        //     if (ret != ERROR_SUCCESS)
        //     {
        //         goto err;
        //     }
        //     /* (void)  */
        //     RegCloseKey(hKey);
        //     return VALUE_KEY;
        // }
        // else
        {
            /*
         * Fall back to GetTimeZoneInformation
         */
            TIME_ZONE_INFORMATION tzi;
            HANDLE hSubKey = null;
            DWORD nSubKeys, i;
            ULONG valueType2;
            TCHAR[MAX_ZONE_CHAR] subKeyName;
            TCHAR[MAX_ZONE_CHAR] szValue;
            WCHAR[MAX_ZONE_CHAR] stdNameInReg;
            TziValue tempTzi;
            WCHAR* stdNamePtr = tzi.StandardName.ptr;
            int onlyMapID;

            timeType = GetTimeZoneInformation(&tzi);
            if (timeType == TIME_ZONE_ID_INVALID) {
                goto err;
            }

            ret = RegOpenKeyEx(HKEY_LOCAL_MACHINE, WIN_CURRENT_TZ_KEY, 0,
                    KEY_READ, cast(PHKEY)&hKey);
            if (ret == ERROR_SUCCESS) {
                /*
             * Determine if auto-daylight time adjustment is turned off.
             */
                bufSize = (val.sizeof);
                ret = RegQueryValueExA(hKey, "DynamicDaylightTimeDisabled",
                        null, &valueType2, cast(LPBYTE)&val, &bufSize);
                if (ret == ERROR_SUCCESS) {
                    if (val == 1 && tzi.DaylightDate.wMonth != 0) {
                        /* (void) */
                        RegCloseKey(hKey);
                        customZoneName(tzi.Bias, winZoneName);
                        return VALUE_GMTOFFSET;
                    }
                }

                /*
             * Win32 problem: If the length of the standard time name is equal
             * to (or probably longer than) 32 in the registry,
             * GetTimeZoneInformation() on NT returns a null string as its
             * standard time name. We need to work around this problem by
             * getting the same information from the TimeZoneInformation
             * registry.
             */
                if (tzi.StandardName[0] == 0) {
                    bufSize = (stdNameInReg.sizeof);
                    ret = getValueInRegistry(hKey, STANDARD_NAME, &valueType2,
                            cast(LPBYTE) stdNameInReg, &bufSize);
                    if (ret != ERROR_SUCCESS) {
                        goto err;
                    }
                    stdNamePtr = stdNameInReg.ptr;
                }
                /* (void) */
                RegCloseKey(hKey);
            }

            /*
         * Open the "Time Zones" registry.
         */
            ret = RegOpenKeyEx(HKEY_LOCAL_MACHINE, NT_TZ_KEY, 0, KEY_READ, cast(PHKEY)&hKey);
            if (ret != ERROR_SUCCESS) {
                ret = RegOpenKeyEx(HKEY_LOCAL_MACHINE, WIN_TZ_KEY, 0, KEY_READ, cast(PHKEY)&hKey);
                /*
             * If both failed, then give up.
             */
                if (ret != ERROR_SUCCESS) {
                    return VALUE_UNKNOWN;
                }
            }

            /*
         * Get the number of subkeys of the "Time Zones" registry for
         * enumeration.
         */
            ret = RegQueryInfoKey(hKey, null, null, null, &nSubKeys, null,
                    null, null, null, null, null, null);
            if (ret != ERROR_SUCCESS) {
                goto err;
            }

            /*
         * Compare to the "Std" value of each subkey and find the entry that
         * matches the current control panel setting.
         */
            onlyMapID = 0;
            for (i = 0; i < nSubKeys; ++i) {
                DWORD size = (subKeyName.sizeof);
                ret = RegEnumKeyEx(hKey, i, subKeyName.ptr, &size, null, null, null, null);
                if (ret != ERROR_SUCCESS) {
                    goto err;
                }
                ret = RegOpenKeyEx(hKey, subKeyName.ptr, 0, KEY_READ, cast(PHKEY)&hSubKey);
                if (ret != ERROR_SUCCESS) {
                    goto err;
                }

                size = (szValue.sizeof);
                ret = getValueInRegistry(hSubKey, STD_NAME, &valueType,
                        cast(ubyte*)(szValue.ptr), &size);
                if (ret != ERROR_SUCCESS) {
                    /*
                 * NT 4.0 SP3 fails here since it doesn't have the "Std"
                 * entry in the Time Zones registry.
                 */
                    RegCloseKey(hSubKey);
                    onlyMapID = 1;
                    ret = RegOpenKeyExW(hKey, stdNamePtr, 0, KEY_READ, cast(PHKEY)&hSubKey);
                    if (ret != ERROR_SUCCESS) {
                        goto err;
                    }
                    break;
                }

                if (wcscmp(cast(WCHAR*) szValue, stdNamePtr) == 0) {
                    /*
                 * Some localized Win32 platforms use a same name to
                 * different time zones. So, we can't rely only on the name
                 * here. We need to check GMT offsets and transition dates
                 * to make sure it's the registry of the current time
                 * zone.
                 */
                    DWORD tziValueSize = (tempTzi.sizeof);
                    ret = RegQueryValueEx(hSubKey, "TZI", null, &valueType,
                            cast(char*)&tempTzi, &tziValueSize);
                    if (ret == ERROR_SUCCESS) {
                        if ((tzi.Bias != tempTzi.bias)
                                || (memcmp(cast(const void*)&tzi.StandardDate,
                                    cast(const void*)&tempTzi.stdDate, (SYSTEMTIME.sizeof)) != 0)) {
                            goto exitout;
                        }

                        if (tzi.DaylightBias != 0) {
                            if ((tzi.DaylightBias != tempTzi.dstBias)
                                    || (memcmp(cast(const void*)&tzi.DaylightDate,
                                        cast(const void*)&tempTzi.dstDate, (SYSTEMTIME.sizeof)) != 0)) {
                                goto exitout;
                            }
                        }
                    }

                    /*
                 * found matched record, terminate search
                 */
                    strcpy(winZoneName, cast(const char*)(subKeyName.ptr));
                    break;
                }
            exitout: /* (void) */
                RegCloseKey(hSubKey);
            }

            /* (void) */
            RegCloseKey(hKey);
        }

        return VALUE_KEY;

    err:
        if (hKey != null) {
            /* (void) */
            RegCloseKey(hKey);
        }
        return VALUE_UNKNOWN;
    }

    /*
 * The mapping table file name.
 */
    enum string MAPPINGS_FILE = "\\lib\\tzmappings";

    /*
 * Index values for the mapping table.
 */
    enum int TZ_WIN_NAME = 0;
    enum int TZ_REGION = 1;
    enum int TZ_JAVA_NAME = 2;

    enum int TZ_NITEMS = 3; /* number of items (fields) */

    /*
 * Looks up the mapping table (tzmappings) and returns a Java time
 * zone ID (e.g., "America/Los_Angeles") if found. Otherwise, null is
 * returned.
 */
    static char* matchJavaTZ(const char* java_home_dir, char* tzName) {
        int line;
        int IDmatched = 0;
        FILE* fp;
        char* javaTZName = null;
        char*[TZ_NITEMS] items;
        char* mapFileName;
        char[MAX_ZONE_CHAR * 4] lineBuffer;
        int offset = 0;
        char* errorMessage = cast(char*) toStringz("unknown error");
        char[MAX_REGION_LENGTH] region;

        // Get the user's location
        if (GetGeoInfo(GetUserGeoID(SYSGEOCLASS.GEOCLASS_NATION),
                SYSGEOTYPE.GEO_ISO2, cast(wchar*) region.ptr, MAX_REGION_LENGTH, 0) == 0) {
            // If GetGeoInfo fails, fallback to LCID's country
            LCID lcid = GetUserDefaultLCID();
            if (GetLocaleInfo(lcid, LOCALE_SISO3166CTRYNAME,
                    cast(wchar*) region.ptr, MAX_REGION_LENGTH) == 0 /* && GetLocaleInfo(lcid, LOCALE_SISO3166CTRYNAME2, cast(wchar*)region.ptr, MAX_REGION_LENGTH) == 0 */
                ) {
                region[0] = '\0';
            }
        }

        mapFileName = cast(char*) malloc(strlen(java_home_dir) + strlen(MAPPINGS_FILE) + 1);
        if (mapFileName == null) {
            return null;
        }
        strcpy(mapFileName, java_home_dir);
        strcat(mapFileName, MAPPINGS_FILE);

        if ((fp = fopen(mapFileName, "r")) == null) {
            // jio_fprintf(stderr, "can't open %s.\n", mapFileName);
            free(cast(void*) mapFileName);
            return null;
        }
        free(cast(void*) mapFileName);

        line = 0;
        while (fgets(lineBuffer.ptr, (lineBuffer.sizeof), fp) != null) {
            char* start;
            char* idx;
            char* endp;
            int itemIndex = 0;

            line++;
            start = idx = lineBuffer.ptr;
            endp = &lineBuffer[(lineBuffer.length - 1)]; ///@gxc

            /*
         * Ignore comment and blank lines.
         */
            if (*idx == '#' || *idx == '\n') {
                continue;
            }

            for (itemIndex = 0; itemIndex < TZ_NITEMS; itemIndex++) {
                items[itemIndex] = start;
                while (*idx && *idx != ':') {
                    if (++idx >= endp) {
                        errorMessage = cast(char*) toStringz("premature end of line");
                        offset = cast(int)(idx - lineBuffer.ptr);
                        goto illegal_format;
                    }
                }
                if (*idx == '\0') {
                    errorMessage = cast(char*) toStringz("illegal null character found");
                    offset = cast(int)(idx - lineBuffer.ptr);
                    goto illegal_format;
                }
                *idx++ = '\0';
                start = idx;
            }

            if (*idx != '\n') {
                errorMessage = cast(char*) toStringz("illegal non-newline character found");
                offset = cast(int)(idx - lineBuffer.ptr);
                goto illegal_format;
            }

            /*
         * We need to scan items until the
         * exact match is found or the end of data is detected.
         */
            if (strcmp(items[TZ_WIN_NAME], tzName) == 0) {
                /*
             * Found the time zone in the mapping table.
             * Check the region code and select the appropriate entry
             */
                if (strcmp(items[TZ_REGION], region.ptr) == 0 || strcmp(items[TZ_REGION], "001") == 0) {
                    javaTZName = strdup(items[TZ_JAVA_NAME]);
                    break;
                }
            }
        }
        fclose(fp);

        return javaTZName;

    illegal_format:
        /* (void) */
        fclose(fp);
        // jio_fprintf(stderr, "Illegal format in tzmappings file: %s at line %d, offset %d.\n",
        //         errorMessage, line, offset);
        return null;
    }

    /*
 * Detects the platform time zone which maps to a Java time zone ID.
 */
    char* findTZ_md(const char* java_home_dir) {
        char[MAX_ZONE_CHAR] winZoneName;
        char* std_timezone = null;
        int result;

        result = getWinTimeZone(winZoneName.ptr);

        if (result != VALUE_UNKNOWN) {
            if (result == VALUE_GMTOFFSET) {
                std_timezone = strdup(winZoneName.ptr);
            } else {
                std_timezone = matchJavaTZ(java_home_dir, winZoneName.ptr);
                if (std_timezone == null) {
                    std_timezone = getGMTOffsetID();
                }
            }
        }
        return std_timezone;
    }

    /**
 * Returns a GMT-offset-based time zone ID.
 */
    char* getGMTOffsetID() {
        LONG bias = 0;
        LONG ret;
        HANDLE hKey = null;
        char[32] zonename;

        // Obtain the current GMT offset value of ActiveTimeBias.
        ret = RegOpenKeyEx(HKEY_LOCAL_MACHINE, WIN_CURRENT_TZ_KEY, 0, KEY_READ, cast(PHKEY)&hKey);
        if (ret == ERROR_SUCCESS) {
            DWORD val;
            DWORD bufSize = (val.sizeof);
            ULONG valueType = 0;
            ret = RegQueryValueExA(hKey, "ActiveTimeBias", null, &valueType,
                    cast(LPBYTE)&val, &bufSize);
            if (ret == ERROR_SUCCESS) {
                bias = cast(LONG) val;
            }
            cast(void) RegCloseKey(hKey);
        }

        // If we can't get the ActiveTimeBias value, use Bias of TimeZoneInformation.
        // Note: Bias doesn't reflect current daylight saving.
        if (ret != ERROR_SUCCESS) {
            TIME_ZONE_INFORMATION tzi;
            if (GetTimeZoneInformation(&tzi) != TIME_ZONE_ID_INVALID) {
                bias = tzi.Bias;
            }
        }

        customZoneName(bias, zonename.ptr);
        return strdup(zonename.ptr);
    }

}
