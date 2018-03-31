//
//  LUAuphonicController.m
//  Wavelength
//
//  Created by Manton Reece on 3/30/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUAuphonicController.h"

#import "LUAuphonic.h"

@implementation LUAuphonicController

- (void) viewDidLoad
{
	[super viewDidLoad];
}

- (IBAction) cancel:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction) signIn:(id)sender
{
	[self.progressSpinner startAnimating];
	
	LUAuphonic* client = [[LUAuphonic alloc] init];
	[client signInWithUsername:self.usernameField.text password:self.passwordField.text completion:^(NSError* error) {
		if (error) {
			// TODO: show alert
		}
		else {
			[self dismissViewControllerAnimated:YES completion:NULL];
		}
	}];
}

@end
