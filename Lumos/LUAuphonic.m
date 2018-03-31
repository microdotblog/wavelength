//
//  LUAuphonic.m
//  Wavelength
//
//  Created by Manton Reece on 3/30/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUAuphonic.h"

#import "UUHttpSession.h"
#import "SSKeychain.h"
#import "UUDictionary.h"

static NSString* const kAuphonicClientID = @"17cb5958de966b2eced53f9ee7d05a";
static NSString* const kAuphonicClientSecret = @"b9fe7f2755a30c34a45e54a4fb7fbb";

static NSString* const kAuphonicUsernamePrefKey = @"AuphonicUsername";
static NSString* const kAuphonicKeychainServiceName = @"Auphonic";

@implementation LUAuphonic

+ (NSString *) savedUsername
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:kAuphonicUsernamePrefKey];
}

- (void) signInWithUsername:(NSString *)username password:(NSString *)password completion: (void (^)(NSError* error))handler
{
	NSDictionary* args = @{
		@"client_id": kAuphonicClientID,
		@"username": username,
		@"password": password,
		@"grant_type": @"password"
	};

	NSString* post_s = [args uuBuildQueryString];
	post_s = [post_s substringFromIndex:1]; // skip the '?'
	NSData* post_d = [post_s dataUsingEncoding:NSUTF8StringEncoding];

	NSString* url = @"https://auphonic.com/oauth2/token/";
	UUHttpRequest* request = [UUHttpRequest postRequest:url queryArguments:nil body:post_d contentType:@"application/x-www-form-urlencoded" user:kAuphonicClientID password:kAuphonicClientSecret];
	[UUHttpSession executeRequest:request completionHandler:^(UUHttpResponse* response) {
		if ([response.parsedResponse isKindOfClass:[NSDictionary class]]) {
			NSString* access_token = [response.parsedResponse objectForKey:@"access_token"];
			NSString* returned_username = [response.parsedResponse objectForKey:@"user_name"];
			NSNumber* expires_in = [response.parsedResponse objectForKey:@"expires_in"];

			[SSKeychain setPassword:access_token forService:kAuphonicKeychainServiceName account:returned_username];
			[[NSUserDefaults standardUserDefaults] setObject:returned_username forKey:kAuphonicUsernamePrefKey];
			
			handler (nil);
		}
		else {
			NSLog (@"Auphonic HTTP error");
			handler (nil);
		}
	}];
}

- (void) getSomething
{
//curl https://auphonic.com/api/presets.json -H "Authorization: Bearer {access_token}"
//curl https://auphonic.com/api/presets.json?bearer_token={access_token}
}

@end
