module hunt.string.PathMatcher;

import hunt.container;
import hunt.lang.Boolean;
import hunt.lang.exception;
import hunt.lang.Nullable;
import hunt.string.common;
import hunt.string.StringUtils;
import hunt.string.StringBuilder;

import std.array;
import std.string;
import std.regex;
import std.container.array;

/**
 * Strategy interface for {@code string}-based path matching.
 *
 * <p>Used by {@link hunt.framework.core.io.support.PathMatchingResourcePatternResolver},
 * {@link hunt.framework.web.servlet.handler.AbstractUrlHandlerMapping},
 * and {@link hunt.framework.web.servlet.mvc.WebContentInterceptor}.
 *
 * <p>The default implementation is {@link AntPathMatcher}, supporting the
 * Ant-style pattern syntax.
 *
 * @author Juergen Hoeller
 * @since 1.2
 * @see AntPathMatcher
 */
interface PathMatcher {

	/**
	 * Does the given {@code path} represent a pattern that can be matched
	 * by an implementation of this interface?
	 * <p>If the return value is {@code false}, then the {@link #match}
	 * method does not have to be used because direct equality comparisons
	 * on the static path Strings will lead to the same result.
	 * @param path the path string to check
	 * @return {@code true} if the given {@code path} represents a pattern
	 */
	bool isPattern(string path);

	/**
	 * Match the given {@code path} against the given {@code pattern},
	 * according to this PathMatcher's matching strategy.
	 * @param pattern the pattern to match against
	 * @param path the path string to test
	 * @return {@code true} if the supplied {@code path} matched,
	 * {@code false} if it didn't
	 */
	bool match(string pattern, string path);

	/**
	 * Match the given {@code path} against the corresponding part of the given
	 * {@code pattern}, according to this PathMatcher's matching strategy.
	 * <p>Determines whether the pattern at least matches as far as the given base
	 * path goes, assuming that a full path may then match as well.
	 * @param pattern the pattern to match against
	 * @param path the path string to test
	 * @return {@code true} if the supplied {@code path} matched,
	 * {@code false} if it didn't
	 */
	bool matchStart(string pattern, string path);

	/**
	 * Given a pattern and a full path, determine the pattern-mapped part.
	 * <p>This method is supposed to find out which part of the path is matched
	 * dynamically through an actual pattern, that is, it strips off a statically
	 * defined leading path from the given full path, returning only the actually
	 * pattern-matched part of the path.
	 * <p>For example: For "myroot/*.html" as pattern and "myroot/myfile.html"
	 * as full path, this method should return "myfile.html". The detailed
	 * determination rules are specified to this PathMatcher's matching strategy.
	 * <p>A simple implementation may return the given full path as-is in case
	 * of an actual pattern, and the empty string in case of the pattern not
	 * containing any dynamic parts (i.e. the {@code pattern} parameter being
	 * a static path that wouldn't qualify as an actual {@link #isPattern pattern}).
	 * A sophisticated implementation will differentiate between the static parts
	 * and the dynamic parts of the given path pattern.
	 * @param pattern the path pattern
	 * @param path the full path to introspect
	 * @return the pattern-mapped part of the given {@code path}
	 * (never {@code null})
	 */
	string extractPathWithinPattern(string pattern, string path);

	/**
	 * Given a pattern and a full path, extract the URI template variables. URI template
	 * variables are expressed through curly brackets ('{' and '}').
	 * <p>For example: For pattern "/hotels/{hotel}" and path "/hotels/1", this method will
	 * return a map containing "hotel"->"1".
	 * @param pattern the path pattern, possibly containing URI templates
	 * @param path the full path to extract template variables from
	 * @return a map, containing variable names as keys; variables values as values
	 */
	Map!(string, string) extractUriTemplateVariables(string pattern, string path);

	/**
	 * Given a full path, returns a {@link Comparator} suitable for sorting patterns
	 * in order of explicitness for that path.
	 * <p>The full algorithm used depends on the underlying implementation,
	 * but generally, the returned {@code Comparator} will
	 * {@linkplain java.util.List#sort(java.util.Comparator) sort}
	 * a list so that more specific patterns come before generic patterns.
	 * @param path the full path to use for comparison
	 * @return a comparator capable of sorting patterns in order of explicitness
	 */
	// Comparator!(string) getPatternComparator(string path);

	/**
	 * Combines two patterns into a new pattern that is returned.
	 * <p>The full algorithm used for combining the two pattern depends on the underlying implementation.
	 * @param pattern1 the first pattern
	 * @param pattern2 the second pattern
	 * @return the combination of the two patterns
	 * @throws IllegalArgumentException when the two patterns cannot be combined
	 */
	string combine(string pattern1, string pattern2);

}



private enum Regex!char VARIABLE_PATTERN = regex("\\{[^/]+?\\}");

