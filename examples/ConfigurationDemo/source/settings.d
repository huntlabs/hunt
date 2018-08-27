module settings;

import hunt.util.configuration;

@Configuration("http")
struct TestHttpConfig
{
    @Value("listen")
    int value;

    string addr;
}

@Configuration("server")
struct ServerSettings
{
    @Value("listen")
    string ip = "127.0.0.1";

    ushort port = 8080;
}


@Configuration("package")
class PackageSettings
{
    string name;
}

@Configuration("app")
class TestConfig
{
    string name = "Kiss";

    @Value("time")
    double time;
    
    PackageSettings package1;

    @Value("pkg")
    PackageSettings package2;

    ServerSettings server1;

    @Value("httpserver")
    ServerSettings server2;

    @Value("interval", true)
    int interval1 = 500;

    @Value("interval", true)
    int interval2 = 600;

    int interval3 = 700;

    @property void description(string d)
    {
        _desc = d;
    }

    @property string description()
    {
        return _desc;
    }

    private string _desc = "Putao Ltd.";

}


class BuilderTest1Config
{
    string name = "Kiss";

    @Value("time")
    double time;

    ServerSettings server1;

    @Value("httpserver")
    ServerSettings server2;

    @Value("interval", true)
    int interval1 = 500;

    @Value("interval", true)
    int interval2 = 600;

    int interval3 = 700;

}


class TestConfigEx : TestConfig
{
    string fullName = "Putao";
}


@Configuration("hunt")
class AppConfig
{
    struct ApplicationConf
    {
        string name = "HUNT APPLICATION";
        string baseUrl;
        string defaultCookieDomain = ".example.com";
        string defaultLanguage = "zh-CN";
        string languages = "zh-CN,en-US";
        string secret = "CD6CABB1123C86EDAD9";
        string encoding = "utf-8";
        int staticFileCacheMinutes = 30;
    }

    struct SessionConf
    {
        string storage = "memory";
        string prefix = "huntsession_";
        string args = "/tmp";
        uint expire = 3600;
    }

    struct CacheConf
    {
        string storage = "memory";
        string args = "/tmp";
        bool enableL2 = false;
    }

    struct HttpConf
    {
        string address = "0.0.0.0";
        ushort port = 8080;
        uint workerThreads = 4;
        uint ioThreads = 2;
        size_t keepAliveTimeOut = 30;
        size_t maxHeaderSize = 60 * 1024;
        int cacheControl;
        string path;
    }

    struct HttpsConf
    {
        bool enabled = false;
        string protocol;
        string keyStore;
        string keyStoreType;
        string keyStorePassword;
    }

    struct RouteConf
    {
        string groups;
    }

    struct LogConfig
    {
        string level = "all";
        string path;
        string file = "";
        bool disableConsole = false;
        string maxSize = "8M";
        uint maxNum = 8;
    }

    struct MemcacheConf
    {
        bool enabled = false;
        string servers;
    }

    struct RedisConf
    {
        bool enabled = false;
        string host = "127.0.0.1";
        string password = "";
        ushort database = 0;
        ushort port = 6379;
        uint timeout = 0;
    }

    struct UploadConf
    {
        string path;
        uint maxSize = 4 * 1024 * 1024;
    }

    struct DownloadConfig
    {
        string path = "downloads";
    }

    struct MailSmtpConf
    {
        string host;
        string channel;
        ushort port;
        string protocol;
        string user;
        string password;
    }

    struct MailConf
    {
        MailSmtpConf smtp;
    }

    struct DbPoolConf
    {
        uint maxConnection = 10;
        uint minConnection = 10;
        uint timeout = 10000;
    }

    struct DBConfig
    {
        string url;
        DbPoolConf pool;
    }

    struct DateConf
    {
        string format;
        string timeZone;
    }

    struct CornConf
    {
        string noon;
    }

    struct ServiceConf
    {
        string address = "127.0.0.1";
        ushort port;
        int workerThreads;
        string password;
    }

    struct RpcConf
    {
        bool enabled = true;
        ServiceConf service;
    }

    struct Views
    {
        string path = "views/";
        string ext = ".dhtml";
    }

    DBConfig database;
    ApplicationConf application;
    SessionConf session;
    CacheConf cache;
    HttpConf http;
    HttpsConf https;
    RouteConf route;
    MemcacheConf memcache;
    RedisConf redis;
    LogConfig log;
    UploadConf upload;
    DownloadConfig download;
    CornConf cron;
    DateConf date;
    MailConf mail;
    RpcConf rpc;
    Views view;
}
