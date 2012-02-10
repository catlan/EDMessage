//---------------------------------------------------------------------------------------
//  EDTextContentCoder.m created by erik on Fri 12-Nov-1999
//  @(#)$Id: EDTextContentCoder.m,v 2.1 2003-04-08 17:06:03 znek Exp $
//
//  Copyright (c) 1997-2000 by Erik Doernenburg. All rights reserved.
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

#ifndef EDMESSAGE_WOBUILD

//#import <AppKit/AppKit.h>
#import <EDCommon/EDCommon.h>
#import "NSString+MessageUtils.h"
#import "EDMessagePart.h"
#import "EDMConstants.h"
#import "EDTextContentCoder.h"

@interface EDTextContentCoder(PrivateAPI)
- (NSString *)_stringFromMessagePart:(EDMessagePart *)mpart;
- (void)_takeTextFromPlainTextMessagePart:(EDMessagePart *)mpart;
- (void)_takeTextFromHTMLMessagePart:(EDMessagePart *)mpart;
@end


//---------------------------------------------------------------------------------------
    @implementation EDTextContentCoder
//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------
//	CAPABILITIES
//---------------------------------------------------------------------------------------

+ (BOOL)canDecodeMessagePart:(EDMessagePart *)mpart
{
    NSString	*subtype, *charset;

    if([[[mpart contentType] firstObject] isEqualToString:@"text"] == NO)
       return NO;

    charset = [[mpart contentTypeParameters] objectForKey:@"charset"];
    if((charset != nil) && ([NSString stringEncodingForMIMEEncoding:charset] == 0))
        return NO;

    subtype = [[mpart contentType] secondObject];
    if([subtype isEqualToString:@"plain"] || [subtype isEqualToString:@"enriched"] || [subtype isEqualToString:@"html"])
        return YES;

    return NO;
}


//---------------------------------------------------------------------------------------
//	INIT & DEALLOC
//---------------------------------------------------------------------------------------

- (id)initWithMessagePart:(EDMessagePart *)mpart
{
    [super init];
    if([[[mpart contentType] firstObject] isEqualToString:@"text"])
        {
        if([[[mpart contentType] secondObject] isEqualToString:@"plain"])
            [self _takeTextFromPlainTextMessagePart:mpart];
        else if([[[mpart contentType] secondObject] isEqualToString:@"html"])
            [self _takeTextFromHTMLMessagePart:mpart];
        }
    return self;
}


- (void)dealloc
{
    [text release];
    [super dealloc];
}


//---------------------------------------------------------------------------------------
//	ATTRIBUTES
//---------------------------------------------------------------------------------------

- (NSAttributedString *)text
{
    return text;
}


//---------------------------------------------------------------------------------------
//	DECODING
//---------------------------------------------------------------------------------------

- (NSString *)_stringFromMessagePart:(EDMessagePart *)mpart
{
    NSString			*charset;
    NSStringEncoding	textEncoding;

    if((charset = [[mpart contentTypeParameters] objectForKey:@"charset"]) == nil)
        charset = MIMEAsciiStringEncoding;
    if((textEncoding = [NSString stringEncodingForMIMEEncoding:charset]) > 0)
        return [NSString stringWithData:[mpart contentData] encoding:textEncoding];
    return nil;
}


- (void)_takeTextFromPlainTextMessagePart:(EDMessagePart *)mpart
{
    NSString *string;
    
    if((string = [self _stringFromMessagePart:mpart]) != nil)
        text = [[NSAttributedString allocWithZone:[self zone]] initWithString:string];
}


- (void)_takeTextFromHTMLMessagePart:(EDMessagePart *)mpart
{
    NSString			*charset;
    NSStringEncoding	textEncoding;
    NSData				*data;

    if((charset = [[mpart contentTypeParameters] objectForKey:@"charset"]) == nil)
        charset = MIMEAsciiStringEncoding;
    if((textEncoding = [NSString stringEncodingForMIMEEncoding:charset]) == 0)
        [NSException raise:EDMessageFormatException format:@"Invalid charset in message part; found '%@'", charset];
    data = [[NSString stringWithData:[mpart contentData] encoding:textEncoding] dataUsingEncoding:NSUnicodeStringEncoding];
    text = [[NSAttributedString allocWithZone:[self zone]] initWithHTML:data documentAttributes:NULL];
}


//---------------------------------------------------------------------------------------
    @end
//---------------------------------------------------------------------------------------

#endif
