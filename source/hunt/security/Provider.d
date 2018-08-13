module hunt.security.Provider;


import std.conv;

abstract class Provider
{

    /**
    * The provider name.
    *
    * @serial
    */
    private string name;

    /**
    * A description of the provider and its services.
    *
    * @serial
    */
    private string info;

    /**
    * The provider version number.
    *
    * @serial
    */
    private double _version;


    private bool initialized;

    /**
    * Constructs a provider with the specified name, version number,
    * and information.
    *
    * @param name the provider name.
    *
    * @param version the provider version number.
    *
    * @param info a description of the provider and its services.
    */
    protected this(string name, double ver, string info) {
        this.name = name;
        this._version = ver;
        this.info = info;
        // putId();
        initialized = true;
    }

    /**
    * Returns the name of this provider.
    *
    * @return the name of this provider.
    */
    string getName() {
        return name;
    }

    /**
    * Returns the version number for this provider.
    *
    * @return the version number for this provider.
    */
    double getVersion() {
        return _version;
    }

    /**
    * Returns a human-readable description of the provider and its
    * services.  This may return an HTML page, with relevant links.
    *
    * @return a description of the provider and its services.
    */
    string getInfo() {
        return info;
    }

    /**
    * Returns a string with the name and the version number
    * of this provider.
    *
    * @return the string with the name and the version number
    * for this provider.
    */
    override
    string toString() {
        return name ~ " version " ~ _version.to!string();
    }
}