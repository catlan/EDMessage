//
//  OPSecureStream.h
//  SecureSocket
//
//  Created by joerg on Fri Nov 30 2001.
//  Copyright (c) 2001 Jörg Westheide. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EDCommon/EDStream.h>


@interface EDStream (SSL)    
+ (id)sslStreamConnectedToHost:(NSHost *)host port:(unsigned short)port;

/*"Methods for turning SSL on and off."*/
- (void) negotiateEncryption;
- (void) shutdownEncryption;

@end
