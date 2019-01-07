/*
 * Hunt - A refined core library for D programming language.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.net
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.datetime.format;

import std.datetime : Month, DayOfWeek;


short monthToShort(Month month)
{
    short resultMonth;
    switch(month)
    {
        case Month.jan:
            resultMonth = 1;
            break;
        case Month.feb:
            resultMonth = 2;
            break;
        case Month.mar:
            resultMonth = 3;
            break;
        case Month.apr:
            resultMonth = 4;
            break;
        case Month.may:
            resultMonth = 5;
            break;
        case Month.jun:
            resultMonth = 6;
            break;
        case Month.jul:
            resultMonth = 7;
            break;
        case Month.aug:
            resultMonth = 8;
            break;
        case Month.sep:
            resultMonth = 9;
            break;
        case Month.oct:
            resultMonth = 10;
            break;
        case Month.nov:
            resultMonth = 11;
            break;
        case Month.dec:
            resultMonth = 12;
            break;
        default:
            resultMonth = 0;
            break;
    }
    
    return resultMonth;
}


string dayAsString(DayOfWeek day) {
    final switch(day) with(DayOfWeek) {
        case mon: return "Mon";
        case tue: return "Tue";
        case wed: return "Wed";
        case thu: return "Thu";
        case fri: return "Fri";
        case sat: return "Sat";
        case sun: return "Sun";
    }
}

string monthAsString(Month month){
    final switch(month) with (Month) {
        case jan: return "Jan";
        case feb: return "Feb";
        case mar: return "Mar";
        case apr: return "Apr";
        case may: return "May";
        case jun: return "Jun";
        case jul: return "Jul";
        case aug: return "Aug";
        case sep: return "Sep";
        case oct: return "Oct";
        case nov: return "Nov";
        case dec: return "Dec";
    }
}