/**
 * {@link PathMatcher} implementation for Ant-style path patterns.
 *
 * <p>Part of this mapping code has been kindly borrowed from <a href="http://ant.apache.org">Apache Ant</a>.
 *
 * <p>The mapping matches URLs using the following rules:<br>
 * <ul>
 * <li>{@code ?} matches one character</li>
 * <li>{@code *} matches zero or more characters</li>
 * <li>{@code **} matches zero or more <em>directories</em> in a path</li>
 * <li>{@code {spring:[a-z]+}} matches the regexp {@code [a-z]+} as a path variable named "spring"</li>
 * </ul>
 *
 * <h3>Examples</h3>
 * <ul>
 * <li>{@code com/t?st.jsp} &mdash; matches {@code com/test.jsp} but also
 * {@code com/tast.jsp} or {@code com/txst.jsp}</li>
 * <li>{@code com/*.jsp} &mdash; matches all {@code .jsp} files in the
 * {@code com} directory</li>
 * <li><code>com/&#42;&#42;/test.jsp</code> &mdash; matches all {@code test.jsp}
 * files underneath the {@code com} path</li>
 * <li><code>org/springframework/&#42;&#42;/*.jsp</code> &mdash; matches all
 * {@code .jsp} files underneath the {@code org/springframework} path</li>
 * <li><code>org/&#42;&#42;/servlet/bla.jsp</code> &mdash; matches
 * {@code org/springframework/servlet/bla.jsp} but also
 * {@code org/springframework/testing/servlet/bla.jsp} and {@code org/servlet/bla.jsp}</li>
 * <li>{@code com/{filename:\\w+}.jsp} will match {@code com/test.jsp} and assign the value {@code test}
 * to the {@code filename} variable</li>
 * </ul>
 *
 * <p><strong>Note:</strong> a pattern and a path must both be absolute or must
 * both be relative in order for the two to match. Therefore it is recommended
 * that users of this implementation to sanitize patterns in order to prefix
 * them with "/" as it makes sense in the context in which they're used.
 *
 * @author Alef Arendsen
 * @author Juergen Hoeller
 * @author Rob Harrop
 * @author Arjen Poutsma
 * @author Rossen Stoyanchev
 * @author Sam Brannen
 * @since 16.07.2003
 */
class AntPathMatcher : PathMatcher {

	/** Default path separator: "/" */
	enum string DEFAULT_PATH_SEPARATOR = "/";

	private enum int CACHE_TURNOFF_THRESHOLD = 65536;

	private enum char[] WILDCARD_CHARS = ['*', '?', '{' ];

	private string pathSeparator;

	private PathSeparatorPatternCache pathSeparatorPatternCache;

	private bool caseSensitive = true;

	private bool trimTokens = false;
	
	private Boolean cachePatterns;

	private Map!(string, string[]) tokenizedPatternCache;

	Map!(string, AntPathStringMatcher) stringMatcherCache;

	/**
	 * Create a new instance with the {@link #DEFAULT_PATH_SEPARATOR}.
	 */
	this() {
		this.pathSeparator = DEFAULT_PATH_SEPARATOR;
		this.pathSeparatorPatternCache = new PathSeparatorPatternCache(DEFAULT_PATH_SEPARATOR);
        initialize();
	}

	/**
	 * A convenient, alternative constructor to use with a custom path separator.
	 * @param pathSeparator the path separator to use, must not be {@code null}.
	 * @since 4.1
	 */
	this(string pathSeparator) {
		assert(pathSeparator, "'pathSeparator' is required");
		this.pathSeparator = pathSeparator;
		this.pathSeparatorPatternCache = new PathSeparatorPatternCache(pathSeparator);
        initialize();
	}

    private void initialize() {
        tokenizedPatternCache = new HashMap!(string, string[])(256); //new ConcurrentHashMap<>(256);
        stringMatcherCache = new HashMap!(string, AntPathStringMatcher)(256);
    }


	/**
	 * Set the path separator to use for pattern parsing.
	 * <p>Default is "/", as in Ant.
	 */
	void setPathSeparator( string pathSeparator) {
		this.pathSeparator = (pathSeparator !is null ? pathSeparator : DEFAULT_PATH_SEPARATOR);
		this.pathSeparatorPatternCache = new PathSeparatorPatternCache(this.pathSeparator);
	}

	/**
	 * Specify whether to perform pattern matching in a case-sensitive fashion.
	 * <p>Default is {@code true}. Switch this to {@code false} for case-insensitive matching.
	 * @since 4.2
	 */
	void setCaseSensitive(bool caseSensitive) {
		this.caseSensitive = caseSensitive;
	}

	/**
	 * Specify whether to trim tokenized paths and patterns.
	 * <p>Default is {@code false}.
	 */
	void setTrimTokens(bool trimTokens) {
		this.trimTokens = trimTokens;
	}

	/**
	 * Specify whether to cache parsed pattern metadata for patterns passed
	 * into this matcher's {@link #match} method. A value of {@code true}
	 * activates an unlimited pattern cache; a value of {@code false} turns
	 * the pattern cache off completely.
	 * <p>Default is for the cache to be on, but with the variant to automatically
	 * turn it off when encountering too many patterns to cache at runtime
	 * (the threshold is 65536), assuming that arbitrary permutations of patterns
	 * are coming in, with little chance for encountering a recurring pattern.
	 * @since 4.0.1
	 * @see #getStringMatcher(string)
	 */
	void setCachePatterns(bool cachePatterns) {
		this.cachePatterns = cachePatterns;
	}

