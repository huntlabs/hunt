module hunt.util.string.Pattern;

import hunt.util.string.common;
import hunt.util.string.StringUtils;

import std.string;


abstract class Pattern {
	
	private __gshared AllMatch ALL_MATCH;

    shared static this()
    {
        ALL_MATCH = new AllMatch();
    }
	
	/**
	 * Matches a string according to the specified pattern
	 * @param str Target string
	 * @return If it returns null, that represents matching failure, 
	 * else it returns an array contains all strings are matched.
	 */
	abstract string[] match(string str);
	
	static Pattern compile(string pattern, string wildcard) {
		bool startWith = pattern.startsWith(wildcard);
		bool endWith = pattern.endsWith(wildcard);
		string[] array = StringUtils.split(pattern, wildcard);
		
		switch (array.length) {
		case 0:
			return ALL_MATCH;
		case 1:
			if (startWith && endWith)
				return new HeadAndTailMatch(array[0]);
			
			if (startWith)
				return new HeadMatch(array[0]);
			
			if (endWith)
				return new TailMatch(array[0]);
			
			return new EqualsMatch(pattern);
		default:
			return new MultipartMatch(startWith, endWith, array);
		}
	}
	
	
	private static class MultipartMatch : Pattern {
		
		private bool startWith, endWith;
		private string[] parts;
		private int num;

		this(bool startWith, bool endWith, string[] parts) {
			// super();
			this.startWith = startWith;
			this.endWith = endWith;
			this.parts = parts;
			num = cast(int)parts.length - 1;
			if(startWith)
				num++;
			if(endWith)
				num++;
		}

		override
		string[] match(string str) {
			int currentIndex = -1;
			int lastIndex = -1;
			string[] ret = new string[num];
			
			for (int i = 0; i < parts.length; i++) {
				string part = parts[i];
				int j = startWith ? i : i - 1;
				currentIndex = cast(int)str.indexOf(part, lastIndex + 1);
				
				if (currentIndex > lastIndex) {
					if(i != 0 || startWith)
						ret[j] = str.substring(lastIndex + 1, currentIndex);
					
					lastIndex = currentIndex + cast(int)part.length - 1;
					continue;
				}
				return null;
			}
			
			if(endWith)
				ret[num - 1] = str.substring(lastIndex + 1);
			
			return ret;
		}
		
	}
	
	private static class TailMatch : Pattern {
		private string part;

		this(string part) {
			this.part = part;
		}

		override
		string[] match(string str) {
			int currentIndex = cast(int)str.indexOf(part);
			if(currentIndex == 0) {
				return [str.substring(cast(int)part.length)];
			}
			return null;
		}
	}
	
	private static class HeadMatch : Pattern {
		private string part;

		this(string part) {
			this.part = part;
		}

		override
		string[] match(string str) {
			int currentIndex = cast(int)str.indexOf(part);
			if(currentIndex + part.length == str.length) {
				return [str.substring(0, currentIndex)];
			}
			return null;
		}
		
		
	}
	
	private static class HeadAndTailMatch : Pattern {
		private string part;

		this(string part) {
			this.part = part;
		}

		override
		string[] match(string str) {
			int currentIndex = cast(int)str.indexOf(part);
			if(currentIndex >= 0) {
				string[] ret = [str[0 .. currentIndex],
						str.substring(currentIndex + cast(int)part.length, cast(int)str.length) ];
				return ret;
			}
			return null;
		}
		
		
	}
	
	private static class EqualsMatch : Pattern {
		private string pattern;
		
		this(string pattern) {
			this.pattern = pattern;
		}

		override
		string[] match(string str) {
			return pattern.equals(str) ? new string[0] : null;
		}
	}
	
	private static class AllMatch : Pattern {

		override
		string[] match(string str) {
			return [str];
		}
	}
}