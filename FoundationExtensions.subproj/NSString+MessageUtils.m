//---------------------------------------------------------------------------------------
//  NSString+MessageUtils.m created by erik on Sun 23-Mar-1997
//  @(#)$Id: NSString+MessageUtils.m,v 2.0 2002-08-16 18:24:13 erik Exp $
//
//  Copyright (c) 1995-2000 by Erik Doernenburg. All rights reserved.
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
#import "NSCharacterSet+MIME.h"
#import "NSString+MessageUtils.h"


#if defined(__APPLE__) && !defined(UINT16_MAX)
#define UINT16_MAX USHRT_MAX
#endif


//---------------------------------------------------------------------------------------
	@implementation NSString(EDMessageUtilities)
//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------
//	EXTRACTING SUBSRUCTURES
//---------------------------------------------------------------------------------------

- (BOOL)isValidMessageID
{ 	
	return [self hasPrefix:@"<"] && [self hasSuffix:@">"] && ([self rangeOfString:@"@"].length != 0);
}


- (NSString *)getURLFromArticleID
{
    NSScanner *scanner;
    NSString  *articleId;

    scanner = [NSScanner scannerWithString:self];
    if([scanner scanString:@"<" intoString:NULL])
        if([scanner scanUpToString:@">" intoString:&articleId])
            return [NSString stringWithFormat:@"news:%@", articleId];
    return nil;
}


/*

This next methods are a hack. We do need a new header coder that contains a proper
RFC822/RFC2047 parser for structured fields such as mail address lists, etc.

 */

- (NSString *)stringByRemovingBracketComments
{
    NSCharacterSet	*stopSet;
    NSString		*chunk;
    NSScanner		*scanner;
    NSMutableString	*result;

    stopSet = [NSCharacterSet characterSetWithCharactersInString:@"("];
    result = [[[NSMutableString allocWithZone:[self zone]] init] autorelease];
    scanner = [NSScanner scannerWithString:self];
    while([scanner isAtEnd] == NO)
        {
        if([scanner scanUpToCharactersFromSet:stopSet intoString:&chunk] == YES)
            [result appendString:chunk];
        if([scanner scanString:@"(" intoString:NULL] == YES)
            if([scanner scanUpToClosingBracketIntoString:NULL] == YES)
                [scanner scanString:@")" intoString:NULL];
        }

    return result;
}


- (NSString *)realnameFromEMailString
{
	static NSCharacterSet *skipChars = nil;	
	NSRange charPos, char2Pos, nameRange;
	
	if(skipChars == nil)
		skipChars = [[NSCharacterSet characterSetWithCharactersInString:@"\"' "] retain];

	if((charPos = [self rangeOfString:@"@"]).length == 0)
		{
		nameRange = NSMakeRange(0, [self length]);
		}
	else if((charPos = [self rangeOfString:@"<"]).length > 0) 
		{
		nameRange = NSMakeRange(0, charPos.location);
		}
	else if((charPos = [self rangeOfString:@"("]).length > 0)
		{
		char2Pos = [self rangeOfString:@")"];          // empty brackets are ignored
		if((char2Pos.length > 0) && (char2Pos.location > charPos.location + 1))
			nameRange = NSMakeRange(charPos.location + 1, char2Pos.location - charPos.location - 1);
		else
			nameRange = NSMakeRange(0, [self length]);
		}
	else
		{
		nameRange = NSMakeRange(0, [self length]);
		}
		
	while((nameRange.length > 0) && [skipChars characterIsMember:[self characterAtIndex:nameRange.location]])
		{
		nameRange.location += 1; nameRange.length -= 1;
		}
	while((nameRange.length > 0) && [skipChars characterIsMember:[self characterAtIndex:nameRange.location + nameRange.length - 1]])
		{
		nameRange.length -= 1;
		}
		
	return [self substringWithRange:nameRange];
}