	private void deactivatePatternCache() {
		this.cachePatterns = false;
		this.tokenizedPatternCache.clear();
		this.stringMatcherCache.clear();
	}


	override
	bool isPattern(string path) {
		return (path.indexOf('*') != -1 || path.indexOf('?') != -1);
	}

	override
	bool match(string pattern, string path) {
		return doMatch(pattern, path, true, null);
	}

	override
	bool matchStart(string pattern, string path) {
		return doMatch(pattern, path, false, null);
	}

	/**
	 * Actually match the given {@code path} against the given {@code pattern}.
	 * @param pattern the pattern to match against
	 * @param path the path string to test
	 * @param fullMatch whether a full pattern match is required (else a pattern match
	 * as far as the given base path goes is sufficient)
	 * @return {@code true} if the supplied {@code path} matched, {@code false} if it didn't
	 */
	protected bool doMatch(string pattern, string path, bool fullMatch,
			 Map!(string, string) uriTemplateVariables) {

		// if (path.startsWith(this.pathSeparator) != pattern.startsWith(this.pathSeparator)) {
		// 	return false;
		// }

		// string[] pattDirs = tokenizePattern(pattern);
		// if (fullMatch && this.caseSensitive && !isPotentialMatch(path, pattDirs)) {
		// 	return false;
		// }

		// string[] pathDirs = tokenizePath(path);

		// int pattIdxStart = 0;
		// int pattIdxEnd = cast(int)pattDirs.length - 1;
		// int pathIdxStart = 0;
		// int pathIdxEnd = cast(int)pathDirs.length - 1;

		// // Match all elements up to the first **
		// while (pattIdxStart <= pattIdxEnd && pathIdxStart <= pathIdxEnd) {
		// 	string pattDir = pattDirs[pattIdxStart];
		// 	if ("**".equals(pattDir)) {
		// 		break;
		// 	}
		// 	if (!matchStrings(pattDir, pathDirs[pathIdxStart], uriTemplateVariables)) {
		// 		return false;
		// 	}
		// 	pattIdxStart++;
		// 	pathIdxStart++;
		// }

		// if (pathIdxStart > pathIdxEnd) {
		// 	// Path is exhausted, only match if rest of pattern is * or **'s
		// 	if (pattIdxStart > pattIdxEnd) {
		// 		return (pattern.endsWith(this.pathSeparator) == path.endsWith(this.pathSeparator));
		// 	}
		// 	if (!fullMatch) {
		// 		return true;
		// 	}
		// 	if (pattIdxStart == pattIdxEnd && pattDirs[pattIdxStart].equals("*") && path.endsWith(this.pathSeparator)) {
		// 		return true;
		// 	}
		// 	for (int i = pattIdxStart; i <= pattIdxEnd; i++) {
		// 		if (!pattDirs[i].equals("**")) {
		// 			return false;
		// 		}
		// 	}
		// 	return true;
		// }
		// else if (pattIdxStart > pattIdxEnd) {
		// 	// string not exhausted, but pattern is. Failure.
		// 	return false;
		// }
		// else if (!fullMatch && "**".equals(pattDirs[pattIdxStart])) {
		// 	// Path start definitely matches due to "**" part in pattern.
		// 	return true;
		// }

		// // up to last '**'
		// while (pattIdxStart <= pattIdxEnd && pathIdxStart <= pathIdxEnd) {
		// 	string pattDir = pattDirs[pattIdxEnd];
		// 	if (pattDir.equals("**")) {
		// 		break;
		// 	}
		// 	if (!matchStrings(pattDir, pathDirs[pathIdxEnd], uriTemplateVariables)) {
		// 		return false;
		// 	}
		// 	pattIdxEnd--;
		// 	pathIdxEnd--;
		// }
		// if (pathIdxStart > pathIdxEnd) {
		// 	// string is exhausted
		// 	for (int i = pattIdxStart; i <= pattIdxEnd; i++) {
		// 		if (!pattDirs[i].equals("**")) {
		// 			return false;
		// 		}
		// 	}
		// 	return true;
		// }

		// while (pattIdxStart != pattIdxEnd && pathIdxStart <= pathIdxEnd) {
		// 	int patIdxTmp = -1;
		// 	for (int i = pattIdxStart + 1; i <= pattIdxEnd; i++) {
		// 		if (pattDirs[i].equals("**")) {
		// 			patIdxTmp = i;
		// 			break;
		// 		}
		// 	}
		// 	if (patIdxTmp == pattIdxStart + 1) {
		// 		// '**/**' situation, so skip one
		// 		pattIdxStart++;
		// 		continue;
		// 	}
		// 	// Find the pattern between padIdxStart & padIdxTmp in str between
		// 	// strIdxStart & strIdxEnd
		// 	int patLength = (patIdxTmp - pattIdxStart - 1);
		// 	int strLength = (pathIdxEnd - pathIdxStart + 1);
		// 	int foundIdx = -1;

		// 	strLoop:
		// 	for (int i = 0; i <= strLength - patLength; i++) {
		// 		for (int j = 0; j < patLength; j++) {
		// 			string subPat = pattDirs[pattIdxStart + j + 1];
		// 			string subStr = pathDirs[pathIdxStart + i + j];
		// 			if (!matchStrings(subPat, subStr, uriTemplateVariables)) {
		// 				continue strLoop;
		// 			}
		// 		}
		// 		foundIdx = pathIdxStart + i;
		// 		break;
		// 	}

		// 	if (foundIdx == -1) {
		// 		return false;
		// 	}

		// 	pattIdxStart = patIdxTmp;
		// 	pathIdxStart = foundIdx + patLength;
		// }

		// for (int i = pattIdxStart; i <= pattIdxEnd; i++) {
		// 	if (!pattDirs[i].equals("**")) {
		// 		return false;
		// 	}
		// }

		return true;
	}

