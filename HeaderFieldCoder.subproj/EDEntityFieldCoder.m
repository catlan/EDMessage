//---------------------------------------------------------------------------------------
//  EDEntityFieldCoder.m created by
//  @(#)$Id: EDEntityFieldCoder.m,v 2.1 2003/04/08 17:06:04 znek Exp $
//
//  Copyright (c) 1997-1999 by Erik Doernenburg. All rights reserved.
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
#import "NSString+MessageUtils.h"
#import "NSData+MIME.h"
#import "EDMConstants.h"
#import "EDEntityFieldCoder.h"

@interface EDEntityFieldCoder(PrivateAPI)
- (void)_setValues:(NSArray *)someValues;
- (void)_setParameters:(NSDictionary *)someParameters;
- (void)_takeValueFromString:(NSString *)body;
- (NSString *)_getFieldBody;
@end


//---------------------------------------------------------------------------------------
    @implementation EDEntityFieldCoder
//---------------------------------------------------------------------------------------

+ (id)encoderWithValues:(NSArray *)someValues andParameters:(NSDictionary *)someParameters
{
    return [[[self alloc] initWithValues:someValues andParameters:someParameters] autorelease];
}


//---------------------------------------------------------------------------------------
//	INIT & DEALLOC
//---------------------------------------------------------------------------------------

- (id)initWithFieldBody:(NSString *)body
{
    [self init];
    NS_DURING
        [self _takeValueFromString:body];
    NS_HANDLER
        [self autorelease];
        [localException raise];
    NS_ENDHANDLER
    return self;
}


- (id)initWithValues:(NSArray *)someValues andParameters:(NSDictionary *)someParameters
{
    [self init];
    NS_DURING
        [self _setValues:someValues];
        [self _setParameters:someParameters];
    NS_HANDLER
        [self autorelease];
        [localException raise];
    NS_ENDHANDLER
    return self;
}


- (void)dealloc
{
    [values release];
    [parameters release];
    [super dealloc];
}


//---------------------------------------------------------------------------------------
//	ACCESSOR METHODS
//---------------------------------------------------------------------------------------

- (NSArray *)values
{
    return values;
}


- (NSDictionary *)parameters
{
    return parameters;
}


- (NSString *)stringValue
{
    return [self _getFieldBody];
}


- (NSString *)fieldBody
{
    return [self _getFieldBody];
}


//---------------------------------------------------------------------------------------
//	PRIVATE ACCESSOR METHODS
//---------------------------------------------------------------------------------------

- (void)_setValues:(NSArray *)someValues
{
    NSEnumerator *valueEnum;
    NSString	 *value;

    [values autorelease];
    values = [[NSMutableArray allocWithZone:[self zone]] initWithCapacity:[someValues count]];
    valueEnum = [someValues objectEnumerator];
    while((value = [valueEnum nextObject]) != nil)
        {
        if([value rangeOfCharacterFromSet:[NSCharacterSet MIMENonTokenCharacterSet]].length != 0)
            [NSException raise:NSInvalidArgumentException format:@"invalid char in '%@'", value];
        value = [value lowercaseString];
        [(NSMutableArray *)values addObject:value];
        }
}


- (void)_setParameters:(NSDictionary *)someParameters
{
    NSEnumerator *attrEnum;
    NSString	 *attr, *value;

    [parameters autorelease];
    parameters = [[NSMutableDictionary allocWithZone:[self zone]] init];
    attrEnum = [someParameters keyEnumerator];
    while((attr = [attrEnum nextObject]) != nil)
    {
        value = [someParameters objectForKey:attr];
        if([attr rangeOfCharacterFromSet:[NSCharacterSet MIMENonTokenCharacterSet]].length != 0)
            [NSException raise:NSInvalidArgumentException format:@"invalid char in parameter '%@'", attr];
        /*if([value rangeOfCharacterFromSet:[NSCharacterSet MIMENonTokenCharacterSet]].length != 0)
        {
            if([value rangeOfCharacterFromSet:[[NSCharacterSet standardASCIICharacterSet] invertedSet]].length != 0)
                [NSException raise:NSInvalidArgumentException format:@"invalid char in attribute value '%@'", value];
            else if([value rangeOfString:DOUBLEQUOTE].length != 0)
                [NSException raise:NSInvalidArgumentException format:@"invalid doublequote in attribute value '%@'", value];
        }*/
        attr = [attr lowercaseString];
        [(NSMutableDictionary *)parameters setObject:value forKey:attr];
    }
}


//---------------------------------------------------------------------------------------
//	CODING HELPER METHODS
//---------------------------------------------------------------------------------------

