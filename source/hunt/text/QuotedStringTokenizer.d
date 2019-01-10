/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2018-2019 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.text.QuotedStringTokenizer;

import std.conv;
import std.ascii;
import std.string;

import hunt.collection.Appendable;
import hunt.collection.StringBuffer;
import hunt.text.StringTokenizer;
import hunt.text.Common;
import hunt.text.StringBuilder;
import hunt.Exceptions;
import hunt.util.TypeUtils;


/**
 * StringTokenizer with Quoting support.
 *
 * This class is a copy of the java.util.StringTokenizer API and the behaviour
 * is the same, except that single and double quoted string values are
 * recognised. Delimiters within quotes are not considered delimiters. Quotes
 * can be escaped with '\'.
 *
 * @see java.util.StringTokenizer
 *
 */
class QuotedStringTokenizer : StringTokenizer {
	private enum string __delim = "\t\n\r";
	private string _string;
	private string _delim = __delim;
	private bool _returnQuotes = false;
	private bool _returnDelimiters = false;
	private StringBuffer _token;
	private bool _hasToken = false;
	private int _i = 0;
	private int _lastStart = 0;
	private bool _double = true;
	private bool _single = true;

	this(string str, string delim, bool returnDelimiters, bool returnQuotes) {
		super("");
		_string = str;
		if (delim !is null)
			_delim = delim;
		_returnDelimiters = returnDelimiters;
		_returnQuotes = returnQuotes;

		if (_delim.indexOf('\'') >= 0 || _delim.indexOf('"') >= 0)
			throw new Error("Can't use quotes as delimiters: " ~ _delim);

		_token = new StringBuffer(_string.length > 1024 ? 512 : _string.length / 2);
	}

	this(string str, string delim, bool returnDelimiters) {
		this(str, delim, returnDelimiters, false);
	}

	this(string str, string delim) {
		this(str, delim, false, false);
	}

	this(string str) {
		this(str, null, false, false);
	}

	override
	bool hasMoreTokens() {
		// Already found a token
		if (_hasToken)
			return true;

		_lastStart = _i;

		int state = 0;
		bool escape = false;
		while (_i < _string.length) {
			char c = _string.charAt(_i++);

			switch (state) {
			case 0: // Start
				if (_delim.indexOf(c) >= 0) {
					if (_returnDelimiters) {
						_token.append(c);
						return _hasToken = true;
					}
				} else if (c == '\'' && _single) {
					if (_returnQuotes)
						_token.append(c);
					state = 2;
				} else if (c == '\"' && _double) {
					if (_returnQuotes)
						_token.append(c);
					state = 3;
				} else {
					_token.append(c);
					_hasToken = true;
					state = 1;
				}
				break;

			case 1: // Token
				_hasToken = true;
				if (_delim.indexOf(c) >= 0) {
					if (_returnDelimiters)
						_i--;
					return _hasToken;
				} else if (c == '\'' && _single) {
					if (_returnQuotes)
						_token.append(c);
					state = 2;
				} else if (c == '\"' && _double) {
					if (_returnQuotes)
						_token.append(c);
					state = 3;
				} else {
					_token.append(c);
				}
				break;

			case 2: // Single Quote
				_hasToken = true;
				if (escape) {
					escape = false;
					_token.append(c);
				} else if (c == '\'') {
					if (_returnQuotes)
						_token.append(c);
					state = 1;
				} else if (c == '\\') {
					if (_returnQuotes)
						_token.append(c);
					escape = true;
				} else {
					_token.append(c);
				}
				break;

			case 3: // Double Quote
				_hasToken = true;
				if (escape) {
					escape = false;
					_token.append(c);
				} else if (c == '\"') {
					if (_returnQuotes)
						_token.append(c);
					state = 1;
				} else if (c == '\\') {
					if (_returnQuotes)
						_token.append(c);
					escape = true;
				} else {
					_token.append(c);
				}
				break;

            default:
                break;
			}
		}

		return _hasToken;
	}

