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
module hunt.validation.validators.AssertTrueValidator;

import hunt.validation.constraints.AssertTrue;
import hunt.validation.ConstraintValidator;
import hunt.validation.ConstraintValidatorContext;
import hunt.validation.Validator;

import hunt.lang;

public class AssertTrueValidator : AbstractValidator , ConstraintValidator!(AssertTrue, bool) {
	private AssertTrue _assert;
	override void initialize(AssertTrue constraintAnnotation){
		_assert = constraintAnnotation;
    }
    
	override
	public bool isValid(bool bl, ConstraintValidatorContext constraintValidatorContext) {
		//null values are valid
		scope(exit) constraintValidatorContext.append(this);

		if(!bl)
		{
			_isValid = false;
			return false;
		}
		else
		{
			return true;
		}
	}

	override string getMessage()
	{
		return _assert.message;
	}

}