	private bool isPotentialMatch(string path, string[] pattDirs) {
		if (!this.trimTokens) {
			int pos = 0;
			foreach (string pattDir ; pattDirs) {
				int skipped = skipSeparator(path, pos, this.pathSeparator);
				pos += skipped;
				skipped = skipSegment(path, pos, pattDir);
				if (skipped < pattDir.length) {
					return (skipped > 0 || (pattDir.length > 0 && isWildcardChar(pattDir.charAt(0))));
				}
				pos += skipped;
			}
		}
		return true;
	}

	private int skipSegment(string path, int pos, string prefix) {
		int skipped = 0;
		for (int i = 0; i < prefix.length; i++) {
			char c = prefix.charAt(i);
			if (isWildcardChar(c)) {
				return skipped;
			}
			int currPos = pos + skipped;
			if (currPos >= path.length) {
				return 0;
			}
			if (c == path.charAt(currPos)) {
				skipped++;
			}
		}
		return skipped;
	}

	private int skipSeparator(string path, int pos, string separator) {
		int skipped = 0;
		while (path.startsWith(separator, pos + skipped)) {
			skipped += separator.length;
		}
		return skipped;
	}

	private bool isWildcardChar(char c) {
		foreach (char candidate ; WILDCARD_CHARS) {
			if (c == candidate) {
				return true;
			}
		}
		return false;
	}

	/**
	 * Tokenize the given path pattern into parts, based on this matcher's settings.
	 * <p>Performs caching based on {@link #setCachePatterns}, delegating to
	 * {@link #tokenizePath(string)} for the actual tokenization algorithm.
	 * @param pattern the pattern to tokenize
	 * @return the tokenized pattern parts
	 */
	// protected string[] tokenizePattern(string pattern) {
	// 	string[] tokenized = null;
	// 	Boolean cachePatterns = this.cachePatterns;
	// 	if (cachePatterns is null || cachePatterns.booleanValue()) {
	// 		tokenized = this.tokenizedPatternCache.get(pattern);
	// 	}
	// 	if (tokenized is null) {
	// 		tokenized = tokenizePath(pattern);
	// 		if (cachePatterns is null && this.tokenizedPatternCache.size() >= CACHE_TURNOFF_THRESHOLD) {
	// 			// Try to adapt to the runtime situation that we're encountering:
	// 			// There are obviously too many different patterns coming in here...
	// 			// So let's turn off the cache since the patterns are unlikely to be reoccurring.
	// 			deactivatePatternCache();
	// 			return tokenized;
	// 		}
	// 		if (cachePatterns is null || cachePatterns.booleanValue()) {
	// 			this.tokenizedPatternCache.put(pattern, tokenized);
	// 		}
	// 	}
	// 	return tokenized;
	// }

	/**
	 * Tokenize the given path string into parts, based on this matcher's settings.
	 * @param path the path to tokenize
	 * @return the tokenized path parts
	 */
	// protected string[] tokenizePath(string path) {
	// 	return StringUtils.tokenizeToStringArray(path, this.pathSeparator, this.trimTokens, true);
	// }

	/**
	 * Test whether or not a string matches against a pattern.
	 * @param pattern the pattern to match against (never {@code null})
	 * @param str the string which must be matched against the pattern (never {@code null})
	 * @return {@code true} if the string matches against the pattern, or {@code false} otherwise
	 */
	// private bool matchStrings(string pattern, string str,
	// 		 Map!(string, string) uriTemplateVariables) {

	// 	return getStringMatcher(pattern).matchStrings(str, uriTemplateVariables);
	// }

