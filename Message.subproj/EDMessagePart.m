//---------------------------------------------------------------------------------------
//  EDMessagePart.m created by erik on Mon 20-Jan-1997
//  @(#)$Id: EDMessagePart.m,v 2.4 2003/10/21 16:50:12 znek Exp $
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
#import "EDCommon.h"
#import "utilities.h"
#import "NSString+MessageUtils.h"
#import "NSData+MIME.h"
#import "EDTextFieldCoder.h"
#import "EDEntityFieldCoder.h"
#import "EDMessagePart.h"

@interface EDMessagePart(PrivateAPI)
+ (NSDictionary *)_defaultFallbackHeaders;
- (NSRange)_takeHeadersFromData:(NSData *)data;
- (void)_takeContentDataFromOriginalTransferData;
- (void)_forgetOriginalTransferData;
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
    value = [[[EDEntityFieldCoder alloc] initWithValues:[NSArray arrayWithObjects:@"text", @"plain", nil] andParameters:[NSDictionary dictionaryWithObject:charset forKey:@"charset"]] fieldBody];
    fields = [NSDictionary dictionaryWithObject:value forKey:@"content-type"];

    return [self initWithTransferData:data fallbackHeaderFields:fields];
}


- (id)initWithTransferData:(NSData *)data fallbackHeaderFields:(NSDictionary *)fields
{
    if (!(self = [super init])) return nil;
    
    if(fields != nil)
        {
        fallbackFields = [[NSMutableDictionary allocWithZone:nil] initWithDictionary:[[self class] _defaultFallbackHeaders]];
        [(NSMutableDictionary *)fallbackFields addEntriesFromDictionary:fields];
        }
    else
        {
        fallbackFields = [[self class] _defaultFallbackHeaders];
        }

    if((data == nil) || ([data length] == 0))
        return self;

    bodyRange = [self _takeHeadersFromData:data];
    originalTransferData = data;

    return self;
}


- (id)init
{
    if (!(self = [super init])) return nil;
    fallbackFields = nil;
    return self;
}




//---------------------------------------------------------------------------------------
//	TRANSFER LEVEL ACCESSOR METHODS
//---------------------------------------------------------------------------------------

- (NSData *)transferData:(NSError **)error
{
    NSMutableData	*transferData;
    NSData			*headerData;
    NSMutableString	*stringBuffer, *headerLine;
    NSEnumerator	*fieldEnum;
    EDObjectPair	*field;

    if(originalTransferData != nil)
        return originalTransferData;

    // Make sure we have an encoding that we can use (we fall back to MIME 8Bit)
    if([contentData isValidTransferEncoding:[self contentTransferEncoding]] == NO)
        [self setContentTransferEncoding:MIME8BitContentTransferEncoding];

    transferData = [NSMutableData data];

    stringBuffer = [NSMutableString string];
    fieldEnum = [[self headerFields] objectEnumerator];
    while((field = [fieldEnum nextObject]) != nil)
        {
        headerLine = [[NSMutableString alloc] initWithString:[field firstObject]];
        [headerLine appendString:@": "];
        [headerLine appendString:[field secondObject]];
        [headerLine appendString:@"\r\n"];
        [stringBuffer appendString:[headerLine stringByFoldingToLimit:998]];
        }

    [stringBuffer appendString:@"\r\n"];
    if((headerData = [stringBuffer dataUsingEncoding:NSASCIIStringEncoding]) == nil)
    {
        //[NSException raise:NSInternalInconsistencyException format:@"-[%@ %@]: Transfer representation of header fields contains non ASCII characters.", NSStringFromClass(isa), NSStringFromSelector(_cmd)];
        if (error != NULL)
        {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"-[%@ %@]: Transfer representation of header fields contains non ASCII characters.", NSStringFromClass([self class]), NSStringFromSelector(_cmd)]};
            *error = [[NSError alloc] initWithDomain:@"EDMessage" code:0 userInfo:userInfo];
        }
    }
    [transferData appendData:headerData];

    [transferData appendData:[contentData encodeContentWithTransferEncoding: [self contentTransferEncoding]]];

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


- (void)setBody:(NSString *)fieldBody forHeaderField:(NSString *)fieldName
{
    [self _forgetOriginalTransferData];
    [super setBody: fieldBody forHeaderField: fieldName];
}


- (void)addToHeaderFields:(EDObjectPair *)headerField
{
    [self _forgetOriginalTransferData];
    [super addToHeaderFields: headerField];
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

    contentType = aType;
    contentTypeParameters = someParameters;

    fCoder = [[EDEntityFieldCoder alloc] initWithValues:[contentType allObjects] andParameters:contentTypeParameters];
    [self setBody:[fCoder fieldBody] forHeaderField:@"Content-Type"];
}


