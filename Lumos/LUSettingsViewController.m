//
//  LUSettingsViewController.m
//  Lumos
//
//  Created by Jonathan Hays on 3/22/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUSettingsViewController.h"

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
}

- (void) updateAppearance
{
	
}

- (void) onDone:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) onLogin:(id)sender
{
}

@end
