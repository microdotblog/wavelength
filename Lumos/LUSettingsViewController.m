//
//  LUSettingsViewController.m
//  Lumos
//
//  Created by Jonathan Hays on 3/22/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUSettingsViewController.h"
#import "SSKeychain.h"
#import "LUNotifications.h"

@interface LUSettingsViewController ()

@end

@implementation LUSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.navigationItem.title = @"Settings";

	self.versionNumber.text = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAppearance) name:kMicroblogConfiguredNotification object:nil];

	[self updateAppearance];
}

- (void) updateAppearance
{
	NSString* token = [SSKeychain passwordForService:@"ExternalMicropub" account:@"default"];

	NSDictionary* userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"Micro.blog User Info"];
	
	if (!userInfo || !token)
	{
		self.userName.text = @"Not signed in to Micro.blog";
		[self.loginButton setTitle:@"Sign In" forState:UIControlStateNormal];
	}
	else
	{
		self.userName.text = [userInfo objectForKey:@"full_name"];
		[self.loginButton setTitle:@"Sign Out" forState:UIControlStateNormal];
	}
}

- (IBAction) onLogin:(id)sender
{
	[self performSegueWithIdentifier:@"SigninSegue" sender:self];
}

- (IBAction) onAuphonic:(id)sender
{
	[self performSegueWithIdentifier:@"AuphonicSegue" sender:self];
}

@end
