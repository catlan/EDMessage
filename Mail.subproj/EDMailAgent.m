//---------------------------------------------------------------------------------------
//  EDMailAgent.m created by erik on Fri 21-Apr-2000
//  $Id: EDMailAgent.m,v 1.1.1.1 2002-08-16 18:21:51 erik Exp $
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
#import "NSString+MessageUtils.h"
#import "NSData+MIME.h"
#import "EDTextFieldCoder.h"
#import "EDDateFieldCoder.h"
#import "EDPlainTextContentCoder.h"
#import "EDCompositeContentCoder.h"
#import "EDMultimediaContentCoder.h"
#import "EDInternetMessage.h"
#import "EDSMTPStream.h"
#import "EDMailAgent.h"

@interface EDMailAgent(PrivateAPI)
- (EDSMTPStream *)_getStream;
- (void)_sendMail:(NSData *)data from:(NSString *)sender to:(NSArray *)recipients usingStream:(EDSMTPStream *)stream;
@end


//---------------------------------------------------------------------------------------
    @implementation EDMailAgent
//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------
//	FACTORY METHODS
//---------------------------------------------------------------------------------------

+ (id)mailAgentForRelayHostWithName:(NSString *)name
{
    EDMailAgent *new = [[[self alloc] init] autorelease];
    [new setRelayHostByName:name];
    return new;
}


//---------------------------------------------------------------------------------------
//	INIT & DEALLOC
//---------------------------------------------------------------------------------------

- (id)initWithRelayHost:(NSHost *)host
{
    [super init];
    relayHost = [host retain];
    return self;
}


- (void)dealloc
{
    [relayHost release];
    [super dealloc];
}


//---------------------------------------------------------------------------------------
//	ACCESSOR METHODS
//---------------------------------------------------------------------------------------

- (void)setRelayHostByName:(NSString  *)hostname
{
    NSHost	*host;

    if((host = [NSHost hostWithNameOrAddress:hostname]) == nil)
        [NSException raise:NSGenericException format:@"Cannot set relay host to %@; no such host.", hostname];
    [self setRelayHost:host];
}


- (void)setRelayHost:(NSHost *)host
{
    [host retain];
    [relayHost release];
    relayHost = host;
}


- (NSHost *)relayHost
{
    return relayHost;
}


- (void)setSkipsExtensionTest:(BOOL)flag
{
    flags.skipExtensionTest = flag;
}


- (BOOL)skipsExtensionTest
{
    return flags.skipExtensionTest;
}


//---------------------------------------------------------------------------------------
//	SENDING EMAILS (PRIVATE PRIMITIVES)
//---------------------------------------------------------------------------------------

- (EDSMTPStream *)_getStream
{
    EDSMTPStream	*stream;
    NSFileHandle	*logfile;

    stream = [EDSMTPStream streamForRelayHost:relayHost];
    //	"If no file exists at path the method returns nil"
#warning * maybe check for root if not debug build   
    logfile = [NSFileHandle fileHandleForWritingAtPath:@"/tmp/EDMailAgent.log"];
    [logfile seekToEndOfFile];
    [stream setDumpFileHandle:logfile];

    NS_DURING
        if(flags.skipExtensionTest == NO)
            [stream checkProtocolExtensions];
    NS_HANDLER
        if([[[localException userInfo] objectForKey:EDBrokenSMPTServerHint] boolValue] == NO)
            [localException raise];
        NSLog(@"server problem during SMTP extension check.");
        stream = [EDSMTPStream streamForRelayHost:relayHost];
    NS_ENDHANDLER

    return stream;
}