- (NSString *)addressFromEMailString
{
    static NSCharacterSet 	*nonAddressChars = nil;
    NSString 				*addr;
    NSRange 				d1Pos, d2Pos, atPos, searchRange, addrRange;

    if(nonAddressChars == nil)
        {
        NSMutableCharacterSet *workingSet;

        workingSet = [[[NSCharacterSet characterSetWithCharactersInString:@"()<>@,;:\\\"[]"] mutableCopy] autorelease];
        [workingSet formUnionWithCharacterSet:[NSCharacterSet controlCharacterSet]];
        [workingSet formUnionWithCharacterSet:[NSCharacterSet linebreakCharacterSet]];
        [workingSet formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
#ifdef EDMESSAGE_OSXBUILD        
#warning ** workaround for broken implementation of -invertedSet in 5G64 
        [workingSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithRange:NSMakeRange(128, UINT16_MAX-128)]];
#else
       [workingSet formUnionWithCharacterSet:[[NSCharacterSet standardASCIICharacterSet] invertedSet]];
#endif        
        nonAddressChars = [workingSet copy];
        }

    if((d1Pos = [self rangeOfString:@"<"]).length > 0)
        {
        searchRange = NSMakeRange(NSMaxRange(d1Pos), [self length] - NSMaxRange(d1Pos));
        d2Pos = [self rangeOfString:@">" options:0 range:searchRange];
        if(d2Pos.length == 0)
            [NSException raise:NSGenericException format:@"Invalid e-mail address string: \"%@\"", self];
        addrRange = NSMakeRange(NSMaxRange(d1Pos), d2Pos.location - NSMaxRange(d1Pos));
        addr = [[self substringWithRange:addrRange] stringByRemovingSurroundingWhitespace];
        }
    else if((atPos = [self rangeOfString:@"@"]).length > 0)
        {
        searchRange = NSMakeRange(0, atPos.location);
        d1Pos = [self rangeOfCharacterFromSet:nonAddressChars options:NSBackwardsSearch range:searchRange];
        if(d1Pos.length == 0)
            d1Pos.location = 0;
        searchRange = NSMakeRange(NSMaxRange(atPos), [self length] - NSMaxRange(atPos));
        d2Pos = [self rangeOfCharacterFromSet:nonAddressChars options:0 range:searchRange];
        if(d2Pos.length == 0)
            d2Pos.location = [self length];
        addrRange = NSMakeRange(NSMaxRange(d1Pos), d2Pos.location - NSMaxRange(d1Pos));
        addr = [self substringWithRange:addrRange];
        }
    else
        {
        d2Pos = [self rangeOfCharacterFromSet:nonAddressChars];
        if(d2Pos.length == 0)
            d2Pos.location = [self length];
        addrRange = NSMakeRange(0, d2Pos.location);
        addr = [self substringWithRange:addrRange];
        }

    return addr;
}


- (NSArray *)addressListFromEMailString
{
    NSCharacterSet	*stopSet;
    NSString		*chunk;
    NSScanner		*scanner;
    NSMutableString	*result;

    stopSet = [NSCharacterSet characterSetWithCharactersInString:@"\""];
    result = [[[NSMutableString allocWithZone:[self zone]] init] autorelease];
    scanner = [NSScanner scannerWithString:self];
    while([scanner isAtEnd] == NO)
        {
        if([scanner scanUpToCharactersFromSet:stopSet intoString:&chunk] == YES)
            [result appendString:chunk];
        if([scanner scanString:@"\"" intoString:NULL] == YES)
            if([scanner scanUpToCharactersFromSet:stopSet intoString:&chunk] == YES)
                [scanner scanString:@"\"" intoString:NULL];
        }
    return [[[result componentsSeparatedByString:@","] arrayByMappingWithSelector:@selector(stringByRemovingSurroundingWhitespace)] arrayByMappingWithSelector:@selector(addressFromEMailString)];
}


- (NSString *)stringByRemovingReplyPrefix
{
    static BOOL		didInitTable = NO;
    static short	delta[7][129];
    short	 		state;
    unsigned int	n, i, c;

    if(didInitTable == NO)
        {
        didInitTable = YES;
        memset(delta, 0, 6 * 129 * sizeof(short));
        for(i = 0; i < 129; i++)
            delta[6][i] = 1;
        delta[2]['r'] = 3; delta[2]['R'] = 3; delta[2][128] = 0;
        delta[3]['e'] = 4; delta[3]['E'] = 4; delta[3][128] = 0;
        delta[4]['^'] = 5; delta[4][':'] = 6; delta[4][128] = 0;
        delta[5]['0'] = 5; delta[5]['1'] = 5; delta[5]['2'] = 5; delta[5]['3'] = 5;
        delta[5]['4'] = 5; delta[5]['5'] = 5; delta[5]['6'] = 5; delta[5]['7'] = 5;
        delta[5]['8'] = 5; delta[5]['9'] = 5; delta[5][':'] = 6; delta[5][128] = 0;
        delta[6][' '] = 6;
        }

    for(i = 0, n = [self length], state = 2; (i < n) && (state > 1); i++)
        {
        c = (unsigned int)[self characterAtIndex:i];
        state = delta[state][MIN(c, 128)];
        }
    if((state == 1) && (i < n))
        return [self substringFromIndex:i - 1];
    return self;
}

