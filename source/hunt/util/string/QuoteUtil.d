module hunt.util.string.QuoteUtil;

import hunt.util.exception;
import hunt.util.string;

import std.ascii;
import std.conv;
import std.range;
import std.string;


/**
 * Provide some consistent Http header value and Extension configuration parameter quoting support.
 * <p>
 * While QuotedStringTokenizer exists in the utils, and works great with http header values, using it in websocket-api is undesired.
 * <ul>
 * <li>Using QuotedStringTokenizer would introduce a dependency to the utils that would need to be exposed via the WebAppContext classloader</li>
 * <li>ABNF defined extension parameter parsing requirements of RFC-6455 (WebSocket) ABNF, is slightly different than the ABNF parsing defined in RFC-2616
 * (HTTP/1.1).</li>
 * <li>Future HTTPbis ABNF changes for parsing will impact QuotedStringTokenizer</li>
 * </ul>
 * It was decided to keep this implementation separate for the above reasons.
 */
class QuoteUtil {
    private static class DeQuotingStringIterator : InputRange!string { 
        private enum State {
            START,
            TOKEN,
            QUOTE_SINGLE,
            QUOTE_DOUBLE
        }

        private string input;
        private string delims;
        private StringBuilder token;
        private bool hasToken = false;
        private int i = 0;

        this(string input, string delims) {
            this.input = input;
            this.delims = delims;
            size_t len = input.length;
            token = new StringBuilder(len > 1024 ? 512 : len / 2);

            popFront();
        }

        private void appendToken(char c) {
            if (hasToken) {
                token.append(c);
            } else {
                if (isWhite(c)) {
                    return; // skip whitespace at start of token.
                } else {
                    token.append(c);
                    hasToken = true;
                }
            }
        }

        bool empty() {
            return !hasToken;
        }

        string front() @property { 
            if (!hasToken) {
                throw new NoSuchElementException();
            }
            string ret = token.toString();
            return QuoteUtil.dequote(ret.strip());
         }

        void popFront() {
            token.setLength(0);
            hasToken = false;

            State state = State.START;
            bool escape = false;
            size_t inputLen = input.length;

            while (i < inputLen) {
                char c = input[i++];

                switch (state) {
                    case State.START: {
                        if (c == '\'') {
                            state = State.QUOTE_SINGLE;
                            appendToken(c);
                        } else if (c == '\"') {
                            state = State.QUOTE_DOUBLE;
                            appendToken(c);
                        } else {
                            appendToken(c);
                            state = State.TOKEN;
                        }
                        break;
                    }
                    case State.TOKEN: {
                        if (delims.indexOf(c) >= 0) {
                            // System.out.printf("hasNext/t: %b [%s]%n",hasToken,token);
                            // return hasToken;
                            return;
                        } else if (c == '\'') {
                            state = State.QUOTE_SINGLE;
                        } else if (c == '\"') {
                            state = State.QUOTE_DOUBLE;
                        }
                        appendToken(c);
                        break;
                    }
                    case State.QUOTE_SINGLE: {
                        if (escape) {
                            escape = false;
                            appendToken(c);
                        } else if (c == '\'') {
                            appendToken(c);
                            state = State.TOKEN;
                        } else if (c == '\\') {
                            escape = true;
                        } else {
                            appendToken(c);
                        }
                        break;
                    }
                    case State.QUOTE_DOUBLE: {
                        if (escape) {
                            escape = false;
                            appendToken(c);
                        } else if (c == '\"') {
                            appendToken(c);
                            state = State.TOKEN;
                        } else if (c == '\\') {
                            escape = true;
                        } else {
                            appendToken(c);
                        }
                        break;
                    }

                    default: break;
                }
                // System.out.printf("%s <%s> : [%s]%n",state,c,token);
            }
        }


        int opApply(scope int delegate(string) dg) {
            if(dg is null)
                throw new NullPointerException("");
            int result = 0;
            while(hasToken && result == 0) {
                result = dg(front());
                popFront();
            }
            return result;
        }

        int opApply(scope int delegate(size_t, string) dg) {
            if(dg is null)
                throw new NullPointerException("");
            int result = 0;          
            size_t index = 0;
            while(hasToken && result == 0) {
                result = dg(index++, front());
                popFront();
            }
            return result;
        }