- (void)_sendMail:(NSData *)data from:(NSString *)sender to:(NSArray *)recipients usingStream:(EDSMTPStream *)stream
{
    unsigned int 	i, n;
    
    if([stream allowsPipelining])
         {
         [stream writeSender:sender];
         for(i = 0, n = [recipients count]; i < n; i++)
             [stream writeRecipient:[recipients objectAtIndex:i]];
         [stream beginBody];
         [stream assertServerAcceptedCommand];
         for(i = 0, n = [recipients count]; i < n; i++)
             [stream assertServerAcceptedCommand];
         [stream assertServerAcceptedCommand];
         }
     else
         {
         [stream writeSender:sender];
         [stream assertServerAcceptedCommand];
         for(i = 0, n = [recipients count]; i < n; i++)
             {
             [stream writeRecipient:[recipients objectAtIndex:i]];
             [stream assertServerAcceptedCommand];
             }
         [stream beginBody];
         [stream assertServerAcceptedCommand];
         }

    [stream setEscapesLeadingDots:YES];
    [stream writeData:data];
    [stream setEscapesLeadingDots:NO];
    [stream finishBody];
    [stream assertServerAcceptedCommand];
    [stream close];     
}


//---------------------------------------------------------------------------------------
//	SENDING EMAILS (CONVENIENCE METHODS, PART 1)
//---------------------------------------------------------------------------------------

- (void)sendMailWithHeaders:(NSDictionary *)userHeaders andBody:(NSString *)body
{
    [self sendMailWithHeaders:userHeaders body:body andAttachments:nil];
}


- (void)sendMailWithHeaders:(NSDictionary *)userHeaders body:(NSString *)body andAttachment:(NSData *)attData withName:(NSString *)attName
{
    [self sendMailWithHeaders:userHeaders body:body andAttachments:[NSArray arrayWithObject:[EDObjectPair pairWithObjects:attData:attName]]];
}


- (void)sendMailWithHeaders:(NSDictionary *)userHeaders body:(NSString *)body andAttachments:(NSArray *)attachmentList
{
    EDSMTPStream			 *stream;
    EDPlainTextContentCoder	 *textCoder;
    EDMultimediaContentCoder *attachmentCoder;
    EDCompositeContentCoder	 *multipartCoder;
    EDInternetMessage		 *message;
    EDMessagePart			 *bodyPart, *attachmentPart;
    NSEnumerator			 *headerFieldNameEnum, *attachmentEnum;
    EDObjectPair			 *attachmentPair;
    NSString				 *sender, *newRecipients, *headerFieldName;
    NSMutableArray 			 *recipients, *partList;
    NSArray					 *authors;
    NSData					 *transferData;
    id						 headerFieldBody;

    recipients = [NSMutableArray array];
    if((newRecipients = [userHeaders objectForKey:@"To"]) != nil)
        [recipients addObjectsFromArray:[newRecipients addressListFromEMailString]];
    if((newRecipients = [userHeaders objectForKey:@"CC"]) != nil)
        [recipients addObjectsFromArray:[newRecipients addressListFromEMailString]];
    if((newRecipients = [userHeaders objectForKey:@"BCC"]) != nil)
        [recipients addObjectsFromArray:[newRecipients addressListFromEMailString]];
    if([recipients count] == 0)
        [NSException raise:NSInvalidArgumentException format:@"-[%@ %@]: No recipients in header list.", NSStringFromClass(isa), NSStringFromSelector(_cmd)];
    
    if((sender = [userHeaders objectForKey:@"Sender"]) == nil)
        {
        authors = [[userHeaders objectForKey:@"From"] addressListFromEMailString];
        if([authors count] == 0)
            [NSException raise:NSInvalidArgumentException format:@"-[%@ %@]: No sender or from field in header list.", NSStringFromClass(isa), NSStringFromSelector(_cmd)];
        if([authors count] > 1)
            [NSException raise:NSInvalidArgumentException format:@"-[%@ %@]: Multiple from addresses and no sender field in header list.", NSStringFromClass(isa), NSStringFromSelector(_cmd)];
        sender = [authors objectAtIndex:0];
        }

    body = [body stringWithCanonicalLinebreaks];

    stream = [self _getStream];

    textCoder = [[[EDPlainTextContentCoder alloc] initWithText:body] autorelease];
    [textCoder setDataMustBe7Bit:([stream handles8BitBodies] == NO)];
    if([attachmentList count] == 0)
        {
        bodyPart = message = [textCoder message];
        }
    else
        {
        bodyPart = [textCoder messagePart];

        partList = [NSMutableArray arrayWithObject:bodyPart];
        attachmentEnum = [attachmentList objectEnumerator];
        while((attachmentPair = [attachmentEnum nextObject]) != nil)
            {
            // this doesn't work too well if you try to attach texts...
            attachmentCoder = [[[EDMultimediaContentCoder alloc] initWithData:[attachmentPair firstObject] filename:[attachmentPair secondObject]] autorelease];
            attachmentPart = [attachmentCoder messagePart];
            [partList addObject:attachmentPart];
            }

        multipartCoder = [[[EDCompositeContentCoder alloc] initWithSubparts:partList] autorelease];
        message = [multipartCoder message];
        }

    headerFieldNameEnum = [userHeaders keyEnumerator];
    while((headerFieldName = [headerFieldNameEnum nextObject]) != nil)
        {
        headerFieldBody = [userHeaders objectForKey:headerFieldName];
        if([headerFieldName caseInsensitiveCompare:@"BCC"] != NSOrderedSame)
            {
            if([headerFieldBody isKindOfClass:[NSDate class]])
                headerFieldBody = [[EDDateFieldCoder encoderWithDate:headerFieldBody] fieldBody];
            else
                // Doesn't do any harm as all fields that shouldn't have MIME words
                // should only have ASCII (in which case no transformation will take
                // place.) A case of garbage in, garbage out...
                headerFieldBody = [[EDTextFieldCoder encoderWithText:headerFieldBody] fieldBody];
            [message addToHeaderFields:[EDObjectPair pairWithObjects:headerFieldName:headerFieldBody]];
            }
        }

    transferData = [message transferData];

//    [stream setStringEncoding:[NSString stringEncodingForMIMEEncoding:charset]];
    [self _sendMail:transferData from:sender to:recipients usingStream:stream];
}


