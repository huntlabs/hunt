module hunt.system.Environment;

import hunt.logging.ConsoleLogger;
import hunt.system.Locale;
import hunt.util.Configuration;

import core.stdc.locale;
import core.stdc.string;

import std.file;
import std.path;
import std.string;

struct Environment {

    __gshared string defaultConfigFile = "hunt.config";
    __gshared string defaultSettingSection = "";

    static ConfigBuilder getProperties() {
        if (props is null) {
            initializeProperties();
        }
        return props;
    }

    static void setProperties(ConfigBuilder props) {
        if (props is null) {
            initializeProperties();
        } else {
            this.props = props;
        }
    }

    private __gshared ConfigBuilder props;

    private static void initializeProperties() {
        string rootPath = dirName(thisExePath());
        string fileName = buildPath(rootPath, defaultConfigFile);
        if (exists(fileName)) {
            if(isDir(fileName)) {
                    throw new Exception("You can't load config from a directory: " ~ fileName);
            } else {
                this.props = new ConfigBuilder(fileName, defaultSettingSection);
            }
        } else {
            this.props = new ConfigBuilder();
        }

        initializeNativeProperties();
    }

// dfmt off
    private static void setupI18nBaseProperties(Locale locale) {
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
    
    private static void initializeNativeProperties() {
        /* Determine the language, country, variant, and encoding from the host,
         * and store these in the user.language, user.country, user.variant and
         * file.encoding system properties. */
        setupI18nBaseProperties(Locale.getUserDefault());
    }
// dfmt on

}
