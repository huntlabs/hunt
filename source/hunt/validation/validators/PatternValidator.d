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
module hunt.validation.validators.PatternValidator;

import hunt.validation.constraints.Pattern;
import hunt.validation.ConstraintValidator;
import hunt.validation.ConstraintValidatorContext;
import hunt.validation.Validator;
import hunt.logging;
import std.regex;

public class PatternValidator : AbstractValidator , ConstraintValidator!(Pattern, string) {

	private Pattern _pattern;

	override void initialize(Pattern constraintAnnotation){
		_pattern = constraintAnnotation;
    }
    
	override
	public bool isValid(string data, ConstraintValidatorContext constraintValidatorContext) {
		scope(exit) constraintValidatorContext.append(this);
		auto m = matchAll(data,regex(_pattern.pattern));
		if(m.empty)
		{
			_isValid = false;
			return false;
		}
		else
		{
			_isValid = true;
			return true;
		}
	}

	override string getMessage()
	{
		import hunt.string.FormatterWrapper;
		import hunt.util.serialize;

		return  new FormatterWrapper("{{","}}").format(_pattern.message,toJSON(_pattern));
	}

}