	/**
	 * Build or retrieve an {@link AntPathStringMatcher} for the given pattern.
	 * <p>The default implementation checks this AntPathMatcher's internal cache
	 * (see {@link #setCachePatterns}), creating a new AntPathStringMatcher instance
	 * if no cached copy is found.
	 * <p>When encountering too many patterns to cache at runtime (the threshold is 65536),
	 * it turns the default cache off, assuming that arbitrary permutations of patterns
	 * are coming in, with little chance for encountering a recurring pattern.
	 * <p>This method may be overridden to implement a custom cache strategy.
	 * @param pattern the pattern to match against (never {@code null})
	 * @return a corresponding AntPathStringMatcher (never {@code null})
	 * @see #setCachePatterns
	 */
	protected AntPathStringMatcher getStringMatcher(string pattern) {
		AntPathStringMatcher matcher = null;
		Boolean cachePatterns = this.cachePatterns;
		if (cachePatterns is null || cachePatterns) {
			matcher = this.stringMatcherCache.get(pattern);
		}
		if (matcher is null) {
			matcher = new AntPathStringMatcher(pattern, this.caseSensitive);
			if (cachePatterns is null && this.stringMatcherCache.size() >= CACHE_TURNOFF_THRESHOLD) {
				// Try to adapt to the runtime situation that we're encountering:
				// There are obviously too many different patterns coming in here...
				// So let's turn off the cache since the patterns are unlikely to be reoccurring.
				deactivatePatternCache();
				return matcher;
			}
			if (cachePatterns is null || cachePatterns) {
				this.stringMatcherCache.put(pattern, matcher);
			}
		}
		return matcher;
	}

	/**
	 * Given a pattern and a full path, determine the pattern-mapped part. <p>For example: <ul>
	 * <li>'{@code /docs/cvs/commit.html}' and '{@code /docs/cvs/commit.html} -> ''</li>
	 * <li>'{@code /docs/*}' and '{@code /docs/cvs/commit} -> '{@code cvs/commit}'</li>
	 * <li>'{@code /docs/cvs/*.html}' and '{@code /docs/cvs/commit.html} -> '{@code commit.html}'</li>
	 * <li>'{@code /docs/**}' and '{@code /docs/cvs/commit} -> '{@code cvs/commit}'</li>
	 * <li>'{@code /docs/**\/*.html}' and '{@code /docs/cvs/commit.html} -> '{@code cvs/commit.html}'</li>
	 * <li>'{@code /*.html}' and '{@code /docs/cvs/commit.html} -> '{@code docs/cvs/commit.html}'</li>
	 * <li>'{@code *.html}' and '{@code /docs/cvs/commit.html} -> '{@code /docs/cvs/commit.html}'</li>
	 * <li>'{@code *}' and '{@code /docs/cvs/commit.html} -> '{@code /docs/cvs/commit.html}'</li> </ul>
	 * <p>Assumes that {@link #match} returns {@code true} for '{@code pattern}' and '{@code path}', but
	 * does <strong>not</strong> enforce this.
	 */
	override
	string extractPathWithinPattern(string pattern, string path) {
		// string[] patternParts = StringUtils.tokenizeToStringArray(pattern, this.pathSeparator, this.trimTokens, true);
		// string[] pathParts = StringUtils.tokenizeToStringArray(path, this.pathSeparator, this.trimTokens, true);
		// StringBuilder builder = new StringBuilder();
		// bool pathStarted = false;

		// for (int segment = 0; segment < patternParts.length; segment++) {
		// 	string patternPart = patternParts[segment];
		// 	if (patternPart.indexOf('*') > -1 || patternPart.indexOf('?') > -1) {
		// 		for (; segment < pathParts.length; segment++) {
		// 			if (pathStarted || (segment == 0 && !pattern.startsWith(this.pathSeparator))) {
		// 				builder.append(this.pathSeparator);
		// 			}
		// 			builder.append(pathParts[segment]);
		// 			pathStarted = true;
		// 		}
		// 	}
		// }

		// return builder.toString();
        return path;
	}

	override
	Map!(string, string) extractUriTemplateVariables(string pattern, string path) {
		Map!(string, string) variables = new LinkedHashMap!(string, string)();
		bool result = doMatch(pattern, path, true, variables);
		if (!result) {
			throw new IllegalStateException("Pattern \"" ~ pattern ~ "\" is not a match for \"" ~ path ~ "\"");
		}
		return variables;
	}

