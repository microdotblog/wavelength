//
//  LUPostController.m
//  Lumos
//
//  Created by Manton Reece on 3/14/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUPostController.h"

@interface LUPostController ()

@end

@implementation LUPostController

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.titleContainer.layer.borderColor = [UIColor lightGrayColor].CGColor;
	self.titleContainer.layer.borderWidth = 0.5;
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self.titleField becomeFirstResponder];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
