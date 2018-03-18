//
//  LUAppDelegate.m
//  Lumos
//
//  Created by Jonathan Hays on 3/12/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUAppDelegate.h"
#import <EZAudio/EZAudio.h>

@implementation LUAppDelegate

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[EZAudioUtilities setShouldExitOnCheckResultFail:NO];
	[self setupAppearance];
	
	return YES;
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

@end
