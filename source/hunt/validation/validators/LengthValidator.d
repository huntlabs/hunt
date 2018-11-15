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
module hunt.validation.validators.LengthValidator;

import hunt.validation.constraints.Length;
import hunt.validation.ConstraintValidator;
import hunt.validation.ConstraintValidatorContext;
import hunt.validation.Validator;

import hunt.logging;
import std.string;

public class LengthValidator : AbstractValidator , ConstraintValidator!(Length, string) {

	private Length _length;

	override void initialize(Length constraintAnnotation){
		_length = constraintAnnotation;
    }
    
	override
	public bool isValid(string data, ConstraintValidatorContext constraintValidatorContext) {
		scope(exit) constraintValidatorContext.append(this);
		if(data.length < _length.min || data.length > _length.max)
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

		return  new FormatterWrapper("{{","}}").format(_length.message,toJSON(_length));
	}

}
