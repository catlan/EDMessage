//---------------------------------------------------------------------------------------
//  NSCharacterSet+MIME.m created by erik on Sun 23-Mar-1997
//  @(#)$Id: NSCharacterSet+MIME.m,v 2.1 2003/04/08 17:06:03 znek Exp $
//
//  Copyright (c) 1997,98 by Erik Doernenburg. All rights reserved.
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
#import "utilities.h"
#import "NSCharacterSet+MIME.h"


//---------------------------------------------------------------------------------------
    @implementation NSCharacterSet(EDMessageExtensions)
//---------------------------------------------------------------------------------------

+ (NSCharacterSet *)standardASCIICharacterSet
{
    static NSCharacterSet *set = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        set = [NSCharacterSet characterSetWithRange:NSMakeRange(0, 127)];
    });
    return set;
}


+ (NSCharacterSet *)linebreakCharacterSet
{
    static NSCharacterSet *set = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        set = [NSCharacterSet characterSetWithCharactersInString:@"\r\n"];
    });
    return set;
}


//---------------------------------------------------------------------------------------
//	character sets for RFC822
//---------------------------------------------------------------------------------------

+ (NSCharacterSet *)MASpecialCharacterSet
{
    static NSCharacterSet *set = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        set = [NSCharacterSet characterSetWithCharactersInString:@"()<>@.,;:\\\"[]"];
    });
    return set;
}

+ (NSCharacterSet *)MAEncodedAtomCharacterSet
{
    static NSCharacterSet *set = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet	*cs;

        cs = [[NSMutableCharacterSet controlCharacterSet] mutableCopy];
        [cs formUnionWithCharacterSet:[self MASpecialCharacterSet]];
        [cs formUnionWithCharacterSet:[self whitespaceCharacterSet]];
        [cs invert];
        set = [cs copy];
    });
    return set;
}

+ (NSCharacterSet *)MAAtomCharacterSet
{
    static NSCharacterSet *set = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet	*cs;

        cs = [[NSMutableCharacterSet controlCharacterSet] mutableCopy];
        [cs formUnionWithCharacterSet:[self MASpecialCharacterSet]];
        [cs formUnionWithCharacterSet:[self whitespaceCharacterSet]];
        [cs invert];
        [cs formIntersectionWithCharacterSet:[self standardASCIICharacterSet]];
        set = [cs copy];
    });
    return set;
}

+ (NSCharacterSet *)MADomainCharacterSet
{
    static NSCharacterSet *set = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *cs;

        cs = [[self standardASCIICharacterSet] mutableCopy];
        [cs removeCharactersInString:@"[]\n\\"];
        set = [cs copy];
    });
    return set;
}


//---------------------------------------------------------------------------------------
//	character sets for RFC2045-2049
//---------------------------------------------------------------------------------------

+ (NSCharacterSet *)MIMETSpecialsCharacterSet
{
    static NSCharacterSet *set = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        set = [NSCharacterSet characterSetWithCharactersInString:@"()<>@,;:\\\"/[]?="];
    });
    return set;
}


+ (NSCharacterSet *)MIMETokenCharacterSet
{
    static	NSCharacterSet *set = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *workingSet;

        workingSet = [[self MIMETSpecialsCharacterSet] mutableCopy];
        [workingSet invert];
        [workingSet formIntersectionWithCharacterSet:[NSCharacterSet characterSetWithRange:NSMakeRange(32, 95)]];
        set = [workingSet copy];
    });
    return set;
}


+ (NSCharacterSet *)MIMENonTokenCharacterSet
{
    static	NSCharacterSet *set = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        set = [[self MIMETokenCharacterSet] invertedSet];
    });
    return set;
}


+ (NSCharacterSet *)MIMEHeaderDefaultLiteralCharacterSet
{
    static	NSCharacterSet *set = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *workingSet;

        workingSet = [[NSCharacterSet characterSetWithRange:NSMakeRange(32, 95)] mutableCopy];
        [workingSet removeCharactersInString:@"=?_ "];
        set = [workingSet copy];
    });
    return set;
}



//---------------------------------------------------------------------------------------
    @end
//---------------------------------------------------------------------------------------
