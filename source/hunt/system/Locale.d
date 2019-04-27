module hunt.system.Locale;

import hunt.Functions;
import hunt.logging.ConsoleLogger;

import core.stdc.locale;
import std.process;
import std.string;

// dfmt off
version(linux) {
    /*
     * Mappings from partial locale names to full locale names
     */    
	enum string[string] localeAliases = [
		"ar" : "ar_EG",
		"be" : "be_BY",
		"bg" : "bg_BG",
		"br" : "br_FR",
		"ca" : "ca_ES",
		"cs" : "cs_CZ",
		"cz" : "cs_CZ",
		"da" : "da_DK",
		"de" : "de_DE",
		"el" : "el_GR",
		"en" : "en_US",
		"eo" : "eo",    /* no country for Esperanto */
		"es" : "es_ES",
		"et" : "et_EE",
		"eu" : "eu_ES",
		"fi" : "fi_FI",
		"fr" : "fr_FR",
		"ga" : "ga_IE",
		"gl" : "gl_ES",
		"he" : "iw_IL",
		"hr" : "hr_HR",

		"hs" : "en_US", // used on Linux: not clear what it stands for

		"hu" : "hu_HU",
		"id" : "in_ID",
		"in" : "in_ID",
		"is" : "is_IS",
		"it" : "it_IT",
		"iw" : "iw_IL",
		"ja" : "ja_JP",
		"kl" : "kl_GL",
		"ko" : "ko_KR",
		"lt" : "lt_LT",
		"lv" : "lv_LV",
		"mk" : "mk_MK",
		"nl" : "nl_NL",
		"no" : "no_NO",
		"pl" : "pl_PL",
		"pt" : "pt_PT",
		"ro" : "ro_RO",
		"ru" : "ru_RU",
		"se" : "se_NO",
		"sk" : "sk_SK",
		"sl" : "sl_SI",
		"sq" : "sq_AL",
		"sr" : "sr_CS",
		"su" : "fi_FI",
		"sv" : "sv_SE",
		"th" : "th_TH",
		"tr" : "tr_TR",

		"ua" : "en_US", // used on Linux: not clear what it stands for

		"uk" : "uk_UA",
		"vi" : "vi_VN",
		"wa" : "wa_BE",
		"zh" : "zh_CN",

		"bokmal" : "nb_NO",
		"bokm\xE5l" : "nb_NO",
		"catalan" : "ca_ES",
		"croatian" : "hr_HR",
		"czech" : "cs_CZ",
		"danish" : "da_DK",
		"dansk" : "da_DK",
		"deutsch" : "de_DE",
		"dutch" : "nl_NL",
		"eesti" : "et_EE",
		"estonian" : "et_EE",
		"finnish" : "fi_FI",
		"fran\xE7\x61is" : "fr_FR",
		"french" : "fr_FR",
		"galego" : "gl_ES",
		"galician" : "gl_ES",
		"german" : "de_DE",
		"greek" : "el_GR",
		"hebrew" : "iw_IL",
		"hrvatski" : "hr_HR",
		"hungarian" : "hu_HU",
		"icelandic" : "is_IS",
		"italian" : "it_IT",
		"japanese" : "ja_JP",
		"korean" : "ko_KR",
		"lithuanian" : "lt_LT",
		"norwegian" : "no_NO",
		"nynorsk" : "nn_NO",
		"polish" : "pl_PL",
		"portuguese" : "pt_PT",
		"romanian" : "ro_RO",
		"russian" : "ru_RU",
		"slovak" : "sk_SK",
		"slovene" : "sl_SI",
		"slovenian" : "sl_SI",
		"spanish" : "es_ES",
		"swedish" : "sv_SE",
		"thai" : "th_TH",
		"turkish" : "tr_TR"
	];


    /*
     * Linux/Solaris language string to ISO639 string mapping table.
     */
    enum string[string] languageNames = [
        "C" : "en",
        "POSIX" : "en",
        "cz" : "cs",
        "he" : "iw",

        "hs" : "en",  // used on Linux : not clear what it stands for

        "id" : "in",
        "sh" : "sr",  // sh is deprecated
        "su" : "fi",

        "ua" : "en",  // used on Linux : not clear what it stands for

        "catalan" : "ca",
        "croatian" : "hr",
        "czech" : "cs",
        "danish" : "da",
        "dansk" : "da",
        "deutsch" : "de",
        "dutch" : "nl",
        "finnish" : "fi",
        "fran\xE7\x61is" : "fr",
        "french" : "fr",
        "german" : "de",
        "greek" : "el",
        "hebrew" : "he",
        "hrvatski" : "hr",
        "hungarian" : "hu",
        "icelandic" : "is",
        "italian" : "it",
        "japanese" : "ja",
        "norwegian" : "no",
        "polish" : "pl",
        "portuguese" : "pt",
        "romanian" : "ro",
        "russian" : "ru",
        "slovak" : "sk",
        "slovene" : "sl",
        "slovenian" : "sl",
        "spanish" : "es",
        "swedish" : "sv",
        "turkish" : "tr"
    ];

    /*
     * Linux/Solaris script string to Java script name mapping table.
     */
    enum string[string] scriptNames = [
        "cyrillic" : "Cyrl",
        "devanagari" : "Deva",
        "iqtelif" : "Latn",
        "latin" : "Latn",
        "Arab" : "Arab",
        "Cyrl" : "Cyrl",
        "Deva" : "Deva",
        "Ethi" : "Ethi",
        "Hans" : "Hans",
        "Hant" : "Hant",
        "Latn" : "Latn",
        "Sund" : "Sund",
        "Syrc" : "Syrc",
        "Tfng" : "Tfng"
    ];

    /*
     * Linux/Solaris country string to ISO3166 string mapping table.
     */
    enum string[string] countryNames = [
        "RN" : "US", // used on Linux : not clear what it stands for
        "YU" : "CS"  // YU has been removed from ISO 3166
    ];    

 } else {
	enum string[string] localeAliases = [
		"ar" : "ar_EG",
		"be" : "be_BY",
		"bg" : "bg_BG",
		"br" : "br_FR",
		"ca" : "ca_ES",
		"cs" : "cs_CZ",
		"cz" : "cs_CZ",
		"da" : "da_DK",
		"de" : "de_DE",
		"el" : "el_GR",
		"en" : "en_US",
		"eo" : "eo",    /* no country for Esperanto */
		"es" : "es_ES",
		"et" : "et_EE",
		"eu" : "eu_ES",
		"fi" : "fi_FI",
		"fr" : "fr_FR",
		"ga" : "ga_IE",
		"gl" : "gl_ES",
		"he" : "iw_IL",
		"hr" : "hr_HR",
		
		"hu" : "hu_HU",
		"id" : "in_ID",
		"in" : "in_ID",
		"is" : "is_IS",
		"it" : "it_IT",
		"iw" : "iw_IL",
		"ja" : "ja_JP",
		"kl" : "kl_GL",
		"ko" : "ko_KR",
		"lt" : "lt_LT",
		"lv" : "lv_LV",
		"mk" : "mk_MK",
		"nl" : "nl_NL",
		"no" : "no_NO",
		"pl" : "pl_PL",
		"pt" : "pt_PT",
		"ro" : "ro_RO",
		"ru" : "ru_RU",
		"se" : "se_NO",
		"sk" : "sk_SK",
		"sl" : "sl_SI",
		"sq" : "sq_AL",
		"sr" : "sr_CS",
		"su" : "fi_FI",
		"sv" : "sv_SE",
		"th" : "th_TH",
		"tr" : "tr_TR",

		"uk" : "uk_UA",
		"vi" : "vi_VN",
		"wa" : "wa_BE",
		"zh" : "zh_CN",

		"big5" : "zh_TW.Big5",
		"chinese" : "zh_CN",
		"iso_8859_1" : "en_US.ISO8859-1",
		"iso_8859_15" : "en_US.ISO8859-15",
		"japanese" : "ja_JP",
		"no_NY" : "no_NO@nynorsk",
		"sr_SP" : "sr_YU",
		"tchinese" : "zh_TW"
 	]; 


    /*
     * Linux/Solaris language string to ISO639 string mapping table.
     */
    string[string] languageNames = [
        "C" : "en",
        "POSIX" : "en",
        "cz" : "cs",
        "he" : "iw",

        "id" : "in",
        "sh" : "sr", // sh is deprecated
        "su" : "fi",

        "chinese" : "zh",
        "japanese" : "ja",
        "korean" : "ko"
    ];

    /*
     * Linux/Solaris script string to Java script name mapping table.
     */
    enum string[string] scriptNames = [
        "Arab" : "Arab",
        "Cyrl" : "Cyrl",
        "Deva" : "Deva",
        "Ethi" : "Ethi",
        "Hans" : "Hans",
        "Hant" : "Hant",
        "Latn" : "Latn",
        "Sund" : "Sund",
        "Syrc" : "Syrc",
        "Tfng" : "Tfng"
    ];

    /*
     * Linux/Solaris country string to ISO3166 string mapping table.
     */
    enum string[string] countryNames = [
        "YU" : "CS"  // YU has been removed from ISO 3166
    ];     
 }

