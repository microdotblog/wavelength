//
//  LUAppDelegate.m
//  Lumos
//
//  Created by Jonathan Hays on 3/12/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUAppDelegate.h"
#import <EZAudio/EZAudio.h>
#import "UUString.h"
#import "UUAlert.h"
#import "RFMicropub.h"
#import "RFClient.h"
#import "SSKeychain.h"
#import "LUNotifications.h"

@implementation LUAppDelegate

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[EZAudioUtilities setShouldExitOnCheckResultFail:NO];
	[self setupAppearance];
	
	return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(id)annotation
{
	return [self handleLumosAuthorization:url];
}

- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void) setupAppearance
{
	self.window.tintColor = [UIColor colorWithRed:0.510 green:0.698 blue:0.875 alpha:1.000];

	UIColor* fontColor = self.window.tintColor;

	UIColor* shadowColor = [UIColor clearColor];
	NSShadow* shadow = [[NSShadow alloc] init];
	shadow.shadowOffset = CGSizeMake(0, 1);
	shadow.shadowColor = shadowColor;
	shadow.shadowBlurRadius = 2.0;
	[[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
														  [UIColor blackColor], NSForegroundColorAttributeName,
														  //shadowColor, NSBackgroundColorAttributeName,
														  shadow, NSShadowAttributeName,
														  [UIFont fontWithName:@"AvenirNext-Medium" size:16], NSFontAttributeName,
														  nil]];
	
	UIImage* header_img = [[UIImage imageNamed:@"menu_header"] resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeStretch];
	[[UINavigationBar appearance] setBackgroundImage:header_img forBarMetrics:UIBarMetricsDefault];
	
	[[UIBarButtonItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
														  fontColor, NSForegroundColorAttributeName,
														  //shadowColor, NSBackgroundColorAttributeName,
														  shadow, NSShadowAttributeName,
														  [UIFont fontWithName:@"AvenirNext-Regular" size:16], NSFontAttributeName, nil]
												forState:UIControlStateNormal];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) handleMicropubURL:(NSString *)url
{
	NSString* code = [[url uuFindQueryStringArg:@"code"] uuUrlDecoded];
	NSString* state = [[url uuFindQueryStringArg:@"state"] uuUrlDecoded];

	if (!code || !state) {
		NSString* msg = [NSString stringWithFormat:@"Authorization \"code\" or \"state\" parameters were missing."];
		[UUAlertViewController uuShowOneButtonAlert:@"Micropub Error" message:msg button:@"OK" completionHandler:NULL];
		return;
	}
	
	NSString* saved_me = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalMicropubMe"];
	NSString* saved_state = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalMicropubState"];
	NSString* saved_endpoint = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalMicropubTokenEndpoint"];
	
	if (![state isEqualToString:saved_state]) {
		[UUAlertViewController uuShowOneButtonAlert:@"Micropub Error" message:@"Authorization state did not match." button:@"OK" completionHandler:NULL];
	}
	else {
		NSDictionary* info = @{
			@"grant_type": @"authorization_code",
			@"me": saved_me,
			@"code": code,
			@"redirect_uri": @"https://sunlit.io/micropub/redirect",
			@"client_id": @"https://sunlit.io/",
			@"state": state
		};
		
		RFMicropub* mp = [[RFMicropub alloc] initWithURL:saved_endpoint];
		[mp postWithParams:info completion:^(UUHttpResponse* response) {
			dispatch_async(dispatch_get_main_queue(), ^{
				if ([response.parsedResponse isKindOfClass:[NSString class]]) {
					NSString* msg = response.parsedResponse;
					if (msg.length > 200) {
						msg = @"";
					}
					[UUAlertViewController uuShowOneButtonAlert:@"Micropub Error" message:msg button:@"OK" completionHandler:NULL];
				}
				else {
					NSString* access_token = [response.parsedResponse objectForKey:@"access_token"];
					if (access_token == nil) {
						NSString* msg = [response.parsedResponse objectForKey:@"error_description"];
						[UUAlertViewController uuShowOneButtonAlert:@"Micropub Error" message:msg button:@"OK" completionHandler:NULL];
					}
					else {
						[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ExternalBlogIsPreferred"];
						[SSKeychain setPassword:access_token forService:@"ExternalMicropub" account:@"default"];

						[self checkMicropubMediaEndpoint];
					}
				}
			});
		}];
	}
}

- (void) checkMicropubMediaEndpoint
{
		NSString* media_endpoint = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalMicropubMediaEndpoint"];
		if (media_endpoint.length == 0) {
			NSString* micropub_endpoint = [[NSUserDefaults standardUserDefaults] objectForKey:@"ExternalMicropubPostingEndpoint"];
			RFMicropub* client = [[RFMicropub alloc] initWithURL:micropub_endpoint];
			NSDictionary* args = @{
				@"q": @"config"
			};
			[client getWithQueryArguments:args completion:^(UUHttpResponse* response)
            {
				BOOL found = NO;
				if (response.parsedResponse && [response.parsedResponse isKindOfClass:[NSDictionary class]]) {
					NSString* new_endpoint = [response.parsedResponse objectForKey:@"media-endpoint"];
					if (new_endpoint) {
						[[NSUserDefaults standardUserDefaults] setObject:new_endpoint forKey:@"ExternalMicropubMediaEndpoint"];
						found = YES;
					}
				}

                dispatch_async(dispatch_get_main_queue(), ^
                {
                    if (!found)
                    {
						[UUAlertViewController uuShowOneButtonAlert:@"Error Checking Server" message:@"Micropub media-endpoint was not found." button:@"OK" completionHandler:NULL];
                    }
                    else
                    {
                        [[NSNotificationCenter defaultCenter] postNotificationName:kMicroblogConfiguredNotification object:nil];
                    }
                });
			}];
		}
}

- (BOOL) handleLumosAuthorization:(NSURL*)inURL
{
    if ([inURL.absoluteString uuStartsWithSubstring:@"wavelength://micropub"])
    {
        NSString* action = [inURL resourceSpecifier];
		NSString* microPubToken = [action uuFindQueryStringArg:@"code"];
		if (microPubToken)
			microPubToken = [microPubToken uuUrlDecoded];
		
        if (microPubToken)
        {
        	[self handleMicropubURL:inURL.absoluteString];
            return YES;
        }
		
		
        NSString* token = [inURL lastPathComponent];
        RFClient* client = [[RFClient alloc] initWithPath:@"/account/verify"];
        NSDictionary* args = @{
            @"token": token
        };
		
        [client postWithParams:args completion:^(UUHttpResponse* response)
        {
            if (response.httpResponse.statusCode == 200)
            {
            	dispatch_async(dispatch_get_main_queue(), ^
            	{
                	NSDictionary* dictionary = response.parsedResponse;
                	NSString* errorString = [dictionary objectForKey:@"error"];
					
                	if (errorString)
                	{
                    	[UUAlertViewController uuShowOneButtonAlert:@"Error Verifying Account" message:errorString button:@"Ok" completionHandler:^(NSInteger buttonIndex)
                    	{
                    	}];
                	}
                	else
                	{
                		NSString* new_token = [dictionary objectForKey:@"token"];
					
                    	[SSKeychain setPassword:new_token forService:@"ExternalMicropub" account:@"default"];
                    	[SSKeychain setPassword:new_token forService:@"Snippets" account:@"default"];

                    	[[NSUserDefaults standardUserDefaults] setObject:response.parsedResponse forKey:@"Micro.blog User Info"];
                    	[[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:@"HasSnippetsBlog"];
						
						RFClient* client = [[RFClient alloc] initWithPath:@"/micropub?q=config"];
						[client getWithQueryArguments:nil completion:^(UUHttpResponse *response)
						{
							dispatch_async(dispatch_get_main_queue(), ^
            				{
								if (!response.httpError)
								{
									[[NSNotificationCenter defaultCenter] postNotificationName:kMicroblogConfiguredNotification object:response.parsedResponse];
								}
								else
								{
									[UUAlertViewController uuShowOneButtonAlert:@"Error Verifying Account" message:errorString button:@"Ok" completionHandler:^(NSInteger buttonIndex)
                    				{
                    				}];
								}
							});
						}];

                	}
				});
            }
            else if (response.httpError)
            {
            	dispatch_async(dispatch_get_main_queue(), ^
            	{
                	[UUAlertViewController uuShowOneButtonAlert:@"Error Verifying Account" message:response.httpError.localizedDescription button:@"OK" completionHandler:^(NSInteger buttonIndex)
                	{
                	}];
				});
            }
            else
            {
            	dispatch_async(dispatch_get_main_queue(), ^
            	{
                	NSString* errorString = [NSString stringWithFormat:@"An unknown error was encountered. Please try again later."];
                	[UUAlertViewController uuShowOneButtonAlert:@"Error Verifying Account" message:errorString button:@"OK" completionHandler:^(NSInteger buttonIndex)
                	{
                	}];
				});
            }
        }];

        return YES;
    }
	
    return NO;
}

@end
