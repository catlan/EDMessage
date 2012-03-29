//---------------------------------------------------------------------------------------
//  EDDateFieldCoder.m created by erik
//  @(#)$Id: EDDateFieldCoder.m,v 2.2 2003/04/21 03:04:15 erik Exp $
//
//  Copyright (c) 1999 by Erik Doernenburg. All rights reserved.
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
#import "EDCommon.h"
#import "NSDate+NetExt.h"
#import "EDMConstants.h"
#import "EDDateFieldCoder.h"

@interface EDDateFieldCoder(PrivateAPI)
- (void)_takeDateFromString:(NSString *)string;
- (NSTimeZone *)_canonicalTimeZone;
@end


//---------------------------------------------------------------------------------------
    @implementation EDDateFieldCoder
//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------
//	CLASS ATTRIBUTES
//---------------------------------------------------------------------------------------

+ (NSString *)dateFormat
{
    // map old format to new
    // return @"%a, %d %b %Y %H:%M:%S %z";
    // %a   ->  EEE     - Abbreviated weekday name
    // %d   ->  dd      - Day of the month as a decimal number (01-31)
    // %b   ->  MMM     - Abbreviated month name
    // %Y   ->  yyyy    - Year with century (such as 1990)
    // %H   ->  HH      - Hour based on a 24-hour clock as a decimal number (00-23)
    // %M   ->  mm      - Minute as a decimal number (00-59)
    // %S   ->  ss      - Second as a decimal number (00-59)
    // %z   ->  ZZ      - Time zone offset in hours and minutes from GMT (HHMM)
    return @"EEE',' dd MMM yyyy HH:mm:ss ZZ";
}


//---------------------------------------------------------------------------------------
//	FACTORY
//---------------------------------------------------------------------------------------

+ (id)encoderWithDate:(NSDate *)value
{
    return [[[self alloc] initWithDate:value] autorelease];
}


//---------------------------------------------------------------------------------------
//	INIT & DEALLOC
//---------------------------------------------------------------------------------------

- (id)initWithFieldBody:(NSString *)body
{
    [self init];
    [self _takeDateFromString:body];
    return self;
}


- (id)initWithDate:(NSDate *)value
{
    [self init];
    date = [value retain];
    return self;
}


- (void)dealloc
{
    [date release];
    [super dealloc];
}


//---------------------------------------------------------------------------------------
//	ACCESSOR METHODS
//---------------------------------------------------------------------------------------

- (NSDate *)date
{
    return date;
}


- (NSString *)stringValue
{
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    NSString *format = [[NSUserDefaults standardUserDefaults] stringForKey:@"NSDateFormatString"];
    [formatter setDateFormat:format];
    return [formatter stringFromDate:date];
}


- (NSString *)fieldBody
{
    NSDate	*canonicalDate;

    canonicalDate = [[date copy] autorelease];
    //[canonicalDate setTimeZone:[self _canonicalTimeZone]];
    
    /*
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar]; 
    NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSTimeZoneCalendarUnit;
    NSDateComponents *dateComponents = [gregorian components:unitFlags fromDate:canonicalDate];
    [dateComponents setTimeZone:[self _canonicalTimeZone]];
    */
    
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [formatter setDateFormat:[[self class] dateFormat]];
    [formatter setTimeZone:[self _canonicalTimeZone]];

    return [formatter stringFromDate:canonicalDate];
}


//---------------------------------------------------------------------------------------
//	CODING HELPER METHODS
//---------------------------------------------------------------------------------------

#ifndef CLASSIC_VERSION

// Use a new parser written by Axel in Objective-C.     

- (void)_takeDateFromString:(NSString *)string
{
    string = [string stringByRemovingSurroundingWhitespace];
    date = [[NSDate dateWithMessageTimeSpecification:string] retain];
    if(date == nil)
        EDLog1(EDLogCoder, @"Invalid date spec; found \"%@\"\n", string);
}

#else

// Use classic yacc grammer for dates. Needs yacc (configured to use bison in postamble)
// and a locking mechanism. This is "proven technology" but looses the timezone and
// will not recognize new style timezones such as Europe/Rome. The choice is yours...


extern time_t parsedate(const char *datespec);

- (void)_takeDateFromString:(NSString *)string
{
    static char buffer[128];
    static EDLightWeightLock retainLock;
    static BOOL lockInitialized = NO;
    time_t t;

    if(lockInitialized == NO)
        {
        lockInitialized = YES;
        EDLWLInit(&retainLock);
        }
      
    EDLWLLock(&retainLock);
    [string getCString:buffer maxLength:127];
    if((t = parsedate(buffer)) == -1)
        {
        EDLog1(EDLogCoder, @"Invalid date spec; found \"%@\"\n", string);
        }
    else
        {
        t += -978307200; // Convert from Unix reference date to Foundation reference date
        date = [[NSCalendarDate allocWithZone:[self zone]] initWithTimeIntervalSinceReferenceDate:t];
        [date setTimeZone:[self _canonicalTimeZone]];
        }
    EDLWLUnlock(&retainLock);
}

#endif

//---------------------------------------------------------------------------------------
//	OTHER HELPER METHODS
//---------------------------------------------------------------------------------------

- (NSTimeZone *)_canonicalTimeZone
{
    static NSTimeZone *canonicalTimeZone = nil;

    if(canonicalTimeZone == nil)
        {
        canonicalTimeZone = [[NSTimeZone alloc] initWithName:@"GMT"];
        NSAssert(canonicalTimeZone != nil, @"System does not know time zone GMT.");
        }
    return canonicalTimeZone;
}


//---------------------------------------------------------------------------------------
    @end
//---------------------------------------------------------------------------------------
