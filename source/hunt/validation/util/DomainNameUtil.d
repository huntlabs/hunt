/*
 * Hunt - Hunt is a high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design. It lets you build high-performance Web applications quickly and easily.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Website: www.huntframework.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */
module hunt.validation.util.DomainNameUtil;

import std.algorithm.searching;
import std.regex;
import std.string;

class DomainNameUtil {

	/**
	 * This is the maximum length of a domain name. But be aware that each label (parts separated by a dot) of the
	 * domain name must be at most 63 characters long. This is verified by {@link IDN#toASCII(string)}.
	 */
	private static const int MAX_DOMAIN_PART_LENGTH = 255;

	private static const string DOMAIN_CHARS_WITHOUT_DASH = "[a-z\u0080-\uFFFF0-9!#$%&'*+/=?^_`{|}~]";
	private static const string DOMAIN_LABEL = "(" ~ DOMAIN_CHARS_WITHOUT_DASH ~ "-*)*" ~ DOMAIN_CHARS_WITHOUT_DASH ~ "+";
	private static const string DOMAIN = DOMAIN_LABEL ~ "+(\\." ~ DOMAIN_LABEL ~ "+)*";

	private static const string IP_DOMAIN = "[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}";
	//IP v6 regex taken from http://stackoverflow.com/questions/53497/regular-expression-that-matches-valid-ipv6-addresses
	private static const string IP_V6_DOMAIN = "(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))";

	/**
	 * Regular expression for the domain part of an URL
	 * <p>
	 * A host string must be a domain string, an IPv4 address string, or "[", followed by an IPv6 address string,
	 * followed by "]".
	 */
	private static const string DOMAIN_PATTERN = 
			DOMAIN ~ "|\\[" ~ IP_V6_DOMAIN ~ "\\]";

	/**
	 * Regular expression for the domain part of an email address (everything after '@')
	 */
	private static const string EMAIL_DOMAIN_PATTERN = 
			DOMAIN ~ "|\\[" ~ IP_DOMAIN ~ "\\]|" ~ "\\[IPv6:" ~ IP_V6_DOMAIN ~ "\\]";

	private this() {
	}

	/**
	 * Checks the validity of the domain name used in an email. To be valid it should be either a valid host name, or an
	 * IP address wrapped in [].
	 *
	 * @param domain domain to check for validity
	 * @return {@code true} if the provided string is a valid domain, {@code false} otherwise
	 */
	public static bool isValidEmailDomainAddress(string domain) {
		return isValidDomainAddress( domain, EMAIL_DOMAIN_PATTERN );
	}

	/**
	 * Checks validity of a domain name.
	 *
	 * @param domain the domain to check for validity
	 * @return {@code true} if the provided string is a valid domain, {@code false} otherwise
	 */
	public static bool isValidDomainAddress(string domain) {
		return isValidDomainAddress( domain, DOMAIN_PATTERN );
	}

	private static bool isValidDomainAddress(string domain, string pattern) {
		// if we have a trailing dot the domain part we have an invalid email address.
		// the regular expression match would take care of this, but IDN.toASCII drops the trailing '.'
		if ( domain.endsWith( "." ) ) {
			return false;
		}

		auto matcher = matchAll( domain , regex(pattern));
		if ( matcher.empty() ) {
			return false;
		}

		

		if ( domain.length > MAX_DOMAIN_PART_LENGTH ) {
			return false;
		}

		return true;
	}

}