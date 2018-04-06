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

- (void) microblogConfigured:(NSNotification*)notification
{
	// ...
}


@end
