//---------------------------------------------------------------------------------------
//  EDHeaderFieldCoder.m created by erik on Sun 24-Oct-1999
//  @(#)$Id: EDHeaderFieldCoder.m,v 2.1 2003/04/08 17:06:05 znek Exp $
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
#import "EDHeaderFieldCoder.h"
#import "NSData+MIME.h"
#import "EDMConstants.h"


#define EDLS_MALFORMED_MIME_HEADER_WORD \
NSLocalizedString(@"Syntax error in MIME header word \"%@\"", "Reason for exception which is raised when a MIME header word is encountered that is syntactically malformed.")

#define EDLS_UNKNOWN_ENCODING_SPEC \
NSLocalizedString(@"Unknown encoding specifier in header field; found \"%@\"", "Reason for exception which is raised when an unknown encoding specifier is found.")


//---------------------------------------------------------------------------------------
    @implementation EDHeaderFieldCoder
//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------
//	FACTORY
//---------------------------------------------------------------------------------------

+ (id)decoderWithFieldBody:(NSString *)fieldBody
{
    return [[self alloc] initWithFieldBody:fieldBody];
}


//---------------------------------------------------------------------------------------
//	INIT & DEALLOC
//---------------------------------------------------------------------------------------

- (id)initWithFieldBody:(NSString *)body
{
    [self methodIsAbstract:_cmd];
    return self;
}




//---------------------------------------------------------------------------------------
//	CODING
//---------------------------------------------------------------------------------------

- (NSString *)stringValue
{
    [self methodIsAbstract:_cmd];
    return nil; // keep compiler happy...
}


- (NSString *)fieldBody
{
   [self methodIsAbstract:_cmd];
    return nil; // keep compiler happy...
}




//---------------------------------------------------------------------------------------
//	HELPER METHODS
//---------------------------------------------------------------------------------------

+ (NSString *)stringByDecodingMIMEWordsInString:(NSString *)fieldBody
{
    NSMutableString		*result;
    NSScanner			*scanner;
    NSString			*chunk, *charset, *transferEncoding, *previousChunk, *decodedWord;
    NSStringEncoding	stringEncoding;
    NSData				*wContents;
    BOOL				hasSeenEncodedWord;
    
    result = [NSMutableString string];
    hasSeenEncodedWord = NO;
    scanner = [NSScanner scannerWithString:fieldBody];
    [scanner setCharactersToBeSkipped:nil];
    while([scanner isAtEnd] == NO)
    {
        if([scanner scanUpToString:@"=?" intoString:&chunk] == YES)
        {
            if((hasSeenEncodedWord == NO) || ([chunk isWhitespace] == NO))
                [result appendString:chunk];
        }
        if([scanner scanString:@"=?" intoString:NULL] == YES)
        {
            previousChunk = chunk;
            if(([scanner scanUpToString:@"?" intoString:&charset] == NO) ||
               ([scanner scanString:@"?" intoString:NULL] == NO) ||
               ([scanner scanUpToString:@"?" intoString:&transferEncoding] == NO) ||
               ([scanner scanString:@"?" intoString:NULL] == NO) ||
               ([scanner scanUpToString:@"?=" intoString:&chunk] == NO) ||
               ([scanner scanString:@"?=" intoString:NULL] == NO))
            {
                [NSException raise:EDMessageFormatException format:EDLS_MALFORMED_MIME_HEADER_WORD, fieldBody];
                if([previousChunk isWhitespace])
                    [result appendString:previousChunk];
                hasSeenEncodedWord = NO;
            }
            else
            {
                wContents = [chunk dataUsingEncoding:NSASCIIStringEncoding];
                if([transferEncoding caseInsensitiveCompare:@"Q"] == NSOrderedSame)
                    wContents = [wContents decodeHeaderQuotedPrintable];
                else if([transferEncoding caseInsensitiveCompare:@"B"] == NSOrderedSame)
                    wContents = [wContents decodeBase64];
                else
                    [NSException raise:EDMessageFormatException format:EDLS_UNKNOWN_ENCODING_SPEC, transferEncoding];
                charset = [charset lowercaseString];
                if((stringEncoding = [NSString stringEncodingForMIMEEncoding:charset]) == 0)
                    stringEncoding = NSASCIIStringEncoding;
                // Only very few string encodings make malformed words possible but of course,
                // if there is something to break a user agent will. In this case stringWithData
                // returns nil by the way.
                if((decodedWord = [NSString stringWithData:wContents encoding:stringEncoding]) != nil)
                    [result appendString:decodedWord];
                hasSeenEncodedWord = YES;
            }
        }
    }
    return result;
}

//---------------------------------------------------------------------------------------
    @end
//---------------------------------------------------------------------------------------