//---------------------------------------------------------------------------------------
//	SENDING EMAILS (CONVENIENCE METHODS, PART 2)
//---------------------------------------------------------------------------------------

- (void)sendMessage:(EDInternetMessage *)message
{
    EDSMTPStream 			*stream;
    NSMutableArray 			*recipients;
    NSArray					*authors;
    NSString				*newRecipients, *sender;
    NSData					*transferData;

    recipients = [NSMutableArray array];
    if((newRecipients = [message bodyForHeaderField:@"To"]) != nil)
        [recipients addObjectsFromArray:[newRecipients addressListFromEMailString]];
    if((newRecipients = [message bodyForHeaderField:@"CC"]) != nil)
        [recipients addObjectsFromArray:[newRecipients addressListFromEMailString]];
    if((newRecipients = [message bodyForHeaderField:@"BCC"]) != nil)
        [recipients addObjectsFromArray:[newRecipients addressListFromEMailString]];
    if([recipients count] == 0)
        [NSException raise:NSInvalidArgumentException format:@"-[%@ %@]: No recipients in message headers.", NSStringFromClass(isa), NSStringFromSelector(_cmd)];

    if((sender = [message bodyForHeaderField:@"Sender"]) == nil)
        {
        authors = [[message bodyForHeaderField:@"From"] addressListFromEMailString];
        if([authors count] == 0)
            [NSException raise:NSInvalidArgumentException format:@"-[%@ %@]: No sender or from field in message headers.", NSStringFromClass(isa), NSStringFromSelector(_cmd)];
        if([authors count] > 1)
            [NSException raise:NSInvalidArgumentException format:@"-[%@ %@]: Multiple from addresses and no sender field in message headers.", NSStringFromClass(isa), NSStringFromSelector(_cmd)];
        sender = [authors objectAtIndex:0];
        }

    stream = [self _getStream];
    if([[message contentTransferEncoding] isEqualToString:MIME8BitContentTransferEncoding])
        {
        // we could try to recode the "offending" parts using Quoted-Printable and Base64...
        if([stream handles8BitBodies] == NO)
            [NSException raise:NSInvalidArgumentException format:@"-[%@ %@]: Message has 8-bit content transfer encoding but remote MTA only accepts 7-bit.", NSStringFromClass(isa), NSStringFromSelector(_cmd)];
        }
    transferData = [message transferData];

    [self _sendMail:transferData from:sender to:recipients usingStream:stream];
}



//---------------------------------------------------------------------------------------
    @end
//---------------------------------------------------------------------------------------
