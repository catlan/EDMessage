//---------------------------------------------------------------------------------------
//  EDCommonDefines.h created by erik on Fri 28-Mar-1997
//  @(#)$Id: EDCommonDefines.h,v 2.0 2002-08-16 18:12:43 erik Exp $
//
//  Copyright (c) 1997-2000,2008 by Erik Doernenburg. All rights reserved.
//
//  Permission to use, copy, modify and distribute this software and its documentation
//  is hereby granted, provided that both the copyright notice and this permission
//  notice appear in all copies of the software, derivative works or modified versions,
//  and any portions thereof, and that both notices appear in supporting documentation,
//  and that credit is given to Erik Doernenburg in all documents and publicity
//  pertaining to direct or indirect use of this code or its derivatives.
//
//  THIS IS EXPERIMENTAL SOFTWARE AND IT IS KNOWN TO HAVE BUGS, SOME OF WHICH MAY HAVE
//  SERIOUS CONSEQUENCES. THE COPYRIGHT HOLDER ALLOWS FREE USE OF THIS SOFTWARE IN ITS
//  "AS IS" CONDITION. THE COPYRIGHT HOLDER DISCLAIMS ANY LIABILITY OF ANY KIND FOR ANY
//  DAMAGES WHATSOEVER RESULTING DIRECTLY OR INDIRECTLY FROM THE USE OF THIS SOFTWARE
//  OR OF ANY DERIVATIVE WORK.
//---------------------------------------------------------------------------------------

# define EDCOMMON_EXTERN extern

/*" Use this if you want to say neither YES nor NO... "*/

#define UNKNOWN 2


// 	A really useful data type

typedef unsigned char byte;


/*"	A global variable that determines the output generated by the log macros. "*/

EDCOMMON_EXTERN unsigned int EDLogMask;

//	Macros to conditionally print messages. This looks scary and is in fact a
//	bad C hack. It is done because this is the only way to prevent the arguments
//	from even being created if no output would be made anyway. If this would
// 	be implemented as a function and called like, say,
//		EDLog1(4, @"array = %@", [array description])
//  then a poentially large description of the array would be created just
//	to be discarded if the log mask does not include the area in question.
//	On the downside, variable argument lists don't work and hence the number of
//	parameters must be given with the macro name.

/*" Function pointer to the function used by the log macros. #NSLog by default. Note that the function does not have to be able to deal with variable arg lists; it is always called with excatly on string argument."*/

EDCOMMON_EXTERN void (*_EDLogFunction)(NSString *);

/*" Don't call this directly. "*/

#define EDLog(area, format, ...)	\
    do { \
        if(EDLogMask & area) \
            (*_EDLogFunction)([NSString stringWithFormat:format, ##__VA_ARGS__]); \
    } while(0)


/*" Log text with format %f and arguments %argN with the logmask specified in %{l}. If !{l & EDLogMask !== 0} the output is supressed and in this case none of the strings are needed. This means that you can pass !{[myObject description]} and the method is only invoked if the output is required."*/


