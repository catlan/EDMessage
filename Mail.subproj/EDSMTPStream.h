//---------------------------------------------------------------------------------------
//  EDSMTPStream.h created by erik on Sun 12-Mar-2000
//  $Id: EDSMTPStream.h,v 1.1.1.1 2002-08-16 18:21:51 erik Exp $
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


#ifndef	__EDSMTPStream_h_INCLUDE
#define	__EDSMTPStream_h_INCLUDE


#import "EDMessageDefines.h"
#import <EDCommon/EDStream.h>


@interface EDSMTPStream : EDStream
{
    struct {
    unsigned 			needExtensionCheck : 1;
    unsigned			triedExtensionsCheck : 1;
    unsigned 			handles8BitBodies : 1;
    unsigned			allowsPipelining : 1;
    unsigned 			padding : 12;
    }				flags2;
    short			state;
    NSMutableArray	*pendingResponses;
}

+ (EDSMTPStream *)streamForRelayHost:(NSHost *)relayHost;
+ (EDSMTPStream *)streamForRelayHostWithName:(NSString *)relayHostname;

- (void)checkProtocolExtensions;
- (BOOL)handles8BitBodies;
- (BOOL)allowsPipelining;

- (void)writeSender:(NSString *)sender;
- (void)writeRecipient:(NSString *)recipient;
- (void)beginBody;
- (void)finishBody;

- (BOOL)hasPendingResponses;
- (void)assertServerAcceptedCommand;

@end


EDMESSAGE_EXTERN NSString *EDSMTPException;
EDMESSAGE_EXTERN NSString *EDBrokenSMPTServerHint;


/*  You can only send 8bit bodies if #handles8BitBodies returns %YES. Note that if you do not call #checkProtocolExtensions directly after creating the stream, #handles8BitBodies will always return %NO. Some improperly-implemented servers close the connection as a response to the check or will not accept further greeting commands (see RFC1651, paragraph 4.7 for details.) In this case an NSFileHandleOperationException or an EDSMTPException is raised and the user info dictionary contains the key EDBrokenSMPTServerHint. You should then get a new stream and assume that only 7bit is acceptable. */

#endif	/* __EDSMTPStream_h_INCLUDE */
