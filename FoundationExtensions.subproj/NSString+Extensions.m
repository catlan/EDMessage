//---------------------------------------------------------------------------------------
//  NSString+printf.m created by erik on Sat 27-Sep-1997
//  @(#)$Id: NSString+Extensions.m,v 2.1 2003-04-08 16:51:35 znek Exp $
//
//  Copyright (c) 1997-2000,2008 by Erik Doernenburg. All rights reserved.
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

#import "NSString+Extensions.h"
#import "EDObjectPair.h"


#if !defined(TARGET_OS_IPHONE) || !TARGET_OS_IPHONE
#import <Cocoa/Cocoa.h>
#endif

@interface NSString(EDExtensionsPrivateAPI)
+ (NSDictionary *)_contentTypeExtensionMapping;
@end



//=======================================================================================
    @implementation NSString(EDExtensions)
//=======================================================================================

/*" Various common extensions to #NSString. "*/

NSString *MIMEAsciiStringEncoding = @"us-ascii";
NSString *MIMELatin1StringEncoding = @"iso-8859-1";
NSString *MIMELatin2StringEncoding = @"iso-8859-2";
NSString *MIME2022JPStringEncoding = @"iso-2022";
NSString *MIMEUTF8StringEncoding = @"utf-8";

NSString *MIMEApplicationContentType = @"application";
NSString *MIMEImageContentType		 = @"image";
NSString *MIMEAudioContentType		 = @"audio";
NSString *MIMEMessageContentType 	 = @"message";
NSString *MIMEMultipartContentType 	 = @"multipart";
NSString *MIMETextContentType 		 = @"text";
NSString *MIMEVideoContentType       = @"video";

NSString *MIMEAlternativeMPSubtype 	 = @"alternative";
NSString *MIMEMixedMPSubtype 		 = @"mixed";
NSString *MIMEParallelMPSubtype 	 = @"parallel";
NSString *MIMEDigestMPSubtype 		 = @"digest";
NSString *MIMERelatedMPSubtype 		 = @"related";

NSString *MIMEInlineContentDisposition = @"inline";
NSString *MIMEAttachmentContentDisposition = @"attachment";


static NSFileHandle *stdoutFileHandle = nil;
static NSLock *printfLock = nil;
static NSCharacterSet *iwsSet = nil;


//---------------------------------------------------------------------------------------
//	CONVENIENCE CONSTRUCTORS
//---------------------------------------------------------------------------------------

/*" Convenience factory method. "*/

+ (NSString *)stringWithData:(NSData *)data encoding:(NSStringEncoding)encoding
{
    return [[NSString alloc] initWithData:data encoding:encoding];
}


//---------------------------------------------------------------------------------------
//	VARIOUS EXTENSIONS
//---------------------------------------------------------------------------------------

/*" Returns a copy of the receiver with all whitespace left of the first non-whitespace character and right of the last whitespace character removed. "*/

- (NSString *)stringByRemovingSurroundingWhitespace
{
    NSRange		start, end, result;

    if(iwsSet == nil)
        iwsSet = [[NSCharacterSet whitespaceCharacterSet] invertedSet];

    start = [self rangeOfCharacterFromSet:iwsSet];
    if(start.length == 0)
        return @""; // string is empty or consists of whitespace only

    end = [self rangeOfCharacterFromSet:iwsSet options:NSBackwardsSearch];
    if((start.location == 0) && (end.location == [self length] - 1))
        return self;

    result = NSMakeRange(start.location, end.location + end.length - start.location);

    return [self substringWithRange:result];	
}


/*" Returns YES if the receiver consists of whitespace only. "*/

- (BOOL)isWhitespace
{
    if(iwsSet == nil)
        iwsSet = [[NSCharacterSet whitespaceCharacterSet] invertedSet];

    return ([self rangeOfCharacterFromSet:iwsSet].length == 0);

}


/*" Returns a copy of the receiver with all whitespace removed. "*/

- (NSString *)stringByRemovingWhitespace
{
    return [self stringByRemovingCharactersFromSet:[NSCharacterSet whitespaceCharacterSet]];
}


/*" Returns a copy of the receiver with all characters from %set removed. "*/

- (NSString *)stringByRemovingCharactersFromSet:(NSCharacterSet *)set
{
    NSMutableString	*temp;

    if([self rangeOfCharacterFromSet:set options:NSLiteralSearch].length == 0)
        return self;
    temp = [self mutableCopyWithZone:nil];
    [temp removeCharactersInSet:set];

    return temp;
}



//---------------------------------------------------------------------------------------
//	FACTORY METHODS
//---------------------------------------------------------------------------------------

/*" Creates and returns a string by converting the bytes in data using the string encoding described by %charsetName. If no NSStringEncoding corresponds to %charsetName this method returns !{nil}. "*/

+ (NSString *)stringWithData:(NSData *)data MIMEEncoding:(NSString *)charsetName
{
    return [[NSString alloc] initWithData:data MIMEEncoding:charsetName];
}