        string moveFront() {
            throw new UnsupportedOperationException("Remove not supported with this iterator");
        }

/++
        // override
        bool hasNext() {
            // already found a token
            if (hasToken) {
                return true;
            }

            State state = State.START;
            bool escape = false;
            size_t inputLen = input.length;

            while (i < inputLen) {
                char c = input.charAt(i++);

                switch (state) {
                    case State.START: {
                        if (c == '\'') {
                            state = State.QUOTE_SINGLE;
                            appendToken(c);
                        } else if (c == '\"') {
                            state = State.QUOTE_DOUBLE;
                            appendToken(c);
                        } else {
                            appendToken(c);
                            state = State.TOKEN;
                        }
                        break;
                    }
                    case State.TOKEN: {
                        if (delims.indexOf(c) >= 0) {
                            // System.out.printf("hasNext/t: %b [%s]%n",hasToken,token);
                            return hasToken;
                        } else if (c == '\'') {
                            state = State.QUOTE_SINGLE;
                        } else if (c == '\"') {
                            state = State.QUOTE_DOUBLE;
                        }
                        appendToken(c);
                        break;
                    }
                    case State.QUOTE_SINGLE: {
                        if (escape) {
                            escape = false;
                            appendToken(c);
                        } else if (c == '\'') {
                            appendToken(c);
                            state = State.TOKEN;
                        } else if (c == '\\') {
                            escape = true;
                        } else {
                            appendToken(c);
                        }
                        break;
                    }
                    case State.QUOTE_DOUBLE: {
                        if (escape) {
                            escape = false;
                            appendToken(c);
                        } else if (c == '\"') {
                            appendToken(c);
                            state = State.TOKEN;
                        } else if (c == '\\') {
                            escape = true;
                        } else {
                            appendToken(c);
                        }
                        break;
                    }

                    default: break;
                }
                // System.out.printf("%s <%s> : [%s]%n",state,c,token);
            }
            // System.out.printf("hasNext/e: %b [%s]%n",hasToken,token);
            return hasToken;
        }

        // override
        string next() {
            if (!hasNext()) {
                throw new NoSuchElementException();
            }
            string ret = token.toString();
            token.setLength(0);
            hasToken = false;
            return QuoteUtil.dequote(ret.strip());
        }
++/
    }

    /**
     * ABNF from RFC 2616, RFC 822, and RFC 6455 specified characters requiring quoting.
     */
    enum string ABNF_REQUIRED_QUOTING = "\"'\\\n\r\t\f\b%+ ;=";

    private enum char UNICODE_TAG = cast(char)0xFF;
    private __gshared char[] escapes;

    shared static this() {
        escapes = new char[32];
        escapes[] = UNICODE_TAG;
        // non-unicode
        escapes['\b'] = 'b';
        escapes['\t'] = 't';
        escapes['\n'] = 'n';
        escapes['\f'] = 'f';
        escapes['\r'] = 'r';
    }

    private static int dehex(byte b) {
        if ((b >= '0') && (b <= '9')) {
            return cast(byte) (b - '0');
        }
        if ((b >= 'a') && (b <= 'f')) {
            return cast(byte) ((b - 'a') + 10);
        }
        if ((b >= 'A') && (b <= 'F')) {
            return cast(byte) ((b - 'A') + 10);
        }
        throw new IllegalArgumentException("!hex:" ~ to!string(0xff & b, 16));
    }

    /**
     * Remove quotes from a string, only if the input string start with and end with the same quote character.
     *
     * @param str the string to remove surrounding quotes from
     * @return the de-quoted string
     */
    static string dequote(string str) {
        char start = str[0];
        if ((start == '\'') || (start == '\"')) {
            // possibly quoted
            char end = str[$ - 1];
            if (start == end) {
                // dequote
                return str[1 .. $-1];
            }
        }
        return str;
    }

    static void escape(StringBuilder buf, string str) {
        foreach (char c ; str) {
            if (c >= 32) {
                // non special character
                if ((c == '"') || (c == '\\')) {
                    buf.append('\\');
                }
                buf.append(c);
            } else {
                // special characters, requiring escaping
                char escaped = escapes[c];

                // is this a unicode escape?
                if (escaped == UNICODE_TAG) {
                    buf.append("\\u00");
                    if (c < 0x10) {
                        buf.append('0');
                    }
                    buf.append(to!string(cast(int)c, 16)); // hex
                } else {
                    // normal escape
                    buf.append('\\').append(escaped);
                }
            }
        }
    }

