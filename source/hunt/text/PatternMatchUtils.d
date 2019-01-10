module hunt.text.PatternMatchUtils;

import hunt.text.Common;

import std.range.primitives;
import std.string;

/**
 * Utility methods for simple pattern matching, in particular for
 * Spring's typical "xxx*", "*xxx" and "*xxx*" pattern styles.
 *
 * @author Juergen Hoeller
 * @since 2.0
 */
abstract class PatternMatchUtils {

	/**
	 * Match a string against the given pattern, supporting the following simple
	 * pattern styles: "xxx*", "*xxx", "*xxx*" and "xxx*yyy" matches (with an
	 * arbitrary number of pattern parts), as well as direct equality.
	 * @param pattern the pattern to match against
	 * @param str the string to match
	 * @return whether the string matches the given pattern
	 */
	static bool simpleMatch(string pattern, string str) {
		if (pattern.empty || str.empty) {
			return false;
		}
		ptrdiff_t firstIndex = pattern.indexOf('*');
		if (firstIndex == -1) {
			return pattern == str;
		}
		if (firstIndex == 0) {
			if (pattern.length == 1) {
				return true;
			}
			ptrdiff_t nextIndex = pattern.indexOf('*', firstIndex + 1);
			if (nextIndex == -1) {
				return str.endsWith(pattern.substring(1));
			}
			string part = pattern.substring(1, nextIndex);
			if ("" == part) {
				return simpleMatch(pattern.substring(nextIndex), str);
			}
			ptrdiff_t partIndex = str.indexOf(part);
			while (partIndex != -1) {
				if (simpleMatch(pattern.substring(nextIndex), str.substring(partIndex + part.length))) {
					return true;
				}
				partIndex = str.indexOf(part, partIndex + 1);
			}
			return false;
		}
		return (str.length >= firstIndex &&
				pattern.substring(0, firstIndex).equals(str.substring(0, firstIndex)) &&
				simpleMatch(pattern.substring(firstIndex), str.substring(firstIndex)));
	}

	/**
	 * Match a string against the given patterns, supporting the following simple
	 * pattern styles: "xxx*", "*xxx", "*xxx*" and "xxx*yyy" matches (with an
	 * arbitrary number of pattern parts), as well as direct equality.
	 * @param patterns the patterns to match against
	 * @param str the string to match
	 * @return whether the string matches any of the given patterns
	 */
	static bool simpleMatch(string[] patterns, string str) {
		if (patterns !is null) {
			foreach (string pattern ; patterns) {
				if (simpleMatch(pattern, str)) {
					return true;
				}
			}
		}
		return false;
	}

}