/*" Creates and returns a string by copying %length characters from %buffer and coverting these into a string using the string encoding described by %charsetName. If no NSStringEncoding corresponds to %charsetName this method returns !{nil}. "*/

+ (NSString *)stringWithBytes:(const void *)buffer length:(unsigned int)length MIMEEncoding:(NSString *)charsetName
{
    return [[NSString alloc] initWithData:[NSData dataWithBytes:buffer length:length] MIMEEncoding:charsetName];
}


//---------------------------------------------------------------------------------------
//	Converting to/from byte representations
//---------------------------------------------------------------------------------------

/*" Initialises a newly allocated string by converting the bytes in buffer using the string encoding described by %charsetName. If no NSStringEncoding corresponds to %charsetName this method returns !{nil}. "*/

- (id)initWithData:(NSData *)buffer MIMEEncoding:(NSString *)charsetName
{
    NSStringEncoding encoding;

    if((encoding = [NSString stringEncodingForMIMEEncoding:charsetName]) == 0)
        return nil; // Behaviour has changed (2001/08/03).
    return [self initWithData:buffer encoding:encoding];
}


/*" Returns an NSData object containing a representation of the receiver in the encoding described by %charsetName. If no NSStringEncoding corresponds to %charsetName this method returns !{nil}. "*/

- (NSData *)dataUsingMIMEEncoding:(NSString *)charsetName
{
    NSStringEncoding encoding;

    if((encoding = [NSString stringEncodingForMIMEEncoding:charsetName]) == 0)
        return nil;
    return [self dataUsingEncoding:encoding];
}


//---------------------------------------------------------------------------------------
//	NSStringEncoding vs. MIME Encoding
//---------------------------------------------------------------------------------------

+ (NSStringEncoding)stringEncodingForMIMEEncoding:(NSString *)charsetName
{
    CFStringEncoding cfEncoding;

    if(charsetName == nil)
        return 0;

    charsetName = [charsetName lowercaseString];
    cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)charsetName);
    if(cfEncoding == kCFStringEncodingInvalidId)
        return 0;
    return CFStringConvertEncodingToNSStringEncoding(cfEncoding);
}


+ (NSString *)MIMEEncodingForStringEncoding:(NSStringEncoding)nsEncoding
{
    CFStringEncoding cfEncoding;

    cfEncoding = CFStringConvertNSStringEncodingToEncoding(nsEncoding);
    return (NSString *)CFStringConvertEncodingToIANACharSetName(cfEncoding);
}


- (NSString *)recommendedMIMEEncoding
{
    static CFStringEncoding preferredEncodings[] = {
        kCFStringEncodingASCII,
        kCFStringEncodingISOLatin1,
        kCFStringEncodingISOLatin2,
        // no constants available for ISO8859-3 through ISO8859-15
        kCFStringEncodingISOLatin3,
        kCFStringEncodingISOLatin4,
        kCFStringEncodingISOLatinCyrillic,
        kCFStringEncodingISOLatinArabic,
        kCFStringEncodingISOLatinGreek,
        kCFStringEncodingISOLatinHebrew,
        kCFStringEncodingISOLatin5,
        kCFStringEncodingISOLatin6,
        kCFStringEncodingISOLatinThai,
        kCFStringEncodingISOLatin7,
        kCFStringEncodingISOLatin8,
        kCFStringEncodingISOLatin9,
        kCFStringEncodingUTF8,
        0 };
    
    
    CFStringEncoding *encodingPtr;

    for(encodingPtr = preferredEncodings; *encodingPtr != 0; encodingPtr++)
        {
        if([self canBeConvertedToEncoding:CFStringConvertEncodingToNSStringEncoding(*encodingPtr)])
            return [NSString MIMEEncodingForStringEncoding:CFStringConvertEncodingToNSStringEncoding(*encodingPtr)];
        }

    return [NSString MIMEEncodingForStringEncoding:[self smallestEncoding]];
}


//---------------------------------------------------------------------------------------
//	TYPE / FILENAME EXTENSION MAPPING
//---------------------------------------------------------------------------------------

static NSMutableDictionary *teTable = nil;


