//---------------------------------------------------------------------------------------
//  EDMessagePart.m created by erik on Mon 20-Jan-1997
//  @(#)$Id: EDMessagePart.m,v 1.1.1.1 2002-08-16 18:21:51 erik Exp $
//
//  Copyright (c) 1999-2000 by Erik Doernenburg. All rights reserved.
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
#import <EDCommon/EDCommon.h>
#import "utilities.h"
#import "NSString+MessageUtils.h"
#import "NSData+MIME.h"
#import "EDTextFieldCoder.h"
#import "EDEntityFieldCoder.h"
#import "EDMessagePart.h"

@interface EDMessagePart(PrivateAPI)
+ (NSDictionary *)_defaultFallbackHeaders;
- (NSData *)_takeHeadersFromData:(NSData *)data;
@end


//---------------------------------------------------------------------------------------
    @implementation EDMessagePart
//---------------------------------------------------------------------------------------


//---------------------------------------------------------------------------------------
//	INIT & DEALLOC
//---------------------------------------------------------------------------------------

- (id)initWithTransferData:(NSData *)data
{
    return [self initWithTransferData:data fallbackHeaderFields:nil];
}


- (id)initWithTransferData:(NSData *)data fallbackStringEncoding:(NSStringEncoding)encoding
{
    NSDictionary	*fields;
    NSString		*charset, *value;

    charset = [NSString MIMEEncodingForStringEncoding:encoding];
    value = [[[[EDEntityFieldCoder alloc] initWithValues:[NSArray arrayWithObjects:@"text", @"plain", nil] andParameters:[NSDictionary dictionaryWithObject:charset forKey:@"charset"]] autorelease] fieldBody];
    fields = [NSDictionary dictionaryWithObject:value forKey:@"content-type"];

    return [self initWithTransferData:data fallbackHeaderFields:fields];
}


- (id)initWithTransferData:(NSData *)data fallbackHeaderFields:(NSDictionary *)fields
{
    NSString	*cte;
    NSData	  	*rawData;

    [super init];
    
    if(fields != nil)
        {
        fallbackFields = [[NSMutableDictionary allocWithZone:[self zone]] initWithDictionary:[[self class] _defaultFallbackHeaders]];
        [(NSMutableDictionary *)fallbackFields addEntriesFromDictionary:fields];
        }
    else
        {
        fallbackFields = [[[self class] _defaultFallbackHeaders] retain];
        }

    if((data == nil) || ([data length] == 0))
        return self;
        
    if((rawData = [self _takeHeadersFromData:data]) == nil)
        return self;
    
    cte = [[[EDTextFieldCoder decoderWithFieldBody:[self bodyForHeaderField:@"content-transfer-encoding"]] text] stringByRemovingSurroundingWhitespace];
    [self setContentData:[rawData decodeContentWithTransferEncoding:cte]];

    return self;
}


- (id)init
{
    [super init];
    fallbackFields = nil;
    return self;
}


- (void)dealloc
{
    [fallbackFields release];
    [contentType release];
    [contentTypeParameters release];
    [contentData release];
    [super dealloc];
}


//---------------------------------------------------------------------------------------
//	TRANSFER LEVEL ACCESSOR METHODS
//---------------------------------------------------------------------------------------

- (NSData *)transferData
{
    NSMutableData	 		*transferData;
    NSData					*headerData;
    NSMutableString			*stringBuffer;
    NSEnumerator			*fieldEnum;
    EDObjectPair			*field;
    NSString				*cte;

    transferData = [NSMutableData data];

    stringBuffer = [NSMutableString string];
    fieldEnum = [[self headerFields] objectEnumerator];
    while((field = [fieldEnum nextObject]) != nil)
        {
        [stringBuffer appendString:[field firstObject]];
        [stringBuffer appendString:@": "];
#warning * should fold long headers...
        [stringBuffer appendString:[field secondObject]];
        [stringBuffer appendString:@"\r\n"];
        }
    [stringBuffer appendString:@"\r\n"];
    if((headerData = [stringBuffer dataUsingEncoding:NSASCIIStringEncoding]) == nil)
        [NSException raise:NSInternalInconsistencyException format:@"-[%@ %@]: Transfer representation of header fields contains non ASCII characters.", NSStringFromClass(isa), NSStringFromSelector(_cmd)];
    [transferData appendData:headerData];

    cte = [[[EDTextFieldCoder decoderWithFieldBody:[self bodyForHeaderField:@"content-transfer-encoding"]] text] stringByRemovingSurroundingWhitespace];
    [transferData appendData:[contentData encodeContentWithTransferEncoding:cte]];

    return transferData;
}


