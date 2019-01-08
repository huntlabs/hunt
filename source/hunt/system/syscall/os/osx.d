module hunt.system.syscall.os.osx;

version(OSX):

enum SYS_syscall = 0;
enum SYS_exit = 1;
enum SYS_fork = 2;
enum SYS_read = 3;
enum SYS_write = 4;
enum SYS_open = 5;
enum SYS_close = 6;
enum SYS_wait4 = 7;
                        /* 8  old creat */
enum SYS_link = 9;
enum SYS_unlink = 10;
                        /* 11  old execv */
enum SYS_chdir = 12;
enum SYS_fchdir = 13;
enum SYS_mknod = 14;
enum SYS_chmod = 15;
enum SYS_chown = 16;
                        /* 17  old break */
enum SYS_getfsstat = 18;
                        /* 19  old lseek */
enum SYS_getpid = 20;
                        /* 21  old mount */
                        /* 22  old umount */
enum SYS_setuid = 23;
enum SYS_getuid = 24;
enum SYS_geteuid = 25;
enum SYS_ptrace = 26;
enum SYS_recvmsg = 27;
enum SYS_sendmsg = 28;
enum SYS_recvfrom = 29;
enum SYS_accept = 30;
enum SYS_getpeername = 31;
enum SYS_getsockname = 32;
enum SYS_access = 33;
enum SYS_chflags = 34;
enum SYS_fchflags = 35;
enum SYS_sync = 36;
enum SYS_kill = 37;
                        /* 38  old stat */
enum SYS_getppid = 39;
                        /* 40  old lstat */
enum SYS_dup = 41;
enum SYS_pipe = 42;
enum SYS_getegid = 43;
                        /* 44  old profil */
                        /* 45  old ktrace */
enum SYS_sigaction = 46;
enum SYS_getgid = 47;
enum SYS_sigprocmask = 48;
enum SYS_getlogin = 49;
enum SYS_setlogin = 50;
enum SYS_acct = 51;
enum SYS_sigpending = 52;
enum SYS_sigaltstack = 53;
enum SYS_ioctl = 54;
enum SYS_reboot = 55;
enum SYS_revoke = 56;
enum SYS_symlink = 57;
enum SYS_readlink = 58;
enum SYS_execve = 59;
enum SYS_umask = 60;
enum SYS_chroot = 61;
                        /* 62  old fstat */
                        /* 63  used internally and reserved */
                        /* 64  old getpagesize */
enum SYS_msync = 65;
enum SYS_vfork = 66;
                        /* 67  old vread */
                        /* 68  old vwrite */
                        /* 69  old sbrk */
                        /* 70  old sstk */
                        /* 71  old mmap */
                        /* 72  old vadvise */
enum SYS_munmap = 73;
enum SYS_mprotect = 74;
enum SYS_madvise = 75;
                        /* 76  old vhangup */
                        /* 77  old vlimit */
enum SYS_mincore = 78;
enum SYS_getgroups = 79;
enum SYS_setgroups = 80;
enum SYS_getpgrp = 81;
enum SYS_setpgid = 82;
enum SYS_setitimer = 83;
                        /* 84  old wait */
enum SYS_swapon = 85;
enum SYS_getitimer = 86;
                        /* 87  old gethostname */
                        /* 88  old sethostname */
enum SYS_getdtablesize = 89;
enum SYS_dup2 = 90;
                        /* 91  old getdopt */
enum SYS_fcntl = 92;
enum SYS_select = 93;
                        /* 94  old setdopt */
enum SYS_fsync = 95;
enum SYS_setpriority = 96;
enum SYS_socket = 97;
enum SYS_connect = 98;
                        /* 99  old accept */
enum SYS_getpriority = 100;
                        /* 101  old send */
                        /* 102  old recv */
                        /* 103  old sigreturn */
enum SYS_bind = 104;
enum SYS_setsockopt = 105;
enum SYS_listen = 106;
                        /* 107  old vtimes */
                        /* 108  old sigvec */
                        /* 109  old sigblock */
                        /* 110  old sigsetmask */
enum SYS_sigsuspend = 111;
                        /* 112  old sigstack */
                        /* 113  old recvmsg */
                        /* 114  old sendmsg */
                        /* 115  old vtrace */
