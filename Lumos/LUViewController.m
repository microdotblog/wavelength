//
//  LUViewController.m
//  Wavelength
//
//  Created by Jonathan Hays on 4/2/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUViewController.h"
#import "LUNotifications.h"
#import "UUAlert.h"

@interface LUViewController ()

@end

@implementation LUViewController

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(microblogConfigured:) name:kMicroblogConfiguredNotification object:nil];
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kMicroblogConfiguredNotification object:nil];
}

- (void) selectBlog:(NSDictionary*)blogInfo
{
	NSString* uid = [blogInfo objectForKey:@"uid"];
	NSString* name = [blogInfo objectForKey:@"name"];
	
	[[NSUserDefaults standardUserDefaults] setObject:uid forKey:@"Wavelength:blog:uid"];
	[[NSUserDefaults standardUserDefaults] setObject:name forKey:@"Wavelength:blog:name"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[UUAlertViewController uuShowOneButtonAlert:nil message:@"You have successfully configured Wavelength to publish to your Micro.blog!" button:@"OK" completionHandler:^(NSInteger buttonIndex)
	{
	}];
}

- (void) microblogConfigured:(NSNotification*)notification
{
	NSDictionary* blogInfo = notification.object;
	NSArray* blogList = [blogInfo objectForKey:@"destination"];
	if (blogList.count > 1)
	{
		UIAlertController* actionSheet = [UIAlertController alertControllerWithTitle:@"Wavelength" message:@"Which Micro.blog would you like to use?" preferredStyle:UIAlertControllerStyleActionSheet];
		
		for (NSDictionary* blog in blogList)
		{
			NSString* blogName = [blog objectForKey:@"name"];
			
			[actionSheet addAction:[UIAlertAction actionWithTitle:blogName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
			{
				[self selectBlog:blog];
			}]];
		}
		
		[self presentViewController:actionSheet animated:YES completion:^
		{
		}];
	}
	else if (blogList.count == 1)
	{
		[self selectBlog:blogList.firstObject];
	}
	else {
		[UUAlertViewController uuShowTwoButtonAlert:@"No Microblogs" message:@"There are no Micro.blog-hosted microblogs on your account." buttonOne:@"Learn More" buttonTwo:@"OK" completionHandler:^(NSInteger buttonIndex) {
			if (buttonIndex == 0) {
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://micro.blog/new/site"] options:@{} completionHandler:^(BOOL success) {
				}];
			}
		}];
	}
}


@end
