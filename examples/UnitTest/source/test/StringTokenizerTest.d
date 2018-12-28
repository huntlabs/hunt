module test.StringTokenizerTest;

import hunt.string.StringTokenizer;

import hunt.lang.exception;
import hunt.logging.ConsoleLogger;
import hunt.util.UnitTest;
import hunt.util.Assert;

alias assertTrue = Assert.assertTrue;
alias assertFalse = Assert.assertFalse;
alias assertThat = Assert.assertThat;
alias assertEquals = Assert.assertEquals;
alias assertNotNull = Assert.assertNotNull;
alias assertNull = Assert.assertNull;

import std.conv;

class StringTokenizerTest {

    void testFormFeed() {
      StringTokenizer st = new StringTokenizer("ABCD\tEFG\fHIJKLM PQR");

      if (st.countTokens() != 4)
         throw new RuntimeException("StringTokenizer does not treat form feed as whitespace.");
    }

    static void checkValue(string val, string checkVal) {
        trace("Comparing \"" ~ val ~ "\" <----> \"" ~ checkVal ~
                "\"");
        assert(val == checkVal, "Test failed");
    }

    void testResetPos() {
        // Simple test
        StringTokenizer st1 = new StringTokenizer("ab", "b", true);
        checkValue("a", st1.nextToken("b"));
        st1.hasMoreTokens();
        checkValue("b", st1.nextToken(""));

        // Test with retDelims set to true
        StringTokenizer st2 = new StringTokenizer("abcd efg", "abc", true);
        st2.hasMoreTokens();
        checkValue("a", st2.nextToken("bc"));
        st2.hasMoreTokens();
        checkValue("b", st2.nextToken());
        st2.hasMoreTokens();
        checkValue("cd", st2.nextToken(" ef"));
        st2.hasMoreTokens();
        checkValue(" ", st2.nextToken(" "));
        st2.hasMoreTokens();
        checkValue("ef", st2.nextToken("g"));
        st2.hasMoreTokens();
        checkValue("g", st2.nextToken("g"));

        // Test with changing delimiters
        StringTokenizer st3 = new StringTokenizer("this is,a interesting,sentence of small, words", ",");
        st3.hasMoreTokens();
        checkValue("this is", st3.nextToken()); // "this is"
        st3.hasMoreTokens();
        checkValue(",a", st3.nextToken(" "));   // ",a"
        st3.hasMoreTokens();
        checkValue(" interesting", st3.nextToken(",")); // " interesting"
        st3.hasMoreTokens();
        checkValue(",sentence", st3.nextToken(" ")); // ",sentence"
        st3.hasMoreTokens();
        checkValue(" of small", st3.nextToken(",")); // " of small"
        st3.hasMoreTokens();
        checkValue(" words", st3.nextToken()); // " words"
    }

// FIXME: Needing refactor or cleanup -@zxp at 12/28/2018, 2:58:49 PM
// 
    // void testSupplementary() {
    //     string text =
    //         "ab\uD800\uDC00\uD800\uDC01cd\uD800\uDC00\uD800xy \uD801\uDC00z\t123\uDCFF456";
    //     string delims = " \t\r\n\f.\uD800\uDC00,:;";
    //     string[] expected = ["ab", "\uD800\uDC01cd", "\uD800xy", "\uD801\uDC00z", "123\uDCFF456" ];
    //     _testTokenizer(text, delims, expected);

    //     delims = " \t\r\n\f.,:;\uDCFF";
    //     expected = ["ab\uD800\uDC00\uD800\uDC01cd\uD800\uDC00\uD800xy",
    //                               "\uD801\uDC00z",
    //                               "123",
    //                               "456" ];
    //     _testTokenizer(text, delims, expected);

    //     delims = "\uD800";
    //     expected = ["ab\uD800\uDC00\uD800\uDC01cd\uD800\uDC00",
    //                               "xy \uD801\uDC00z\t123\uDCFF456" ];
    //     _testTokenizer(text, delims, expected);
    // }

    // static void _testTokenizer(string text, string delims, string[] expected) {
    //     StringTokenizer tokenizer = new StringTokenizer(text, delims);
    //     int n = tokenizer.countTokens();
    //     if (n != expected.length) {
    //         throw new RuntimeException("countToken(): wrong value " + n
    //                                    ~ ", expected " ~ expected.length.to!string());
    //     }
    //     int i = 0;
    //     while (tokenizer.hasMoreTokens()) {
    //         string token = tokenizer.nextToken();
    //         if (!token.equals(expected[i++])) {
    //             throw new RuntimeException("nextToken(): wrong token. got \""
    //                                        ~ token ~ "\", expected \"" ~ expected[i-1]);
    //         }
    //     }
    //     if (i != expected.length) {
    //         throw new RuntimeException("unexpected the number of tokens: " ~ i.to!string()
    //                                    ~ ", expected " ~ expected.length.to!string());
    //     }
    // }
}