//---------------------------------------------------------------------------------------
//	OVERRIDES
//---------------------------------------------------------------------------------------

- (NSString *)bodyForHeaderField:(NSString *)name
{
    NSString *fieldBody;

    if((fieldBody = [super bodyForHeaderField:name]) == nil)
        fieldBody = [fallbackFields objectForKey:[name lowercaseString]];

    return fieldBody;
}


//---------------------------------------------------------------------------------------
//	CONTENT TYPE ACCESSOR METHODS
//---------------------------------------------------------------------------------------

- (void)setContentType:(EDObjectPair *)aType
{
    [self setContentType:aType withParameters:nil];
}


- (void)setContentType:(EDObjectPair *)aType withParameters:(NSDictionary *)someParameters
{
    EDEntityFieldCoder *fCoder;

    [aType retain];
    [contentType release];
    contentType = aType;
    [someParameters retain];
    [contentTypeParameters release];
    contentTypeParameters = someParameters;

    fCoder = [[EDEntityFieldCoder alloc] initWithValues:[contentType allObjects] andParameters:contentTypeParameters];
    [self setBody:[fCoder fieldBody] forHeaderField:@"Content-Type"];
    [fCoder release];
}


- (EDObjectPair *)contentType
{
    NSString 			*fBody;
    EDEntityFieldCoder	*coder;

    if((contentType == nil) && ((fBody = [self bodyForHeaderField:@"content-type"]) != nil))
        {
        coder = [EDEntityFieldCoder decoderWithFieldBody:fBody];
        contentType = [[EDObjectPair allocWithZone:[self zone]] initWithObjects:[[coder values] objectAtIndex:0]:[[coder values] objectAtIndex:1]];
        contentTypeParameters = [[coder parameters] retain];
        }
    return contentType;
}


- (NSDictionary *)contentTypeParameters
{
    [self contentType];
    return contentTypeParameters;
}


//---------------------------------------------------------------------------------------
//	CONTENT TYPE ACCESSOR METHODS
//---------------------------------------------------------------------------------------

- (void)setContentDisposition:(NSString *)aDispositionDirective
{
    [self setContentDisposition:aDispositionDirective withParameters:nil];
}


- (void)setContentDisposition:(NSString *)aDispositionDirective withParameters:(NSDictionary *)someParameters
{
    EDEntityFieldCoder *fCoder;

    [aDispositionDirective retain];
    [contentDisposition release];
    contentDisposition = aDispositionDirective;
    [someParameters retain];
    [contentDispositionParameters release];
    contentDispositionParameters = someParameters;

    fCoder = [[EDEntityFieldCoder alloc] initWithValues:[NSArray arrayWithObject:contentDisposition] andParameters:contentDispositionParameters];
    [self setBody:[fCoder fieldBody] forHeaderField:@"Content-Disposition"];
    [fCoder release];
}


- (NSString *)contentDisposition
{
    NSString 			*fBody;
    EDEntityFieldCoder	*coder;

    if((contentDisposition == nil) && ((fBody = [self bodyForHeaderField:@"content-disposition"]) != nil))
        {
        coder = [EDEntityFieldCoder decoderWithFieldBody:fBody];
        contentDisposition = [[[coder values] objectAtIndex:0] retain];
        contentDispositionParameters = [[coder parameters] retain];
        }
    return contentDisposition;
}


- (NSDictionary *)contentDispositionParameters
{
    [self contentDisposition];
    return contentDispositionParameters;
}


//---------------------------------------------------------------------------------------
//	CONTENT TRANSFER ENCODING
//---------------------------------------------------------------------------------------

- (void)setContentTransferEncoding:(NSString *)anEncoding
{
    [self setBody:anEncoding forHeaderField:@"Content-Transfer-Encoding"];
}


- (NSString *)contentTransferEncoding
{
    return [[[[EDTextFieldCoder decoderWithFieldBody:[self bodyForHeaderField:@"content-transfer-encoding"]] text] stringByRemovingSurroundingWhitespace] lowercaseString];
}


//---------------------------------------------------------------------------------------
//	CONTENT DATA ACCESSOR METHODS
//---------------------------------------------------------------------------------------

- (void)setContentData:(NSData *)data
{
    [contentData autorelease];
    contentData = [data copyWithZone:[self zone]];
}


- (NSData *)contentData
{
    return contentData;
}
    

//---------------------------------------------------------------------------------------
//	DERIVED ATTRIBUTES
//---------------------------------------------------------------------------------------

