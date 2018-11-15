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
module hunt.validation.validators.RangeValidator;

import hunt.validation.constraints.Range;
import hunt.validation.ConstraintValidator;
import hunt.validation.ConstraintValidatorContext;
import hunt.validation.Validator;
import hunt.logging;
import std.string;

// alias Range = hunt.validation.constraints.Range.Range;

public class RangeValidator : AbstractValidator , ConstraintValidator!(Range, long) {

	private Range _range;

	override void initialize(Range constraintAnnotation){
		_range = constraintAnnotation;
    }
    
	override
	public bool isValid(long data, ConstraintValidatorContext constraintValidatorContext) {
		scope(exit) constraintValidatorContext.append(this);
		if( data < _range.min || data > _range.max)
		{
			_isValid = false;
		}
		else
		{
			_isValid = true;
		}
		return _isValid;

	}

	override string getMessage()
	{
		import hunt.string.FormatterWrapper;
		import hunt.util.serialize;

		return  new FormatterWrapper("{{","}}").format(_range.message,toJSON(_range));
	}
}