/*
                                    digit      space
                                    /	\	   /   \ 	
         R,r        E,e         ^   \   /   :  \   /
    (2) -----> (3) -----> (4) -----> (5) -----> (6) -----> ((1))
                            \___________________/
                                        :
*/


//---------------------------------------------------------------------------------------
//	CONVERSIONS
//---------------------------------------------------------------------------------------

- (NSString *)stringByApplyingROT13
{
	NSString	 	*result;
	unsigned int 	length, i;
	unichar			*buffer, *cp;

	length = [self length];
	buffer = NSZoneMalloc([self zone], length * sizeof(unichar));
	[self getCharacters:buffer range:NSMakeRange(0, length)];
	for(i = 0, cp = buffer; i < length; i++, cp++)
		if((*cp >= (unichar)'a') && (*cp <= (unichar)'z'))
			*cp = (((*cp - 'a') + 13) % 26) + 'a';
		else if((*cp >= (unichar)'A') && (*cp <= (unichar)'Z'))
			*cp = (((*cp - 'A') + 13) % 26) + 'A';
	result = [NSString stringWithCharacters:buffer length:length];
	NSZoneFree([self zone], buffer);
	
	return result;
}


- (NSString *)stringWithCanonicalLinebreaks
{
    EDStringScanner	*scanner;
    NSMutableString	*result;
    unichar			c, lc;
    unsigned int	start;
    NSRange			range;

    scanner = [EDStringScanner scannerWithString:self];
    result = [[[NSMutableString allocWithZone:[self zone]] initWithCapacity:[self length]] autorelease];
    start = 0;
    lc = EDStringScannerEndOfDataCharacter;
    while((c = [scanner getCharacter]) != EDStringScannerEndOfDataCharacter)
        {
        if((c == LF) && (lc != CR))
            {
            range = NSMakeRange(start, [scanner scanLocation] - 1 - start);
            [result appendString:[self substringWithRange:range]];
            [result appendString:@"\r\n"];
            start = [scanner scanLocation];
            }
        lc = c;
        }
    if(start == 0)
        return self;

    range = NSMakeRange(start, [scanner scanLocation] - start);
    if(range.length > 0)
        [result appendString:[self substringWithRange:range]];

    return result;
}


//---------------------------------------------------------------------------------------
//	REFORMATTING
//---------------------------------------------------------------------------------------

- (NSString *)stringByUnwrappingParagraphs
{
    NSCharacterSet	*forceBreakSet, *separatorSet;
    NSMutableString	*buffer;
    NSEnumerator	*lineEnum;
    NSString		*lineBreakSeq, *currentLine, *nextLine;

    lineBreakSeq = @"\r\n";
    if([self rangeOfString:lineBreakSeq].length == 0)
        lineBreakSeq = @"\n";
    
    separatorSet = [NSCharacterSet characterSetWithCharactersInString:@" -\t"];
    forceBreakSet = [NSCharacterSet characterSetWithCharactersInString:@" \t.?!:-�1234567890>}#%|"];
    buffer = [[[NSMutableString allocWithZone:[self zone]] init] autorelease];
    lineEnum = [[self componentsSeparatedByString:lineBreakSeq] objectEnumerator];
    currentLine = [lineEnum nextObject];
    while((nextLine = [lineEnum nextObject]) != nil)
        {
        [buffer appendString:currentLine];
		// if any of these conditions is met we don't unwrap
        if(([currentLine isEqualToString:@""]) || ([nextLine isEqualToString:@""]) || ([currentLine length] < 55) || ([forceBreakSet characterIsMember:[nextLine characterAtIndex:0]]))
            {
            [buffer appendString:lineBreakSeq];
            }
		// if the line didn't end with a whitespace or hyphen we insert a space
        else if([separatorSet characterIsMember:[currentLine characterAtIndex:[currentLine length] - 1]] == NO)
            {
            [buffer appendString:@" "];
            }
        currentLine = nextLine;
        }
    [buffer appendString:currentLine];

    return buffer;
}