- (NSString *)pathExtensionForContentType
{	
    NSString *typeString, *subtype, *extension;

    subtype = [[self contentType] secondObject];
    typeString = [NSString stringWithFormat:@"%@/%@", [[self contentType] firstObject], subtype];

    if((extension = [NSString pathExtensionForContentType:typeString]) == nil)
        {
        if([subtype hasPrefix:@"x-"])
            extension = [subtype substringFromIndex:2];
        else
            extension = subtype;
        }

    return extension;
}



//---------------------------------------------------------------------------------------
//	DESCRIPTION
//---------------------------------------------------------------------------------------

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ 0x%x: %@>", NSStringFromClass(isa), self, [self bodyForHeaderField:@"content-type"]];
}


//---------------------------------------------------------------------------------------
//	PARSING STUFF
//---------------------------------------------------------------------------------------

+ (NSDictionary *)_defaultFallbackHeaders
{
    static NSDictionary	*defaultFallbackHeaders = nil;

    if(defaultFallbackHeaders == nil)
        {
        NSMutableDictionary  *temp;
        NSArray				 *values;
        NSDictionary		 *parameters;
        NSString			 *fBody;

        temp = [NSMutableDictionary dictionary];
        values = [NSArray arrayWithObjects:@"text", @"plain", nil];
        parameters = [NSDictionary dictionaryWithObject:MIMEAsciiStringEncoding forKey:@"charset"];
        fBody = [[[[EDEntityFieldCoder alloc] initWithValues:values andParameters:parameters] autorelease] fieldBody];
        [temp setObject:fBody forKey:@"content-type"];
        [temp setObject:MIME8BitContentTransferEncoding forKey:@"content-transfer-encoding"];
        values = [NSArray arrayWithObject:MIMEInlineContentDisposition];
        fBody = [[[[EDEntityFieldCoder alloc] initWithValues:values andParameters:nil] autorelease] fieldBody];
        [temp setObject:fBody forKey:@"content-disposition"];
        defaultFallbackHeaders = [[NSDictionary alloc] initWithDictionary:temp];
        }

    return defaultFallbackHeaders;
}


- (NSData *)_takeHeadersFromData:(NSData *)data
{
    const char		 *p, *pmax, *fnamePtr, *fbodyPtr, *eolPtr;
    NSMutableData	 *fbodyData;
    NSString 		 *name, *fbodyContents;
    EDObjectPair	 *field;
    NSRange			 bodyRange;
    NSStringEncoding encoding;
    
#warning * default encoding for headers?!    
    encoding = NSISOLatin1StringEncoding;
    name = nil;
    fnamePtr = p = [data bytes];
    pmax = p + [data length];
    fbodyPtr = NULL;
    fbodyData = nil;
    for(;p < pmax; p++)
        {
        if((*p == COLON) && (fbodyPtr == NULL))
            {
            fbodyPtr = p + 1;
            if((fbodyPtr < pmax) && (iswhitespace(*fbodyPtr)))
                fbodyPtr += 1;
            name = [NSString stringWithCString:fnamePtr length:(p - fnamePtr)];
            }
        else if(iscrlf(*p))
            {
            eolPtr = p;
            p = skipnewline(p, pmax);
            if((p < pmax) && iswhitespace(*p)) // folded header!
                {
                if(fbodyData == nil)
                    fbodyData = [NSMutableData dataWithBytes:fbodyPtr length:(eolPtr - fbodyPtr)];
                else
                    [fbodyData appendBytes:fbodyPtr length:(eolPtr - fbodyPtr)];
                fbodyPtr = p;
                }
            else
                {
                if(fbodyData == nil)
                    fbodyData = (id)[NSData dataWithBytes:fbodyPtr length:(eolPtr - fbodyPtr)];
                else
                    [fbodyData appendBytes:fbodyPtr length:(eolPtr - fbodyPtr)];
                fbodyContents = [NSString stringWithData:fbodyData encoding:encoding];
                // we know something about the implementation of addToHeaderFields ;-)
                // by uniqueing the string here we avoid creating another pair.
                name = [name sharedInstance];
                field = [[EDObjectPair allocWithZone:[self zone]] initWithObjects:name:fbodyContents];
                [self addToHeaderFields:field];
                [field release];
                fbodyData = nil;
                fnamePtr = p;
                fbodyPtr = NULL;
                if((p < pmax) && iscrlf(*p))
                    break;
                }
            }
        }

    p = skipnewline(p, pmax);
    if(p > pmax)
        return nil;
    bodyRange = NSMakeRange(p - (char *)[data bytes], pmax - p);
    return [data subdataWithRange:bodyRange];
}


//---------------------------------------------------------------------------------------
    @end
//---------------------------------------------------------------------------------------
