//---------------------------------------------------------------------------------------
//  EDMailAgent.h created by erik on Fri 21-Apr-2000
//  $Id: EDMailAgent.h,v 2.0 2002-08-16 18:24:15 erik Exp $
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


#ifndef	__EDMailAgent_h_INCLUDE
#define	__EDMailAgent_h_INCLUDE


#import <Foundation/Foundation.h>

@class EDInternetMessage;


@interface EDMailAgent : NSObject
{
    NSHost 			*relayHost;
	struct {
        unsigned 	skipExtensionTest : 1;
    } flags;
}

+ (id)mailAgentForRelayHostWithName:(NSString *)name;

- (id)initWithRelayHost:(NSHost *)host;

- (void)setRelayHostByName:(NSString  *)hostname;
- (void)setRelayHost:(NSHost *)host;
- (NSHost *)relayHost;

- (void)setSkipsExtensionTest:(BOOL)flag;
- (BOOL)skipsExtensionTest;

- (void)sendMailWithHeaders:(NSDictionary *)userHeaders andBody:(NSString *)body;
- (void)sendMailWithHeaders:(NSDictionary *)userHeaders body:(NSString *)body andAttachment:(NSData *)attData withName:(NSString *)attName;
- (void)sendMailWithHeaders:(NSDictionary *)userHeaders body:(NSString *)body andAttachments:(NSArray *)attList;

- (void)sendMessage:(EDInternetMessage *)message;

@end

#endif	/* __EDMailAgent_h_INCLUDE */
