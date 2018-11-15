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
module hunt.validation.validators.MaxValidator;

import hunt.validation.constraints.Max;
import hunt.validation.ConstraintValidator;
import hunt.validation.ConstraintValidatorContext;
import hunt.validation.Validator;

import hunt.lang;

public class MaxValidator : AbstractValidator , ConstraintValidator!(Max, long) {

	private Max _max;

	override void initialize(Max constraintAnnotation){
		_max = constraintAnnotation;
    }
    
	override
	public bool isValid(long data, ConstraintValidatorContext constraintValidatorContext) {
		//null values are valid
		scope(exit) constraintValidatorContext.append(this);
		if(data > _max.value)
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

		return  new FormatterWrapper("{{","}}").format(_max.message,toJSON(_max));
	}
}