	/**
	 * Combine two patterns into a new pattern.
	 * <p>This implementation simply concatenates the two patterns, unless
	 * the first pattern contains a file extension match (e.g., {@code *.html}).
	 * In that case, the second pattern will be merged into the first. Otherwise,
	 * an {@code IllegalArgumentException} will be thrown.
	 * <h3>Examples</h3>
	 * <table border="1">
	 * <tr><th>Pattern 1</th><th>Pattern 2</th><th>Result</th></tr>
	 * <tr><td>{@code null}</td><td>{@code null}</td><td>&nbsp;</td></tr>
	 * <tr><td>/hotels</td><td>{@code null}</td><td>/hotels</td></tr>
	 * <tr><td>{@code null}</td><td>/hotels</td><td>/hotels</td></tr>
	 * <tr><td>/hotels</td><td>/bookings</td><td>/hotels/bookings</td></tr>
	 * <tr><td>/hotels</td><td>bookings</td><td>/hotels/bookings</td></tr>
	 * <tr><td>/hotels/*</td><td>/bookings</td><td>/hotels/bookings</td></tr>
	 * <tr><td>/hotels/&#42;&#42;</td><td>/bookings</td><td>/hotels/&#42;&#42;/bookings</td></tr>
	 * <tr><td>/hotels</td><td>{hotel}</td><td>/hotels/{hotel}</td></tr>
	 * <tr><td>/hotels/*</td><td>{hotel}</td><td>/hotels/{hotel}</td></tr>
	 * <tr><td>/hotels/&#42;&#42;</td><td>{hotel}</td><td>/hotels/&#42;&#42;/{hotel}</td></tr>
	 * <tr><td>/*.html</td><td>/hotels.html</td><td>/hotels.html</td></tr>
	 * <tr><td>/*.html</td><td>/hotels</td><td>/hotels.html</td></tr>
	 * <tr><td>/*.html</td><td>/*.txt</td><td>{@code IllegalArgumentException}</td></tr>
	 * </table>
	 * @param pattern1 the first pattern
	 * @param pattern2 the second pattern
	 * @return the combination of the two patterns
	 * @throws IllegalArgumentException if the two patterns cannot be combined
	 */
	override
	string combine(string pattern1, string pattern2) {
		if (pattern1.empty() && pattern2.empty()) {
			return "";
		}
		if (pattern1.empty()) {
			return pattern2;
		}
		if (pattern2.empty()) {
			return pattern1;
		}

		bool pattern1ContainsUriVar = (pattern1.indexOf('{') != -1);
		if (!pattern1.equals(pattern2) && !pattern1ContainsUriVar && match(pattern1, pattern2)) {
			// /* + /hotel -> /hotel ; "/*.*" ~ "/*.html" -> /*.html
			// However /user + /user -> /usr/user ; /{foo} + /bar -> /{foo}/bar
			return pattern2;
		}

		// /hotels/* + /booking -> /hotels/booking
		// /hotels/* + booking -> /hotels/booking
		if (pattern1.endsWith(this.pathSeparatorPatternCache.getEndsOnWildCard())) {
			return concat(pattern1.substring(0, pattern1.length - 2), pattern2);
		}

		// /hotels/** + /booking -> /hotels/**/booking
		// /hotels/** + booking -> /hotels/**/booking
		if (pattern1.endsWith(this.pathSeparatorPatternCache.getEndsOnDoubleWildCard())) {
			return concat(pattern1, pattern2);
		}

		int starDotPos1 = cast(int)pattern1.indexOf("*.");
		if (pattern1ContainsUriVar || starDotPos1 == -1 || this.pathSeparator.equals(".")) {
			// simply concatenate the two patterns
			return concat(pattern1, pattern2);
		}

		string ext1 = pattern1.substring(starDotPos1 + 1);
		int dotPos2 = cast(int)pattern2.indexOf('.');
		string file2 = (dotPos2 == -1 ? pattern2 : pattern2.substring(0, dotPos2));
		string ext2 = (dotPos2 == -1 ? "" : pattern2.substring(dotPos2));
		bool ext1All = (ext1.equals(".*") || ext1.equals(""));
		bool ext2All = (ext2.equals(".*") || ext2.equals(""));
		if (!ext1All && !ext2All) {
			throw new IllegalArgumentException("Cannot combine patterns: " ~ pattern1 ~ " vs " ~ pattern2);
		}
		string ext = (ext1All ? ext2 : ext1);
		return file2 ~ ext;
	}

	private string concat(string path1, string path2) {
		bool path1EndsWithSeparator = path1.endsWith(this.pathSeparator);
		bool path2StartsWithSeparator = path2.startsWith(this.pathSeparator);

		if (path1EndsWithSeparator && path2StartsWithSeparator) {
			return path1 ~ path2[1 .. $];
		}
		else if (path1EndsWithSeparator || path2StartsWithSeparator) {
			return path1 ~ path2;
		}
		else {
			return path1 ~ this.pathSeparator ~ path2;
		}
	}

	/**
	 * Given a full path, returns a {@link Comparator} suitable for sorting patterns in order of
	 * explicitness.
	 * <p>This{@code Comparator} will {@linkplain java.util.List#sort(Comparator) sort}
	 * a list so that more specific patterns (without uri templates or wild cards) come before
	 * generic patterns. So given a list with the following patterns:
	 * <ol>
	 * <li>{@code /hotels/new}</li>
	 * <li>{@code /hotels/{hotel}}</li> <li>{@code /hotels/*}</li>
	 * </ol>
	 * the returned comparator will sort this list so that the order will be as indicated.
	 * <p>The full path given as parameter is used to test for exact matches. So when the given path
	 * is {@code /hotels/2}, the pattern {@code /hotels/2} will be sorted before {@code /hotels/1}.
	 * @param path the full path to use for comparison
	 * @return a comparator capable of sorting patterns in order of explicitness
	 */
	// override
	// Comparator!(string) getPatternComparator(string path) {
	// 	return new AntPatternComparator(path);
	// }

}



