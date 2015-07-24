//---------------------------------------------------------------------------------------
//  NSArray+Extensions.m created by erik on Thu 28-Mar-1996
//  @(#)$Id: NSArray+Extensions.m,v 2.4 2008-04-21 05:54:19 znek Exp $
//
//  Copyright (c) 1996,1999,2008 by Erik Doernenburg. All rights reserved.
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
#import "NSArray+Extensions.h"
#import "NSObject+Extensions.h"
#import "EDObjcRuntime.h"


//=======================================================================================
    @implementation NSArray(EDExtensions)
//=======================================================================================

/*" Various common extensions to #NSArray. "*/

//---------------------------------------------------------------------------------------

/*" Return the object at index 0 or !{nil} if the array is empty. "*/

- (id)firstObject
{
    if([self count] == 0)
        return nil;
    return [self objectAtIndex:0];
}


//---------------------------------------------------------------------------------------

/*" Uses each object in the receiver as a key and looks up the corresponding value in %mapping. All these values are added in the same order to the array returned. Note that this method raises an Exception if any of the objects in the receiver are not found as a key in %mapping."*/

- (NSArray *)arrayByMappingWithDictionary:(NSDictionary *)mapping
{
    NSMutableArray	*mappedArray;
    NSUInteger		i, n = [self count];

    mappedArray = [[NSMutableArray allocWithZone:nil] initWithCapacity:n];
    for(i = 0; i < n; i++)
        [mappedArray addObject:[mapping objectForKey:[self objectAtIndex:i]]];

    return mappedArray;
}


/*" Invokes the method described by %selector in each object in the receiver. All returned values are added in the same order to the array returned. "*/

- (NSArray *)arrayByMappingWithSelector:(SEL)selector
{
    NSMutableArray	*mappedArray;
    NSUInteger		i, n = [self count];

    mappedArray = [[NSMutableArray allocWithZone:nil] initWithCapacity:n];
    for(i = 0; i < n; i++)
        [mappedArray addObject:EDObjcMsgSend([self objectAtIndex:i], selector)];

    return mappedArray;
}


/*" Invokes the method described by %selector in each object in the receiver, passing %object as an argument. All returned values are added in the same order to the array returned. "*/

- (NSArray *)arrayByMappingWithSelector:(SEL)selector withObject:(id)object
{
    NSMutableArray	*mappedArray;
    NSUInteger		i, n = [self count];

    mappedArray = [[NSMutableArray allocWithZone:nil] initWithCapacity:n];
    for(i = 0; i < n; i++)
        [mappedArray addObject:EDObjcMsgSend1([self objectAtIndex:i], selector, object)];

    return mappedArray;
}





//=======================================================================================
    @end
//=======================================================================================


