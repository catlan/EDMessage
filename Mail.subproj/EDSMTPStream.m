//---------------------------------------------------------------------------------------
//  EDSMTPStream.m created by erik on Sun 12-Mar-2000
//  $Id: EDSMTPStream.m,v 2.0 2002-08-16 18:24:16 erik Exp $
//
//  Copyright (c) 2000 by Erik Doernenburg. All rights reserved.
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
#import "EDSMTPStream.h"

@interface EDSMTPStream(PrivateAPI)
- (void)_assertServerIsReady;
- (void)_shutdown;
- (NSString *)_pathFromAddress:(NSString *)address;
- (NSArray *)_readResponse;
@end


//---------------------------------------------------------------------------------------
    @implementation EDSMTPStream
//---------------------------------------------------------------------------------------

NSString *EDSMTPException = @"EDSMTPException";
NSString *EDBrokenSMPTServerHint = @"EDBrokenSMPTServerHint";


//---------------------------------------------------------------------------------------
//	FACTORY METHODS
//---------------------------------------------------------------------------------------

+ (EDSMTPStream *)streamForRelayHost:(NSHost *)relayHost
{
    // I don't think we need a getservbyname... ;-)
    return [[self class] streamConnectedToHost:relayHost port:25];
}


+ (EDSMTPStream *)streamForRelayHostWithName:(NSString *)relayHostname
{
    return [[self class] streamForRelayHost:[NSHost hostWithName:relayHostname]];
}


//---------------------------------------------------------------------------------------
//	INITIALISER
//---------------------------------------------------------------------------------------

- (id)initWithFileHandle:(NSFileHandle *)aFileHandle
{
    [super initWithFileHandle:aFileHandle];
    [self setLinebreakStyle:EDCanonicalLinebreakStyle];
    [self setEnforcesCanonicalLinebreaks:YES];
    pendingResponses = [[NSMutableArray allocWithZone:[self zone]] init];
    state = 0;
    return self;
}


- (void)dealloc
{
    if(state != 5)
        {
        NS_DURING
        [self close];
        NS_HANDLER
        NS_ENDHANDLER
        }
    [super dealloc];
}


//---------------------------------------------------------------------------------------
//	STARTUP/SHUTDOWN
//---------------------------------------------------------------------------------------

- (void)_assertServerIsReady
{
    NSHost		 		*localhost;
    NSString	 		*name, *domain, *line, *responseCode;
    NSArray		 		*response;
    NSEnumerator 		*lineEnum;
    NSMutableDictionary	*amendedUserInfo;
    
    if(state < 3)  // not ready yet
        {
        if(state < 1)  // must read initial greeting
            {
            [pendingResponses addObject:@"220"];
            [self assertServerAcceptedCommand];
            state = flags2.needExtensionCheck ? 1 : 2;
            }

        localhost = [NSHost currentHost];
        if((name = [localhost fullyQualifiedName]) == nil)
            {
            name = [localhost name];
            if(([name isEqualToString:@"localhost"] == NO) && ((domain = [NSHost localDomain]) != nil))
                name = [[name stringByAppendingString:@"."] stringByAppendingString:domain];
            }

        NS_DURING

        if(state == 1)  // try EHLO
            {
            [self writeFormat:@"EHLO %@\r\n", name];
            flags2.triedExtensionsCheck = YES;
            response = [self _readResponse];
            responseCode = [[response objectAtIndex:0] substringToIndex:3];
            if([responseCode isEqualToString:@"250"]) // okay!
                {
                lineEnum = [response objectEnumerator];
                while((line = [lineEnum nextObject]) != nil)
                    {
                    if([[line substringFromIndex:4] caseInsensitiveCompare:@"8BITMIME"] == NSOrderedSame)
                        flags2.handles8BitBodies = YES;
                    if([[line substringFromIndex:4] caseInsensitiveCompare:@"PIPELINING"] == NSOrderedSame)
                        flags2.allowsPipelining = YES;
                    }
                state = 3;
                }
            else if(([responseCode hasPrefix:@"5"])) // didn't like EHLO, now try HELO
                {
                state = 2;
                }
            else // other error; most likely 421 - Service not available
                {
                state = 4;
                [NSException raise:EDSMTPException format:@"Failed to initialize STMP connection; read \"%@\"", [response componentsJoinedByString:@" "]];
                }
            }
        if(state == 2)  // EHLO doesn't work, say HELO
            {
            [self writeFormat:@"HELO %@\r\n", name];
            response = [self _readResponse];
            responseCode = [[response objectAtIndex:0] substringToIndex:3];
            if([responseCode isEqualToString:@"250"]) // okay!
                {
                state = 3;
                }
            else if([responseCode hasPrefix:@"5"]) // didn't like HELO?!
                {
                [NSException raise:EDSMTPException format:@"Failed to initialize STMP connection; read \"%@\"", [response componentsJoinedByString:@" "]];
                }
            else
                {
                state = 4;
                [NSException raise:EDSMTPException format:@"Failed to initialize STMP connection; read \"%@\"", [response componentsJoinedByString:@" "]];
                }
            }

        NS_HANDLER

            if((flags2.triedExtensionsCheck == NO) || (state == 4))
                [localException raise];
            
            // We can also get here if the extensions "parsing" fails; if for example
            // a line in the response contains less than 4 characters. This is also
            // counted as a broken server that doesn't really understand EHLO...
            state = 4;
            amendedUserInfo = [NSMutableDictionary dictionaryWithDictionary:[localException userInfo]];
            [amendedUserInfo setObject:@"YES" forKey:EDBrokenSMPTServerHint];
            [[NSException exceptionWithName:[localException name] reason:[localException reason] userInfo:amendedUserInfo] raise];
            
        NS_ENDHANDLER
        }

    if((state == 3) && (flags2.allowsPipelining == NO) && ([self hasPendingResponses]))
        {
        [NSException raise:NSInternalInconsistencyException format:@"-[%@ %@]: Attempt to issue an SMTP command when a response is pending and server is not known to allow pipelining.", NSStringFromClass(isa), NSStringFromSelector(_cmd)];
        }

    if(state > 3) // not in command state
        {
        if(state == 9)
            {
            [NSException raise:NSInternalInconsistencyException format:@"-[%@ %@]: Attempt to issue an SMTP command within message body.", NSStringFromClass(isa), NSStringFromSelector(_cmd)];
            }
        else if(state == 5)
            {
            [NSException raise:NSInternalInconsistencyException format:@"-[%@ %@]: Attempt to issue an SMTP command on a closed stream.", NSStringFromClass(isa), NSStringFromSelector(_cmd)];
            }
        else
            {
            [NSException raise:NSInternalInconsistencyException format:@"-[%@ %@]: Attempt to issue an SMTP command on an unusable stream.", NSStringFromClass(isa), NSStringFromSelector(_cmd)];
            }

        }
}