/**
 * Tests whether or not a string matches against a pattern via a {@link Pattern}.
 * <p>The pattern may contain special characters: '*' means zero or more characters; '?' means one and
 * only one character; '{' and '}' indicate a URI template pattern. For example <tt>/users/{user}</tt>.
 */
protected static class AntPathStringMatcher {

    private enum Regex!char GLOB_PATTERN = regex("\\?|\\*|\\{((?:\\{[^/]+?\\}|[^/{}]|\\\\[{}])+?)\\}");

    private enum string DEFAULT_VARIABLE_PATTERN = "(.*)";

    private Regex!char pattern;

    private Array!(string) variableNames;

    this(string pattern) {
        this(pattern, true);
    }

    this(string pattern, bool caseSensitive) {
        StringBuilder patternBuilder = new StringBuilder();
        RegexMatch!string matcher = matchAll(pattern, GLOB_PATTERN);
        while(!matcher.empty) {
			Captures!string item = matcher.front;
            string match = item.front;
            patternBuilder.append(quote(match));
            if ("?" == match) {
                patternBuilder.append('.');
            }
            else if ("*" == match) {
                patternBuilder.append(".*");
            }
            else if (match.startsWith("{") && match.endsWith("}")) {
                int colonIdx = cast(int)match.indexOf(':');
                if (colonIdx == -1) {
                    patternBuilder.append(DEFAULT_VARIABLE_PATTERN);
                    this.variableNames.insertBack(matcher.post());
                }
                else {
                    string variablePattern = match[colonIdx + 1 .. $ - 1];
                    patternBuilder.append('(');
                    patternBuilder.append(variablePattern);
                    patternBuilder.append(')');
                    string variableName = match[1 .. colonIdx];
                    this.variableNames.insertBack(variableName);
                }
            }

			matcher.popFront();
        }
        // patternBuilder.append(quote(pattern, end, pattern.length));
        // this.pattern = (caseSensitive ? Pattern.compile(patternBuilder.toString()) :
        //         Pattern.compile(patternBuilder.toString(), Pattern.CASE_INSENSITIVE));
        this.pattern = regex(patternBuilder.toString());
    }

    /**
     * Returns a literal pattern <code>string</code> for the specified
     * <code>string</code>.
     *
     * <p>This method produces a <code>string</code> that can be used to
     * create a <code>Pattern</code> that would match the string
     * <code>s</code> as if it were a literal pattern.</p> Metacharacters
     * or escape sequences in the input sequence will be given no special
     * meaning.
     *
     * @param  s The string to be literalized
     * @return  A literal string replacement
     * @since 1.5
     */
    static string quote(string s) {
        int slashEIndex = cast(int)s.indexOf("\\E");
        if (slashEIndex == -1)
            return "\\Q" ~ s ~ "\\E";

        StringBuilder sb = new StringBuilder(s.length * 2);
        sb.append("\\Q");
        slashEIndex = 0;
        int current = 0;
        while ((slashEIndex = cast(int)s.indexOf("\\E", current)) != -1) {
            sb.append(s.substring(current, slashEIndex));
            current = slashEIndex + 2;
            sb.append("\\E\\\\E\\Q");
        }
        sb.append(s.substring(current, s.length));
        sb.append("\\E");
        return sb.toString();
    }

    /**
     * Main entry point.
     * @return {@code true} if the string matches against the pattern, or {@code false} otherwise.
     */
    bool matchStrings(string str,  Map!(string, string) uriTemplateVariables) {
        // RegexMatch!string matcher = matchAll(str, this.pattern);
        // if (matcher.matches()) {
        //     if (uriTemplateVariables !is null) {
        //         // SPR-8455
        //         if (this.variableNames.length != matcher.groupCount()) {
        //             throw new IllegalArgumentException("The number of capturing groups in the pattern segment " ~
        //                     to!string(this.pattern) ~ " does not match the number of URI template variables it defines, " ~
        //                     "which can occur if capturing groups are used in a URI template regex. " ~
        //                     "Use non-capturing groups instead.");
        //         }
        //         for (int i = 1; i <= matcher.groupCount(); i++) {
        //             string name = this.variableNames[i - 1];
        //             string value = matcher.group(i);
        //             uriTemplateVariables.put(name, value);
        //         }
        //     }
        //     return true;
        // }
        // else {
        //     return false;
        // }
        return true;
    }
}



/**
 * The default {@link Comparator} implementation returned by
 * {@link #getPatternComparator(string)}.
 * <p>In order, the most "generic" pattern is determined by the following:
 * <ul>
 * <li>if it's null or a capture all pattern (i.e. it is equal to "/**")</li>
 * <li>if the other pattern is an actual match</li>
 * <li>if it's a catch-all pattern (i.e. it ends with "**"</li>
 * <li>if it's got more "*" than the other pattern</li>
 * <li>if it's got more "{foo}" than the other pattern</li>
 * <li>if it's shorter than the other pattern</li>
 * </ul>
 */
// protected class AntPatternComparator : Comparator!(string) {