enum SYS_gettimeofday = 116;
enum SYS_getrusage = 117;
enum SYS_getsockopt = 118;
                        /* 119  old resuba */
enum SYS_readv = 120;
enum SYS_writev = 121;
enum SYS_settimeofday = 122;
enum SYS_fchown = 123;
enum SYS_fchmod = 124;
                        /* 125  old recvfrom */
enum SYS_setreuid = 126;
enum SYS_setregid = 127;
enum SYS_rename = 128;
                        /* 129  old truncate */
                        /* 130  old ftruncate */
enum SYS_flock = 131;
enum SYS_mkfifo = 132;
enum SYS_sendto = 133;
enum SYS_shutdown = 134;
enum SYS_socketpair = 135;
enum SYS_mkdir = 136;
enum SYS_rmdir = 137;
enum SYS_utimes = 138;
enum SYS_futimes = 139;
enum SYS_adjtime = 140;
                        /* 141  old getpeername */
enum SYS_gethostuuid = 142;
                        /* 143  old sethostid */
                        /* 144  old getrlimit */
                        /* 145  old setrlimit */
                        /* 146  old killpg */
enum SYS_setsid = 147;
                        /* 148  old setquota */
                        /* 149  old qquota */
                        /* 150  old getsockname */
enum SYS_getpgid = 151;
enum SYS_setprivexec = 152;
enum SYS_pread = 153;
enum SYS_pwrite = 154;
enum SYS_nfssvc = 155;
                        /* 156  old getdirentries */
enum SYS_statfs = 157;
enum SYS_fstatfs = 158;
enum SYS_unmount = 159;
                        /* 160  old async_daemon */
enum SYS_getfh = 161;
                        /* 162  old getdomainname */
                        /* 163  old setdomainname */
                        /* 164  */
enum SYS_quotactl = 165;
                        /* 166  old exportfs */
enum SYS_mount = 167;
                        /* 168  old ustat */
enum SYS_csops = 169;
enum SYS_csops_audittoken = 170;
                        /* 171  old wait3 */
                        /* 172  old rpause */
enum SYS_waitid = 173;
                        /* 174  old getdents */
                        /* 175  old gc_control */
                        /* 176  old add_profil */
enum SYS_kdebug_typefilter = 177;
enum SYS_kdebug_trace_string = 178;
enum SYS_kdebug_trace64 = 179;
enum SYS_kdebug_trace = 180;
enum SYS_setgid = 181;
enum SYS_setegid = 182;
enum SYS_seteuid = 183;
enum SYS_sigreturn = 184;
                        /* 185  old chud */
enum SYS_thread_selfcounts = 186;
enum SYS_fdatasync = 187;
enum SYS_stat = 188;
enum SYS_fstat = 189;
enum SYS_lstat = 190;
enum SYS_pathconf = 191;
enum SYS_fpathconf = 192;
                        /* 193  old getfsstat */
enum SYS_getrlimit = 194;
enum SYS_setrlimit = 195;
enum SYS_getdirentries = 196;
enum SYS_mmap = 197;
                        /* 198  old __syscall */
enum SYS_lseek = 199;
enum SYS_truncate = 200;
enum SYS_ftruncate = 201;
enum SYS_sysctl = 202;
enum SYS_mlock = 203;
enum SYS_munlock = 204;
enum SYS_undelete = 205;
                        /* 206  old ATsocket */
                        /* 207  old ATgetmsg */
                        /* 208  old ATputmsg */
                        /* 209  old ATsndreq */
                        /* 210  old ATsndrsp */
                        /* 211  old ATgetreq */
                        /* 212  old ATgetrsp */
                        /* 213  Reserved for AppleTalk */
                        /* 214  */
                        /* 215  */
enum SYS_open_dprotected_np = 216;
                        /* 217  old statv */
                        /* 218  old lstatv */
                        /* 219  old fstatv */
enum SYS_getattrlist = 220;
enum SYS_setattrlist = 221;
enum SYS_getdirentriesattr = 222;
enum SYS_exchangedata = 223;
                        /* 224  old checkuseraccess or fsgetpath */