	override
	string nextToken() {
		if (!hasMoreTokens() || _token is null)
			throw new NoSuchElementException("");
		string t = _token.toString();
		_token.setLength(0);
		_hasToken = false;
		return t;
	}

	override
	string nextToken(string delim) {
		_delim = delim;
		_i = _lastStart;
		_token.setLength(0);
		_hasToken = false;
		return nextToken();
	}


	/**
	 * Not implemented.
	 */
	override
	int countTokens() {
		return -1;
	}

	/**
	 * Quote a string. The string is quoted only if quoting is required due to
	 * embedded delimiters, quote characters or the empty string.
	 * 
	 * @param s
	 *            The string to quote.
	 * @param delim
	 *            the delimiter to use to quote the string
	 * @return quoted string
	 */
	static string quoteIfNeeded(string s, string delim) {
		if (s is null)
			return null;
		if (s.length == 0)
			return "\"\"";

		for (int i = 0; i < s.length; i++) {
			char c = s[i];
			if (c == '\\' || c == '"' || c == '\'' || std.ascii.isWhite(c) || delim.indexOf(c) >= 0) {
				StringBuffer b = new StringBuffer(s.length + 8);
				quote(b, s);
				return b.toString();
			}
		}

		return s;
	}

	/**
	 * Quote a string. The string is quoted only if quoting is required due to
	 * embeded delimiters, quote characters or the empty string.
	 * 
	 * @param s
	 *            The string to quote.
	 * @return quoted string
	 */
	static string quote(string s) {
		if (s is null)
			return null;
		if (s.length == 0)
			return "\"\"";

		StringBuffer b = new StringBuffer(s.length + 8);
		quote(b, s);
		return b.toString();

	}

	private __gshared char[] escapes; // = new char[32];

	shared static this() {
        // escapes[] = cast(char) 0xFFFF;
		escapes = new char[32];
		escapes[] = cast(char) 0xFF;
		// for(size_t i=0; i<escapes.length; i++)
		// 	escapes[i] = cast(char) 0xFFFF;
		escapes['\b'] = 'b';
		escapes['\t'] = 't';
		escapes['\n'] = 'n';
		escapes['\f'] = 'f';
		escapes['\r'] = 'r';
	}

	/**
	 * Quote a string into an Appendable. Only quotes and backslash are escaped.
	 * 
	 * @param buffer
	 *            The Appendable
	 * @param input
	 *            The string to quote.
	 */
	static void quoteOnly(Appendable buffer, string input) {
		if (input is null)
			return;

		try {
			buffer.append('"');
			for (int i = 0; i < input.length; ++i) {
				char c = input[i];
				if (c == '"' || c == '\\')
					buffer.append('\\');
				buffer.append(c);
			}
			buffer.append('"');
		} catch (IOException x) {
			throw new RuntimeException(x);
		}
	}

	/**
	 * Quote a string into an Appendable. The characters ", \, \n, \r, \t, \f
	 * and \b are escaped
	 * 
	 * @param buffer
	 *            The Appendable
	 * @param input
	 *            The string to quote.
	 */
	static void quote(Appendable buffer, string input) {
		if (input is null)
			return;

		try {
			buffer.append('"');
			for (int i = 0; i < input.length; ++i) {
				char c = input[i];
				if (c >= 32) {
					if (c == '"' || c == '\\')
						buffer.append('\\');
					buffer.append(c);
				} else {
					char escape = escapes[c];
					if (escape == 0xFFFF) {
						// Unicode escape
						buffer.append('\\').append('u').append('0').append('0');
						if (c < 0x10)
							buffer.append('0');
						buffer.append(to!string(cast(int)c, 16));
					} else {
						buffer.append('\\').append(escape);
					}
				}
			}
			buffer.append('"');
		} catch (IOException x) {
			throw new RuntimeException(x);
		}
	}

	static string unquoteOnly(string s) {
		return unquoteOnly(s, false);
	}

