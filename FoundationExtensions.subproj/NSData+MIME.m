//---------------------------------------------------------------------------------------
//  NSData+MIME.m created by erik on Sun 12-Jan-1997
//  @(#)$Id: NSData+MIME.m,v 2.0 2002-08-16 18:24:13 erik Exp $
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

#import <Foundation/Foundation.h>
#import <EDCommon/EDCommon.h>
#import "EDMessageDefines.h"
#import "utilities.h"
#import "NSCharacterSet+MIME.h"
#import "NSData+MIME.h"

@interface NSData(EDMIMEExtensionsPrivateAPI)
- (NSData *)_encodeQuotedPrintableStep1;
- (NSData *)_encodeQuotedPrintableStep2;
@end


NSString *MIME7BitContentTransferEncoding = @"7bit";
NSString *MIME8BitContentTransferEncoding = @"8bit";
NSString *MIMEBinaryContentTransferEncoding = @"binary";
NSString *MIMEQuotedPrintableContentTransferEncoding = @"quoted-printable";
NSString *MIMEBase64ContentTransferEncoding = @"base64";


//---------------------------------------------------------------------------------------
//	MOTHER'S LITTLE HELPERS
//---------------------------------------------------------------------------------------


static char basishex[] =
   "0123456789ABCDEF";

static byte indexhex[128] = {
    99,99,99,99, 99,99,99,99, 99,99,99,99, 99,99,99,99,
    99,99,99,99, 99,99,99,99, 99,99,99,99, 99,99,99,99,
    99,99,99,99, 99,99,99,99, 99,99,99,99, 99,99,99,99,
     0, 1, 2, 3,  4, 5, 6, 7,  8, 9,99,99, 99,99,99,99,
    99,10,11,12, 13,14,15,99, 99,99,99,99, 99,99,99,99,
    99,99,99,99, 99,99,99,99, 99,99,99,99, 99,99,99,99,
    99,10,11,12, 13,14,15,99, 99,99,99,99, 99,99,99,99,
    99,99,99,99, 99,99,99,99, 99,99,99,99, 99,99,99,99
};

static __inline__ void encode2bytehex(unsigned int value, char *buffer)
{
    buffer[0] = basishex[value/16];
    buffer[1] = basishex[value%16];
}


static __inline__ unsigned int decode2bytehex(const char *p)
{
    return indexhex[(int)*p] * 16 + indexhex[(int)*(p+1)];
}


static byte basis64[] =
   "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

static byte index64[128] = {
    99,99,99,99, 99,99,99,99, 99,99,99,99, 99,99,99,99,
    99,99,99,99, 99,99,99,99, 99,99,99,99, 99,99,99,99,
    99,99,99,99, 99,99,99,99, 99,99,99,62, 99,99,99,63,
    52,53,54,55, 56,57,58,59, 60,61,99,99, 99,99,99,99,
    99, 0, 1, 2,  3, 4, 5, 6,  7, 8, 9,10, 11,12,13,14,
    15,16,17,18, 19,20,21,22, 23,24,25,99, 99,99,99,99,
    99,26,27,28, 29,30,31,32, 33,34,35,36, 37,38,39,40,
    41,42,43,44, 45,46,47,48, 49,50,51,99, 99,99,99,99
};


static __inline__ byte char64(byte c)
{
    return (c > 127) ? 99 : index64[(int)c];
}


static __inline__ byte invchar64(byte b)
{
    return basis64[(int)b];
}


static __inline__ BOOL isqpliteral(byte b)
{
    return ((b >= 33) && (b <= 60)) || ((b >=62) && (b <= 126));
}


//---------------------------------------------------------------------------------------
    @implementation NSData(EDMIMEExtensions)
//---------------------------------------------------------------------------------------

- (NSData *)decodeContentWithTransferEncoding:(NSString *)encodingName
{
    encodingName = [encodingName lowercaseString];
    if([encodingName isEqualToString:MIME7BitContentTransferEncoding])
        return self;
    if([encodingName isEqualToString:MIME8BitContentTransferEncoding])
        return self;
    if([encodingName isEqualToString:MIMEBinaryContentTransferEncoding])
        return self;
    if([encodingName isEqualToString:MIMEQuotedPrintableContentTransferEncoding])
        return [self decodeQuotedPrintable];
    if([encodingName isEqualToString:MIMEBase64ContentTransferEncoding])
        return [self decodeBase64];
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %@]: Unknown content transfer encoding; found '%@'", NSStringFromClass(isa), NSStringFromSelector(_cmd), encodingName];
    return nil; // keep compiler happy
}


