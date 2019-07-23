/*
 * Hunt - Hunt is a high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design. It lets you build high-performance Web applications quickly and easily.
 *
 * Copyright (C) 2018-2019 HuntLabs
 *
 * Website: www.huntframework.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */
module hunt.text.FormatterWrapper;

import std.regex;
import std.json;
import std.conv;
import hunt.logging;

class  FormatterWrapper
{
    private string _open_delimiter;
    private string _close_delimiter;

    this(string open_delimiter , string close_delimiter)
    {
        _open_delimiter = open_delimiter;
        _close_delimiter = close_delimiter;
    }

    string[string] match(string input)
    {
        ///such as ("\\{\\{\\s*(.+?)\\s*\\}\\}")
        string[string] result;
        string pattern;
        foreach(ch; _open_delimiter) {
            switch (ch){
                case '{': pattern ~= r"\{";
                          break;
                case '[': pattern ~= r"\[";
                          break; 
                case '(': pattern ~= r"\(";
                          break;
                case '}': pattern ~= r"\}";
                          break;
                case ']': pattern ~= r"\]";
                          break;
                case ')': pattern ~= r"\)";
                          break;
                case '$': pattern ~= r"\$";
                          break;
                case '*': pattern ~= r"\*";
                          break;
                case '+': pattern ~= r"\+";
                          break;
                case '^': pattern ~= r"\^";
                          break;
                case '?': pattern ~= r"\?";
                          break;
                case '|': pattern ~= r"\|";
                          break;
                case '=': pattern ~= r"\=";
                          break;
                case '-': pattern ~= r"\-";
                          break;
                case '!': pattern ~= r"\!";
                          break;
                case '#': pattern ~= r"\#";
                          break;
                default : 
                    pattern ~= ch;
            }
        }
        pattern ~= r"\s*(.+?)\s*";
        foreach(ch; _close_delimiter) {
            switch (ch){
                case '{': pattern ~= r"\{";
                          break;
                case '[': pattern ~= r"\[";
                          break; 
                case '(': pattern ~= r"\(";
                          break;
                case '}': pattern ~= r"\}";
                          break;
                case ']': pattern ~= r"\]";
                          break;
                case ')': pattern ~= r"\)";
                          break;
                case '$': pattern ~= r"\$";
                          break;
                case '*': pattern ~= r"\*";
                          break;
                case '+': pattern ~= r"\+";
                          break;
                case '^': pattern ~= r"\^";
                          break;
                case '?': pattern ~= r"\?";
                          break;
                case '|': pattern ~= r"\|";
                          break;
                case '=': pattern ~= r"\=";
                          break;
                case '-': pattern ~= r"\-";
                          break;
                case '!': pattern ~= r"\!";
                          break;
                case '#': pattern ~= r"\#";
                          break;
                default : 
                    pattern ~= ch;
            }
        }

        auto matchs = matchAll(input , regex(pattern));
        foreach(match; matchs) {
            result[match.captures[0]] = match.captures[1];
        }
        import std.format;
        // logDebug("format pattern : %s , match result : %s".format(pattern,result));
        return result;
    }

    string format(string input , JSONValue data)
    {
        import std.string;
        auto matchs = match(input);
        foreach(k , v; matchs) {
            if(v in data)
            {
                if(data[v].type == JSONType.string)
                    input = input.replace(k , data[v].str);
                else
                    input = input.replace(k , data[v].to!string);
            }
        }

        return input;
    }
}


unittest
{
	JSONValue v;
	v["age"] = 12;
	v["name"] = "gaoxincheng";

	string input = "the age is #@$%^&*!+_()[]{} age #@$%^&*!+_()[]{} , and name is #@$%^&*!+_()[]{}  name #@$%^&*!+_()[]{} ...";

	FormatterWrapper wrapper = new FormatterWrapper("#@$%^&*!+_()[]{}","#@$%^&*!+_()[]{}");
	assert("the age is 12 , and name is gaoxincheng ..." == wrapper.format(input,v));
}