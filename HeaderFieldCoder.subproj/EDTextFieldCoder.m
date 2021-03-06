//---------------------------------------------------------------------------------------
//  EDTextFieldCoder.m created by erik
//  @(#)$Id: EDTextFieldCoder.m,v 2.2 2003/04/08 17:06:05 znek Exp $
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
#import "NSString+MessageUtils.h"
#import "NSData+MIME.h"
#import "EDMConstants.h"
#import "EDTextFieldCoder.h"

@interface EDTextFieldCoder(PrivateAPI)
+ (NSString *)_wrappedWord:(NSString *)aString encoding:(NSString *)encoding;
@end


//---------------------------------------------------------------------------------------
    @implementation EDTextFieldCoder
//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------
//	FACTORY
//---------------------------------------------------------------------------------------

+ (id)encoderWithText:(NSString *)value
{
    return [[self alloc] initWithText:value];
}


//---------------------------------------------------------------------------------------
//	INIT & DEALLOC
//---------------------------------------------------------------------------------------

- (id)initWithFieldBody:(NSString *)body
{
    if (!(self = [self init])) return nil;
    text = [[self class] stringByDecodingMIMEWordsInString:body];
    return self;
}


- (id)initWithText:(NSString *)value
{
    if (!(self = [self init])) return nil;
    text = [value copyWithZone:nil];
    return self;
}




//---------------------------------------------------------------------------------------
//	CODING
//---------------------------------------------------------------------------------------

- (NSString *)text
{
    return text;
}


- (NSString *)stringValue
{
    return text;
}


- (NSString *)fieldBody
{
    return [[self class] stringByEncodingString:text];
}


//---------------------------------------------------------------------------------------
//	HELPER METHODS
//---------------------------------------------------------------------------------------


+ (NSString *)stringByEncodingString:(NSString *)string
{
    NSCharacterSet	*spaceCharacterSet;
    NSScanner		*scanner;
    NSMutableString	*buffer, *chunk;
    NSString		*currentEncoding, *nextEncoding, *word, *spaces;

    spaceCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" "];
    buffer = [[NSMutableString allocWithZone:nil] init];
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
            chunk = [word mutableCopy];
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
    NSUInteger		b64Length, qpLength;

    stringData = [aString dataUsingMIMEEncoding:encoding];
    b64Rep = [stringData encodeBase64WithLineLength:(UINT_MAX - 3) andNewlineAtEnd:NO];
    qpRep = [stringData encodeHeaderQuotedPrintable];
    b64Length = [b64Rep length]; qpLength = [qpRep length];
    if((qpLength < 6) || (qpLength < [stringData length] * 3/2) || (qpLength <= b64Length))
        transferRep = qpRep;
    else
        transferRep = b64Rep;

    // Note, that this might be wrong if QP was chosen even though it was longer than B64!
    //if((length = [transferRep length] + 7 + [encoding length]) > 75)
    //    [NSException raise:NSInvalidArgumentException format:@"-[%@ %@]: Encoding of this header field body results in a MIME word which exceeds the maximum length of 75 characters. Try to split it into components that are separated by whitespaces.", NSStringFromClass(self), NSStringFromSelector(_cmd)];

    result = [[NSString allocWithZone:nil] initWithFormat:@"=?%@?%@?%@?=", encoding, (transferRep == qpRep) ? @"Q" : @"B", [NSString stringWithData:transferRep encoding:NSASCIIStringEncoding]];

    return result;
}


//---------------------------------------------------------------------------------------
    @end
//---------------------------------------------------------------------------------------