- (NSData *)encodeContentWithTransferEncoding:(NSString *)encodingName
{
    encodingName = [encodingName lowercaseString];
    if([encodingName isEqualToString:MIME7BitContentTransferEncoding])
        return self;
    if([encodingName isEqualToString:MIME8BitContentTransferEncoding])
        return self;
    if([encodingName isEqualToString:MIMEBinaryContentTransferEncoding])
        return self;
    if([encodingName isEqualToString:MIMEQuotedPrintableContentTransferEncoding])
        return [self encodeQuotedPrintable];
    if([encodingName isEqualToString:MIMEBase64ContentTransferEncoding])
        return [self encodeBase64];
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %@]: Unknown content transfer encoding; found '%@'", NSStringFromClass(isa), NSStringFromSelector(_cmd), encodingName];
    return nil; // keep compiler happy
}


//---------------------------------------------------------------------------------------
//	BASE64 (RFC 2045)
//---------------------------------------------------------------------------------------

- (NSData *)decodeBase64
{
    NSMutableData 	*decodedData;
    const byte      *source, *endOfSource;
    byte            *dest, groupv[4], c, b;
    int             groupc = 0;
    BOOL            groupHadPadding = NO;

    source = [self bytes];
    endOfSource = source + [self length];
    decodedData = [NSMutableData dataWithLength:[self length]];
    dest = [decodedData mutableBytes];

    while(source < endOfSource)
        {
        c = *source++;
        if((b = char64(c)) != 99)
            {
            groupv[groupc++] = b;
            }
        else if(c == EQUALS)
            {
            if(groupc > 1)
                {
                groupv[groupc++] = 127;
                groupHadPadding = YES;
                }
            }
        if(groupc == 4)
            {
            groupc = 0;
            *dest++ = (groupv[0]<<2) | ((groupv[1]&0x30)>>4);
            if(groupv[2] != 127)
                {
                *dest++ = ((groupv[1]&0xF) << 4) | ((groupv[2]&0x3C) >> 2);
                if(groupv[3] != 127)
                    *dest++ = ((groupv[2]&0x03) << 6) | groupv[3];
                }
            if(groupHadPadding)
                break;
            }
        }
    if(groupc != 0)
        EDLog(EDLogCoder, @"MIME Decoder: premature end of base64 encoded data");

    [decodedData setLength:(unsigned int)((void *)dest - [decodedData mutableBytes])];

    return decodedData;
}


- (NSData *)encodeBase64
{
    return [self encodeBase64WithLineLength:76 andNewlineAtEnd:YES];
}


- (NSData *)encodeBase64WithLineLength:(unsigned int)lineLength andNewlineAtEnd:(BOOL)endWithNL
{
    NSMutableData 	*encodedData;
    const byte		*source, *endOfSource;
    byte			*dest, groupv[4], b;
    int				i, bytec = 0, groupc = 0;
    unsigned int	numgroups, groupsPerLine, dataLength;

    source = [self bytes];
    endOfSource = source + [self length];

    numgroups = udivroundup([self length], 3);
    groupsPerLine = lineLength / 4;
    if(groupsPerLine == 0)
        [NSException raise:NSInvalidArgumentException format:@"-[%@ %@]: Line length must be > 3", NSStringFromClass(isa), NSStringFromSelector(_cmd)];
    if((lineLength % 4) != 0)
        EDLog(EDLogCoder, @"MIME Encoder: rounded down line length for base64 encoding.");
    dataLength = numgroups * 4;
    if(lineLength > 0)
        dataLength += udivroundup(numgroups, groupsPerLine) * 2;

    encodedData = [NSMutableData dataWithLength:dataLength];
    dest = [encodedData mutableBytes];

    while(source < endOfSource)
        {
        b = *source++;
        switch(bytec++)
            {
        case 0:
            groupv[0]  = (b & 0xFC) >> 2;
            groupv[1]  = (b & 0x03) << 4;
            break;
        case 1:
            groupv[1] |= (b & 0xF0) >> 4;
            groupv[2]  = (b & 0x0F) << 2;
            break;
        case 2:
            groupv[2] |= (b & 0xC0) >> 6;
            groupv[3]  = (b & 0x3F);
            break;
            }
        if((bytec == 3) || (source == endOfSource))
            {
            for(i = 0; i < bytec + 1; i++)
                *dest++ = invchar64(groupv[i]);
            for(; i < 4; i++)
                *dest++ = EQUALS;
            bytec = 0;
            groupc += 1;
            if(((groupc % groupsPerLine) == 0) || ((source == endOfSource) && (endWithNL == YES)))
                {
                *dest++ = CR;
                *dest++ = LF;
                }
            }
        }

    [encodedData setLength:(unsigned int)((void *)dest - [encodedData mutableBytes])];

    return encodedData;
}