enum SYS_searchfs = 225;
enum SYS_delete = 226;
enum SYS_copyfile = 227;
enum SYS_fgetattrlist = 228;
enum SYS_fsetattrlist = 229;
enum SYS_poll = 230;
enum SYS_watchevent = 231;
enum SYS_waitevent = 232;
enum SYS_modwatch = 233;
enum SYS_getxattr = 234;
enum SYS_fgetxattr = 235;
enum SYS_setxattr = 236;
enum SYS_fsetxattr = 237;
enum SYS_removexattr = 238;
enum SYS_fremovexattr = 239;
enum SYS_listxattr = 240;
enum SYS_flistxattr = 241;
enum SYS_fsctl = 242;
enum SYS_initgroups = 243;
enum SYS_posix_spawn = 244;
enum SYS_ffsctl = 245;
                        /* 246  */
enum SYS_nfsclnt = 247;
enum SYS_fhopen = 248;
                        /* 249  */
enum SYS_minherit = 250;
enum SYS_semsys = 251;
enum SYS_msgsys = 252;
enum SYS_shmsys = 253;
enum SYS_semctl = 254;
enum SYS_semget = 255;
enum SYS_semop = 256;
                        /* 257  old semconfig */
enum SYS_msgctl = 258;
enum SYS_msgget = 259;
enum SYS_msgsnd = 260;
enum SYS_msgrcv = 261;
enum SYS_shmat = 262;
enum SYS_shmctl = 263;
enum SYS_shmdt = 264;
enum SYS_shmget = 265;
enum SYS_shm_open = 266;
enum SYS_shm_unlink = 267;
enum SYS_sem_open = 268;
enum SYS_sem_close = 269;
enum SYS_sem_unlink = 270;
enum SYS_sem_wait = 271;
enum SYS_sem_trywait = 272;
enum SYS_sem_post = 273;
enum SYS_sysctlbyname = 274;
                        /* 275  old sem_init */
                        /* 276  old sem_destroy */
enum SYS_open_extended = 277;
enum SYS_umask_extended = 278;
enum SYS_stat_extended = 279;
enum SYS_lstat_extended = 280;
enum SYS_fstat_extended = 281;
enum SYS_chmod_extended = 282;
enum SYS_fchmod_extended = 283;
enum SYS_access_extended = 284;
enum SYS_settid = 285;
enum SYS_gettid = 286;
enum SYS_setsgroups = 287;
enum SYS_getsgroups = 288;
enum SYS_setwgroups = 289;
enum SYS_getwgroups = 290;
enum SYS_mkfifo_extended = 291;
enum SYS_mkdir_extended = 292;
enum SYS_identitysvc = 293;
enum SYS_shared_region_check_np = 294;
                        /* 295  old shared_region_map_np */
enum SYS_vm_pressure_monitor = 296;
enum SYS_psynch_rw_longrdlock = 297;
enum SYS_psynch_rw_yieldwrlock = 298;
enum SYS_psynch_rw_downgrade = 299;
enum SYS_psynch_rw_upgrade = 300;
enum SYS_psynch_mutexwait = 301;
enum SYS_psynch_mutexdrop = 302;
enum SYS_psynch_cvbroad = 303;
enum SYS_psynch_cvsignal = 304;
enum SYS_psynch_cvwait = 305;
enum SYS_psynch_rw_rdlock = 306;
enum SYS_psynch_rw_wrlock = 307;
enum SYS_psynch_rw_unlock = 308;
enum SYS_psynch_rw_unlock2 = 309;
enum SYS_getsid = 310;
enum SYS_settid_with_pid = 311;
enum SYS_psynch_cvclrprepost = 312;
enum SYS_aio_fsync = 313;
enum SYS_aio_return = 314;
enum SYS_aio_suspend = 315;
enum SYS_aio_cancel = 316;
enum SYS_aio_error = 317;
enum SYS_aio_read = 318;
enum SYS_aio_write = 319;
enum SYS_lio_listio = 320;
                        /* 321  old __pthread_cond_wait */
enum SYS_iopolicysys = 322;
enum SYS_process_policy = 323;
enum SYS_mlockall = 324;
enum SYS_munlockall = 325;
                        /* 326  */
enum SYS_issetugid = 327;
enum SYS___pthread_kill = 328;
enum SYS___pthread_sigmask = 329;
enum SYS___sigwait = 330;
enum SYS___disable_threadsignal = 331;
enum SYS___pthread_markcancel = 332;
enum SYS___pthread_canceled = 333;
enum SYS___semwait_signal = 334;
                        /* 335  old utrace */
