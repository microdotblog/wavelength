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
static NSString* const kAuphonicExpiresPrefKey = @"AuphonicExpires";
static NSString* const kAuphonicKeychainServiceName = @"Auphonic";
static NSString* const kAuphonicProductionNumberPrefKey = @"AuphonicProductionNumber";
static NSString* const kAuphonicWaitingProductionPrefKey = @"AuphonicWaitingProduction";
static NSInteger const kAuphonicStatusDone = 3;

@implementation LUAuphonic

+ (NSString *) savedUsername
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:kAuphonicUsernamePrefKey];
}

+ (void) clearSignin
{
	NSString* username = [self savedUsername];
	[SSKeychain deletePasswordForService:kAuphonicKeychainServiceName account:username];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kAuphonicUsernamePrefKey];
}

- (instancetype) init
{
	self = [super init];
	if (self) {
		self.path = @"";
		self.url = @"";
	}
	
	return self;
}

- (void) setupRequest:(UUHttpRequest *)request
{
	NSMutableDictionary* headers = [request.headerFields mutableCopy];
	if (headers == nil) {
		headers = [NSMutableDictionary dictionary];
	}

	NSString* username = [[NSUserDefaults standardUserDefaults] objectForKey:kAuphonicUsernamePrefKey];
	NSString* token = [SSKeychain passwordForService:kAuphonicKeychainServiceName account:username];
	if (token) {
		[headers setObject:[NSString stringWithFormat:@"Bearer %@", token] forKey:@"Authorization"];
	}
	request.headerFields = headers;
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
			[[NSUserDefaults standardUserDefaults] setObject:expires_in forKey:kAuphonicExpiresPrefKey];

			handler (nil);
		}
		else {
			NSLog (@"Auphonic HTTP error");
			handler (nil);
		}
	}];
}

- (void) getPresets
{
	NSString* url = @"https://auphonic.com/api/presets.json";
	UUHttpRequest* request = [UUHttpRequest getRequest:url queryArguments:nil];
	[self setupRequest:request];
	[UUHttpSession executeRequest:request completionHandler:^(UUHttpResponse* response) {
		if ([response.parsedResponse isKindOfClass:[NSDictionary class]]) {
		}
	}];
}

- (void) createProductionWithCompletion:(void (^)(NSString* productionUUID, NSError* error))handler
{
	NSNumber* production_number = [[NSUserDefaults standardUserDefaults] objectForKey:kAuphonicProductionNumberPrefKey];
	NSInteger production_i = [production_number integerValue] + 1;
	
	NSDictionary* info = @{
		@"output_basename": [NSString stringWithFormat:@"Wavelength-%ld", (long)production_i]
	};
	NSData* post_d = [NSJSONSerialization dataWithJSONObject:info options:0 error:nil];;

	[[NSUserDefaults standardUserDefaults] setInteger:production_i forKey:kAuphonicProductionNumberPrefKey];

	NSString* url = @"https://auphonic.com/api/productions.json";
	UUHttpRequest* request = [UUHttpRequest postRequest:url queryArguments:nil body:post_d contentType:@"application/json"];
	[self setupRequest:request];
	[UUHttpSession executeRequest:request completionHandler:^(UUHttpResponse* response) {
		if ([response.parsedResponse isKindOfClass:[NSDictionary class]]) {
			NSString* production_uuid = [[response.parsedResponse objectForKey:@"data"] objectForKey:@"uuid"];
			handler (production_uuid, nil);
		}
		else {
			handler (nil, response.httpError);
		}
	}];
}

- (void) sendAudio:(NSData *)data toProduction:(NSString *)productionUUID withCompletion:(void (^)(NSError* error))handler
{
	self.url = [NSString stringWithFormat:@"https://auphonic.com/api/production/%@/upload.json", productionUUID];
	[self uploadAudioData:data named:@"input_file" httpMethod:@"POST" queryArguments:nil completion:^(UUHttpResponse* response) {
		[[NSUserDefaults standardUserDefaults] setObject:productionUUID forKey:kAuphonicWaitingProductionPrefKey];
		handler (response.httpError);
	}];
}

- (void) startProduction:(NSString *)productionUUID withCompletion:(void (^)(NSError* error))handler
{
	self.url = [NSString stringWithFormat:@"https://auphonic.com/api/production/%@/start.json", productionUUID];
	[self postWithParams:nil completion:^(UUHttpResponse* response) {
		handler (response.httpError);
	}];
}

- (void) getDetailsForProduction:(NSString *)productionUUID withCompletion:(void (^)(NSString* outputURL, NSError* error))handler
{
	self.url = [NSString stringWithFormat:@"https://auphonic.com/api/production/%@.json", productionUUID];
	[self getWithQueryArguments:nil completion:^(UUHttpResponse* response) {
		if ([response.parsedResponse isKindOfClass:[NSDictionary class]]) {
			NSString* output_url = @"";
			NSNumber* status = [[response.parsedResponse objectForKey:@"data"] objectForKey:@"status"];
			if (status.integerValue == kAuphonicStatusDone) {
				[[NSUserDefaults standardUserDefaults] removeObjectForKey:kAuphonicWaitingProductionPrefKey];
				NSArray* output_files = [[response.parsedResponse objectForKey:@"data"] objectForKey:@"output_files"];
				for (NSDictionary* info in output_files) {
					if ([[info objectForKey:@"format"] isEqualToString:@"mp3"]) {
						output_url = [info objectForKey:@"download_url"];
						break;
					}
				}
			}
			handler (output_url, nil);
		}
		else {
			handler (nil, response.httpError);
		}
	}];
}

@end
