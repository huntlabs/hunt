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
module hunt.validation.validators.MinValidator;

import hunt.validation.constraints.Min;
import hunt.validation.ConstraintValidator;
import hunt.validation.ConstraintValidatorContext;
import hunt.validation.Validator;

import hunt.lang;

public class MinValidator : AbstractValidator , ConstraintValidator!(Min, long) {

	private Min _min;

	override void initialize(Min constraintAnnotation){
		_min = constraintAnnotation;
    }
    
	override
	public bool isValid(long data, ConstraintValidatorContext constraintValidatorContext) {
		//null values are valid
		scope(exit) constraintValidatorContext.append(this);
		if(data < _min.value)
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

		return  new FormatterWrapper("{{","}}").format(_min.message,toJSON(_min));
	}
}
