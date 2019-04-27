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
            this.props = new ConfigBuilder(fileName, defaultSettingSection);
        } else {
            this.props = new ConfigBuilder();
        }

        initializeNativeProperties();
    }

    private static void initializeNativeProperties() {
        /* Determine the language, country, variant, and encoding from the host,
         * and store these in the user.language, user.country, user.variant and
         * file.encoding system properties. */
        string localeString = Locale.set(LocaleCategory.ALL);
        version (HUNT_DEBUG) {
            tracef("Locale(ALL):%s ", localeString);
        }
        Locale le = Locale.parse(LocaleCategory.MESSAGES);
        if (le !is null) {
            if (!props.hasProperty("user.language")) {
                props.setProperty("user.language", le.language);
            }
            if (!props.hasProperty("user.country")) {
                props.setProperty("user.country", le.country);
            }
            if (!props.hasProperty("user.variant")) {
                props.setProperty("user.variant", le.variant);
            }
            if (!props.hasProperty("user.encoding")) {
                props.setProperty("user.encoding", le.encoding);
            }
            if (!props.hasProperty("user.script")) {
                props.setProperty("user.script", le.script);
            }
        }
    }

}
