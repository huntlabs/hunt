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
module hunt.validation.Validator;


interface Validator {

	/**
	 * <p>
	 * get error msg
	 * <p>
	 * The default implementation is a no-op.
	 * 
	 */
	string getMessage();

	/**
	 * @return {@code false} if {@code value} does not pass the constraint
	 */
	bool isValid();

	/**
	 * set valid property name
	 */
	void setPropertyName(string name);

	/**
	 * get valid property name
	 */
	string getPropertyName();
}

class  AbstractValidator : Validator {

	protected bool _isValid = true;
	protected string _propertyName ;

	/**
	 * <p>
	 * get error msg
	 * <p>
	 * The default implementation is a no-op.
	 * 
	 */
	override string getMessage(){ return string.init; }

	/**
	 * @return {@code false} if {@code value} does not pass the constraint
	 */
	override protected bool isValid(){ return _isValid ;}

	/**
	 * set valid property name
	 */
	void setPropertyName(string name) { _propertyName = name ;}

	/**
	 * get valid property name
	 */
	string getPropertyName(){ return _propertyName; }
}