	/**
	 * Unquote a string, NOT converting unicode sequences
	 * 
	 * @param s
	 *            The string to unquote.
	 * @param lenient
	 *            if true, will leave in backslashes that aren't valid escapes
	 * @return quoted string
	 */
	static string unquoteOnly(string s, bool lenient) {
		if (s is null)
			return null;
		if (s.length < 2)
			return s;

		char first = s.charAt(0);
		char last = s.charAt(cast(int)s.length - 1);
		if (first != last || (first != '"' && first != '\''))
			return s;

		StringBuilder b = new StringBuilder(cast(int)s.length - 2);
		bool escape = false;
		for (int i = 1; i < s.length - 1; i++) {
			char c = s[i];

			if (escape) {
				escape = false;
				if (lenient && !isValidEscaping(c)) {
					b.append('\\');
				}
				b.append(c);
			} else if (c == '\\') {
				escape = true;
			} else {
				b.append(c);
			}
		}

		return b.toString();
	}

	static string unquote(string s) {
		return unquote(s, false);
	}

	/**
	 * Unquote a string.
	 * 
	 * @param s
	 *            The string to unquote.
	 * @param lenient
	 *            true if unquoting should be lenient to escaped content,
	 *            leaving some alone, false if string unescaping
	 * @return quoted string
	 */
	static string unquote(string s, bool lenient) {
		if (s is null)
			return null;
		if (s.length < 2)
			return s;

		char first = s.charAt(0);
		char last = s.charAt(cast(int)s.length - 1);
		if (first != last || (first != '"' && first != '\''))
			return s;

		StringBuilder b = new StringBuilder(cast(int)s.length - 2);
		bool escape = false;
		for (int i = 1; i < cast(int)s.length - 1; i++) {
			char c = s[i];

			if (escape) {
				escape = false;
				switch (c) {
				case 'n':
					b.append('\n');
					break;
				case 'r':
					b.append('\r');
					break;
				case 't':
					b.append('\t');
					break;
				case 'f':
					b.append('\f');
					break;
				case 'b':
					b.append('\b');
					break;
				case '\\':
					b.append('\\');
					break;
				case '/':
					b.append('/');
					break;
				case '"':
					b.append('"');
					break;
				case 'u':
					b.append(cast(char) ((TypeUtils.convertHexDigit(cast(byte) s.charAt(i++)) << 24)
							+ (TypeUtils.convertHexDigit(cast(byte) s.charAt(i++)) << 16)
							+ (TypeUtils.convertHexDigit(cast(byte) s.charAt(i++)) << 8)
							+ (TypeUtils.convertHexDigit(cast(byte) s.charAt(i++)))));
					break;
				default:
					if (lenient && !isValidEscaping(c)) {
						b.append('\\');
					}
					b.append(c);
				}
			} else if (c == '\\') {
				escape = true;
			} else {
				b.append(c);
			}
		}

		return b.toString();
	}

	/**
	 * Check that char c (which is preceded by a backslash) is a valid escape
	 * sequence.
	 * 
	 * @param c
	 * @return
	 */
	private static bool isValidEscaping(char c) {
		return ((c == 'n') || (c == 'r') || (c == 't') || (c == 'f') || (c == 'b') || (c == '\\') || (c == '/')
				|| (c == '"') || (c == 'u'));
	}

	static bool isQuoted(string s) {
		return s !is null && s.length > 0 && s.charAt(0) == '"' && s.charAt(cast(int)s.length - 1) == '"';
	}

	/**
	 * @return handle double quotes if true
	 */
	bool getDouble() {
		return _double;
	}

	/**
	 * @param d
	 *            handle double quotes if true
	 */
	void setDouble(bool d) {
		_double = d;
	}

	/**
	 * @return handle single quotes if true
	 */
	bool getSingle() {
		return _single;
	}

	/**
	 * @param single
	 *            handle single quotes if true
	 */
	void setSingle(bool single) {
		_single = single;
	}
}