- (void)_shutdown
{
    if(state < 1)
        [pendingResponses addObject:@"220"];
    else if(state == 9)
        [self finishBody];
    while([self hasPendingResponses])
        [self assertServerAcceptedCommand];
    [self writeString:@"QUIT\r\n"];
    [pendingResponses addObject:@"221"];
    [self assertServerAcceptedCommand];
    state = 5;
}


//---------------------------------------------------------------------------------------
//	OVERRIDES
//---------------------------------------------------------------------------------------

- (void)close
{
    [self _shutdown];
    [super close];
}


//---------------------------------------------------------------------------------------
//	SMTP EXTENSIONS
//---------------------------------------------------------------------------------------

- (void)checkProtocolExtensions
{
    flags2.needExtensionCheck = YES;
    [self _assertServerIsReady];
}


- (BOOL)handles8BitBodies
{
    return flags2.handles8BitBodies;
}


- (BOOL)allowsPipelining
{
    return flags2.allowsPipelining;
}


//---------------------------------------------------------------------------------------
//	WRITE WRAPPER
//---------------------------------------------------------------------------------------

- (void)writeSender:(NSString *)sender
{
    [self _assertServerIsReady];
    if(flags2.handles8BitBodies == YES)
        [self writeFormat:@"MAIL FROM:%@ BODY=8BITMIME\r\n", [self _pathFromAddress:sender]];
    else
        [self writeFormat:@"MAIL FROM:%@\r\n", [self _pathFromAddress:sender]];
    [pendingResponses addObject:@"250"];
}


- (void)writeRecipient:(NSString *)recipient
{
    [self _assertServerIsReady];
    [self writeFormat:@"RCPT TO:%@\r\n", [self _pathFromAddress:recipient]];
    [pendingResponses addObject:@"250"];
}


- (void)beginBody
{
    [self _assertServerIsReady];
    [self writeString:@"DATA\r\n"];
    [pendingResponses addObject:@"354"];
    state = 9;
}


- (void)finishBody
{
    if(state != 9)
        [NSException raise:NSInternalInconsistencyException format:@"-[%@ %@]: Attempt to finish a message body that was not begun.", NSStringFromClass(isa), NSStringFromSelector(_cmd)];
    [self writeString:@"\r\n.\r\n"];
    [pendingResponses addObject:@"250"];
    state = 3;
}


- (BOOL)hasPendingResponses
{
    return [pendingResponses count] > 0;
}


- (void)assertServerAcceptedCommand
{
    NSString	*expectedCode;
    NSArray		*response;
    
    if([pendingResponses count] == 0)
        [NSException raise:NSInternalInconsistencyException format:@"-[%@ %@]: No pending responses.", NSStringFromClass(isa), NSStringFromSelector(_cmd)];

    expectedCode = [[[pendingResponses objectAtIndex:0] retain] autorelease];
    [pendingResponses removeObjectAtIndex:0];
    response = [self _readResponse];
    if([[response objectAtIndex:0] hasPrefix:expectedCode] == NO)
        [NSException raise:EDSMTPException format:@"Unexpected SMTP response code; expected %@, read \"%@\"", expectedCode, [response componentsJoinedByString:@" "]];
}



//-------------------------------------------------------------------------------------------
//	HELPER
//-------------------------------------------------------------------------------------------

- (NSString *)_pathFromAddress:(NSString *)address
{
    NSString	*path;

    if([address hasPrefix:@"<"] == NO)
        path = [NSString stringWithFormat:@"<%@>", address];
    else
        path = address;

    return path;
}


- (NSArray *)_readResponse
{
    NSString			*partialResponse;
    NSMutableArray		*response;

    response = [NSMutableArray array];
    do
        {
        partialResponse = [self availableLine];
        [response addObject:partialResponse];
        }
    while([partialResponse characterAtIndex:3] == '-');

    return response;
}



//---------------------------------------------------------------------------------------
    @end
//---------------------------------------------------------------------------------------