- (EDObjectPair *)contentType
{
    NSString 			*fBody;
    EDEntityFieldCoder	*coder;

    if((contentType == nil) && ((fBody = [self bodyForHeaderField:@"content-type"]) != nil))
        {
        coder = [EDEntityFieldCoder decoderWithFieldBody:fBody];
        contentType = [[EDObjectPair allocWithZone:nil] initWithObjects:[[coder values] objectAtIndex:0]:[[coder values] objectAtIndex:1]];
        contentTypeParameters = [coder parameters];
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

    contentDisposition = aDispositionDirective;
    contentDispositionParameters = someParameters;

    fCoder = [[EDEntityFieldCoder alloc] initWithValues:[NSArray arrayWithObject:contentDisposition] andParameters:contentDispositionParameters];
    [self setBody:[fCoder fieldBody] forHeaderField:@"Content-Disposition"];
}


- (NSString *)contentDisposition
{
    NSString 			*fBody;
    EDEntityFieldCoder	*coder;

    if((contentDisposition == nil) && ((fBody = [self bodyForHeaderField:@"content-disposition"]) != nil))
        {
        coder = [EDEntityFieldCoder decoderWithFieldBody:fBody];
        contentDisposition = [[coder values] objectAtIndex:0];
        contentDispositionParameters = [coder parameters];
        }
    return contentDisposition;
}


- (NSDictionary *)contentDispositionParameters
{
    [self contentDisposition];
    return contentDispositionParameters;
}


- (NSString *)attachmentFilename
{
    NSString *attachmentFilename = [[self contentDispositionParameters] objectForKey:@"filename"];
    if (!attachmentFilename)
    {
        attachmentFilename = [[self contentTypeParameters] objectForKey:@"name"];
    }
    return attachmentFilename;
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
    [self _forgetOriginalTransferData];
    contentData = [data copyWithZone:nil];
}


- (NSData *)contentData
{
    if((contentData == nil) && (originalTransferData != nil))
       [self _takeContentDataFromOriginalTransferData];
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
    return [NSString stringWithFormat:@"<%@ %p: %@>", NSStringFromClass([self class]), self, [self bodyForHeaderField:@"content-type"]];
}


//---------------------------------------------------------------------------------------
//	INTERNAL STUFF
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
        fBody = [[[EDEntityFieldCoder alloc] initWithValues:values andParameters:parameters] fieldBody];
        [temp setObject:fBody forKey:@"content-type"];
        [temp setObject:MIME8BitContentTransferEncoding forKey:@"content-transfer-encoding"];
        values = [NSArray arrayWithObject:MIMEInlineContentDisposition];
        fBody = [[[EDEntityFieldCoder alloc] initWithValues:values andParameters:nil] fieldBody];
        [temp setObject:fBody forKey:@"content-disposition"];
        defaultFallbackHeaders = [[NSDictionary alloc] initWithDictionary:temp];
        }

    return defaultFallbackHeaders;
}


- (NSRange)_takeHeadersFromData:(NSData *)data
{
    const char		 *p, *pmax, *fnamePtr, *fbodyPtr, *eolPtr;
    NSMutableData	 *fbodyData;
    NSString 		 *name, *fbodyContents;
    EDObjectPair	 *field;
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
            name = [[NSString alloc] initWithBytes:fnamePtr length:(p - fnamePtr) encoding:NSUTF8StringEncoding];
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
                // Ignore header fields without body; which shouldn't exist...
                if(fbodyPtr == NULL)
                    continue;
                
                if(fbodyData == nil)
                    fbodyData = (id)[NSData dataWithBytes:fbodyPtr length:(eolPtr - fbodyPtr)];
                else
                    [fbodyData appendBytes:fbodyPtr length:(eolPtr - fbodyPtr)];
                fbodyContents = [NSString stringWithData:fbodyData encoding:encoding];
                field = [[EDObjectPair allocWithZone:nil] initWithObjects:name:fbodyContents];
                [self addToHeaderFields:field];
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
        return NSMakeRange(-1, 0);
    return NSMakeRange(p - (char *)[data bytes], pmax - p);
}


- (void)_takeContentDataFromOriginalTransferData
{
    NSString 	*cte;
    NSData		*rawData;

    if(originalTransferData == nil)
        [NSException raise:NSInternalInconsistencyException format:@"-[%@ %@]: Original transfer data not available anymore.", NSStringFromClass([self class]), NSStringFromSelector(_cmd)];

    // If we have a contentData already, it must have been created from the original before
    if(contentData != nil)
        return;

    cte = [self contentTransferEncoding];
    rawData = [originalTransferData subdataWithRange:bodyRange];
    contentData = [rawData decodeContentWithTransferEncoding:cte];
}


- (void)_forgetOriginalTransferData
{
    if(originalTransferData == nil)
        return;

    if(bodyRange.length > 0)
        [self _takeContentDataFromOriginalTransferData];

    originalTransferData = nil;
}


//---------------------------------------------------------------------------------------
    @end
//---------------------------------------------------------------------------------------
