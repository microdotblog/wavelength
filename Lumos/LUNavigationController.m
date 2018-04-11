//
//  LUNavigationController.m
//  Wavelength
//
//  Created by Manton Reece on 4/10/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#import "LUNavigationController.h"

@implementation LUNavigationController

- (BOOL) shouldAutorotate
{
	return YES;
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

@end