//     private string path;

//     this(string path) {
//         this.path = path;
//     }

//     /**
//      * Compare two patterns to determine which should match first, i.e. which
//      * is the most specific regarding the current path.
//      * @return a negative integer, zero, or a positive integer as pattern1 is
//      * more specific, equally specific, or less specific than pattern2.
//      */
//     override
//     int compare(string pattern1, string pattern2) {
//         PatternInfo info1 = new PatternInfo(pattern1);
//         PatternInfo info2 = new PatternInfo(pattern2);

//         if (info1.isLeastSpecific() && info2.isLeastSpecific()) {
//             return 0;
//         }
//         else if (info1.isLeastSpecific()) {
//             return 1;
//         }
//         else if (info2.isLeastSpecific()) {
//             return -1;
//         }

//         bool pattern1EqualsPath = pattern1.equals(path);
//         bool pattern2EqualsPath = pattern2.equals(path);
//         if (pattern1EqualsPath && pattern2EqualsPath) {
//             return 0;
//         }
//         else if (pattern1EqualsPath) {
//             return -1;
//         }
//         else if (pattern2EqualsPath) {
//             return 1;
//         }

//         if (info1.isPrefixPattern() && info2.getDoubleWildcards() == 0) {
//             return 1;
//         }
//         else if (info2.isPrefixPattern() && info1.getDoubleWildcards() == 0) {
//             return -1;
//         }

//         if (info1.getTotalCount() != info2.getTotalCount()) {
//             return info1.getTotalCount() - info2.getTotalCount();
//         }

//         if (info1.getLength() != info2.getLength()) {
//             return info2.getLength() - info1.getLength();
//         }

//         if (info1.getSingleWildcards() < info2.getSingleWildcards()) {
//             return -1;
//         }
//         else if (info2.getSingleWildcards() < info1.getSingleWildcards()) {
//             return 1;
//         }

//         if (info1.getUriVars() < info2.getUriVars()) {
//             return -1;
//         }
//         else if (info2.getUriVars() < info1.getUriVars()) {
//             return 1;
//         }

//         return 0;
//     }
// }


/**
 * Value class that holds information about the pattern, e.g. number of
 * occurrences of "*", "**", and "{" pattern elements.
 */
private class PatternInfo {
    
    private string pattern;

    private int uriVars;

    private int singleWildcards;

    private int doubleWildcards;

    private bool catchAllPattern;

    private bool prefixPattern;

    private int length;

    this( string pattern) {
        this.pattern = pattern;
        if (this.pattern !is null) {
            initCounters();
            this.catchAllPattern = this.pattern.equals("/**");
            this.prefixPattern = !this.catchAllPattern && this.pattern.endsWith("/**");
        }
        if (this.uriVars == 0) {
            this.length = cast(int) (this.pattern !is null ? this.pattern.length : 0);
        }
    }

    protected void initCounters() {
        int pos = 0;
        if (this.pattern !is null) {
            while (pos < this.pattern.length) {
                if (this.pattern.charAt(pos) == '{') {
                    this.uriVars++;
                    pos++;
                }
                else if (this.pattern.charAt(pos) == '*') {
                    if (pos + 1 < this.pattern.length && this.pattern.charAt(pos + 1) == '*') {
                        this.doubleWildcards++;
                        pos += 2;
                    }
                    else if (pos > 0 && !this.pattern.substring(pos - 1).equals(".*")) {
                        this.singleWildcards++;
                        pos++;
                    }
                    else {
                        pos++;
                    }
                }
                else {
                    pos++;
                }
            }
        }
    }

    int getUriVars() {
        return this.uriVars;
    }

    int getSingleWildcards() {
        return this.singleWildcards;
    }

    int getDoubleWildcards() {
        return this.doubleWildcards;
    }

    bool isLeastSpecific() {
        return (this.pattern is null || this.catchAllPattern);
    }

    bool isPrefixPattern() {
        return this.prefixPattern;
    }

    int getTotalCount() {
        return this.uriVars + this.singleWildcards + (2 * this.doubleWildcards);
    }

    /**
     * Returns the length of the given pattern, where template variables are considered to be 1 long.
     */
    int getLength() {
        // if (this.length == 0 && !this.pattern.empty) {
        //     Captures!string m = matchFirst(this.pattern, VARIABLE_PATTERN);
        //     string r = 
        //     this.length = 
        //             VARIABLE_PATTERN.matcher(this.pattern).replaceAll("#").length ;
        // }
        return this.length;
    }
}

/**
 * A simple cache for patterns that depend on the configured path separator.
 */
private class PathSeparatorPatternCache {

    private string endsOnWildCard;

    private string endsOnDoubleWildCard;

    this(string pathSeparator) {
        this.endsOnWildCard = pathSeparator ~ "*";
        this.endsOnDoubleWildCard = pathSeparator ~ "**";
    }

    string getEndsOnWildCard() {
        return this.endsOnWildCard;
    }

    string getEndsOnDoubleWildCard() {
        return this.endsOnDoubleWildCard;
    }
}
