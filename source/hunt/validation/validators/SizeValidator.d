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
module hunt.validation.validators.SizeValidator;

import hunt.validation.constraints.Size;
import hunt.validation.ConstraintValidator;
import hunt.validation.ConstraintValidatorContext;
import std.exception;
import hunt.validation.Validator;

import hunt.logging;
import std.string;

public class SizeValidator(T) : AbstractValidator , ConstraintValidator!(Size, T) {

	private Size _size;

	override void initialize(Size constraintAnnotation){
		_size = constraintAnnotation;
    }
    
	override
	public bool isValid(T data, ConstraintValidatorContext constraintValidatorContext) {
		 scope(exit) constraintValidatorContext.append(this);
		
		static if(isArray!(T) || isAssociativeArray!(T))
		{
			if( data.length < _size.min || data.length > _size.max)
			{
				_isValid = false;
			}
			else 
			{
				_isValid = true;
			}
			return _isValid;
		}
		else 
		{
			throw new Exception("not support type : ",T.stringof);
			_isValid = false;
			return false;
		}

	}

	override string getMessage()
	{
		import hunt.string.FormatterWrapper;
		import hunt.util.serialize;

		return  new FormatterWrapper("{{","}}").format(_size.message,toJSON(_size));
	}
}
