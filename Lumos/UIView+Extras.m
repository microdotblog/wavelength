//
//  UIView+Extras.m
//  Wavelength
//
//  Created by Manton Reece on 3/8/24.
//  Copyright © 2024 Micro.blog. All rights reserved.
//

#import "UIView+Extras.h"

@implementation UIView (Extras)

- (BOOL) mb_isDarkMode
{
	return ([self.traitCollection userInterfaceStyle] == UIUserInterfaceStyleDark);
}

@end
