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
module hunt.validation.DeclDef;

import std.traits;

import hunt.validation.validators.AssertFalseValidator;
import hunt.validation.validators.AssertTrueValidator;
import hunt.validation.validators.EmailValidator;
import hunt.validation.validators.LengthValidator;
import hunt.validation.validators.MaxValidator;
import hunt.validation.validators.MinValidator;
import hunt.validation.validators.NotBlankValidator;
import hunt.validation.validators.NotEmptyValidator;
import hunt.validation.validators.PatternValidator;
import hunt.validation.validators.SizeValidator;
import hunt.validation.constraints.AssertFalse;
import hunt.validation.constraints.AssertTrue;
import hunt.validation.constraints.Email;
import hunt.validation.constraints.Max;
import hunt.validation.constraints.Min;
import hunt.validation.constraints.NotBlank;
import hunt.validation.constraints.NotEmpty;
import hunt.validation.constraints.Pattern;
import hunt.validation.constraints.Size;
import hunt.validation.constraints.Length;
import hunt.validation.constraints.Range;


mixin template MakeValid()
{
	mixin(makeValidInit);
    mixin(makeDoValid!(typeof(this)));
}

string makeValidInit()
{
	string str = `
		private ConstraintValidatorContext _context;
		public ConstraintValidatorContext valid(){ return doValid() ;}
	`;

	return str;
}

bool hasAnnotation(T, A)() {
    bool res = false;
    foreach(a; __traits(getAttributes, T)) {
        static if (is(typeof(a) == A) || a.stringof == A.stringof) {
            res = true;
            break;
        }
    }
    return res;
}