- (NSString *)stringByWrappingToLineLength:(unsigned int)length
{
    NSCharacterSet	*breakSet, *textSet;
    NSMutableString	*buffer;
    NSEnumerator	*lineEnum;
    NSString		*lineBreakSeq, *originalLine, *prefix, *spillOver, *lastPrefix;
	NSMutableString	*mcopy;
    NSRange			textStart, endOfLine;
    unsigned int	lineStart, nextLineStart, prefixLength;

    lineBreakSeq = @"\r\n";
    if([self rangeOfString:lineBreakSeq].length == 0)
        lineBreakSeq = @"\n";

    breakSet = [NSCharacterSet characterSetWithCharactersInString:@" \t-"];
    textSet = [[NSCharacterSet characterSetWithCharactersInString:@" \t>}#%|"] invertedSet];
    buffer = [[[NSMutableString allocWithZone:[self zone]] init] autorelease];
	spillOver = nil; lastPrefix = nil; // keep compiler happy...
    lineEnum = [[self componentsSeparatedByString:lineBreakSeq] objectEnumerator];
    while((originalLine = [lineEnum nextObject]) != nil)
        {
		if((textStart = [originalLine rangeOfCharacterFromSet:textSet]).length == 0)
			textStart.location = [originalLine length];
		prefix = [originalLine substringToIndex:textStart.location];
		prefixLength = textStart.location;
		lineStart = textStart.location;		
				
		if(spillOver != nil)
			if(([lastPrefix isEqualToString:prefix] == NO) || (textStart.length == 0))
				{
                [buffer appendString:lastPrefix];
                [buffer appendString:spillOver];
                [buffer appendString:lineBreakSeq];
				}
			else
				{
				originalLine = mcopy = [[originalLine mutableCopy] autorelease];
				[mcopy insertString:@" " atIndex:lineStart];
				[mcopy insertString:spillOver atIndex:lineStart];
				}
	
		// note that this doesn't work properly if length(prefix) > length!, so...
		NSAssert(prefixLength <= length, @"line prefix too long.");
	
		if([originalLine length] - lineStart  > length - prefixLength)
			{
			do
            	{
				endOfLine = [originalLine rangeOfCharacterFromSet:breakSet options:NSBackwardsSearch range:NSMakeRange(lineStart, length - prefixLength)];
           		if(endOfLine.length > 0)
                	{
                	if([originalLine characterAtIndex:endOfLine.location] == (unichar)'-')
                    	endOfLine.location += 1;
                	nextLineStart = endOfLine.location;
                	while((nextLineStart < [originalLine length]) && ([originalLine characterAtIndex:nextLineStart] == (unichar)' '))
                    	nextLineStart += 1;
                	}
            	else
                	{
                	endOfLine = [originalLine rangeOfComposedCharacterSequenceAtIndex:lineStart + length - prefixLength];
                	nextLineStart = endOfLine.location;
                	}
                [buffer appendString:prefix];
                [buffer appendString:[originalLine substringWithRange:NSMakeRange(lineStart, endOfLine.location - lineStart)]];
                [buffer appendString:lineBreakSeq];
            	lineStart = nextLineStart;
				}
			while([originalLine length] - lineStart  > length - prefixLength);
            spillOver = [originalLine substringFromIndex:lineStart];
			}
		else
			{
			[buffer appendString:originalLine];
           	[buffer appendString:lineBreakSeq];
			spillOver = nil;
			}
		lastPrefix = prefix;
        }
	if(spillOver != nil)
        {
        [buffer appendString:lastPrefix];
        [buffer appendString:spillOver];
        [buffer appendString:lineBreakSeq];
        }

    return buffer;
}


- (NSString *)stringByPrefixingLinesWithString:(NSString *)prefix
{
    NSMutableString *buffer;
    NSEnumerator   	*lineEnum;
    NSString		*lineBreakSeq, *line;

    lineBreakSeq = @"\r\n";
    if([self rangeOfString:lineBreakSeq].length == 0)
        lineBreakSeq = @"\n";

    buffer = [[[NSMutableString allocWithZone:[self zone]] init] autorelease];
    lineEnum = [[self componentsSeparatedByString:lineBreakSeq] objectEnumerator];
    while((line = [lineEnum nextObject]) != nil)
        {
        [buffer appendString:prefix];
        [buffer appendString:line];
        [buffer appendString:lineBreakSeq];
        }
    
    return buffer;
}



//---------------------------------------------------------------------------------------
    @end
//---------------------------------------------------------------------------------------



//---------------------------------------------------------------------------------------
    @implementation NSMutableString(EDMessageUtilities)
//---------------------------------------------------------------------------------------

- (void)appendAsLine:(NSString *)line withPrefix:(NSString *)prefix
{
	[self appendString:prefix];
	[self appendString:line];
	[self appendString:@"\n"];
}


//---------------------------------------------------------------------------------------
    @end
//---------------------------------------------------------------------------------------