enum SYS_proc_info = 336;
enum SYS_sendfile = 337;
enum SYS_stat64 = 338;
enum SYS_fstat64 = 339;
enum SYS_lstat64 = 340;
enum SYS_stat64_extended = 341;
enum SYS_lstat64_extended = 342;
enum SYS_fstat64_extended = 343;
enum SYS_getdirentries64 = 344;
enum SYS_statfs64 = 345;
enum SYS_fstatfs64 = 346;
enum SYS_getfsstat64 = 347;
enum SYS___pthread_chdir = 348;
enum SYS___pthread_fchdir = 349;
enum SYS_audit = 350;
enum SYS_auditon = 351;
                        /* 352  */
enum SYS_getauid = 353;
enum SYS_setauid = 354;
                        /* 355  old getaudit */
                        /* 356  old setaudit */
enum SYS_getaudit_addr = 357;
enum SYS_setaudit_addr = 358;
enum SYS_auditctl = 359;
enum SYS_bsdthread_create = 360;
enum SYS_bsdthread_terminate = 361;
enum SYS_kqueue = 362;
enum SYS_kevent = 363;
enum SYS_lchown = 364;
                        /* 365  old stack_snapshot */
enum SYS_bsdthread_register = 366;
enum SYS_workq_open = 367;
enum SYS_workq_kernreturn = 368;
enum SYS_kevent64 = 369;
enum SYS___old_semwait_signal = 370;
enum SYS___old_semwait_signal_nocancel = 371;
enum SYS_thread_selfid = 372;
enum SYS_ledger = 373;
enum SYS_kevent_qos = 374;
enum SYS_kevent_id = 375;
                        /* 376  */
                        /* 377  */
                        /* 378  */
                        /* 379  */
enum SYS___mac_execve = 380;
enum SYS___mac_syscall = 381;
enum SYS___mac_get_file = 382;
enum SYS___mac_set_file = 383;
enum SYS___mac_get_link = 384;
enum SYS___mac_set_link = 385;
enum SYS___mac_get_proc = 386;
enum SYS___mac_set_proc = 387;
enum SYS___mac_get_fd = 388;
enum SYS___mac_set_fd = 389;
enum SYS___mac_get_pid = 390;
                        /* 391  */
                        /* 392  */
                        /* 393  */
enum SYS_pselect = 394;
enum SYS_pselect_nocancel = 395;
enum SYS_read_nocancel = 396;
enum SYS_write_nocancel = 397;
enum SYS_open_nocancel = 398;
enum SYS_close_nocancel = 399;
enum SYS_wait4_nocancel = 400;
enum SYS_recvmsg_nocancel = 401;
enum SYS_sendmsg_nocancel = 402;
enum SYS_recvfrom_nocancel = 403;
enum SYS_accept_nocancel = 404;
enum SYS_msync_nocancel = 405;
enum SYS_fcntl_nocancel = 406;
enum SYS_select_nocancel = 407;
enum SYS_fsync_nocancel = 408;
enum SYS_connect_nocancel = 409;
enum SYS_sigsuspend_nocancel = 410;
enum SYS_readv_nocancel = 411;
enum SYS_writev_nocancel = 412;
enum SYS_sendto_nocancel = 413;
enum SYS_pread_nocancel = 414;
enum SYS_pwrite_nocancel = 415;
enum SYS_waitid_nocancel = 416;
enum SYS_poll_nocancel = 417;
enum SYS_msgsnd_nocancel = 418;
enum SYS_msgrcv_nocancel = 419;
enum SYS_sem_wait_nocancel = 420;
enum SYS_aio_suspend_nocancel = 421;
enum SYS___sigwait_nocancel = 422;
enum SYS___semwait_signal_nocancel = 423;
enum SYS___mac_mount = 424;
enum SYS___mac_get_mount = 425;
enum SYS___mac_getfsstat = 426;
enum SYS_fsgetpath = 427;
enum SYS_audit_session_self = 428;
enum SYS_audit_session_join = 429;
enum SYS_fileport_makeport = 430;
enum SYS_fileport_makefd = 431;
enum SYS_audit_session_port = 432;
enum SYS_pid_suspend = 433;
enum SYS_pid_resume = 434;
enum SYS_pid_hibernate = 435;
enum SYS_pid_shutdown_sockets = 436;
                        /* 437  old shared_region_slide_np */
