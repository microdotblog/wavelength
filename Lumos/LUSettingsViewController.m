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
	
	self.navigationItem.hidesBackButton = YES;
    self.navigationItem.title = @"Settings";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(onDone:)];

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
		self.userName.text = @"Not signed in";
		[self.loginButton setTitle:@"Sign In" forState:UIControlStateNormal];
	}
	else
	{
		self.userName.text = [userInfo objectForKey:@"full_name"];
		[self.loginButton setTitle:@"Sign Out" forState:UIControlStateNormal];
	}
}

- (void) onDone:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) onLogin:(id)sender
{
}

@end