string makeDoValid(T)()
{
	string str = `
		private ConstraintValidatorContext doValid()
		{
			if(_context is null)
				_context = new DefaultConstraintValidatorContext();
			return doValid(_context);
		}

		public ConstraintValidatorContext doValid(ConstraintValidatorContext context)
		{`;
			foreach(memberName; __traits(derivedMembers, T)) {
        		static if (__traits(getProtection, __traits(getMember, T, memberName)) == "public") {
            		alias memType = typeof(__traits(getMember, T ,memberName));
					static if (!isFunction!(memType)) {
						static if(hasUDA!(__traits(getMember, T ,memberName), Max))
						{
				str	~=`		{
								MaxValidator validator = new MaxValidator();`;
								static if((getUDAs!(__traits(getMember, T ,memberName), Max)[0]).stringof == Max.stringof)
								{
									str	~=`	validator.initialize(`~ (getUDAs!(__traits(getMember, T ,memberName), Max)[0]).stringof~ `());`; 
								}
								else
								{
									str	~=`	validator.initialize(`~ (getUDAs!(__traits(getMember, T ,memberName), Max)[0]).stringof~ `);`;
								}
					str	~=`		validator.setPropertyName(`~memberName.stringof~`);
								validator.isValid(this.` ~ memberName ~ `,context);
							}`;
						}
						static if(hasUDA!(__traits(getMember, T ,memberName), Min))
						{
				str	~=`		{
								MinValidator validator = new MinValidator();`;
								static if((getUDAs!(__traits(getMember, T ,memberName), Min)[0]).stringof == Min.stringof)
								{
									str	~=`	validator.initialize(`~ (getUDAs!(__traits(getMember, T ,memberName), Min)[0]).stringof~ `());`; 
								}
								else
								{
									str	~=`	validator.initialize(`~ (getUDAs!(__traits(getMember, T ,memberName), Min)[0]).stringof~ `);`;
								}
					str	~=`		validator.setPropertyName(`~memberName.stringof~`);
								validator.isValid(this.` ~ memberName ~ `,context);
							}`;
						}
						static if(hasUDA!(__traits(getMember, T ,memberName), AssertFalse))
						{
				str	~=`		{
								AssertFalseValidator validator = new AssertFalseValidator();`;
								static if((getUDAs!(__traits(getMember, T ,memberName), AssertFalse)[0]).stringof == AssertFalse.stringof)
								{
									str	~=`	validator.initialize(`~ (getUDAs!(__traits(getMember, T ,memberName), AssertFalse)[0]).stringof~ `());`; 
								}
								else
								{
									str	~=`	validator.initialize(`~ (getUDAs!(__traits(getMember, T ,memberName), AssertFalse)[0]).stringof~ `);`;
								}
					str	~=`		validator.setPropertyName(`~memberName.stringof~`);
								validator.isValid(this.` ~ memberName ~ `,context);
							}`;
						}
						static if(hasUDA!(__traits(getMember, T ,memberName), AssertTrue))
						{
				str	~=`		{
								AssertTrueValidator validator = new AssertTrueValidator();`;
								static if((getUDAs!(__traits(getMember, T ,memberName), AssertTrue)[0]).stringof == AssertTrue.stringof)
								{
									str	~=`	validator.initialize(`~ (getUDAs!(__traits(getMember, T ,memberName), AssertTrue)[0]).stringof~ `());`; 
								}
								else
								{
									str	~=`	validator.initialize(`~ (getUDAs!(__traits(getMember, T ,memberName), AssertTrue)[0]).stringof~ `);`;
								}
					str	~=`		validator.setPropertyName(`~memberName.stringof~`);
								validator.isValid(this.` ~ memberName ~ `,context);
							}`;
						}
						static if(hasUDA!(__traits(getMember, T ,memberName), Email))
						{
				str	~=`		{
								EmailValidator validator = new EmailValidator();`;
								static if((getUDAs!(__traits(getMember, T ,memberName), Email)[0]).stringof == Email.stringof)
								{
									str	~=`	validator.initialize(`~ (getUDAs!(__traits(getMember, T ,memberName), Email)[0]).stringof~ `());`; 
								}
								else
								{
									str	~=`	validator.initialize(`~ (getUDAs!(__traits(getMember, T ,memberName), Email)[0]).stringof~ `);`;
								}
					str	~=`		validator.setPropertyName(`~memberName.stringof~`);
								validator.isValid(this.` ~ memberName ~ `,context);
							}`;
						}
						static if(hasUDA!(__traits(getMember, T ,memberName), Length))
						{
				str	~=`		{
								LengthValidator validator = new LengthValidator();`;
								static if((getUDAs!(__traits(getMember, T ,memberName), Length)[0]).stringof == Length.stringof)
								{
									str	~=`	validator.initialize(`~ (getUDAs!(__traits(getMember, T ,memberName), Length)[0]).stringof~ `());`; 
								}
								else
								{
									str	~=`	validator.initialize(`~ (getUDAs!(__traits(getMember, T ,memberName), Length)[0]).stringof~ `);`;
								}
					str	~=`		validator.setPropertyName(`~memberName.stringof~`);
								validator.isValid(this.` ~ memberName ~ `,context);
							}`;
						}
						static if(hasUDA!(__traits(getMember, T ,memberName), NotBlank))
						{
				str	~=`		{
								NotBlankValidator validator = new NotBlankValidator();`;
								static if((getUDAs!(__traits(getMember, T ,memberName), NotBlank)[0]).stringof == NotBlank.stringof)
								{
									str	~=`	validator.initialize(`~ (getUDAs!(__traits(getMember, T ,memberName), NotBlank)[0]).stringof~ `());`; 
								}
								else
								{
									str	~=`	validator.initialize(`~ (getUDAs!(__traits(getMember, T ,memberName), NotBlank)[0]).stringof~ `);`;
								}
					str	~=`		validator.setPropertyName(`~memberName.stringof~`);
								validator.isValid(this.` ~ memberName ~ `,context);
							}`;
						}
						static if(hasUDA!(__traits(getMember, T ,memberName), NotEmpty))
						{
				str	~=`		{
								auto validator = new NotEmptyValidator!`~memType.stringof~`();`;
								static if((getUDAs!(__traits(getMember, T ,memberName), NotEmpty)[0]).stringof == NotEmpty.stringof)
								{
									str	~=`	validator.initialize(`~ (getUDAs!(__traits(getMember, T ,memberName), NotEmpty)[0]).stringof~ `());`; 
								}
								else
								{
									str	~=`	validator.initialize(`~ (getUDAs!(__traits(getMember, T ,memberName), NotEmpty)[0]).stringof~ `);`;
								}
					str	~=`		validator.setPropertyName(`~memberName.stringof~`);
								validator.isValid(this.` ~ memberName ~ `,context);
							}`;
						}
						static if(hasUDA!(__traits(getMember, T ,memberName), Pattern))
						{
				str	~=`		{
								PatternValidator validator = new PatternValidator();`;
								static if((getUDAs!(__traits(getMember, T ,memberName), Pattern)[0]).stringof == Pattern.stringof)
								{
									str	~=`	validator.initialize(`~ (getUDAs!(__traits(getMember, T ,memberName), Pattern)[0]).stringof~ `());`; 
								}
								else
								{
									str	~=`	validator.initialize(`~ (getUDAs!(__traits(getMember, T ,memberName), Pattern)[0]).stringof~ `);`;
								}
					str	~=`		validator.setPropertyName(`~memberName.stringof~`);
								validator.isValid(this.` ~ memberName ~ `,context);
							}`;
						}
						static if(hasUDA!(__traits(getMember, T ,memberName), Size))
						{
				str	~=`		{
								auto validator = new SizeValidator!`~memType.stringof~`();`;
								static if((getUDAs!(__traits(getMember, T ,memberName), Size)[0]).stringof == Size.stringof)
								{
									str	~=`	validator.initialize(`~ (getUDAs!(__traits(getMember, T ,memberName), Size)[0]).stringof~ `());`; 
								}
								else
								{
									str	~=`	validator.initialize(`~ (getUDAs!(__traits(getMember, T ,memberName), Size)[0]).stringof~ `);`;
								}
					str	~=`		validator.setPropertyName(`~memberName.stringof~`);
								validator.isValid(this.` ~ memberName ~ `,context);
							}`;
						}
                        static if(hasUDA!(__traits(getMember, T ,memberName), Range))
						{
				str	~=`		{
								RangeValidator validator = new RangeValidator();`;
								static if((getUDAs!(__traits(getMember, T ,memberName), Range)[0]).stringof == Range.stringof)
								{
									str	~=`	validator.initialize(`~ (getUDAs!(__traits(getMember, T ,memberName), Range)[0]).stringof~ `());`; 
								}
								else
								{
									str	~=`	validator.initialize(`~ (getUDAs!(__traits(getMember, T ,memberName), Range)[0]).stringof~ `);`;
								}
					str	~=`		validator.setPropertyName(`~memberName.stringof~`);
								validator.isValid(this.` ~ memberName ~ `,context);
							}`;
						}
					}
				}
			}
	str ~= " return context;";
	str ~=`}`;
	return str;
}