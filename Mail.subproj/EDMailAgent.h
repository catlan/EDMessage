//---------------------------------------------------------------------------------------
//  EDMailAgent.h created by erik on Fri 21-Apr-2000
//  $Id: EDMailAgent.h,v 2.1 2002-08-19 00:05:41 erik Exp $
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


struct EDMAFlags
{
    unsigned 	skipExtensionTest : 1;
};


@interface EDMailAgent : NSObject
{
    NSHost 				*relayHost;		/*" All instance variables are private. "*/
	struct EDMAFlags 	flags;			/*" "*/		
}


/*" Creating mail agent instances "*/

+ (id)mailAgentForRelayHostWithName:(NSString *)aName;

- (id)initWithRelayHost:(NSHost *)aHost;

/*" Configuring the mail agent "*/

- (void)setRelayHostByName:(NSString  *)hostname;
- (void)setRelayHost:(NSHost *)aHost;
- (NSHost *)relayHost;

- (void)setSkipsExtensionTest:(BOOL)flag;
- (BOOL)skipsExtensionTest;

/*" Sending messages "*/

- (void)sendMailWithHeaders:(NSDictionary *)userHeaders andBody:(NSString *)body;
- (void)sendMailWithHeaders:(NSDictionary *)userHeaders body:(NSString *)body andAttachment:(NSData *)attData withName:(NSString *)attName;
- (void)sendMailWithHeaders:(NSDictionary *)userHeaders body:(NSString *)body andAttachments:(NSArray *)attList;

- (void)sendMessage:(EDInternetMessage *)message;

@end

#endif	/* __EDMailAgent_h_INCLUDE */