- (void)_takeValueFromString:(NSString *)body
{
    NSArray					*fieldBodyParts;
    NSEnumerator			*fieldBodyPartEnum;
    NSString				*mainPart, *parameterPart, *attr, *attrValue, *value;
    NSScanner				*scanner;
    NSMutableArray			*scannedValues;
    NSMutableDictionary		*scannedParameters;

    body = [body stringByRemovingSurroundingWhitespace]; // I've seen this!
    fieldBodyParts = [body componentsSeparatedByString:@";"];
    fieldBodyPartEnum = [fieldBodyParts objectEnumerator];

    if((mainPart = [fieldBodyPartEnum nextObject]) == nil)
        [NSException raise:EDMessageFormatException format:@"no value in '%@'", self];

    scannedValues = [NSMutableArray array];
    scanner = [NSScanner scannerWithString:mainPart];
    do
        {
        if([scanner scanCharactersFromSet:[NSCharacterSet MIMETokenCharacterSet] intoString:&value] == NO)
            [NSException raise:EDMessageFormatException format:@"invalid value format; found '%@'", body];
        value = [value lowercaseString];
        [scannedValues addObject:value];
        }
    while([scanner scanString:@"/" intoString:NULL] == YES);
    values = [[NSArray allocWithZone:[self zone]] initWithArray:scannedValues];

    // forgiving, ie. simply skips syntactially incorrect attribute/value pairs...
    scannedParameters = [[NSMutableDictionary allocWithZone:[self zone]] init];
    while((parameterPart = [fieldBodyPartEnum nextObject]) != nil)
        {
        scanner = [NSScanner scannerWithString:parameterPart];
        if([scanner scanCharactersFromSet:[NSCharacterSet MIMETokenCharacterSet] intoString:&attr] == NO)
            continue;
        attr = [attr lowercaseString];
        if([scanner scanString:@"=" intoString:NULL] == NO)
            continue;
        if([scanner scanString:DOUBLEQUOTE intoString:NULL] == NO)
            {
            if([scanner scanCharactersFromSet:[NSCharacterSet MIMETokenCharacterSet] intoString:&attrValue] == YES)
                [scannedParameters setObject:attrValue forKey:attr];
            }
        else
            {
            if([scanner scanUpToString:DOUBLEQUOTE intoString:&attrValue] == YES)
                [scannedParameters setObject:attrValue forKey:attr];
            }
        }
    parameters = [[NSDictionary allocWithZone:[self zone]] initWithDictionary:scannedParameters];
}


- (NSString *)_getFieldBody
{
    NSMutableString	*fieldBody;
    NSString		*attr, *attrValue;
    NSEnumerator	*attrEnumerator;

    fieldBody = [NSMutableString string];
    [fieldBody appendString:[values componentsJoinedByString:@"/"]];
    attrEnumerator = [parameters keyEnumerator];
    while((attr = [attrEnumerator nextObject]) != nil)
    {
        attrValue = [parameters objectForKey:attr];
        attrValue = [EDEntityFieldCoder stringByEncodingString:attrValue];
        if([attrValue rangeOfCharacterFromSet:[NSCharacterSet MIMENonTokenCharacterSet]].length != 0 || [attrValue rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].length != 0 )
            attrValue = [NSString stringWithFormat:@"\"%@\"", attrValue];
        [fieldBody appendFormat:@"; %@=%@", attr, attrValue];
    }
    return fieldBody;
}

// ----

+ (NSString *)stringByEncodingString:(NSString *)string
{
    NSCharacterSet	*spaceCharacterSet;
    NSScanner		*scanner;
    NSMutableString	*buffer, *chunk;
    NSString		*currentEncoding, *nextEncoding, *word, *spaces;
    
    spaceCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" "];
    buffer = [[[NSMutableString allocWithZone:[(NSObject *)self zone]] init] autorelease];
    scanner = [NSScanner scannerWithString:string];
    [scanner setCharactersToBeSkipped:nil];
    
    chunk = [NSMutableString string];
    currentEncoding = nil;
    do
    {
        if([scanner scanCharactersFromSet:spaceCharacterSet intoString:&spaces] == NO)
            spaces = @"";
        if([scanner scanUpToCharactersFromSet:spaceCharacterSet intoString:&word] == NO)
            word = nil;
        
        nextEncoding = [word recommendedMIMEEncoding];
        if((nextEncoding != currentEncoding) || ([chunk length] + [word length] + 7 + [currentEncoding length] > 75) || (word == nil))
        {
            if([chunk length] > 0)
            {
                if([currentEncoding caseInsensitiveCompare:MIMEAsciiStringEncoding] != NSOrderedSame)
                    [buffer appendString:[self _wrappedWord:chunk encoding:currentEncoding]];
                else
                    [buffer appendString:chunk];
            }
            [buffer appendString:spaces];
            currentEncoding = nextEncoding;
            chunk = [[word mutableCopy] autorelease];
        }
        else
        {
            [chunk appendString:spaces];
            [chunk appendString:word];
        }
    }
    while([chunk length] > 0);
    
    return buffer;
}

#ifndef UINT_MAX
// doesn't really matter, 4 Gig should be enough for everybody.... ;-)
#define UINT_MAX 0xffffffff
#endif

+ (NSString *)_wrappedWord:(NSString *)aString encoding:(NSString *)encoding
{
    NSData			*stringData, *b64Rep, *qpRep, *transferRep;
    NSString		*result;
    NSUInteger		b64Length, qpLength, length;
    
    stringData = [aString dataUsingMIMEEncoding:encoding];
    b64Rep = [stringData encodeBase64WithLineLength:(UINT_MAX - 3) andNewlineAtEnd:NO];
    qpRep = [stringData encodeHeaderQuotedPrintable];
    b64Length = [b64Rep length]; qpLength = [qpRep length];
    if((qpLength < 6) || (qpLength < [stringData length] * 3/2) || (qpLength <= b64Length))
        transferRep = qpRep;
    else
        transferRep = b64Rep;
    
    // Note, that this might be wrong if QP was chosen even though it was longer than B64!
    if((length = [transferRep length] + 7 + [encoding length]) > 75)
        [NSException raise:NSInvalidArgumentException format:@"-[%@ %@]: Encoding of this header field body results in a MIME word which exceeds the maximum length of 75 characters. Try to split it into components that are separated by whitespaces.", NSStringFromClass(self), NSStringFromSelector(_cmd)];
    
    result = [[[NSString allocWithZone:[(NSObject *)self zone]] initWithFormat:@"=?%@?%@?%@?=", encoding, (transferRep == qpRep) ? @"Q" : @"B", [NSString stringWithData:transferRep encoding:NSASCIIStringEncoding]] autorelease];
    
    return result;
}


//---------------------------------------------------------------------------------------
    @end
//---------------------------------------------------------------------------------------