//---------------------------------------------------------------------------------------
//	QUOTED PRINTABLE (RFC 2045)
//---------------------------------------------------------------------------------------

- (NSData *)decodeQuotedPrintable
{
    NSMutableData 	*decodedData;
    const char      *source, *endOfSource;
    char           	*dest;

    source = [self bytes];
    endOfSource = source + [self length];
    decodedData = [NSMutableData dataWithLength:[self length]];
    dest = [decodedData mutableBytes];

    while(source < endOfSource)
        {
        if(*source == EQUALS)
            {
            source += 1;
            if(iscrlf(*source) || iswhitespace(*source))
                {
                while(iswhitespace(*source))
                    source += 1;
                if(*source == CR)       // this is not exactly according
                    source += 1;        // to rfc2045 but it does decode
                if(*source == LF)       // it properly while offering
                    source += 1;        // some robustness...
                }
            else
                {
                if(isxdigit(*source) && isxdigit(*(source+1)))
                    {
                    *dest++ = decode2bytehex(source);
                    source += 2;
                    }
                }
            }
        else
            {
            *dest ++ = *source++;
            }
        }
    [decodedData setLength:(unsigned int)((void *)dest - [decodedData mutableBytes])];

    return decodedData;
}


- (NSData *)encodeQuotedPrintable
{
    // this is a bit lame but doing it in one pass proved to be too mind-boggling
    return [[self _encodeQuotedPrintableStep1] _encodeQuotedPrintableStep2];
}


- (NSData *)_encodeQuotedPrintableStep1
{
    NSMutableData	*dest;
    NSData			*chunk;
    char			escBuffer[3] = "=00";
    const byte		*source, *chunkStart, *endOfSource;
    byte			c;

    dest = [[[NSMutableData allocWithZone:[self zone]] init] autorelease];
    source = [self bytes];
    endOfSource = source + [self length];
    while(source < endOfSource)
        {
        c = *source;
        if(iscrlf(c))
            {
            source = skipnewline(source, endOfSource);
            [dest appendBytes:&"\r\n" length:2];
            }
        else if(iswhitespace(c))
            {
            chunkStart = source;
            do
                source += 1;
            while((source < endOfSource) && (iswhitespace(*source) == YES));

            if((source == endOfSource) || iscrlf(*source))
                {
                // need to escape last space.
                chunk = [NSData dataWithBytes:chunkStart length:(source - chunkStart - 1)];
                [dest appendData:chunk];
                encode2bytehex(*(source  - 1), &escBuffer[1]);
                [dest appendBytes:escBuffer length:3];
                }
            else
                {
                // we have a valid continuation char
                chunk = [NSData dataWithBytes:chunkStart length:(source - chunkStart)];
                [dest appendData:chunk];
                }
            }
        else if(isqpliteral(c))
            {
            chunkStart = source;
            do
                source += 1;
            while((source < endOfSource) && isqpliteral(*source));
            chunk = [NSData dataWithBytes:chunkStart length:(source - chunkStart)];
            [dest appendData:chunk];
            }
        else
            {
            source += 1;
            encode2bytehex(c, &escBuffer[1]);
            [dest appendBytes:escBuffer length:3];
            }
        }

    return dest;
}