+ (NSDictionary *)_contentTypeExtensionMapping
{
    if(teTable == nil)
        {
        teTable = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                       // Application types
                       @"application/postscript", @"ps",
                       
                       // Message types
                       @"message/rfc822", @"txt", 
                       
                       // Image types
                       @"image/gif", @"gif", 
                       @"image/jpeg", @"jpg", 
                       @"image/jpeg", @"jpe", 
                       @"image/ief", @"ief", 
                       @"image/png", @"png", 
                       @"image/tiff", @"tif", 
                       @"image/tiff", @"tiff", 
                       @"image/jpeg", @"jpeg", 
                       
                       // Audio types
                       @"audio/basic", @"au", 
                       @"audio/x-realaudio", @"ra", 
                       @"audio/basic", @"snd", 
                       @"audio/midi", @"mid", 
                       @"audio/midi", @"kar", 
                       @"audio/mpeg", @"mp2", 
                       @"audio/x-aiff", @"aif", 
                       @"audio/x-pn-realaudio", @"ram", 
                       @"audio/x-pn-realaudio-plugin", @"rpm", 
                       @"audio/x-wav", @"wav", 
                       @"audio/midi", @"midi", 
                       @"audio/mpeg", @"mpga", 
                       @"audio/x-aiff", @"aiff", 
                       @"audio/x-aiff", @"aifc", 
                       
                       // Video types
                       @"video/quicktime", @"qt", 
                       @"video/x-msvideo", @"avi", 
                       @"video/mpeg", @"mpg", 
                       @"video/mpe", @"mpe", 
                       @"video/quicktime", @"mov", 
                       @"video/mpeg", @"mpeg", 
                       @"video/x-sgi-movie", @"movie", 
                       
                       // Text types
                       @"text/html", @"html", 
                       @"text/html", @"htm", 
                       @"text/plain", @"txt", 
                       @"text/richtext", @"rtx", 
                       @"text/x-sgml", @"sgm", 
                       @"text/x-sgml", @"sgml", 
                       
                       // Client-side components related types
                       @"application/java-archive", @"jar", 
                       @"application/applet", @"class", 
                       nil];
        }
    return teTable;
}


/*" Adds a mapping between a MIME content type/subtype and a file extension to the internal table; the MIME type/subtype being the first object and the file extension the second object in the pair. Note that one MIME type might be represented by several file extensions but a file extension must always map to exactly one MIME type; for example "image/jpeg" maps to "jpg" and "jpeg." A fairly extensive table is available by default. "*/

+ (void)addContentTypePathExtensionPair:(EDObjectPair *)tePair
{
    [self _contentTypeExtensionMapping];
    if([teTable isKindOfClass:[NSMutableDictionary class]] == NO)
        {
        teTable = [[NSMutableDictionary alloc] initWithDictionary:teTable];
        }
    [teTable setObject:[tePair secondObject] forKey:[tePair firstObject]];
}


/*" Returns a file extension that is used for files of the MIME content type/subtype. Note that one MIME type might be represented by several file extensions. "*/

+ (NSString *)pathExtensionForContentType:(NSString *)contentType
{
    NSDictionary   	*table;
    NSEnumerator	*extensionEnum;
    NSString		*extension;

    contentType = [contentType lowercaseString];
    table = [self _contentTypeExtensionMapping];
    extensionEnum = [table keyEnumerator];
    while((extension = [extensionEnum nextObject]) != nil)
        {
        if([[table objectForKey:extension] isEqualToString:contentType])
            break;
        }
    return extension;
}


/*" Returns the MIME content type/subtype for extension "*/

+ (NSString *)contentTypeForPathExtension:(NSString *)extension
{
    return [[self _contentTypeExtensionMapping] objectForKey:[extension lowercaseString]];
}




//=======================================================================================
    @end
//=======================================================================================


//=======================================================================================
    @implementation NSMutableString(EDExtensions)
//=======================================================================================

/*" Various common extensions to #NSMutableString. "*/

/*" Removes all whitespace left of the first non-whitespace character and right of the last whitespace character. "*/

- (void)removeSurroundingWhitespace
{
    NSRange		start, end;

    if(iwsSet == nil)
        iwsSet = [[NSCharacterSet whitespaceCharacterSet] invertedSet];

    start = [self rangeOfCharacterFromSet:iwsSet];
    if(start.length == 0)
        {
        [self setString:@""];  // string is empty or consists of whitespace only
        return;
        }

    if(start.location > 0)
        [self deleteCharactersInRange:NSMakeRange(0, start.location)];
    
    end = [self rangeOfCharacterFromSet:iwsSet options:NSBackwardsSearch];
    if(end.location < [self length] - 1)
        [self deleteCharactersInRange:NSMakeRange(NSMaxRange(end), [self length] - NSMaxRange(end))];
}


/*" Removes all whitespace from the string. "*/

- (void)removeWhitespace
{
    [self removeCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}


/*" Removes all characters in %set from the string. "*/

- (void)removeCharactersInSet:(NSCharacterSet *)set
{
    NSRange			matchRange, searchRange, replaceRange;
    unsigned int    length;

    length = [self length];
    matchRange = [self rangeOfCharacterFromSet:set options:NSLiteralSearch range:NSMakeRange(0, length)];
    while(matchRange.length > 0)
        {
        replaceRange = matchRange;
        searchRange.location = NSMaxRange(replaceRange);
        searchRange.length = length - searchRange.location;
        for(;;)
            {
            matchRange = [self rangeOfCharacterFromSet:set options:NSLiteralSearch range:searchRange];
            if((matchRange.length == 0) || (matchRange.location != searchRange.location))
                break;
            replaceRange.length += matchRange.length;
            searchRange.length -= matchRange.length;
            searchRange.location += matchRange.length;
            }
        [self deleteCharactersInRange:replaceRange];
        matchRange.location -= replaceRange.length;
        length -= replaceRange.length;
        }
}


//=======================================================================================
    @end
//=======================================================================================