/*
 * Linux/Solaris variant string to Java variant name mapping table.
 */
enum string[string] variantNames = [
    "nynorsk" : "NY",
];

// dfmt on

enum LocaleCategory {
    ALL = LC_ALL,
    COLLATE = LC_COLLATE,
    CTYPE = LC_CTYPE,
    MONETARY  = LC_MONETARY,
    NUMERIC = LC_NUMERIC,
    TIME = LC_TIME,
    MESSAGES = LC_MESSAGES
}

/**
see_also:
    https://linux.die.net/man/3/setlocale
*/
class Locale {
    string language;
    string country;
    string script;
    string variant;
    string encoding;

    static string set(LocaleCategory cat, string locale="") {
        char* p = setlocale(cast(int)cat, locale.toStringz());
        return cast(string)fromStringz(p);
    }


    static Locale parse(LocaleCategory cat) {
        string std_language, std_country, std_encoding, std_script, std_variant;
        char* lc = setlocale(cast(int)cat, null);
        if(lc is null) {
            return null;
        }


        string lcString = cast(string)fromStringz(lc);
        version(HUNT_DEBUG) tracef("category=%s, locale: %s", cat, lcString);

        // lcString = "zh_CN.UTF-8@nynorsk";  // for test
        if(lcString.empty || lcString == "C" || lcString == "POSIX") {
            lcString = "en_US";
        }
        string temp = lcString;

        /*
         * locale string format in Solaris is
         * <language name>_<country name>.<encoding name>@<variant name>
         * <country name>, <encoding name>, and <variant name> are optional.
         */

        /* Parse the language, country, encoding, and variant from the
         * locale.  Any of the elements may be missing, but they must occur
         * in the order language_country.encoding@variant, and must be
         * preceded by their delimiter (except for language).
         *
         * If the locale name (without .encoding@variant, if any) matches
         * any of the names in the locale_aliases list, map it to the
         * corresponding full locale name.  Most of the entries in the
         * locale_aliases list are locales that include a language name but
         * no country name, and this facility is used to map each language
         * to a default country if that's possible.  It's also used to map
         * the Solaris locale aliases to their proper Java locale IDs.
         */ 
        
        string encoding_variant;
        /* Copy the leading '.' */
        ptrdiff_t index = lcString.indexOf('.');
        if(index == -1) {
            /* Copy the leading '@' */
            index = lcString.indexOf('@'); 
        }
    
        if(index >= 0) {
            encoding_variant = lcString[index .. $];
            temp = lcString[0..index];
        }

        string language = temp;
        if(!temp.empty && localeAliases.hasKey(temp)) {
            language = localeAliases[temp];
            // check the "encoding_variant" again, if any.
            index = language.indexOf('.');
            if(index == -1) {
                /* Copy the leading '@' */
                index = language.indexOf('@'); 
            }

            if(index >= 0) {
                encoding_variant = language[index .. $];
                language = language[0 .. index];
            }
        } 

        // 
        string country;
        index = language.indexOf('_');
        if(index >= 0) {
            country = language[index+1 .. $];
            language = language[0..index];
        }

        // 
        string encoding;
        index = encoding_variant.indexOf('.');
        if(index >= 0) {
            encoding = encoding_variant[index+1 .. $];
        }

        // 
        string variant;
        index = encoding.indexOf('@');
        if(index >= 0) {
            variant = encoding[index+1 .. $];
            encoding = encoding[0 .. index];
        }

        version(HUNT_DEBUG) {
            tracef("language=%s, country=%s, variant=%s, encoding=%s", 
                language, country, variant, encoding);
        }

        /* Normalize the language name */
        if(language.empty() ) {
            std_language = "en";
        } else if(languageNames.hasKey(language)) {
            std_language = languageNames[language];
        } else {
            std_language = language;
        }

        /* Normalize the country name */
        if(!country.empty()) {
            if(countryNames.hasKey(country)) {
                std_country= countryNames[country];
            } else {
                std_country = country;
            }
        }

        /* Normalize the script and variant name.  Note that we only use
         * variants listed in the mapping array; others are ignored.
         */
        if(scriptNames.hasKey(variant))
            std_script = scriptNames[variant];
            
        if(variantNames.hasKey(variant))
            std_variant = variantNames[variant];

        /* Normalize the encoding name.  Note that we IGNORE the string
         * 'encoding' extracted from the locale name above.  Instead, we use the
         * more reliable method of calling nl_langinfo(CODESET).  This function
         * returns an empty string if no encoding is set for the given locale
         * (e.g., the C or POSIX locales); we use the default ISO 8859-1
         * converter for such locales.
         */

        /* OK, not so reliable - nl_langinfo() gives wrong answers on
         * Euro locales, in particular. */
        string p = encoding;
        if (p != "ISO8859-15") {
            char * _p = nl_langinfo(CODESET); 
            p = cast(string)fromStringz(_p);
        }       
        /* Convert the bare "646" used on Solaris to a proper IANA name */
        if (p == "646")
            p = "ISO646-US";            

        /* return same result nl_langinfo would return for en_UK,
         * in order to use optimizations. */
        if(p.empty)
            std_encoding = "ISO8859-1";
        else
            std_encoding = p;

        version(linux) {
            /*
             * Remap the encoding string to a different value for japanese
             * locales on linux so that customized converters are used instead
             * of the default converter for "EUC-JP". The customized converters
             * omit support for the JIS0212 encoding which is not supported by
             * the variant of "EUC-JP" encoding used on linux
             */            
            if (p == "EUC-JP") std_encoding = "EUC-JP-LINUX";
        } else {
            if (p == "eucJP") {
                /* For Solaris use customized vendor defined character
                 * customized EUC-JP converter
                 */
                std_encoding = "eucJP-open";
            } else if (p == "Big5" || p == "BIG5") {
                /*
                 * Remap the encoding string to Big5_Solaris which augments
                 * the default converter for Solaris Big5 locales to include
                 * seven additional ideographic characters beyond those included
                 * in the Java "Big5" converter.
                 */
                std_encoding = "Big5_Solaris";
            } else if (p == "Big5-HKSCS") {
                /*
                 * Solaris uses HKSCS2001
                 */
                std_encoding = "Big5-HKSCS-2001";
            }
        }

        version(OSX) {
            /*
             * For the case on MacOS X where encoding is set to US-ASCII, but we
             * don't have any encoding hints from LANG/LC_ALL/LC_CTYPE, use UTF-8
             * instead.
             *
             * The contents of ASCII files will still be read and displayed
             * correctly, but so will files containing UTF-8 characters beyond the
             * standard ASCII range.
             *
             * Specifically, this allows apps launched by double-clicking a .jar
             * file to correctly read UTF-8 files using the default encoding (see
             * 8011194).
             */
            string lang = environment.get("LANG", "");
            string lcall = environment.get("LC_ALL", "");
            string lctype = environment.get("LC_CTYPE", "");
            if (p == "US-ASCII" && lang.empty() &&
                lcall.empty() && lctype.empty()) {
                std_encoding = "UTF-8";
            }            
        }

        Locale locale = new Locale();
        locale.language = std_language;
        locale.country = std_country;
        locale.encoding = std_encoding;
        locale.variant = std_variant;
        locale.script = std_script;

        return locale;
    }
}

enum _NL_CTYPE_CODESET_NAME = 14;
alias CODESET = _NL_CTYPE_CODESET_NAME;

extern(C) {
    char * nl_langinfo (int __item);
}