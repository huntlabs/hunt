module kiss.util.uri;

struct Uri
{
    string scheme;
    string host;
    ushort port;
    string path;
    string username;
    string password;
    string query;
    string fragment;
}

class Parser
{
    public Uri parse(string parseString)
    {
        Uri uri;

        uri.scheme = "postgresql";

        return uri;
    }
}
