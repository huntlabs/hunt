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

module hunt.validation.DefaultConstraintValidatorContext;

import hunt.validation.ConstraintValidatorContext;
import hunt.validation.Validator;

import std.json;
import std.format;

class DefaultConstraintValidatorContext :  ConstraintValidatorContext  
{
    private Validator[] _validators;
    private bool _isValid = true;

    override public string toString()
    {
        return json().toString;
    }

    public JSONValue json()
    {
        string[string] msg;
        foreach(v; _validators) {
            if(!v.isValid)
            {
                msg[v.getPropertyName] = v.getMessage;
            }
        }
        return JSONValue(msg);
    }

    override public ConstraintValidatorContext append(Validator v)
    {
        _validators ~= v;
        if(!v.isValid)
            _isValid = false;
        return this;
    }

    override public bool isValid()
    {
        return _isValid;
    }
}