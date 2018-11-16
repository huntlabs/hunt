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
module hunt.validation.validators.EmailValidator;

import hunt.validation.constraints.Email;
import hunt.validation.ConstraintValidator;
import hunt.validation.ConstraintValidatorContext;
import hunt.validation.util.DomainNameUtil;
import hunt.validation.Validator;

import hunt.logging;
import std.regex;
import std.string;

public class EmailValidator : AbstractValidator , ConstraintValidator!(Email, string) {

	static const string ATOM = "[a-z0-9!#$%&'*+/=?^_`{|}~-]";
    static const string DOMAIN = "(" ~ ATOM ~ "+(\\." ~ ATOM ~ "+)+";
    static const string IP_DOMAIN = "\\[[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\]";

    static const string PATTERN =
            "^" ~ ATOM ~ "+(\\." ~ ATOM ~ "+)*@"
                    ~ DOMAIN
                    ~ "|"
                    ~ IP_DOMAIN
                    ~ ")$";
	private  Email _email;

	override void initialize(Email constraintAnnotation) {
		_email = constraintAnnotation;
    }
    
	override
	public bool isValid(string data, ConstraintValidatorContext constraintValidatorContext) {
		scope(exit) constraintValidatorContext.append(this);	

		auto splitPosition = data.indexOf( '@' );

		// need to check if
		if ( splitPosition < 0 ) {
			return false;
		}

		// string localPart = data[0 .. splitPosition];
		// string domainPart = data[splitPosition+1 .. $];

		// if ( !isValidEmailLocalPart( localPart ) ) {
		// 	return false;
		// }

		// return DomainNameUtil.isValidEmailDomainAddress( domainPart );
		_isValid = isValidEmail(data);

		return _isValid;
	}

	private bool isValidEmailLocalPart(string localPart) {
		auto matcher = matchAll(localPart, regex("^" ~ ATOM ~ "+(\\." ~ ATOM ~ "+)*"));
		return !matcher.empty();
	}

	private bool isValidEmail(string email) {
		auto matcher = matchAll(email, regex( _email.pattern.length == 0 ? PATTERN : _email.pattern));
		return !matcher.empty();
	}

	override string getMessage()
	{
		return _email.message;
	}
}