- (NSData *)_encodeQuotedPrintableStep2
{
    NSMutableData	*dest;
    NSData			*chunk;
    const byte		*source, *chunkStart, *startOfSource, *endOfSource, *softbreakPos;
    int				lineLength;

    dest = [[[NSMutableData allocWithZone:[self zone]] init] autorelease];
    startOfSource = source = [self bytes];
    endOfSource = source + [self length];
    chunkStart = source;
    lineLength = 0;
    while(source < endOfSource)
        {
        if(lineLength < 75)
            {
            if(*source == CR)
                {
                lineLength = 0;
                source += 2;
                }
            else
                {
                lineLength += 1;
                source += 1;
                }
            }
        if(lineLength >= 75)
            {
            softbreakPos = source - 1;
            while(iswhitespace(*softbreakPos) == NO)
                {
                softbreakPos -= 1;
                if((*softbreakPos == LF) || (softbreakPos < startOfSource) || (softbreakPos <= chunkStart))
                    {
                    // couldn't find a space! break anywhere but in the middle of an =XX
                    softbreakPos = source - 1;
                    if(*softbreakPos == EQUALS)
                        softbreakPos -= 1;
                    else if(*(softbreakPos - 1) == EQUALS)
                        softbreakPos -= 2;
                    break;
                    }
                }
            // note: softbreakPos now points to the last char that should be on the line
            softbreakPos += 1;
            chunk = [NSData dataWithBytes:chunkStart length:(softbreakPos - chunkStart)];
            [dest appendData:chunk];
            [dest appendBytes:&"=\r\n" length:3];
            chunkStart = softbreakPos;
            lineLength = (source - softbreakPos);
            }
        }
    if(chunkStart != source)
        {
        chunk = [NSData dataWithBytes:chunkStart length:(source - chunkStart)];
        [dest appendData:chunk];
        }
    return dest;    
}

//---------------------------------------------------------------------------------------
//	QUOTED PRINTABLE FOR HEADERS (RFC ????)
//---------------------------------------------------------------------------------------

- (NSData *)decodeHeaderQuotedPrintable
{
    NSMutableData 	*decodedData;
    const byte      *source, *endOfSource;
    byte            *dest;

    source = [self bytes];
    endOfSource = source + [self length];
    decodedData = [NSMutableData dataWithLength:[self length]];
    dest = [decodedData mutableBytes];

    while(source < endOfSource)
        {
        byte c = *source++;
        if((c == EQUALS) && (source < endOfSource - 1) && isxdigit(*(source)) && isxdigit(*(source+1)))
            {
            c = decode2bytehex(source);
            source += 2;
            }
        else if(c == UNDERSCORE)
            {
            c = SPACE;
            }
        *dest++ = c;
        }
    [decodedData setLength:(unsigned int)((void *)dest - [decodedData mutableBytes])];

    return decodedData;
}


- (NSData *)encodeHeaderQuotedPrintable
{
    return [self encodeHeaderQuotedPrintableMustEscapeCharactersInString:nil];
}


- (NSData *)encodeHeaderQuotedPrintableMustEscapeCharactersInString:(NSString *)escChars
{
    NSMutableCharacterSet *tempCharacterSet;
    NSCharacterSet		  *literalChars;
    NSMutableData		  *buffer;
    unsigned int		  length;
    const byte		   	  *source, *chunkStart, *endOfSource;
    char				  escValue[3] = "=00", underscore = '_';

    if(escChars != nil)
        {
        tempCharacterSet = [[NSCharacterSet MIMEHeaderDefaultLiteralCharacterSet] mutableCopy];
        [tempCharacterSet removeCharactersInString:escChars];
        literalChars = [[tempCharacterSet copy] autorelease];
        [tempCharacterSet release];
        }
    else
        {
        literalChars = [NSCharacterSet MIMEHeaderDefaultLiteralCharacterSet];
        }

    length = [self length];
    buffer = [[[NSMutableData alloc] initWithCapacity:length + length / 10] autorelease];

    chunkStart = source = [self bytes];
    endOfSource = source + length;
    while(source < endOfSource)
        {
        if([literalChars characterIsMember:(unichar)(*source)] == NO)
            {
            if((length = (source - chunkStart)) > 0)
                [buffer appendBytes:chunkStart length:length];
            if(*source == SPACE)
                {
                [buffer appendBytes:&underscore length:1];
                }
            else
                {
                encode2bytehex(*source, &escValue[1]);
                [buffer appendBytes:escValue length:3];
                }
            chunkStart = source + 1;
            }
        source += 1;
        }
    [buffer appendBytes:chunkStart length:(source - chunkStart)];

    return buffer;
}


//---------------------------------------------------------------------------------------
    @end
//---------------------------------------------------------------------------------------


#if 0
static void appendchars(NSMutableString *buffer, const char *p, unsigned int l)
{
    NSString *s = [[NSString alloc] initWithData:[NSData dataWithBytes:p length:l] encoding:NSISOLatin1StringEncoding];
    [buffer appendString:s];
    [s release];
}
#endif
