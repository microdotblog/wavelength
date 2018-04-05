//
//  LUNewBlogController.m
//  Wavelength
//
//  Created by Manton Reece on 4/5/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUNewBlogController.h"

@interface LUNewBlogController ()

@end

@implementation LUNewBlogController

- (void) viewDidLoad
{
	[super viewDidLoad];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self.sitenameField becomeFirstResponder];
}

@end
