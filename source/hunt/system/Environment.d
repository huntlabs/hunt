module hunt.system.Environment;

import hunt.Exceptions;
import hunt.logging.ConsoleLogger;
import hunt.system.Locale;
import hunt.util.Configuration;

import core.stdc.locale;
import core.stdc.string;

import std.concurrency : initOnce;
import std.file;
import std.path;
import std.string;

struct Environment {

    __gshared string defaultConfigFile = "hunt.config";
    __gshared string defaultSettingSection = "";

    private __gshared ConfigBuilder _props;

    static ConfigBuilder getProperties() {
        if (_props is null) {
            return initOnce!(_props)({
                ConfigBuilder props;
                string rootPath = dirName(thisExePath());
                string fileName = buildPath(rootPath, defaultConfigFile);
                if (exists(fileName)) {
                    if(isDir(fileName)) {
                            throw new Exception("You can't load config from a directory: " ~ fileName);
                    } else {
                        props = new ConfigBuilder(fileName, defaultSettingSection);
                    }
                } else {
                    props = new ConfigBuilder();
                }
                initializeProperties(props);
                return props;
            }());
        } else {
            return _props;
        }
    }

    static void setProperties(ConfigBuilder props) {
        if (props is null) {
            throw new NullPointerException();
        } else {
            this._props = props;
        }
    }

    private static void initializeProperties(ConfigBuilder props) {
        /* Determine the language, country, variant, and encoding from the host,
         * and store these in the user.language, user.country, user.variant and
         * file.encoding system properties. */
        setupI18nBaseProperties(props, Locale.getUserDefault());
    }

// dfmt off
    private static void setupI18nBaseProperties(ConfigBuilder props, Locale locale) {
        if (locale !is null) {
            if (!props.hasProperty("user.language") && locale.language !is null) {
                props.setProperty("user.language", locale.language);
            }
            if (!props.hasProperty("user.country") && locale.country !is null) {
                props.setProperty("user.country", locale.country);
            }
            if (!props.hasProperty("user.variant") && locale.variant !is null) {
                props.setProperty("user.variant", locale.variant);
            }
            if (!props.hasProperty("user.script") && locale.script !is null) {
                props.setProperty("user.script", locale.script);
            }
            if (!props.hasProperty("user.encoding") && locale.encoding !is null) {
                props.setProperty("user.encoding", locale.encoding);
            }
        } else {
            if (!props.hasProperty("user.language"))
                props.setProperty("user.language", "en");
            if (!props.hasProperty("user.encoding"))
                props.setProperty("user.encoding", "ISO8859-1");
        }
    }
    
// dfmt on

}
