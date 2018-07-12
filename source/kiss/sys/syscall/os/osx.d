module kiss.sys.syscall.os.osx;

version(OSX):

enum SYSCALL = 0;
enum EXIT = 1;
enum FORK = 2;
enum READ = 3;
enum WRITE = 4;
enum OPEN = 5;
enum CLOSE = 6;
enum WAIT4 = 7;
enum LINK = 9;
enum UNLINK = 10;
enum CHDIR = 12;
enum FCHDIR = 13;
enum MKNOD = 14;
enum CHMOD = 15;
enum CHOWN = 16;
enum GETFSSTAT = 18;
enum GETPID = 20;
enum SETUID = 23;
enum GETUID = 24;
enum GETEUID = 25;
enum PTRACE = 26;
enum RECVMSG = 27;
enum SENDMSG = 28;
enum RECVFROM = 29;
enum ACCEPT = 30;
enum GETPEERNAME = 31;
enum GETSOCKNAME = 32;
enum ACCESS = 33;
enum CHFLAGS = 34;
enum FCHFLAGS = 35;
enum SYNC = 36;
enum KILL = 37;
enum GETPPID = 39;
enum DUP = 41;
enum PIPE = 42;
enum GETEGID = 43;
enum SIGACTION = 46;
enum GETGID = 47;
enum SIGPROCMASK = 48;
enum GETLOGIN = 49;
enum SETLOGIN = 50;
enum ACCT = 51;
enum SIGPENDING = 52;
enum SIGALTSTACK = 53;
enum IOCTL = 54;
enum REBOOT = 55;
enum REVOKE = 56;
enum SYMLINK = 57;
enum READLINK = 58;
enum EXECVE = 59;
enum UMASK = 60;
enum CHROOT = 61;
enum MSYNC = 65;
enum VFORK = 66;
enum MUNMAP = 73;
enum MPROTECT = 74;
enum MADVISE = 75;
enum MINCORE = 78;
enum GETGROUPS = 79;
enum SETGROUPS = 80;
enum GETPGRP = 81;
enum SETPGID = 82;
enum SETITIMER = 83;
enum SWAPON = 85;
enum GETITIMER = 86;
enum GETDTABLESIZE = 89;
enum DUP2 = 90;
enum FCNTL = 92;
enum SELECT = 93;
enum FSYNC = 95;
enum SETPRIORITY = 96;
enum SOCKET = 97;
enum CONNECT = 98;
enum GETPRIORITY = 100;
enum BIND = 104;
enum SETSOCKOPT = 105;
enum LISTEN = 106;
enum SIGSUSPEND = 111;
enum GETTIMEOFDAY = 116;
enum GETRUSAGE = 117;
enum GETSOCKOPT = 118;
enum READV = 120;
enum WRITEV = 121;
enum SETTIMEOFDAY = 122;
enum FCHOWN = 123;
enum FCHMOD = 124;
enum SETREUID = 126;
enum SETREGID = 127;
enum RENAME = 128;
enum FLOCK = 131;
enum MKFIFO = 132;
enum SENDTO = 133;
enum SHUTDOWN = 134;
enum SOCKETPAIR = 135;
enum MKDIR = 136;
enum RMDIR = 137;
enum UTIMES = 138;
enum FUTIMES = 139;
enum ADJTIME = 140;
enum GETHOSTUUID = 142;
enum SETSID = 147;
enum GETPGID = 151;
enum SETPRIVEXEC = 152;
enum PREAD = 153;
enum PWRITE = 154;
enum NFSSVC = 155;
enum STATFS = 157;
enum FSTATFS = 158;
enum UNMOUNT = 159;
enum GETFH = 161;
enum QUOTACTL = 165;
enum MOUNT = 167;
enum CSOPS = 169;
enum CSOPS_AUDITTOKEN = 170;
enum WAITID = 173;
enum KDEBUG_TRACE = 180;
enum SETGID = 181;
enum SETEGID = 182;
enum SETEUID = 183;
enum SIGRETURN = 184;
enum CHUD = 185;
enum FDATASYNC = 187;
enum STAT = 188;
enum FSTAT = 189;
enum LSTAT = 190;
enum PATHCONF = 191;
enum FPATHCONF = 192;
enum GETRLIMIT = 194;
enum SETRLIMIT = 195;
enum GETDIRENTRIES = 196;
enum MMAP = 197;
enum LSEEK = 199;
enum TRUNCATE = 200;
enum FTRUNCATE = 201;
enum __SYSCTL = 202;
enum MLOCK = 203;
enum MUNLOCK = 204;
enum UNDELETE = 205;
enum OPEN_DPROTECTED_NP = 216;
enum GETATTRLIST = 220;
enum SETATTRLIST = 221;
enum GETDIRENTRIESATTR = 222;
enum EXCHANGEDATA = 223;
enum SEARCHFS = 225;
enum DELETE = 226;
enum COPYFILE = 227;
enum FGETATTRLIST = 228;
enum FSETATTRLIST = 229;
enum POLL = 230;
enum WATCHEVENT = 231;
enum WAITEVENT = 232;
enum MODWATCH = 233;
enum GETXATTR = 234;
enum FGETXATTR = 235;
enum SETXATTR = 236;
enum FSETXATTR = 237;
enum REMOVEXATTR = 238;
enum FREMOVEXATTR = 239;
enum LISTXATTR = 240;
enum FLISTXATTR = 241;
enum FSCTL = 242;
enum INITGROUPS = 243;
enum POSIX_SPAWN = 244;
enum FFSCTL = 245;
enum NFSCLNT = 247;
enum FHOPEN = 248;
enum MINHERIT = 250;
enum SEMSYS = 251;
enum MSGSYS = 252;
enum SHMSYS = 253;
enum SEMCTL = 254;
enum SEMGET = 255;
enum SEMOP = 256;
enum MSGCTL = 258;
enum MSGGET = 259;
enum MSGSND = 260;
enum MSGRCV = 261;
enum SHMAT = 262;
enum SHMCTL = 263;
enum SHMDT = 264;
enum SHMGET = 265;
enum SHM_OPEN = 266;
enum SHM_UNLINK = 267;
enum SEM_OPEN = 268;
enum SEM_CLOSE = 269;
enum SEM_UNLINK = 270;
enum SEM_WAIT = 271;
enum SEM_TRYWAIT = 272;
enum SEM_POST = 273;
enum SEM_GETVALUE = 274;
enum SEM_INIT = 275;
enum SEM_DESTROY = 276;
enum OPEN_EXTENDED = 277;
enum UMASK_EXTENDED = 278;
enum STAT_EXTENDED = 279;
enum LSTAT_EXTENDED = 280;
enum FSTAT_EXTENDED = 281;
enum CHMOD_EXTENDED = 282;
enum FCHMOD_EXTENDED = 283;
enum ACCESS_EXTENDED = 284;
enum SETTID = 285;
enum GETTID = 286;
enum SETSGROUPS = 287;
enum GETSGROUPS = 288;
enum SETWGROUPS = 289;
enum GETWGROUPS = 290;
enum MKFIFO_EXTENDED = 291;
enum MKDIR_EXTENDED = 292;
enum IDENTITYSVC = 293;
enum SHARED_REGION_CHECK_NP = 294;
enum VM_PRESSURE_MONITOR = 296;
enum PSYNCH_RW_LONGRDLOCK = 297;
enum PSYNCH_RW_YIELDWRLOCK = 298;
enum PSYNCH_RW_DOWNGRADE = 299;
enum PSYNCH_RW_UPGRADE = 300;
enum PSYNCH_MUTEXWAIT = 301;
enum PSYNCH_MUTEXDROP = 302;
enum PSYNCH_CVBROAD = 303;
enum PSYNCH_CVSIGNAL = 304;
enum PSYNCH_CVWAIT = 305;
enum PSYNCH_RW_RDLOCK = 306;
enum PSYNCH_RW_WRLOCK = 307;
enum PSYNCH_RW_UNLOCK = 308;
enum PSYNCH_RW_UNLOCK2 = 309;
enum GETSID = 310;
enum SETTID_WITH_PID = 311;
enum PSYNCH_CVCLRPREPOST = 312;
enum AIO_FSYNC = 313;
enum AIO_RETURN = 314;
enum AIO_SUSPEND = 315;
enum AIO_CANCEL = 316;
enum AIO_ERROR = 317;
enum AIO_READ = 318;
enum AIO_WRITE = 319;
enum LIO_LISTIO = 320;
enum IOPOLICYSYS = 322;
enum PROCESS_POLICY = 323;
enum MLOCKALL = 324;
enum MUNLOCKALL = 325;
enum ISSETUGID = 327;
enum __PTHREAD_KILL = 328;
enum __PTHREAD_SIGMASK = 329;
enum __SIGWAIT = 330;
enum __DISABLE_THREADSIGNAL = 331;
enum __PTHREAD_MARKCANCEL = 332;
enum __PTHREAD_CANCELED = 333;
enum __SEMWAIT_SIGNAL = 334;
enum PROC_INFO = 336;
enum SENDFILE = 337;
enum STAT64 = 338;
enum FSTAT64 = 339;
enum LSTAT64 = 340;
enum STAT64_EXTENDED = 341;
enum LSTAT64_EXTENDED = 342;
enum FSTAT64_EXTENDED = 343;
enum GETDIRENTRIES64 = 344;
enum STATFS64 = 345;
enum FSTATFS64 = 346;
enum GETFSSTAT64 = 347;
enum __PTHREAD_CHDIR = 348;
enum __PTHREAD_FCHDIR = 349;
enum AUDIT = 350;
enum AUDITON = 351;
enum GETAUID = 353;
enum SETAUID = 354;
enum GETAUDIT_ADDR = 357;
enum SETAUDIT_ADDR = 358;
enum AUDITCTL = 359;
enum BSDTHREAD_CREATE = 360;
enum BSDTHREAD_TERMINATE = 361;
enum KQUEUE = 362;
enum KEVENT = 363;
enum LCHOWN = 364;
enum STACK_SNAPSHOT = 365;
enum BSDTHREAD_REGISTER = 366;
enum WORKQ_OPEN = 367;
enum WORKQ_KERNRETURN = 368;
enum KEVENT64 = 369;
enum __OLD_SEMWAIT_SIGNAL = 370;
enum __OLD_SEMWAIT_SIGNAL_NOCANCEL = 371;
enum THREAD_SELFID = 372;
enum LEDGER = 373;
enum __MAC_EXECVE = 380;
enum __MAC_SYSCALL = 381;
enum __MAC_GET_FILE = 382;
enum __MAC_SET_FILE = 383;
enum __MAC_GET_LINK = 384;
enum __MAC_SET_LINK = 385;
enum __MAC_GET_PROC = 386;
enum __MAC_SET_PROC = 387;
enum __MAC_GET_FD = 388;
enum __MAC_SET_FD = 389;
enum __MAC_GET_PID = 390;
enum __MAC_GET_LCID = 391;
enum __MAC_GET_LCTX = 392;
enum __MAC_SET_LCTX = 393;
enum SETLCID = 394;
enum GETLCID = 395;
enum READ_NOCANCEL = 396;
enum WRITE_NOCANCEL = 397;
enum OPEN_NOCANCEL = 398;
enum CLOSE_NOCANCEL = 399;
enum WAIT4_NOCANCEL = 400;
enum RECVMSG_NOCANCEL = 401;
enum SENDMSG_NOCANCEL = 402;
enum RECVFROM_NOCANCEL = 403;
enum ACCEPT_NOCANCEL = 404;
enum MSYNC_NOCANCEL = 405;
enum FCNTL_NOCANCEL = 406;
enum SELECT_NOCANCEL = 407;
enum FSYNC_NOCANCEL = 408;
enum CONNECT_NOCANCEL = 409;
enum SIGSUSPEND_NOCANCEL = 410;
enum READV_NOCANCEL = 411;
enum WRITEV_NOCANCEL = 412;
enum SENDTO_NOCANCEL = 413;
enum PREAD_NOCANCEL = 414;
enum PWRITE_NOCANCEL = 415;
enum WAITID_NOCANCEL = 416;
enum POLL_NOCANCEL = 417;
enum MSGSND_NOCANCEL = 418;
enum MSGRCV_NOCANCEL = 419;
enum SEM_WAIT_NOCANCEL = 420;
enum AIO_SUSPEND_NOCANCEL = 421;
enum __SIGWAIT_NOCANCEL = 422;
enum __SEMWAIT_SIGNAL_NOCANCEL = 423;
enum __MAC_MOUNT = 424;
enum __MAC_GET_MOUNT = 425;
enum __MAC_GETFSSTAT = 426;
enum FSGETPATH = 427;
enum AUDIT_SESSION_SELF = 428;
enum AUDIT_SESSION_JOIN = 429;
enum FILEPORT_MAKEPORT = 430;
enum FILEPORT_MAKEFD = 431;
enum AUDIT_SESSION_PORT = 432;
enum PID_SUSPEND = 433;
enum PID_RESUME = 434;
enum SHARED_REGION_MAP_AND_SLIDE_NP = 438;
enum KAS_INFO = 439;
enum MEMORYSTATUS_CONTROL = 440;
enum GUARDED_OPEN_NP = 441;
enum GUARDED_CLOSE_NP = 442;
enum GUARDED_KQUEUE_NP = 443;
enum CHANGE_FDGUARD_NP = 444;
enum PROC_RLIMIT_CONTROL = 446;
enum CONNECTX = 447;
enum DISCONNECTX = 448;
enum PEELOFF = 449;
enum SOCKET_DELEGATE = 450;
enum TELEMETRY = 451;
enum PROC_UUID_POLICY = 452;
enum MEMORYSTATUS_GET_LEVEL = 453;
enum SYSTEM_OVERRIDE = 454;
enum VFS_PURGE = 455;
enum MAXSYSCALL = 456;
