
#import <EDMessage/EDMessage.h>
#import <Foundation/Foundation.h>

int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    EDMailAgent *mailAgent = [EDMailAgent mailAgentForRelayHostWithName:@"mail.mulle-kybernetik.com" port:25];
	[mailAgent setUsesSecureConnections:YES];

	NSMutableDictionary *authInfo = [NSMutableDictionary dictionary];
	[authInfo setObject:@"<username>" forKey:EDSMTPUserName];
	[authInfo setObject:@"<password>" forKey:EDSMTPPassword];
	[mailAgent setAuthInfo:authInfo];
	
	NSMutableDictionary *headerFields = [NSMutableDictionary dictionary];
    [headerFields setObject:@"Erik Doernenburg <erik@mulle-kybernetik.com>" forKey:@"To"];
    [headerFields setObject:@"Erik Doernenburg <erik@mulle-kybernetik.com>" forKey:@"From"];
    [headerFields setObject:@"EDMessage Test" forKey:@"Subject"];
	
	NSString *text = @"This is a test mail\n\nSent with the EDMessage framework\n";
    text = [text stringWithCanonicalLinebreaks];

    [mailAgent sendMailWithHeaders:headerFields andBody:text];
	
	[pool release];
}

