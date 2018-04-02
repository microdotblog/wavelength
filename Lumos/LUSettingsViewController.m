//
//  LUSettingsViewController.m
//  Lumos
//
//  Created by Jonathan Hays on 3/22/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUViewController.h"
#import "LUSettingsViewController.h"

#import "LUAuphonic.h"
#import "SSKeychain.h"
#import "LUNotifications.h"
#import "UUAlert.h"

@interface LUSettingsViewController ()

@end

@implementation LUSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.navigationItem.title = @"Settings";

	self.versionNumber.text = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];

	[self updateAppearance];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self updateAppearance];
}

- (void) selectBlog:(NSDictionary*)blogInfo
{
	[super selectBlog:blogInfo];
	[self updateAppearance];
}

- (void) updateAppearance
{
	NSString* token = [SSKeychain passwordForService:@"ExternalMicropub" account:@"default"];
	NSString* blogName = [[NSUserDefaults standardUserDefaults] objectForKey:@"Wavelength:blog:name"];
	NSDictionary* userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"Micro.blog User Info"];
	
	if (!userInfo || !token)
	{
		self.blogName.text = @"";
		self.userName.text = @"Not signed in to Micro.blog";
		[self.loginButton setTitle:@"Sign In" forState:UIControlStateNormal];
	}
	else
	{
		self.blogName.text = blogName;
		self.userName.text = [userInfo objectForKey:@"full_name"];
		[self.loginButton setTitle:@"Sign Out" forState:UIControlStateNormal];
	}
	
	NSString* auphonic_username = [LUAuphonic savedUsername];
	if (auphonic_username) {
		self.auphonicName.text = [NSString stringWithFormat:@"Auphonic.com: %@", auphonic_username];
		[self.auphonicButton setTitle:@"Sign Out" forState:UIControlStateNormal];
	}
	else {
		self.auphonicName.text = @"Auphonic.com";
		[self.auphonicButton setTitle:@"Sign In" forState:UIControlStateNormal];
	}
}

- (IBAction) onLogin:(id)sender
{
	NSString* token = [SSKeychain passwordForService:@"ExternalMicropub" account:@"default"];
	NSDictionary* userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"Micro.blog User Info"];

	if (!userInfo || !token)
	{
		[self performSegueWithIdentifier:@"SigninSegue" sender:self];
	}
	else
	{
        [UUAlertViewController uuShowTwoButtonAlert:@"" message:@"Are you sure you want to unlink Wavelength with this blog?" buttonOne:@"Cancel" buttonTwo:@"Sign Out" completionHandler:^(NSInteger buttonIndex)
		{
			if (buttonIndex == 1)
			{
				[SSKeychain deletePasswordForService:@"ExternalMicropub" account:@"default"];
				[[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"Micro.blog User Info"];
				[[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"Wavelength:blog:uid"];
				[[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"Wavelength:blog:name"];
				[[NSUserDefaults standardUserDefaults] synchronize];

                [self updateAppearance];
			}
		}];
	}
}

- (IBAction) onAuphonic:(id)sender
{
	NSString* auphonic_username = [LUAuphonic savedUsername];
	if (auphonic_username == nil) {
		[self performSegueWithIdentifier:@"AuphonicSegue" sender:self];
	}
	else {
		[LUAuphonic clearSignin];
		[self updateAppearance];
	}
}

@end
