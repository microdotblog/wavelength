//
//  LUSplitController.m
//  Lumos
//
//  Created by Manton Reece on 3/20/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUSplitController.h"

#import "LUSegment.h"

@implementation LUSplitController

- (void) viewDidLoad
{
	[super viewDidLoad];

	[self setupButtons];
}

- (void) setupButtons
{
	self.splitButton.layer.cornerRadius = 28.0;
	self.splitButton.layer.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.5].CGColor;
	self.splitButton.clipsToBounds = YES;

	self.deleteButton.layer.cornerRadius = 28.0;
	self.deleteButton.layer.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.5].CGColor;
	self.deleteButton.clipsToBounds = YES;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	// Get the new view controller using [segue destinationViewController].
	// Pass the selected object to the new view controller.
}

@end
