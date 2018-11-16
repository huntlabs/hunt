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

module hunt.validation.ConstraintValidatorContext;
import hunt.validation.Validator;

interface ConstraintValidatorContext  {
    
    /**
	 * return valid string
	 */
    string toString();

    /**
	 * append validator
	 */
    ConstraintValidatorContext append(Validator);

    /**
	 * if it is valid 
	 */
    bool isValid();

    /**
	 * Get all errors associated with a field
     * @ the key is filed's name and the value is error message
     * Note : Multiple errors for the same field will only return one
	 */
    string[string] messages();

}