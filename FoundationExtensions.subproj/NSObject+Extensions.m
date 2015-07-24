//---------------------------------------------------------------------------------------
//  NSObject+Extensions.m created by erik on Sun 06-Sep-1998
//  @(#)$Id: NSObject+Extensions.m,v 2.5 2005-09-25 11:06:36 erik Exp $
//
//  Copyright (c) 1998-2000,2008 by Erik Doernenburg. All rights reserved.
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

#import <Foundation/Foundation.h>
#import "EDObjcRuntime.h"
#import "NSObject+Extensions.h"


//---------------------------------------------------------------------------------------
    @implementation NSObject(EDExtensions)
//---------------------------------------------------------------------------------------

/*" Various extensions to #NSObject. "*/

//---------------------------------------------------------------------------------------
//	RUNTIME CONVENIENCES
//---------------------------------------------------------------------------------------

/*" Raises an #NSInternalInconsistencyException stating that the method must be overriden. "*/

- (volatile void)methodIsAbstract:(SEL)selector
{
    [NSException raise:NSInternalInconsistencyException format:@"*** -[%@ %@]: Abstract definition must be overriden.", NSStringFromClass([self class]), NSStringFromSelector(selector)];
}


//---------------------------------------------------------------------------------------
    @end
//---------------------------------------------------------------------------------------