enum SYS_shared_region_map_and_slide_np = 438;
enum SYS_kas_info = 439;
enum SYS_memorystatus_control = 440;
enum SYS_guarded_open_np = 441;
enum SYS_guarded_close_np = 442;
enum SYS_guarded_kqueue_np = 443;
enum SYS_change_fdguard_np = 444;
enum SYS_usrctl = 445;
enum SYS_proc_rlimit_control = 446;
enum SYS_connectx = 447;
enum SYS_disconnectx = 448;
enum SYS_peeloff = 449;
enum SYS_socket_delegate = 450;
enum SYS_telemetry = 451;
enum SYS_proc_uuid_policy = 452;
enum SYS_memorystatus_get_level = 453;
enum SYS_system_override = 454;
enum SYS_vfs_purge = 455;
enum SYS_sfi_ctl = 456;
enum SYS_sfi_pidctl = 457;
enum SYS_coalition = 458;
enum SYS_coalition_info = 459;
enum SYS_necp_match_policy = 460;
enum SYS_getattrlistbulk = 461;
enum SYS_clonefileat = 462;
enum SYS_openat = 463;
enum SYS_openat_nocancel = 464;
enum SYS_renameat = 465;
enum SYS_faccessat = 466;
enum SYS_fchmodat = 467;
enum SYS_fchownat = 468;
enum SYS_fstatat = 469;
enum SYS_fstatat64 = 470;
enum SYS_linkat = 471;
enum SYS_unlinkat = 472;
enum SYS_readlinkat = 473;
enum SYS_symlinkat = 474;
enum SYS_mkdirat = 475;
enum SYS_getattrlistat = 476;
enum SYS_proc_trace_log = 477;
enum SYS_bsdthread_ctl = 478;
enum SYS_openbyid_np = 479;
enum SYS_recvmsg_x = 480;
enum SYS_sendmsg_x = 481;
enum SYS_thread_selfusage = 482;
enum SYS_csrctl = 483;
enum SYS_guarded_open_dprotected_np = 484;
enum SYS_guarded_write_np = 485;
enum SYS_guarded_pwrite_np = 486;
enum SYS_guarded_writev_np = 487;
enum SYS_renameatx_np = 488;
enum SYS_mremap_encrypted = 489;
enum SYS_netagent_trigger = 490;
enum SYS_stack_snapshot_with_config = 491;
enum SYS_microstackshot = 492;
enum SYS_grab_pgo_data = 493;
enum SYS_persona = 494;
                        /* 495  */
                        /* 496  */
                        /* 497  */
                        /* 498  */
enum SYS_work_interval_ctl = 499;
enum SYS_getentropy = 500;
enum SYS_necp_open = 501;
enum SYS_necp_client_action = 502;
enum SYS___nexus_open = 503;
enum SYS___nexus_register = 504;
enum SYS___nexus_deregister = 505;
enum SYS___nexus_create = 506;
enum SYS___nexus_destroy = 507;
enum SYS___nexus_get_opt = 508;
enum SYS___nexus_set_opt = 509;
enum SYS___channel_open = 510;
enum SYS___channel_get_info = 511;
enum SYS___channel_sync = 512;
enum SYS___channel_get_opt = 513;
enum SYS___channel_set_opt = 514;
enum SYS_ulock_wait = 515;
enum SYS_ulock_wake = 516;
enum SYS_fclonefileat = 517;
enum SYS_fs_snapshot = 518;
                        /* 519  */
enum SYS_terminate_with_payload = 520;
enum SYS_abort_with_payload = 521;
enum SYS_necp_session_open = 522;
enum SYS_necp_session_action = 523;
enum SYS_setattrlistat = 524;
enum SYS_net_qos_guideline = 525;
enum SYS_fmount = 526;
enum SYS_ntp_adjtime = 527;
enum SYS_ntp_gettime = 528;
enum SYS_os_fault_with_payload = 529;
enum SYS_MAXSYSCALL = 530;
enum SYS_invalid = 63;