    /**
     * Simple quote of a string, escaping where needed.
     *
     * @param buf the StringBuilder to append to
     * @param str the string to quote
     */
    static void quote(StringBuilder buf, string str) {
        buf.append('"');
        escape(buf, str);
        buf.append('"');
    }

    /**
     * Append into buf the provided string, adding quotes if needed.
     * <p>
     * Quoting is determined if any of the characters in the <code>delim</code> are found in the input <code>str</code>.
     *
     * @param buf   the buffer to append to
     * @param str   the string to possibly quote
     * @param delim the delimiter characters that will trigger automatic quoting
     */
    static void quoteIfNeeded(StringBuilder buf, string str, string delim) {
        if (str is null) {
            return;
        }
        // check for delimiters in input string
        size_t len = str.length;
        if (len == 0) {
            return;
        }
        int ch;
        for (size_t i = 0; i < len; i++) {
            // ch = str.codePointAt(i);
            ch = str[i];
            if (delim.indexOf(ch) >= 0) {
                // found a delimiter codepoint. we need to quote it.
                quote(buf, str);
                return;
            }
        }

        // no special delimiters used, no quote needed.
        buf.append(str);
    }

    /**
     * Create an iterator of the input string, breaking apart the string at the provided delimiters, removing quotes and triming the parts of the string as
     * needed.
     *
     * @param str    the input string to split apart
     * @param delims the delimiter characters to split the string on
     * @return the iterator of the parts of the string, trimmed, with quotes around the string part removed, and unescaped
     */
    static InputRange!string splitAt(string str, string delims) {
        return new DeQuotingStringIterator(str.strip(), delims);
    }

    static string unescape(string str) {
        if (str is null) {
            // nothing there
            return null;
        }

        size_t len = str.length;
        if (len <= 1) {
            // impossible to be escaped
            return str;
        }

        StringBuilder ret = new StringBuilder(len - 2);
        bool escaped = false;
        char c;
        for (size_t i = 0; i < len; i++) {
            c = str[i];
            if (escaped) {
                escaped = false;
                switch (c) {
                    case 'n':
                        ret.append('\n');
                        break;
                    case 'r':
                        ret.append('\r');
                        break;
                    case 't':
                        ret.append('\t');
                        break;
                    case 'f':
                        ret.append('\f');
                        break;
                    case 'b':
                        ret.append('\b');
                        break;
                    case '\\':
                        ret.append('\\');
                        break;
                    case '/':
                        ret.append('/');
                        break;
                    case '"':
                        ret.append('"');
                        break;
                    case 'u':
                        ret.append(cast(char) ((dehex(cast(byte) str[i++]) << 24) + 
                            (dehex(cast(byte) str[i++]) << 16) + 
                            (dehex(cast(byte) str[i++]) << 8) + 
                            (dehex(cast(byte) str[i++]))));
                        break;
                    default:
                        ret.append(c);
                }
            } else if (c == '\\') {
                escaped = true;
            } else {
                ret.append(c);
            }
        }
        return ret.toString();
    }

    // static string join(Object[] objs, string delim) {
    //     if (objs is null) {
    //         return "";
    //     }
    //     StringBuilder ret = new StringBuilder();
    //     int len = objs.length;
    //     for (int i = 0; i < len; i++) {
    //         if (i > 0) {
    //             ret.append(delim);
    //         }
    //         if (objs[i] instanceof string) {
    //             ret.append('"').append(objs[i]).append('"');
    //         } else {
    //             ret.append(objs[i]);
    //         }
    //     }
    //     return ret.toString();
    // }

    // static string join(Collection<?> objs, string delim) {
    //     if (objs is null) {
    //         return "";
    //     }
    //     StringBuilder ret = new StringBuilder();
    //     bool needDelim = false;
    //     foreach (Object obj ; objs) {
    //         if (needDelim) {
    //             ret.append(delim);
    //         }
    //         if (obj instanceof string) {
    //             ret.append('"').append(obj).append('"');
    //         } else {
    //             ret.append(obj);
    //         }
    //         needDelim = true;
    //     }
    //     return ret.toString();
    // }
}
